# easyLoong — NSCSCC 2026 龙芯杯个人赛 (LoongArch)

基于 XC7A200T-2FBG676C FPGA 的 LoongArch 32-bit (LA32R) 精简版 CPU 实现。

## 致谢

本项目引用了以下开源仓库：

- [loongsonlab/la32r-nemu](https://gitee.com/loongsonlab/la32r-nemu) — LoongArch32-Reduced NEMU 参考模型
- [loongson-edu/nscscc-solo-la-soc](https://gitee.com/loongson-edu/nscscc-solo-la-soc) — NSCSCC 龙芯杯 SoC 仿真与上板框架
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

- **icache**：2 路组相联、256 组、16 字节行、8KB、只读、PLRU、关键字优先；**0-cycle 命中**（标签 LUTRAM + 数据组合读取，`addr_ok`+`data_ok`+数据同拍响应，fetch 延迟 2 拍 → 0 拍）
- **数据访存（无 dcache，2026-08-04 起）**：LSU 直通 AXI 仲裁器 → `axi_sram_direct` 在 **cpu_clk 直驱异步 SRAM 引脚**（BaseRAM/ExtRAM），固定时序——读 2 拍（地址稳定后采样），写 3 拍（地址/数据建立 + WE 脉冲 + 保持；真 SRAM 在 WE 下降沿锁存地址，同拍驱动会导致写错位）。完全绕开原 AXI CDC / crossbar / axi2sram 链路（~16-20 拍）与人为延迟校准（EXTRA_LATENCY）
- **写缓冲（8 项 FIFO，store→load 转发）**：store 接受即完成（LSU ~1 拍退休），后台 3 拍排空；load 按字节匹配 FIFO 中最新 store——全覆盖的 load 1 拍完成不碰 SRAM（RMW 模式最快路径），部分覆盖则 SRAM 读 + 合并
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
| `axi_sram_direct.sv` | 直连异步 SRAM 控制器：AXI 从端 + 8 项写缓冲 + store→load 转发 + 3 拍写/2 拍读 |
| `ram_sdpram.sv` | 单读口 RAM 封装（READ_LATENCY 0/1，推断 LUTRAM/BRAM，icache 存储用） |
| `icache.sv` | 指令 Cache（2 路组相联、8KB、只读） |
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

## 4. 评测阶段

| 阶段 | 类型 | 说明 | 指令级 difftest | 数据比对 |
|------|------|------|----------------|----------|
| 1 | 功能测试 | 斐波那契数列（裸机） | ✅ DIFF=1 通过 | N/A |
| 2 | MATRIX | 矩阵乘加 (96×96, 64KB) | ✅ DIFF=1 通过 | ✅ 通过 |
| 3 | STREAM | ~3 MiB 连续访存 | ✅ DIFF=1 通过 | ✅ 通过 |
| 4 | CRYPTONIGHT | 2 MiB 内存访问 + 整数运算 | ✅ DIFF=1 通过 | ✅ Verilator 通过<br>⚠ 直连方案上板验证中 |
| 5 | MIXED | 混合运算 | ✅ DIFF=1 通过 | ✅ 通过 |
| fibonacci | 自修改代码 | UART 加载 + 执行 | ✅ DIFF=1 通过 | ✅ 通过 |

> 阶段 1-5 + fibonacci 的 difftest 和数据比对均已全部通过（2026-08-04 直连 SRAM + 无 dcache 方案）。

### 当前性能指标（Verilator difftest, 2026-08-04，**直连异步 SRAM + 无 dcache + 写缓冲**）

| 测试 | 指令数 | difftest 周期 | difftest IPC | 50MHz 折算 | 旧基线（AXI+两级cache）IPC |
|------|--------|--------|----------------|:---:|:---:|
| simple | ~804K | 1.38M | 0.5841 | 27.6 ms | 0.5818 |
| fibonacci | 111,173 | 0.84M | 0.1328 | 16.7 ms | 0.1265 |
| stream | 3,951,032 | 7.98M | 0.4951 | 159.6 ms | 0.2543 |
| matrix | 5,641,498 | 12.60M | 0.4476 | 252.1 ms | 0.7179 |
| mixed | 326,060 | 0.50M | 0.6503 | 10.1 ms | 0.5070 |
| cryptonight | 23,087,552 | 28.96M | **0.7974** | 579.1 ms | 0.3854 |

> 旧基线 = 原 AXI CDC 链路 + 两级 dcache（2026-08-03，上板四测试 1932ms）。直连 SRAM（2 拍读/3 拍写）+ 无 dcache + 写缓冲后：cryptonight +107%、stream +95%、mixed +28%、matrix -38%（其工作集原先吃缓存命中）——**四测试 difftest 周期合计约减半**。矩阵/流等指令数差异 = 内核 FLUSH_DCACHE walk（65,536 步 cacop）在无 dcache 时被正确跳过。difftest 已无人为延迟校准（EXTRA_LATENCY 移除），周期数即真实时序。**上板实测待验证**（CI `submit-nodcache-wb`）。

### 分支预测准确率（BTFNT, Verilator 仿真, 2026-08-02）

| 测试 | 条件分支数 | 误预测数 | 准确率 |
|------|-----------|----------|--------|
| Simple | 5,554 | 819 | 85.25% |
| Stream | 791,986 | 820 | 99.90% |
| Matrix | 245,363 | 10,132 | 95.87% |
| Mixed | 42,418 | 4,950 | 88.33% |
| Cryptonight | 1,578,418 | 821 | 99.95% |
| Fibonacci | 17,966 | 330 | 98.16% |

> BTFNT (Backward Taken, Forward Not Taken) 静态预测器，独立模块 `branch_predictor.sv`。`DifftestBranchState` 通过 DPI-C 逐周期上报 `total_branches`（仅条件分支 BEQ/BNE/BLT/BGE/BLTU/BGEU）和 `mispredictions`（预测方向 ≠ 实际方向）。
>
> **BTFNT ID 级重定向已实现**：预测 taken 时在 ID 阶段通过 `bp_do_jump` 重定向 fetch，npc 在 EX 阶段抑制冗余 flush 并处理 misprediction 恢复。

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
| submit-20260731-1910 | ✅ 通过 | — | 0 | 2026-07-31 |
| submit-20260731-1950 | ❌ 综合失败（Vivado 2019.2 不接受 `!|` 语法） | — | — | 2026-07-31 |
| submit-20260731-1953 | ❌ 同上 | — | — | 2026-07-31 |
| submit-20260731-2005 | ⏳ CI 中（`37518fc` 修复后） | — | 0 | 2026-07-31 |
| submit-20260731-2221 | ✅ 通过 → **上板通过**（非阻塞 dcache） | — | 0 | 2026-07-31 |
| submit-20260731-2235 | ✅ 通过 → **上板失败**（写回/refill 重叠，全 50 分） | — | 0 | 2026-07-31 |
| submit-20260801-0734 | ✅ 通过 → 上板失败（XDC 时钟组通配符版，无效修复） | — | 0 | 2026-08-01 |
| submit-20260801-0824 | ✅ 通过 → 上板失败（XDC 显式引脚版，仍 50 分） | — | 0 | 2026-08-01 |
| submit-20260801-dcache1mb-v2 | ✅ 通过（1MB 全 BRAM dcache，295 BRAM，WNS 2.794） → **上板 cryptonight WaitStart 超时**（根因：HUM 一致性回归，见 DEVLOG 2026-08-02） | 2.794 | 0 | 2026-08-02 |
| submit-20260802-humfix-v2 | ✅ 通过（HUM 一致性修复：S_REFILL_WRITE 写口/响应/清除/dirty 门控 + HUM dirty/PLRU 恢复） → **上板全部通过**：matrix 209ms / stream 566ms / cryptonight 1367ms / mixed 35ms | — | 0 | 2026-08-02 |
| submit-20260802-2levelci3 | ✅ 通过（两级 dcache，`b838abb`，impl 恢复收敛） → **上板全部通过**：matrix 190ms / stream 419ms / cryptonight 1399ms / mixed 37ms（合计 2045ms，-6.1% vs 单级） | — | 0 | 2026-08-02 |

> **submit-20260731-2221**（`30e9c97`）：非阻塞 dcache（hit-under-miss，单 MSHR）。**上板全部测试通过**，为当时 master 版本。
>
> **submit-20260802-humfix-v2**（`0365302`）：1MB dcache 上板 WaitStart 超时根因定位为 **HUM 一致性回归**（3c8da53 重写相对 master 删除了 hum_ok 的 dirty/PLRU 更新，且 S_REFILL_WRITE 的 HUM store 写口/响应/清除/dirty 四处门控不一致）：refill 写口被 HUM store 覆盖丢 word、HUM store 不置 dirty 导致换出静默丢数据。修复后上板全过：matrix 209ms（-47% vs master）、cryptonight 1367ms（-15%）、stream 566ms（+28%，1 拍命中惩罚+16B 行）、mixed 35ms（+52%）。**REQP-1839/1840 复位窗口嫌疑排除**（2:1 仿真复现不可靠，且修复后上板通过）。详见 DEVLOG。
>
> **submit-20260731-2235**（`2c4f3298`）：写回/refill 重叠（IPC +12~26%）。上板**全部测试稳定 50 分**——程序能完整跑完但自校验失败，cryptonight 首个 mismatch 在 ExtRAM 首字节（actual=0x00, expected=0x51）。已回退（见 DEVLOG「写回/refill 重叠上板失败排查」）。
>
> **submit-20260801-0734/0824**：CI `soc.xdc` 时钟组修复两次尝试。本地复现证实原版 `get_pins -hierarchical *CLKOUT*` 在网表中匹配不到任何引脚（`set_clock_groups` 一直是空操作，cpu_clk↔sys_clk CDC 路径被当同步路径分析）；显式引脚版修复后本地 Inter-Clock 表跨时钟路径 199→0 条，但上板仍 50 分——CDC 约束缺陷非根因（详见证伪过程见 DEVLOG）。

> **submit-20260731-1910**：含 Bug 8 闭合三处修复 + 关联 bug 两处修复（fetch_unit WAIT_DATA 放弃 / icache keyword 地址门控 / keep_capture 收紧 / ID 重复下发门控）。综合、实现、时序全通过。
>
> **submit-20260731-1950/1953**：含 dcache load 快速路径。`!|cpu_req.strobe` 为合法 SystemVerilog（Verilator 接受），但 Vivado 2019.2 解析器报 `syntax error near |`，综合在 elaboration 阶段失败。`37518fc` 改为括号形式 `!(|cpu_req.strobe)` 修复。

> **submit-20260729-1747**：含 mul.w 16 位部分积分解 + CSR 读打拍 + EX mux 拆分。Synthesis WNS 5.388→7.728ns（+43%），DSP48E1 级联从关键路径消除，新最差路径转移至 dcache just_hit → pc_reg。IPC 不变。详见 DEVLOG。

> **submit-20260729-1630**：含 dcache S_STORE_FINAL 消除 + cpu_resp 拆分优化。Synthesis WNS 5.290→5.388ns，dcache 关键路径从 #1 跌至 #6+，新最差路径为 ALU(MUL)→CSR→ex_mem。详见 DEVLOG。

> **submit-20260729-1031**：含标签 LUTRAM 优化（`(* ram_style = "distributed" *)`）。HDL Lint、综合、布局均通过（0 Critical Warnings, Place WNS=0.564 ns），布线阶段超 1h CI 限制。详见 [DEVLOG.md](DEVLOG.md) 中时序优化注意事项。

详细工作流见 [docs/CI-WORKFLOW.md](docs/CI-WORKFLOW.md)。

## 10. DEVLOG

开发进度与已知问题见 [DEVLOG.md](DEVLOG.md)。

## 11. 历史：0-cycle icache 分支修复记录（2026-07-31 已合并至 master）

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
| `make test-simple` | ✅ 803,959 条，IPC 0.5202 |
| `make test-fibonacci` | ✅ 98,477 条，数据比对 PASS，IPC 0.1264 |
| `make test-stream/matrix/mixed/cryptonight` | ✅ 全通过，数据比对 PASS，IPC 0.2469/0.6324/0.4553/0.3594（两级 dcache，2026-08-02） |

> **2026-07-31 追加：DCache load 命中快速路径（0-cycle，镜像 icache）**——数据 RAM 组合读取端口 + fast-path cpu_resp 的 load 分支，load 命中同拍返回数据（store 快速路径 2026-07-29 已就位）。matrix IPC 0.3024→0.3730（+23.3%，load 密集），stream +6.7%，mixed +2.4%，simple +0.4%；cryptonight 不变（其 load 几乎全为 scratchpad 强制 miss，无命中可提速）。详见 DEVLOG。

详细根因分析与修复记录见 [DEVLOG.md](DEVLOG.md) 的「wip/icache-0cycle 分支修复记录（2026-07-31 续）」。
