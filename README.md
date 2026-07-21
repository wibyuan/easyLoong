# easyLoong — NSCSCC 2026 龙芯杯个人赛 (LoongArch)

基于 XC7A200T-2FBG676C FPGA 的 LoongArch 32-bit (LA32R) 精简版 CPU 实现。

## 1. 项目组成结构

```text
.
|-- asm/                       # 汇编测试程序，make -C asm → .bin
|-- src/
|   |-- soc/                   # ★ CPU SoC 源码（顶层 thinpad_top 与 core_top）
|   |   |-- cpu/               #   CPU 核心模块（五级流水线）
|   |   `-- xilinx_ip/         # Xilinx IP (.xci)
|   `-- vivado_cannot/         # 不可综合源码说明
|-- difftest/                  # ★ differential test 框架
|   |-- difftest.v             #   DPI-C Verilog wrapper 模块
|   |-- difftest_interface.cpp/h  # DPI-C C++ 桥接
|   |-- difftest_dut.cpp/h        # difftest 步进/比对逻辑
|   `-- Makefile                  # 构建 la32r-nemu .so
|-- la32r-nemu/                # [submodule] LA32R NEMU 参考模型
|-- run_vivado/
|   |-- constraints/           # 引脚约束 (thinpad_top.xdc)
|   |-- simulation/            # 仿真模型 (SRAM/Flash)
|   `-- flow/                  # ★ 受控 CI 脚本（不可修改）
|-- nscscc-solo-la-soc/        # 官方 SoC 仿真框架 (Verilator/XSIM)
|   `-- sdk/software/examples/
|       `-- supervisor/        # LA32R 监控程序与测试用例
|-- docs/
|   |-- *.pdf                  # 原始参考文档（⚠ 公开前须从 git 历史中彻底删除）
|   |-- md/                    # PDF 的 OCR 翻译 + 指令编码表 + 原理图要点
|   `-- html/                  # 平台评测题目（阶段 1-5）
`-- README.md
```

## 2. CPU 设计

### 架构

- **流水线**：五级经典流水线 (IF → ID → EX → MEM → WB)，含数据转发与流水线冒险控制
- **数据通路**：32 位
- **寄存器文件**：32 个 32 位通用寄存器 (r0 恒为 0)
- **总线接口**：AXI4 Master（通过 `core_top` 封装 SoC 接口）
- **特权级**：当前仅支持 M-mode 直接地址模式

### 指令集覆盖

按 supervisor 无 cache 模式最小要求实现，首批计划 18 条指令：

| 类别 | 已实现指令 |
|------|-----------|
| 立即数计算 | `lu12i.w`, `pcaddu12i` |
| 立即数 ALU | `addi.w`, `andi`, `ori`, `xori`, `slti`, `sltui` |
| 寄存器 ALU | `add.w`, `sub.w`, `slt`, `sltu`, `and`, `nor`, `or`, `xor`, `sll.w`, `srl.w`, `sra.w` |
| 移位立即数 | `slli.w`, `srli.w`, `srai.w` |
| 访存 | `ld.b`, `ld.h`, `ld.w`, `ld.bu`, `ld.hu`, `st.b`, `st.h`, `st.w` |
| 跳转/分支 | `b`, `bl`, `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`, `jirl` |

### 模块清单 (`src/soc/cpu/`)

| 文件 | 功能 |
|------|------|
| `common.sv` | LA32R 基础类型定义（word_t、alu_op_t、br_type_t、总线结构体） |
| `core.sv` | 五级流水线顶层，例化全部子模块并连接各级寄存器 |
| `pipeline_reg.sv` | 通用流水线寄存器，支持 stall / flush |
| `regfile.sv` | 32×32 位寄存器文件（r0 硬连线为 0） |
| `decode.sv` | 指令译码（casez 模式匹配 LA32R 编码格式） |
| `alu.sv` | 32 位 ALU（加减、逻辑、移位、LUI/PCADD） |
| `bcu.sv` | 分支条件判断（BEQ/BNE/BLT/BGE/BLTU/BGEU） |
| `npc.sv` | 下一 PC 计算（分支/跳转/顺序） |
| `fetch_unit.sv` | 取指单元，通过 ibus 发起读请求 |
| `lsu.sv` | 访存单元，支持 byte/half/word 读写、符号/无符号扩展 |
| `hazard_unit.sv` | 流水线冒险控制（load-use 停顿、跳转冲刷） |
| `axibus_arbiter.sv` | ibus/dbus → AXI4 读写仲裁器 |

### 顶层封装

- `src/soc/core_top.sv` — AXI Master 接口封装，例化 `core` + `axibus_arbiter`
- `src/soc/thinpad_top.v` — Vivado 开发板顶层（待接入 `core_top`）

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

| 阶段 | 类型 | 说明 | 状态 |
|------|------|------|------|
| 1 | 功能测试 | 斐波那契数列（裸机，6 条基础指令） | 🔧 difftest 通过，UART 待调通 |
| 2 | MATRIX | Monitor 运行，矩阵乘加 | ⬜ |
| 3 | STREAM | Monitor 运行，~3MiB 连续访存 | ⬜ |
| 4 | CRYPTONIGHT | Monitor 运行，2MiB 内存访问 + 整数运算 | ⬜ |
| 5 | MIXED | Monitor 运行，混合运算 | ⬜ |

> **评测方式**：脚本将测试程序写入 BaseRAM → 释放复位 → CPU 运行后将结果写入 ExtRAM → 脚本读回比对。不通过 UART 输出判定结果。
> **指令集最终要求**：以 supervisor README 为准。

## 5. 开发环境搭建

### Clone 仓库（含子模块）

```bash
git clone --recurse-submodules <this-repo-url>
cd easyLoong
```

如果已 clone 但缺少子模块：

```bash
git submodule update --init --recursive
```

### LA32R 交叉编译工具链

使用 nscscc 提供的下载脚本安装：

```bash
cd nscscc-solo-la-soc/sdk/toolchains
bash init.sh
```

> 根目录 Makefile 已内置工具链路径，无需手动设 `PATH`。

### 构建

```bash
make build
```

自动完成 NEMU 参考模型编译 + supervisor 软件构建。产物在 `nscscc-solo-la-soc/sdk/software/examples/supervisor/build/` 下，包括：

- `build/kernel/auto/axi_ram.mif` —— 默认 kernel（自适应 cache）
- `build/kernel/uncache/axi_ram.mif` —— 强制 uncache kernel（当前阶段使用）
- `build/kernel/auto/utest_symbols.txt` —— 性能测试入口地址
- `build/utility/` —— 各测试的输入、期望结果和 MIF

### CPU 源文件及 difftest 软链接

nscscc 仿真框架要求 CPU 源文件位于 `rtl/ip/myCPU/`。从 easyLoong 根目录执行：

```bash
# 清旧链接后重建
rm -f nscscc-solo-la-soc/rtl/ip/myCPU/*.sv nscscc-solo-la-soc/rtl/ip/myCPU/difftest.v
for f in src/soc/cpu/*.sv; do
    ln -sf "$(realpath "$f")" "nscscc-solo-la-soc/rtl/ip/myCPU/$(basename "$f")"
done
ln -sf "$(realpath src/soc/core_top.sv)" nscscc-solo-la-soc/rtl/ip/myCPU/core_top.sv
ln -sf "$(realpath difftest/difftest.v)" nscscc-solo-la-soc/rtl/ip/myCPU/difftest.v

# difftest C++ 文件软链接
ln -sf "$(realpath difftest/difftest_interface.h)" nscscc-solo-la-soc/sim/verilator/difftest_interface.h
ln -sf "$(realpath difftest/difftest_interface.cpp)" nscscc-solo-la-soc/sim/verilator/difftest_interface.cpp
ln -sf "$(realpath difftest/difftest_dut.h)" nscscc-solo-la-soc/sim/verilator/difftest_dut.h
ln -sf "$(realpath difftest/difftest_dut.cpp)" nscscc-solo-la-soc/sim/verilator/difftest_dut.cpp
```

## 6. Difftest 差分测试

### 原理

difftest 框架在 Verilator 仿真中引入 loongarch32r NEMU 作为 golden reference model。
每个时钟周期，CPU 的五级流水线 WB 级提交一条已退休指令，通过 DPI-C
将 DUT 的 GPR/CSR 状态传入 C++ 层，同时步进 NEMU 执行同一条指令，
逐条比对寄存器状态。任何不一致立即报告并退出。

### 快速开始

从 easyLoong 根目录直接运行：

```bash
make test-simple       # 冒烟测试（difftest 默认开启）
make test-fibonacci    # 斐波那契测试
make test-matrix       # 矩阵乘加
make test-stream       # 连续访存
make test-cryptonight  # 密码学运算
make test-mixed        # 混合运算
make test-all          # 全部 6 个测试
make test-fibonacci DIFF=0  # 关闭 difftest，仅仿真
```

每条命令自动完成 NEMU + supervisor 构建，无需手动准备。`test-all` 中单个测试失败不中断后续。

### 可用测试场景

| 目标 | 说明 |
|------|------|
| `test-simple` | 基础冒烟测试 |
| `test-fibonacci` | 阶段 1：UART 交互 + 斐波那契 |
| `test-matrix` | 阶段 2：矩阵乘加 |
| `test-stream` | 阶段 3：连续访存 |
| `test-cryptonight` | 阶段 4：密码学运算 |
| `test-mixed` | 阶段 5：混合运算 |

### 手动构建参考模型

```bash
make build-nemu
# 产物: la32r-nemu/NEMU/build/la32r-nemu-interpreter-so
```

### 手动运行（底层命令）

如需精确控制参数，可直接调用 run.py：

```bash
# 准备软件
cd nscscc-solo-la-soc/sdk/software/examples/supervisor && ./build_all.sh && cd -

# 运行仿真（通过 run.py 透传 plusarg）
python3 nscscc-solo-la-soc/sim/run.py \
    nscscc-solo-la-soc/sdk/software/examples/supervisor/sim/cases/simple.json \
    -- \
    +diff_so=la32r-nemu/NEMU/build/la32r-nemu-interpreter-so \
    +diff_img=path/to/binary.bin

# 或直接调用 Verilator 二进制
nscscc-solo-la-soc/sim/verilator/obj_dir/Vverilator_tb \
    +base_ram_mif=path/to/axi_ram.mif \
    +diff_so=la32r-nemu/NEMU/build/la32r-nemu-interpreter-so \
    +diff_img=path/to/binary.bin \
    +supervisor_entry=0x1c000000 \
    +max_time=10000000
```

### DPI-C 接口

| Verilog 模块 | DPI-C 函数 | 功能 |
|-------------|-----------|------|
| `DifftestArchIntRegState` | `v_difftest_ArchIntRegState` | 32 个 GPR（含组合逻辑旁路） |
| `DifftestInstrCommit` | `v_difftest_InstrCommit` | WB 级提交信息（pc, instr, wen, wdest, wdata） |
| `DifftestCSRState` | `v_difftest_CSRState` | 26 个 CSR 字段（当前硬编码默认值） |
| `DifftestIdlePC` | `v_difftest_IdlePC` | 已提交指令的 PC，用于 regcpy 缓冲区对齐 |
| `DifftestTrapEvent` | `v_difftest_TrapEvent` | 陷阱事件 |

### 当前比对范围

GPR[0..31] + 26 个 CSR 字段 + idle_pc（完整 236 字节 regcpy 缓冲区）。

框架已通过 Verilator 编译，所有 DPI-C 调用正常执行。difftest 可检测并报告
DUT 与 NEMU 之间逐条指令的寄存器差异，任何不一致立即 ABORT 退出。

### 调试实践

从 easyLoong 根目录运行：

```bash
make test-fibonacci       # difftest 模式（默认）
make test-fibonacci DIFF=0 # 仅仿真，不比对
```

**常见过程**：

1. 首次运行 `make test-fibonacci` 自动完成 NEMU + supervisor 构建 + difftest 仿真
2. difftest 逐条比对 GPR[0..31] + CSR + idle_pc，任何不一致立即报告 "different at pc=..." 并 abort

**底层命令**（如需精确控制）：在 `nscscc-solo-la-soc/` 目录下运行：

```bash
cd nscscc-solo-la-soc

python3 sim/run.py sdk/software/examples/supervisor/sim/cases/fibonacci.json -- \
    +diff_so=../la32r-nemu/NEMU/build/la32r-nemu-interpreter-so \
    +diff_img=sdk/software/examples/supervisor/build/kernel/uncache/kernel.bin
```

**首次运行时的预期**：

- difftest 输出 `state synced at startup` 表示初始同步完成
- 裸机测试中，CSR 字段在 supervisor 写 CSR 之前应一致（DUT 硬编码与 NEMU 默认值对齐）
- 若测试中 supervisor 写 CSR，CSR 字段会触发 difftest 报告，这指明下一步需对接完整的 CSR 读写

**临时 debug 打印**：如需逐条观察，可在 `difftest_dut.cpp:checkregs` 处加 `fprintf` 打印 `pc` 和关键 `gpr` 值，调试完毕后清理。

> **注意**：`DifftestTrapEvent` 模块仅在 `difftest.v` 中定义，未在 `core.sv` 中实例化，
> 其 DPI 函数 `v_difftest_TrapEvent` 当前未被调用。待后续需要处理异常/中断 difftest 时接入。

> CSR 当前在 DUT 侧硬编码为复位默认值（CRMD=0x00000008, ASID=0x000A0000, 其余为 0）。
> supervisor 初始化期间写入 CSR 后 NEMU 状态与 DUT 状态必然不一致，
> difftest 将精确报告差异位置，这指明了 CPU 下一步需实现的 CSR 功能。

## 7. Verilator 仿真

### 前置条件

- Verilator >= 5.0
- Python 3 + numpy
- 已完成 myCPU 软链接
- （工具链路径由根目录 Makefile 自动处理）

### 运行单个测试

```bash
make test-simple          # difftest 模式（默认）
make test-simple DIFF=0   # 仅仿真，不比对
```

强制重新编译 RTL（修改 CPU 源码后）：

```bash
FORCE_VERILATOR_REBUILD=1 make test-simple
```

### 运行全部回归

```bash
make test-all
```

### 可用测试场景

| 目标 | JSON 文件 | 说明 |
|------|-----------|------|
| `test-simple` | `cases/simple.json` | 基础冒烟测试 |
| `test-fibonacci` | `cases/fibonacci.json` | 阶段 1：UART 交互 + 斐波那契 |
| `test-stream` | `cases/stream.json` | 阶段 3：连续访存 |
| `test-matrix` | `cases/matrix.json` | 阶段 2：矩阵乘加 |
| `test-cryptonight` | `cases/cryptonight.json` | 阶段 4：密码学运算 |
| `test-mixed` | `cases/mixed.json` | 阶段 5：混合运算 |

## 8. Vivado 本地流程

```bash
make -C asm
vivado -mode batch -source run_vivado/flow/create_vivado_project.tcl
vivado -mode batch -source run_vivado/flow/implement_design.tcl
vivado -mode batch -source run_vivado/flow/generate_bitstream.tcl
```

### RTL 规范

- 所有设计源码放在 `src/soc/`，顶层模块固定为 `thinpad_top`
- CPU 核封装为 `core_top` 模块（AXI master 接口），由 `thinpad_top` 与
  nscscc 仿真框架共用
- `nscscc-solo-la-soc/rtl/ip/myCPU/` 下为软链接，指向 `src/soc/cpu/` 和 `src/soc/core_top.sv`
- 不自建 Vivado IP 目录，`.xci` 放 `src/soc/xilinx_ip/<name>/`
- 不提交 `ip_user_files/`、`.runs/`、`.cache/` 等中间产物

## 9. 提交规范

### 可修改

```
src/soc/**  src/vivado_cannot/**  run_vivado/constraints/**  asm/**  difftest/**  README.md  design.pdf
```

### 受控（不可修改）

```
run_vivado/flow/**
```

> 注：`nscscc-solo-la-soc` 已从 submodule 转为仓库内直接维护（difftest 集成导致改动较大）。
> 如需与上游同步，可通过 diff/patch 进行选择性合并。

> **公开前须知**：repo 公开前，须向主办方请示哪些内容可以公开。
> `docs/` 及工具链二进制须从 git 历史中彻底删除。
