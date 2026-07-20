# Supervisor 仿真场景

本目录不能作为独立仿真工程运行，只保存与 supervisor 软件语义相关的场景配置。请配合
[`nscscc-solo-la-soc`](https://gitee.com/loongson-edu/nscscc-solo-la-soc.git)
的 `master` 分支使用；该父仓库提供 SoC 顶层、SRAM/UART 模型、Verilator/XSIM 驱动和
`sim/run.py`。推荐使用以下方式取得匹配环境：

```bash
git clone --branch master --recurse-submodules \
  https://gitee.com/loongson-edu/nscscc-solo-la-soc.git
cd nscscc-solo-la-soc
```

测试入口、软件镜像和参考结果继续保存在 supervisor 场景中，不写入父仓库 RTL。

## 运行场景

在仓库根目录执行：

```bash
python3 sim/run.py sdk/software/examples/supervisor/sim/cases/matrix.json --prepare
```

`--prepare` 会先运行 `build_all.sh`。已有 `build/` 产物时可以省略。场景默认使用
Verilator；临时改用 Vivado xsim：

```bash
python3 sim/run.py sdk/software/examples/supervisor/sim/cases/simple.json \
  --backend xsim --recreate-project \
  --vivado /mnt/d/Xilinx/Vivado/2019.2/bin/vivado.bat
```

额外 plusarg 放在命令末尾，例如 `+wave` 或 `+trace_boot`。它们只影响本次运行，
无需修改场景文件。

运行全部回归：

```bash
python3 sim/run.py sdk/software/examples/supervisor/sim/suite.json --prepare
```

套件依次运行 SIMPLE、STREAM、MATRIX、MIXED、CryptoNight 和 Fibonacci，并在首个
失败用例处停止。Fibonacci 使用 Verilator 专用的完整串口协议自检，因此整套回归默认
固定为 Verilator；其余场景可用 `--backend xsim` 单独运行。

## 场景职责

`cases/*.json` 负责指定 BaseRAM/ExtRAM 镜像、程序入口、超时和结果检查。路径相对
场景文件解析，因此仓库移动后仍然有效。入口通过
`build/kernel/auto/utest_symbols.txt` 中的符号解析，不依赖固定链接地址。
`stream.json`、`matrix.json`、`cryptonight.json` 和 `mixed.json` 检查各自的 ExtRAM
结果；`fibonacci.json` 验证完整的 A/D/G/R/D 串口流程；`simple.json` 适合作为最短
启动检查。

添加新程序时，应在本目录新增场景，而不是在 `sim/mycpu_tb.v`、
`sim/verilator/verilator_main.cpp` 或 `rtl/config.h` 中加入程序地址和文件路径。
