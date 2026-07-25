# easyLoong — NSCSCC 2026 龙芯杯个人赛 (LoongArch)

基于 XC7A200T-2FBG676C FPGA 的 LoongArch 32-bit (LA32R) 精简版 CPU 实现。

## 致谢

本项目引用了以下开源仓库：

- [loongsonlab/la32r-nemu](https://gitee.com/loongsonlab/la32r-nemu) — LoongArch32-Reduced NEMU 参考模型
- [loongson-edu/nscscc-solo-la-soc](https://gitee.com/loongson-edu/nscscc-solo-la-soc) — NSCSCC 龙芯杯 SoC 仿真与上板框架

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
├── difftest/                    # ★ Differential test 框架 (DPI-C)
├── la32r-nemu/                  # NEMU 参考模型（项目自有代码）
├── docs/                        # 参考文档、评测说明
├── Makefile                     # 根构建/测试入口
├── DEVLOG.md                    # 开发进度
└── README.md
```

## 2. CPU 设计

### 架构

- **流水线**：五级经典流水线 (IF → ID → EX → MEM → WB)，含数据转发与流水线冒险控制
- **寄存器文件**：32 个 32 位通用寄存器 (r0 恒为 0)，含 write-bypass
- **总线接口**：AXI4 Master（通过 `core_top` 封装 SoC 接口）
- **特权级**：支持 DMW 直接映射地址翻译 (DA/PG 模式切换)，CRMD/DMW0/DMW1 可编程

### Cache 系统

- **icache**：2 路组相联、256 组、16 字节行、8KB、只读、PLRU、关键字优先
- **dcache**：2 路组相联、256 组、16 字节行、8KB、写回+写分配、PLRU、关键字优先
- **CACOP**：支持 `cacop 0x00` (I$ 索引无效)、`cacop 0x01` (D$ 索引无效)、`cacop 0x09` (D$ 索引写回无效)
- **IBAR**：支持 hint=0 流水线冲刷
- **Cacheability**：基于 CRMD/DMW 区分 cacheable/uncacheable，支持 auto 和 uncache 两种 kernel 构建

> **已知 Workaround**：ICache/DCache 的幽灵命中修复目前通过每次 hit 后强清 S1 流水级实现，等效于 hit 后 1 周期强制空泡，降低 cache 吞吐。正确做法应取消 `s1_valid` 清零，改为在 S2 阶段直接对 BRAM 读出做组合逻辑 tag 比较。见 DEVLOG 待完成列表。

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
| 4 | CRYPTONIGHT | 2 MiB 内存访问 + 整数运算 | ✅ DIFF=1 通过 | ✅ 通过 |
| 5 | MIXED | 混合运算 | ✅ DIFF=1 通过 | ✅ 通过 |
| fibonacci | 自修改代码 | UART 加载 + FLUSH_DCACHE + 执行 | ✅ DIFF=1 通过 | ✅ 通过 |

> 阶段 1-5 + fibonacci 的 difftest 和数据比对均已全部通过。

### 当前性能指标（Verilator difftest 估测 vs 实板）

| 测试 | 指令数 | 周期数 | IPC | 估测耗时 | 实板耗时 | 偏差 |
|------|--------|--------|-----|----------|----------|------|
| Mixed | 328K | 2.94M | 0.112 | 89 ms | 88 ms | +1.1% |
| Matrix | 5.64M | 44.42M | 0.127 | 1346 ms | 1391 ms | -3.2% |
| Stream | 3.95M | 48.91M | 0.081 | 1482 ms | 1524 ms | -2.8% |
| Cryptonight | 23.09M | 261.72M | 0.088 | 7931 ms | 8387 ms | -5.4% |

> 估测公式：`runtime = total_cycles / 33MHz`（cpu_clk 经 PLL XCI 确认为 33 MHz）。
> 偏差系统性为负（Verilator 无 bus contention、无跨时钟域延迟、无物理走线延迟）。

### Cache 命中率（Verilator 仿真）

| 测试 | ICache 访问 | ICache 命中率 | DCache 访问 | DCache 命中率 | DCache 写回 |
|------|------------|--------------|------------|--------------|------------|
| Mixed | 732K | 99.98% | 66K | 70.46% | 62K words |
| Matrix | 11.10M | 100.00% | 2.66M | 91.26% | 885K words |
| Stream | 12.23M | 100.00% | 1.57M | 75.00% | 787K words |
| Cryptonight | 65.43M | 100.00% | 4.72M | 52.95% | 8.88M words |

> Cryptonight 的 DCache 命中率仅 53%，大量随机访存导致频繁 miss + 写回，与算法特征一致。

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

### 仿真结束时输出

difftest 正常退出时自动输出：

- **IPC**：`指令数 / 总周期数`
- **FPGA 运行时估测**：`总周期数 / 33MHz`（cpu_clk 频率）
- **ICache 指标**：访问数 / hit / miss / 命中率
- **DCache 指标**：访问数 / hit / miss / 命中率 / 写回 word 数

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

详细工作流见 [docs/CI-WORKFLOW.md](docs/CI-WORKFLOW.md)。

## 10. DEVLOG

开发进度与已知问题见 [DEVLOG.md](DEVLOG.md)。
