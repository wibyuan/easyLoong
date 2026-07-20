# myCPU 接入说明

此目录由参赛者放置自己的 LA32R CPU RTL，发布仓库不附带参考 CPU 实现。CPU 顶层模块
必须命名为 `core_top`，完整 AXI 和调试端口定义见仓库根目录 `readme.md`。

目录层级可以自行组织。Vivado 和 Verilator 会递归收集 `.v`、`.sv` 文件并加入各级
include 目录，不要求提供 `mycpu.h` 或使用固定文件名。Vivado 还会收集 `.xci`、`.xcix`
形式的 CPU 自有 IP。

请只保留源文件和 IP 配置文件，不要提交以下生成物：

- `.Xil/`、Vivado 工程及 IP output products。
- `*_sim_netlist.v`、`*_stub.v` 等可由 XCI 重新生成的文件。
- Verilator `obj_dir/`、FST/WDB 波形和综合实现日志。

加入 CPU 后先运行快速功能回归：

```bash
python3 sim/run.py sdk/software/examples/supervisor/sim/cases/simple.json --prepare
```

再运行 `sdk/software/examples/supervisor/sim/suite.json` 覆盖全部 supervisor 场景，并使用
Windows Vivado XSIM 至少复核 SIMPLE 场景。修改 CPU 文件集合后 Verilator 会自动检测并
重新编译。
