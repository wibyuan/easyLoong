# easyLoong — NSCSCC 2026 龙芯杯个人赛 (LoongArch)

基于 XC7A200T-2FBG676C FPGA 的 LoongArch 32-bit (LA32R) 精简版 CPU 实现。

## 致谢

本项目引用了以下开源仓库：

- [loongsonlab/la32r-nemu](https://gitee.com/loongsonlab/la32r-nemu) — LoongArch32-Reduced NEMU 参考模型
- [loongson-edu/nscscc-solo-la-soc](https://gitee.com/loongson-edu/nscscc-solo-la-soc) — NSCSCC 龙芯杯 SoC 仿真与上板框架
- [Tan-YiFan/rvcpu](https://github.com/Tan-YiFan/rvcpu) — 借鉴其 AXI INCR Burst refill 架构与组合逻辑命中检测等 cache 设计思想。已作为 git submodule 纳入 `rvcpu/` 目录便于学习参考

## 1. 项目结构

```text
.
├── nscscc-solo-la-soc/          # ★ SoC 仿真与上板框架 (Verilator / XSIM / Vivado)
│   ├── rtl/
│   │   ├── soc_top.v            #   SoC 顶层
│   │   └── ip/
│   │       ├── myCPU/           #   ★ CPU RTL（core_top + 五级流水线模块）
│   │       ├── APB_UART/        #   UART 控制器
│   │       ├── Bus_interconnects/ # AXI 互联与 CDC
│   │       ├── confreg/         #   配置寄存器 + 数码管 + 按键
│   │       ├── ram_wrap/        #   外部 SRAM 封装
│   │       └── rst_sync/        #   复位同步
│   ├── fpga/                    #   Vivado 上板脚本 + 引脚约束 (soc.xdc)
│   ├── sim/                     #   仿真基础设施 (Verilator / XSIM)
│   ├── sdk/software/examples/
│   │   └── supervisor/          #   LA32R 监控程序 + 阶段 1-5 测试用例
│   └── sdk/toolchains/          #   LA32R 交叉编译工具链
├── src/soc/                     # → nscscc-solo-la-soc/rtl/ 的 symlink（供 CI 提交用）
├── difftest/                    # ★ Differential test 框架 (DPI-C)
├── la32r-nemu/                  # NEMU 参考模型（项目自有代码）
├── docs/                        # 参考文档、评测说明
├── Makefile                     # 根构建/测试入口
├── DEVLOG.md                    # 开发进度
└── README.md
```
> **注意**：`src/soc/myCPU/` 下每个 `.sv` 文件都是指向 `nscscc-solo-la-soc/rtl/ip/myCPU/` 对应文件的独立 symlink。新增 RTL 模块时需同步添加 symlink（`ln -s ../../../nscscc-solo-la-soc/rtl/ip/myCPU/新文件.sv src/soc/myCPU/`），否则 CI HDL Lint 会报 `Cannot find file containing module`。Verilator 仿真不走此路径，故此类遗漏不会在仿真中暴露。

## 2. CPU 设计

### 架构

- **流水线**：五级经典流水线 (IF → ID → EX → MEM → WB)，含数据转发与流水线冒险控制
- **寄存器文件**：32 个 32 位通用寄存器 (r0 恒为 0)，含 write-bypass
- **总线接口**：AXI4 Master（通过 `core_top` 封装 SoC 接口）
- **特权级**：支持 DMW 直接映射地址翻译 (DA/PG 模式切换)，CRMD/DMW0/DMW1 可编程

### Cache 系统

- **icache**：2 路组相联、256 组、16 字节行、8KB、只读、PLRU、关键字优先；**0-cycle 命中**（标签 LUTRAM + 数据组合读取，`addr_ok`+`data_ok`+数据同拍响应，fetch 延迟 2 拍 → 0 拍）
- **dcache**：2 路组相联、256 组、16 字节行、8KB、写回+写分配、PLRU、关键字优先；**0-cycle 命中**（load/store 均旁路 S1/S2 流水线：标签 LUTRAM 组合比较 + 数据组合读取，请求拍内返回数据；miss 仍走 S1/S2 管道）
- **参数化**：dcache 支持 NR_SETS / NR_WAYS / NR_WORDS 三参数配置，组数/路数/行大小可独立调整。icache 同理（独立参数）。`core_top.sv` 中通过 `DCACHE_SETS`, `ICACHE_SETS` 及其他模组参数统一控制。
- **CACOP**：支持 `cacop 0x00` (I$ 索引无效)、`cacop 0x01` (D$ 索引无效)、`cacop 0x09` (D$ 索引写回无效)
- **IBAR**：支持 hint=0 流水线冲刷
- **Cacheability**：基于 CRMD/DMW 区分 cacheable/uncacheable，支持 auto 和 uncache 两种 kernel 构建

> dcache 增强实验（组数/路数/行大小扫描）结论：在当前五级顺序流水线 + 同步 refill 架构下，增大 cache 参数（组数、路数、行大小）无法有效提升 IPC——命中率虽有改善，但 miss penalty 同步增大导致净收益为负（Cryptonight 32B 行 IPC 下降 44.8%）。瓶颈在 miss 处理延迟，不在 cache 参数配置。详见 [DEVLOG.md](DEVLOG.md) 中「dcache 增强实验」章节。

### 指令集覆盖

| 类别 | 已实现指令 |
|------|-----------|
| 立即数计算 | `lu12i.w`, `pcaddu12i` |
| 立即数 ALU | `addi.w`, `andi`, `ori`, `xori`, `slti`, `sltui` |
| 寄存器 ALU | `add.w`, `sub.w`, `mul.w`, `slt`, `sltu`, `and`, `nor`, `or`, `xor`, `sll.w`, `srl.w`, `sra.w` |
| 移位立即数 | `slli.w`, `srli.w`, `srai.w` |
| 访存 | `ld.b`, `ld.h`, `ld.w`, `ld.bu`, `ld.hu`, `st.b`, `st.h`, `st.w` |
| 跳转/分支 | `b`, `bl`, `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`, `jirl` |
| 系统/CSR | `csrrd`, `csrwr`, `csrxchg`, `cpucfg` |
| Cache 维护 | `cacop 0x00/0x01/0x09`, `ibar` |

### 模块清单 (`nscscc-solo-la-soc/rtl/ip/myCPU/`)

| 文件 | 功能 |
|------|------|
| `common.sv` | LA32R 基础类型定义 |
| `core.sv` | 五级流水线顶层，例化全部子模块 |
| `pipeline_reg.sv` | 通用流水线寄存器 (stall/flush) |
| `regfile.sv` | 32×32 位寄存器文件 (r0=0)，含 write-bypass |
| `csr_regfile.sv` | 26 个 CSR 寄存器文件 + DMW 存储 |
| `decode.sv` | 指令译码 |
| `alu.sv` | 32 位 ALU |
| `bcu.sv` | 分支条件判断 |
| `branch_predictor.sv` | 分支预测器 (BTFNT) |
| `npc.sv` | 下一 PC 计算 |
| `fetch_unit.sv` | 取指单元 |
| `lsu.sv` | 访存单元 |
| `dcache.sv` | 数据 Cache（2 路组相联、8KB、写回） |
| `icache.sv` | 指令 Cache（2 路组相联、8KB、只读） |
| `hazard_unit.sv` | 流水线冒险控制 |
| `axibus_arbiter.sv` | ibus/dbus AXI4 仲裁 |
| `core_top.sv` | AXI Master 接口封装 |

## 3. 硬件平台

| 项目 | 值 |
|------|-----|
| FPGA | XC7A200T-2FBG676C |
| BaseRAM | `0x1c000000 - 0x1c3fffff` (4 MiB) |
| ExtRAM | `0x1c400000 - 0x1c7fffff` (4 MiB) |
| UART 窗口 | `0x1f000000 - 0x1f0fffff` (1 MiB) |
| 复位 PC | `0x1c000000` |
| 串口 | 115200 baud, 8N1 |
| 字节序 | 小端 |

## 4. 评测阶段

| 阶段 | 类型 | 说明 | 指令级 difftest | 数据比对 |
|------|------|------|----------------|----------|
| 1 | 功能测试 | 斐波那契数列（裸机） | ✅ DIFF=1 通过 | N/A |
| 2 | MATRIX | 矩阵乘加 (96×96, 64KB) | ✅ DIFF=1 通过 | ✅ 通过 |
| 3 | STREAM | ~3 MiB 连续访存 | ✅ DIFF=1 通过 | ✅ 通过 |
| 4 | CRYPTONIGHT | 2 MiB 内存访问 + 整数运算 | ✅ DIFF=1 通过 | ✅ Verilator 通过<br>⚠ FPGA 平台 50 分 |
| 5 | MIXED | 混合运算 | ✅ DIFF=1 通过 | ✅ 通过 |
| fibonacci | 自修改代码 | UART 加载 + FLUSH_DCACHE + 执行 | ✅ DIFF=1 通过 | ✅ 通过 |

> 阶段 1-5 + fibonacci 的 difftest 和数据比对均已全部通过。

### 当前性能指标（Verilator difftest 估测 vs 实板, AXI INCR Burst Refill + Writeback 2026-07-27）

| 测试 | 指令数 | 周期数 | IPC | IPC(旧) | 提升 |
|------|--------|--------|-----|---------|------|
| Mixed | 329K | 1.87M | 0.176 | 0.121 | +45.5% |
| Matrix | 5.64M | 32.80M | 0.172 | 0.122 | +41.0% |
| Stream | 3.95M | 28.07M | 0.141 | 0.085 | +65.9% |
| Cryptonight | 23.09M | 141.85M | 0.163 | 0.091 | +78.8% |

> 估测公式：`runtime = total_cycles / 50MHz`（cpu_clk 经 PLL XCI 确认为 50 MHz）。
> IPC(旧) = BTFNT+ID重定向 基线（2026-07-26），即 burst refill + writeback burst 改造前的值。
>
> **Burst 改造效果**：DCache refill 与 writeback 均由逐字握手改为 AXI INCR burst 单次事务。Cryptonight 单次 miss penalty 从 87 → 30.5 周期（-65%），IPC 提升 78.8%。

### DCache 标签 LUTRAM + 存储命中快速路径（2026-07-29）

| 测试 | 指令数 | 周期数 | IPC | IPC(旧) | 提升 |
|------|--------|--------|-----|---------|------|
| Mixed | 329K | 1.77M | 0.186 | 0.176 | +5.5% |
| Matrix | 5.64M | 30.16M | 0.187 | 0.172 | +8.8% |
| Stream | 3.95M | 26.26M | 0.150 | 0.141 | +6.8% |
| Cryptonight | 23.09M | 134.38M | 0.172 | 0.163 | +5.4% |

> 将 DCache 标签 RAM 从 BRAM 迁移至分布式 RAM (LUTRAM)，实现组合逻辑标签读取。在 S2 空闲时，存储命中请求在同周期内触发 `addr_ok`+`data_ok` 并直写 BRAM，旁路 S1/S2 流水线。借鉴 rvcpu 的 0 周期标签比较设计思想，但仅将标签（~10.5Kb）放入 LUTRAM，数据 RAM（64Kb）保留 BRAM。IPC 提升 5-9%。

### 流水线 Stall 七类拆解（Verilator difftest, 2026-07-29 标签 LUTRAM，优先级降序）

| 类别 | Mixed | Matrix | Stream | Cryptonight |
|------|:-----:|:------:|:------:|:-----------:|
| DCache Refill | **40.0%** | **34.2%** | **50.7%** | **60.9%** |
| ICache Refill | 0.4% | 0.0% | 0.0% | 0.0% |
| Load-Use | 0.8% | 0.2% | 5.3% | 0.0% |
| Branch Flush | 20.1% | 19.4% | 12.0% | 15.8% |
| DCache Hit Pipe | 9.8% | 15.7% | 10.8% | 6.0% |
| ICache Hit Pipe | 23.5% | 22.0% | 15.7% | 15.8% |
| Other | 5.4% | 8.4% | 5.4% | 1.4% |

> DCache Hit Pipe 占比从 10-21% 降至 6-16%（存储命中延迟已消除）。DCache Refill 仍为最大瓶颈（34-61%）。下一步优先考虑写缓冲（消除 refill 期间 store 阻塞）或非阻塞 cache（hit-under-miss）。

### 当前性能指标（Verilator difftest, 2026-07-31，0-cycle icache + dcache load 快速路径）

| 测试 | 指令数 | IPC | 说明 |
|------|--------|-----|------|
| simple | 24K | 0.1669 | 与旧流水线基线 0.1505 相比 +11% |
| fibonacci | 97K | 0.1360 | UART 串口读写主导（DCache Hit Pipe 来自串口轮询） |
| stream | 3.96M | 0.2241 | |
| matrix | 5.65M | **0.3730** | load 密集（91% 命中），dcache load 快速路径收益最大 |
| mixed | 331K | 0.2963 | |
| cryptonight | 23.09M | 0.2478 | load 几乎全为 2MB scratchpad 强制 miss，无命中可提速 |

> 从 2026-07-27 基线（IPC 0.141-0.176）累计提升：Burst refill/writeback → 标签 LUTRAM + store 快速路径 → 0-cycle icache → dcache load 快速路径。各阶段增量与数据见 [DEVLOG.md](DEVLOG.md)。

### 分支预测准确率（BTFNT, Verilator 仿真, 2026-07-26）

| 测试 | 条件分支数 | 误预测数 | 准确率 |
|------|-----------|----------|--------|
| Simple | 4,879 | 819 | 83.21% |
| Stream | 791,311 | 820 | 99.90% |
| Matrix | 244,688 | 10,132 | 95.86% |
| Mixed | 41,743 | 4,950 | 88.14% |
| Cryptonight | 1,577,743 | 821 | 99.95% |
| Fibonacci | 17,966 | 330 | 98.16% |

> BTFNT (Backward Taken, Forward Not Taken) 静态预测器，独立模块 `branch_predictor.sv`。`DifftestBranchState` 通过 DPI-C 逐周期上报 `total_branches`（仅条件分支 BEQ/BNE/BLT/BGE/BLTU/BGEU）和 `mispredictions`（预测方向 ≠ 实际方向）。
>
> **BTFNT ID 级重定向已实现**：预测 taken 时在 ID 阶段通过 `bp_do_jump` 重定向 fetch，npc 在 EX 阶段抑制冗余 flush 并处理 misprediction 恢复。IPC 提升见上方性能表。

### Cache 命中率（Verilator 仿真, 2026-07-27 Burst 后）

| 测试 | ICache 访问 | ICache 命中率 | DCache 访问 | DCache 命中率 | DCache 写回 |
|------|------------|--------------|------------|--------------|------------|
| Mixed | 610K | 99.98% | 66K | 70.46% | 62K words |
| Matrix | 10.85M | 100.00% | 2.66M | 91.26% | 885K words |
| Stream | 9.09M | 100.00% | 1.57M | 75.00% | 787K words |
| Cryptonight | 47.81M | 100.00% | 4.72M | 52.95% | 8.88M words |

> 命中率与 burst 改造前一致（取决于程序访存模式而非微架构），ICache 访问数因总周期缩减而下降。

## 5. 开发环境搭建

### Clone

```bash
git clone <this-repo-url>
cd easyLoong
```

### LA32R 交叉编译工具链

```bash
cd nscscc-solo-la-soc/sdk/toolchains
bash init.sh
```

### 构建

```bash
make build
```

自动完成 NEMU 参考模型编译 + supervisor 软件构建。

## 6. Verilator 仿真

> **注意事项**：
> - **不要随意使用 `make test-all`**：全量 6 测试耗时极长（单 cryptonight 即约 2300 万条指令），日常调试优先用单个测试目标（如 `make test-mixed` 复现最快）。
> - **不要随意使用 `DIFF=0`**（nodiff 模式）：若 difftest 未通过，关闭 difftest 后的 DUT 可能在错误路径上进入死循环，导致仿真卡死且无任何有用输出。始终先用 DIFF=1 确认程序能正常运行。

从 easyLoong 根目录运行：

```bash
make test-simple          # 冒烟测试
make test-fibonacci       # 斐波那契
make test-matrix          # 矩阵乘加
make test-stream          # 连续访存
make test-cryptonight     # 密码学运算
make test-mixed           # 混合运算
make test-all             # 全部测试

DIFF=0 make test-simple   # 关闭 difftest，仅仿真
```

### 单元测试

当 difftest 报错时，可将错误现场提取为独立单元测试，快速迭代调试：

```bash
cd unittest/ex_mem_flush && ./run_test.sh
```

单元测试实例化 `core` 模块直连 NEMU difftest，绕过 supervisor / UART / SRAM 等全系统依赖，仿真时间 < 1 秒。工作流文档见 `unittest/UNITTEST-WORKFLOW.md`。

### 强制重新编译 RTL

```bash
FORCE_VERILATOR_REBUILD=1 make test-simple
```

## 7. Difftest 差分测试

每个时钟周期 WB 级提交一条已退休指令，通过 DPI-C 将 DUT 的 GPR/CSR 状态传入 C++ 层，同步步进 NEMU 参考模型执行同一条指令，逐条比对寄存器状态。

### DPI-C 接口

| Verilog 模块 | 功能 |
|-------------|------|
| `DifftestArchIntRegState` | 32 个 GPR |
| `DifftestInstrCommit` | WB 级提交信息 |
| `DifftestCSRState` | CSR 字段 |
| `DifftestIdlePC` | regcpy 缓冲区对齐 |
| `DifftestTrapEvent` | 陷阱事件（已定义，待接入） |
| `DifftestCacheState` | ICache/DCache 性能计数器（hit/miss/access/writeback） |
| `DifftestBranchState` | 分支预测性能计数器（total_branches/mispredictions） |
| `DifftestStallState` | 流水线 stall 7 类拆解（DCache/ICache Refill, Load-Use, Branch Flush, Cache Hit Pipe, Other） |

### 仿真结束时输出

difftest 正常退出时自动输出：

- **IPC**：`指令数 / 总周期数`
- **FPGA 运行时估测**：`总周期数 / 50MHz`（cpu_clk 频率）
- **ICache 指标**：访问数 / hit / miss / 命中率
- **DCache 指标**：访问数 / hit / miss / 命中率 / 写回 word 数
- **分支预测指标**：条件分支数 / 误预测数 / 准确率
- **流水线 Stall 七类拆解**：按优先级 DCache Refill > ICache Refill > Load-Use > Branch Flush > DCache Hit Pipe > ICache Hit Pipe > Other，输出各类周期数和占 stall 周期百分比

### Mismatch 时输出

1. Commit Group Trace（最近 16 组提交）
2. Commit Instr Trace（最近 16 条指令）
3. Register Diff（逐寄存器 REF vs DUT）
4. REF Regs（NEMU 完整寄存器 dump）

### MMIO 处理

DUT 从设备地址 (`0x1f000000-0x1f000fff`) load 时，将值注入 NEMU 内存。

### MIF 注入

仿真初始化时自动将 `base_ram_mif` 和 `ext_ram_mif` 加载至 NEMU 对应地址空间，支持 `@` 地址标记格式。

## 8. Vivado 上板与仿真

Vivado 2019.2 在 Windows 11 上有兼容性问题，推荐使用 Docker 容器运行。完整安装教程见 [vivado-docker.md](vivado-docker.md)。

> **已知问题**：Docker 内 `report_timing_summary` 可能触发 JVM segfault（signal 11, `reportTcl`），合成本身 0 errors。用 `report_timing -max_paths 100` 替代可规避。详见 DEVLOG。

```bash
# 综合 + 实现 + 生成 bitstream
make build-bitstream

# XSIM RTL 行为仿真（耗时约 2-5 分钟/测试，输入输出通过 UART 引脚逐 bit 解码）
make vivado-sim-behavioral

# Post-Implementation 门级时序仿真（接口就绪，极慢，暂不推荐直接运行）
make vivado-sim-post-impl

# 清理 Vivado 项目文件
make clean-vivado
```

> **性能警告**：`vivado-sim-behavioral` 使用 Vivado XSim 的 RTL 行为仿真。与 Verilator（C++ 编译仿真，秒级完成）不同，XSim 是解释型事件驱动仿真器，simple 测试约需 **2-5 分钟**（含编译+elaboration+仿真）。全量 6 个测试预计 **20-30 分钟**。

> `vivado-sim-post-impl` 使用门级网表 + SDF 时序反标，速度约为行为仿真的 1145 倍慢，仅适合极小时间窗口的时序验证。

引脚约束文件：`nscscc-solo-la-soc/fpga/constraints/soc.xdc`。

## 9. GitLab CI

通过组委会 GitLab 平台 (`GITLAB_HOST_REDACTED:18002`) 自动综合生成比特流。

```bash
# 一键提交
./scripts/submit-ci.sh

# 指定分支名
./scripts/submit-ci.sh submit-v4
```

CI 流水线：HDL Lint → Vivado 综合+实现 → 时序检查 → 生成比特流。

提交记录：

| 分支 | 结果 | WNS | Critical Warnings | 日期 |
|------|------|-----|-------------------|------|
| submit-v1 | ❌ 时序失败 | -1.274 ns | 34 | 2026-07-25 |
| submit-v3 | ✅ 通过 | 7.811 ns | 0 | 2026-07-25 |
| submit-v4 | ✅ 通过 | — | 0 | 2026-07-25 |
| submit-20260729-1031 | ⏳ 超时 | 0.564 (Place) | 0 | 2026-07-29 |
| submit-20260729-1630 | ⏳ 超时 | 5.388 (Synth) | 0 | 2026-07-29 |
| submit-20260729-1747 | ⏳ CI 中 | 7.728 (Synth) | 0 | 2026-07-29 |

> **submit-20260729-1747**：含 mul.w 16 位部分积分解 + CSR 读打拍 + EX mux 拆分。Synthesis WNS 5.388→7.728ns（+43%），DSP48E1 级联从关键路径消除，新最差路径转移至 dcache just_hit → pc_reg。IPC 不变。详见 DEVLOG。

> **submit-20260729-1630**：含 dcache S_STORE_FINAL 消除 + cpu_resp 拆分优化。Synthesis WNS 5.290→5.388ns，dcache 关键路径从 #1 跌至 #6+，新最差路径为 ALU(MUL)→CSR→ex_mem。详见 DEVLOG。

> **submit-20260729-1031**：含标签 LUTRAM 优化（`(* ram_style = "distributed" *)`）。HDL Lint、综合、布局均通过（0 Critical Warnings, Place WNS=0.564 ns），布线阶段超 1h CI 限制。详见 [DEVLOG.md](DEVLOG.md) 中时序优化注意事项。

详细工作流见 [docs/CI-WORKFLOW.md](docs/CI-WORKFLOW.md)。

## 10. DEVLOG

开发进度与已知问题见 [DEVLOG.md](DEVLOG.md)。

## 11. 分支状态（wip/icache-0cycle → master，2026-07-31）

> **2026-07-31：wip/icache-0cycle 已 fast-forward 合并至 master**（36 个提交：0-cycle icache + 7 个流水线 bug 修复 + dcache load 快速路径 + 7 个单元测试 + 文档）。以下为本分支全部工作的最终状态。

0-cycle icache 命中路径（`req_hit` 组合逻辑直接驱动 `data_ok`，fetch 延迟 2 拍 → 0 拍）将流水线推到 ~1 IPC 满载，陆续暴露了 7 个被低 IPC 掩盖的深层流水线 bug（全部零 IPC 代价修复）：

| Bug | 根因 | 修复 | 单元测试 |
|-----|------|------|---------|
| 分支预测重定向后 IF/ID 未冲刷 | `hazard_unit` 实例化漏接 `.bp_do_jump()` | `3b00951` | `unittest/ex_mem_flush/` ✅ |
| cacop stall 期间重复 commit | MEM/WB 从不 stall，EX/MEM 滞留指令被多次捕获 | `1b62bc2` | `unittest/ex_mem_stall_dup/` ✅ |
| CSR 写不在退休点 | CSR 写在 EX 级生效，difftest 每拍采样实时值 → 提交比较口径错位 | `f2213a1`（写移至 WB + 三级在飞转发） | `unittest/csr_dmw0_loop/` ✅ |
| EX 操作数 ID 锁存陈旧 | stall 期间锁存操作数落后于已退休的写者（2-back RAW 跨 stalled load） | `e104547`（EX 级组合读 regfile） | `unittest/gpr_fwd_load_stall/` ✅ |
| 重定向目标/被扣分支被 if_id_flush 杀 | `pc_current == jump_target` 时 flush 杀正确捕获；load_use 扣住的分支被自身 bp flush 清零 | `3467452` + `7ffb793` | `unittest/beq_redirect_target/` + `bne_load_use_bpflush/` ✅ |
| icache keyword-forward 错误路径存活 | miss 无 addr_ok 应答，keyword 数据与当前 pc 配对；重定向后 fetch_unit 滞留 WAIT_DATA，keyword 把错误路径指令送进流水线 | `a8f6b9a` + fetch_unit WAIT_DATA 放弃 + icache keyword 地址门控 + keep_capture 收紧 | `unittest/icache_redirect_stale/` ✅ |
| IF/ID 被扣期间 ID 重复下发（重复 commit） | `if_id_stall=1` 时 ID 每拍重解码同一指令，id_ex_stall 释放后同一条指令二次进入 EX | `id_ex_in.ctrl.valid` 门控 `!(if_id_stall && !if_id_flush)` | fibonacci WELCOME 循环回归 ✅ |

**测试状态（全量回归通过）**：

| 测试 | 状态 |
|------|------|
| 7 个单元测试（含新增 icache_redirect_stale） | ✅ 全部通过 |
| `make test-simple` | ✅ 24447 条，IPC 0.1669（修复前基线 0.1663） |
| `make test-fibonacci` | ✅ 96857 条，数据比对 PASS，IPC 0.1360 |
| `make test-stream/matrix/mixed/cryptonight` | ✅ 全通过，数据比对 PASS，IPC 0.2241/0.3730/0.2963/0.2478 |

> **2026-07-31 追加：DCache load 命中快速路径（0-cycle，镜像 icache）**——数据 RAM 组合读取端口 + fast-path cpu_resp 的 load 分支，load 命中同拍返回数据（store 快速路径 2026-07-29 已就位）。matrix IPC 0.3024→0.3730（+23.3%，load 密集），stream +6.7%，mixed +2.4%，simple +0.4%；cryptonight 不变（其 load 几乎全为 scratchpad 强制 miss，无命中可提速）。详见 DEVLOG。

详细根因分析与修复记录见 [DEVLOG.md](DEVLOG.md) 的「wip/icache-0cycle 分支修复记录（2026-07-31 续）」。
