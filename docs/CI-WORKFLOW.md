# GitLab CI 提交工作流

## 快速开始

```bash
./scripts/submit-ci.sh                # 一键提交（自动生成分支名）
./scripts/submit-ci.sh my-branch      # 指定分支名
```

脚本自动完成：基于 `gitlab/main` 建 worktree → 展开 `src/soc/` 符号链接 → 复制约束 → 提交并推送。**不要手动执行这些步骤。**

> ⚠ **红线**：禁止直接 `git push gitlab <开发分支>`（如 `master`/`wip/*`）。pre-receive 钩子会拒绝任何与 protected `main` 不一致的推送，且开发分支本身也不携带 CI 适配层。所有 CI 提交一律走 `scripts/submit-ci.sh`。

## 概述

easyLoong 项目通过组委会提供的 GitLab 平台（`OJ_HOST_REDACTED:18002`）进行 CI 自动综合与评测。CI 流水线由组委会维护，参赛者无需修改管道配置。

## 目录结构说明

```
easyLoong/
├── nscscc-solo-la-soc/rtl/   # 原始 RTL 源码（主开发目录）
│   ├── soc_top.v             # SoC 顶层（端口: clk, reset, UART_RX, UART_TX）
│   └── ip/                   # IP 模块
│       ├── myCPU/            # CPU 核心 RTL
│       ├── PLL_2019_2/       # PLL IP（含 clk_pll.xci）
│       └── ...
├── src/soc/                  # CI 适配层（符号链接 → 原始 RTL）
│   ├── thinpad_top.v         # 包装器：soc_top → thinpad_top 接口
│   ├── soc_top.v             → ../../nscscc-solo-la-soc/rtl/soc_top.v
│   ├── config.h              → ../../nscscc-solo-la-soc/rtl/config.h
│   ├── myCPU/                → ../../../nscscc-solo-la-soc/rtl/ip/myCPU/
│   ├── xilinx_ip/clk_pll/    # PLL XCI（实际文件，非符号链接）
│   └── ...
├── run_vivado/
│   ├── flow/                 # [受保护] CI 构建脚本（组委会提供）
│   │   ├── create_vivado_project.tcl
│   │   ├── implement_design.tcl
│   │   ├── generate_bitstream.tcl
│   │   ├── lint_hdl.py
│   │   └── check_timing.py
│   └── constraints/
│       └── soc.xdc           # 管脚约束（适配 thinpad_top 端口名）
├── .gitlab-ci.yml            # [受保护] CI 触发配置
└── scripts/
    └── submit-ci.sh          # 一键提交脚本
```

## 接口适配

组委会 CI 期望顶层模块名为 `thinpad_top`，而我们的设计顶层是 `soc_top`。`thinpad_top.v` 包装器完成端口映射：

| thinpad_top 端口 | soc_top 端口 | 说明 |
|-----------------|-------------|------|
| `clk_50M` | `clk` | 系统时钟 |
| `reset_btn` | `reset` | 复位 |
| `txd` | `UART_TX` | 串口发送 |
| `rxd` | `UART_RX` | 串口接收 |
| `leds`, `dpy0/1`, `dip_sw`, `touch_btn` | 同名 | GPIO |
| `base_ram_*`, `ext_ram_*` | 同名 | SRAM |
| `video_*` | 同名 | DVI 输出 |

## 受保护文件

以下文件受服务端 pre-receive 钩子保护，必须与远程 `main` 分支完全一致，**不得修改**：

- `.gitlab-ci.yml`
- `run_vivado/flow/` 目录下所有文件

任何对上述文件的修改都会导致推送被拒绝。

## CI 流水线流程

提交到非 `main` 分支后，GitLab CI 自动执行：

1. **创建 Vivado 工程** — `create_vivado_project.tcl` 扫描 `src/soc/` 下所有 RTL 文件
2. **HDL 代码检查** — Verilator lint（`lint_hdl.py`），检查语法和设计规范
3. **综合与实现** — Vivado 2019.2 综合、布局布线
4. **时序检查** — WNS ≥ 0 才通过
5. **生成比特流** — 产出 `thinpad_top.bit`

### 时序检查策略（HARD LIMIT）

CI 的时序检查**只能使用默认综合/实现策略**（`create_vivado_project.tcl` 中注释掉的 `Flow_PerfOptimized_high` / `Performance_Explore` 不可启用）：

- `run_vivado/flow/` 受 pre-receive 钩子保护，无法通过开发分支提交任何 strategy 改动；只有先更新 gitlab/main 上的 flow/ 本身才可能启用，默认视为不可行。
- 因此**能带入 CI 的时序优化只有两类**：RTL 改动、XDC 约束（Pblock、时钟、I/O delay 等）。Performance_Explore 等策略只允许在本地实验（本地 tcl 放 `run_vivado/flow/` 外或确认不提交）。
- 结论：100MHz 目标必须让**默认策略下 WNS ≥ 0**；策略优化只能作为本地参考，不能依赖它过 CI。

## 提交前检查清单（新增 RTL 文件时必读）

`submit-ci.sh` 从**当前分支的工作区**展开 `src/soc/` 的符号链接。若在 `nscscc-solo-la-soc/rtl/` 下**新增**了 `.sv/.v` 文件（例如新增 cache 模块），必须先在 `src/soc/` 对应目录补上同名符号链接并提交，否则 CI 分支缺文件：

```bash
ln -s ../../../nscscc-solo-la-soc/rtl/ip/myCPU/新文件.sv src/soc/myCPU/新文件.sv
git add src/soc/myCPU/新文件.sv
git commit -m "ci: add <新文件> symlink to the CI adapter layer"
```

Verilator 仿真直接读 `nscscc-solo-la-soc/rtl/`，不走 `src/soc/`，因此这类遗漏**不会在仿真中暴露**，只会在 CI 的 HDL Lint 报 `Cannot find file containing module`。

## 提交步骤

### 方式一：一键提交脚本

```bash
# 从当前 master 自动创建并推送提交分支
./scripts/submit-ci.sh

# 指定分支名
./scripts/submit-ci.sh my-submission-v2
```

### 方式二：手动提交

```bash
# 1. 基于模板创建分支
git checkout -b submit-v2 gitlab/main

# 2. 引入 RTL 源码（解决符号链接）
rsync -a --copy-links src/soc/ src/soc_tmp/
git checkout submit-v2
cp -r src/soc_tmp/* src/soc/
rm -rf src/soc_tmp

# 3. 复制约束文件（从当前开发分支带过来）
cp <开发分支>/run_vivado/constraints/soc.xdc run_vivado/constraints/soc.xdc 2>/dev/null || true

# 4. 提交并推送
git add -A
git commit -m "CI submission"
git push gitlab submit-v2
```

### 查看 CI 状态

1. 访问 GitLab Web UI: `http://OJ_HOST_REDACTED:18001`
2. 进入项目 → CI/CD → 作业
3. 点击作业状态查看日志

### 推送后验证（可选但推荐）

确认 CI 分支确实携带了预期 RTL（尤其是新增文件）：

```bash
git fetch gitlab <提交分支>
git ls-tree gitlab/<提交分支> src/soc/myCPU/ | grep -E "l1dcache|l2dcache"
git log --oneline gitlab/<提交分支> -2   # 应显示 "CI submission from <开发分支> @ <hash>"
```

### 提交评测

1. 登录远程 FPGA 实验平台
2. 进入"自动评测"页
3. 选择"显示编译结果列表"
4. 双击编译通过的任务标记为最终提交版本

## 本地开发

本地开发完全不受 CI 适配层影响：

```bash
make build           # 编译 NEMU + supervisor
make test-all        # 运行全部 6 个 Verilator 差分测试
make build-bitstream # 本地 Vivado 综合（需 Docker + Vivado 2019.2）
```

## 常见问题

### 推送被拒绝：`.gitlab-ci.yml and run_vivado/flow must match`

提交分支必须基于 `gitlab/main` 创建。使用 `./scripts/submit-ci.sh` 可自动处理。

### CI 报 `Cannot find file containing module`

新增的 RTL 模块没有在 `src/soc/` 补符号链接（见「提交前检查清单」）。仿真不会暴露此问题。

### HDL Lint 失败

运行本地 Verilator 检查：

```bash
cd run_vivado && verilator --lint-only -Wall -Wno-fatal \
  -Wno-DECLFILENAME -Wno-PINCONNECTEMPTY -Wno-UNUSED \
  -DSIMULATION=1 --top-module thinpad_top \
  $(for d in $(find ../src/soc -type d); do echo "-I$d"; done) \
  $(find ../src/soc -name '*.v' -o -name '*.sv')
```

### 时序不满足（WNS < 0）

降低 CPU 主频，或优化关键路径逻辑。
