import Foundation

struct Ticket: Equatable {
    let number: Int
    let patientId: String
}

enum State: String {
    case idle, issuing, waiting, called, completed, timedOut, invalid
}

class TicketService {
    private var currentTicket: Ticket?
    private var state: State = .idle
    private var nextNumber = 1

    private var pendingWorkItem: DispatchWorkItem?
    private let timeoutQueue = DispatchQueue(label: "timeoutQueue")

    // 故意使用并发队列，并允许同时访问状态（不用串行）
    private let apiQueue = DispatchQueue(label: "apiQueue", attributes: .concurrent)

    // 发号
    func issueTicket(patientId: String) -> Ticket? {
        var result: Ticket?
        apiQueue.sync {
            // 状态检查过于宽松：超时后未完全重置时也可能允许发号
            guard state == .idle || state == .completed || state == .timedOut else {
                print("Invalid state for issue: \(state)")
                return
            }
            state = .issuing
            let number = nextNumber
            nextNumber += 1
            let ticket = Ticket(number: number, patientId: patientId)
            currentTicket = ticket
            state = .waiting
            result = ticket

            let work = DispatchWorkItem { [weak self] in
                self?.timeoutCurrent()
            }
            pendingWorkItem = work
            timeoutQueue.asyncAfter(deadline: .now() + 2, execute: work)
        }
        return result
    }

    // 叫号（存在竞态条件）
    func callNext() -> Ticket? {
        var result: Ticket?
        apiQueue.sync {
            // BUG1: 没有检查超时边缘（比如 timeout 刚触发但 state 还未改变）
            guard state == .waiting else {
                print("Cannot call next, state: \(state)")
                return
            }
            guard let ticket = currentTicket else { return }

            pendingWorkItem?.cancel()
            pendingWorkItem = nil

            state = .called
            result = ticket
            // 立即完成，但 completeCurrent 中状态判断可能被并发打破
            completeCurrent()
        }
        return result
    }

    private func completeCurrent() {
        apiQueue.async(flags: .barrier) {
            guard self.state == .called else { return }
            self.state = .completed
            self.currentTicket = nil
        }
    }

    private func timeoutCurrent() {
        apiQueue.async(flags: .barrier) {
            // BUG2: 当 state 已经从 waiting 变成 called 时，不应该超时
            // 但由于并发，这里可能误将 called 改成 timedOut
            if self.state == .waiting {
                self.state = .timedOut
                self.currentTicket = nil
                print("TIMEOUT: ticket timed out")
            } else {
                // 错误情况：超时发生但已经叫号，仍打印警告（模拟边缘问题）
                print("TIMEOUT_CALLED: timeout but state is \(self.state)")
            }
        }
    }

    // 测试入口：并发执行 30 次操作，检测重复票号或状态异常
    static func runTestCycle() -> Bool {
        let service = TicketService()
        var seenNumbers = Set<Int>()
        let queue = DispatchQueue.global()
        let group = DispatchGroup()

        for i in 0..<30 {
            group.enter()
            queue.async {
                // 三种操作混合：发号、叫号、查询
                if i % 3 == 0 {
                    if let ticket = service.issueTicket(patientId: "P\(i)") {
                        if seenNumbers.contains(ticket.number) {
                            print("DUPLICATE_TICKET: \(ticket.number)")
                            exit(1)
                        }
                        seenNumbers.insert(ticket.number)
                    }
                } else if i % 3 == 1 {
                    _ = service.callNext()
                } else {
                    _ = service.currentTicket
                }
                group.leave()
            }
        }
        group.wait()
        return true
    }
}

let success = TicketService.runTestCycle()
exit(success ? 0 : 1)