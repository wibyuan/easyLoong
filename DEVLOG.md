# DEVLOG — 开发进度与已知问题

## 已验证

- [x] 仿真环境（Verilator 编译、MIF 加载、超时退出）
- [x] 五级流水线冒烟（PC 从 0x1c000000 启动，取指成功）
- [x] reset 向量 → supervisor init 代码线性执行
- [x] AXI 读写通路正常（BSS 清零、ExtRAM 存储、UART 写入均可完成）
- [x] Difftest 前 215 条指令 GPR/CSR 逐条比对通过

## 当前卡住

`fibonacci.json` 测试在 supervisor 收到 `A`（加载程序）和 `D`（回读校验）后，
**缺少 `G`（跳转执行）命令**导致死锁超时：

1. supervisor 处理完 A/D 后回到 `SHELL` 等待下一条 UART 命令
2. testbench (`verilator_main.cpp`) 的 `PendingCommand::Run` 仅在
   `+supervisor_entry` 参数存在时触发
3. `fibonacci.json` 未提供 `supervisor_entry` 字段
4. 双方互相等待 → 测试超时

解决方向（待确认）：
- 方案 A: 在 `fibonacci.json` 中添加 `"supervisor_entry": "0x1c300000"`
- 方案 B: 修改 testbench 在 LoadReadback 后自动发 G（entry 取 `supervisor_a_addr`）
- 方案 C: 修改 supervisor shell，A 命令后自动执行加载的程序

## 待完成

- [ ] 测试流程死锁：打通 supervisor UART 交互使 fibonacci 程序运行完成
- [ ] UART 模型差异：UART LSR 读回值与 NEMU 参考模型不一致，不影响 CPU 核心
  正确性，但会导致 difftest 在 UART 交互后报 mismatch
- [ ] supervisor CSR 对接：需实现完整 CSR 读写，以通过后续测试阶段
  （MATRIX / STREAM / CRYPTONIGHT / MIXED）
- [ ] DifftestTrapEvent 接入：模块已定义，未在 core.sv 实例化，异常/中断时需接入
