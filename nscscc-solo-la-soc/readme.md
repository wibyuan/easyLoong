# la32r_soc

`la32r_soc` 提供 LA32R CPU IP 使用的 SoC 外壳、存储系统、UART、FPGA 工程和仿真测试环境。
学生实现的 CPU RTL 放在 `rtl/ip/myCPU/` 下，内部目录层级可以自行组织。Vivado 和
Verilator 会递归收集该目录下的 Verilog 源文件和 include 目录，`mycpu.h`/`mycpu.vh`
不是必需文件。

## CPU IP 顶层接口

SoC 中以模块名 `core_top` 例化 CPU。即使部分功能暂时不实现，也要保留该模块名和完整端口列表。
CPU 作为 AXI 主设备接入 SoC，SoC 边界不再提供独立的指令 SRAM 或数据 SRAM 接口。

```verilog
module core_top #(
    parameter TLBNUM = 32
)(
    input           aclk,
    input           aresetn,
    input  [7:0]    intrpt,

    output [3:0]    arid,
    output [31:0]   araddr,
    output [7:0]    arlen,
    output [2:0]    arsize,
    output [1:0]    arburst,
    output [1:0]    arlock,
    output [3:0]    arcache,
    output [2:0]    arprot,
    output          arvalid,
    input           arready,
    input  [3:0]    rid,
    input  [31:0]   rdata,
    input  [1:0]    rresp,
    input           rlast,
    input           rvalid,
    output          rready,

    output [3:0]    awid,
    output [31:0]   awaddr,
    output [7:0]    awlen,
    output [2:0]    awsize,
    output [1:0]    awburst,
    output [1:0]    awlock,
    output [3:0]    awcache,
    output [2:0]    awprot,
    output          awvalid,
    input           awready,
    output [3:0]    wid,
    output [31:0]   wdata,
    output [3:0]    wstrb,
    output          wlast,
    output          wvalid,
    input           wready,
    input  [3:0]    bid,
    input  [1:0]    bresp,
    input           bvalid,
    output          bready,

    input           break_point,
    input           infor_flag,
    input  [4:0]    reg_num,
    output          ws_valid,
    output [31:0]   rf_rdata,

    output [31:0]   debug0_wb_pc,
    output [3:0]    debug0_wb_rf_wen,
    output [4:0]    debug0_wb_rf_wnum,
    output [31:0]   debug0_wb_rf_wdata,
    output [31:0]   debug0_wb_inst
);
```

`aclk` 是 CPU 时钟，`aresetn` 是低有效复位。复位结束后，CPU 应从 SoC 启动地址
`0x1c000000` 开始取指。

## AXI 接口要求

CPU 需要实现 32 位 AXI master 接口，包含读地址、读数据、写地址、写数据和写响应五个通道。
简单 CPU 可以只支持 1 个未完成读请求和 1 个未完成写请求，ID 可以使用常量，也可以只发
single-beat 访问（`arlen`/`awlen = 0`）。如果实现 cache refill 或 writeback，可以使用
AXI burst；递增突发访问使用 `arburst`/`awburst = 2'b01`，并正确处理 `rlast`/`wlast`。

字节、半字和字写操作必须正确驱动 `wstrb`。读操作可以按字读取后在 CPU 内部选择对应字节或半字，
但送到 AXI 的地址仍应与软件访问的 SoC 地址一致。如果 CPU 不使用 AXI cache 属性，
`arlock`/`awlock` 可以固定为 `0`，`arprot`/`awprot` 可以固定为 `0`，
`arcache`/`awcache` 也可以固定为常量。

## 可暂时简化的端口

以下端口必须保留在 `core_top` 定义中，但在早期调通阶段可以先做简单 stub：

- `intrpt`：当前在 `soc_top` 中接为 `8'h0`。如果软件不打开中断，可以先不实现中断处理。
- `break_point`、`infor_flag`、`reg_num`、`ws_valid`、`rf_rdata`：历史调试寄存器读取接口。
  `soc_top` 中输入接为低电平，输出未使用，因此可以先令 `ws_valid = 1'b0`、
  `rf_rdata = 32'b0`。
- `debug0_wb_*`：硬件运行本身不依赖这些信号，但仿真跟踪、定位错误和性能测试调试强烈建议接上。
  如果暂时不接，可以全部置零，但会降低调试可见性。
- AXI 旁带信号 `arlock`、`awlock`、`arcache`、`awcache`、`arprot`、`awprot`
  以及 AXI ID：对单发射或简单 CPU 可以先使用常量，但端口必须存在。

## 源文件约定

发布仓库不包含 CPU 实现。使用前需要在 `rtl/ip/myCPU/` 下加入定义 `core_top` 的
`.v`/`.sv` 源文件，内部目录可以自行组织，也不要求存在 `mycpu.h`。Vivado 额外识别
`.xci`/`.xcix` IP 文件；不要提交 `.Xil`、IP 输出目录、仿真 netlist 或 Vivado 工程目录。

当前板级输入时钟为 50 MHz，PLL 配置的 `cpu_clk` 约为 50 MHz，`sys_clk` 为 25 MHz。
XSIM 使用相同的双时钟关系；Verilator 为提高速度暂时令 CPU 和系统总线使用同一时钟，
因此 Verilator 适合功能回归，跨时钟和板级时序仍需由 XSIM 与 Vivado 实现报告验证。

## 软件与仿真

生成 supervisor、测试输入和参考结果：

```bash
cd sdk/software/examples/supervisor
./build_all.sh
cd ../../../..
```

运行完整 Verilator 回归：

```bash
python3 sim/run.py sdk/software/examples/supervisor/sim/suite.json
```

首次运行或软件修改后可增加 `--prepare`，使 suite 在所有测试开始前只构建一次软件。
单个场景、TCP 串口和波形参数见 `sim/README.md` 与 `sim/verilator/README.md`。

## Vivado 工程与 bitstream

在 Windows Vivado 2019.2 Tcl Shell 中，或从 WSL 调用 `vivado.bat`：

```bash
cd fpga
vivado -mode batch -source create_project.tcl
vivado -mode batch -source build_bitstream.tcl
```

bitstream 默认生成在 `fpga/project/Loongson_Soc.runs/impl_1/`。使用同一软件场景运行
XSIM 的方法见 `sim/README.md`。工程目录是生成物，不纳入版本控制。

## 第三方源码

`sdk/software/examples/supervisor/` 是 Git 子模块，上游地址为
<https://gitee.com/loongson-edu/supervisor.git>。首次克隆建议使用
`git clone --recurse-submodules <la32r_soc-url>`；已有工作树可执行：

```bash
git submodule update --init --recursive
```

修改 supervisor 时，先在子模块中提交并推送，再回到本仓库提交更新后的子模块指针。
父仓库只记录 supervisor 的提交 ID，不重复跟踪其源码和生成物。
