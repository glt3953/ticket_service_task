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

    // 修复：用一个串行队列保护所有状态变更
    private let stateQueue = DispatchQueue(label: "stateQueue")

    func issueTicket(patientId: String) -> Ticket? {
        return stateQueue.sync {
            guard state == .idle || state == .completed || state == .timedOut else {
                print("Invalid state for issue: \(state)")
                return nil
            }
            state = .issuing
            let number = nextNumber
            nextNumber += 1
            let ticket = Ticket(number: number, patientId: patientId)
            currentTicket = ticket
            state = .waiting

            let work = DispatchWorkItem { [weak self] in
                self?.timeoutCurrent()
            }
            pendingWorkItem = work
            timeoutQueue.asyncAfter(deadline: .now() + 2, execute: work)

            return ticket
        }
    }

    func callNext() -> Ticket? {
        return stateQueue.sync {
            guard state == .waiting else {
                print("Cannot call next, state: \(state)")
                return nil
            }
            guard let ticket = currentTicket else { return nil }

            pendingWorkItem?.cancel()
            pendingWorkItem = nil

            state = .called
            completeCurrent()
            return ticket
        }
    }

    private func completeCurrent() {
        // 确保已经在 stateQueue 中执行
        guard state == .called else { return }
        state = .completed
        currentTicket = nil
    }

    private func timeoutCurrent() {
        stateQueue.async {
            guard self.state == .waiting else { return }
            self.state = .timedOut
            self.currentTicket = nil
            print("TIMEOUT: ticket timed out")
        }
    }

    static func runTestCycle() -> Bool {
        let service = TicketService()
        var seenNumbers = Set<Int>()
        let queue = DispatchQueue.global()
        let group = DispatchGroup()

        for i in 0..<30 {
            group.enter()
            queue.async {
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