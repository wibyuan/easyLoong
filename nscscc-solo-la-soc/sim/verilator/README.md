# Verilator 仿真使用说明

本目录提供与具体软件无关的 SoC Verilator 后端。`run_verilator.sh` 会从仓库根目录
收集 RTL、编译 `verilator_tb`，并将生成文件放到 `sim/verilator/obj_dir/`。
软件回归优先使用根目录的 `sim/run.py` 和软件自己维护的 JSON 场景。

## 文件说明

- `run_verilator.sh`：一键构建并运行 Verilator 仿真的脚本。
- `verilator_tb.v`：Verilator 顶层封装，例化 `soc_top`、BaseRAM、ExtRAM，并导出调试信号。
- `verilator_main.cpp`：C++ 驱动，负责时钟复位、TCP-UART、自动回归、ExtRAM 比较和 FST 波形。
- `obj_dir/`：Verilator 生成目录，不应作为源码维护。

脚本会复用未过期的 `obj_dir/Vverilator_tb`；切换软件场景或 MIF 不会重新编译 RTL。
缓存签名覆盖 Verilator 版本、完整 RTL/头文件清单、文件内容、仿真 C++、脚本和探针配置，
因此源码新增、删除、重命名或修改都会自动重建。需要强制重建可设置
`FORCE_VERILATOR_REBUILD=1`。

## term.py 交互仿真

先构建 supervisor，确保 `sdk/axi_ram.mif` 和 `sdk/ext_ram.mif` 已准备好：

```bash
cd sdk/software/examples/supervisor
./build_all.sh --install auto --ext matrix
cd ../../../..
```

在仓库根目录启动 Verilator：

```bash
./sim/verilator/run_verilator.sh
```

没有指定其它运行模式时，脚本默认在 `127.0.0.1:6666` 提供 TCP 串口桥。看到
`TCP UART listening` 后，在另一个终端连接：

```bash
python3 sdk/software/examples/supervisor/term/term.py -t 127.0.0.1:6666
```

之后可自由使用 `A/F/D/G/R` 命令；输入 `Q` 会关闭连接并结束仿真。monitor 等待下一条
命令时，Verilator 会暂停推进仿真时间，避免空转占用 CPU 和扩大波形。可以显式指定端口：

```bash
./sim/verilator/run_verilator.sh +term_port=7777
```

`+term_bind=<IPv4>` 用于修改监听地址，默认只监听本机 `127.0.0.1`。需要从其它主机
连接时可使用 `+term_bind=0.0.0.0`，同时应使用防火墙限制访问。

## 波形文件

Verilator 默认不记录波形，避免性能测试因跟踪完整 SoC 和 RAM 层次而产生过大的文件。
需要调试时使用 `+wave`，生成 `sim/verilator/wave.fst`：

```bash
./sim/verilator/run_verilator.sh +wave
```

可用 Surfer 或 GTKWave 打开：

```bash
surfer sim/verilator/wave.fst
```

使用 `+wave_file=<path>` 可指定输出文件并自动启用波形。`+no_wave` 会强制关闭波形，
即使同时传入了 `+wave` 或 `+wave_file`。FST 会记录 SoC 层级信号，长时间性能测试的
文件可能很大，建议只在定位问题时启用。

## 自动运行

构建产物并依次运行 SIMPLE、STREAM、MATRIX、MIXED、CryptoNight 和 Fibonacci：

```bash
python3 sim/run.py sdk/software/examples/supervisor/sim/suite.json --prepare
```

套件会在首个失败用例处停止并返回非零状态。Fibonacci 串口协议自检目前只支持
Verilator，因此完整套件默认使用 Verilator。

运行 supervisor MATRIX 场景并自动准备软件产物：

```bash
python3 sim/run.py sdk/software/examples/supervisor/sim/cases/matrix.json --prepare
```

场景同时指定 BaseRAM/ExtRAM 镜像、入口和结果文件，因此不需要把生成文件复制到
`sdk/`。下面的直接 plusarg 用法保留用于临时调试。

指定 `+supervisor_entry` 后，驱动等待欢迎词并自动发送 `G`，收到程序结束标志后退出：

```bash
./sim/verilator/run_verilator.sh +supervisor_entry=<address-from-utest_symbols>
```

程序通过 UART 输出 `0x06` 时打印 started，输出 `0x07` 时打印 finished。

## Supervisor 串口协议自检

`+supervisor_uart_check` 会按真实终端交互顺序完成一次闭环验证：

1. 等待 supervisor 欢迎词。
2. 用 `A` 命令把用户程序加载到 `0x1c300000`。
3. 用 `D` 命令读回程序字节并逐字节比较。
4. 用 `G` 命令执行程序，等待开始标志 `0x06` 和结束标志 `0x07`。
5. 用 `R` 命令读取 124 字节寄存器区并检查指定寄存器。
6. 用 `D` 命令读取结果内存并检查执行结果。

以下命令加载 `sdk/software/examples/supervisor/build/utility/fibonacci/fibonacci.mem`。
对应汇编源码是 `utility/fibonacci/fibonacci.S`。程序向 `0x1c400000` 写入 8 个 Fibonacci
数，并在返回后检查寄存器和 ExtRAM：

```bash
./sim/verilator/run_verilator.sh \
  +supervisor_uart_check \
  +supervisor_a_file=sdk/software/examples/supervisor/build/utility/fibonacci/fibonacci.mem \
  +supervisor_a_addr=0x1c300000 \
  +supervisor_expected_regs=r4:1c400020,r5:1c400020,r12:22,r13:37,r14:37 \
  +supervisor_result_addr=0x1c400000 \
  +supervisor_result_words=2,3,5,8,d,15,22,37 \
  +no_ext_ram_write_log
```

列表中的数值均为十六进制。任一步比较失败或仿真超时，脚本都会返回非零状态。
`R` 命令固定返回 `uregs[0]` 和 `r2` 至 `r31`，共 124 字节；参数中的
`rN:value` 直接使用 LoongArch 寄存器编号。

## 常用参数

Verilator 参数以 plusarg 形式传给脚本：

```bash
./sim/verilator/run_verilator.sh +supervisor_entry=<address-from-utest_symbols>
```

常用参数：

- `+term_port=<port>`：启动 term.py TCP 串口桥；默认交互端口为 `6666`。
- `+term_bind=<IPv4>`：TCP 监听地址，默认 `127.0.0.1`。
- `+wave`：启用 FST 波形，默认输出到 `sim/verilator/wave.fst`。
- `+wave_file=<path>`：指定 FST 输出路径并自动启用波形。
- `+no_wave`：强制关闭 FST 波形；优先级高于 `+wave` 和 `+wave_file`。
- `+base_ram_mif=<path>`：运行时指定 BaseRAM MIF；`none` 表示不初始化。
- `+ext_ram_mif=<path>`：运行时指定 ExtRAM MIF；`none` 表示不初始化。
- `+supervisor_entry=<addr>`：进入自动模式并发送 `G` 命令到指定地址。
- `+supervisor_uart_check`：启用完整的 `A/D/G/R/D` 串口协议自检。
- `+supervisor_a_addr=<addr>`：用 `A` 命令写入程序的起始地址，默认 `0x1c300000`。
- `+supervisor_a_words=<w0,w1,...>`：待写入的 32 位十六进制机器码；指定后 `G` 默认跳转到 `supervisor_a_addr`。
- `+supervisor_a_file=<path>`：从文本文件读取十六进制机器码，每个空白分隔项为一个 32 位字；不能与 `supervisor_a_words` 同时使用。
- `+supervisor_expected_regs=<rN:value,...>`：完整自检时要比较的寄存器及十六进制预期值。
- `+supervisor_result_addr=<addr>`：完整自检最后一次 `D` 命令的起始地址，默认 `0x1c400000`。
- `+supervisor_result_words=<w0,w1,...>`：结果内存的 32 位十六进制预期值。
- `+max_time=<time>`：设置最大仿真时间，超时返回失败。
- `+dump_ext_addr=<addr>`：程序结束后 dump ExtRAM 起始地址，可填字节偏移或物理地址。
- `+dump_ext_size=<bytes>`：dump 字节数，默认 `200`；设为 `0` 可关闭 dump。
- `+compare_ext_file=<path>`：程序结束后与参考二进制文件比较。
- `+compare_ext_addr=<addr>`：比较起始地址，默认等于 `dump_ext_addr`。
- `+compare_ext_size=<bytes>`：最多比较字节数；为 `0` 时按参考文件大小比较。
- `+compare_mismatch_limit=<n>`：打印 mismatch 样例数量。
- `+log_ext_ram_write`：打印 ExtRAM 写入。
- `+log_ext_ram_all`：打印所有 ExtRAM 写入。
- `+no_ext_ram_write_log`：关闭 ExtRAM 写入日志。
- `+log_ext_ram_addr=<addr>`：只打印指定 ExtRAM 地址范围内的写入。
- `+log_ext_ram_size=<bytes>`：配合 `log_ext_ram_addr` 指定范围大小。
- `+ext_ram_write_log_limit=<n>`：限制写日志数量，默认 `2048`。
- `+trace_boot`：打印启动阶段 PC、AXI 读写等信息。
- `+trace_pc_range=<start:end>`：只跟踪指定 PC 范围。
- `+heartbeat_cycles=<n>`：每隔指定 CPU 周期打印心跳。

ExtRAM 地址参数既可以写字节偏移，例如 `0x20000`，也可以写物理地址，例如
`0x1c420000`。仿真驱动会自动转换为 ExtRAM 内部偏移。

例如，先通过串口 `A` 命令向 BaseRAM 写入两条指令，再从该地址执行：

```bash
./sim/verilator/run_verilator.sh \
  +supervisor_a_addr=0x1c300000 \
  +supervisor_a_words=0280040c,4c000020
```

每个机器码按 `objdump` 指令列中的 32 位数值填写，驱动在 UART 协议中按小端序发送。
例如 `addi.w $t0,$zero,1` 填写为 `0280040c`，实际发送的 4 个字节为
`0c 04 80 02`。

## 性能测试示例

性能测试配置位于 supervisor 源码树，参考结果由 `build_all.sh` 统一生成：

```bash
python3 sim/run.py sdk/software/examples/supervisor/sim/cases/stream.json
python3 sim/run.py sdk/software/examples/supervisor/sim/cases/matrix.json
python3 sim/run.py sdk/software/examples/supervisor/sim/cases/cryptonight.json
python3 sim/run.py sdk/software/examples/supervisor/sim/cases/mixed.json
```

首次运行或软件修改后给任一命令增加 `--prepare`。场景从
`build/kernel/auto/utest_symbols.txt` 解析入口，链接地址变化时无需修改 JSON 或后端。

## 调试说明

默认 Verilator 仿真不依赖 `myCPU` 内部层级。若需要使用 OpenLA500 兼容的内部探针，可设置：

```bash
MYCPU_OPENLA500_PROBES=1 ./sim/verilator/run_verilator.sh +trace_data_addr=0x1c420000
```

该模式会引用 `u_soc_top.u_cpu` 内部信号，只适用于仍保留这些内部层级和信号名的 CPU。
学生自定义 CPU 不应依赖该模式完成基本仿真。
