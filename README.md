# NSCSCC 2026 LoongArch/Mips 提交模板

主要修改 `src/soc/`、`run_vivado/constraints/`、`asm/` 和设计文档；`run_vivado/flow/` 为受控流程文件，不应修改。

## 1. 项目组成结构

```text
.
|-- asm/
|   |-- Makefile
|   `-- user-sample.s
|
|-- src/
|   |-- soc/
|   |   |-- *.v
|   |   `-- xilinx_ip/
|   `-- vivado_cannot/
|
|-- run_vivado/
|   |-- constraints/
|   |   `-- thinpad_top.xdc
|   |-- simulation/
|   `-- flow/
|       |-- create_vivado_project.tcl
|       |-- lint_hdl.py
|       |-- implement_design.tcl
|       |-- check_timing.py
|       `-- generate_bitstream.tcl
|
`-- README.md
```

目录说明：

- `asm/`：汇编测试程序目录，`make -C asm` 会生成 `.bin` 文件。
- `src/soc/`：SoC/CPU 设计源码目录。顶层模块应保持为 `thinpad_top`，供 Vivado 工程脚本识别。
- `src/soc/xilinx_ip/`：用户自定义 Xilinx IP 放置目录。每个 IP 使用独立子目录，子目录中只放 `.xci` 或 `.xcix` 文件。
- `src/vivado_cannot/`：Vivado 不能直接综合的源码或生成型 HDL 工程说明目录，例如 Chisel、SpinalHDL、Scala 等。
- `run_vivado/constraints/`：约束文件目录，允许用户按设计需要修改 XDC。
- `run_vivado/simulation/`：仿真资源目录。
- `run_vivado/flow/`：受控 CI/Vivado 流程脚本目录。该目录用于创建工程、语法检查、实现、时序检查和生成 bitstream。

## 2. 工程开展方法

### 修改 RTL

将设计源码放在 `src/soc/` 下。Vivado 工程脚本会加载该目录，并将 `thinpad_top` 作为工程顶层。

如果使用 Xilinx IP，请按如下结构放置：

```text
src/soc/xilinx_ip/<ip_name>/<ip_name>.xci
```

或：

```text
src/soc/xilinx_ip/<ip_name>/<ip_name>.xcix
```

不要提交 Vivado 自动生成的 `ip_user_files/`、`.runs/`、`.cache/`、`.gen/` 等中间目录。

### 修改约束

板级引脚、时钟和时序约束放在：

```text
run_vivado/constraints/
```

该目录是用户可修改目录。CI 创建 Vivado 工程时会自动加载其中的约束文件。

### 修改汇编程序

汇编程序放在 `asm/` 下。CI 会先执行：

```bash
make -C asm
```

生成 `.bin` 文件。

### 本地运行流程

在已配置 Vivado 2019.2、LoongArch/Mips GCC 工具链和 Python 的环境中，可以按顺序本地运行，示例为Linux环境：

```bash

make -C asm
vivado -mode batch -source run_vivado/flow/create_vivado_project.tcl
python3 run_vivado/flow/lint_hdl.py run_vivado/project/thinpad_top.xpr
vivado -mode batch -source run_vivado/flow/implement_design.tcl
python3 run_vivado/flow/check_timing.py run_vivado/project/thinpad_top.runs/impl_1/timing_summary.rpt
vivado -mode batch -source run_vivado/flow/generate_bitstream.tcl
```

流程含义：

1. `create_vivado_project.tcl`：创建 Vivado 工程、添加 `src/soc/`、添加约束、更新 IP。
2. `lint_hdl.py`：从 Vivado 工程中提取 HDL 源码并运行 Verilator 语法检查。
3. `implement_design.tcl`：运行 implementation，并生成资源和时序报告。
4. `check_timing.py`：检查 timing summary 中的 WNS；当前 WNS 不大于 0 时仅告警，不阻断后续流程。
5. `generate_bitstream.tcl`：在实现完成后生成 bitstream。

## 3. 仓库提交规范与方法

### 可修改内容

通常只应修改：

```text
src/soc/**
src/vivado_cannot/**
run_vivado/constraints/**
asm/**
README.md
design.pdf
```

如需补充设计文档、参考资料或生成型 HDL 的编译说明，应放入合适目录并在设计报告中说明。

### 受控内容

以下内容为比赛/平台受控文件，不应修改：

```text
run_vivado/flow/**
```

如您有任何问题，可在官方 QQ交流群583344130 交流。