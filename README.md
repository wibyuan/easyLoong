# easyLoong — NSCSCC 2026 龙芯杯个人赛 (LoongArch)

> 本项目为第十届龙芯杯（NSCSCC 2026）个人赛 LA32R 处理器核开发的完整代码记录。
> 本项目最终止步初赛（未能进入决赛），在 Matrix、Stream 等性能测试上与顶尖选手的乱序多发射核存在数倍的客观差距。
> 记录仅为完整留存本人从零搭建流水线、接入 difftest、利用大模型（DeepSeek V4）进行硬件调试与优化的真实过程，供后续参赛同学与体系结构初学者参考避坑。

基于 XC7A200T-2FBG676C FPGA 的 LoongArch 32-bit (LA32R) 精简版 CPU 实现。

> **⚠ 任何 Vivado / 综合 / 实现 / 时序 / PLL 工作必须首先阅读并遵循 [DEVLOG.md](DEVLOG.md)「Vivado 操作手册（交接必备）」**，并使用 `scripts/vivado/run_vivado.sh {create|synth|impl}` 流程（默认策略）。RTL 改动必须先过门禁 `scripts/gate_diff.sh simple matrix cryptonight`。

> **当前状态（2026-08-05）**：无 dcache + `axi_sram_direct` 直通异步 SRAM（2 拍读/3 拍写 + 4 项写缓冲 + store→load 转发）+ 1KB 直接映射 icache（0-cycle 命中）。PLL 为 cpu_clk=100MHz / sys_clk=25MHz，默认策略下 **Implementation WNS +0.024 闭环**。difftest 6/6 + 数据比对全部通过，基准 IPC：matrix 0.448 / stream 0.496 / mixed 0.593 / cryptonight 0.744。完整开发历程与教训见 [DEVLOG.md](DEVLOG.md)。


## 致谢

本项目引用了以下开源仓库：

- [loongsonlab/la32r-nemu](https://gitee.com/loongsonlab/la32r-nemu) — LoongArch32-Reduced NEMU 参考模型
- [loongson-edu/nscscc-solo-la-soc](https://gitee.com/loongson-edu/nscscc-solo-la-soc) — NSCSCC 龙芯杯 SoC 仿真与上板框架
- [Wubian111/Wubian_la32r_cpu](https://github.com/Wubian111/Wubian_la32r_cpu) — 借鉴其 SRAM 数据总线三态选择提前寄存（`MemoryIO.v`：写选择/WE 寄存化驱动数据总线）的做法
- [Tan-YiFan/rvcpu](https://github.com/Tan-YiFan/rvcpu) — 借鉴其 AXI INCR Burst refill 架构与组合逻辑命中检测等 cache 设计思想。已作为 git submodule 纳入 `rvcpu/` 目录便于学习参考
- [KyleMao2023/LoongArch](https://github.com/KyleMao2023/LoongArch)（Synapse-X4，2025 龙芯杯个人赛二等奖）— 四发射乱序（Tomasulo + ROB + 局部历史/BTB/RAS 分支预测）参考实现，其「无 dcache + WriteBuffer + 固定 2 拍直连异步 SRAM」思路直接启发了本项目 2026-08-04 的直连方案。已作为 git submodule 纳入 `synapse-x4/` 目录（仅学习参考，不参与构建/提交）

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
├── unittest/                    # 流水线 bug 单元测试（core 直连 NEMU difftest）
├── scripts/                     # CI 提交等辅助脚本（submit-ci.sh）
├── experiments/                 # cache 参数扫描等实验脚本
├── Makefile                     # 根构建/测试入口
├── DEVLOG.md                    # 开发进度
└── README.md
```
> **注意**：`src/soc/myCPU/` 下每个 `.sv` 文件都是指向 `nscscc-solo-la-soc/rtl/ip/myCPU/` 对应文件的独立 symlink。新增 RTL 模块时需同步添加 symlink（`ln -s ../../../nscscc-solo-la-soc/rtl/ip/myCPU/新文件.sv src/soc/myCPU/`），否则 CI HDL Lint 会报 `Cannot find file containing module`。Verilator 仿真不走此路径，故此类遗漏不会在仿真中暴露。

## 2. CPU 设计

### 架构

- **流水线**：五级双发射顺序流水线（IF2/ID2/EX2/MEM2/WB2，2026-08-03 起），深度 3 取指队列，4R2W 寄存器堆，双 EX（EX0 全功能 / EX1 纯 ALU），共享单 LSU，含数据转发与流水线冒险控制
- **寄存器文件**：32 个 32 位通用寄存器 (r0 恒为 0)，含 write-bypass
- **总线接口**：AXI4 Master（通过 `core_top` 封装 SoC 接口）
- **特权级**：支持 DMW 直接映射地址翻译 (DA/PG 模式切换)，CRMD/DMW0/DMW1 可编程

### Cache 与数据访存

- **icache**：直接映射、64 组、16 字节行、1KB、只读；**0-cycle 命中**（标签 LUTRAM + 数据组合读取，`addr_ok`+`data_ok`+数据同拍响应，fetch 延迟 2 拍 → 0 拍）
- **数据访存（无 dcache，2026-08-04 起）**：LSU 直通 AXI 仲裁器 → `axi_sram_direct` 在 **cpu_clk 直驱异步 SRAM 引脚**（BaseRAM/ExtRAM），固定时序——读 2 拍（地址稳定后采样），写 3 拍（地址/数据建立 + WE 脉冲 + 保持；真 SRAM 在 WE 下降沿锁存地址，同拍驱动会导致写错位）。完全绕开原 AXI CDC / crossbar / axi2sram 链路（~16-20 拍）与人为延迟校准（EXTRA_LATENCY）
- **写缓冲（4 项 FIFO，store→load 转发）**：store 接受即完成（LSU ~1 拍退休），后台 3 拍排空；load 按字节匹配 FIFO 中最新 store——全覆盖的 load 1 拍完成不碰 SRAM（RMW 模式最快路径），部分覆盖则 SRAM 读 + 合并
- **MMIO（UART/confreg）**：地址不在 SRAM 范围（0x1c000000-0x1c7fffff）时经原 AXI CDC + crossbar 转发，不受影响
- **CACOP**：仅 `cacop 0x00` (I$ 索引无效) 生效；`CPUCFG.0x10` bit2 = 0（无 D-cache），内核自动跳过 dcache 初始化与 FLUSH_DCACHE
- **IBAR**：支持 hint=0 流水线冲刷
- **Cacheability**：基于 CRMD/DMW 区分 cacheable/uncacheable，支持 auto 和 uncache 两种 kernel 构建（无 dcache 后 cacheable 仅用于 icache 判定）

> **历史**：2026-07-25 ~ 2026-08-02 的两级 dcache 方案（8KB 0-cycle L1 + 1MB BRAM L2，hit-under-miss、word-sector 填充等）已由直连 SRAM 取代并移除（`l1dcache.sv`/`l2dcache.sv` 保留在树中但未实例化）。直连方案下缓存命中优势（0-2 拍）被 2 拍直连追平，而 miss 的 L2 REQ/RESP + 换出写回机械开销成为净负担——cryptonight IPC 0.3854 → 0.7974（+107%），四测试合计周期约减半。详细记录见 [DEVLOG.md](DEVLOG.md)。


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
| Cache 维护 | `cacop 0x00`（仅 I$；D$ 已无）、`ibar` |

### 模块清单 (`nscscc-solo-la-soc/rtl/ip/myCPU/`)

| 文件 | 功能 |
|------|------|
| `common.sv` | LA32R 基础类型定义 |
| `core.sv` | 五级双发射流水线顶层，例化全部子模块 |
| `pipeline_reg.sv` | 通用流水线寄存器 (stall/flush) |
| `regfile.sv` | 4R2W 寄存器文件 (r0=0)，含 write-bypass |
| `csr_regfile.sv` | 26 个 CSR 寄存器文件 + DMW 存储 |
| `decode.sv` | 指令译码 |
| `alu.sv` | 32 位 ALU |
| `bcu.sv` | 分支条件判断 |
| `branch_predictor.sv` | 分支预测器 (BTFNT) |
| `npc.sv` | 下一 PC 计算 |
| `fetch_unit.sv` | 取指单元 |
| `lsu.sv` | 访存单元 |
| `axi_sram_direct.sv` | 直连异步 SRAM 控制器：AXI 从端 + 4 项写缓冲 + store→load 转发 + 3 拍写/2 拍读 |
| `ram_sdpram.sv` | 单读口 RAM 封装（READ_LATENCY 0/1，推断 LUTRAM/BRAM，icache 存储用） |
| `icache.sv` | 指令 Cache（直接映射、1KB、只读） |
| `hazard_unit.sv` | 流水线冒险控制 |
| `axibus_arbiter.sv` | ibus/dbus AXI4 仲裁 |
| `core_top.sv` | AXI Master 接口封装 + L1/L2 dcache 旁路（无 dcache） |

> `l1dcache.sv` / `l2dcache.sv`（两级 dcache，2026-07-25 ~ 2026-08-02）保留在树中但**不再实例化**，由直连 SRAM + 写缓冲取代。历史记录见 [DEVLOG.md](DEVLOG.md)。

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

## 4. 验证

指令级差分测试（difftest，DUT vs NEMU 逐拍比对）6/6 全部通过：阶段 1-5 功能测试 + fibonacci，含 ExtRAM 数据比对（matrix/stream/cryptonight/mixed）。基准 IPC（Verilator difftest，100MHz）：matrix 0.448 / stream 0.496 / mixed 0.593 / cryptonight 0.744。测试方法见第 6/7 节，历史记录见 [DEVLOG.md](DEVLOG.md)。

**上板实测（100MHz，2026-08-05）**：Matrix 126ms / Stream 80ms / Cryptonight 311ms / Mixed 6ms（相对 90MHz 基线 140/89/345/6ms，比例 ≈90/100，IPC 无损失）。

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
| `DifftestCacheState` | 缓存性能计数器（ICache 全量；DCache 在无 dcache 方案下为 0） |
| `DifftestBranchState` | 分支预测性能计数器（total_branches/mispredictions） |
| `DifftestStallState` | 流水线 stall 7 类拆解（DCache/ICache Refill, Load-Use, Branch Flush, Cache Hit Pipe, Other；无 dcache 后 DCache 类恒 0） |

### 仿真结束时输出

difftest 正常退出时自动输出：

- **IPC**：`指令数 / 总周期数`
- **FPGA 运行时估测**：`总周期数 / 50MHz`（cpu_clk 频率；直连方案无 EXTRA_LATENCY 校准，即为真实时序）
- **ICache 指标**：访问数 / hit / miss / 命中率
- **DCache 指标**：无 dcache 方案下恒 0（保留接口）
- **分支预测指标**：条件分支数 / 误预测数 / 准确率
- **流水线 Stall 拆解**：按优先级 DCache Refill > ICache Refill > Load-Use > Branch Flush > DCache Hit Pipe > ICache Hit Pipe > Other，输出各类周期数和占 stall 周期百分比

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

> ⚠ 提交 CI 一律使用 `scripts/submit-ci.sh`（自动基于 `gitlab/main` 建分支并展开 `src/soc/` 符号链接）。**禁止直接 `git push gitlab <开发分支>`**（pre-receive 钩子会拒绝）。新增 RTL 文件时需先在 `src/soc/` 补同名 symlink。详见 [docs/CI-WORKFLOW.md](docs/CI-WORKFLOW.md)。

```bash
# 一键提交
./scripts/submit-ci.sh

# 指定分支名
./scripts/submit-ci.sh submit-v4
```

CI 流水线：HDL Lint → Vivado 综合+实现 → 时序检查（WNS ≥ 0）→ 生成比特流。历次提交与上板记录见 [DEVLOG.md](DEVLOG.md)。

详细工作流见 [docs/CI-WORKFLOW.md](docs/CI-WORKFLOW.md)。

## 10. DEVLOG

开发进度与已知问题见 [DEVLOG.md](DEVLOG.md)。
