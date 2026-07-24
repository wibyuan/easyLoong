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
- [x] Vivado XSim 行为仿真通过：simple supervisor 测试在 XSim RTL 仿真中完整通过（2026-07-23）
- [x] Post-Implementation 仿真基础设施就绪：TCL 脚本 + Python runner + 无 XMR 门级 testbench
- [x] Vivado Makefile 工作流：`make build-bitstream` / `make vivado-sim-behavioral` / `make vivado-sim-post-impl`

## 待完成

- [ ] DifftestTrapEvent 接入：模块已定义，未在 core.sv 实例化，异常/中断时需接入
- [ ] FPGA 上板实测：bitstream 烧录后实机运行各阶段测试
- [x] dcache 模块创建：2 路组相联、256 组、16 字节行、8KB、写回+写分配、PLRU、关键字优先、两级流水、插入 core_top 的 dreq/dresp 路径
- [ ] dcache tag BRAM 初始化：Verilator 中 BRAM 初始值为 `'x`，tag valid bit 为 `'x` 导致 `s2_hit` 为 `'x`，`if(s2_hit)` 和 `else` 分支均不触发，dcache 永不对 CPU 请求响应。需加冷启动清零 FSM（256 个 tag 条目依次写 0）

## Vivado FPGA 构建状态（2026-07-23）

### RTL 可综合性

- 全部模块通过 Vivado 2019.2 的 RTL Elaboration 阶段，无功能错误
- PLL IP（`clk_pll`）可在 out-of-context 综合中完成 5 个模块的模块级综合
- `default_nettype` directive 已从所有 CPU .sv 文件中移除（Vivado 2019.2 兼容性修复）
- `difftest.v` 从 `create_project.tcl` 的 `collect_files` 阶段直接过滤（避免 Docker 内 symlink 解析失败）

### 已解决：TclStackFree 崩溃

Vivado 2019.2 在 Windows 11 24H2 上综合阶段崩溃（`TclStackFree: incorrect freePtr`），为操作系统兼容性 bug。通过在 Docker 容器内运行 Vivado 2019.2 on Ubuntu 18.04 绕过，详见 [vivado-docker.md](vivado-docker.md)。

### Bitstream 生成（2026-07-23，Docker 重建验证）

Docker 容器内 Vivado 2019.2 on Ubuntu 18.04 一次性综合/实现成功，与 DEVLOG 初次记录一致，验证可重复性：

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

**PLL 配置**：CLKIN1=50MHz → cpu_clk=66MHz (CLKOUT0), sys_clk=50MHz (CLKOUT1)。

### Vivado 仿真工作流

| target | 功能 | 状态 |
|--------|------|------|
| `make build-bitstream` | 综合+实现+生成 bitstream | ✅ 通过 |
| `make vivado-sim-behavioral` | XSim RTL 行为仿真 (simple) | ✅ 通过 |
| `make vivado-sim-post-impl` | Post-Implementation 门级时序仿真 | ⬜ 接口就绪，极慢 |

**行为仿真性能**：XSim RTL 仿真 simple 测试含编译约 2-5 分钟。与 Verilator（<1 秒）相比慢 1145 倍以上。日常迭代优先使用 `make test-all`（Verilator）。

**Post-Implementation 仿真**：门级网表 + SDF 时序反标，模拟 1000ns 消耗约 100 秒 CPU。完整测试需数小时，暂不推荐，接口已保留。

**Post-Impl 关键实现**：
- `sim/mycpu_tb_post_impl.v`：无 XMR（跨层级引用）的门级 testbench，通过 UART_TX 引脚逐 bit 解码 supervisor 输出
- `sim/xsim/run_post_impl.tcl`：Post-Implementation 仿真 TCL 脚本（自动切换 testbench top）
- `sim/run_post_impl.py`：Python runner（复用 scenario JSON 格式）

### Python 3.6 兼容性修复

Vivado 2019.2 Docker 镜像基于 Ubuntu 18.04（Python 3.6），修复了以下不兼容调用：
- `subprocess.run(text=True)` → `universal_newlines=True`
- `shlex.join()` → `' '.join(shlex.quote())`
- `is_wsl()` + `has_wslpath()` 判断，避免 Docker-on-WSL2 内误调用 wslpath

## 已知局限

- MMIO 注入目前覆盖 0x1f000000-0x1f000fff，若后续阶段访问其他设备地址需扩展 is_mmio_addr。

## Vivado 2019.2 Docker 环境

TclStackFree 崩溃的解决方案及完整安装教程见 [vivado-docker.md](vivado-docker.md)。
