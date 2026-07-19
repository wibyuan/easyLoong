# easyLoong — NSCSCC 2026 龙芯杯个人赛 (LoongArch)

基于 XC7A200T-2FBG676C FPGA 的 LoongArch 32-bit (LA32R) 精简版 CPU 实现。

## 1. 项目组成结构

```text
.
|-- asm/                       # 汇编测试程序，make -C asm → .bin
|-- src/
|   |-- soc/                   # ★ CPU SoC 源码（顶层 thinpad_top）
|   |   `-- xilinx_ip/         # Xilinx IP (.xci)
|   `-- vivado_cannot/         # 不可综合源码说明
|-- run_vivado/
|   |-- constraints/           # 引脚约束 (thinpad_top.xdc)
|   |-- simulation/            # 仿真模型 (SRAM/Flash)
|   `-- flow/                  # ★ 受控 CI 脚本（不可修改）
|-- docs/
|   |-- *.pdf                     # 原始参考文档（⚠ 公开前须从 git 历史中彻底删除）
|   |-- md/                       # PDF 的 OCR 翻译 + 指令编码表 + 原理图要点
|   `-- html/                     # 平台评测题目（阶段 1-5）
|-- loongarch32r-linux-gnusf-2022-05-20/  # LA32R 交叉编译工具链 (GCC 8.3.0)
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

> **指令集最终要求**：以 [supervisor README](https://gitee.com/loongson-edu/supervisor) 为准。

## 4. 开发环境

### 工具链

```bash
export PATH=$PWD/loongarch32r-linux-gnusf-2022-05-20/bin:$PATH
```

编译汇编测试：

```bash
loongarch32r-linux-gnusf-as -mabi=ilp32s -o test.o test.s
loongarch32r-linux-gnusf-ld -Ttext 0x1c000000 -o test.elf test.o
loongarch32r-linux-gnusf-objcopy -O binary test.elf test.bin
```

### Vivado 本地流程

```bash
make -C asm
vivado -mode batch -source run_vivado/flow/create_vivado_project.tcl
vivado -mode batch -source run_vivado/flow/implement_design.tcl
vivado -mode batch -source run_vivado/flow/generate_bitstream.tcl
```

### RTL 规范

- 所有设计源码放在 `src/soc/`，顶层模块固定为 `thinpad_top`
- 不自建 Vivado IP 目录，`.xci` 放 `src/soc/xilinx_ip/<name>/`
- 不提交 `ip_user_files/`、`.runs/`、`.cache/` 等中间产物

## 5. 提交规范

### 可修改

```
src/soc/**  src/vivado_cannot/**  run_vivado/constraints/**  asm/**  README.md  design.pdf
```

### 受控（不可修改）

```
run_vivado/flow/**
```

> **公开前须知**：repo 公开前，须向主办方请示哪些内容可以公开。`docs/` 及 `loongarch32r-linux-gnusf-2022-05-20/` 须从 git 历史中彻底删除。