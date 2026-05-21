# CodingAgent 示例题
考察 **顶级 Coding Agent（如 Kimi Code 中的 K2.5 模型）** 在复杂、真实工程场景下的三大核心能力：

## 1. 深层推理能力（考“脑子”）
* 拒绝常规算法套路：不能是 LeetCode 类题目，必须包含复杂业务状态流转、并发死锁陷阱、非常规底层 API 交互。

* 考察逻辑推演：要求 Agent 在大量干扰信息中定位关键代码路径，跨抽象层级追踪根因（如跨仓库嵌套调用问题）。

* 典型示例：繁琐 Context 下的 Bug 修复、跨仓库嵌套调用的 Bug 定位。

## 2. 长程任务规划能力（Long‑horizon）
* 多文件、跨步骤：任务需在隔离容器中执行，要求 Agent 跨文件阅读、运行中间脚本、基于报错日志自我修正。

* 长时间 Context 稳定性：测试 Agent 在长链路、多轮迭代中不丢失目标、不遗忘早期信息。

* 典型示例：跨语言重构（Python → Rust）、性能优化与迭代验证。

## 3. 指令遵循能力（尤其对抗性约束）
* 欺骗性/反直觉约束：例如“绝对禁用某标准库”“严格内存峰值限制”“禁止使用深度学习框架但需达到高精度”。

* 检验遗忘倾向：在长程任务中是否会忘记初始的强约束条件，或擅自使用被禁止的工具/库。

* 典型示例：不依赖 GPU 的机器学习算法优化（禁用深度学习）、严格资源限制下的优化。

## 总结：对应聘者（或 Coding Agent）的期望
这不是一道普通的算法或工程题，而是一道 **“系统级、多约束、需要自主规划与纠错”**的综合设计题。
成功完成它需要：**像资深工程师一样推理业务逻辑 + 像架构师一样跨模块规划 + 像严格质量门禁一样始终遵守反直觉约束。**

## 如何使用
1. 创建 ticket_service_task 目录，并按上面结构放入所有文件。

2. 在目录内执行：
```
docker build -t ticket-task .
docker run --rm -v $(pwd)/logs:/logs ticket-task
```
3. 验证：原始版本应偶尔失败（重复票号或超时被叫）。
运行 solve.sh 后应稳定通过 100 轮。

### 方案一：安装 Docker Desktop for Mac（推荐，保证与判题环境一致）
1. **下载安装**
访问 [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/) 下载 .dmg，安装后启动。

2. **验证安装**
```
docker --version
docker run hello-world
```
3. **回到题目目录**
重新执行：
```
docker build -t ticket-task .
docker run --rm -v $(pwd)/logs:/logs ticket-task
```
> 注意：第一次运行会下载 swift:5.9 镜像（约 1.5GB），请确保网络良好。

### 方案二：不使用 Docker，直接在 macOS 本地验证（快速验证逻辑）
题目中的代码是纯 Swift，可以在 macOS 上直接编译运行（Swift 5.9 自带）。
你需要做以下调整：

1. 修改 test.sh（去掉对 /logs 的依赖，改为本地文件）
```
#!/bin/bash
set -e

swift build

for i in {1..100}; do
  echo "=== Round $i ==="
  if ./.build/debug/TicketService 2>&1 | grep -E "DUPLICATE_TICKET|TIMEOUT_CALLED"; then
    echo "Detected bug, exiting with failure"
    exit 1
  fi
done

echo "1.0" > reward.txt   # 写入当前目录
```
2. 直接运行
```
chmod +x test.sh solve.sh
./test.sh
```
3. 验证修复版本
```
./solve.sh   # 会覆盖 Sources 中的文件
./test.sh
```
这样你就可以在 不安装 Docker 的情况下验证 bug 是否存在、修复是否有效。
但是注意：macOS 下的 GCD 行为和 Linux 下略有不同（但本题逻辑是通用的，一般不影响）。