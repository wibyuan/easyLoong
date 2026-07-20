# easyLoong — NSCSCC 2026 龙芯杯个人赛 (LoongArch)

基于 XC7A200T-2FBG676C FPGA 的 LoongArch 32-bit (LA32R) 精简版 CPU 实现。

## 1. 项目组成结构

```text
.
|-- asm/                       # 汇编测试程序，make -C asm → .bin
|-- src/
|   |-- soc/                   # ★ CPU SoC 源码（顶层 thinpad_top 与 core_top）
|   |   `-- xilinx_ip/         # Xilinx IP (.xci)
|   `-- vivado_cannot/         # 不可综合源码说明
|-- run_vivado/
|   |-- constraints/           # 引脚约束 (thinpad_top.xdc)
|   |-- simulation/            # 仿真模型 (SRAM/Flash)
|   `-- flow/                  # ★ 受控 CI 脚本（不可修改）
|-- nscscc-solo-la-soc/        # [submodule] 官方 SoC 仿真框架 (Verilator/XSIM)
|   `-- sdk/software/examples/
|       `-- supervisor/        # [submodule] LA32R 监控程序与测试用例
|-- docs/
|   |-- *.pdf                     # 原始参考文档（⚠ 公开前须从 git 历史中彻底删除）
|   |-- md/                       # PDF 的 OCR 翻译 + 指令编码表 + 原理图要点
|   `-- html/                     # 平台评测题目（阶段 1-5）
`-- README.md
```

## 2. 硬件平台

| 项目 | 值 |
|------|-----|
| FPGA | XC7A200T-2FBG676C |
| BaseRAM | `0x1c000000 - 0x1c3fffff` (4 MiB) |
| ExtRAM | `0x1c400000 - 0x1c7fffff` (4 MiB) |
| UART 窗口 | `0x1f000000 - 0x1f0fffff` (1 MiB) |
| 复位 PC | `0x1c000000` |
| 串口 | 115200 baud, 8N1 |
| 字节序 | 小端 |

## 3. 评测阶段

| 阶段 | 类型 | 说明 |
|------|------|------|
| 1 | 功能测试 | 6 条指令 (`lu12i.w addi.w add.w ld.w st.w bne`)，计算斐波那契数列。裸机，无 UART、无 CSR、无异常 |
| 2 | MATRIX | Monitor 运行，矩阵乘加。需 UART |
| 3 | STREAM | Monitor 运行，~3MiB 连续访存 |
| 4 | CRYPTONIGHT | Monitor 运行，2MiB 内存访问 + 整数运算 |
| 5 | MIXED | Monitor 运行，混合运算 |

> **评测方式**：脚本将测试程序写入 BaseRAM → 释放复位 → CPU 运行后将结果写入 ExtRAM → 脚本读回比对。不通过 UART 输出判定结果。

> **指令集最终要求**：以 supervisor README 为准。

## 4. 开发环境搭建

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

本项目不自带工具链二进制。使用 nscscc 提供的下载脚本安装：

```bash
cd nscscc-solo-la-soc/sdk/toolchains
bash init.sh
```

或者手动下载 `loongson-gnu-toolchain-8.3-x86_64-loongarch32r-linux-gnusf-v2.0.tar.xz`
并解压到 `nscscc-solo-la-soc/sdk/toolchains/`。

将工具链加入 PATH：

```bash
TOOLCHAIN_BIN="$(pwd)/nscscc-solo-la-soc/sdk/toolchains/loongson-gnu-toolchain-8.3-x86_64-loongarch32r-linux-gnusf-v2.0/bin"
export PATH="$TOOLCHAIN_BIN:$PATH"
```

验证：

```bash
loongarch32r-linux-gnusf-gcc --version
```

### Supervisor 构建

```bash
cd nscscc-solo-la-soc/sdk/software/examples/supervisor
./build_all.sh
```

产物在 `build/` 下（MIF / BIN / ELF），包括：

- `build/kernel/auto/axi_ram.mif` —— 默认 kernel（自适应 cache）
- `build/kernel/uncache/axi_ram.mif` —— 强制 uncache kernel
- `build/kernel/auto/utest_symbols.txt` —— 性能测试入口地址
- `build/utility/` —— 各测试的输入、期望结果和 MIF

## 5. Verilator 仿真

### 前置条件

- Verilator >= 5.0
- Python 3 + numpy
- LA32R 工具链在 PATH 中

### 运行单个测试

```bash
cd nscscc-solo-la-soc
python3 sim/run.py sdk/software/examples/supervisor/sim/cases/simple.json
```

首次运行或软件修改后加 `--prepare` 重新构建 supervisor。

### 运行全部回归

```bash
python3 sim/run.py sdk/software/examples/supervisor/sim/suite.json
```

### 可用测试场景

| 场景 | JSON 文件 | 说明 |
|------|-----------|------|
| SIMPLE | `cases/simple.json` | 基础冒烟测试 |
| FIBONACCI | `cases/fibonacci.json` | 阶段 1：UART 交互 + 斐波那契 |
| STREAM | `cases/stream.json` | 阶段 3：连续访存 |
| MATRIX | `cases/matrix.json` | 阶段 2：矩阵乘加 |
| CRYPTONIGHT | `cases/cryptonight.json` | 阶段 4：密码学运算 |
| MIXED | `cases/mixed.json` | 阶段 5：混合运算 |

## 6. Vivado 本地流程

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
- `nscscc-solo-la-soc/rtl/ip/myCPU/` 下为软链接，指向 `src/soc/` 中的源文件
- 不自建 Vivado IP 目录，`.xci` 放 `src/soc/xilinx_ip/<name>/`
- 不提交 `ip_user_files/`、`.runs/`、`.cache/` 等中间产物

## 7. 提交规范

### 可修改

```
src/soc/**  src/vivado_cannot/**  run_vivado/constraints/**  asm/**  README.md  design.pdf
```

### 受控（不可修改）

```
run_vivado/flow/**
nscscc-solo-la-soc/**
```

> **公开前须知**：repo 公开前，须向主办方请示哪些内容可以公开。
> `docs/` 及工具链二进制须从 git 历史中彻底删除。
