# 仿真使用说明

`sim/` 只维护与具体软件无关的 SoC 仿真基础设施。Vivado xsim 使用
`sim/mycpu_tb.v`，Verilator 使用 `sim/verilator/` 下的专用封装；具体程序的入口、
内存镜像和参考结果由软件目录中的 JSON 场景维护。

## 目录说明

- `mycpu_tb.v`：Vivado xsim 顶层 testbench，顶层模块为 `tb_top`。
- `sram.v`：仿真用 32 位 SRAM 模型，BaseRAM 和 ExtRAM 都使用该模型。
- `run.py`：读取软件场景并统一调用 Verilator 或 xsim。
- `xsim/`：Vivado xsim 的通用批处理入口。
- `verilator/`：Verilator 仿真入口、C++ 驱动和使用说明。

supervisor 专用场景位于 `sdk/software/examples/supervisor/sim/`。新增软件测试时，
应在对应软件目录增加场景，不要把程序地址或生成文件路径写入 RTL。
场景中的 `supervisor_entry` 可引用 `utest_symbols.txt` 中的符号，避免链接布局变化后
手工同步入口地址。完整 supervisor 回归使用：

```bash
python3 sim/run.py sdk/software/examples/supervisor/sim/suite.json --prepare
```

## 内存初始化

BaseRAM 和 ExtRAM 镜像通过运行时 plusarg `base_ram_mif`、`ext_ram_mif` 指定，
不再写死在 `rtl/config.h`。推荐直接运行软件场景，路径会相对场景文件解析：

```bash
python3 sim/run.py sdk/software/examples/supervisor/sim/cases/matrix.json --prepare
```

这样生成文件只保留在 supervisor 的 `build/` 下，不需要复制到 `sdk/`。直接使用
`run_verilator.sh` 时仍兼容 `sdk/axi_ram.mif` 和 `sdk/ext_ram.mif`；也可显式传入
`+base_ram_mif=<path>`、`+ext_ram_mif=<path>`，用 `none` 表示不初始化该 RAM。

## Vivado xsim 流程

统一场景入口可以重建工程并运行 Windows Vivado 2019.2：

```bash
python3 sim/run.py sdk/software/examples/supervisor/sim/cases/simple.json \
  --backend xsim --recreate-project \
  --vivado /mnt/d/Xilinx/Vivado/2019.2/bin/vivado.bat
```

也可以先手动创建 Vivado 工程：

```tcl
cd fpga
vivado -mode batch -source create_project.tcl
```

在 Vivado GUI 或 Tcl Console 中运行行为级仿真：

```tcl
launch_simulation
run all
```

工程已设置 `xsim.simulate.log_all_signals=true`。每次行为仿真都会生成 WDB 波形，通常位于：

```text
fpga/project/Loongson_Soc.sim/sim_1/behav/xsim/tb_top_behav.wdb
```

可在 Vivado 波形窗口直接打开；重新运行仿真会更新该文件。

当前兼容 testbench 会监听 UART 欢迎词。收到
`MONITOR for Loongarch32 - initialized.` 后，testbench 自动向 UART 发送 `G` 命令，
跳转到 `supervisor_entry` 指定的入口。推荐通过 JSON 场景从编译产物解析 `UTEST_*`
符号；临时调试时也可以直接覆盖入口，例如：

```tcl
set_property -name {xsim.simulate.xsim.more_options} \
  -value {-testplusarg supervisor_entry=1c002008} \
  -objects [get_filesets sim_1]
launch_simulation
run all
```

不要在脚本中复制上述示例地址。实际入口以
`sdk/software/examples/supervisor/build/kernel/<mode>/utest_symbols.txt` 为准。

## xsim 常用 Plusargs

- `base_ram_mif=<path>`：BaseRAM 的 32 位二进制 MIF；`none` 表示不初始化。
- `ext_ram_mif=<path>`：ExtRAM 的 32 位二进制 MIF；`none` 表示不初始化。
- `supervisor_entry=<hex>`：设置自动发送 `G` 命令时跳转的入口地址。
- `supervisor_a_file=<path>`：在 `G` 之前，通过一条串口 `A` 命令下载指定的十六进制机器码文件。
- `supervisor_a_addr=<hex>`：A 命令下载起始地址，默认 `1c300000`。
- `supervisor_a_count=<dec>`：从文件读取并下载的 32 位机器字数量，范围为 `1..1024`。
- `supervisor_fast_uart`：将 UART 16 倍采样使能提升为每个 SoC 时钟一次，以加速 supervisor 命令仿真；默认关闭。
- `log_ext_ram_write`：打印 ExtRAM 写入日志。
- `log_ext_ram_all`：打印所有 ExtRAM 写入。
- `no_ext_ram_write_log`：关闭 ExtRAM 写入日志。
- `log_ext_ram_addr=<hex>`：只打印指定 ExtRAM 字节偏移或物理地址附近的写入。
- `log_ext_ram_size=<hex>`：配合 `log_ext_ram_addr` 指定范围大小，默认 `4` 字节。
- `ext_ram_write_log_limit=<dec>`：限制写日志数量，默认 `2048`。
- `compare_ext_file=<path>`：程序结束后，将 ExtRAM 指定范围与二进制参考文件比较。
- `compare_ext_addr=<hex>`：比较起始地址，可填 ExtRAM 字节偏移或 `0x1c400000` 起的物理地址。
- `compare_ext_size=<hex>`：最多比较的字节数；为 `0` 时按参考文件大小比较。
- `compare_mismatch_limit=<dec>`：打印的 mismatch 数量上限。
- `max_time=<dec>`：最大仿真时间（ns）；超时以失败状态结束，`0` 表示关闭看门狗。

supervisor 测试程序通过 UART 发送 `0x06` 表示开始，发送 `0x07` 表示结束。
testbench 收到结束信号后会执行可选的 ExtRAM 比较。结果一致时调用 `$finish`；
镜像无效、地址越界、结果不一致或超时时调用 `$fatal(1)`，批处理进程返回非零状态。

## xsim 测试 A 命令

`sdk/software/examples/supervisor/utility/fibonacci/fibonacci.S` 是示例汇编源码，
`build_all.sh` 生成对应的 `build/utility/fibonacci/fibonacci.mem`。程序从 BaseRAM `0x1c300000` 执行，将 8 个 Fibonacci 数写入
ExtRAM `0x1c400000`。在 Vivado Tcl Console 中设置：

```tcl
set_property -name {xsim.simulate.xsim.more_options} \
  -value {-testplusarg base_ram_mif=../../../../../../sdk/software/examples/supervisor/build/kernel/uncache/axi_ram.mif -testplusarg ext_ram_mif=none -testplusarg supervisor_a_file=../../../../../../sdk/software/examples/supervisor/build/utility/fibonacci/fibonacci.mem -testplusarg supervisor_a_addr=1c300000 -testplusarg supervisor_a_count=11 -testplusarg supervisor_fast_uart} \
  -objects [get_filesets sim_1]
launch_simulation
run all
```

机器码文件每行填写一个 `objdump` 指令列中的 32 位数值。testbench 会将每个数值
按小端序放入 A 命令数据。例如 `0280040c` 实际发送为 `0c 04 80 02`。
`supervisor_fast_uart` 仍逐 bit 驱动串行线，并由 UART 接收状态机采样，软件也仍访问
UART 寄存器并解析 A/G 协议；它只绕过正常波特率分频。验证实际波特率时不要使用该选项。

## 注意事项

Vivado xsim 适合波形调试，但运行 supervisor 性能测试会比较慢。需要快速跑完整软件测试时，
优先使用 `sim/verilator/` 下的 Verilator 仿真。Verilator 默认关闭 FST 波形，可用
`+wave` 显式启用，并可通过 TCP 串口桥与 `term.py` 自由交互，具体命令见
`sim/verilator/README.md`。Vivado xsim 仍按工程配置生成 WDB 波形。
