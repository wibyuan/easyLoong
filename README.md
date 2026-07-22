# easyLoong — NSCSCC 2026 龙芯杯个人赛 (LoongArch)

基于 XC7A200T-2FBG676C FPGA 的 LoongArch 32-bit (LA32R) 精简版 CPU 实现。

## 1. 项目结构

```text
.
├── nscscc-solo-la-soc/          # ★ SoC 仿真与上板框架 (Verilator / XSIM / Vivado)
│   ├── rtl/
│   │   ├── soc_top.v            #   SoC 顶层
│   │   └── ip/
│   │       ├── myCPU/           #   ★ CPU RTL（core_top + 五级流水线模块）
│   │       ├── APB_UART/        #   UART 控制器
│   │       ├── Bus_interconnects/ # AXI 互联与 CDC
│   │       ├── confreg/         #   配置寄存器 + 数码管 + 按键
│   │       ├── ram_wrap/        #   外部 SRAM 封装
│   │       └── rst_sync/        #   复位同步
│   ├── fpga/                    #   Vivado 上板脚本 + 引脚约束 (soc.xdc)
│   ├── sim/                     #   仿真基础设施 (Verilator / XSIM)
│   ├── sdk/software/examples/
│   │   └── supervisor/          #   LA32R 监控程序 + 阶段 1-5 测试用例
│   └── sdk/toolchains/          #   LA32R 交叉编译工具链
├── difftest/                    # ★ Differential test 框架 (DPI-C)
├── la32r-nemu/                  # [git submodule] NEMU 参考模型
├── docs/                        # 参考文档、评测说明
├── Makefile                     # 根构建/测试入口
├── DEVLOG.md                    # 开发进度
└── README.md
```

## 2. CPU 设计

### 架构

- **流水线**：五级经典流水线 (IF → ID → EX → MEM → WB)，含数据转发与流水线冒险控制
- **寄存器文件**：32 个 32 位通用寄存器 (r0 恒为 0)
- **总线接口**：AXI4 Master（通过 `core_top` 封装 SoC 接口）
- **特权级**：当前仅支持 M-mode 直接地址模式

### 指令集覆盖

按 supervisor 无 cache 模式最小要求实现：

| 类别 | 已实现指令 |
|------|-----------|
| 立即数计算 | `lu12i.w`, `pcaddu12i` |
| 立即数 ALU | `addi.w`, `andi`, `ori`, `xori`, `slti`, `sltui` |
| 寄存器 ALU | `add.w`, `sub.w`, `slt`, `sltu`, `and`, `nor`, `or`, `xor`, `sll.w`, `srl.w`, `sra.w` |
| 移位立即数 | `slli.w`, `srli.w`, `srai.w` |
| 访存 | `ld.b`, `ld.h`, `ld.w`, `ld.bu`, `ld.hu`, `st.b`, `st.h`, `st.w` |
| 跳转/分支 | `b`, `bl`, `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`, `jirl` |

### 模块清单 (`nscscc-solo-la-soc/rtl/ip/myCPU/`)

| 文件 | 功能 |
|------|------|
| `common.sv` | LA32R 基础类型定义 |
| `core.sv` | 五级流水线顶层，例化全部子模块 |
| `pipeline_reg.sv` | 通用流水线寄存器 (stall/flush) |
| `regfile.sv` | 32×32 位寄存器文件 (r0=0) |
| `decode.sv` | 指令译码 |
| `alu.sv` | 32 位 ALU |
| `bcu.sv` | 分支条件判断 |
| `npc.sv` | 下一 PC 计算 |
| `fetch_unit.sv` | 取指单元 |
| `lsu.sv` | 访存单元 |
| `hazard_unit.sv` | 流水线冒险控制 |
| `axibus_arbiter.sv` | ibus/dbus AXI4 仲裁 |
| `core_top.sv` | AXI Master 接口封装 |

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
| 1 | 功能测试 | 斐波那契数列（裸机） | ✅ difftest 30K+ 条通过 |
| 2 | MATRIX | 矩阵乘加 | ⬜ 待 CSR 支持 |
| 3 | STREAM | ~3 MiB 连续访存 | ⬜ 待 CSR 支持 |
| 4 | CRYPTONIGHT | 2 MiB 内存访问 + 整数运算 | ⬜ 待 CSR 支持 |
| 5 | MIXED | 混合运算 | ⬜ 待 CSR 支持 |

## 5. 开发环境搭建

### Clone

```bash
git clone --recurse-submodules <this-repo-url>
cd easyLoong
```

### LA32R 交叉编译工具链

```bash
cd nscscc-solo-la-soc/sdk/toolchains
bash init.sh
```

### 构建

```bash
make build
```

自动完成 NEMU 参考模型编译 + supervisor 软件构建。

## 6. Verilator 仿真

从 easyLoong 根目录运行：

```bash
make test-simple          # 冒烟测试
make test-fibonacci       # 斐波那契
make test-matrix          # 矩阵乘加
make test-stream          # 连续访存
make test-cryptonight     # 密码学运算
make test-mixed           # 混合运算
make test-all             # 全部测试

DIFF=0 make test-simple   # 关闭 difftest，仅仿真
```

### 强制重新编译 RTL

```bash
FORCE_VERILATOR_REBUILD=1 make test-simple
```

## 7. Difftest 差分测试

每个时钟周期 WB 级提交一条已退休指令，通过 DPI-C 将 DUT 的 GPR/CSR 状态传入 C++ 层，同步步进 NEMU 参考模型执行同一条指令，逐条比对寄存器状态。

### DPI-C 接口

| Verilog 模块 | 功能 |
|-------------|------|
| `DifftestArchIntRegState` | 32 个 GPR |
| `DifftestInstrCommit` | WB 级提交信息 |
| `DifftestCSRState` | CSR 字段 |
| `DifftestIdlePC` | regcpy 缓冲区对齐 |
| `DifftestTrapEvent` | 陷阱事件（已定义，待接入） |

### Mismatch 时输出

1. Commit Group Trace（最近 16 组提交）
2. Commit Instr Trace（最近 16 条指令）
3. Register Diff（逐寄存器 REF vs DUT）
4. REF Regs（NEMU 完整寄存器 dump）

### MMIO 处理

DUT 从设备地址 (`0x1f000000-0x1f000fff`) load 时，将值注入 NEMU 内存，避免 NEMU 因缺少设备模型返回 0。

## 8. Vivado 上板

使用 `nscscc-solo-la-soc/fpga/` 下的 TCL 脚本：

```bash
cd nscscc-solo-la-soc/fpga
vivado -mode batch -source create_project.tcl
vivado -mode batch -source build_bitstream.tcl
```

引脚约束文件：`nscscc-solo-la-soc/fpga/constraints/soc.xdc`。

## 9. DEVLOG

开发进度与已知问题见 [DEVLOG.md](DEVLOG.md)。
