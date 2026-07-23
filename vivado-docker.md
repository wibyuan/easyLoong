# Vivado 2019.2 Docker 安装教程

## 前置条件

- WSL（Ubuntu）或原生 Linux，磁盘可用空间 >= 120GB
- Docker Engine
- Vivado 2019.2 安装包（Xilinx Unified Installer，约 27GB tar.gz）
- 目标 FPGA：xc7a200tfbg676-1（Artix-7，WebPACK 免费授权覆盖）

## 1. 安装 Docker 并配置镜像加速（国内）

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

## 2. 复制安装包到 WSL 本地磁盘

从 `/mnt/c/...` 复制到 WSL 原生文件系统（避免跨文件系统 I/O 开销）：

```bash
mkdir -p ~/vivado-installer
cp /mnt/c/Users/<用户名>/Downloads/Xilinx_Vivado_2019.2_1106_2127.tar.gz ~/vivado-installer/
```

## 3. 解压并生成安装配置文件

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

## 4. 创建安装脚本

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

## 5. 启动容器并安装 Vivado

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

## 6. 提交镜像并验证

```bash
docker commit vivado-install vivado:2019.2
docker run --rm vivado:2019.2 bash -c \
    "source /opt/Xilinx/Vivado/2019.2/settings64.sh && vivado -version"
```

## 7. 冷备份（可选）

```bash
docker save vivado:2019.2 -o vivado-2019.2-image.tar
```

恢复：`docker load -i vivado-2019.2-image.tar`

## 8. 清理安装临时文件

```bash
docker rm vivado-install
rm -rf ~/vivado-installer/Xilinx_Vivado_2019.2_1106_2127 \
       ~/vivado-installer/Xilinx_Vivado_2019.2_1106_2127.tar.gz
```

## 使用：项目构建 Bitstream

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

## 磁盘回收（Windows WSL）

WSL 的 `ext4.vhdx` 在删除文件后不会自动缩小。在 Windows 管理员 PowerShell 中执行：

```powershell
wsl --shutdown
diskpart
select vdisk file="$env:LOCALAPPDATA\Packages\<发行版>\ext4.vhdx"
compact vdisk
exit
```

## 注意：`docker run` 超时

`docker run` 是同步命令，Vivado 完成后自动返回，不需要设置超时。设置任意静态超时值都是多余的——过短会误中断，过长则无谓阻塞。

若需确认 Vivado 进度，读取 `vivado.log` 即可。
