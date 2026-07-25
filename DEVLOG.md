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
- [x] icache 模块创建：2 路组相联、256 组、16 字节行、8KB（只读）、PLRU、关键字优先、两级流水、插入 core_top 的 ireq/iresp 路径
- [x] icache tag BRAM 初始化：`S_INIT` 冷启动 FSM 同时写两路 tag = 0（valid=0），256 周期完成
- [x] icache 流水线幽灵命中修复：命中后 `s2_valid` 和 `s1_valid` 同时清零，避免旧请求参数推进到 S2 形成错误命中（⚠ workaround，见待完成列表）
- [x] icache 与 dCache 接口隔离：iCache miss 通过 arbiter 现有 `ireq` 端口访存，与 dCache 的 `dreq` 端口独立仲裁
- [x] fetch_unit 双重跳转修复：JAL/BL 在 ID 级的 `do_id_jump` 和 EX 级的 `do_ex_flush` 先后将 PC 设到同一跳转目标。`do_ex_flush` 在目标指令从 icache 到达的同一周期重复设置 next_pc，覆盖了本应发生的 `pc+4` 自增，导致 fetch_unit 重复请求同一地址 → 双重提交到 WB。修复：`do_ex_flush` / `do_id_jump` 仅在 `pc_current != jump_target` 时生效（2026-07-24）
- [x] icache difftest simple 通过：dcache 幽灵 store hit 修复（Bug 7, 7639ae4）解决 #10120 sp=0。simple difftest DIFF=1 通过
- [x] icache difftest stream 通过：regfile 写旁路修复（Bug 8, b43ffec）解决 load→branch 转发窗口错过问题。stream 3.9M 条指令 DIFF=1 通过（2026-07-24）
- [x] CACOP 指令实现：decode + core pipeline 集成 + dcache code 0x01/0x09 + icache code 0x00（2026-07-25）
- [x] IBAR 指令实现：hint=0 流水线冲刷（2026-07-25）
- [x] CPUCFG 修复：0x10 报告 I/D cache 存在，0x11/0x12 返回 cache 几何参数，NEMU ref 同步更新（2026-07-25）
- [x] dcache FLUSH_DCACHE 通过：stage 2-5 全量数据比对通过（2026-07-25）
- [x] dcache cacheable 属性支持：基于 CRMD/DMW 计算 cacheability，dcache 门控 is_cachable（2026-07-25）
- [x] fibonacci difftest 通过：uncache kernel（DA 模式）下 dcache bypass，store 直写 SRAM，I/D 一致性正确（2026-07-25）

## 待完成

- [ ] DifftestTrapEvent 接入：模块已定义，未在 core.sv 实例化，异常/中断时需接入
- [ ] FPGA 上板实测：bitstream 烧录后实机运行各阶段测试
- [ ] Cache 幽灵命中修复去幽灵化：Bug 4/5 的 "修复" 本质是每次 hit 后强制空泡 1 周期（清空 s1_valid），等效于人为阻塞。正确的做法是在 BRAM 读延迟后的 S2 阶段做组合逻辑 tag 比较，而非靠丢弃 S1 请求避错。当前 workaround 导致 cache 流水线出现无谓的吞吐空洞。

## 当前 difftest 状态（2026-07-25，CACOP/IBAR/cacheable 实现后）

| 测试 | DIFF=1 difftest | 数据比对 | 指令数 |
|------|-----------------|----------|--------|
| simple | ✅ 通过 | N/A | ~170 |
| stream | ✅ 通过 | ✅ 通过 | ~390 万 |
| matrix | ✅ 通过 | ✅ 通过 | ~560 万 |
| mixed | ✅ 通过 | ✅ 通过 | ~30 万 |
| cryptonight | ✅ 通过 | ✅ 通过 | ~2300 万 |
| fibonacci | ✅ 通过 | ✅ 通过 | ~34.5K |

### 修复记录

#### Bug 9: dcache 写回泄漏 addr_ok/data_ok 到后续 refill 导致 load 返回 0（2026-07-25, 95ba59d + 7e70198）

matrix/mixed/cryptonight 三个测试中 load 指令均返回 0x00000000。根因：dcache 写回脏行时，arbiter 的 write addr_ok 在写回结束后仍保持 1，dcache 误判为 refill read 的 addr_ok，提前进入 S_REFILL_WAIT。随后 write bvalid 触发 w_dresp_data_ok=1，被 dresp.data_ok 合并传递，dcache 误认为 refill 数据到达 → 关键字转发 data=0（r_dresp_data 默认 0）。

##### 修复 1：dcache 拆分 S_REFILL_REQ（95ba59d）

将 S_REFILL_REQ 拆分为 S_REFILL_SEND（无条件发请求 + 延迟一周期）+ S_REFILL_ACK（检查 addr_ok）。确保 write addr_ok 在进入 ack 检查前已释放，消除写回→refill 临界区的 addr_ok 泄漏。

##### 修复 2：arbiter 抑制写 data_ok（7e70198）

增加 `dreq_read_pending` 标志：接受 dreq 读请求时置 1，读数据返回时清 0。在 pending 期间，`dresp.data_ok` 仅包含 `r_dresp_data_ok`，不合并 `w_dresp_data_ok`。防止 write bvalid 冒充 read data_ok。\n\n##### 效果：5/6 测试 difftest 通过，fibonacci 仍因 I/D 一致性（dcache flush 缺失）失败，见下方已知问题。

stream difftest 在 #3942292 处失败：FLUSH_DCACHE 函数中 `ld.w $r12, $r12, 0` → `beq $r12, $r0, target` 序列，load 在 MEM 等待 dcache 返回期间整个流水线被 lsu_not_ready 停滞。当 load 完成进入 WB 时 branch 仍在 IF/ID，需额外 1 周期到达 EX，此时 load 已从 WB 退休（mem_wb_out.valid=0），转发失败。register file 的 rd1/rd2 输出无写旁路，branch 在 ID 阶段读到 regfile 旧值并 latch 进 id_ex_out，导致 EX 阶段 forward_a 为旧值 → branch 判定错误。

**修复**：`regfile.sv` 的 `rd1`/`rd2` 增加 write-bypass：`assign rd1 = (wen && wa == ra) ? wd : regs[ra]`。load 在 WB 写寄存器时，同一周期 branch 在 ID 读到新值并 latch，EX 阶段转发正确。

**效果**：difftest stream 3.9M 条指令全部通过。⚠ 自校验 4084 处 mismatch 为 dcache flush 缺失导致，非本修复范围。

#### Bug 7: dcache store 命中后 s1_valid 未清零 → 幽灵 hit 污染 load（2026-07-24, 7639ae4）

dcache 在 store 命中 S2 时，`else if (s2_valid)` 路径仅清零 `s2_valid`，未清零 `s1_valid`。s1_valid 保留为 stale 值（store 地址/origin），下个周期 s1_stall 降为 0 后 stale S1 推进到 S2 形成幽灵 store hit。若 LSU 恰在此周期发起 load 请求，误将幽灵 hit 的 `data_ok=1` 当 load 完成信号 → `rdata_out=0`（stores 不返回 data）→ sp=0。

**修复**：在 `else if (s2_valid)` 路径中增加 `s1_valid <= 1'b0`，与 load hit 修复（Bug 5）对称。阻止 stale S1→S2 推进。

**效果**：difftest simple 从 #10120 → 通过（~170 条指令）。

#### Bug 6: fetch_unit 双重跳转提交（2026-07-24, 28f3546）

JAL/BL 的 `do_id_jump`（ID 级）和 `do_ex_flush`（EX 级）先后将 PC 设到同一跳转目标。`do_ex_flush` 在目标指令从 icache 到达的同一周期重复设置 next_pc = ex_jump_pc，if-else 优先级高于默认的 `pc+4` 自增，导致 fetch_unit 重复请求同一地址，同一条指令两次进入流水线 → 两次 WB 提交。difftest 每次 posedge 捕获一次 commit，NEMU 执行两条指令而 DUT 只执行一条，t1 寄存器不匹配。

**修复**：`fetch_unit.sv` 中 `do_ex_flush` 和 `do_id_jump` 仅在 `pc_current != jump_target` 时生效。

**效果**：simple difftest 从 #9169 推进至 #10120。

#### Bug 5: dCache load 命中后 s2_valid 未清零 → 幽灵命中（2026-07-24）

dCache 流水线在 load 命中 S2 后，时序逻辑无条件执行 `s2_valid <= s1_valid`（`!s1_stall` 为真），导致 `s2_valid` 额外保持 1 周期。下一周期 LSU 已切换到新请求，却收到幽灵 `data_ok=1` 和旧数据。

**修复**：当 `s2_valid && s2_hit && !s2_op && is_cachable(s2_addr)` 时，同时清零 `s2_valid` 和 `s1_valid`。与 icache Bug 4 修复一致。

**效果**：diffest simple 从 #198 错误推进至 #9169，t1 寄存器 mismatch（0x1c7f0080）已消除。

⚠ **已知：此修复是 workaround**。清空 `s1_valid` 导致每次 hit 后强制 1 周期空泡，等效于人为阻塞，降低 cache 吞吐。正确修法应为在 S2 用组合逻辑直接从 BRAM 读出的 tag 做比较（而非依赖流水线移位），天然消除跨级数据依赖。见待完成列表。

---

## dcache bug 修复记录（2026-07-24）

### Bug 1: tag BRAM 未初始化 → s2_hit = X → 死锁

Tag BRAM 在 Verilator 中初始值为 `'x`，导致 `s2_hit` 解析为 `'x`，`if(s2_hit)` 和 `else` 分支均不触发，dcache 永不对 CPU 请求响应。

**修复**：增加 `S_INIT` 冷启动 FSM 状态（复位后首个状态），依次写 tag_mem[0][0..255] 和 tag_mem[1][0..255] = 21'd0（valid=0），共 512 周期。完成后进入 `S_IDLE`。此期间 `s1_stall=1` 阻塞所有 CPU 请求。

### Bug 2: rf_cnt 过早递增 → rf_buf 错位 → 关键字优先转发数据错

`rf_cnt` 在 `S_REFILL_REQ` 收到 `addr_ok` 时立即递增，但对应数据在 `S_REFILL_WAIT` 才到达，此时 `rf_cnt` 已指向下一个 word 偏移，导致 `rf_buf[rf_cnt]` 写入错误位置。

**修复**：将 `rf_cnt` 递增从 `S_REFILL_REQ && addr_ok` 移至 `S_REFILL_WAIT && data_ok`，存入当前 `rf_cnt` 后才递增。

### Bug 3: fmask 完成判定延迟 → 冗余第 5 次 refill → 虚假 keyword 转发

`(&rf_fmask)` 在组合逻辑中只能看到寄存器旧值（上一周期），导致第 4 个 word 到达后仍判为未完成，产生一次多余的 `S_REFILL_REQ`。该冗余 refill 在收到第 5 个数据时再次触发 keyword 转发，将错误数据发给 LSU。

**修复**：改用 `(&(rf_fmask | (4'd1 << rf_cnt)))` 预判完成——将当前 word 对应 bit 也纳入判定，避免延迟。

### Bug 4: s2_valid 在 hit 后未清零 → 重复命中死循环 / 错误转发

`S_IDLE` 中 hit 完成后 `next_state = S_IDLE`，`s2_valid` 既不被 `!s1_stall` 更新（stall=1），也不被 `state != S_IDLE` 清零，导致同一请求被无限次重新命中。后续 miss 处理后回到 `S_IDLE` 时，`s2_valid <= old s1_valid` 复用旧值 1，导致旧请求（如前一 GOT load）重新命中，将错误 `data_ok` 返回给 LSU。

**修复**：
- 增加 `else if (s2_valid) s2_valid <= 1'b0` 在 `S_IDLE` 中 hit 后清零
- 在 `state != S_IDLE` 期间同时清零 `s1_valid <= 1'b0`，防止旧值传播

⚠ **已知：此修复是 workaround**。清空 `s2_valid`/`s1_valid` 导致每次 hit 后强制 1 周期空泡。正确修法见待完成列表。

| 参数 | 值 | 说明 |
|------|-----|------|
| 行大小 | 16 字节 (4 words) | offset = addr[3:0] |
| 路数 | 2 路组相联 | |
| 组数 | 256 组 | index = addr[11:4] |
| 总容量 | 8KB (2 × 256 × 16) | 满足比赛 ≥ 8KB 要求 |
| tag | 20 位 | addr[31:12] |
| 写策略 | 写回 + 写分配 | dirty 位 per line |
| 替换策略 | PLRU | 2 路时等价真 LRU |
| 关键字优先 | 是 | refill 时关键字词最先取回并转发 |
| 写回缓冲区 | 无 | 先写回再 refill，共用 AXI 接口 |
| 流水级 | 2 级 (TAG + DATA) | S1 发 BRAM 读地址，S2 比较 tag 并响应 |
| 插入位置 | lsu ↔ axibus_arbiter | core_top.sv 中 dreq/dresp 路径 |
| 缓存范围 | 0x1c000000 – 0x1cffffff | BaseRAM + ExtRAM |
| BRAM 资源 | data: 8 × 256×32, tag: 2 × 256×21 | 约 4.5 BRAM36K |

## icache 参数（2026-07-24）

| 参数 | 值 | 说明 |
|------|-----|------|
| 行大小 | 16 字节 (4 words) | offset = addr[3:0] |
| 路数 | 2 路组相联 | |
| 组数 | 256 组 | index = addr[11:4] |
| 总容量 | 8KB (2 × 256 × 16) | 满足比赛 ≥ 8KB 要求 |
| tag | 20 位 | addr[31:12] |
| 写策略 | 无关（只读） | 无 dirty / 写回机制 |
| 替换策略 | PLRU | 2 路时等价真 LRU |
| 关键字优先 | 是 | refill 时关键字词最先取回并转发 |
| 流水级 | 2 级 (TAG + DATA) | S1 发 BRAM 读地址，S2 比较 tag 并响应 |
| 插入位置 | fetch_unit ↔ axibus_arbiter | core_top.sv 中 ireq/iresp 路径 |
| 缓存范围 | 0x1c000000 – 0x1cffffff | 全覆盖，无 uncached 路径 |
| inv_all | 256 周期全失效 | 同时写两路 tag = 0（valid=0） |

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

### Bitstream 构建耗时

| 日期 | 综合 | 实现 | 总计 | 关键参数 |
|------|------|------|------|----------|
| 2026-07-23 | ~7min | ~20min | ~27min | `-jobs 4`, maxThreads 默认 |
| 2026-07-25 (CACOP后) | 7:31 | 20:41 | 28:12 | `-jobs 4`, maxThreads 默认 |
| 2026-07-25 (优化后) | 6:57 | **11:43** | **18:40** | `-jobs 8`, maxThreads=16 |

> 优化后 route_design 从 13:16 降至 4:23（~3x 提速）；综合 + 实现总耗时从 ~28min 降至 ~19min。
> 最新 bitstream 时序：WNS=4.330ns, WHS=0.075ns (33MHz cpu_clk)。

**PLL 配置**：CLKIN1=50MHz → cpu_clk=33MHz (CLKOUT0), sys_clk=25MHz (CLKOUT1)（经 XCI 确认，非之前错误记载的 66/50MHz）。

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

## GitLab CI 提交记录 (2026-07-25)

### submit-v1

分支 `submit-v1`，基于 `gitlab/main`。HDL Lint 通过，综合+实现通过，**时序失败（WNS=-1.274 ns）**。

失败原因：`run_vivado/constraints/soc.xdc` 中 `create_clock -name clk` 覆盖了 PLL board XDC 的 `clk_50M` 时钟名，`create_generated_clock` 的 hierarchical filter `*u_clk_pll*` 在 `thinpad_top` 包装器层级下匹配不到 PLL 管脚，`set_clock_groups` 引用的时钟名无效，导致 `cpu_clk`/`sys_clk` 间 CDC 路径被当成同步路径报时序。

另：`thinpad_top.v` 中 `rxd`/`txd` 声明为 `input`/`output`，而 `soc_top` 中 `UART_RX`/`UART_TX` 为 `inout`，导致 Verilator `ASSIGNIN` 错误。已在 `adfd535` 修复。

### submit-v2

分支 `submit-v2`，XDC 改为仅保留管脚分配（`f1b5498`），移除全部时钟和时序约束。**时序仍失败**。无 `set_clock_groups -asynchronous`，CDC 跨域路径仍被 Vivado 报时序违约。

### submit-v3 ✅ PASSED (2026-07-25)

分支 `submit-v3`，XDC 用 `create_clock -name clk_50M`（与 PLL 同名合并，仅 1 Warning）、`get_pins -hierarchical *CLKOUT*` 动态发现 PLL 时钟、补回 `set_clock_groups -asynchronous`。**全流程通过**：

- HDL Lint：passed
- Synthesis + Implementation：passed（`route_design Complete!`）
- **0 Critical Warnings**（对比 submit-v1 的 34 条）
- **WNS=7.811 ns, TNS=0, WHS=0.084 ns**
- phys_opt_design 跳过（WNS ≥ 0.25 ns，无需物理优化）

### submit-v4

分支 `submit-v4`，XDC 与 submit-v3 相同。预期结果一致。

### 当前结论

- XCI（`clk_pll.xci`）自首次提交 `69feb88` 以来从未变更，全程一致
- 时钟约束与 PLL IP XDC 冲突是时序失败的直接原因，非设计本身问题
- DEVLOG 此前错误记载 PLL 输出 66/50 MHz，经 XCI 确认实际为 33/25 MHz，已于 2026-07-25 修正。

### 工作流

- 开发分支 `master`，`src/soc/` 通过相对路径符号链接指向 `nscscc-solo-la-soc/rtl/`
- CI 提交用 `scripts/submit-ci.sh`，自动解析符号链接、创建基于 `gitlab/main` 的分支并推送
- 文档见 `docs/CI-WORKFLOW.md`

## 已知局限

- MMIO 注入目前覆盖 0x1f000000-0x1f000fff，若后续阶段访问其他设备地址需扩展 is_mmio_addr。

## Vivado 2019.2 Docker 环境

TclStackFree 崩溃的解决方案及完整安装教程见 [vivado-docker.md](vivado-docker.md)。
