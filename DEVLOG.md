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
- [x] mul.w 指令实现：纯组合逻辑 `*` 运算符，DSP 可推断
- [x] cpucfg 指令实现：返回 CPUCFG 配置值（0x10），supervisor 据此跳过 cache 初始化
- [x] CSR 寄存器组 (`csr_regfile.sv`)：26 个完整 CSR + DMW0/DMW1 存储，difftest 全量接线
- [x] csrrd / csrwr / csrxchg 指令解码与执行：EX 阶段执行 CSR 读改写，结果走 ALU 路径
- [x] DMW 地址翻译：MEM 阶段组合逻辑匹配 DMW0/DMW1，支持 identity 映射与 UART uncached alias
- [x] 阶段 2-5 性能测试 DIFF=0 全通过：MATRIX (96×96), STREAM (~3 MiB), CRYPTONIGHT (2 MiB), MIXED
- [x] 阶段 1-5 difftest DIFF=1 全通过：全量 6 个测试均通过（2026-07-23）
- [x] NEMU cpucfg 兼容：la32r-nemu 添加 cpucfg 解码与 EHelper，修复解码表模式顺序
- [x] la32r-nemu 去 submodule 化：从 gitee 拉取新版并作为项目自有代码维护
- [x] difftest MIF 注入：支持 BaseRAM/ExtRAM MIF（含 `@` 地址标记）注入 NEMU，使数据依赖测试可通过

## 待完成

- [ ] DifftestTrapEvent 接入：模块已定义，未在 core.sv 实例化，异常/中断时需接入
- [ ] 上板验证：soc_top.v + 引脚约束 + Vivado bitstream 生成 → 被 Vivado 2019.2 TclStackFree 崩溃阻塞

## Vivado FPGA 构建状态（2026-07-22）

### RTL 可综合性

- 全部模块通过 Vivado 2019.2 的 RTL Elaboration 阶段，无功能错误
- PLL IP（`clk_pll`）可在 out-of-context 综合中完成 5 个模块的模块级综合
- `default_nettype` directive 已从所有 CPU .sv 文件中移除（Vivado 2019.2 兼容性修复）
- `difftest.v` 保留 symlink，改由 `create_project.tcl` 从 `sources_1` 排除（该文件为 Verilator-only DPI-C）

### 阻塞：TclStackFree 崩溃

**现象**：RTL Elaboration 完成后，Vivado 崩溃输出 `TclStackFree: incorrect freePtr. Call out of sequence?`

**特征**：
- 66 个模块 `done synthesizing module` 全部正常完成
- 不打印 `synth_design completed successfully` 和 timing summary
- 崩溃位置在 Vivado C 层，Tcl `catch` 无法拦截
- `launch_runs` 将 run 标记为 failed，导致后续 `impl_1` 依赖断裂

**已验证无效的规避**：
- `-mode batch` / `-mode tcl` / GUI Tcl Console 直接执行 — 均崩溃
- `create_project -in_memory` / `open_project` — 均崩溃
- `-flatten_hierarchy none` / warning suppression — 均无效
- UNC 路径 vs D: 盘原生路径 — 与路径无关

**环境**：Vivado v2019.2, Windows 11 24H2 (build 10.0.26200), FPGA xc7a200tfbg676-1

### 后续方向

1. Vivado 2019.2 on Ubuntu (Docker)：赛事指定 2019.2 版本，TclStackFree 为 Windows 11 特定问题，Linux 下应可规避
2. 验证 `decode.sv` rs1 多驱动修复后的 Vivado 综合
3. GUI 中 `reset_target Synthesis [get_ips clk_pll]` → `generate_target Synthesis` 确认 IP OOC 能否产出有效 DCP

### 代码修改

| commit | 说明 |
|--------|------|
| `default_nettype` 移除 | 所有 CPU .sv 文件 |
| `create_project.tcl` | `difftest.v` 从 `sources_1` 排除 |
| `add mul.w` | `decode.sv` + `alu.sv` + `common.sv` |
| `add cpucfg` | `decode.sv` + `core.sv` (EX 级 CPUCFG 查询) |
| `add CSR + DMW` | 新增 `csr_regfile.sv`，`decode.sv` (csrrd/csrwr/csrxchg)，`core.sv` (CSR 流水线 + DMW 翻译 + difftest 接线) |
| `update docs` | README / DEVLOG 同步进度 |
| `fix multi-driven rs1` | `decode.sv` rs1 从 `assign` 移入 `always_comb` 消除多驱动 |
| `nemu cpucfg` | NEMU 添加 cpucfg 解码 (decode.c) + EHelper (special.h) + 指令注册 (isa-all-instr.h) |
| `difftest MIF inject` | difftest 支持 BaseRAM/ExtRAM MIF 注入 NEMU（含 @ 地址标记） |

## 已知局限

- MMIO 注入目前覆盖 0x1f000000-0x1f000fff，若后续阶段访问其他设备地址需扩展 is_mmio_addr。
