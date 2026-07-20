# supervisor-32：32位监控程序（“龙芯杯”个人赛）

本目录包含 LA32R supervisor/monitor 程序、串口终端和内置性能测试。软件从 `0x1c000000` 启动，通过串口命令读写内存、读写用户寄存器并跳转到 `UTEST_*` 测试入口。

本仓库可独立使用，也可由 LA32R SoC 仓库以 Git 子模块方式引入。修改应先提交到本仓库，
再由上层仓库更新子模块提交指针；不要直接在上层仓库复制或重复跟踪本目录中的源码文件。

## CPU 指令需求

如果使用 `make uncache` 构建，并且只运行 monitor 本身和串口命令（不执行内置 `UTEST_*` 性能程序），CPU 至少需要实现以下普通整数、访存和跳转指令：

```text
pcaddu12i, lu12i.w,
addi.w, sub.w,
andi, ori, or,
slli.w, srli.w,
ld.b, ld.w, st.b, st.w,
b, bl, beq, bne, jirl
```

这种模式不需要 `cpucfg`、`csrwr`、`csrxchg` 或 `cacop`，也不需要任何 CSR 支持；软件完全依赖复位后的直接地址、uncache 状态。

若要运行当前内置 `UTEST_*` 性能程序，还需要覆盖测试程序使用到的额外普通指令：

```text
add.w, slt, and, xor, sll.w, mul.w
```

其中 `mul.w` 由 `UTEST_MATRIX` 和 `UTEST_CRYPTONIGHT` 使用；如果只运行 monitor 基本命令，可暂时不覆盖乘法测试。

默认 `make` 构建下，无 cache CPU 仍建议实现 `cpucfg`，并让 `CPUCFG[0x10]` 返回 I-cache 和 D-cache 均不存在。这样 supervisor 会跳过 cache 初始化、DMW 配置和返回前 cache 写回，保持复位后的直接地址模式。

默认 `make` 构建且有 cache 的 CPU 还需要实现：

```text
cpucfg, csrwr, csrxchg, cacop
```

相关 CSR/CPUCFG 最小要求：

- `CPUCFG[0x10]`：bit0 表示 L1 I-cache 存在，bit2 表示 L1 D-cache 存在。
- `CPUCFG[0x11]`：I-cache 几何参数。
- `CPUCFG[0x12]`：D-cache 几何参数，`[30:24]` 为 offset bits，`[23:16]` 为 index bits，`[15:0]` 为 max way。
- `CSR.CRMD` (`0x0`)：支持 `DA`、`PG` 以及直接地址/分页模式切换。
- `CSR.DMW0` (`0x180`) 和 `CSR.DMW1` (`0x181`)：支持直接映射窗口。
- `cacop 0x00`：I-cache index invalidate。
- `cacop 0x01`：D-cache index invalidate。
- `cacop 0x09`：D-cache index writeback invalidate。

当前 supervisor 不依赖异常返回、TLB 指令、LL/SC、浮点、除法或中断处理。

## SoC 地址空间需求

当前软件按以下物理地址访问 SoC：

| 地址范围 | 用途 | 是否必需 |
| --- | --- | --- |
| `0x1c000000 - 0x1c3fffff` | BaseRAM，存放 supervisor/kernel | 必需 |
| `0x1c400000 - 0x1c7fffff` | ExtRAM，存放测试输入、工作区和结果 | 必需 |
| `0x1f000000 - 0x1f0fffff` | UART 窗口 | 必需 |
| `0x1f100000 - 0x1f5fffff` | DVI/confreg/DMA/FFT 等扩展外设 | 当前 supervisor 不依赖 |

BaseRAM 和 ExtRAM 各 4 MiB。当前测试常用地址包括：

- `UTEST_STREAM`：从 `0x1c100000` 复制到 `0x1c400000`。
- `UTEST_MATRIX`：`A=0x1c400000`，`B=0x1c410000`，`C=0x1c420000`。
- `UTEST_CRYPTONIGHT`：2 MiB 工作区从 `0x1c400000` 开始。
- `UTEST_MIXED`：使用 `0x1c500000`、`0x1c510000`、`0x1c520000`。

复位后 CPU 应从 `0x1c000000` 取指。无 cache 情况下虚地址等于物理地址。

有 cache 情况下 supervisor 会进入 PG 模式并配置两个 DMW。DMW 命中规则是：虚地址 `VA[31:29]` 匹配窗口的 `VSEG` 后，物理地址变为 `{PSEG, VA[28:0]}`，低 29 位保持不变，访存属性由 `MAT` 决定。

| 窗口值 | 虚地址范围 | 物理地址范围 | 属性 | 用途 |
| --- | --- | --- | --- | --- |
| `DMW0 = 0x00000019` | `0x00000000 - 0x1fffffff` | `0x00000000 - 0x1fffffff` | cacheable | BaseRAM/ExtRAM 身份映射 |
| `DMW1 = 0xa0000009` | `0xa0000000 - 0xbfffffff` | `0x00000000 - 0x1fffffff` | uncached | 低 512 MiB 的 uncached 别名 |

因此 cache 模式下 UART 使用 uncached 别名访问：虚地址 `0xbf000000` 映射到物理地址 `0x1f000000`，`0xbf000005` 映射到物理地址 `0x1f000005`。

## UART 最小接口

如果使用固定波特率 UART，可以只实现两个有效寄存器：

| 物理地址 | 名称 | 行为 |
| --- | --- | --- |
| `0x1f000000` | `UART_DATA` | 写低 8 位发送 1 字节；读返回接收字节 |
| `0x1f000005` | `UART_STATUS` | bit0=`RX_READY`，bit5=`TX_READY` |

串口读写伪代码：

```c
while ((UART_STATUS & 0x20) == 0) {}
UART_DATA = ch;

while ((UART_STATUS & 0x01) == 0) {}
ch = UART_DATA;
```

真实板卡需要配置波特率。若保持当前 supervisor 初始化代码不变，UART 还需要兼容以下 16550 风格写入：

| 地址偏移 | 写入值 | 含义 |
| --- | --- | --- |
| `+2` | `0x07` | 清 FIFO，可简化为忽略 |
| `+3` | `0x80` | 设置 `DLAB=1`，进入 divisor 配置 |
| `+1` | `0x00` | `DLH` |
| `+0` | `0x0e` | `DLL`，25 MHz UART 时钟下约 115200 baud |
| `+3` | `0x03` | 8 data bits、no parity、1 stop bit，并退出 divisor 配置 |
| `+4` | `0x00` | modem control，可简化为忽略 |

简化实现中，`+1/+2/+3/+4` 至少应允许写入不报错；真正运行依赖 `UART_DATA(+0)` 和 `UART_STATUS(+5)`。

## term.py 使用方法

`term/term.py` 是 Linux/WSL 环境下的 supervisor 交互工具。当前只使用 `-t` TCP 网络模式，没有本地执行模式，也不直接打开本地串口设备；它必须连接到一个已经运行的 SoC/仿真环境提供的 TCP 串口桥。运行前需要：

- Python 3。
- LoongArch32R 工具链在 `PATH` 中，或通过 `GCCPREFIX` 指定前缀；`A`/`F` 命令会调用 `loongarch32r-linux-gnusf-as`、`objcopy` 和 `objdump`。

常用启动方式：

```bash
cd sdk/software/examples/supervisor
python3 term/term.py -t 127.0.0.1:6666
```

其中 `127.0.0.1:6666` 是 TCP 串口桥的地址和端口，按实际仿真或上板代理程序修改。

默认启动后会等待并打印 supervisor 欢迎词。如果程序已经运行到命令循环，不想等待欢迎词，可加 `-c`：

```bash
python3 term/term.py -t 127.0.0.1:6666 -c
```

进入 `>>` 提示符后支持以下命令：

| 命令 | 作用 |
| --- | --- |
| `R` | 读取并打印用户寄存器备份。 |
| `D` | Dump 内存；依次输入起始地址和字节数，字节数必须是 4 的倍数。 |
| `A` | 从指定地址开始逐行输入汇编指令或 32-bit 机器码，并写入目标内存。空行结束。 |
| `F` | 从文件装载代码/数据到指定地址；Linux 版依赖本地 LoongArch 工具链，Windows 版 `term_win.py` 按二进制文件写入。 |
| `G` | 跳转到指定地址执行程序；收到 `0x06` 后开始计时，收到 `0x07` 后停止计时。 |
| `Q` | 退出终端。 |

`A`/`F` 命令写入临时用户程序时，推荐从 BaseRAM 的 `0x1c300000` 开始，然后用 `G 0x1c300000` 执行。不要覆盖 `0x1c000000` 附近的 supervisor 代码区、`0x1c7f0000` 附近的栈和用户寄存器备份区，也不要把程序写到 `0x1f000000` 及以上的外设地址空间。若还要运行内置性能测试，避免占用 `0x1c100000` 的 STREAM 输入区和 `0x1c400000 - 0x1c7fffff` 的 ExtRAM 测试数据区。

通过 `G` 执行的用户程序结束时只需执行 `jirl zero, ra, 0` 返回。默认构建下，如果启动时检测到 D-cache，supervisor 会在保存用户寄存器后、发送 `0x07` 之前统一执行 D-cache writeback invalidate；`make uncache` 构建下该步骤为空操作。

性能测试入口由链接结果决定。构建后可直接查看：

```bash
cat build/kernel/auto/utest_symbols.txt
```

运行示例：

```text
>> G
>>addr: <UTEST address from utest_symbols.txt>
elapsed time: 12.345s
```

## 构建与运行

仓库只跟踪源码，ELF、BIN、MIF、反汇编和测试参考数据统一生成到被忽略的 `build/`。一键生成全部产物：

```bash
cd sdk/software/examples/supervisor
./build_all.sh
```

脚本需要 LoongArch32R 工具链、Python 3、NumPy 和宿主机 C 编译器。它会生成：

```text
build/
├── kernel/auto/       # 默认 CPUCFG/cache 自适应版本
├── kernel/uncache/    # 强制 uncache 版本
└── utility/
    ├── matrix/        # 输入、期望结果、BIN 和 MIF
    ├── mixed/         # 完整参考镜像和签名
    ├── crypto/        # CryptoNight 参考 BIN 和 MIF
    ├── stream/        # 3 MiB 输入、合并 BaseRAM MIF
    └── fibonacci/     # ELF、BIN、MIF、MEM 和反汇编（.disasm）
```

`build/SHA256SUMS` 记录所有产物的校验和。MATRIX 默认使用固定随机种子 `2026`，因此相同源码和工具版本应生成相同数据。

默认构建会读取 `CPUCFG` 自动判断 cache 能力；`uncache` 版本不执行 `cpucfg`、`cacop`、`csrwr` 或 `csrxchg`，所有地址均按 uncache 直接地址模式访问。

JSON 场景直接引用 `build/` 中的镜像。仅兼容旧的手工 Vivado 流程时，才需要显式安装
默认 kernel 和 MATRIX 数据到 `sdk/axi_ram.mif`、`sdk/ext_ram.mif`：

```bash
./build_all.sh --install auto --ext matrix
```

为不实现 `CPUCFG` 的 CPU 安装强制 uncache kernel：

```bash
./build_all.sh --install uncache --ext matrix
```

`--install` 只复制仿真需要的 MIF，不会把 ELF、BIN 或反汇编散落到 SDK 顶层。删除 `build/` 和 kernel 中间产物（不删除已安装到 SDK 的 MIF）：

```bash
./build_all.sh --clean
```

## 仿真场景

`sim/` 不是独立仿真工程，需要配合
[`nscscc-solo-la-soc`](https://gitee.com/loongson-edu/nscscc-solo-la-soc.git)
的 `master` 分支使用。该 SoC 仓库以子模块方式引入 supervisor，并提供 RTL、RAM/UART
testbench、Verilator/XSIM backend 及仓库根目录的 `sim/run.py`。推荐直接克隆完整环境：

```bash
git clone --branch master --recurse-submodules \
  https://gitee.com/loongson-edu/nscscc-solo-la-soc.git
cd nscscc-solo-la-soc
```

supervisor 的程序入口、RAM 镜像和结果检查集中在 `sim/cases/*.json`，通用仿真器位于
父仓库根目录的 `sim/`。例如在本目录构建并运行 MATRIX：

```bash
python3 ../../../../sim/run.py sim/cases/matrix.json --prepare
```

已有 `build/` 产物时省略 `--prepare`。使用 `--backend xsim` 可运行同一场景的
Vivado 仿真，Verilator/xsim 的后端参数和 Windows Vivado 示例见 `sim/README.md`。
场景通过 `utest_symbols.txt` 按符号解析程序入口。新增测试时应在本目录添加场景，
不要在 SoC RTL、通用 testbench 或文档中硬编码链接地址。

运行全部 supervisor 回归：

```bash
python3 ../../../../sim/run.py sim/suite.json --prepare
```

仅调试 kernel 时仍可在 `kernel/` 执行 `make`、`make uncache`、`make install` 或 `make install-uncache`；这些中间产物均已由 `.gitignore` 排除。
