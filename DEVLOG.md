# DEVLOG — 开发进度与已知问题

## 已验证

- [x] 仿真环境（Verilator 编译、MIF 加载、超时退出）
- [x] 五级流水线冒烟（PC 从 0x1c000000 启动，取指成功）
- [x] reset 向量 → supervisor init 代码线性执行
- [x] AXI 读写通路正常（BSS 清零、ExtRAM 存储、UART 写入均可完成）
- [x] fibonacci difftest 30K+ 条指令全流程通过（supervisor A/D/G/R/D 完整链路）
- [x] BL 指令 rd 修复：隐式写 r1(ra) 而非 instr[4:0] 的 offset 位
- [x] MMIO difftest 解决：UART LSR 等设备寄存器读值在 ref_exec 前注入 NEMU 内存
- [x] difftest mismatch 全状态暴露：commit group/instruction trace + 逐寄存器 diff + NEMU isa_reg_display
- [x] mul.w 指令实现：纯组合逻辑 `*` 运算符，DSP 可推断
- [x] cpucfg 指令实现：返回 CPUCFG 配置值（0x10），supervisor 据此跳过 cache 初始化
- [x] CSR 寄存器组 (`csr_regfile.sv`)：26 个完整 CSR + DMW0/DMW1 存储，difftest 全量接线
- [x] csrrd / csrwr / csrxchg 指令解码与执行：EX 阶段执行 CSR 读改写，结果走 ALU 路径
- [x] DMW 地址翻译：MEM 阶段组合逻辑匹配 DMW0/DMW1，支持 identity 映射与 UART uncached alias
- [x] 阶段 2-5 性能测试 DIFF=0 全通过：MATRIX (96×96), STREAM (~3 MiB), CRYPTONIGHT (2 MiB), MIXED
- [x] 阶段 1-5 difftest DIFF=1 全通过：全量 6 个测试均通过（2026-07-23）
- [x] NEMU cpucfg 兼容：la32r-nemu 添加 cpucfg 解码与 EHelper，修复解码表模式顺序
- [x] la32r-nemu 去 submodule 化：从 gitee 拉取新版并作为项目自有代码维护
- [x] difftest MIF 注入：支持 BaseRAM/ExtRAM MIF（含 `@` 地址标记）注入 NEMU，使数据依赖测试可通过

## 待完成

- [ ] DifftestTrapEvent 接入：模块已定义，未在 core.sv 实例化，异常/中断时需接入
- [ ] FPGA 上板实测：bitstream 烧录后实机运行各阶段测试

## Vivado FPGA 构建状态（2026-07-22）

### RTL 可综合性

- 全部模块通过 Vivado 2019.2 的 RTL Elaboration 阶段，无功能错误
- PLL IP（`clk_pll`）可在 out-of-context 综合中完成 5 个模块的模块级综合
- `default_nettype` directive 已从所有 CPU .sv 文件中移除（Vivado 2019.2 兼容性修复）
- `difftest.v` 保留 symlink，改由 `create_project.tcl` 从 `sources_1` 排除（该文件为 Verilator-only DPI-C）

### 阻塞：TclStackFree 崩溃 — 已解决

**现象**：RTL Elaboration 完成后，Vivado 崩溃输出 `TclStackFree: incorrect freePtr. Call out of sequence?`

**特征**：
- 66 个模块 `done synthesizing module` 全部正常完成
- 不打印 `synth_design completed successfully` 和 timing summary
- 崩溃位置在 Vivado C 层，Tcl `catch` 无法拦截
- `launch_runs` 将 run 标记为 failed，导致后续 `impl_1` 依赖断裂

**已验证无效的规避**：
- `-mode batch` / `-mode tcl` / GUI Tcl Console 直接执行 — 均崩溃
- `create_project -in_memory` / `open_project` — 均崩溃
- `-flatten_hierarchy none` / warning suppression — 均无效
- UNC 路径 vs D: 盘原生路径 — 与路径无关

**环境**：Vivado v2019.2, Windows 11 24H2 (build 10.0.26200), FPGA xc7a200tfbg676-1

**根因**：TclStackFree 为 Vivado 2019.2 在 Windows 11 24H2 上的兼容性 bug。该版本 Vivado 的 Tcl 运行时与新版 Windows 内存管理机制不兼容。

**解决方案**：在 Docker 容器内运行 Vivado 2019.2 on Ubuntu 18.04，完全绕过 Windows 版本问题。详见 [Vivado Docker 安装教程](#vivado-20192-docker-安装教程)。

### Bitstream 生成结果（2026-07-23）

Docker 容器内 Vivado 2019.2 on Ubuntu 18.04 一次性综合/实现成功：

| 阶段 | 结果 |
|------|------|
| RTL Elaboration | 66 模块全部通过 |
| 综合 (synth_design) | 0 errors, 228 warnings |
| 优化 (opt_design) | 0 errors |
| 布局 (place_design) | 0 errors, WNS=12.103 |
| 物理优化 (phys_opt_design) | 跳过（WNS >= 0.25ns，无需优化） |
| 布线 (route_design) | 0 errors, 全部网络完成 |
| 写入 bitstream | `soc_top.bit` (1.7 MB) |

**最终时序**：WNS=11.859ns, TNS=0.000, WHS=0.012ns, THS=0.000 — setup/hold 均无违例。

### Docker 环境已知问题与修复

**问题**：`difftest.v` 符号链接使用绝对路径（`/home/wibyu/easyLoong/difftest/difftest.v`），Docker 容器内项目挂载到 `/workspace` 后路径解析失败。

```
ERROR: [Vivado 12-172] File or Directory '/workspace/.../difftest.v' does not exist
```

**修复**：将 symlink 改为相对路径（`../../../../difftest/difftest.v`），宿主机和容器内均可正确解析。

### 代码修改

| commit | 说明 |
|--------|------|
| `default_nettype` 移除 | 所有 CPU .sv 文件 |
| `create_project.tcl` | `difftest.v` 从 `sources_1` 排除 |
| `add mul.w` | `decode.sv` + `alu.sv` + `common.sv` |
| `add cpucfg` | `decode.sv` + `core.sv` (EX 级 CPUCFG 查询) |
| `add CSR + DMW` | 新增 `csr_regfile.sv`，`decode.sv` (csrrd/csrwr/csrxchg)，`core.sv` (CSR 流水线 + DMW 翻译 + difftest 接线) |
| `update docs` | README / DEVLOG 同步进度 |
| `fix multi-driven rs1` | `decode.sv` rs1 从 `assign` 移入 `always_comb` 消除多驱动 |
| `nemu cpucfg` | NEMU 添加 cpucfg 解码 (decode.c) + EHelper (special.h) + 指令注册 (isa-all-instr.h) |
| `difftest MIF inject` | difftest 支持 BaseRAM/ExtRAM MIF 注入 NEMU（含 @ 地址标记） |
| `fix difftest.v symlink` | difftest.v 符号链接改为相对路径，兼容 Docker 挂载路径 `/workspace` |

## 已知局限

- MMIO 注入目前覆盖 0x1f000000-0x1f000fff，若后续阶段访问其他设备地址需扩展 is_mmio_addr。

## Vivado 2019.2 Docker 安装教程

### 前置条件

- WSL（Ubuntu）或原生 Linux，磁盘可用空间 >= 120GB
- Docker Engine
- Vivado 2019.2 安装包（Xilinx Unified Installer，约 27GB tar.gz）
- 目标 FPGA：xc7a200tfbg676-1（Artix-7，WebPACK 免费授权覆盖）

### 1. 安装 Docker 并配置镜像加速（国内）

```bash
sudo apt update && sudo apt install -y docker.io
sudo usermod -aG docker $USER
sudo service docker start
```

重新登录使 docker 组生效。国内网络需配置镜像加速器：

```bash
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://docker.m.daocloud.io"]
}
EOF
sudo service docker restart
```

### 2. 复制安装包到 WSL 本地磁盘

从 `/mnt/c/...` 复制到 WSL 原生文件系统（避免跨文件系统 I/O 开销）：

```bash
mkdir -p ~/vivado-installer
cp /mnt/c/Users/<用户名>/Downloads/Xilinx_Vivado_2019.2_1106_2127.tar.gz ~/vivado-installer/
```

### 3. 解压并生成安装配置文件

```bash
cd ~/vivado-installer
tar -xzf Xilinx_Vivado_2019.2_1106_2127.tar.gz
cd Xilinx_Vivado_2019.2_1106_2127
./xsetup -b ConfigGen -e "Vivado HL WebPACK" -l /tmp/vivado-test
```

生成的配置文件位于 `~/.Xilinx/install_config.txt`。编辑该文件，将不必要的模块设为 `0` 以减小安装体积：

```ini
Edition=Vivado HL WebPACK
Destination=/opt/Xilinx
Modules=Virtex UltraScale+ HBM:0,Zynq UltraScale+ MPSoC:0,DocNav:0,Kintex UltraScale:0,Zynq-7000:1,System Generator for DSP:0,Virtex UltraScale+:0,Kintex UltraScale+:0,Model Composer:0
InstallOptions=
CreateProgramGroupShortcuts=0
CreateShortcutsForAllUsers=0
CreateDesktopShortcuts=0
CreateFileAssociation=0
EnableDiskUsageOptimization=1
```

> **说明**：7 Series（含 Artix-7）是基础安装的一部分，无需额外勾选。`Zynq-7000:1` 可选，空间开销很小。

### 4. 创建安装脚本

```bash
cat > install_vivado.sh <<'SCRIPT'
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
export LANG=en_US.UTF-8

apt-get update && apt-get install -y locales && locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8

apt-get install -y \
    libncurses5 libncursesw5 libtinfo5 libstdc++6 libc6-dev libc6-dev-i386 \
    libx11-6 libxrender1 libxext6 libxi6 libxtst6 libxft2 libglib2.0-0 \
    libsm6 libice6 lib32z1 lib32stdc++6 libgtk2.0-0 libcanberra-gtk-module \
    libcanberra-gtk3-module net-tools lsb-release openjdk-11-jdk-headless

rm -rf /var/lib/apt/lists/*

/installer/xsetup \
    --batch Install \
    --agree XilinxEULA,3rdPartyEULA,WebTalkTerms \
    --config /tmp/install_config.txt
SCRIPT
chmod +x install_vivado.sh
```

### 5. 启动容器并安装 Vivado

```bash
docker pull ubuntu:18.04

docker run -d --name vivado-install \
    -v $(pwd):/installer:ro \
    -v /path/to/install_config.txt:/tmp/install_config.txt:ro \
    -v $(pwd)/install_vivado.sh:/tmp/install_vivado.sh:ro \
    ubuntu:18.04 tail -f /dev/null

docker exec vivado-install bash /tmp/install_vivado.sh
```

安装耗时约 30-60 分钟，取决于磁盘 I/O。

### 6. 提交镜像并验证

```bash
docker commit vivado-install vivado:2019.2
docker run --rm vivado:2019.2 bash -c \
    "source /opt/Xilinx/Vivado/2019.2/settings64.sh && vivado -version"
```

### 7. 冷备份（可选）

```bash
docker save vivado:2019.2 -o vivado-2019.2-image.tar
```

恢复：`docker load -i vivado-2019.2-image.tar`

### 8. 清理安装临时文件

```bash
docker rm vivado-install
rm -rf ~/vivado-installer/Xilinx_Vivado_2019.2_1106_2127 \
       ~/vivado-installer/Xilinx_Vivado_2019.2_1106_2127.tar.gz
```

### 使用：项目构建 Bitstream

```bash
cd easyLoong/nscscc-solo-la-soc/fpga

# 创建 Vivado 项目
docker run --rm -v $(pwd)/../..:/workspace vivado:2019.2 bash -c \
    "source /opt/Xilinx/Vivado/2019.2/settings64.sh && \
     cd /workspace/nscscc-solo-la-soc/fpga && \
     vivado -mode batch -source create_project.tcl"

# 综合 + 实现 + 生成 bitstream
docker run --rm -v $(pwd)/../..:/workspace vivado:2019.2 bash -c \
    "source /opt/Xilinx/Vivado/2019.2/settings64.sh && \
     cd /workspace/nscscc-solo-la-soc/fpga && \
     vivado -mode batch -source build_bitstream.tcl"
```

### 磁盘回收（Windows WSL）

WSL 的 `ext4.vhdx` 在删除文件后不会自动缩小。在 Windows 管理员 PowerShell 中执行：

```powershell
wsl --shutdown
diskpart
select vdisk file="$env:LOCALAPPDATA\Packages\<发行版>\ext4.vhdx"
compact vdisk
exit
```
