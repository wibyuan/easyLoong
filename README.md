# NSCSCC 2026 个人赛初赛提交模板

本仓库用于提交 LoongArch 或 MIPS SoC 设计，asm编译仅决赛阶段启用。

## 文件放置规范

- src/soc/：放置可由 Vivado 直接读取的 RTL，顶层模块必须命名为 thinpad_top。
- src/soc/xilinx_ip/<ip_name>/：每个 Xilinx IP 使用独立目录，只提交 .xci 或 .xcix。
- run_vivado/constraints/：放置板级引脚、时钟和时序约束 .xdc。
- asm/：提供 Makefile_la、Makefile_mips 和汇编入口。决赛阶段只保留目标架构的 Makefile，删除架构尾缀并命名为 Makefile，再编写 .s 程序。
- src/vivado_cannot/：放置 Vivado 不能直接综合的生成型 HDL 工程或说明。
- design.pdf：提交设计说明文档。

不要提交 Vivado 自动生成的 project/、.Xil/、*.runs/、*.cache/、ip_user_files/、*.dcp、*_stub.* 或网表文件。

## 提交要求

参赛者通常只修改 src/soc/、src/vivado_cannot/、run_vivado/constraints/、asm/、README.md 和 design.pdf。

.gitlab-ci.yml 与 run_vivado/flow/** 为受控流程文件，未经维护者确认不要修改。
