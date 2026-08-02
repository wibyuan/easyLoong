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

- **流水线**：五级经典流水线 (IF → ID → EX → MEM → WB)，含数据转发与流水线冒险控制
- **寄存器文件**：32 个 32 位通用寄存器 (r0 恒为 0)，含 write-bypass
- **总线接口**：AXI4 Master（通过 `core_top` 封装 SoC 接口）
- **特权级**：支持 DMW 直接映射地址翻译 (DA/PG 模式切换)，CRMD/DMW0/DMW1 可编程

### Cache 系统

- **icache**：2 路组相联、256 组、16 字节行、8KB、只读、PLRU、关键字优先；**0-cycle 命中**（标签 LUTRAM + 数据组合读取，`addr_ok`+`data_ok`+数据同拍响应，fetch 延迟 2 拍 → 0 拍）
- **dcache**：2 路组相联、256 组、**8 字节行**（NR_WORDS=2）、4KB、写回+写分配、PLRU、关键字优先；**0-cycle 命中**（load/store 均旁路 S1/S2 流水线：标签 LUTRAM 组合比较 + 数据组合读取，请求拍内返回数据；miss 仍走 S1/S2 管道）
- **非阻塞（hit-under-miss，单 MSHR）**：请求拍内组合判定命中/缺失，store miss **当拍接受**（数据在 refill 写入阶段合并进新行，流水线在 refill 期间继续运行）；refill 期间命中其他行（load 恒可、store 在写口空闲时）同拍响应；**读回写**（store 命中正在 refill 的行）当拍接受并合并进 refill 写（第二合并槽，后写者优先）；load miss 当拍 `addr_ok` 应答，数据经关键字转发返回。无法处理的二次 miss 等待当前 refill 完成（单 MSHR 上限）
- **参数化**：dcache 支持 NR_SETS / NR_WAYS / NR_WORDS 三参数配置，组数/路数/行大小可独立调整（`core_top.sv` 的 `DCACHE_SETS/DCACHE_WAYS/DCACHE_WORDS`）。icache 同理。**CPUCFG.0x12 的缓存几何编码随参数化**（offset_bits/index_bits/max_way），NEMU 侧由 `scripts/build.mk` 的 `-DDCACHE_OFFSET_BITS/-DDCACHE_INDEX_BITS/-DDCACHE_MAX_WAY` 宏镜像——**换几何必须两侧同步，且 `rm -rf NEMU/build` 强制重编 NEMU**（make 不跟踪宏变化）。内核 FLUSH_DCACHE 按 CPUCFG 报告的几何遍历，几何不一致会导致收尾 dirty 行漏写回（2026-08-01 实测踩坑，见 DEVLOG）。
- **CACOP**：支持 `cacop 0x00` (I$ 索引无效)、`cacop 0x01` (D$ 索引无效)、`cacop 0x09` (D$ 索引写回无效)
- **IBAR**：支持 hint=0 流水线冲刷
- **Cacheability**：基于 CRMD/DMW 区分 cacheable/uncacheable，支持 auto 和 uncache 两种 kernel 构建

> 行宽实测结论（2026-08-01，三配置上板实测）：**8 字节行是总分最优**——cryptonight 1883ms（16B 2446 / 4B 1699），stream 473ms（16B 395 / 4B 756），matrix 444ms（16B 374 / 4B 578），四测试合计 8B 2825ms < 4B 3066ms < 16B 3240ms。4B 行对 cryptonight 最优但 stream/matrix 严重受损（空间局部性丢失）；8B 行是折中，定为新默认。2 路组相联对 cryptonight 无收益（容量 miss 主导）但保护 stream（1-way 下 0.2293→0.0669）。详见 [DEVLOG.md](DEVLOG.md)「DCache 行宽/相联度实测」。

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
| `dcache.sv` | 数据 Cache（2 路组相联、8B 行、4KB、写回） |
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

### 当前性能指标（Verilator difftest, 2026-08-01，**8B 行默认**，EXTRA_LATENCY=7 校准）

| 测试 | 指令数 | 周期数 | IPC (difftest) | 估计耗时（50MHz） | 上板实测 | 真实 IPC（上板） | 校准偏差 |
|------|--------|--------|----------------|-------------------|:---:|:---:|:---:|
| simple | 24,431 | 162,864 | 0.1488 | 3.3 ms | — | — | — |
| fibonacci | 96,857 | 714,295 | 0.1329 | 14.3 ms | — | — | — |
| stream | 3,956,595 | 21.79M | 0.1815 | 436 ms | **442 ms** | **0.1790** | -1.4% |
| matrix | 5,647,061 | 19.20M | 0.2941 | 384 ms | **391 ms** | **0.2888** | -1.8% |
| mixed | 331,623 | 1.21M | 0.2744 | 24.2 ms | **23 ms** | **0.2884** | +5.0% |
| cryptonight | 23,093,115 | 78.99M | **0.2923** | **1580 ms** | **1600 ms** | **0.2887** | **+1.3%** |

> 真实 IPC = 指令数 ÷ (上板耗时 × 50MHz)。**2026-08-01 并发写回/refill 重叠后**（读先发、写回 drain 与读在飞并行，load 关键字路径不含写回）：cryptonight 上板 1600ms（相对 16B 无并发 2446ms，**-35%**；8B 无并发 1883ms），matrix 391ms、stream 442ms、mixed 23ms——**全测试上板均优于无并发版本，且 difftest 估时与上板偏差 ≤5%**（cryptonight +1.3%，写回移出关键路径后校准更准）。行宽三配置（无并发）上板实测：cryptonight 16B 2446 / 8B 1883 / 4B 1699ms；stream 395 / 473 / 756ms；matrix 374 / 444 / 578ms——8B 行合计最优，定为默认；叠加并发写回后 8B 行合计再降 ~14%。非阻塞 dcache（store-miss 解耦 + hit-under-miss + 并发写回）完整路径见 [DEVLOG.md](DEVLOG.md)。

### 流水线 Stall 拆解（Verilator difftest, 2026-08-01，8B 行默认 + EXTRA_LATENCY=7 校准，占总周期 %）

| 类别 | Simple | Fibonacci | Stream | Matrix | Mixed | Cryptonight |
|------|:------:|:---------:|:------:|:------:|:-----:|:-----------:|
| DCache Refill | — | — | **80.41%** | **67.51%** | **63.20%** | **76.00%** |
| ICache Refill | — | — | 0.00% | 0.00% | 0.00% | 0.00% |
| Load-Use | — | — | 0.01% | 0.01% | 0.23% | 0.00% |
| Branch Flush | — | — | 0.01% | 0.05% | 0.46% | 0.00% |
| DCache Hit Pipe | — | — | 1.86% | 0.30% | 5.18% | 0.07% |
| ICache Hit Pipe | — | — | 0.21% | 0.22% | 3.66% | 0.05% |
| Other | — | — | 1.64% | 7.77% | 3.91% | 1.30% |

> 8B 行 refill 为 2-beat burst，关键字（首 beat）返回后剩余 beat 与流水线执行重叠（hit-under-miss 重新出现：cryptonight 262,180、stream 786,462），DCache Refill 仍是主瓶颈（load miss 关键字等待 + 单口 SRAM 串行读）。Simple/Fibonacci 的 Hit Pipe 占比高来自非缓存 UART 轮询与 uncache 内核。优化空间受单口 SRAM + 顺序提交约束（读时延无法并行/乱序隐藏），见 [DEVLOG.md](DEVLOG.md)「优化方向分析」。

### 分支预测准确率（BTFNT, Verilator 仿真, 2026-08-01，8B 行默认）

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
> **BTFNT ID 级重定向已实现**：预测 taken 时在 ID 阶段通过 `bp_do_jump` 重定向 fetch，npc 在 EX 阶段抑制冗余 flush 并处理 misprediction 恢复。IPC 提升见上方性能表。

### Cache 命中率（Verilator 仿真, 2026-08-01，8B 行默认）

| 测试 | ICache 访问 | ICache 命中率 | DCache 访问 | DCache 命中率 | DCache 写回 | hit-under-miss |
|------|------------|--------------|------------|--------------|------------|----------------|
| Simple | 34.6K | 98.04% | 403 | 81.89% | 43 words | 11 |
| Fibonacci | 144K | 99.90% | —（uncache 内核，dcache 旁路） | — | — | — |
| Stream | 4.75M | 99.99% | 1.57M | 50.01% | 786K words | **786,462** |
| Matrix | 6.14M | 99.99% | 2.89M | 84.19% | 885K words | 37 |
| Mixed | 383K | 99.82% | 66K | 50.99% | 48K words | 16,420 |
| Cryptonight | 24.68M | 95.75% | 4.72M | 50.09% | 4.71M words | **262,180** |

> 8B 行每行 2 word：cryptonight 命中率 50.09%（16B 52.95% / 4B 44.49%），stream 顺序流命中率大幅回升至 50.01%（4B 行 0.02%——相邻访问命中同一行）。hit-under-miss 在 8B 行下重新活跃（2-beat refill 的后续 beat 与流水线执行重叠）。

### 上板耗时校准（Verilator 固定 SRAM 时延）

上板实测与 difftest 折算不符（difftest 偏快）：板上 sys_clk=25MHz（cpu_clk=50MHz，2:1），SRAM 访问在 CPU 时钟域折合更多周期，而 Verilator 同源同频 1:1 未建模。在 `axi2sram_sp_external.v` 的 `ifdef VERILATOR` 分支给**每笔 SRAM 事务首拍**（读关键字 / 写首字）插入固定 `EXTRA_LATENCY=7` 周期等待（上板 RTL 不变），并对**每笔读事务后清零时延计数器**（否则连续读事务只有第一笔被限速，校准失效——2026-08-01 修复）。8B 行默认下标定：

| 基准 | difftest 估计 | 上板实测 | 偏差 |
|------|:---:|:---:|:---:|
| **cryptonight** | **2046ms** | 1883ms | **+8.7%** |
| matrix | 468ms | 444ms | +5.4% |
| stream | 499ms | 473ms | +5.5% |
| mixed | 28.4ms | 25ms | +13.5% |

> 校准后 difftest 估时与上板偏差 +5~14%（常量按 4B 行事务数标定，8B 行事务数减半、7 拍略偏大，可再标定但偏差已可用）。行宽三配置上板实测（2026-08-01）：cryptonight 16B 2446 / **8B 1883** / 4B 1699ms；stream 395 / **473** / 756ms；matrix 374 / **444** / 578ms；mixed 25 / **25** / 33ms——**8B 行四测试合计 2825ms 最优**，为默认配置。

### cryptonight 校准后指标（difftest, 2026-08-01，核心优化指标，**8B 行默认**）

| 指标 | 数值 |
|------|------|
| 指令 / 周期 / IPC | 23.09M / 102.28M / **0.2258** |
| 估计耗时（50MHz） | **2046ms**（上板 1883ms，+8.7%） |
| ICache | 24.68M 访问，95.75% 命中，s1_accept/cycle=0.9995 |
| DCache | 4.72M 访问，50.09% 命中，2.36M miss，写回 4.71M words，hit-under-miss 262,180 |
| 分支预测 | 1,578,418 分支，仅 821 误预测，**99.95% 准确率** |
| Stall 构成 | **DCache Refill 占 76.0% 总周期**（98.2% 的 stall 周期），其余 <1.4% |

> 行宽三配置上板实测：16B 2446ms / **8B 1883ms** / 4B 1699ms——4B 行对 cryptonight 单独最优，但 stream/matrix 受损严重（合计 8B 最优），故默认 8B。DCache Refill 仍是主瓶颈（load miss 关键字等待），受单口 SRAM + 顺序提交约束，读时延无法并行/乱序隐藏；进一步优化空间有限（容量/状态机开销，各 ~5%）。

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
| `DifftestCacheState` | ICache/DCache 性能计数器（hit/miss/access/writeback + dcache fast_path_load_hits + hit_under_miss_hits） |
| `DifftestBranchState` | 分支预测性能计数器（total_branches/mispredictions） |
| `DifftestStallState` | 流水线 stall 7 类拆解（DCache/ICache Refill, Load-Use, Branch Flush, Cache Hit Pipe, Other） |

### 仿真结束时输出

difftest 正常退出时自动输出：

- **IPC**：`指令数 / 总周期数`
- **FPGA 运行时估测**：`总周期数 / 50MHz`（cpu_clk 频率）
- **ICache 指标**：访问数 / hit / miss / 命中率
- **DCache 指标**：访问数 / hit / miss / 命中率 / 写回 word 数 / fast_path_load_hits（load 快速路径命中数）/ hit_under_miss_hits（refill 期间同拍服务的命中数，含读回写合并）
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

> **submit-20260731-2221**（`30e9c97`）：非阻塞 dcache（hit-under-miss，单 MSHR）。**上板全部测试通过**，为当前 master 版本。
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
| `make test-simple` | ✅ 24431 条，IPC 0.1669 |
| `make test-fibonacci` | ✅ 96857 条，数据比对 PASS，IPC 0.1360 |
| `make test-stream/matrix/mixed/cryptonight` | ✅ 全通过，数据比对 PASS，IPC 0.1587/0.2414/0.2336/0.2258（8B 行默认，2026-08-01） |

> **2026-07-31 追加：DCache load 命中快速路径（0-cycle，镜像 icache）**——数据 RAM 组合读取端口 + fast-path cpu_resp 的 load 分支，load 命中同拍返回数据（store 快速路径 2026-07-29 已就位）。matrix IPC 0.3024→0.3730（+23.3%，load 密集），stream +6.7%，mixed +2.4%，simple +0.4%；cryptonight 不变（其 load 几乎全为 scratchpad 强制 miss，无命中可提速）。详见 DEVLOG。

详细根因分析与修复记录见 [DEVLOG.md](DEVLOG.md) 的「wip/icache-0cycle 分支修复记录（2026-07-31 续）」。
