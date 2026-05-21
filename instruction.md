# 任务：修复挂号排队系统的并发状态机 Bug（含超时边缘条件）

## 背景
我们有一个简化版的医院科室叫号系统（Swift 实现）。它运行在 Linux 环境，使用 GCD 进行并发控制。

## 现象
运行 `./test.sh` 时会不定期出现：
- 同一个票号被分配给两个不同患者
- 一个患者在超时后仍然被叫到号
- 偶发性卡死（超时后没有正确重置状态）

## 你的任务
修改 `Sources/TicketService.swift` 中的 `TicketService` 类，使得 **所有测试用例通过**，并且满足以下强约束：

### 强约束（必须遵守）
1. **严禁使用任何显式锁 API**，包括但不限于：  
   `NSLock`, `NSRecursiveLock`, `os_unfair_lock`, `pthread_mutex`, `DispatchSemaphore`（信号量也不允许）。
2. **只能使用** `DispatchQueue`（串行/并发）和 `DispatchGroup` 来实现线程安全。
3. **禁止改变公共接口**（`struct Ticket`, `enum State`, 类的方法签名）。
4. **禁止删除或注释掉现有状态机的任何状态**，只能修改方法内部实现。

## 验收标准
- 运行 `./test.sh` 后，连续 100 轮测试无 crash、无重复票号、无超时后叫号。
- 最终 `/logs/verifier/reward.txt` 中分数为 1.0。

## 提示
- 仔细检查 `issueTicket()` 和 `callNext()` 的并发执行路径。
- 超时是通过 `DispatchWorkItem` 实现的，注意取消时机。