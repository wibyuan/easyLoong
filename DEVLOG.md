# DEVLOG — 开发进度与已知问题

## 已验证

- [x] 仿真环境（Verilator 编译、MIF 加载、超时退出）
- [x] 五级流水线冒烟（PC 从 0x1c000000 启动，取指成功）
- [x] reset 向量 → supervisor init 代码线性执行
- [x] AXI 读写通路正常（BSS 清零、ExtRAM 存储、UART 写入均可完成）
- [x] fibonacci difftest 30K+ 条指令全流程通过（supervisor A/D/G/R/D 完整链路）
- [x] BL 指令 rd 修复：隐式写 r1(ra) 而非 instr[4:0] 的 offset 位
- [x] MMIO difftest 解决：UART LSR 等设备寄存器读值在 ref_exec 前注入 NEMU 内存
- [x] difftest mismatch 全状态暴露：commit group/instruction trace + 逐寄存器 diff + NEMU isa_reg_display

## 待完成

- [ ] supervisor CSR 对接：需实现完整 CSR 读写，以通过 MATRIX / STREAM / CRYPTONIGHT / MIXED
- [ ] DifftestTrapEvent 接入：模块已定义，未在 core.sv 实例化，异常/中断时需接入
- [ ] 上板验证：soc_top.v + 引脚约束 + Vivado bitstream 生成

## 已知局限

- DUT 侧 CSR 硬编码为复位默认值（CRMD=0x00000008, ASID=0x000A0000, 其余为 0）。supervisor 写 CSR 后 NEMU 与 DUT 的 CSR 状态将不一致，后续测试阶段需实现完整 CSR
- MMIO 注入目前覆盖 0x1f000000-0x1f000fff，若后续阶段访问其他设备地址需扩展 is_mmio_addr
