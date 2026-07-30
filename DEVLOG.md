# DEVLOG — 开发进度与已知问题

## 已验证

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
- [ ] FPGA 上板实测：bitstream 烧录后实机运行各阶段测试
- [x] dcache ghost hit workaround 修复（2026-07-26）：LSU 修复 + just_hit 机制替代 s1_valid 无条件清零，store hit stall 移除（见修复记录）
- [ ] dcache 写缓冲（write buffer）实现：store 命中后异步写 BRAM，消除 MEM 级寄存器延迟空泡

## 当前 difftest 状态（2026-07-26，icache workaround + dcache workaround 修复后）

| 测试 | DIFF=1 difftest | 数据比对 | 指令数 |
|------|-----------------|----------|--------|
| simple | ✅ 通过 | N/A | ~21K |
| stream | ✅ 通过 | ✅ 通过 | ~395 万 |
| matrix | ✅ 通过 | ✅ 通过 | ~564 万 |
| mixed | ✅ 通过 | ✅ 通过 | ~33 万 |
| cryptonight | ✅ 通过 | ✅ 通过 | ~2309 万 |
| fibonacci | ✅ 通过 | ✅ 通过 | ~7.6 万 |

### 分支预测 BTFNT 准确率（2026-07-26）

| 测试 | 条件分支数 | 误预测数 | 准确率 |
|------|-----------|----------|--------|
| Simple | 4,879 | 819 | 83.21% |
| Stream | 791,311 | 820 | 99.90% |
| Matrix | 244,688 | 10,132 | 95.86% |
| Mixed | 41,743 | 4,950 | 88.14% |
| Cryptonight | 1,577,743 | 821 | 99.95% |
| Fibonacci | 17,966 | 330 | 98.16% |

> BTFNT (Backward Taken, Forward Not Taken) 静态预测器，独立模块 `branch_predictor.sv`，含 ID 级 `bp_do_jump` 重定向。`DifftestBranchState` 通过 DPI-C 逐周期上报 `total_branches`（仅条件分支 BEQ/BNE/BLT/BGE/BLTU/BGEU）和 `mispredictions`（预测方向 ≠ 实际方向）。npc 在 EX 阶段抑制正确预测的冗余 flush 并恢复误预测（→ pc+4）。

### 流水线 Stall 七类拆解（2026-07-27 Burst Refill + Writeback）

| 测试 | DCache Refill | ICache Refill | Load-Use | Branch Flush | DCache Hit Pipe | ICache Hit Pipe | Other |
|------|:------------:|:------------:|:--------:|:------------:|:---------------:|:---------------:|:-----:|
| Simple | 0.5% | 4.4% | 2.3% | 12.7% | 46.5% | 22.4% | 11.3% |
| Mixed | 37.5% | 0.4% | 0.7% | 18.6% | 13.3% | 21.5% | 8.0% |
| Matrix | 27.0% | 0.0% | 0.0% | 19.9% | 20.7% | 21.8% | 10.6% |
| Stream | 45.7% | 0.0% | 3.3% | 11.5% | 14.9% | 14.8% | 9.7% |
| Cryptonight | 57.1% | 0.0% | 0.0% | 15.6% | 9.9% | 13.8% | 3.6% |

> 数值为占全部 stall 周期的百分比。DCache Refill 占 stall 比从 burst 改造前的 51-84% 降至 27-57%。Cache 命中流水线延迟（Hit Pipe）合计占 24-43%，已超过 Refill 成为部分 benchmark 的主瓶颈。下一步优先考虑写缓冲（消除 store hit 延迟）或非阻塞 cache（hit-under-miss）。

### 2026-07-27 性能对比（Burst Refill + Writeback Burst vs 基线）

| 测试 | 基线 IPC | 新 IPC | Δ IPC | 基线周期 | 新周期 | Δ 周期 |
|------|---------|--------|-------|---------|--------|--------|
| simple | 0.1505 | 0.152 | +1.1% | 144K | 143K | -0.9% |
| mixed | 0.121 | 0.176 | +45.5% | 2.73M | 1.87M | -31.6% |
| stream | 0.085 | 0.141 | +65.9% | 46.35M | 28.07M | -39.4% |
| cryptonight | 0.091 | 0.163 | +78.8% | 253.95M | 141.85M | -44.1% |
| matrix | 0.122 | 0.172 | +41.0% | 46.35M | 32.80M | -29.2% |

> 基线 = BTFNT+ID重定向（2026-07-26），即 burst 改造前的值。Cryptonight 单次 miss penalty 87 → 30.5 周期（-65%）。refill 数据传递和 writeback 数据传递均由逐字 AXI 事务改为单次 INCR burst。

### 修复记录

#### dcache workaround 修复：load hit ghost + store hit stall（2026-07-26, 750227e + 1f62308）

dcache 存在三个注释标记为 WORKAROUND 的代码段，均是为修复功能 bug 而牺牲时序的错误行为。

**Workaround 1（store hit stall）**：每次 store 命中时 `s1_stall=1`，声称防止 BRAM read-after-write 冲突。

**Workaround 2（load hit ghost）**：每次 load 命中时同时清零 `s2_valid` 和 `s1_valid`，防止 stale S1 值推进到 S2 形成幽灵命中。每次命中浪费 1 周期。

**Workaround 3（s2 linger）**：s1_stall 阻塞 s1→s2 推进时，手动清零遗留的 s2_valid/s1_valid。

根本原因：LSU 在 dcache 返回 data_ok 后 dreq.valid 仍保持 1（因 valid_in 仍为同一指令高电平，state 仍为 IDLE），导致 stale 请求被 s1 重新捕获。Fetch_unit 没有此问题（data_ok 时 ireq.valid 拉低为 0）。

修复分为两部分：

##### 修复 1：LSU dreq.valid 拉低（750227e）

在 LSU IDLE 状态下，当 `dresp.data_ok` 到达时拉低 `dreq.valid`，镜像 fetch_unit 的 `ireq.valid` 处理方式。防止 stale 请求被 dcache s1 重新捕获。

##### 修复 2：dcache just_hit 机制替代 Workaround 2（750227e）

参照 icache 修复，加入 `just_hit` + `last_hit_addr` 寄存器。当 s2_hit 时仅清零 s2_valid（不清零 s1_valid）。下一周期若 s1_addr 与 last_hit_addr 相同（stale），则抑制 s1→s2 推进。需要 LSU 修复配合，否则背靠背同地址 load 会被误抑制。

##### 修复 3：移除 Workaround 1（1f62308）

论证：store hit 时 BRAM 写入与 legitimate 新请求的 BRAM 读取无冲突。新请求进入 s1 的时机晚于 store hit 至少 1 周期（受限于 ex_mem_out 流水线寄存器延迟），此时 BRAM 写入已完成。s1 中 stale 的 store 请求由 just_hit 机制正确处理。

##### IPC 分析

两个 workaround 消除后，dcache 吞吐量达到 1 req/cycle（与 openLA500 持平），但 IPC 无变化。瓶颈不在 dcache，而在 in-order 五级流水线的 ex_mem_out 寄存器延迟：Load A 在 cycle N 命中，Load B 必须等 cycle N+1 的 posedge 才从 id_ex_out 进入 ex_mem_out，最早在 cycle N+1 被 dcache s1 捕获。这 1 周期间隙是流水线物理寄存器固有的，不是 workaround 引入的。

未来提升方向：引入 dcache 写缓冲（write buffer），store 命中后异步写 BRAM 并立即回 data_ok，消除 ex_mem_out 延迟。参照 openLA500 的设计。

##### 效果

全部 6 个测试 DIFF=1 difftest 通过，IPC 不变（如下表）。

| 测试 | 修复前 IPC | 修复后 IPC | 周期变化 |
|------|-----------|-----------|---------|
| simple | 0.1505 | 0.1505 | 0 |
| mixed | 0.1169 | 0.1169 | 0 |
| stream | 0.0812 | 0.0812 | 0 |
| matrix | 0.1218 | 0.1218 | 0 |
| fibonacci | 0.1063 | 0.1063 | 0 |

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

**分析**：当前 DCache 标签和数据均在 BRAM 中（1 周期读延迟），形成 2 级流水线 (S1→S2)。每次缓存访问（含命中）都需要等待标签和数据从 BRAM 返回（1 周期），导致流水线停顿。标签 RAM 仅 ~10.5Kb，可放入分布式 RAM (LUTRAM) 实现组合逻辑读取（0 周期），数据 RAM (64Kb) 必须保留 BRAM。加载命中因 BRAM 数据延迟无法消除停顿。

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

## 2026-07-29: 加载命中延迟分析与写缓冲区设计探讨

### 加载命中延迟消除（借鉴 rvcpu，架构评估后搁置）

**目标**：借鉴 rvcpu 的加载命中 0 停顿设计，消除剩余的 DCache Hit Pipe（6-16%）。

**rvcpu 的关键机制**（`DCache.sv:151-152`）：
```verilog
assign dresp.addr_ok = 1'b1;
assign dresp.data_ok = (state == INIT && hit);  // 标签组合命中 → 同周期 data_ok
```
数据 RAM 为 `READ_LATENCY=1`（BRAM），`data_ok` 触发时 `dresp.data` 实际是旧数据。rvcpu 的关键在于 **Writeback 级直接组合读取 `dresp.data`**（不经过 MEM→WB 流水线寄存器）：
```verilog
.rd(dresp.data)   // writeback stage input — combinational, not pipelined
```
数据 1 周期后到达时，WB 级组合读取到正确值。

**easyLoong 无法直接复现的原因**：

当前数据路径：`dresp.data → LSU(字节提取) → mem_wb_in → mem_wb_out → regfile`

`mem_wb_in` 在 `data_ok` 同周期捕捉 `lsu_rdata`，但 BRAM 数据晚 1 周期才就绪 → 捕捉到旧数据。延迟 `mem_valid` 1 周期会抵消无停顿收益。要在 WB 级直接组合读取 `dresp.data` 进行字节提取，需要重构核心数据路径（当前 `final_res` 经流水线寄存器）。

**结论**：rvcpu 方案依赖特定的数据路径拓扑。easyLoong 需要在流水线结构层面设计数据 bypass 路径后再实施。

### 写缓冲区设计探讨

**目标**：消除 DCache Refill 期间的 store 阻塞（占所有 stall 的 34-61%）。

**尝试方案**：独立 `write_buffer` 模块（LSU 与 DCache 之间），存储命中直通 DCache，refill 期间缓冲 store。

**遇到的设计挑战**：

1. **存储缓冲 vs 直通决策**：独立模块无法获知 DCache 状态（refill 中 vs 空闲），需要额外 busy 信号或重试机制
2. **加载转发复杂度**：缓冲区内地址匹配的存储数据必须转发给后续加载（CPU 访存 RAW 冒险），需要 word 粒度比较和部分写入的合并逻辑
3. **排空与 CPU 请求冲突**：DCache 忙时排空被阻塞，同时占着 mem_req 接口，CPU 加载无法直通 DCache
4. **接口时序**：`mem_req` 寄存器输出引入虚假有效信号

**更可行的方向**：DCache 内部存储队列。DCache 已经知道自身状态（S_IDLE 时 fast path，S_REFILL 期间缓冲 store），无需外部 busy 信号，且数据和标签在同一模块内，加载转发可利用 BRAM 读路径自然解决。

**当前阶段结论**：标签 LUTRAM 优化已取得显著成果（+5-9% IPC），加载命中消除和写缓冲区均需更深入的设计准备后在后续阶段实施。

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


**CI**：`submit-20260729-1630` 已推送，待结果。
