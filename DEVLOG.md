# DEVLOG — 开发进度与已知问题

## 已验证

- [x] 两级 dcache（直通式）上板通过（2026-08-02）：8KB 0-cycle L1 + 1MB 全 BRAM L2（全部 `ram_sdpram` 实例化），单元测试 15/15、difftest 6/6；上板四测试合计 **2045ms**（单级 2177ms，-6.1%）：matrix 190ms / stream 419ms / cryptonight 1399ms / mixed 37ms。详见「2026-08-02（续三）」
- [x] 1MB 单级 DCache 上板通过（2026-08-02）：WaitStart 超时根因定位为 **HUM 一致性回归**（S_REFILL_WRITE 写口覆盖 + HUM store 缺 dirty/PLRU + 响应/清除/写口门控不一致，`2c803d8`+`0365302` 修复）。上板全过：matrix 209ms / stream 566ms / cryptonight 1367ms / mixed 35ms（合计 -11% vs master）；**REQP-1839/1840 复位窗口嫌疑排除**。详见文末「1MB 单级 DCache」章节
- [x] 上板实测通过（2026-08-01）：`30e9c97`（非阻塞 dcache，当前 master）FPGA 实机全部测试通过；`2c4f3298`（写回/refill 重叠）上板全部 50 分已回退，排查记录见「写回/refill 重叠上板失败排查」
- [x] SRAM 固定时延校准（2026-08-01）：`axi2sram_sp_external.v` `ifdef VERILATOR` 每笔事务首拍 +16 周期，4 基准 difftest 估计 vs 上板偏差 -0.4%/-2.7%/-12.6%/-0.3%；**cryptonight 定为后续核心优化指标**（详见文末「SRAM 固定时延校准」章节）
- [x] 非阻塞 DCache（hit-under-miss，单 MSHR）（2026-07-31）：store miss 当拍接受 + refill 合并、refill 期间同拍服务其他行命中、读回写合并进 refill 写、load miss 当拍 addr_ok；修复 arbiter R_ARB 突发截断缺陷。stream IPC +25.1%、mixed +11.2%、cryptonight +7.9%、matrix +3.3%，全 6 测试 difftest + 数据比对 + 7 单元测试通过。详见下方「非阻塞 DCache（hit-under-miss，单 MSHR）」章节
- [x] ICache 0-cycle 命中路径实现（2026-07-30，wip/icache-0cycle）：ICache 标签 LUTRAM + 数据 BRAM 组合读取 + 去除 S1/S2 流水线。`req_hit` 组
合逻辑直接驱动 `data_ok`，fetch 延迟从 2 拍降至 0 拍。Ghost hit 仅用于 miss 检测（防止 redirect 当拍捕获错误地址），不再抑制 `data_ok`。fetch_unit 修复：所有状态下 `ireq.addr` 保持 `pc_current`（断开旧实现中 `data_ok→addr=0` 的组合环路）。功能验证到 instruction #35（difftest 因 pipeline EX/MEM flush 缺失导致的重复 commit 而失败，此为独立问题，非 icache 引入）。
- [x] 仿真环境（Verilator 编译、MIF 加载、超时退出）
- [x] AXI INCR Burst Refill + Writeback 实现（2026-07-27）：DCache refill 与 writeback 均由逐字握手改为单次 AXI INCR burst（refill 4 字一行一次 burst，writeback 4 字一行一次 burst）。arbiter 读写通道加入 burst 计数，Cryptonight 单次 miss penalty 从 87 → 30.5 周期（-65%），IPC 提升 41-79%。全部 5 个基准测试 difftest + 数据比对通过。
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
- [x] icache ghost hit workaround 修复（2026-07-26）：用 `just_hit` + `last_hit_addr` 寄存器精确检测 S1 stale 地址，仅在 s1_addr 与 s2_hit 地址相同时抑制 s1→s2 推进。消除了无条件清 s1_valid 的 1 周期强制空泡，icache 管道效率 access/s1_accept 从 33% 提升至 50%。
- [x] fetch_unit 消除 IDLE 死周期（2026-07-26）：REQ 状态在 data_ok 后不再回 IDLE；同时抑制 data_ok、do_ex_flush、do_id_jump 活跃时的 stale 请求。结合 icache 修复后，linear 代码 IPC +0.2%~+10.9%，Matrix 循环因无分支预测器致投机取指冲刷 +4.1% 周期（见下）。
- [x] dcache ghost hit workaround 修复（2026-07-26）：LSU 修复 + just_hit 机制替代 s1_valid 无条件清零，store hit stall 移除（见修复记录）
- [x] 分支预测器 BTFNT 实现（2026-07-26）：独立模块 `branch_predictor.sv`，含 ID 级重定向，difftest 结尾报告准确率
- [x] 流水线 Stall 七类拆解 difftest 集成（2026-07-26）：`DifftestStallState` DPI-C 模块 + `dcache.sv`/`icache.sv` `in_refill` 信号 + `hazard_unit.sv` `load_use_hazard` 暴露。按优先级 DCache Refill > ICache Refill > Load-Use > Branch Flush > DCache Hit Pipe > ICache Hit Pipe > Other 逐周期统计，仿真实结束时输出各类周期数和占 stall 百分比。全部 5 个基准测试通过

## 待完成

- [ ] DifftestTrapEvent 接入：模块已定义，未在 core.sv 实例化，异常/中断时需接入
- [x] FPGA 上板实测（2026-08-01）：`30e9c97`（非阻塞 dcache）实机全部测试通过；写回/refill 重叠（`2c4f3298`）全部 50 分已回退（见「写回/refill 重叠上板失败排查」）
- [x] dcache ghost hit workaround 修复（2026-07-26）：LSU 修复 + just_hit 机制替代 s1_valid 无条件清零，store hit stall 移除（见修复记录）
- [x] dcache 写缓冲/非阻塞化（2026-07-31）：store miss 当拍接受 + refill 合并、读回写合并进 refill 写、hit-under-miss 同拍服务其他行命中——refill 期间 store 不再阻塞（原占 stall 70-89% 的主瓶颈，见「非阻塞 DCache」章节）。残余阻塞：refill 期间到达的二次 miss（单 MSHR 上限）、顺序 load miss 延迟、写回→refill 串行（写回/refill 重叠已实现但上板失败回退，见「写回/refill 重叠上板失败排查」）

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
> 最新 bitstream 时序：WNS=4.330ns, WHS=0.075ns (50MHz cpu_clk)。

**PLL 配置**：CLKIN1=50MHz → cpu_clk=50MHz (CLKOUT0), sys_clk=25MHz (CLKOUT1)（经 XCI 确认）。

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

## dcache 增强实验（2026-07-26）

在五组实验中系统评估了组数、路数、行大小对命中率和 IPC 的影响。实验脚本位于 `experiments/dcache_sweep.sh`。

### 实验矩阵

| 实验 | 组数 | 路数 | 行大小 | 容量 | 变量 |
|------|------|------|--------|------|------|
| A (baseline) | 256 | 2 | 16B (4w) | 8KB | — |
| B | **512** | 2 | 16B | 16KB | 组数 ×2 |
| C | 256 | **4** | 16B | 16KB | 路数 ×2 |
| D | 256 | 2 | **32B** (8w) | 16KB | 行大小 ×2 |

### 命中率对比

| 测试 | A (baseline) | B (512组) | C (4路) | D (32B行) |
|------|-------------|-----------|---------|-----------|
| simple | 94.29% | 94.29% | 94.29% | 96.77% |
| stream | 75.00% | 75.00% | 75.00% | **87.50%** |
| matrix | 91.26% | 91.26% | 91.35% | — |
| mixed | 70.46% | 71.88% | 71.90% | **81.30%** |
| cryptonight | 52.95% | 53.12% | 53.12% | 54.52% |

### IPC 对比（32B 行 vs baseline 16B 行）

| 测试 | A IPC | D IPC | Δ |
|------|-------|-------|-----|
| stream | 0.085 | 0.0837 | -1.5% |
| mixed | 0.121 | 0.0989 | **-18.3%** |
| cryptonight | 0.091 | 0.0502 | **-44.8%** |

### 分析

**benchmark 访存模式分类：**

| 类型 | benchmark | 特征 | 主导 miss | 有效优化 |
|------|-----------|------|-----------|---------|
| 流式 | stream | 3MB 顺序访问，单次经过 | 强制 miss | 增大行大小 |
| 循环 | matrix | 96×96 矩阵，内层重用 | 接近饱和 | 无需优化 |
| 随机 | cryptonight | 2MB 随机访问 | 容量 miss | 几乎无效 |
| 混合 | mixed | 多种模式交织 | 容量+冲突 | 部分受益 |

**关键量化结论：**

1. **组数/路数扩容对命中率提升微乎其微**（+0.17%~+1.44%）。容量从 8KB 增至 16KB 在几 MB 工作集面前杯水车薪。

2. **32B 行对 stream/mixed 命中率有效**（+12.5%/+10.8%），因为强制 miss 减半。但对 cryptonight 几乎无效（+1.57%），因为随机访问模式无空间局部性可利用。

3. **IPC 在增大行大小后全面下降**。以 cryptonight 为例：miss 率从 47% 降至 45%，但每次 miss 的 refill 从 4 words 增至 8 words，miss 处理延迟 ~20→~40 周期。在五级顺序流水线 + 同步 refill 架构下，miss penalty 翻倍直接导致 IPC 腰斩（-44.8%）。

4. **BRAM 成本：** 2 路 16B 行 10 BRAM36K, 4 路 16B 行 20 BRAM36K, 2 路 32B 行 16 BRAM36K（16 banks × 256×32）。

### 结论

**当前 CPU 架构瓶颈不在 cache 参数配置，而在 miss 处理延迟。** 在顺序流水线、同步 refill、无写缓冲的设计中，任何增大 miss penalty 的优化都会被放大为 IPC 损失。下一步方向应优先考虑：写缓冲（store hit 异步化）、非阻塞 cache（load-under-miss）、或预取机制，而非继续调整组数/路数/行大小。

### Bug 10: Cryptonight FPGA 平台数据比对 FAIL — Verilator PASS

**现象**：Verilator difftest 全部 6 测试 DIFF=1 + 数据比对全 PASS。但竞赛 FPGA 平台 Cryptonight 功能得分仅 50%（program returned but data mismatch at `0x1c400001`: actual=`0x2e`, expected=`0x34`）。其他 4 个性能测试满分。

**可能原因**：

1. **CDC 跨域竞态（主疑）**：`cpu_clk=50MHz` 与 `sys_clk=25MHz` 为整数倍（2:1），`Axi_CDC` 异步 FIFO 在谐波时钟下有明确的读写仲裁窗口。Cryptonight 写回 8.88M words（其他测试总和的 5×），6σ 样本量放大了小概率 SRAM 写入错误。

2. **Verilator 与 FPGA SRAM 时序差异**：Verilator `fpga_sram_sp` 行为模型零延迟响应，FPGA 板 IS61WV102416ALL SRAM 有真实时序要求（写脉冲 ≥ 8ns）。50MHz 下写脉冲宽度 20ns，满足时序要求。

3. **Post-Implementation 门级仿真未跑**：SDF 反标的 Post-Impl 仿真能复现 FPGA 行为，因耗时过长（完整测试数小时）未执行。

**验证路径**：cpu_clk 改为 50MHz（2:1 倍 sys_clk）→ 提交 CI 验证 Cryptonight 是否 100 分。

### 已知局限

- MMIO 注入目前覆盖 0x1f000000-0x1f000fff，若后续阶段访问其他设备地址需扩展 is_mmio_addr。

## Vivado 2019.2 Docker 环境

TclStackFree 崩溃的解决方案及完整安装教程见 [vivado-docker.md](vivado-docker.md)。

### JVM segfault in reportTcl (2026-07-29)

**现象**：Docker 内 Vivado 2019.2 合成完成后，写 report 阶段 JVM crash（signal 11）：

```
Stack:
libc.so.6(+0x3ef10)
libc.so.6(_IO_vfprintf+0x3c)
librdi_synth.so(UParam::Base::reportTcl(...)+0x31d)
```

`synthes_design` 和 `Timing Optimization` 均成功（0 errors），`launch_runs` 返回 `synth_design ERROR` 为 crash 导致的误报。DCP checkpoint 正常生成。

**根因**：Vivado 2019.2 的 `report_timing_summary` 或 `report_utilization` 在部分环境下的内存损坏（非设计问题）。与 DEVLOG 早前记录的 `TclStackFree: incorrect freePtr`（Windows 11 24H2）同类。

**规避**：在合成脚本中用轻量级 `report_timing -max_paths 100` 替代 `report_timing_summary`。或合成后单独 `open_run synth_1`（在同一 Vivado session 内）提取时序，避免 `launch_runs` 内嵌 report 触发崩溃路径。

## 2026-07-29: DCache 标签 LUTRAM + 存储命中快速路径

**目标**：消除 DCache 存储命中流水线停顿（stall_dcache_hit_pipe 中 store 部分）。

**分析**：当前 DCache 标签和数据均在 BRAM 中（1 周期读延迟），形成 2 级流水线 (S1→S2)。每次缓存访问（含命中）都需要等待标签和数据从 BRAM 返回（1 周期），导致流水线停顿。标签 RAM 仅 ~10.5Kb，可放入分布式 RAM (LUTRAM) 实现组合逻辑读取（0 周期）。

**实现**：

1. **标签 RAM → LUTRAM**：`(* ram_style = "distributed" *)`，双读端口（组合逻辑 `req_tag_data` + 寄存器 `tag_rd_data` 供 S2/miss/cacop 路径使用）。
2. **组合逻辑命中检测**：在 S_IDLE 状态下，基于 `cpu_req` 直接组合读取标签判断命中（无流水线延迟）。
3. **直接存储命中路径**：S2 空闲时，存储命中在同周期触发 `addr_ok`+`data_ok`，直写 BRAM 数据，更新 PLRU/dirty，旁路 S1/S2。
4. **组合逻辑环路修复**：LSU 移除 `dreq` 信号对 `dresp.data_ok` 的组合依赖，避免同周期响应导致的 Verilator 振荡。

**结果**（Verilator difftest，全 6 测试 PASS）：

| 测试 | 旧 IPC | 新 IPC | ΔIPC | DCache Hit Pipe (旧) | DCache Hit Pipe (新) |
|------|--------|--------|------|----------------------|----------------------|
| Mixed | 0.176 | 0.186 | +5.5% | 13.3% | 9.8% |
| Matrix | 0.172 | 0.187 | +8.8% | 20.7% | 15.7% |
| Stream | 0.141 | 0.150 | +6.8% | 14.9% | 10.8% |
| Cryptonight | 0.163 | 0.172 | +5.4% | 9.9% | 6.0% |

**借鉴**：rvcpu 的 0 周期标签比较设计思想（组合逻辑标签读取 + `data_ok` 同周期触发），但仅应用于标签（数据保留 BRAM），限存储命中场景。

## 2026-07-29: 写缓冲区设计探讨

**目标**：消除 DCache Refill 期间的 store 阻塞（占所有 stall 的 34-61%）。

**尝试方案**：独立 `write_buffer` 模块（LSU 与 DCache 之间），存储命中直通 DCache，refill 期间缓冲 store。

**遇到的设计挑战**：

1. **存储缓冲 vs 直通决策**：独立模块无法获知 DCache 状态（refill 中 vs 空闲），需要额外 busy 信号或重试机制
2. **加载转发复杂度**：缓冲区内地址匹配的存储数据必须转发给后续加载（CPU 访存 RAW 冒险），需要 word 粒度比较和部分写入的合并逻辑
3. **排空与 CPU 请求冲突**：DCache 忙时排空被阻塞，同时占着 mem_req 接口，CPU 加载无法直通 DCache
4. **接口时序**：`mem_req` 寄存器输出引入虚假有效信号

**更可行的方向**：DCache 内部存储队列。DCache 已经知道自身状态（S_IDLE 时 fast path，S_REFILL 期间缓冲 store），无需外部 busy 信号，且数据和标签在同一模块内，加载转发可利用 BRAM 读路径自然解决。

**当前阶段结论**：标签 LUTRAM 优化已取得显著成果（+5-9% IPC），写缓冲区需更深入的设计准备后在后续阶段实施。

## 2026-07-29: CI 提交结果与后续时序优化注意事项

### CI 提交 `submit-20260729-1031`

分支基于 `gitlab/main`，含标签 LUTRAM 优化。

**结果**：❌ CI 超时（1 小时限制），非设计错误。

**阶段进展**：

| 阶段 | 结果 | 备注 |
|------|------|------|
| HDL Lint | ✅ 通过 | `(* ram_style = "distributed" *)` 语法无问题 |
| Synthesis | ✅ 通过 | 0 Critical Warnings, 0 Errors |
| Placement | ✅ 通过 | WNS=0.564 ns（setup slack 充足） |
| Routing | ⏳ 超时 | Phase 4 Rip-up And Reroute 中，超过 1h CI 限制 |

**分析**：XC7A200T 的 Vivado 实现（综合+布局+布线）总耗时本身接近 CI 时间上限（submit-v3/v4 均需数十分钟）。标签 LUTRAM 将 ~10.5Kb 存储从 BRAM 移至分布式 RAM（LUT），可能略微增加布线拥塞（布线初期 WHS=-0.193 有小量 hold 违例），但 Place 后 setup slack (WNS=0.564) 表明设计有充裕的时序余量。重跑 CI 或 runners 空闲时很可能通过。

### 后续修改者的时序注意事项

**⚠️ 标签 LUTRAM 优化已将部分存储资源从 BRAM 迁移至 LUT，再增加新逻辑时必须关注时序收敛**：

1. **监控资源使用**：分布式 RAM 消耗 LUT 资源。运行 `report_utilization` 检查 LUT 使用率。当前设计约消耗 4239 个 LUTNM（Place 阶段报告），XC7A200T 总 LUT 约 134K。
2. **优先使用 BRAM 做大存储**：标签 ~10.5Kb 适合 LUTRAM，更大的存储体（如写入缓冲区 FIFO、MSHR 等）应使用 BRAM
3. **每次改动后跑 CI**：确认 Vivado 综合+实现可通过，关注 `WNS` 和 `WHS`。Place 后 WNS < 0.5ns 时需考虑时序优化
4. **50MHz cpu_clk**：若后续提升时钟频率，时序压力会显著增加，需重新评估关键路径
5. **组合逻辑深度**：LUTRAM 组合读取路径 + 标签比较 + data_ok 生成均在单周期内，添加更多组合逻辑（如写入缓冲区地址匹配 CAM）可能成为关键路径

## 2026-07-29: DCache S_STORE_FINAL 消除 + cpu_resp 拆分

**目标**：降低 dcache FSM 组合逻辑深度，提升 synthesis WNS。

**分析**：dcache 的 `cpu_resp`（`addr_ok`/`data_ok`/`data`）和 FSM `next_state`、PLRU、dirty 等慢路径在同一个 200 行 `always_comb` 块中。Vivado 展平为单一 LUT 网络，使 PLRU 树 256→1 地址解码器（MUXF8/MUXF7 级联）插入 `data_ok` 到 core 的关键路径。

**实现**：
1. `cpu_resp` 从 FSM `always_comb` 移出为独立 `always_comb`（参照 rvcpu 的连续赋值模式）
2. 消除 `S_STORE_FINAL` 状态——refill 完成后直接回 `S_IDLE`，pending store 通过标准快速路径重试命中（标签刚写入，必然 hit）
3. 删除 `m_wdata`/`m_wstrb`/`m_size` 寄存器（不再需要）

**结果**（Verilator difftest，全 6 测试 PASS，IPC 不变）：

| 指标 | 修改前 | 修改后 |
|------|--------|--------|
| Synthesis WNS | 5.290ns | **5.388ns** |
| dcache 段最差路径排名 | #1 | #6+（slack ~5.539ns） |
| 最差路径来源 | dcache→pc_reg（26 级） | ALU(MUL)→CSR→ex_mem（15 级） |
| Logic levels（最差） | 26 | 15 |
| dcache 单元数 | 134,261 | 未变 |

> PLRU/dirty 加 `(* ram_style = "distributed" *)` 实验：无效（它们已被 Vivado 自动推断为 LUTRAM）。瓶颈是 always_comb 中的跨信号子表达式共享，非 RAM 类型。

## 2026-07-29: EX 阶段关键路径优化

**目标**：缩短 synthesis 关键路径，提升 WNS 为 Implementation 留出收敛余量。

**背景**：S_STORE_FINAL 消除后，synthesis WNS=5.388ns。最差路径为 `reg_ex_mem_ctrl[5]` → ALU(mul.w 2× DSP48E1 级联，~5.4ns) → CARRY4 → 4× LUT6(5 路结果 mux + CSR 读) → `reg_ex_mem_data[0]`，共 15 级逻辑。

### 优化 1：CSR 读打拍

CSR `always_comb` case 语句被 Vivado 与 5 路结果 mux 合并进同一 LUT 网络，插入关键路径尾部。将 `csr_rdata` 输出转化为寄存器输出（`csr_rdata_r`），用 `csr_num` 变化检测自动触发 CSR 读指令 1 周期 stall。CSR/JAL/PCADD/cpucfg 路径改用 `csr_rdata_r`。

**效果**：WNS 5.359→5.381ns（+0.022ns，微）。CSR 路径只占尾部少量 LUT 级，DSP 级联是瓶颈。

### 优化 2：EX 结果 mux 拆分

原 5 路优先编码 mux（CSR→JAL→PCADD→cpucfg→ALU）将 `alu_result`（含 MUL 的 DSP→CARRY4）拖入完整 LUT 链。将 ALU 结果从 mux 中分离——`alu_result` 直连 `ex_mem_in.alu_res`，非 ALU 结果走独立 mux 由 2 选 1 终选。

**效果**：WNS 5.381→5.389ns（+0.008ns，微）。Vivado 将 `is_non_alu` 条件信号和 CSR 读合并进同一组合逻辑块，抵消了 mux 拆分收益。

### 优化 3：mul.w 分解为 16 位部分积

借鉴 `wip-100mhz` 分支，将 32 位乘法 `a * b` 分解为三个 16 位部分积：
- `p0 = a[15:0] * b[15:0]`（单个 DSP48E1）
- `p1l = a[15:0] * b[31:16]`（单个 DSP48E1）
- `p2l = a[31:16] * b[15:0]`（单个 DSP48E1）

FSM (`mul_in_progress`)：
- 第 1 周期：三个 16×16 并行计算（组合逻辑），posedge 捕获 `p0/p1l/p2l` 到寄存器，pipeline stall
- 第 2 周期：`mul_hi = p0[31:16] + p1l + p2l`（17 位加法），`mul_result = {mul_hi[15:0], p0[15:0]}` 组合输出，pipeline 释出
- ALU (`alu.sv`) 移除 `ALU_MUL` case，`ex_alu_result = mul_in_progress ? mul_result : alu_result` 二选一

三个 16×16 各自在单个 DSP48E1 内完成（无级联），部分积寄存器打断 DSP 链。mul.w 增加 1 周期延迟，MUL 指令罕见于 benchmark → IPC 零损失。

**效果**（Verilator difftest 全 6 测试 PASS，IPC 不变）：

| 指标 | 优化前 | 优化后 | Δ |
|------|--------|--------|-----|
| Synthesis WNS | 5.388ns | **7.728ns** | **+2.34ns (+43%)** |
| 数据路径延迟 | 14.41ns | 12.04ns | -2.37ns |
| 逻辑延迟 | 8.45ns | 5.50ns | -2.95ns |
| 逻辑级数 | 15 | 22 | +7 |
| DSP48E1 关键路径 | 2 个（级联） | **0 个** | 消除 |
| 新最差路径 | ALU→CSR→reg | DCache just_hit → pc_reg[28] | 路径转移 |

> **关键**：DSP48E1 级联（~5.4ns，占原路径 37%）被三个并行 16 位部分积 + 寄存器完全消除。新最差路径转移至 dcache LUTRAM 组合逻辑标签命中检测（MUXF8×2、CARRY4×9）→ NPC，但 WNS 7.73ns 提供充足 Implementation 收敛余量。


**CI**：`submit-20260729-1630` 已推送（结果：综合 WNS 5.388ns，超时未完成实现）；`submit-20260729-1747` 随后推送（综合 WNS 7.728ns，见 README CI 提交记录）。

## 已知问题（wip/icache-0cycle 分支，2026-07-31）

### Bug 1：`bp_do_jump` 未接入 hazard_unit → 分支预测重定向后 IF/ID 未冲刷 ✅

**现象**：`make test-simple` 在 instruction #36 处 difftest mismatch。`or $r16` 在 BTFNT 预测 taken 后，fall-through 路径的 `addi.w $r12` 未被冲刷，错误提交。

**根因**：`core.sv:574` 中 `hazard_unit` 实例化缺少 `.bp_do_jump(bp_do_jump)` 连接。当 BTFNT 预测跳转时，`fetch_unit` 被重定向（`bp_do_jump` 驱动 `next_pc`），但 `if_id_flush` 不触发——已取出的下一条顺序指令进入流水线而不被冲刷。

**修复**：`3b00951` — 在 `hazard_unit` 实例化中补上 `.bp_do_jump(bp_do_jump)`。

**单元测试**：`unittest/ex_mem_flush/` — 最小循环体（`or → cacop → addi → slt → beq`），cacop 立即完成，验证分支冲刷。运行方式：

```bash
cd unittest/ex_mem_flush && ./run_test.sh
```

### Bug 2：cacop stall 期间 EX/MEM 被 MEM/WB 重复捕获 → 同一条指令 commit 两次 ✅

**现象**：`make test-simple` 在 instruction #36 处 difftest mismatch（同 Bug 1 的现象，但根因不同）。`or $r16` 在 `cacop` 的 pipeline stall 期间被 MEM/WB 连续两次捕获，提交两次。

**根因**：`mem_wb_in.ctrl.valid` 无去重逻辑。`cacop` 进入 EX 时 `cacop_not_ready=1` → `ex_mem_stall=1`，EX/MEM 被卡住。但 MEM/WB 的 `stall` 硬编码为 `1'b0`（从不阻塞），每个 cycle 都从 EX/MEM 捕获同一指令。`or` 不访存（`lsu_ready=1`），故 `mem_valid` 在每个 stall cycle 都为 1。

**修复**：`1b62bc2` — `mem_valid` 增加 `!ex_mem_stall` 条件，pipeline stall 期间不推进 MEM/WB。

**单元测试**：`unittest/ex_mem_stall_dup/` — `or → cacop` 背靠背，`cacop_done` 打一拍（模拟真实 delay）。运行方式：

```bash
cd unittest/ex_mem_stall_dup && ./run_test.sh
```

### Bug 3：CSR 写在 EX 级、difftest 在 WB 级捕获 → dmw0 CSR 值提前可见 ✅（2026-07-31 修复，f2213a1）

**现象**：Bug 1/2 修复后 `make test-simple` 推进到 instruction #7241，报 dmw0 mismatch（DUT=0x19, REF=0x00）。

**根因**：CSR 写（`csr_we`）在 EX 级通过组合逻辑完成，但 difftest 的 DPI-C 在 WB 级（`mem_wb_out`）捕获 commit 和 CSR 状态。`csrwr $r12, CSR_DMW0` 在 EX 级写完 DMW0=0x19 之后的下一周期，其前驱指令 `ori $r12,$r0,0x19` 在 WB 级提交，difftest 捕获到此 commit 时看到 DMW0 已变为 0x19——此时 `csrwr` 尚未提交。

这是 CSR 执行阶段（EX）与 difftest 捕获边界（WB）之间的固有 timing skew，**不是功能 bug**：CSR 最终写入值正确，后续指令通过组合旁路也能读到新值。旧 icache（0.5 IPC）下指令间距大，skew 恰好不触发；0-cycle icache（1 IPC）压缩指令间距后暴露。

**尝试过的修复（均失败）**：

1. **2 级 posedge CSR 管道**（difftest 输入打 2 拍）：单元测试通过，但 `make test-simple` 初始 sync 崩坏——difftest sync 需要**当前** CSR 值，而管道输出是**延迟 2 拍**的值，CRMD/ASID 在指令 #0 即 mismatch。sync 与比较共用同一捕获机制，无法同时满足。
2. **negedge 采样**（下时钟沿打拍）：dirty hack，本质是绕开 Verilator NBA 与 DPI-C 的求值顺序竞争，且同样破坏初始 sync。已放弃。
3. **csr_regfile 写旁路**（`csr_we` 同周期组合输出）：不影响 difftest 捕获时机，无法解决。

**结论**：~~该问题根因在 difftest 捕获口径（CSR 状态与指令提交不同步），不在 CPU 功能。修复方向应是在 difftest 框架内让 CSR 状态与提交对齐（如仅在 CSR 指令提交时比较 CSR），而非改动 CPU 流水线。在未修复前，`make test-simple` 在 #7241 处失败，其余测试（含 5 个 benchmark）不受影响。~~ **已按"CPU 结构性修复"方向解决（f2213a1）**：CSR 写推迟到 WB 退休点 + EX 级三级在飞写转发（MEM/WB/WB-退休后 1 拍）+ csr_regfile 输出写旁路，顺带修掉潜伏的 `csrwr→csrrd` RAW 冒险。零 IPC 代价。详见下方 Bug 4。

**单元测试**：`unittest/csr_dmw0/` 已删除（不是正确复现——它把 skew 推到极限，在任何 `csrwr` 紧跟前驱指令时都在指令 #0 失败，与 #7241 的实际触发条件不符）。`unittest/csr_dmw0_loop/`（csrwr→cacop→csrwr 含 cacop 延迟）已作为回归测试提交（5d2ffd3）。

---

## wip/icache-0cycle 分支修复记录（2026-07-31 续）

> **2026-07-31：本分支已 fast-forward 合并至 master**（含 Bug 8 闭合三处修复、关联 bug 两处修复、dcache load 命中快速路径、7 个单元测试）。CI：submit-20260731-1910 通过（Bug 8 修复）；1950/1953 因 `!|` 语法被 Vivado 2019.2 拒绝而失败（37518fc 修复）；2005 为最新提交（待结果）。

0-cycle icache 将指令间距压缩到 ~1 IPC 后，陆续暴露了流水线深层的结构性问题。本会话共定位并修复 5 个 bug（均零 IPC 代价），simple 测试已通过；fibonacci 仍有 1 个未闭合问题（见 Bug 8）。

### Bug 4：CSR 写不落在退休点 → difftest 比较口径错位 ✅（f2213a1）

**现象**：`unittest/csr_dmw0_loop` 在指令 #0 失败（dmw0: DUT=0x19, REF=0x00）；simple 在 #7241 失败。

**根因**：CSR 写在 EX 级生效（`csr_we` 由 `id_ex_out` 驱动），difftest 每拍采样实时 CSR 并在每次提交时全量比较——DUT 的 CSR 状态比退休点超前 2 条指令。0-cycle icache 把指令间距压缩后必然触发。附带潜伏 bug：`csrwr→csrrd`（同一 CSR 背靠背）时 `csr_read_stall` 因 `csr_num == csr_num_r` 不触发，`csr_rdata_r` 是写前旧值 → RAW 冒险。

**修复**：CSR 写移至 WB（退休点）生效，`is_csrwr/is_csrxchg/csr_wdata` 贯穿 EX→MEM→WB；csr_regfile 26 个输出加写旁路（镜像 regfile `gpr_dbg` 模式）；EX 读路径三级在飞写转发（MEM → WB → WB 退休后 1 拍，覆盖 csrrd/csrxchg 在写者后 1/2/3 条的所有窗口）；DMW0/DMW1/CRMD 翻译路径加 MEM 级转发。全部组合逻辑，零新增 stall。

**单元测试**：`unittest/csr_dmw0_loop/`（回归）。

### Bug 5：EX 操作数在 ID 锁存 → stall 期间陈旧 ✅（e104547）

**现象**：simple 在 WELCOME 循环失败——`addi.w $r23,$r23,0x44 → ld.b $r4,$r23,0 → addi.w $r23,$r23,1`（跨 stalled load 的 2-back RAW），DUT 提交 0x1c0022ad（应为 0x1c0022f1）。

**根因**：`id_ex` 在 ID→EX 边界锁存 `rd1/rd2`。stall 把消费者扣在 EX 多拍时（dcache miss refill ~20 拍），Bug 2 修复的 `mem_valid` 门控在 WB 制造空泡，`fw_a_mw` 转发中途死亡，操作数回落到 ID 时锁存的旧值——而生产者已退休进阵列。1-back load→use 免疫（`load_use_hazard` 的 flush+hold 恰好对齐转发窗口）；5 个 benchmark 未踩中（窗口极窄）。

**修复**：regfile 读口从 ID 移到 EX（`id_ex_out.data.rs1/rs2` 组合读 + 写旁路），操作数基底永远是"已退休 + WB 在飞"的架构值。转发 mux 不变。

**单元测试**：`unittest/gpr_fwd_load_stall/`（dresp.data_ok 延迟 1 拍模拟 dcache 命中延迟，精确复现 simple 失败值）。

### Bug 6：EX 重定向目标 == 当前取指 pc 时 if_id_flush 杀掉目标 ✅（3467452）

**现象**：simple 的 putc `.WSERIAL` 丢失 `pcaddu12i`（la.global），后续 `ld.w` 以陈旧 r13 计算地址（0xfffffa00）返回 0。

**根因**：0-cycle icache 让"重定向目标指令的 data_ok"与"EX 误预测 flush"同一拍到达。fetch_unit 的 Bug 6 旧修复（`do_ex_flush` 仅在 `pc_current != jump_target` 时生效）抑制了重定向，但 hazard_unit 的 `if_id_flush` 不知道这个抑制——目标指令的 IF/ID 捕获被 flush 杀掉，取指继续顺序前进，目标永久丢失。JAL 因 `ex_jump_flush_hazard = ex_jump_flush && !is_jal` 天然免疫；条件分支/jirl/ibar 全部中招。

**修复**：hazard_unit 的 `if_id_flush` 的 `jump_flush` 项加 `!(pc_current == ex_jump_pc)` 门控（镜像 fetch_unit 逻辑）。

**单元测试**：`unittest/beq_redirect_target/`（beq 目标 == 顺序取指位置）。

### Bug 7：load_use 扣住的分支被自身 bp_do_jump flush 杀掉 + BP 重定向目标捕获被杀 ✅（7ffb793）

**现象**：simple 的 WELCOME 循环后向 `bne`（1c0012cc）从未提交——DUT 提交流比 NEMU 少一条，第二个 `addi` 处 s0 mismatch（0x1c0022f2 vs 0x1c0022f1）。

**根因**（两个机制，同一修复覆盖）：
1. `bne $r4` 依赖 1-back 的 `ld.b $r4` → `load_use_hazard` 触发 id_ex_flush（杀 bne 的 ID→EX 条目）+ if_id_stall（把 bne 扣在 ID）。同一拍 bne 自己的预测（后向→taken）触发 `bp_do_jump` → if_id_flush——pipeline_reg 中 flush 优先于 stall——把正被扣在 if_id 里的 bne 本身清零。分支蒸发，取指沿（正确的）预测路径继续，循环照跑但 bne 永不提交。
2. 下一拍 `bp_do_jump` 仍断言而 `pc_current == bp_jump_pc`（取指已在目标），fetch_unit 抑制重定向但 if_id_flush 照杀——目标的捕获被杀死（Bug 6 类问题在 BP 重定向上的翻版）。

**修复**：`if_id_flush` 的 `id_jump_req`/`bp_do_jump` 两项补 `(pc_current != jump_pc)` + `!load_use_hazard` 门控。`id_ex_flush` 与 EX 重定向项不动。

**单元测试**：`unittest/bne_load_use_bpflush/`（load 喂养的后向 bne，修复前 t8: ref=1, dut=2）。

### Bug 8：icache keyword-forward 的 pc 配对错误 ✅（a8f6b9a + 本会话三处修复）

**现象**：`make test-fibonacci` 在 #167 失败——0x1c001060 处取到 0x288af1ad（应为 beq 0x580033c0），执行错误指令后 difftest mismatch（t1: ref=0x1c7f0088, dut=0）。

**根因**：0-cycle icache 的 miss 不返回 `addr_ok`，fetch_unit 无法进入 WAIT_DATA 记录"缺失取指的 pc"（`captured_pc`）。refill 的 keyword forward（S_REFILL_WAIT 的 data_ok）与**当前** pc 配对——当 keyword 与 EX 重定向（bne/beq 误预测在 store stall 释放时触发）同拍到达时，keyword 的数据被配到重定向目标的 pc 上，目标指令被静默替换。

**修复分四步**（a8f6b9a 为已提交的第一步）：

1. **a8f6b9a（已提交）**：S_IDLE 的 miss 分支补 `cpu_resp.addr_ok = 1` → fetch_unit 进入 WAIT_DATA → `captured_pc` 锁存 miss 的 pc → keyword forward 正确配对。
2. **fetch_unit.sv：WAIT_DATA 放弃陈旧取指**。重定向（EX 误预测 / ID / BP redirect）使 `pc_current` 偏离在飞的 miss 取指时，WAIT_DATA 立即回到 REQ 重新请求当前 pc（此前会一直等到 keyword 到达，把错误路径指令送进流水线）；`if_valid`/`captured_instr` 同步加 `pc_current == captured_pc` 门控。
3. **icache.sv：keyword forward 按地址门控**。S_REFILL_WAIT 的 keyword forward 仅在 `cpu_req.addr[31:2] == {m_tag, m_idx, m_wo}` 时发出——重定向后 requester 已不再要该地址，旧 forward 若照发会在 REQ 态被配到新 pc 上（单独只有 2 或 3 都无法闭合，单元测试分别验证）。
4. **hazard_unit.sv：keep_capture 收紧**。`jump_flush_keep_capture` 原条件 `pc_current == ex_jump_pc` 过松：pc 可以恰好推进到目标地址（分支位于行尾、fall-through 的 pc+4 恰为目标）而 if_id 里仍是上一拍捕获的 fall-through——flush 被误抑制，错误路径指令存活。现在要求 `if_id_in_valid && if_id_in_pc == ex_jump_pc`（在飞捕获确实是目标才保留）。

**过程中发现的关联 bug**（同为 fibonacci 回归中暴露）：

- **关联 bug（core.sv）：IF/ID 被 stall 扣住期间 ID 重复下发同一条指令**。WELCOME 循环的 bne 在 dcache refill stall 期间被扣在 IF/ID（`if_id_stall=1`），id_ex_stall 释放后 ID 每个周期重复解码同一指令 → 同一 bne 提交两次（s0 差 1，NEMU 多执行一次 addi）。修复：`id_ex_in.ctrl.valid = id_valid && !(if_id_stall && !if_id_flush)`——IF 级真正推进（未 stall 或被 flush）才允许下发。第一版 `!if_id_stall` 过严：JAL/branch 在重定向当拍 if_id_flush=1（副本被清）而目标取指在飞（if_id_stall=1）时被门控掉 → bl 丢失（READSERIAL 第三次调用被跳过，ra 停在旧值）。`!(if_id_stall && !if_id_flush)` 恰好兼容两种情形。

**单元测试**：`unittest/icache_redirect_stale/`——真实 icache 例化在 core 与慢速 fake memory 之间（dresp 对特定地址延迟 5 拍模拟 dcache miss 把分支扣在 EX，imem 延迟 10 拍让 refill 在重定向后才出 keyword），精确复现 fibonacci 的时序。修复前 t8: ref=0xAA dut=0x55（fall-through 0x1c000010 错误提交），修复后通过。两个单独修复（只改 fetch_unit 或只改 icache）均失败，证明两部分缺一不可。

### 测试状态（2026-07-31，Bug 8 闭合后全量回归）

| 测试 | 状态 | 备注 |
|------|------|------|
| unittest/ex_mem_flush | ✅ | 3716 条 |
| unittest/ex_mem_stall_dup | ✅ | 1672 条 |
| unittest/csr_dmw0_loop | ✅ | 1668 条 |
| unittest/gpr_fwd_load_stall | ✅ | 1668 条 |
| unittest/beq_redirect_target | ✅ | 1666 条 |
| unittest/bne_load_use_bpflush | ✅ | 3747 条 |
| unittest/icache_redirect_stale | ✅ | 新增，3179 条 |
| make test-simple | ✅ | 24383 条，IPC 0.1663（与修复前基线一致） |
| make test-fibonacci | ✅ | 96857 条，D result memory PASS（32 字节比对一致），IPC 0.1360 |
| make test-stream | ✅ | 395 万条，ExtRAM 3 MiB 数据比对 PASS，IPC 0.2101 |
| make test-matrix | ✅ | 565 万条，matrix_expected 比对 PASS，IPC 0.3024 |
| make test-mixed | ✅ | 33 万条，signature 比对 PASS，IPC 0.2894 |
| make test-cryptonight | ✅ | 2309 万条，2 MiB 数据比对 PASS，IPC 0.2478 |

> 性能基准（stream/matrix/mixed/cryptonight）为 0-cycle icache 分支首次全量回归，IPC 较 2026-07-29 的旧流水线提升 40%-62%（matrix +62%、mixed +56%、cryptonight +44%、stream +40%）属 0-cycle icache 预期效果（simple 与旧值一致）。

## 2026-07-31：DCache Load 命中快速路径（0-cycle，镜像 icache）

**目标**：消除 dcache load 命中的 S1/S2 流水线停顿（stall_dcache_hit_pipe 中 load 部分，旧占比 6-16%）。

**分析**：icache 的 0-cycle 命中 = 标签 LUTRAM 组合读取 + 数据组合读取 + `data_ok` 同拍响应。dcache 的标签 LUTRAM 组合读取与 store 命中快速路径（2026-07-29）已就位，只差数据组合读取端口与 load 分支——2026-07-29 曾判定"load 命中因 BRAM 数据延迟无法消除"，但 icache-0cycle 的工作证明：数据 RAM 声明为组合读取后综合为分布式 RAM（LUTRAM），读延迟为 0，无需 rvcpu 式的 WB 级旁路重构。

**实现**（dcache.sv，与 store 快速路径完全对称）：

1. **数据组合读取端口**：`assign data_rd_comb[gw][gb] = mem[req_idx]`（分布式 RAM 双读端口：组合读供快速路径，注册读 data_rd_out 保留给 S2/miss/writeback/cacop 路径）。
2. **fast-path cpu_resp 增加 load 分支**：`S_IDLE && !s2_valid && cpu_req.valid && is_cachable && req_hit` 时对 load 同拍返回 `addr_ok + data_ok + data`（store 分支不变，条件从 `|cpu_req.strobe` 放宽到所有 cacheable 命中）。
3. **S1 捕获抑制 / just_hit / PLRU / 性能计数器** 同步放宽到 load 命中（PLRU 更新；dirty 仅在 store 时置位）。
4. **新性能指标** `fast_path_load_hits`（difftest 结尾输出）——load 快速路径命中数。

**load 数据正确性**：`dresp.data`（组合读）→ LSU 字节提取（组合）→ `mem_wb_in.final_res`，全部在同一周期内稳定，`mem_valid` 在请求拍置位，WB 捕获即正确数据——无需改动 core/LSU。

**结果**（Verilator difftest，全 6 测试 + 7 单元测试 PASS）：

| 测试 | 旧 IPC | 新 IPC | ΔIPC | 说明 |
|------|--------|--------|------|------|
| simple | 0.1663 | 0.1669 | +0.4% | |
| stream | 0.2101 | 0.2241 | +6.7% | |
| matrix | 0.3024 | 0.3730 | **+23.3%** | load 密集（91% 命中），Hit Pipe 占 stall 从 15.7%→5.6% |
| mixed | 0.2894 | 0.2963 | +2.4% | |
| cryptonight | 0.2478 | 0.2478 | 0% | load 几乎全为 2MB scratchpad 强制 miss（load 2.23M vs miss 2.22M，fast_path_load_hits 仅 8.4K），无命中可提速 |

> cryptonight 的 load 命中路径无收益属预期（其 load 为随机 scratchpad 访问，容量 miss 主导；命中主要来自栈 store，2026-07-29 已走快速路径）。残余 hit-pipe（matrix 3.5% 周期）来自 `!s2_valid` 门控下 miss 的 S1/S2 窗口内到达的请求（回退 S2 管道，正确但 2 拍）——与 icache 类似地整体拆除 S1/S2（组合 miss 检测）可进一步消除，留待后续。

**资源影响**：dcache 数据 64Kb 由 BRAM 迁移至分布式 RAM（~1024 LUT），组合读路径（LUTRAM 读 + tag 比较 + data_ok + LSU 字节提取）进入 50MHz 关键路径，需 CI 时序确认。

---

## 2026-07-31: 非阻塞 DCache（hit-under-miss，单 MSHR）

**目标**：消除 DCache Refill 期间的流水线停顿（旧占全部 stall 的 70-89%，绝对主瓶颈）。参照 2026-07-29「写缓冲区设计探讨」的结论方向：DCache 内部完成 store 缓冲，不引入外部写缓冲模块。

**核心洞察**：旧架构中 miss 处理是**同步**的——store miss 期间整条流水线被 `lsu_ready=0` 冻结，store 的数据要等 refill 完成后通过"重试命中"写回。这使 store miss（不需要返回数据）白白阻塞流水线 ~30 拍。将 store miss 解耦后，流水线在 refill 期间继续运行，LSU 会向 dcache 发出新请求——dcache 必须能在 refill 期间同拍响应，即 **hit-under-miss**。

### 实现（dcache.sv，单 MSHR = 一个在飞 miss + 两个合并槽）

1. **组合 miss 接受**（S_IDLE 快速路径扩展）：所有 cacheable 请求请求拍内组合响应——
   - 命中（load/store）：原有 0-cycle 路径；
   - **store miss：当拍 `addr_ok`+`data_ok` 接受**，miss 上下文（m_wdata/m_wstrb/m_wo，重引入 2026-07-29 删除的寄存器）在 S_REFILL_WRITE 写入对应 word 时合并进新行（写分配完成，dirty=1）；
   - **load miss：当拍 `addr_ok`**，LSU 进入 WAIT（dreq.valid=0），数据经原有关键字转发返回——同时消除了 S1/S2 检测窗口（每 miss 省 1-2 拍）。
2. **Hit-under-miss**（refill 状态下的组合响应）：`in_refill && req_hit_any && !(req_idx==m_idx && req_hit_way==m_eway)`——正在 refill 的行**整行排除**（数据 RAM 只写了一半或 tag 尚未更新，读取会拿到部分/旧数据）；load 恒可服务（组合读口），store 在数据写口空闲时服务（S_REFILL_WRITE 期间写口被 refill 占用，store 命中等 ≤4 拍后在 S_IDLE 重试）。
3. **读回写合并**（第二合并槽 st_merge_*）：store 命中正在 refill 的行（cryptonight `scratchpad[x]=…` 读回写模式）当拍接受，只要其 word 尚未写入数据 RAM（S_REFILL_WAIT 及更早恒可，S_REFILL_WRITE 时要求 `rf_wr_cnt < req_wo`）；合并进 refill 写（后写者优先于 store-miss 合并）。`st_merge_pending` **保持到 refill 完成**（不能在合并拍清除——dirty 位在完成拍用 `m_op || st_merge_pending` 生成，提前清除会把合并过的行标为 clean，evict 时静默丢弃 store 数据，这是本实现排查出的第一处功能 bug）。
4. **二次 miss 等待**：refill 期间到达的未命中请求不给任何应答（单 MSHR 上限），LSU 保持请求，refill 完成后在 S_IDLE 正常处理（命中或新 miss）。
5. **cacop 门控**：S_IDLE 的 miss 接受需 `!cacop_pending`（FSM 中 cacop 优先级更高，若接受而 cacop 先走，refill 不会启动，被接受的 load miss 会把 LSU 卡在 WAIT 死锁）。

### 修复的关联缺陷：arbiter R_ARB 突发截断（axibus_arbiter.sv）

- **现象**：simple 测试 WELCOME 循环第 5 个字符（'T'）读到 0x84，refill 只收到 1 个 beat，行的 word1-3 写入陈旧 rf_buf 数据。
- **根因**：arbiter 的 `R_ARB` 状态（ireq 与 dreq 读请求同时挂起时的仲裁路径）**不设置 arlen**——默认 arlen=0 单拍。旧架构下流水线在任意 miss 期间全停，icache 请求不可能与 dcache refill 读同时挂起，此路径从未被触发；0-cycle icache + store-miss 解耦后流水线在 refill 期间运行，icache 取指与 dcache 突发 refill 首次并发 → refill burst 被截成单拍 → 行数据损坏。
- **修复**：`R_ARB` 按请求方设置 arlen（dreq 取 `dreq.burst_len`，ireq 恒 0）。

### 结果（Verilator difftest，全 6 测试 + 7 单元测试 PASS）

| 测试 | 旧 IPC | 新 IPC | Δ IPC | hit-under-miss |
|------|--------|--------|-------|----------------|
| simple | 0.1669 | 0.1671 | +0.1% | 11 |
| stream | 0.2241 | **0.2804** | **+25.1%** | 589,838 |
| matrix | 0.3730 | 0.3853 | +3.3% | 18,217 |
| mixed | 0.2963 | **0.3295** | **+11.2%** | 8,213 |
| cryptonight | 0.2478 | **0.2673** | +7.9% | 339,785 |
| fibonacci | 0.1360 | 0.1360 | 0%（uncache 内核） | — |

**Stall 拆解**：DCache Hit Pipe 基本清零（matrix 5.6%→0.5%、cryptonight 6.6%→0.1%）；DCache Refill 仍为主瓶颈（stream 64.1%、cryptonight 70.6% 的周期），其中 cryptonight 的 load miss 为顺序流水线无法隐藏的延迟（scratchpad 随机读，关键字返回前流水线必然等待），stream 的残余为 load miss 延迟 + refill 期间到达的二次 miss 等待。

### 可调参数

| 参数 | 位置 | 说明 |
|------|------|------|
| `DCACHE_SETS` / `ICACHE_SETS` | `core_top.sv` 模组参数 | 组数（默认 256，8KB） |
| `NR_WAYS` / `NR_WORDS` | `core_top.sv` 例化 dcache/icache | 路数（默认 2）/ 行 word 数（默认 4，16B） |
| `st_merge` 槽数 | dcache.sv | 读回写合并槽，当前 1 个（与 store-miss 合并槽共 2 个） |
| MSHR 数 | dcache.sv FSM | 当前 1（单在飞 miss），受 arbiter 单 outstanding 读限制 |

> 组数/路数/行大小扫描结论不变（见「dcache 增强实验」）：命中率提升被 miss penalty 放大抵消，瓶颈在 miss 处理延迟。非阻塞化后 miss penalty 的构成（写回串行 + refill + 写回 RAM）成为下一步优化对象。

### 保守取舍（未实现，留待后续）

1. **写回/refill 重叠**（cryptonight 收益最大，估 ~8-12%）：脏行写回与下一行 refill 共用 dcache 单一 `mem_req` 接口，burst 数据须逐拍驱动，无法并行发出两个事务。实现需 arbiter 写通道在 AW 握手时缓冲整个突发（4×32b），并允许 dcache 在写回排空期间切换到 refill 读——接口级改动，风险高，本期未做。
2. **MSHR 多路 outstanding**（load-under-miss × N）：顺序流水线 + 单 LSU 下，后续 load 无法越过在飞的 load miss 发起新请求；需要 LSU 重排序缓冲 + 乱序完成，侵入流水线核心，未做。
3. **refill 行 store 合并的 word 已写情形**（S_REFILL_WRITE 中 `rf_wr_cnt > req_wo` 的 store）：需第三个合并槽或写缓冲，窗口仅 1-4 拍，未做。
4. **icache 非阻塞**：取指为单流顺序，miss 即阻塞取指单元本身，无并行请求可服务（ICache Refill 占 stall 0.0%），无意义。

---

## 2026-08-01: 写回/refill 重叠上板失败排查（已回退）

### 现象

`4c7f524`（写回/refill 重叠，IPC +12~26%）的 CI 提交 `2c4f3298` 上板**全部测试稳定 50 分**：程序能完整跑完（UART 输出正常、boot 消息可见），但数据比对失败——cryptonight 首个 mismatch 在 `0x1c400000`（ExtRAM 首字节）：`actual=0x00, expected=0x51`。上一版本 `30e9c97`（非阻塞 dcache，串行写回）同一平台全部通过。**差异仅 dcache.sv 的写回/refill 重叠（+37/-25 行）**。

### 排查过程

1. **cbor 上板日志分析**（平台事件流）：ExtRAM 读回 2MB 内容与 crypto.bin 仅 0.46% 字节匹配（≈随机），211 个 4B 字匹配均匀分散、无连续块——排除地址偏移；`actual[0]=0x00` 恰为 fill 初值（`pad[0]=0`）——指向算法阶段（load→refill→store 读回写 + 脏写回）写入丢失/未生效，而非顺序写路径。cryptonight 初始化是全量的（`st.w pad[i]=i` 覆盖 2MB），排除"上板 ExtRAM 初始随机"假设。
2. **CDC 约束缺陷发现（已修复但非根因）**：本地复现 CI 流水线（docker + 解析后的 src/soc 树 + CI 版 flow tcl）发现 CI `soc.xdc` 的 `get_pins -hierarchical *CLKOUT0/1` 在网表中**匹配不到任何引脚**（clk_wiz 端口编号 ≠ plle2 引脚编号，工具推导时钟为 `cpu_clk_clk_pll`(50MHz) 挂 **CLKOUT0**、`sys_clk_clk_pll`(25MHz) 挂 **CLKOUT1**）——原版 `set_clock_groups` 一直是空操作，cpu_clk↔sys_clk CDC 路径（Axi_CDC 五通道 FIFO 指针同步器）被当同步路径分析（本地确认 199 条被分析路径，最差穿过 `u_Axi_CDC/rFifo` BRAM）。显式引脚版修复后本地 Inter-Clock 表跨时钟路径 199→0 条，CI 构建（`d08c8a90`）**上板仍 50 分**——**CDC 约束缺陷被证伪，不是根因**。
3. **2:1 谐波复现尝试**（wip 分支 `CDC_ASYNC_SIM`）：Verilator 默认 `cpu_clk==sys_clk` 同源同频，跨时钟行为完全掩盖。临时改造仿真：tb 时钟 50MHz 当 cpu_clk、`sys_clk=clk/2`（25MHz，UART 不变），difftest 步进改到 CPU 时钟沿。simple 通过；cryptonight 在该配置下未跑完（挂起，待查）——复现工作未闭合。

### 结论

- 写回/refill 重叠在 FPGA 上系统性失败（全测试、稳定复现），Verilator（同源同频）无法暴露
- CDC 时序约束缺陷是真实存在的历史问题（原版 `set_clock_groups` 从未生效），修复后上板仍失败——非根因
- 根因未定位（跨时钟 FIFO 功能性问题 / SRAM 物理时序 / 其他），相关代码与调试状态保存在 `wip/wb-overlap-xdc` 分支
- **已回退**：master 回到 `48c0dfd`（非阻塞 dcache，上板通过）

---

## 2026-08-01: SRAM 固定时延校准（difftest ↔ 上板 50MHz）+ cryptonight 核心指标

### 背景

上板实测与 Verilator difftest 折算（`ticks_/50MHz`）不符，difftest 系统性偏快。根因：板上 PLL 输出 cpu_clk=50MHz / **sys_clk=25MHz**（2:1，`src/soc/xilinx_ip/clk_pll/clk_pll.xci`），AXI CDC / crossbar / SRAM / UART 全挂 25MHz sys_clk，每笔 SRAM 访问在 CPU 时钟域折合更多周期；而 Verilator（`soc_top.v` SIMULATION 分支）`cpu_clk=sys_clk=clk` 1:1，SRAM 模型（`sim/sram.v`）组合读零时延，未建模该固定时延。

### 实现（`rtl/ip/Bus_interconnects/axi2sram_sp_external.v`，仅 `ifdef VERILATOR`）

- 每笔 SRAM 事务**首拍**（读关键字 / 写首字）前插入固定 `EXTRA_LATENCY=16` 周期等待；综合/上板分支恒为 0，板载 RTL 不变。
- **只加首拍的原因**（两轮实测迭代得出）：per-beat 加时延几乎全被吸收（L=2/beat 时 mixed 仅 +76K 周期，预期 +285K）——非阻塞 dcache（hit-under-miss）下 refill 后续拍与流水线执行重叠；实测加入量 ≈ **load-miss 关键字数 × 16**，只有关键字等待 1:1 落在关键路径上。
- 验证（4 测试全部 difftest PASS + 数据比对 PASS）：

| 基准 | difftest 估计 | 上板实测 | 偏差 |
|------|:---:|:---:|:---:|
| **cryptonight** | **2438ms** | 2446ms | **-0.3%** |
| mixed | 24.9ms | 25ms | -0.4% |
| matrix | 363.8ms | 374ms | -2.7% |
| stream | 345.1ms | 395ms | -12.6% |

- stream 偏差来源：写回占比最高（787K words / 写回 196.8K 事务），写路径时延在板上同样翻倍但仿真侧被 hit-under-miss 吸收更多，单一常量无法同时拟合（如需可给写路径加权重）。

### cryptonight 校准后指标（difftest，核心优化指标，2026-08-01 **8B 行默认**）

| 指标 | 数值 |
|------|------|
| 指令 / 周期 / IPC | 23.09M / 102.28M / **0.2258** |
| 估计耗时（50MHz） | **2046ms**（上板 1883ms，+8.7%；16B 行 2446ms，-23%） |
| ICache | 24.68M 访问，95.75% 命中，s1_accept/cycle=0.9995 |
| DCache | 4.72M 访问，50.09% 命中，2.36M miss，写回 4.71M words，hit-under-miss 262,180 |
| 分支预测 | 1,578,418 分支，仅 821 误预测，**99.95% 准确率** |
| Stall 构成 | **DCache Refill 占 76.0% 总周期**（98.2% 的 stall 周期），其余 <1.4% |

> **默认配置定为 8B 行（2026-08-01 上板三配置实测后）**：cryptonight 16B 2446 / **8B 1883** / 4B 1699ms；stream 395 / **473** / 756ms；matrix 374 / **444** / 578ms；mixed 25 / **25** / 33ms——**四测试合计 8B 2825ms < 4B 3066ms < 16B 3240ms**。4B 行对 cryptonight 单独最优但 stream/matrix 空间局部性全失；8B 行折中最优。16B 行时期 cryptonight 真实 IPC 0.1889（2446ms）；8B 行真实 IPC 0.2453（1883ms）。
>
> **校准修复与重标定（2026-08-01 晚）**：时延计数器原先只在写路径清零，连续读事务只有首笔被限速（4B 行下校准失效）；修复为读送达时清零，重标定 `EXTRA_LATENCY=7`（EXTRA_LATENCY=16 时代的校准数据作废）。
>
> **真实 IPC（指令数 ÷ 上板耗时 × 50MHz，2026-08-01，8B 行）**：cryptonight 0.2453（difftest IPC 0.2258）、matrix 0.2544（0.2414）、stream 0.1673（0.1587）、mixed 0.2653（0.2336）。difftest 估时与上板偏差 +5~14%（8B 行事务数减半，7 拍常量略偏大，未重新标定），可直接对照优化。
>
> **优化方向分析（2026-08-01 晚）**：load miss 的 SRAM 首拍时延（~19 拍）是主瓶颈。单口异步 SRAM 读事务串行（B 的读只能在 A 的读响应返回后发出），顺序提交约束 WB 单槽（load A 在 WB 等数据时后续指令全阻塞）——**多 MSHR / load-under-miss 无法隐藏读时延（收益 <5%）**；write buffer 也无收益（store 已解耦 + 写回已 fire-and-forget）。可行方向仅容量（miss 数，~5%）与状态机/仲裁开销（~5%）。

## 2026-08-01: DCache 行宽/相联度实测 —— cryptonight 最优 cacheline = 4B

### 背景与改造

将 dcache 参数化（`NR_SETS/NR_WAYS/NR_WORDS` 经 `core_top` 透传），并**将 CPUCFG.0x12 编码参数化**（offset_bits = clog2(行宽)、index_bits = clog2(sets)、max_way = ways-1，内核私有编码 [30:24]/[23:16]/[15:0]）。NEMU 侧同步：`scripts/build.mk` 增加 `-DDCACHE_OFFSET_BITS/-DDCACHE_MAX_WAY` 宏（与既有 `DCACHE_INDEX_BITS` 同机制），`special.h` 用宏拼 `cfg_val`。**换配置必须同步 NEMU 宏并 `rm -rf NEMU/build` 强制重编**（make 不跟踪宏变化，本次踩坑：`special.o` 未重编导致 difftest mismatch）。

### 实测数据（Verilator difftest，全测试 PASS）

| 配置 | cryptonight (cycles / IPC) | matrix | stream | mixed |
|---|---|---|---|---|
| 2w/16B（旧默认） | 121.90M / 0.1894 | 0.3104 | 0.2293 | 0.2665 |
| 2w/8B | 109.32M / 0.2112 | 0.2295 | 0.1695 | 0.2348 |
| 1w/16B | 122.07M / 0.1892 | 0.2991 | **0.0669** | 0.2614 |
| **2w/4B（新默认）** | **68.79M / 0.3357** | 0.2399 | 0.1430 | 0.2483 |
| 1w/4B | 68.81M / 0.3356 | 0.1892 | 0.1429 | 0.2467 |

- **去掉两路组相联对 cryptonight 无收益**（命中率由 2MiB 容量 miss 主导，52.95→52.87%）；对 stream 是灾难（0.2293→0.0669，容量减半+顺序冲突）。
- **4B line 使 cryptonight 周期减半（-44%），IPC +77%**：随机访问下 refill 只取需要的 1 个 word。matrix/stream（有空间局部性）以 16B 为最优，这是明确的权衡——cryptonight 为核心指标，故 4B line 定为新默认。

### 修复的三个正确性缺陷（4B line 下暴露，difftest 全绿但 ExtRAM 数据错）

1. **CPUCFG 几何与 RTL 脱节**：CPUCFG 固定报 16B 行 → 内核 FLUSH_DCACHE（`cacop 0x09`，`set<<offset_bits` 遍历）漏掉 3/4 的行 → 测试收尾 dirty 行未写回，数据丢失。修复：CPUCFG 全参数化（DUT + NEMU 锁步）。
2. **空 slice 被编译器当 2 位**：`cacop_wb_cnt[WORD_WIDTH-1:0]`（WORD_WIDTH=0 → `[-1:0]`）被 Verilator 解析为 2 位 slice → S_CACOP_WB_WRITE 地址拼接 34 位、截断丢 etag 高 2 位 → cacop 写回地址错乱到 0x71xxxxxx（ExtRAM 窗外）。修复：`(WORD_WIDTH > 0) ? … : {etag, idx, 2'b00}` 三元守卫。
3. **cacop dirty 检查混用两拍地址**：`dirty[当前拍 addr[0]][寄存器(上一拍) cacop_idx]` → 背靠背 cacop 读错行 dirty → 直接 INV 丢写回。修复：dirty 索引用当前拍地址解码（与 cacop_way 同拍）。

另修两个潜伏缺陷：`store_refill_ok` 单槽覆盖（原 `req_wo != st_merge_wo` 守卫在 1-word 下恒放行，第二个 store 覆盖第一个）；S2 miss 路径缺 `m_wdata/m_wstrb` 捕获（refill 合并写旧值）。

### difftest 规范问题（未修，录入备忘）

1. **cacop 特权检查不一致**：NEMU 在 PLV=3（用户态）执行非 0x10 的 cacop 报 IPE 异常（`special.h`），DUT（`core.sv` cacop 通路）无特权检查。内核只在特权态用 cacop，暂未暴露；若用户程序执行 cacop 会 difftest 分叉。修复需在 DUT decode/EX 增加 PLV 检查。
2. **difftest store queue overflow 静默降级**：出现 `difftest store queue overflow, difftest store commit disabled` 时 store 提交校验被禁用（baseline 日志可见），该段无覆盖。NEMU 侧 store 队列应加大或至少显式告警。
3. **difftest 不比内存**：cacop/flush/写回类错误（如本次 1/2/3）difftest 全绿、只有 ExtRAM compare 能抓。任何 cache 一致性改动必须跑 compare_ext 类测试。

## 2026-08-01（深夜）: 并发写回/refill 重叠上板验证通过 —— 全测试优于串行版

上板实测（8B 行默认 + 并发写回，2026-08-01）：

| 测试 | 8B 无并发 | 8B+并发写回 | 16B 无并发 | difftest 预估 | 偏差 |
|------|:---:|:---:|:---:|:---:|:---:|
| cryptonight | 1883ms | **1600ms** | 2446ms | 1580ms | **+1.3%** |
| matrix | 444ms | **391ms** | 374ms | 384ms | -1.8% |
| stream | 473ms | **442ms** | 395ms | 436ms | -1.4% |
| mixed | 25ms | **23ms** | 25ms | 24.2ms | +5.0% |

- 相对 16B 无并发：cryptonight **-35%**、stream +12%（16B 行对 stream 更优但并发缩小差距）、matrix +4.5%、mixed -8%。
- **difftest 估时与上板偏差 ≤5%**（并发前 +5~14%）：写回移出 load 关键路径后，EXTRA_LATENCY=7 校准模型的"关键字等待"假设更贴近实际。
- 与 2026-07-31 的 `4c7f524` 失败（上板 50 分）对比：根因是并发写回期间写回完成（bvalid）被误认作 refill 读数据（`data_ok` 读写合并的竞态窗口），1:1 Verilator 踩不到、2:1 上板触发。`rdata_ok`（读通道专属数据有效）分离后根治。

## 2026-08-01: DCache 数据回归 BRAM（rvcpu 格式 0-cycle hit）

**背景**：2026-07-29~31 的 0-cycle 命中路径为数据 RAM 增加了组合读端口（`data_rd_comb`），`ram_style="block"` 无法满足异步读 → Vivado 整体降级：
- dcache 数据 8×256×32 → LUTRAM（RAM128X1D×128/数组，~1024 LUT）
- dcache tag（变量 way 索引写）→ "3D RAM not supported" **完全寄存器化**（~10.5Kb FF）
- icache 数据（256 深 LUTRAM 级联）→ RAM64X1D×8 + RAM64M×40/数组

**借鉴 rvcpu 的 0-cycle hit 格式**（`RAM_SinglePort/SimpleDualPort` + `READ_LATENCY` 参数）：
- **只有 tag 需要异步读**（0-cycle hit 判定、data_ok 请求拍发出 → 流水线不暂停）
- **数据保持注册读（READ_LATENCY=1，BRAM）**：读延迟被 M→W 流水寄存器吸收，WB 级在请求后一拍直接采样 cache 数据输出（`writeback(.rd(dresp.data))`），load-use hazard 兜底 RAW
- 存储统一封装参数化模块 `ram_sdpram`（1 写 1 读 + BYTE_WIDTH 字节使能，READ_LATENCY=0 → `ram_style="distributed"` 组合读，=1 → `"block"` 注册读）

**落地改动**：
1. `ram_sdpram.sv`（新）：参数化 SDP RAM，generate 分支按 READ_LATENCY 选 ram_style
2. `icache.sv`：data/tag 改 `ram_sdpram`（latency 0，保持 0-cycle 取指 —— fetch_unit 需 data_ok 同拍指令）
3. `dcache.sv`：data 改 `ram_sdpram`（latency 1，BRAM），删除 `data_rd_comb` 组合读；读控制在请求拍发 fast-path/hum 读；S_MISS 拍 HUM 推迟（读端口被 victim 读占用）；tag 写改 per-way 使能（`g_tag_way` generate，修复寄存器化）
4. `core.sv`：`dbus_resp_t` 增 `hit`/`hit_way`；mem_wb 增 `mem_hit/mem_hit_way/mem_size/mem_unsigned`；WB 级 `wb_final_res` 用**全量数据端口** `dcache_data_wb`（= `data_rd_out`）按寄存器化 way/word 提取 —— dresp.data 的 way/word 选择反映**当前**请求，WB 拍（下一拍）已错位，不能用于覆盖

**调试中排掉的两个坑**（difftest 定位，instruction #7438 循环末次迭代 load 得 0）：
1. **S2 hit 误标 `hit=1`**：S2 hit 数据同拍就绪（S1 拍发的读），是 0 延迟语义，应 MEM 捕获（hit=0）；混用 1 延迟 WB 覆盖依赖脆弱的"WB 拍 data_rd_out 不变"假设
2. **WB 覆盖数据错位**：`wb_final_res = extract(dresp.data, ...)` 在 WB 拍用**新请求**的 `req_hit_way/req_wo` 索引上一请求的读结果 → 取到别的 way/word（未初始化 0）。修复：dcache 直出 `data_rd_out` 全量（`data_wb` 端口），WB 用 mem_wb 寄存器化的 `mem_hit_way` + `mem_addr` word 位选择 —— 与 rvcpu 的"数据全量输出 + W 级寄存化地址选择"同构

**验证**：
- 全量 6 测试 difftest 通过：simple 24K / fibonacci 95K / mixed 331K / stream 3.96M / matrix 5.65M / cryptonight 23.09M 条指令
- Vivado 2019.2 综合（step_synth）：0 error；**dcache 数据 4×256×32 → RAMB18 ×4（Block RAM）**，tag → LUTRAM（RAM64X1D+RAM64M），icache data/tag → LUTRAM；BRAM 报告 READ_FIRST/WRITE_FIRST 双口成立
- 遗留：impl 时序未跑（CI 流程覆盖）；`data_wb` 128 位总线走线需关注

## 2026-08-02: 1MB 单级 DCache（全 BRAM）——WaitStart 超时根因定位（HUM 一致性回归）并修复

### 背景

matrix 装下工作集的探索（2026-08-01）最终收敛到 **1MB 单级**：16384 sets × 4 ways × 16B = 1MB，全部存储（数据/tag/dirty/PLRU）进 BRAM。之前 2048 深 LUTRAM 的教训（dcache 分区 370 万实例、Timing Optimization 40+ 分钟、CI LUT 超用/时序失败）证明深度相关 MUX 只能靠 BRAM 消灭。

### 架构（2 拍命中路径）

tag/dirty/PLRU 全部 `ram_sdpram`（READ_LATENCY=1 注册读），命中路径 2 级流水：
- **REQ 拍**：发 tag+data+dirty+PLRU 读（请求 index）+ 锁存请求（p_valid/p_addr/p_*）
- **RESP 拍**：注册 tag 比较判定命中/缺失，data_ok + 数据当拍（LSU 停 1 拍，S1/S2 管道删除）

HUM 期间读地址保持（p_valid && in_refill 时 data/tag/dirty/plru 读口持续指向 p_idx，否则中间 refill 状态会用 mem[0] 覆盖注册输出——调试中定位的数据错位 bug）。miss 上下文（m_eway victim/m_edirty/m_etag）在 RESP 拍从注册输出捕获。dirty/PLRU 写口统一在单一 always_comb 驱动（DRC MDRV-1 多驱动修复——曾因 FSM 组合块 + 顺序块双驱动被 CI 拒绝）。

### difftest 结果（全 6 测试通过）

| 测试 | 8B 基线 | 128KB 0-cycle | 1MB（1 拍命中） |
|------|:---:|:---:|:---:|
| matrix | 0.2941 | 0.7572 | 0.5815（+98%，hit 99.75%） |
| cryptonight | 0.2923 | 0.2859 | 0.3686（+26%，hit 71.4%） |
| mixed | 0.2744 | 0.3754 | 0.4962（+81%） |
| simple | 0.1488 | 0.4066 | 0.5961 |
| stream | 0.1815 | 0.2541 | 0.1820（~0，1 拍惩罚抵消容量收益） |
| fibonacci | 0.1329 | 0.1316 | 0.1264（-5%，S_INIT 65536 拍） |

cryptonight 命中率 71.4%（上板实测 **74.93%**）= 50% 短期重用（迭代内 ld+st 同地址，与容量无关）+ ~25% 容量项（实测线性系数 ~0.42×C/W，低于理论 0.85——PLRU 对随机流效率损失）。1 拍命中惩罚是主要代价（matrix 对比 128KB 0-cycle 0.757→0.5815）。

### CI（submit-20260801-dcache1mb-v2）✅

- **BRAM 295 个全部推断成功**（数据 256 RAMB36 + tag 27 + dirty/PLRU RAMB18），占用 295/365 = 81%
- **WNS = 2.794 ns**（0 违例）；布线垂直 3.9%/水平 4.3%（无拥塞）
- 实现耗时 ~8 分钟（全 BRAM 无 LUTRAM 级联，远快于 2048×4 的 40 分钟）
- 0 Errors / 0 Critical Warnings

### ⚠ 上板问题：cryptonight WaitStart 超时（15s）——根因：HUM 一致性回归（已修复）

远程实验平台现象：`MONITOR initialized → Jumping to CRYPTONIGHT → ERROR: timeout during WaitStart`。**monitor 轻负载通过、测试程序重负载卡死**——monitor 工作集极小从不触发换出，测试程序一上来就是 2MB scratchpad 填充（海量 store → 换出 → 写回）。

**根因**（`2c803d8` + `0365302` 修复）：1MB 重写（`3c8da53`）相对上板验证版 master（`eb61351`）删除/破坏了 HUM 命中（refill 期间命中其他行）的状态维护：

1. **S_REFILL_WRITE 写口覆盖**：HUM store 的 RESP 拍若落在 S_REFILL_WRITE（数据写口归 refill 所有），FSM 组合块内 HUM store 赋值（后置）覆盖 refill 写 → **refill 行丢一个 word**（tag 已置 valid，之后命中读到垃圾/旧数据）
2. **HUM store 不置 dirty**（master 的 `if (hum_ok) plru/dirty` 更新被删）：行换出时 `m_edirty=0` → 不写回 → **store 数据静默丢失**（difftest 不比内存，抓不到）
3. **响应/清除/写口不一致**（首轮修复只门控写口，次轮闭合）：S_REFILL_WRITE 拍 HUM store 仍被应答（data_ok）+ 清 p_valid + 置 dirty 但数据未写——响应块/顺序块清除/dirty 更新须与写口同步门控 `(p_op ? (state != S_REFILL_WRITE) : 1'b1)`，让 store 被拒绝、保持 p_valid、refill 完成后在 S_IDLE 快路径命中重写（与 master `hum_ok` 的 S_REFILL_WRITE 语义一致）

**为何 difftest 全绿**：difftest 只做寄存器锁步不比内存；HUM store 在 1:1 短 refill 窗口下少，且丢数据若不被后续 load 读回则寄存器不受影响。上板 2:1 时钟下 refill 窗口翻倍 → HUM store 概率大幅上升 → 数据损坏 → cryptonight 死循环 → WaitStart 超时。

**排除 REQP-1839/1840**：42 个警告（CDC 异步复位寄存器驱动 BRAM 控制脚）曾为主要嫌疑，但 CDC_ASYNC_SIM 2:1 仿真复现被判定不可靠（`71fbe97` 丢弃），且 HUM 回归修复后上板全过——**复位窗口非本次卡死根因**（警告本身仍遗留，见待办）。

### ✅ 修复后上板实测（submit-20260802-humfix-v2，全测试通过）

| 测试 | master 8B+重叠 | 1MB+HUM 修复 | 变化 |
|------|:---:|:---:|:---:|
| matrix | 391ms | **209ms** | **-47%** |
| cryptonight | 1600ms | **1367ms** | **-15%** |
| stream | 442ms | 566ms | +28% |
| mixed | 23ms | 35ms | +52% |

matrix/cryptonight 吃满 1MB 容量收益（matrix 110KB 工作集全命中、cryptonight 命中率 71.4%）；stream/mixed 顺序流/短重用被 1 拍命中惩罚 + 16B 行抵消（与 difftest 预估方向一致）。四项合计 2177ms vs master 2456ms（**-11%**）。

**待办**（遗留项，均非本次卡死根因）：
1. REQP-1839/1840 警告仍在（42 个）——BRAM 控制引脚由 CDC 异步复位寄存器驱动，复位窗口风险未消除，建议后续 CDC 相关寄存器改同步复位或复位期门控 BRAM 写使能

## 2026-08-02（续）：两级 dcache 第二轮 —— 直通式设计（wip/2level-cache，未提交）

### 背景

第一轮两级尝试（8KB L1 + 1MB L2，B 式逐字 refill）IPC 全面下降且 cryptonight 未修好（该轮记录已移除——其结论在第三轮修复正确性 bug 后不成立，两级最终为正收益，见 README「两级 cache 落地」注记与续三）。本轮重新设计：**L1 miss 直通 L2**，消除逐字 refill 的往返开销；L1 只做 0-cycle 命中叠层 + 按字填充。

### 新设计（l1dcache.sv 重写，约 570 行）

- **L1 命中**：请求拍内 0-cycle 响应（LUTRAM tag 组合读 + 数据注册读，WB 级重取，沿用 wip 的 `dresp.hit/hit_way/data_wb` 机制）；store hit 同拍写 L1 并置 dirty
- **L1 miss**：请求**原样直通 L2**（`mem_req` 组合直连，`cpu_resp` 在「有 outstanding 或正在转发」时直通 L2 响应）——miss 路径与单级 1MB 完全相同，**永远不会比单级差**
- **按字填充（word-sector）**：L2 响应到达时，L1 把该 word 写入本行并置 per-word valid；行 = 16B 4 word，per-word valid/dirty；partial-byte store 不填充（字保持无效，后续访问走 L2）
- **淘汰**：fill 需替换 victim（PLRU）时先捕获 victim 行（vc，读端口空闲时），脏字按字写回 L2（dr，LSU 请求优先）；fill/vc/dr 互斥（wb_buf 独占）
- **cacop**：L1 的 `S_CACOP_INV` 改为**电平 done**（等 `cacop_req.valid` 掉落），`l2_cacop_req.valid = core.valid && l1_done` 门控不变——修复「L1 done 脉冲被 L2 忙碌错过」的死锁（flush walk 会挂死）
- **数据数组**：L1/L2 的数据 BRAM 都改为**模块内声明**（`data_mem` + 注册读），不再经 `ram_sdpram` 模块——Verilator 对模块输入端口（raddr）的采样在状态转移拍滞后一拍，导致 cacop/写回读错行（tag/dirty 是模块内数组不受影响，data 受影响）

### 单元测试（unittest/cache_hierarchy/，12 场景）

`cd unittest/cache_hierarchy && ./run_test.sh`（run_test.sh 为本轮新建）。

### 本轮修复的 bug（全部由单元测试暴露）

1. **L2 `S_REFILL_DONE` 拍 `p_st_merge` 污染**：清除 `st_merge_pending` 只在 `S_REFILL_WRITE` 的 `rf_wr_cnt==3` 拍；落在 `S_REFILL_DONE` 拍的 store RESP 会设置合并槽且永不被消费 → 残留的旧合并数据污染下一个 refill 行（test 3b/4b 数据错位）。修复：`p_st_merge` 排除 `S_REFILL_DONE`（该 store 保持 p_valid，refill 后在 S_IDLE 重新命中）
2. **L2 冷行 partial store 合并丢 rf_buf 字节**：`S_REFILL_WRITE` 的 store-miss/read-back 合并分支只写 store 字节（`we=m_wstrb`），rf_buf 的其他字节从未写入 BRAM（refill 前是旧值）→ 冷行 `st.b` 后读回错误。修复：合并分支整字写入，按 strobe 与 `rf_buf[rf_wr_cnt]` 逐字节合并（master 也有此潜在 bug，上板测试以全字 st.w 为主从未触发）
3. **L1 `cpu_resp` 无条件泄漏 `mem_resp`**：响应 mux 的 else 分支无条件直通 L2 响应，无请求时残留响应（如 drain store 的 accept）被 driver/下一请求误用 → 下一请求被错误完成且拿到错数据（test 6 line1/2 读回 0）。修复：直通门控在 `o_valid || (cpu_req.valid && !req_hit)`
4. **L1 cacop drain 呈现旧值**：`cacop_wb_buf` 在 `S_CACOP_WB_WRITE` 第一拍末才捕获，drain store 从第一拍就呈现旧值（0），L2 捕获到 0（test 7 写回 0）。修复：`cacop_store_req` 跳过捕获拍
5. **L1 cacop drain 地址错**：`cacop_store_addr` 用 `cacop_req.addr[31:4]`，但 cacop 指定的是 **index（set/way）**，该 index 上的实际行可能映射到其他地址（storm 中 L1 set 0 way0 放的是 0x1c014008 行）→ 脏数据写回错误内存行（test 12 的 1278 个 diff 的主因）。修复：用 `tag_mem[cacop_way][cacop_idx]` 的行真实 tag 拼地址
6. **L2 读控制状态转移拍 data 读错位**：`S_IDLE→S_CACOP_WB_READ` 转移时 raddr 组合跳到新状态的默认 0，而 ram_sdpram 的 raddr 端口采样滞后一拍 → cacop 读错行。修复：数据数组改为模块内声明（与 tag/dirty 读同一采样时机）+ 读控制补 `S_CACOP_WB_READ/WRITE → cacop_idx`、`p_valid && S_IDLE → p_idx` 分支
7. 测试驱动注册化呈现问题（testbench 侧）：呈现门控在响应缺席时，避免旧请求被重复转发

### 测试状态（12 场景，10 通过，2 失败）

```
[PASS] test 1-7, 9-11   （store 流、keyword、0-cycle hit、word-sector、partial store、
                         淘汰写回、cacop 0x09 顺序、hit-under-miss、store 读回、uncached）
[FAIL] test 8: got 00000000   ← cacop 0x01 语义与测试期望矛盾（见下）
[FAIL] test 12: 1278 words differ after flush   ← L2 换出写回从未触发（见下）
```

### 剩余问题 1：test 8（测试期望问题，非 RTL bug）

test 8 期望「store → cacop 0x01 → load 读回 store 数据」，但 cacop 0x01（index invalidate）按语义清 **L1+L2** 的行（不写回），store 数据只在缓存（未落内存）→ load 从内存读 0 是**正确行为**。需修改测试期望（或改用 0x09 验证）。注意：0x01 的 L2 行为（清行）与 0x09（写回+清）都经 `l2_cacop_req` 门控发给 L2。

### 剩余问题 2：test 12 漏写回（活跃调试中）

- 现象：storm（3000 次伪随机，2MB 窗口）后全量 flush walk（0x09），1278/131072 words 与 lastv 不符，全部是 `mem=0 want=非0`（漏写回）
- 已确认：storm 期间 **`L2WBURST=0`**——L2 的 `S_WB_WRITE`（换出写回内存）从未触发；L1 的 drain（脏字→L2）正常（test 6 验证过）
- 推论：L2 换出时 `m_edirty` 判定恒为 0 → dirty 行被换出时**静默丢弃**（未写回内存）→ flush walk 时这些行已不在 L2，无法写回
- `m_edirty <= dirty_rd_data[victim_way()]`（S_MISS 拍），`victim_way()` 遍历 `plru_rd_data`（REQ 拍发的 plru 读）。**下一步查：plru 读/更新的正确性、victim_way() 遍历、以及 S_MISS 拍 dirty_rd_data 的采样时机**（l2dcache.sv 的 plru 数组/读控制/`victim_way()` 在 ~239 行、plru 更新在 ~770 行附近）
- 调试 trace 已保留在 test_tb.sv（`L2WBURST`/`L2WRITE` 打印、test 7/8 区间打印、test 12 的 pre-flush DEBUG 读）
- 验证手段：`unittest/cache_hierarchy/run_test.sh`（storm 迭代数已临时改为 3000，定位后可恢复 60000）

## 2026-08-02（续二）：两级 dcache 第三轮 —— 单元测试 12/12 全绿（wip/2level-cache）

按上文的调试方向继续用单元测试追 test 12。**此前的「L2 换出写回从未触发」推论是错的**：3000 次随机访问摊到 16384 组，每组平均 <1 次 miss，L2 根本不需要换出（`L2WBURST=0` 是正常现象，不是 bug）。真正的根因分三层，全部由 testbench 级 trace 暴露：

### 本轮修复的 bug（l1dcache.sv 3 处 + l2dcache.sv 1 处 + testbench 3 处）

1. **L1 drain 跳字漏写（l1dcache.sv 核心 bug，test 12 的 1278 漏写主因）**：`dr` 状态机在「脏字因 LSU 占用总线无法呈递」时落入 `else dr_word <= dr_word + 1` 分支**跳过该脏字**——drain 从字 1 开始的脏行全部被静默丢弃（1237 次 victim capture 只有 18 次真正送达 L2）。修复：脏字未呈递时 HOLD（不推进）。
2. **L1 drain accept 被抢（l1dcache.sv）**：drain store 呈递后被 LSU 新请求抢占（mem_req mux 优先），L2 改答 LSU 的请求，drain 误认 accept → 脏字丢失 + `o_valid` 卡死（cacop walk 挂死）。修复：`lsu_forward_req` 门控 `!(dr_valid && dr_waiting)`——drain store 持续呈递直至 L2 捕获，LSU 请求（本来就重呈递）排队等待。
3. **L1 fresh fill 残留旧 dirty 位（l1dcache.sv）**：`fill_new_dirty` 无条件保留旧行的 dirty 位——非 partial fill 覆盖 victim 后，旧行**从未被写入的字的陈旧数据**被标 dirty，后续 eviction 把 garbage 写进 L2 的错误行（storm 中两条相邻 L2 行数据互串）。修复：仅 partial fill 合并旧 dirty 位。
4. **L2 mem_req_r 幽灵请求（l2dcache.sv）**：`assign mem_req = mem_req_r`（注册输出）在 FSM 离开呈递态后仍有效一拍——空闲总线把幽灵请求当新事务接受：写回 burst 结束后再写一遍该行（word 0 写进最后一字数据、其余字被零覆盖）。修复：`mem_req.valid` 门控 `state inside {S_UNCACHED, S_WB_WRITE, S_REFILL_REQ, S_CACOP_WB_WRITE}`。
5. **testbench lastv 数组尺寸（test_tb.sv）**：storm 窗口 2MB = 2^19 words，`lastv` 只有 2^17 项——高位回卷别名，1354 个「漏写」全是假阳性（对比词恰是回卷位置）。
6. **testbench 内存模型 addr_ok 时序（test_tb.sv）**：模型把 `m_addr_ok` 寄存一拍，而真实 arbiter 的 `w_dresp_addr_ok` 是组合输出——模型每拍采样到的数据比 wb_cnt 滞后一拍，burst 写回的最后一字丢失（eviction 写回 [0,0,0,0x493] 变成 [0,0,0,0]）。修复：`m_addr_ok` 改组合逻辑。
7. **testbench test 8 期望（test_tb.sv）**：按 cacop 0x01 语义（两级 invalidate 不写回）改为期望读回 0，并校验 invalidation 确实到达两级。

### 测试状态（12/12 通过）

```
[PASS] test 1-12（含 60000 次迭代 storm：L2 换出 burst 46240 次呈递、cacop 写回 404 次，全部正确）
[ALL PASS]
```

storm 迭代数已恢复 60000（`for i < 60000`）。调试 trace 已清理，保留 `L2WBURST`/`L2WRITE` 两项关键打印。

### 下一步清单

1. `make test-*` 六个 difftest 全量回归（cryptonight 是上一轮的失败项，本轮设计应规避其根因，需实测）
2. IPC 测量 + L1 尺寸调优（`core_top.sv` 的 `L1CACHE_SETS` 参数，预期 matrix 提升最大）
3. 提交 + CI（CI 需注意 Vivado 2019.2 语法兼容性）

## 2026-08-02（续三）：L1 存储 ram_sdpram 实例化 —— CI impl 卡死根因（wip/2level-cache）

上一轮 difftest 全过、IPC 有正有负，但 **gitlab CI 的 impl 永不收敛**（route Phase 4.2 Global Iteration 1，Number of Nodes with overlaps = 123862，Failed Nets = 115277），且 impl 阶段前无任何错误日志。对比单级成功提交（`submit-20260802-perfcnt`，WNS=2.213、1:49 收敛）：两级 link_design 报告 **Analyzing 25922 Unisim elements**（单级 1714，15 倍）——Unisim Transformation 两边相同（RAM128X1D×512 等来自 icache），差异全部来自 L1 dcache 的存储数组。

### 根因：模块内多维数组 + ram_style 属性不被推断为宏

`l1dcache.sv` 原声明四个模块内数组：`data_mem`（2×256×4×32，**8 个注册读口**——单 primitive 只有 1 读口，BRAM 推断必然失败）、`tag_mem`/`dirty_mem`/`plru`（multidim + 多地址组合读）。Vivado 2019.2 不把这类数组综合成 BRAM/LUTRAM 宏，而是**展开成纯逻辑**（LUT 树），约 +24k Unisim 元素，routing 永不收敛。**结论：cache 存储（及任何可推断 RAM）必须用 `ram_sdpram` 实例化，一个读口一个实例；模块内数组 + ram_style 是反模式**（已写入 AGENTS.md 硬规则）。

### 修复（l1dcache.sv，b838abb）

- **data**：16× `ram_sdpram #(.READ_LATENCY(1))` 实例（2 way × 4 word，`en` = 写使能 × way/word 匹配），照单级 `dcache.sv` 的 g_data_way/g_data_word——进 BRAM（synth 实测 **293.5 BRAM tiles**，LUT as Memory 2792 / LUT 11284）
- **tag/dirty/plru**：每 way 一个 `ram_sdpram #(.READ_LATENCY(0))` 实例（组合读，LUTRAM 宏），照 `icache.sv`——0-cycle 命中路径保持组合
- **单读口收敛**：每个实例只有 1 个读地址；tag/dirty/plru 的全部组合引用收敛到统一地址 mux：`req_idx`（请求/命中）→ `o_idx`（outstanding 请求：load miss 关键字拍 LSU 在 WAIT 不再呈现 `cpu_req`，`req_idx` 是陈旧的，必须读 outstanding 请求的索引）→ `cacop_idx`（cacop 状态）

### 调试中发现的隐藏 bug：fill 期间命中误判（test 12 的 14 words 丢失）

raddr mux 最初把 `f_valid`（fill 进行中）切到 `f_idx`（fill 写判定需要读目标行 v/dirty）——但 **0-cycle 命中判断（`req_tag_data`，每拍组合运行）也被迫读 `f_idx` 的行**：store 27215（idx 0xc0, tag 1c052）在另一个 idx（3c）的 fill 进行中时，`tag_rd_data[1]` 读到 fill 目标行的 tag 恰好也是 1c052 → **误判命中错误行，store 数据写进错误行静默丢失**（storm 对比 14 words mem=0）。修复：**fill 写侧读提前到 initiation 拍捕获**（`f_old_v`/`f_old_dirty` 寄存器，此刻读口地址恰为请求索引），fill 写拍不再碰读口——读口永远服务命中判断（`req_idx`/`o_idx`）。

### 验证

- 单元测试 **13/13 全绿**（含 60000 次 storm + 全量 flush 内存比对）
- difftest 6/6 通过，**IPC 无回退**（与提交版逐项一致）：simple 0.5202 / stream 0.2469 / matrix 0.6324 / mixed 0.4553 / cryptonight 0.3594 / fibonacci 0.1264
- 本地 synth（Vivado 2019.2 docker）：Block RAM **293.5 tiles（284 RAMB36 + 19 RAMB18）**、Slice LUTs 11284（8.38%）、LUT as Memory 2792——存储全部宏化，impl 前资源健康
- gitlab CI 已提交 `submit-20260802-2levelci3`（b838abb），**impl 恢复收敛（对比 25922 Unisim 卡死）**
- **上板实测（gitlab CI 远程平台，50MHz）**：matrix **190ms**（单级 209ms，**-9.1%**）、stream **419ms**（单级 566ms，**-26.0%**）、cryptonight 1399ms（单级 1367ms，+2.3%）、mixed 37ms（单级 35ms，+5.7%）——**四测试合计 2045ms，较单级 2177ms 总成绩提升 6.1%**；stream/matrix 的大幅提升来自 L1 0-cycle 命中消除 1 拍命中惩罚 + 顺序流局部性；cryptonight/mixed 微降（L1 容量 miss 的逐字往返惩罚）
- AGENTS.md 增补硬规则：cache 存储必须 `ram_sdpram` 实例，禁止模块内多维数组 + ram_style；提交前查 `report_utilization`（d0f720b）

## 2026-08-02（续六）：burst 整行分支收尾（wip/burst-wholeline）—— 不并入，存档；单测迁移 + 修复评估

### 背景

在直通式两级（本分支，上板 2045ms）基础上，`wip/burst-wholeline` 分支按「逐字往返惩罚」的教训改造 L1↔L2 传输通道：L2 cpu 口对 `burst_len=3` 请求流式整行返回（keyword 优先），L1 整行收集后原子建行。本记录为最终评估与收尾。

### burst 分支状态（HEAD 8731b31，存档）

- 正确性：**8 个 bug 全部修复**（col 收集丢失、load miss 整行不齐、hum 挂起读错 set、收集 word 错位、误判 hit 打断 refill、**col_cnt 2-bit 回卷误收集、挂起 collection 被同线 store 弄脏后 materialize 过期行、填充期间同线 store 被转发**）——**60000 次 storm 14/14 全绿**（新增 test 14 push/pop 同线连续 store，旧代码稳定复现）
- difftest：simple 0.5202 / stream 0.2444 / matrix 0.5051 / mixed 0.4452 / fibonacci 0.1264 通过；**cryptonight 未通过**（crn_hext scratchpad load 读到 0，2MB thrash 下根因未定位）
- 对比直通版（本分支）：burst 版 difftest 无优势（matrix 0.6324→0.5051 反而回退——整行 fill + 脏行 drain 的固定开销在容量主导工作集上更重），且 cryptonight 未过 → **不并入，分支存档**（其 3 个收尾修复 + test 14 的价值已评估，见下）

### 单测迁移到本分支（unittest/cache_hierarchy，13/13 → 15/15 全绿）

- **test 14**（push/pop 同线连续 store，monitor 栈帧模式）：迁移，直接通过——直通式按字填充下该模式无 stale 窗口
- **test 15**（脏 victim 拖住 fill 期间同 word store，回归保护）：迁移，直接通过——**直通式天然安全**：fill_wr 只被 vc_valid 阻塞、dr 不阻塞；窗口内 store 被 drain 门控（`!(dr_valid && dr_waiting)`）压住，fill 完成后 store 重试**命中 L1 写最新数据**（无"转发后 LSU 不再重试"的丢失路径，与 burst 版 collection 挂起机制不同）
- **3 个 burst 修复对直通式评估结论：均不适用**——修复 1/2（col_cnt 回卷、挂起 collection 被同线 store 弄脏）针对 burst 版整行 collection 机制（直通式无 collection，fill 在响应拍立即发起并捕获响应数据）；修复 3（fill 挂起期间同线 store 被转发）的窗口被直通式的 dr 门控 + store 重试命中天然覆盖（见 test 15 注释）

### 结论

两级直通式（本分支，上板 **2045ms**）为当前最优配置。burst 整行方向验证完毕：能修对（storm 14/14）但相对直通式无 difftest 收益且 cryptonight 未收敛，**存档于 wip/burst-wholeline**（含全部修复与单测，供未来参考——若重走两级路线，优先在直通式上修 cryptonight 的 load 读到 0（2MB thrash 路径），而非整行填充）。

---

## 下一步方向（2026-08-03）：Runahead —— 掩盖顺序核的 miss 延迟

### 问题（已量化）

cryptonight 的 DCacheRefill 占 ~43% 周期：2MB 随机 scratchpad + 串行依赖链（`addr2` 依赖 `pad[addr1]` 返回数据）。**多 MSHR / load-under-miss 收益 <5%**（DEVLOG 2026-08-01 实测）：顺序流水线一次只有一条 load 在 MEM，后续地址算得出但发不出——**MSHR 只是存储槽，不产生并发**。并发地址只能来自预取器 / runahead / 乱序执行。

### 方案：MERE（`docs/md/2504.01582v1.pdf_by_PaddleOCR-VL-1.6.md`，东南大学 2025，J.ACM）

标量顺序核上实现 runahead：**miss 时不 stall**，继续投机执行后续指令（不提交、不写 GPR），把链上后续访存地址当预取发出；miss 返回瞬间算好下一地址继续预取（**提前一个 miss 步长**），正常执行重跑时命中。核心组件：

- **RCU**（runahead 控制单元 + Efficiency Detector：检测间接访存，预取准确率 95%）
- **MC-CP**（多周期 GPR checkpoint / 恢复）
- **Runahead-Cache**（投机 store 暂存，供投机 load 转发）
- **释放电路**（依赖 stall-load 寄存器的指令跳过，scoreboard 式）

论文结果：达到 2-wide OoO 的 **93.5% 性能**，面积/功耗 <5%。

### 与我们的匹配

- cryptonight 的链式间接访问正是论文 target 的 **indirect miss** 模式（地址依赖前一个 miss 数据）
- 我们的 2-wide 顺序 + 单 MSHR 两级 cache 与论文基座（5 级标量顺序 + 非阻塞 D-cache）同构
- mixed_stride 的伪随机索引 + 依赖链同样受益

### 关键结论（多轮分析收敛）

1. **单 MSHR 即可起步**：cryptonight 的 B 地址依赖 A 数据，天然串行，每时刻只有一个可发预取——单 MSHR 够用
2. **多 MSHR 不是先决条件，是增强**（stream/mixed 的独立预取并发），可后置
3. **真正的先决**：LSU fire-and-forget（miss 不 stall、发出即释放）+ L1 预取接受语义 + checkpoint/释放电路
4. **MSHR 覆盖顺序、不覆盖随机**：随机 + 依赖链的地址不可提前预测，多 MSHR 只能干等

### 路线

在 **master（单 LSU 双发射，`a7e6b67`，上板 1932ms）** 上实施，与双 LSU 方向互斥（双 LSU 的锁步 vs runahead 的投机自由推进）：

1. LSU fire-and-forget + L1 预取路径（runahead 模式）
2. GPR checkpoint / 恢复（MC-CP）
3. Runahead-Cache（投机 store 转发）
4. Efficiency Detector + StepCounter（进入/退出条件）

双 LSU 分支（`dev/ilp-2wide`）已存档：difftest 6/6 全过但仅 matrix +1.9%（其余 0%），且尚未上板验证，**性价比低，不回用**。

## 2026-08-04: 100MHz 冲刺阶段记录（Impl WNS -2.333，交接状态）

### 目标与流程

100MHz（cpu_clk 10ns，PLL CLKOUT0=100MHz/sys_clk=25MHz，xci 由 docker Vivado 重生成）通过 Implementation 且 WNS ≥ 0。流程：difftest IPC 基线 → 修复关键路径 → 全量 difftest + IPC 证明 → Synthesis 余量 → Implementation（40 分钟熔断）。

**difftest 基线（当前 master，no-dcache + axi_sram_direct）**：simple 0.1627 / matrix 0.4476 / stream 0.4951 / mixed 0.6503 / cryptonight 0.7974。

### 已提交的有效优化（按提交顺序，WNS 为累计效果）

| 提交 | 内容 | 效果（synth/impl） |
|------|------|------|
| `12bed5b`/`e9f4c9e` | PLL 重生成 100MHz（docker Vivado 操作 xci） | 时钟基座 |
| `5515524` | XDC：显式 generated clock（cpu_clk=10ns/sys_clk=40ns）+ SRAM I/O delay 挂真实时钟域 | 修复假松弛 |
| `9434138` | core_top dresp 多驱动 bug 修复 | 消除 sim/synth 不一致隐患 |
| `e4acbdd` | SRAM 引脚驱动寄存器化 | 消除 19 级到 OBUFT 的头号瓶颈 |
| `d3bc3fb` | DMW 翻译 EX→MEM（WB 旁路语义修正） | 零 IPC |
| `2bdb2f3` | 槽1旁路直取 alu_res0 | 零 IPC |
| `1addd52` | regfile 写旁路冗余删除 | 零 IPC |
| `ac35c43` | 槽内旁路值注册化 + 同拍依赖对门禁 | 打破串行双加法器静态路径；**IPC 代价 mixed -10.4%、cryptonight -6.7%** |
| `741ded2` | 写缓冲整行覆盖注册 | 响应路径脱离 8 项搜索；impl +0.9ns |
| `d32b5db`/`d16e09f` | Pblock 布局约束（core X20-75×Y10-60 + sram X0-35×Y18-100）+ bcu 符号位预判 | impl -4.496→-2.333（Pblock 贡献约 +1.0ns） |

**WNS 轨迹**：impl -4.496（起点）→ -3.695（Pblock）→ -3.364（注册旁路+门禁）→ -3.007（dresp 注册实验，未采纳）→ -2.462（整行覆盖注册）→ -2.278（Pblock 微调）→ **-2.333**（bcu 显式化，impl 噪声内）。当前 synth -1.230。

### 尝试并回退的实验（含原因）

- **dresp 响应整体注册**：+0.36ns 但 matrix -19.9%——性价比极差，未采纳
- **槽1依赖门禁（无注册旁路）**：静态时序不认逻辑门控，纯 IPC 损失（对照实验证实 impl 仅 +0.16ns）
- **pc_stall 取指侧注册**：破坏 icache miss 取指配对
- **EX 重定向注册（首轮）**：fetch 侧 +1 与流水线实时冲刷不一致，difftest #45 失配——**未查明根因即回退（教训！）**
- **更紧 Pblock**（X15-65×Y10-65）：密度过高反变差
- **转发搜索逐拍注册**：突发读每拍地址变化，1 拍滞后必然错
- **fetch next_pc 显式两级**：综合归一化无变化；优先级写反版失配 #3
- **bcu ltu 最后一级**：synth -1.242（综合重合并 mux）
- **npc 无条件/分支分流**：synth -1.475（逻辑 +0.33 超路由 -0.24）

### 当前关键路径

**JIRL 重定向链**（rf → forward → bcu ltu 3-4 CARRY4 → br_taken → npc jalr 加法器 3 CARRY4 → ex_jump_pc → fetch pc+4 → pc_reg），20 级 6-7 CARRY4，route 占 69%（数据网 0.24-1.43ns ×13），impl -2.333 的 200 条最差路径全部同族。

### IPC 牺牲记录（唯一一处，当前 master 生效）

**提交 `ac35c43`**（槽1旁路值注册化 + 同拍依赖对门禁——打破串行双加法器静态路径的唯一网表级解法；门禁保证注册旁路对同拍依赖对不产生过期值）。**这是当前 master 唯一生效的 IPC 牺牲点**。全量 difftest 前后对比（数据比对全过）：

| 测试 | 提交前基线 | 提交后 | 变化 |
|------|-----------|--------|------|
| simple | 0.1627 | 0.1618 | -0.55% |
| matrix | 0.4476 | 0.4475 | ≈0 |
| stream | 0.4951 | 0.4951 | 0 |
| mixed | 0.6503 | 0.5829 | **-10.4%** |
| cryptonight | 0.7974 | 0.7436 | **-6.7%** |

**曾尝试但已回退的 IPC 牺牲**（不生效，仅记录）：`9de09b2` 纯门禁（无注册旁路）同代价但静态时序无收益，`e9db3c3` 回退；dresp 响应整体注册 matrix -19.9%/stream -16.5%/cryptonight -4.8% 换 +0.36ns，放弃。回收方向：addi/subi+dep-mem 同拍对用合并立即数地址（零串行）。

### 时序闭环后的 IPC 恢复计划（100MHz WNS≥0 后第一优先）

`ac35c43` 的 IPC 代价（mixed -10.4%、cryptonight -6.7%）**不是必要成本**——当时选择"先注册旁路保时序、恢复后置"。时序闭环后按以下方案回收：

**合并立即数地址（零 IPC 代价、零串行）**：对 `addi/subi`（slot0，b=imm）+ 依赖访存（slot1，rs1=rd0）的同拍对，地址 = alu_res0 + imm1 = a0 + (imm0+imm1)——**ID 级预计算 merged_imm = imm0+imm1（常数），ALU1 用 a=forward_a0、b=merged_imm 单加法器并行算出地址**，无串行链。实施点：
1. ID：合并条件（slot0=ADD/SUB-imm && slot1=mem && rs1_1==rd0）+ merged_imm；
2. EX：alu_a1 的合并路径选择 forward_a0、alu_b1 选 merged_imm；
3. 门禁放行该子类（`slot1_dep_alu0` 去掉可合并项）；
4. 验证：difftest 6/6 + IPC 对比（预期收回 mixed/cryptonight 的主要损失）。

备用：收窄门禁（只拦 slot1 的 ADD/SUB/SLT/SLTU 依赖，逻辑操作依赖放行）。

### 交接要点（下一步方向）

1. **分支重定向注册化重做**（最高价值）：在 npc 输出打一拍（fetch 重定向 +1，误预测惩罚 +1），打断 20 级组合链。首轮失败疑为"fetch +1 与流水线实时冲刷不一致导致 if_id N 拍捕获的错误路径存活"——**用 `unittest/UNITTEST-WORKFLOW.md` 的单元测试方法提取失败现场（difftest #45：t0 值错 + idle_pc 卡 0x1c001080）逐个验证冲刷窗口**，不要像首轮那样失配即回退。
2. **工作流硬规则**：任何 RTL 改动必须先过门禁（simple+matrix+cryptonight，`/tmp/opencode/gate_diff.sh`，失败即 exit 1）才能启动 Vivado；**禁止 `grep "mismatch" && docker` 链**（grep 匹配失败文本退出码是 0 会放行）；每次改动的验证计划先写后做。

---

## 2026-08-04（续二）：分支重定向注册化落地（Impl WNS -2.333 → -1.028）

### 已提交的优化（按提交顺序）

| 提交 | 内容 | 效果（synth/impl） |
|------|------|------|
| `1d0c1a1` | B 无条件跳转改 ID 级重定向（+3 处冲刷窗口修复：FQ keep-target 吸收、keep vs EX-override、fetch 侧重定向等待 load_use）| IPC 全涨（simple +3.0%、fib +3.8%、matrix +0.2%、mixed +0.9%），6/6 |
| `469254a` | EX 重定向注册化（do_ex_flush_r/ex_jump_pc_r + flush_pending_r + flush_pc_r + 3 处窗口修复 + if_not_ready 项移除）| synth -1.230 → -0.521；IPC 无损失（simple +2.6%、fib +3.6%、matrix/mixed +0.1%）|
| `ff7aef1` | 写缓冲 per-word full-cover 预计算注册（wb_full_w_r）| synth -0.521 → -0.115（IPC 零代价）|
| `32cc519` | icache/arbiter Pblock（X35-75×Y60-100）| synth -0.115 → -0.092（零 IPC；⚠ 与 pblock_core 在 Y60 边界重叠，需复核）|

### 当前时序（100MHz，默认策略）

- **Synth WNS -0.092**（关键路径：ex_mem ctrl → 写缓冲覆盖搜索 CARRY 链 → arready → arbiter → icache m_eway CE）
- **Impl WNS -1.028**（关键路径：id_ex0 → ALU 加法器 → alu_res0_r → ex_mem → LSU → arbiter → sram-direct 读完成 → icache 标签 RAM WE；13 级、77% 布线）
- 分支重定向链（原唯一瓶颈族）已彻底消失；现瓶颈为**跨模块组合链**（core → sram-direct/arbiter/icache 的布线）

### 尝试并回退的实验

- **icache mem_resp 注册化**（refill +1）：synth -0.092 → -0.066（+0.026），但 **impl -1.028 → -1.078（变差）**——它确实切断了 refill 路径，但网表变化导致布局噪声，浮出并列的 **store 路径**（LSU FSM → Axi_CDC wFifo，约 -1.05）。IPC 实测代价：matrix/stream/cryptonight ~0.02%、mixed -0.43%（在历史波动 0.5829~0.5882 范围内，归因待复跑确认）、simple（smoke）-2.0%。已回退。
- **Pblock 布局**（icache/arbiter）：synth +0.023（零 IPC）——但属"绕过"而非"切分"，且与 pblock_core 重叠；**RTL 切分才是正路**（保留但待复核）。

### 下一步（两条跨模块组合链，均可尝试）

1. **refill 路径**（Impl -1.028）：读完成 → arbiter → icache 状态 → 标签写。切点 = icache 的 `mem_resp` 注册化（refill +1；miss 次数少：simple 894/stream ~数千，性能 IPC 实测代价 ~0.02%；mixed -0.43% 需复跑归因）。切后预期浮出 store 路径（见下）。
2. **store 路径**（Impl -1.078 浮出）：LSU FSM → Axi_CDC wFifo。切点待分析（LSU 请求注册化 or CDC 写端口寄存器化；store 延迟的 IPC 代价需实测）。

两条路径的 IPC 归因都需**同构建复跑**（排除 workload 重建波动）。

---

## 2026-08-04（续三）：系统视图 + 断一指（Synth +0.499 / Impl -0.489）

### 教训（全部沉淀为 AGENTS.md 硬规则）

1. **系统视图**：synth/impl 报告是同一网表同批路径家族的不同排序——不得把 synth top 与 impl top 当无关家族分开处理；每次改动的 top 变化序列（谁浮出、谁消失）揭示整个家族集。
2. **断一指**：改动必须让一个家族从路径集中**结构性消失**（不再出现在报告），而不是在多个家族上各切几级（"伤十指"）。实证：**微调 0 成功 vs 结构消除 5 成功**（记录在 AGENTS.md）。
3. 其他沉淀：commit gate（WNS 变好才 commit）、报告归档进 git、禁波形分析、edit/apply_patch 纪律、每个 commit 自验证。

### 已断家族（7 个，全部结构性消除，IPC 全程零损失）

| 家族 | 断法 | 效果（累计 synth WNS） |
|------|------|------|
| r_addr 复位折叠伪路径 | 删突发死代码（`462a0af`） | -0.092 → +0.050 |
| icache miss 捕获 CE 链 | 捕获条件去掉 next_state 项（`81174be`） | +0.050 → +0.102 |
| 接受链（m_eway/wb_q CE/r_addr） | AR 预览 + 行捕获移位 + c0_cmp（`37bcfd4`） | +0.102 → +0.187 |
| 行级搜索捕获 | WB_DEPTH 8→4（`7b32af3`） | +0.187 → +0.296 |
| cacop 路径 + 命中环（PLRU/way） | cacop 请求寄存化 + icache 直接映射（`e7fbea8`） | +0.296 → **+0.499**；impl -0.868 → **-0.489** |

### 剩余两族（下一轮）

1. **pc_reg 预测**（synth top，+0.499，22 级 9.29ns）：fq_instr → ID 解码（6 级）→ bp 目标加法器 CARRY4×8（7 级）→ 到达比较（3 级）→ flush（1 级）→ next_pc mux（5 级）。零 IPC 断法未找到（加法器/到达比较必须本拍；寄存化 = 重定向晚 1 拍 = IPC）。
2. **SRAM 引脚输出**（impl top，-0.489）：ram_write_active_r → OBUFT → 引脚。数据 6.75ns（OBUFT 3.3 固有）+ 时钟偏斜 -3.347（布局结果）。布局实验两次无效（-0.818/-1.093）；skew 是当前布局的产物，结构修正 synth 后 impl 会随布局重排变化。

**关键路径报告归档位置**：每次 `run_vivado.sh {synth|impl}` 的时序/关键路径报告自动归档在 `run_vivado/reports/<时间戳>-<commit>/`（含 `{synth,impl}_critical_paths.rpt`、`{synth,impl}_timing_summary.rpt`、`synth_util_hier.rpt`）。**当前状态（e7fbea8，synth +0.499 / impl -0.489）的对应归档：`run_vivado/reports/20260804-152939-1c9c813-dirty/`**。历次运行归档（含失败实验）：`20260804-131219-be0b957`（删突发基线 +0.050）、`20260804-140820-37bcfd4`（接受链重构 +0.187）、`20260804-142110-867ad82-dirty`（WB_DEPTH=4 +0.296）、`20260804-144207-7b32af3`（impl -0.868 基线）、`20260804-142751-7b32af3-dirty`/`20260804-143426-7b32af3-dirty`（cacop 实验）、`20260804-132531-81174be-dirty`/`20260804-134040-c90a8ca-dirty`/`20260804-134646-c90a8ca-dirty`/`20260804-141512-867ad82-dirty`（失败的微调实验）、`20260804-145920-20d3d5c-dirty`/`20260804-153828-7a124a4-dirty`/`20260804-154537-7a124a4-dirty`（失败的布局实验）。

### 75MHz CI 尝试（未完成，记录调查结论）

- 目标：提交 75MHz 试 CI 管线（75MHz 周期 13.33ns 必然通过）。
- PLL 实况（sim_netlist 权威）：MMCM，CLKIN 50MHz，MULT_F=18（VCO 900MHz），CLKOUT0 DIVIDE 9→100MHz（cpu_clk），CLKOUT1 DIVIDE 36→25MHz（sys_clk）。75MHz = CLKOUT0 DIVIDE 12。
- **Vivado 2019.2 batch 无改 IP 命令**：`write_ip`/`open_ip` 不存在（GUI 会话命令）、`CONFIG.MMCM_CLKOUT0_DIVIDE_F` 为 disabled 参数（自动推导）、`CONFIG.CLKOUT0_REQUESTED_OUT_FREQ` 在 read_ip 下只读、open_project 下不存在、`export_ip` 语法不可用。**无头 docker 下"通过 Vivado 读写 xci"的可行方法未找到**（`create_ip` 重新生成是候选但未完成——端口名等配置需与现 xci 对齐）。
- git 先例：`submit-75mhz` 分支（`650e481` "sync 75MHz PLL XCI to CI path"——xci 字段级改动，旧配置 MULT 33 时代）——**不能直接套用**（当前 MULT 18）。
- 临时脚本留在 `scripts/pll_*.tcl`（未提交）：`pll_75mhz.tcl`（read_ip+set_property+write_ip 尝试）、`pll_query*.tcl`/`pll_dump.tcl`（参数/配置查询）。

---

## Vivado 操作手册（交接必备）

### 流程入口

```bash
scripts/vivado/run_vivado.sh create   # 重建工程（RTL + xci + XDC）
scripts/vivado/run_vivado.sh synth    # create + 综合 + utilization/时序报告
scripts/vivado/run_vivado.sh impl     # create + 综合 + 实现 + 时序报告
```

- Docker 镜像 `vivado:2019.2`，仓库根目录挂载为 `/workspace`。
- 报告输出：`run_vivado/project/{synth,impl}_timing_summary.rpt`、
  `{synth,impl}_critical_paths.rpt`、`synth_util_hier.rpt`。
- WNS 读取：报告首行数据表的第 1 列。
- **报告归档（硬性）**：每次 `synth/impl` 运行后 `run_vivado.sh` 自动把上述
  报告归档到 `run_vivado/reports/<时间戳>-<commit>/`。**必须随运行 commit**
  （与 RTL 改动同 commit，或基线运行单独 docs commit）。`run_vivado/project/`
  每次被覆盖，**WNS 对比一律引用归档报告**，不得凭记忆或 `/tmp` 日志。

### 硬性注意事项

1. **任何 RTL 改动必须先过门禁再启动 Vivado**：
   `scripts/gate_diff.sh simple matrix cryptonight`（失败 exit 1）。
   禁止 `grep "mismatch" && docker` 链（grep 匹配失败文本退出码是 0 会放行）。
2. **PLL 产物清理**：Vivado 每次运行会在 `src/soc/xilinx_ip/clk_pll/` 再生成
   `clk_pll_sim_netlist.v/.dcp/.veo/.xml` 等 7 个产物，`create_project.tcl` 会
   把它们当源文件扫入，综合报 `Synth 8-5832: source file was generated for
   simulation`。`run_vivado.sh` 已自动清理（产物每次重新生成，删除安全；
   `.xci` 才是源）。
3. **xci 保护**：任何 Vivado 运行后检查 `git status src/soc/xilinx_ip/`——
   `upgrade_ip` 可能静默改写 `.xci`，用 `git checkout` 还原。
4. **difftest 串行**：`make test-*` 共享构建目录（NEMU defconfig + supervisor），
   并行会写坏构建（曾实测）。串行跑，日志可放 `/tmp`（输出物非源）。
5. **`run_vivado/flow/` 受 pre-receive 钩子保护**：不得修改；实验脚本一律放
   `scripts/`。
6. **IPC 归因**：`make test-*` 每次重建 kernel（workload 数据可能变动），
   IPC 有运行间波动（如 mixed 0.5829~0.5882）——归因需同构建复跑。
7. **禁止波形分析**：功能/死锁调试不得使用波形（VCD/FST/gtkwave，含
   `+wave` trace）。只能通过 difftest 输出（Commit Instr Trace、寄存器快照、
   NEMU vs DUT 对比）、静态 RTL 分析、以及 `unittest/UNITTEST-WORKFLOW.md`
   的单测提取流程定位 bug。100MHz 冲刺期间反复用波形挖根因从未成功，
   只烧时间。

### 未跟踪的实验文件（有意保留，勿随意删除）

- `unittest/beq_fallthrough_beq/`：back-to-back beq 模式单测，**未复现 bug**
  （NEMU 按 DUT 提交步进，弹跳自洽），未入库。
- `nscscc-solo-la-soc/rtl/ip/myCPU/core.sv.bak_dbg`：调试备份。
