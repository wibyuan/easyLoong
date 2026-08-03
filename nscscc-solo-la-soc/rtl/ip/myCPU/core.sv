`include "common.sv"

module core import la32_common::*; #(
    parameter int ICACHE_SETS = 256,
    parameter int DCACHE_SETS = 256,
    parameter int DCACHE_WAYS = 2,
    parameter int DCACHE_WORDS = 4,
    // L1 dcache geometry (the WB stage re-extracts the 0-cycle load hit
    // data from the L1's full data port).
    parameter int L1CACHE_WAYS = 2,
    parameter int L1CACHE_WORDS = 4
)(
    input  logic       clk,
    input  logic       reset,
    output ibus_req_t  ireq,
    input  ibus_resp_t iresp,
    output dbus_req_t  dreq,
    input  dbus_resp_t dresp,
    // Full L1 data port: the WB stage selects the line/word for a
    // 0-cycle load hit with the registered context (mem_hit_way +
    // mem_addr word bits), since dresp.data reflects the current request.
    input  logic [31:0] dcache_data_wb [0:L1CACHE_WAYS-1][0:L1CACHE_WORDS-1],
    output cacop_req_t cacop_req,
    input  logic       cacop_done,
    input  logic       dcache_in_refill,
    input  logic       icache_in_refill,
    output logic [31:0] debug_wb_pc,
    output logic [31:0] debug_wb_inst,
    output logic        debug_wb_rf_wen,
    output logic [4:0]  debug_wb_rf_wnum,
    output logic [31:0] debug_wb_rf_wdata,
    output logic [63:0] stall_dcache_refill,
    output logic [63:0] stall_icache_refill,
    output logic [63:0] stall_load_use,
    output logic [63:0] stall_branch_flush,
    output logic [63:0] stall_dcache_hit_pipe,
    output logic [63:0] stall_icache_hit_pipe,
    output logic [63:0] stall_other,
    // Other-bubble breakdown: fetch-empty / single-issue / dual-issue-fill
    // / non-empty-no-advance (diagnostic counters).
    output logic [63:0] stall_other_fetch,
    output logic [63:0] stall_other_single,
    output logic [63:0] stall_other_dual,
    output logic [63:0] stall_other_noissue
);

    typedef struct packed {
        logic valid;
    } if_id_ctrl_t;
    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] instr;
    } if_id_data_t;
    typedef struct packed {
        if_id_ctrl_t ctrl;
        if_id_data_t data;
    } if_id_t;

    typedef struct packed {
        logic      valid;
        logic      rf_we;
        logic      mem_re;
        logic      mem_we;
        logic      is_branch;
        logic      is_cond_branch;
        logic      predict_taken;
        logic      is_jal;
        logic      is_jalr;
        logic      is_pcadd;
        logic      is_cpucfg;
        logic      is_csrrd;
        logic      is_csrwr;
        logic      is_csrxchg;
        logic      is_cacop;
        logic      is_ibar;
    } id_ex_ctrl_t;
    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] instr;
        logic [4:0]  rs1, rs2, rd;
        logic [31:0] imm;
        logic [31:0] target_pc;
        logic [31:0] pc_plus_4;
        // Forward flags computed at ID against the EX/MEM producers:
        //   fw_*_ex0/ex1 : 1-back producers in the EX slots this cycle
        //   fw_*_mem0/mem1 : 2-back producers in the MEM slots this cycle
        // The EX stage resolves them against the (then-current) MEM/WB
        // slots; slot1 additionally bypasses slot0's combinational ALU
        // result for the in-slot RAW (same-cycle issue pair).
        logic        fw_a_ex0, fw_a_ex1, fw_a_mem0, fw_a_mem1;
        logic        fw_b_ex0, fw_b_ex1, fw_b_mem0, fw_b_mem1;
        alu_op_t     alu_op;
        br_type_t    br_type;
        logic        alu_src_sel;
        msize_t      mem_size;
        logic        mem_unsigned;
    } id_ex_data_t;
    typedef struct packed {
        id_ex_ctrl_t ctrl;
        id_ex_data_t data;
    } id_ex_t;

    typedef struct packed {
        logic      valid;
        logic      rf_we;
        logic      mem_re;
        logic      mem_we;
        logic      is_cond_branch;
        logic      is_csrwr;
        logic      is_csrxchg;
    } ex_mem_ctrl_t;
    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] instr;
        logic [4:0]  rd;
        logic [31:0] alu_res;
        logic [31:0] rs2_val;
        logic [31:0] mem_addr;
        msize_t      mem_size;
        logic        mem_unsigned;
        logic        mem_cacheable;
        logic [31:0] csr_wdata;
    } ex_mem_data_t;
    typedef struct packed {
        ex_mem_ctrl_t ctrl;
        ex_mem_data_t data;
    } ex_mem_t;

    typedef struct packed {
        logic      valid;
        logic      rf_we;
        logic      mem_re;
        logic      mem_we;
        logic      is_cond_branch;
        logic      is_csrwr;
        logic      is_csrxchg;
        // rvcpu-style 0-cycle load hit: data_ok fires in the request cycle
        // while the data completes on the cache's registered read port one
        // cycle later.  mem_hit marks such loads — the WB stage re-extracts
        // the full data port (dcache_data_wb) with the registered
        // size/unsigned/address/way instead of using the value captured at
        // MEM (which is stale for these hits).
        logic      mem_hit;
        logic      mem_hit_way;
        msize_t    mem_size;
        logic      mem_unsigned;
    } mem_wb_ctrl_t;
    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] instr;
        logic [4:0]  rd;
        logic [31:0] final_res;
        logic [31:0] mem_addr;
        logic [31:0] csr_wdata;
    } mem_wb_data_t;
    typedef struct packed {
        mem_wb_ctrl_t ctrl;
        mem_wb_data_t data;
    } mem_wb_t;

    logic [31:0] pc, next_pc_reg;
    if_id_t  if_id_out;
    if_id_t  if_id1_out;
    id_ex_t  id_ex0_in,  id_ex0_out;
    id_ex_t  id_ex1_in,  id_ex1_out;
    ex_mem_t ex_mem0_in, ex_mem0_out;
    ex_mem_t ex_mem1_in, ex_mem1_out;
    mem_wb_t mem_wb0_in, mem_wb0_out;
    mem_wb_t mem_wb1_in, mem_wb1_out;

    logic pc_stall, if_id_stall, id_ex_stall, ex_mem_stall;
    logic if_id_flush, id_ex_flush, ex_jump_flush;
    logic [31:0] ex_jump_pc, id_jump_pc;
    logic id_jump_req;
    logic ex_stage_busy;
    logic ex_jump_flush_hazard;

    // ==================== FETCH QUEUE (2-wide) ====================
    // 3-entry shift queue between fetch and ID.  ID reads the queue head
    // (slot0 = entry 0, slot1 = entry 1); slot1 is gated by the issue
    // constraints.  Depth 3 absorbs the "produce 2 / consume 1" skew of a
    // held slot1 without ever losing an instruction; when the queue is
    // full the fetch is held.
    localparam int FQ_DEPTH = 3;
    logic [FQ_DEPTH-1:0]   fq_valid;
    logic [31:0] fq_pc [0:FQ_DEPTH-1];
    logic [31:0] fq_instr [0:FQ_DEPTH-1];

    logic fetch_valid0, fetch_valid1;
    logic [31:0] fetch_pc0, fetch_instr0, fetch_pc1, fetch_instr1;
    logic fetch_absorb2;
    logic slot1_issue;
    logic fq_stall_all;
    logic pipeline_stall;

    // ==================== FETCH ====================
    logic do_ex_flush;
    assign do_ex_flush = ex_jump_flush && !ex_mem_stall;

    logic bp_do_jump;
    logic [31:0] bp_jump_pc;
    assign ex_jump_flush_hazard = ex_jump_flush && !id_ex0_out.ctrl.is_jal;

    fetch_unit if_stage (
        .clk, .reset,
        .pc_stall(pc_stall_fetch), .pc_current(pc),
        .wb_jump_req(1'b0), .wb_jump_pc(32'd0),
        .do_ex_flush(do_ex_flush), .ex_jump_pc,
        .do_id_jump(id_jump_req && !id_ex_stall), .id_jump_pc,
        .bp_do_jump(bp_do_jump), .bp_jump_pc(bp_jump_pc),
        .ireq, .iresp,
        .fetch_absorb2(fetch_absorb2),
        .next_pc(next_pc_reg),
        .if_pc_valid(),
        .if_valid0(fetch_valid0), .if_pc0(fetch_pc0), .if_instr0(fetch_instr0),
        .if_valid1(fetch_valid1), .if_pc1(fetch_pc1), .if_instr1(fetch_instr1)
    );

    logic [63:0] cyc;
    always_ff @(posedge clk) begin
        if (reset) begin
            pc <= PCINIT;
            cyc <= 0;
        end else begin
            pc <= next_pc_reg;
            cyc <= cyc + 1;
        end
    end

    // Queue-head aliases for the ID stage (slot0 = entry 0, slot1 = entry 1).
    assign if_id_out.ctrl.valid = fq_valid[0];
    assign if_id_out.data.pc    = fq_pc[0];
    assign if_id_out.data.instr = fq_instr[0];
    assign if_id1_out.ctrl.valid = fq_valid[1];
    assign if_id1_out.data.pc    = fq_pc[1];
    assign if_id1_out.data.instr = fq_instr[1];

    // Queue consumption: c0 = slot0 issues, c1 = slot1 issues.  The queue
    // holds on pipeline_stall/load_use and also while the fetch is not
    // ready: the legacy single-issue semantics kill the ID->EX entry with
    // id_ex_flush when if_not_ready fires, so issuing into id_ex during a
    // fetch stall would lose the instruction (the ID must not advance).
    assign fq_stall_all = pipeline_stall || load_use_hazard || !iresp.data_ok;
    wire c0 = fq_valid[0] && !fq_stall_all && !if_id_flush;
    wire c1 = fq_valid[1] && slot1_issue && !fq_stall_all && !if_id_flush;

    // Free slots after consumption, and how many fetch outputs are taken.
    wire [2:0] rem_cnt = {1'b0, fq_valid[0] && !c0}
                       + {1'b0, fq_valid[1] && !c1}
                       + {2'b0, fq_valid[2]};
    wire [2:0] fq_space = 3'd3 - rem_cnt;
    wire f0_ok = fetch_valid0 && (fq_space >= 3'd1);
    // fetch_absorb2 gates both the fetch advance (+8) and the f1
    // absorption; when it is off the fetch advances +4 and re-fetches the
    // second word, so only f0 is taken (single-issue behavior).
    assign fetch_absorb2 = fetch_valid1 && (fq_space >= 3'd2);
    wire f1_ok = fetch_absorb2;

    // Queue advance: remaining entries first, then absorbed fetch outputs.
    // When slot0 issues as a predicted-taken branch (bp_do_jump), the queue
    // tail behind it is wrong-path: the legacy if_id_flush is suppressed
    // while load_use holds the branch (Bug 7) or after the fetch already
    // redirected (pc == bp target), so the tail must be discarded here —
    // the single-issue IF/ID register overwrote it, the queue accumulates.
    logic [FQ_DEPTH-1:0]   nfq_valid;
    logic [31:0] nfq_pc [0:FQ_DEPTH-1];
    logic [31:0] nfq_instr [0:FQ_DEPTH-1];
    wire fq_kill_slot1 = c0 && bp_do_jump;
    always_comb begin
        automatic int rc = 0;
        for (int i = 0; i < FQ_DEPTH; i++) begin
            nfq_valid[i] = 1'b0;
            nfq_pc[i]    = 32'd0;
            nfq_instr[i] = 32'd0;
        end
        if (fq_valid[0] && !c0) begin
            nfq_valid[rc] = 1'b1; nfq_pc[rc] = fq_pc[0]; nfq_instr[rc] = fq_instr[0]; rc++;
        end
        if (fq_valid[1] && !c1 && !fq_kill_slot1) begin
            nfq_valid[rc] = 1'b1; nfq_pc[rc] = fq_pc[1]; nfq_instr[rc] = fq_instr[1]; rc++;
        end
        if (fq_valid[2] && !fq_kill_slot1) begin
            nfq_valid[rc] = 1'b1; nfq_pc[rc] = fq_pc[2]; nfq_instr[rc] = fq_instr[2]; rc++;
        end
        if (f0_ok) begin
            nfq_valid[rc] = 1'b1; nfq_pc[rc] = fetch_pc0; nfq_instr[rc] = fetch_instr0; rc++;
        end
        if (f1_ok) begin
            nfq_valid[rc] = 1'b1; nfq_pc[rc] = fetch_pc1; nfq_instr[rc] = fetch_instr1;
        end
    end

    always_ff @(posedge clk) begin
        if (reset || if_id_flush) begin
            fq_valid <= 3'd0;
        end else if (!fq_stall_all) begin
            fq_valid  <= nfq_valid;
            fq_pc[0]  <= nfq_pc[0];    fq_pc[1]  <= nfq_pc[1];    fq_pc[2]  <= nfq_pc[2];
            fq_instr[0] <= nfq_instr[0]; fq_instr[1] <= nfq_instr[1]; fq_instr[2] <= nfq_instr[2];
        end
    end

    // ==================== DECODE (dual slot) ====================
    logic [4:0]  dec_rs1_0, dec_rs2_0, dec_rd_0;
    logic [4:0]  dec_rs1_1, dec_rs2_1, dec_rd_1;
    logic        dec_rf_we_0, dec_alu_src_sel_0;
    logic        dec_rf_we_1, dec_alu_src_sel_1;
    logic        dec_mem_re_0, dec_mem_we_0, dec_mem_unsigned_0;
    logic        dec_mem_re_1, dec_mem_we_1, dec_mem_unsigned_1;
    logic        dec_is_branch_0, dec_is_jal_0, dec_is_jalr_0;
    logic        dec_is_branch_1, dec_is_jal_1, dec_is_jalr_1;
    logic        dec_is_pcadd_0, dec_is_cpucfg_0;
    logic        dec_is_pcadd_1, dec_is_cpucfg_1;
    logic        dec_is_csrrd_0, dec_is_csrwr_0, dec_is_csrxchg_0;
    logic        dec_is_csrrd_1, dec_is_csrwr_1, dec_is_csrxchg_1;
    logic        dec_is_cacop_0, dec_is_ibar_0;
    logic        dec_is_cacop_1, dec_is_ibar_1;
    logic [31:0] dec_imm_0, dec_imm_1;
    alu_op_t     dec_alu_op_0, dec_alu_op_1;
    br_type_t    dec_br_type_0, dec_br_type_1;
    msize_t      dec_mem_size_0, dec_mem_size_1;

    decode dec_unit0 (
        .instr(if_id_out.data.instr),
        .rs1(dec_rs1_0), .rs2(dec_rs2_0), .rd(dec_rd_0),
        .rf_we(dec_rf_we_0), .imm(dec_imm_0),
        .alu_op(dec_alu_op_0), .alu_src_sel(dec_alu_src_sel_0),
        .is_word_op(),
        .mem_we(dec_mem_we_0), .mem_re(dec_mem_re_0),
        .mem_size(dec_mem_size_0), .mem_unsigned(dec_mem_unsigned_0),
        .is_branch(dec_is_branch_0), .is_jal(dec_is_jal_0), .is_jalr(dec_is_jalr_0),
        .br_type(dec_br_type_0),
        .is_pcadd(dec_is_pcadd_0),
        .is_cpucfg(dec_is_cpucfg_0),
        .is_csrrd(dec_is_csrrd_0),
        .is_csrwr(dec_is_csrwr_0),
        .is_csrxchg(dec_is_csrxchg_0),
        .is_cacop(dec_is_cacop_0),
        .is_ibar(dec_is_ibar_0),
        .is_illegal()
    );
    decode dec_unit1 (
        .instr(if_id1_out.data.instr),
        .rs1(dec_rs1_1), .rs2(dec_rs2_1), .rd(dec_rd_1),
        .rf_we(dec_rf_we_1), .imm(dec_imm_1),
        .alu_op(dec_alu_op_1), .alu_src_sel(dec_alu_src_sel_1),
        .is_word_op(),
        .mem_we(dec_mem_we_1), .mem_re(dec_mem_re_1),
        .mem_size(dec_mem_size_1), .mem_unsigned(dec_mem_unsigned_1),
        .is_branch(dec_is_branch_1), .is_jal(dec_is_jal_1), .is_jalr(dec_is_jalr_1),
        .br_type(dec_br_type_1),
        .is_pcadd(dec_is_pcadd_1),
        .is_cpucfg(dec_is_cpucfg_1),
        .is_csrrd(dec_is_csrrd_1),
        .is_csrwr(dec_is_csrwr_1),
        .is_csrxchg(dec_is_csrxchg_1),
        .is_cacop(dec_is_cacop_1),
        .is_ibar(dec_is_ibar_1),
        .is_illegal()
    );

    logic id_valid0, id_valid1;
    assign id_valid0 = if_id_out.ctrl.valid;
    assign id_valid1 = if_id1_out.ctrl.valid;

    // ----- Issue constraints for slot1 -----
    // Complex instructions (mul/cacop/ibar/csr*/cpucfg) execute in slot0
    // only and are exclusive: slot1 is empty when slot0 is complex.
    // EX0 carries the full function (CSR/JAL/pcadd/cpucfg non-ALU paths);
    // EX1 is a pure ALU/address unit, so every non-ALU-producing
    // instruction must stay in slot0.
    wire slot0_complex = id_valid0 &&
        ((id_valid0 && dec_alu_op_0 == ALU_MUL) || dec_is_cacop_0 || dec_is_ibar_0 ||
         dec_is_csrrd_0 || dec_is_csrwr_0 || dec_is_csrxchg_0 || dec_is_cpucfg_0 ||
         dec_is_pcadd_0);
    wire slot1_complex = id_valid1 &&
        ((id_valid1 && dec_alu_op_1 == ALU_MUL) || dec_is_cacop_1 || dec_is_ibar_1 ||
         dec_is_csrrd_1 || dec_is_csrwr_1 || dec_is_csrxchg_1 || dec_is_cpucfg_1 ||
         dec_is_pcadd_1);
    wire slot0_mem = id_valid0 && (dec_mem_re_0 || dec_mem_we_0);
    wire slot1_mem = id_valid1 && (dec_mem_re_1 || dec_mem_we_1);
    // A branch/jump in slot0: unconditional jumps (B/JAL/JALR) and
    // predicted-taken conditional branches are exclusive — slot1 is the
    // fall-through, a wrong path the redirect must not have executed.
    // A predicted-not-taken conditional branch lets slot1 issue: the
    // fall-through IS the predicted path; a mispredict is handled by the
    // EX flush (id_ex_flush kills both slots, the queue is discarded,
    // and the fall-through's EX->MEM transfer is suppressed below).
    wire slot0_branch = id_valid0 &&
        ((dec_is_branch_0 && dec_br_type_0 == BR_NONE) || dec_is_jal_0 || dec_is_jalr_0 ||
         (dec_is_branch_0 && dec_br_type_0 != BR_NONE && id_predict_taken));
    wire slot1_branch = id_valid1 && (dec_is_branch_1 || dec_is_jal_1 || dec_is_jalr_1);
    logic slot1_issue_raw;
    // slot1 reading slot0's load result: the data is not available at EX
    // (the load completes at MEM), so hold slot1.
    wire slot0_load = id_valid0 && dec_mem_re_0;
    wire slot1_dep_load0 = slot0_load && (dec_rd_0 != 5'd0) &&
        ((dec_rs1_1 == dec_rd_0) || (dec_rs2_1 == dec_rd_0));
    // A slot1 instruction whose operand is slot0's same-cycle ALU result
    // is denied: the in-slot bypass now delivers the REGISTERED ALU0
    // result (which breaks the serial adder static path), so the pair's
    // value would be stale — slot1 waits one cycle and uses the em0/mw0
    // forwards.  The store-data dependency (rs2 of a store) does NOT
    // serialize (the data path bypasses ALU1) and stays allowed; a load's
    // decoded rs2 is the imm's top bits and never a real dependency.
    wire slot0_alu_prod = id_valid0 && dec_rf_we_0 && !dec_mem_re_0 && !dec_mem_we_0;
    wire slot1_dep_alu0 = slot0_alu_prod && (dec_rd_0 != 5'd0) &&
        ((dec_rs1_1 == dec_rd_0) ||
         (dec_rs2_1 == dec_rd_0 && (dec_mem_we_1 || !dec_mem_re_1)));

    assign slot1_issue_raw = id_valid1 && !slot0_complex && !slot1_complex
        && !slot0_branch && !slot1_branch
        && !(slot0_mem && slot1_mem)
        && !slot1_dep_load0 && !slot1_dep_alu0;
    // The slot1 slot issues when the queue head pair accepts.
    assign slot1_issue = slot1_issue_raw && !fq_stall_all && !if_id_flush;

    // Diagnostic: why slot1 was held (slot1_issue_raw = 0 with a valid
    // slot1).  Priority order matches the raw expression.
    logic [63:0] s1_hold_s0complex, s1_hold_s1complex, s1_hold_s0branch;
    logic [63:0] s1_hold_s1branch, s1_hold_mem, s1_hold_dep0, s1_hold_other;
    always_ff @(posedge clk) begin
        if (reset) begin
            s1_hold_s0complex <= 64'd0;
            s1_hold_s1complex <= 64'd0;
            s1_hold_s0branch  <= 64'd0;
            s1_hold_s1branch  <= 64'd0;
            s1_hold_mem       <= 64'd0;
            s1_hold_dep0      <= 64'd0;
            s1_hold_other     <= 64'd0;
        end else if (id_valid1 && !slot1_issue_raw) begin
            if (slot0_complex)      s1_hold_s0complex <= s1_hold_s0complex + 64'd1;
            else if (slot1_complex) s1_hold_s1complex <= s1_hold_s1complex + 64'd1;
            else if (slot0_branch)  s1_hold_s0branch  <= s1_hold_s0branch  + 64'd1;
            else if (slot1_branch)  s1_hold_s1branch  <= s1_hold_s1branch  + 64'd1;
            else if (slot0_mem && slot1_mem)
                                    s1_hold_mem       <= s1_hold_mem       + 64'd1;
            else if (slot1_dep_load0)
                                    s1_hold_dep0      <= s1_hold_dep0      + 64'd1;
            else                    s1_hold_other     <= s1_hold_other     + 64'd1;
        end
    end

    // ----- JAL/BL redirect (slot0 only) -----
    assign id_jump_req = dec_is_jal_0 && id_valid0;
    assign id_jump_pc  = if_id_out.data.pc + dec_imm_0;

    logic id_predict_taken;
    branch_predictor bp_unit (
        .clk, .reset,
        .id_pc(if_id_out.data.pc),
        .id_imm(dec_imm_0),
        .id_br_type(dec_br_type_0),
        .id_is_cond_branch(dec_is_branch_0 & id_valid0 & (dec_br_type_0 != BR_NONE)),
        .id_valid(if_id_out.ctrl.valid),
        .id_stall(id_ex_stall),
        .ex_br_taken(br_taken_0),
        .ex_valid(id_ex0_out.ctrl.valid),
        .ex_predict_taken(id_ex0_out.ctrl.predict_taken),
        .predict_taken(id_predict_taken),
        .bp_redirect(bp_do_jump),
        .bp_target(bp_jump_pc),
        .bp_mispredict(),
        .bp_correct_pc()
    );

    // ----- Register file: 4R2W, slot0 = write port 1, slot1 = port 2 -----
    logic [31:0] gpr_state [31:0];
    logic [31:0] rf_rd1_0, rf_rd2_0, rf_rd1_1, rf_rd2_1;
    regfile rf_unit (
        .clk,
        .ra1(id_ex0_out.data.rs1), .ra2(id_ex0_out.data.rs2),
        .ra3(id_ex1_out.data.rs1), .ra4(id_ex1_out.data.rs2),
        .rd1(rf_rd1_0), .rd2(rf_rd2_0), .rd3(rf_rd1_1), .rd4(rf_rd2_1),
        .wa1(mem_wb0_out.data.rd), .wd1(wb_final_res0),
        .wen1(mem_wb0_out.ctrl.rf_we && mem_wb0_out.ctrl.valid),
        .wa2(mem_wb1_out.data.rd), .wd2(wb_final_res1),
        .wen2(mem_wb1_out.ctrl.rf_we && mem_wb1_out.ctrl.valid),
        .gpr_dbg(gpr_state)
    );

    // ----- ID -> EX (slot0) -----
    // The ID stage must not re-issue the instruction held in the queue
    // while the queue is held: with fq_stall_all=1 the head keeps its
    // content and the ID would decode the SAME instruction again after
    // id_ex_stall released — the instruction executes twice. Only issue to
    // EX when the queue actually advances — i.e. when it is not held, or
    // when it is being flushed (a redirect discards the queue; the
    // JAL/branch must still be issued so it is not lost entirely).
    assign id_ex0_in.ctrl.valid      = id_valid0 && !(fq_stall_all && !if_id_flush);
    assign id_ex0_in.ctrl.rf_we      = dec_rf_we_0 & id_ex0_in.ctrl.valid;
    assign id_ex0_in.ctrl.mem_re     = dec_mem_re_0 & id_ex0_in.ctrl.valid;
    assign id_ex0_in.ctrl.mem_we     = dec_mem_we_0 & id_ex0_in.ctrl.valid;
    assign id_ex0_in.ctrl.is_branch  = dec_is_branch_0 & id_ex0_in.ctrl.valid;
    assign id_ex0_in.ctrl.is_cond_branch = (dec_is_branch_0 & id_ex0_in.ctrl.valid) && (dec_br_type_0 != BR_NONE);
    assign id_ex0_in.ctrl.predict_taken  = id_predict_taken & id_ex0_in.ctrl.valid;
    assign id_ex0_in.ctrl.is_jal     = dec_is_jal_0 & id_ex0_in.ctrl.valid;
    assign id_ex0_in.ctrl.is_jalr    = dec_is_jalr_0 & id_ex0_in.ctrl.valid;
    assign id_ex0_in.ctrl.is_pcadd   = dec_is_pcadd_0 & id_ex0_in.ctrl.valid;
    assign id_ex0_in.ctrl.is_cpucfg  = dec_is_cpucfg_0 & id_ex0_in.ctrl.valid;
    assign id_ex0_in.ctrl.is_csrrd   = dec_is_csrrd_0 & id_ex0_in.ctrl.valid;
    assign id_ex0_in.ctrl.is_csrwr   = dec_is_csrwr_0 & id_ex0_in.ctrl.valid;
    assign id_ex0_in.ctrl.is_csrxchg = dec_is_csrxchg_0 & id_ex0_in.ctrl.valid;
    assign id_ex0_in.ctrl.is_cacop   = dec_is_cacop_0 & id_ex0_in.ctrl.valid;
    assign id_ex0_in.ctrl.is_ibar    = dec_is_ibar_0  & id_ex0_in.ctrl.valid;

    assign id_ex0_in.data.fw_a_ex0   = (dec_rs1_0 != 5'd0) && (dec_rs1_0 == id_ex0_out.data.rd);
    assign id_ex0_in.data.fw_a_ex1   = (dec_rs1_0 != 5'd0) && (dec_rs1_0 == id_ex1_out.data.rd);
    assign id_ex0_in.data.fw_a_mem0  = (dec_rs1_0 != 5'd0) && (dec_rs1_0 == ex_mem0_out.data.rd);
    assign id_ex0_in.data.fw_a_mem1  = (dec_rs1_0 != 5'd0) && (dec_rs1_0 == ex_mem1_out.data.rd);
    assign id_ex0_in.data.fw_b_ex0   = (dec_rs2_0 != 5'd0) && (dec_rs2_0 == id_ex0_out.data.rd);
    assign id_ex0_in.data.fw_b_ex1   = (dec_rs2_0 != 5'd0) && (dec_rs2_0 == id_ex1_out.data.rd);
    assign id_ex0_in.data.fw_b_mem0  = (dec_rs2_0 != 5'd0) && (dec_rs2_0 == ex_mem0_out.data.rd);
    assign id_ex0_in.data.fw_b_mem1  = (dec_rs2_0 != 5'd0) && (dec_rs2_0 == ex_mem1_out.data.rd);

    assign id_ex0_in.data.pc         = if_id_out.data.pc;
    assign id_ex0_in.data.instr      = if_id_out.data.instr;
    assign id_ex0_in.data.rs1        = dec_rs1_0;
    assign id_ex0_in.data.rs2        = dec_rs2_0;
    assign id_ex0_in.data.rd         = dec_rd_0;
    assign id_ex0_in.data.imm        = dec_imm_0;
    assign id_ex0_in.data.target_pc  = if_id_out.data.pc + dec_imm_0;
    assign id_ex0_in.data.pc_plus_4  = if_id_out.data.pc + 32'd4;
    assign id_ex0_in.data.alu_op     = dec_alu_op_0;
    assign id_ex0_in.data.br_type    = dec_br_type_0;
    assign id_ex0_in.data.alu_src_sel = dec_alu_src_sel_0;
    assign id_ex0_in.data.mem_size   = dec_mem_size_0;
    assign id_ex0_in.data.mem_unsigned = dec_mem_unsigned_0;

    // ----- ID -> EX (slot1, gated by slot1_issue) -----
    assign id_ex1_in.ctrl.valid      = slot1_issue;
    assign id_ex1_in.ctrl.rf_we      = dec_rf_we_1 & slot1_issue;
    assign id_ex1_in.ctrl.mem_re     = dec_mem_re_1 & slot1_issue;
    assign id_ex1_in.ctrl.mem_we     = dec_mem_we_1 & slot1_issue;
    assign id_ex1_in.ctrl.is_branch  = dec_is_branch_1 & slot1_issue;
    assign id_ex1_in.ctrl.is_cond_branch = (dec_is_branch_1 & slot1_issue) && (dec_br_type_1 != BR_NONE);
    assign id_ex1_in.ctrl.predict_taken  = 1'b0;
    assign id_ex1_in.ctrl.is_jal     = dec_is_jal_1 & slot1_issue;
    assign id_ex1_in.ctrl.is_jalr    = dec_is_jalr_1 & slot1_issue;
    assign id_ex1_in.ctrl.is_pcadd   = dec_is_pcadd_1 & slot1_issue;
    assign id_ex1_in.ctrl.is_cpucfg  = dec_is_cpucfg_1 & slot1_issue;
    assign id_ex1_in.ctrl.is_csrrd   = dec_is_csrrd_1 & slot1_issue;
    assign id_ex1_in.ctrl.is_csrwr   = dec_is_csrwr_1 & slot1_issue;
    assign id_ex1_in.ctrl.is_csrxchg = dec_is_csrxchg_1 & slot1_issue;
    assign id_ex1_in.ctrl.is_cacop   = dec_is_cacop_1 & slot1_issue;
    assign id_ex1_in.ctrl.is_ibar    = dec_is_ibar_1  & slot1_issue;

    // Slot1 forward flags: EX0/EX1 (1-back), MEM0/MEM1 (2-back); the
    // in-slot EX0 bypass (same-cycle issue pair) is resolved combinationally
    // in the EX stage.
    assign id_ex1_in.data.fw_a_ex0   = (dec_rs1_1 != 5'd0) && (dec_rs1_1 == id_ex0_out.data.rd);
    assign id_ex1_in.data.fw_a_ex1   = (dec_rs1_1 != 5'd0) && (dec_rs1_1 == id_ex1_out.data.rd);
    assign id_ex1_in.data.fw_a_mem0  = (dec_rs1_1 != 5'd0) && (dec_rs1_1 == ex_mem0_out.data.rd);
    assign id_ex1_in.data.fw_a_mem1  = (dec_rs1_1 != 5'd0) && (dec_rs1_1 == ex_mem1_out.data.rd);
    assign id_ex1_in.data.fw_b_ex0   = (dec_rs2_1 != 5'd0) && (dec_rs2_1 == id_ex0_out.data.rd);
    assign id_ex1_in.data.fw_b_ex1   = (dec_rs2_1 != 5'd0) && (dec_rs2_1 == id_ex1_out.data.rd);
    assign id_ex1_in.data.fw_b_mem0  = (dec_rs2_1 != 5'd0) && (dec_rs2_1 == ex_mem0_out.data.rd);
    assign id_ex1_in.data.fw_b_mem1  = (dec_rs2_1 != 5'd0) && (dec_rs2_1 == ex_mem1_out.data.rd);

    assign id_ex1_in.data.pc         = if_id1_out.data.pc;
    assign id_ex1_in.data.instr      = if_id1_out.data.instr;
    assign id_ex1_in.data.rs1        = dec_rs1_1;
    assign id_ex1_in.data.rs2        = dec_rs2_1;
    assign id_ex1_in.data.rd         = dec_rd_1;
    assign id_ex1_in.data.imm        = dec_imm_1;
    assign id_ex1_in.data.target_pc  = if_id1_out.data.pc + dec_imm_1;
    assign id_ex1_in.data.pc_plus_4  = if_id1_out.data.pc + 32'd4;
    assign id_ex1_in.data.alu_op     = dec_alu_op_1;
    assign id_ex1_in.data.br_type    = dec_br_type_1;
    assign id_ex1_in.data.alu_src_sel = dec_alu_src_sel_1;
    assign id_ex1_in.data.mem_size   = dec_mem_size_1;
    assign id_ex1_in.data.mem_unsigned = dec_mem_unsigned_1;

    pipeline_reg #($bits(id_ex_ctrl_t)) reg_id_ex0_ctrl (
        .clk, .reset, .stall(id_ex_stall), .flush(id_ex_flush),
        .data_in(id_ex0_in.ctrl), .data_out(id_ex0_out.ctrl)
    );
    pipeline_reg #($bits(id_ex_data_t)) reg_id_ex0_data (
        .clk, .reset, .stall(id_ex_stall), .flush(1'b0),
        .data_in(id_ex0_in.data), .data_out(id_ex0_out.data)
    );
    pipeline_reg #($bits(id_ex_ctrl_t)) reg_id_ex1_ctrl (
        .clk, .reset, .stall(id_ex_stall), .flush(id_ex_flush),
        .data_in(id_ex1_in.ctrl), .data_out(id_ex1_out.ctrl)
    );
    pipeline_reg #($bits(id_ex_data_t)) reg_id_ex1_data (
        .clk, .reset, .stall(id_ex_stall), .flush(1'b0),
        .data_in(id_ex1_in.data), .data_out(id_ex1_out.data)
    );

    // ==================== EXECUTE (dual) ====================
    // Forwarding matrix.  Flags are computed at ID against the EX slots
    // (1-back producers) and the MEM slots (2-back producers); the EX
    // stage resolves them against the then-current MEM/WB slots:
    //   fw_*_em0/em1 : 1-back, producer now in MEM (ex_mem0/ex_mem1)
    //   fw_*_mw0/mw1 : 2-back, producer now in WB (wb_final_res0/1)
    // Priority: slot1 (newer) > slot0 for both depths.  Slot1 also
    // bypasses slot0's combinational result for the same-cycle pair.
    logic [31:0] forward_a0, forward_b0, forward_a1, forward_b1;
    logic [31:0] alu_res0, alu_res1;
    logic [31:0] ex0_result;      // ALU or non-ALU (CSR/JAL/pcadd/cpucfg)
    logic fw_a0_em0, fw_a0_em1, fw_a0_mw0, fw_a0_mw1;
    logic fw_b0_em0, fw_b0_em1, fw_b0_mw0, fw_b0_mw1;
    logic fw_a1_em0, fw_a1_em1, fw_a1_mw0, fw_a1_mw1;
    logic fw_b1_em0, fw_b1_em1, fw_b1_mw0, fw_b1_mw1;

    assign fw_a0_em0 = id_ex0_out.data.fw_a_ex0 && ex_mem0_out.ctrl.rf_we && ex_mem0_out.ctrl.valid && !ex_mem0_out.ctrl.mem_re;
    assign fw_a0_em1 = id_ex0_out.data.fw_a_ex1 && ex_mem1_out.ctrl.rf_we && ex_mem1_out.ctrl.valid && !ex_mem1_out.ctrl.mem_re;
    assign fw_a0_mw0 = id_ex0_out.data.fw_a_mem0 && mem_wb0_out.ctrl.rf_we && mem_wb0_out.ctrl.valid;
    assign fw_a0_mw1 = id_ex0_out.data.fw_a_mem1 && mem_wb1_out.ctrl.rf_we && mem_wb1_out.ctrl.valid;
    assign fw_b0_em0 = id_ex0_out.data.fw_b_ex0 && ex_mem0_out.ctrl.rf_we && ex_mem0_out.ctrl.valid && !ex_mem0_out.ctrl.mem_re;
    assign fw_b0_em1 = id_ex0_out.data.fw_b_ex1 && ex_mem1_out.ctrl.rf_we && ex_mem1_out.ctrl.valid && !ex_mem1_out.ctrl.mem_re;
    assign fw_b0_mw0 = id_ex0_out.data.fw_b_mem0 && mem_wb0_out.ctrl.rf_we && mem_wb0_out.ctrl.valid;
    assign fw_b0_mw1 = id_ex0_out.data.fw_b_mem1 && mem_wb1_out.ctrl.rf_we && mem_wb1_out.ctrl.valid;

    // In-slot bypass: slot1 reading the same-cycle slot0 producer's ALU
    // result (the issue gate already excludes slot1 depending on slot0's
    // load/mul/branch, so the EX0 result is available).  The bypass value
    // is the REGISTERED ALU0 result: the same-cycle dependent pair is
    // denied at the issue gate (slot1_dep_alu0), so this entry never
    // selects a live value — the register exists to break the serial
    // ALU0->ALU1 static netlist path (timing analysis is static; a
    // combinational mux input keeps the two adders on one path no matter
    // how the select is gated).
    logic [31:0] alu_res0_r;
    always_ff @(posedge clk) begin
        if (reset) alu_res0_r <= 32'd0;
        else alu_res0_r <= alu_res0;
    end
    logic fw_a1_ex0_comb, fw_b1_ex0_comb;
    assign fw_a1_ex0_comb = id_ex1_out.ctrl.valid && id_ex0_out.ctrl.valid &&
        (id_ex1_out.data.rs1 != 5'd0) && (id_ex1_out.data.rs1 == id_ex0_out.data.rd) &&
        id_ex0_out.ctrl.rf_we && !id_ex0_out.ctrl.mem_re && !mul_in_progress;
    assign fw_b1_ex0_comb = id_ex1_out.ctrl.valid && id_ex0_out.ctrl.valid &&
        (id_ex1_out.data.rs2 != 5'd0) && (id_ex1_out.data.rs2 == id_ex0_out.data.rd) &&
        id_ex0_out.ctrl.rf_we && !id_ex0_out.ctrl.mem_re && !mul_in_progress;

    assign fw_a1_em0 = id_ex1_out.data.fw_a_ex0 && ex_mem0_out.ctrl.rf_we && ex_mem0_out.ctrl.valid && !ex_mem0_out.ctrl.mem_re;
    assign fw_a1_em1 = id_ex1_out.data.fw_a_ex1 && ex_mem1_out.ctrl.rf_we && ex_mem1_out.ctrl.valid && !ex_mem1_out.ctrl.mem_re;
    assign fw_a1_mw0 = id_ex1_out.data.fw_a_mem0 && mem_wb0_out.ctrl.rf_we && mem_wb0_out.ctrl.valid;
    assign fw_a1_mw1 = id_ex1_out.data.fw_a_mem1 && mem_wb1_out.ctrl.rf_we && mem_wb1_out.ctrl.valid;
    assign fw_b1_em0 = id_ex1_out.data.fw_b_ex0 && ex_mem0_out.ctrl.rf_we && ex_mem0_out.ctrl.valid && !ex_mem0_out.ctrl.mem_re;
    assign fw_b1_em1 = id_ex1_out.data.fw_b_ex1 && ex_mem1_out.ctrl.rf_we && ex_mem1_out.ctrl.valid && !ex_mem1_out.ctrl.mem_re;
    assign fw_b1_mw0 = id_ex1_out.data.fw_b_mem0 && mem_wb0_out.ctrl.rf_we && mem_wb0_out.ctrl.valid;
    assign fw_b1_mw1 = id_ex1_out.data.fw_b_mem1 && mem_wb1_out.ctrl.rf_we && mem_wb1_out.ctrl.valid;

    always_comb begin
        if (fw_a0_em1)      forward_a0 = ex_mem1_out.data.alu_res;
        else if (fw_a0_em0) forward_a0 = ex_mem0_out.data.alu_res;
        else if (fw_a0_mw1) forward_a0 = wb_final_res1;
        else if (fw_a0_mw0) forward_a0 = wb_final_res0;
        else                forward_a0 = rf_rd1_0;

        if (fw_b0_em1)      forward_b0 = ex_mem1_out.data.alu_res;
        else if (fw_b0_em0) forward_b0 = ex_mem0_out.data.alu_res;
        else if (fw_b0_mw1) forward_b0 = wb_final_res1;
        else if (fw_b0_mw0) forward_b0 = wb_final_res0;
        else                forward_b0 = rf_rd2_0;
    end

    always_comb begin
        if (fw_a1_ex0_comb) forward_a1 = alu_res0_r;
        else if (fw_a1_em1) forward_a1 = ex_mem1_out.data.alu_res;
        else if (fw_a1_em0) forward_a1 = ex_mem0_out.data.alu_res;
        else if (fw_a1_mw1) forward_a1 = wb_final_res1;
        else if (fw_a1_mw0) forward_a1 = wb_final_res0;
        else                forward_a1 = rf_rd1_1;

        if (fw_b1_ex0_comb) forward_b1 = alu_res0_r;
        else if (fw_b1_em1) forward_b1 = ex_mem1_out.data.alu_res;
        else if (fw_b1_em0) forward_b1 = ex_mem0_out.data.alu_res;
        else if (fw_b1_mw1) forward_b1 = wb_final_res1;
        else if (fw_b1_mw0) forward_b1 = wb_final_res0;
        else                forward_b1 = rf_rd2_1;
    end

    // ---- EX0 (full function) ----
    logic [31:0] alu_a0, alu_b0;
    assign alu_a0 = forward_a0;
    assign alu_b0 = id_ex0_out.data.alu_src_sel ? id_ex0_out.data.imm : forward_b0;
    alu alu_unit0 (
        .a(alu_a0), .b(alu_b0),
        .op(id_ex0_out.data.alu_op),
        .res(alu_res0)
    );

    logic br_taken_0;
    bcu bcu_unit0 (
        .rs1_val(forward_a0), .rs2_val(forward_b0),
        .br_type(id_ex0_out.data.br_type), .br_taken(br_taken_0)
    );

    npc npc_unit0 (
        .target_pc(id_ex0_out.data.target_pc),
        .pc_plus_4(id_ex0_out.data.pc_plus_4),
        .rs1_val(forward_a0),
        .imm(id_ex0_out.data.imm),
        .is_branch(id_ex0_out.ctrl.is_branch),
        .is_jal(id_ex0_out.ctrl.is_jal),
        .is_jalr(id_ex0_out.ctrl.is_jalr),
        .is_ibar(id_ex0_out.ctrl.is_ibar),
        .br_taken(br_taken_0),
        .predict_taken(id_ex0_out.ctrl.predict_taken),
        .next_pc(ex_jump_pc),
        .flush_req(ex_jump_flush)
    );

    // ---- MUL (slot0 only, 2 cycles) ----
    logic        mul_in_progress;
    logic        mul_first_cycle;
    logic [31:0] mul_p0_reg;
    logic [15:0] mul_p1l_reg;
    logic [15:0] mul_p2l_reg;
    logic [15:0] mul_hi;
    logic [31:0] mul_result;

    assign mul_first_cycle = id_ex0_out.ctrl.valid &&
        id_ex0_out.data.alu_op == ALU_MUL &&
        !mul_in_progress;

    always_ff @(posedge clk) begin
        if (reset || (ex_jump_flush && !ex_mem_stall))
            mul_in_progress <= 1'b0;
        else if (mul_in_progress)
            mul_in_progress <= 1'b0;
        else if (id_ex0_out.ctrl.valid && id_ex0_out.data.alu_op == ALU_MUL)
            mul_in_progress <= 1'b1;
    end

    always_ff @(posedge clk) begin
        if (mul_first_cycle) begin
            mul_p0_reg  <= forward_a0[15:0] * forward_b0[15:0];
            mul_p1l_reg <= forward_a0[15:0] * forward_b0[31:16];
            mul_p2l_reg <= forward_a0[31:16] * forward_b0[15:0];
        end
    end

    assign mul_hi     = mul_p0_reg[31:16] + mul_p1l_reg + mul_p2l_reg;
    assign mul_result = {mul_hi[15:0], mul_p0_reg[15:0]};
    logic [31:0] ex0_alu_result;
    assign ex0_alu_result = mul_in_progress ? mul_result : alu_res0;

    // ---- CSR (slot0 only) ----
    logic [13:0] csr_num;
    logic [31:0] csr_rdata, csr_wdata;
    logic [31:0] csr_crmd, csr_dmw0, csr_dmw1;
    logic [31:0] csr_prmd, csr_euen, csr_ecfg, csr_estat, csr_era, csr_badv, csr_eentry;
    logic [31:0] csr_tlbidx, csr_tlbehi, csr_tlbelo0, csr_tlbelo1, csr_asid, csr_pgdl, csr_pgdh;
    logic [31:0] csr_save0, csr_save1, csr_save2, csr_save3;
    logic [31:0] csr_tid, csr_tcfg, csr_tval, csr_llbctl, csr_tlbrentry;

    assign csr_num = id_ex0_out.data.instr[23:10];

    logic [13:0] csr_num_r;
    logic [31:0] csr_rdata_r;

    always_ff @(posedge clk) begin
        if (reset) csr_num_r <= 14'd0;
        else csr_num_r <= csr_num;
    end

    always_ff @(posedge clk) begin
        csr_rdata_r <= csr_rdata;
    end

    // CSR writes take effect at the WB retirement point (in-order). The
    // regfile array write happens when the csrwr/csrxchg retires, so the
    // architectural state (and difftest comparison) is always consistent.
    // In-flight write tracking for EX-stage forwarding:
    //   mem_csr_* : write in MEM  (1 instruction older than the EX reader)
    //   wb_csr_*  : write in WB   (2 instructions older)
    //   wb_csr_*_r: write retired last cycle (covers the 1-cycle lag of the
    //               free-running csr_rdata_r read pipeline, 3+ older)
    logic mem_csr_we, wb_csr_we;
    logic [13:0] mem_csr_num, wb_csr_num;
    logic [31:0] mem_csr_wdata, wb_csr_wdata;
    logic        wb_csr_we_r;
    logic [13:0] wb_csr_num_r;
    logic [31:0] wb_csr_wdata_r;

    always_ff @(posedge clk) begin
        wb_csr_we_r    <= wb_csr_we;
        wb_csr_num_r   <= wb_csr_num;
        wb_csr_wdata_r <= wb_csr_wdata;
    end

    logic [31:0] csr_rdata_final;
    always_comb begin
        if (mem_csr_we && mem_csr_num == csr_num)
            csr_rdata_final = mem_csr_wdata;
        else if (wb_csr_we && wb_csr_num == csr_num)
            csr_rdata_final = wb_csr_wdata;
        else if (wb_csr_we_r && wb_csr_num_r == csr_num)
            csr_rdata_final = wb_csr_wdata_r;
        else
            csr_rdata_final = csr_rdata_r;
    end

    csr_regfile csr_rf (
        .clk, .reset,
        .csr_num,
        .csr_rdata,
        .csr_we(wb_csr_we),
        .csr_waddr(wb_csr_num),
        .csr_wdata(wb_csr_wdata),
        .crmd(csr_crmd), .prmd(csr_prmd), .euen(csr_euen),
        .ecfg(csr_ecfg), .estat(csr_estat), .era(csr_era),
        .badv(csr_badv), .eentry(csr_eentry),
        .tlbidx(csr_tlbidx), .tlbehi(csr_tlbehi),
        .tlbelo0(csr_tlbelo0), .tlbelo1(csr_tlbelo1),
        .asid(csr_asid), .pgdl(csr_pgdl), .pgdh(csr_pgdh),
        .save0(csr_save0), .save1(csr_save1), .save2(csr_save2), .save3(csr_save3),
        .tid(csr_tid), .tcfg(csr_tcfg), .tval(csr_tval),
        .llbctl(csr_llbctl), .tlbrentry(csr_tlbrentry),
        .dmw0(csr_dmw0), .dmw1(csr_dmw1)
    );

    always_comb begin
        if (id_ex0_out.ctrl.is_csrwr)
            csr_wdata = forward_a0;
        else if (id_ex0_out.ctrl.is_csrxchg)
            csr_wdata = (csr_rdata_final & ~forward_a0) | (forward_b0 & forward_a0);
        else
            csr_wdata = 32'd0;
    end

    assign mem_csr_we    = ex_mem0_out.ctrl.valid && (ex_mem0_out.ctrl.is_csrwr || ex_mem0_out.ctrl.is_csrxchg);
    assign mem_csr_num   = ex_mem0_out.data.instr[23:10];
    assign mem_csr_wdata = ex_mem0_out.data.csr_wdata;
    assign wb_csr_we     = mem_wb0_out.ctrl.valid && (mem_wb0_out.ctrl.is_csrwr || mem_wb0_out.ctrl.is_csrxchg);
    assign wb_csr_num    = mem_wb0_out.data.instr[23:10];
    assign wb_csr_wdata  = mem_wb0_out.data.csr_wdata;

    logic csr_read_stall;
    assign csr_read_stall = id_ex0_out.ctrl.valid &&
        (id_ex0_out.ctrl.is_csrrd || id_ex0_out.ctrl.is_csrxchg) &&
        (csr_num != csr_num_r);

    logic        is_non_alu0;
    logic [31:0] non_alu_result0;
    assign is_non_alu0 = id_ex0_out.ctrl.is_csrrd || id_ex0_out.ctrl.is_csrwr ||
        id_ex0_out.ctrl.is_csrxchg || id_ex0_out.ctrl.is_jal || id_ex0_out.ctrl.is_jalr ||
        id_ex0_out.ctrl.is_pcadd || id_ex0_out.ctrl.is_cpucfg;

    logic [31:0] cpucfg_result;
    // CPUCFG.0x11/0x12 use the kernel-private encoding
    // (offset_bits[30:24], index_bits[23:16], max_way[15:0]).  The reported
    // geometry MUST match the parameterized cache: the kernel flushes the
    // dcache by walking set << offset_bits, and NEMU mirrors these values
    // via the ICACHE_INDEX_BITS/DCACHE_* build defines, so any geometry
    // change must update both sides in lockstep.
    localparam ICACHE_CFG = (4 << 24) | ($clog2(ICACHE_SETS) << 16) | 1;
    localparam DCACHE_CFG = (($clog2(DCACHE_WORDS) + 2) << 24) |
                            ($clog2(DCACHE_SETS) << 16) |
                            (DCACHE_WAYS - 1);
    always_comb begin
        cpucfg_result = 32'd0;
        case (forward_a0)
            32'd16: cpucfg_result = 32'h00000011; // no D-cache (wip/no-dcache) // no D-cache (wip/no-dcache)
            32'd17: cpucfg_result = ICACHE_CFG;
            32'd18: cpucfg_result = DCACHE_CFG;
            default: cpucfg_result = 32'd0;
        endcase
    end

    always_comb begin
        if (id_ex0_out.ctrl.is_csrrd || id_ex0_out.ctrl.is_csrwr || id_ex0_out.ctrl.is_csrxchg)
            non_alu_result0 = csr_rdata_final;
        else if (id_ex0_out.ctrl.is_jal || id_ex0_out.ctrl.is_jalr)
            non_alu_result0 = id_ex0_out.data.pc_plus_4;
        else if (id_ex0_out.ctrl.is_pcadd)
            non_alu_result0 = id_ex0_out.data.pc + id_ex0_out.data.imm;
        else if (id_ex0_out.ctrl.is_cpucfg)
            non_alu_result0 = cpucfg_result;
        else
            non_alu_result0 = 32'd0;
    end
    assign ex0_result = is_non_alu0 ? non_alu_result0 : ex0_alu_result;

    // ---- CACOP (slot0 only) ----
    logic cacop_not_ready;
    logic cacop_in_ex;
    assign cacop_in_ex = id_ex0_out.ctrl.is_cacop && id_ex0_out.ctrl.valid;
    assign cacop_req.valid = cacop_in_ex;
    assign cacop_req.code  = id_ex0_out.data.instr[4:0];
    assign cacop_req.addr  = ex0_result;
    assign cacop_not_ready = cacop_in_ex && !cacop_done;

    // ---- EX1 (ALU / address only) ----
    logic [31:0] alu_a1, alu_b1;
    assign alu_a1 = forward_a1;
    assign alu_b1 = id_ex1_out.data.alu_src_sel ? id_ex1_out.data.imm : forward_b1;
    alu alu_unit1 (
        .a(alu_a1), .b(alu_b1),
        .op(id_ex1_out.data.alu_op),
        .res(alu_res1)
    );

    // ==================== EX -> MEM (dual) ====================
    logic ex_valid0, ex_valid1;
    assign ex_valid0 = id_ex0_out.ctrl.valid;
    assign ex_valid1 = id_ex1_out.ctrl.valid;

    assign ex_mem0_in.ctrl.valid     = ex_valid0;
    assign ex_mem0_in.ctrl.rf_we     = id_ex0_out.ctrl.rf_we & ex_valid0;
    assign ex_mem0_in.ctrl.mem_re    = id_ex0_out.ctrl.mem_re & ex_valid0;
    assign ex_mem0_in.ctrl.mem_we    = id_ex0_out.ctrl.mem_we & ex_valid0;
    assign ex_mem0_in.ctrl.is_cond_branch = id_ex0_out.ctrl.is_cond_branch & ex_valid0;
    assign ex_mem0_in.ctrl.is_csrwr  = id_ex0_out.ctrl.is_csrwr & ex_valid0;
    assign ex_mem0_in.ctrl.is_csrxchg = id_ex0_out.ctrl.is_csrxchg & ex_valid0;
    assign ex_mem0_in.data.pc        = id_ex0_out.data.pc;
    assign ex_mem0_in.data.instr     = id_ex0_out.data.instr;
    assign ex_mem0_in.data.rd        = id_ex0_out.data.rd;
    assign ex_mem0_in.data.alu_res   = ex0_result;
    assign ex_mem0_in.data.rs2_val   = forward_b0;
    assign ex_mem0_in.data.mem_size  = id_ex0_out.data.mem_size;
    assign ex_mem0_in.data.mem_unsigned = id_ex0_out.data.mem_unsigned;
    assign ex_mem0_in.data.csr_wdata = csr_wdata;

    // A mispredict flush (EX branch redirect) suppresses slot1's EX->MEM
    // transfer: the branch is slot0-only, so a slot1 instruction issued
    // beside it is the fall-through (wrong path) and must not reach MEM
    // — id_ex_flush kills the ID->EX entries but ex_mem would otherwise
    // capture the fall-through's copy and retire it.
    assign ex_mem1_in.ctrl.valid     = ex_valid1 && !(ex_jump_flush && !ex_mem_stall);
    assign ex_mem1_in.ctrl.rf_we     = id_ex1_out.ctrl.rf_we & ex_valid1;
    assign ex_mem1_in.ctrl.mem_re    = id_ex1_out.ctrl.mem_re & ex_valid1;
    assign ex_mem1_in.ctrl.mem_we    = id_ex1_out.ctrl.mem_we & ex_valid1;
    assign ex_mem1_in.ctrl.is_cond_branch = id_ex1_out.ctrl.is_cond_branch & ex_valid1;
    assign ex_mem1_in.ctrl.is_csrwr  = id_ex1_out.ctrl.is_csrwr & ex_valid1;
    assign ex_mem1_in.ctrl.is_csrxchg = id_ex1_out.ctrl.is_csrxchg & ex_valid1;
    assign ex_mem1_in.data.pc        = id_ex1_out.data.pc;
    assign ex_mem1_in.data.instr     = id_ex1_out.data.instr;
    assign ex_mem1_in.data.rd        = id_ex1_out.data.rd;
    assign ex_mem1_in.data.alu_res   = alu_res1;
    assign ex_mem1_in.data.rs2_val   = forward_b1;
    assign ex_mem1_in.data.mem_size  = id_ex1_out.data.mem_size;
    assign ex_mem1_in.data.mem_unsigned = id_ex1_out.data.mem_unsigned;
    assign ex_mem1_in.data.csr_wdata = 32'd0;

    // ---- DMW translation for the memory slot (at most one) ----
    // The RAW slot address is captured at EX; the DMW translation happens
    // at MEM on the registered address (the translate compare/mux is off
    // the EX critical path; the low address bits used by the WB word
    // select are unaffected by the translation).
    logic        ex_slot0_mem;
    logic [31:0] ex_mem_slot_addr;
    assign ex_slot0_mem = id_ex0_out.ctrl.valid && (id_ex0_out.ctrl.mem_re || id_ex0_out.ctrl.mem_we);
    assign ex_mem_slot_addr = ex_slot0_mem ? ex0_result : alu_res1;

    // Only the memory slot carries the (raw) address.
    assign ex_mem0_in.data.mem_addr  = ex_slot0_mem ? ex_mem_slot_addr : 32'd0;
    assign ex_mem0_in.data.mem_cacheable = 1'b0;
    assign ex_mem1_in.data.mem_addr  = ex_slot0_mem ? 32'd0 : ex_mem_slot_addr;
    assign ex_mem1_in.data.mem_cacheable = 1'b0;

    pipeline_reg #($bits(ex_mem_ctrl_t)) reg_ex_mem0_ctrl (
        .clk, .reset, .stall(ex_mem_stall), .flush(1'b0),
        .data_in(ex_mem0_in.ctrl), .data_out(ex_mem0_out.ctrl)
    );
    pipeline_reg #($bits(ex_mem_data_t)) reg_ex_mem0_data (
        .clk, .reset, .stall(ex_mem_stall), .flush(1'b0),
        .data_in(ex_mem0_in.data), .data_out(ex_mem0_out.data)
    );
    pipeline_reg #($bits(ex_mem_ctrl_t)) reg_ex_mem1_ctrl (
        .clk, .reset, .stall(ex_mem_stall), .flush(1'b0),
        .data_in(ex_mem1_in.ctrl), .data_out(ex_mem1_out.ctrl)
    );
    pipeline_reg #($bits(ex_mem_data_t)) reg_ex_mem1_data (
        .clk, .reset, .stall(ex_mem_stall), .flush(1'b0),
        .data_in(ex_mem1_in.data), .data_out(ex_mem1_out.data)
    );

    // ==================== MEMORY (single LSU, ≤1 mem instr/cycle) ====================
    logic [31:0] lsu_rdata;
    logic lsu_ready;

    // The memory slot: at most one of the two MEM slots is a load/store
    // (the issue gate forbids two mem instructions in the same cycle, and
    // successive mem instructions occupy different slots as they flow).
    wire mem_slot_is_slot0 = ex_mem0_out.ctrl.valid &&
        (ex_mem0_out.ctrl.mem_re || ex_mem0_out.ctrl.mem_we);

    // ---- DMW translation at MEM (off the EX critical path) ----
    // The RAW slot addresses were captured at EX; the translate compare
    // and mux now run here on the registered values.  The WB word select
    // touches only bits [3:2] (unaffected by the translation); difftest's
    // MMIO injection keeps the translated address.
    logic [31:0] crmd_eff, dmw0_eff, dmw1_eff;
    // WB-stage bypass: a csrwr/csrxchg one instruction older is retiring
    // this cycle — its write lands at the end of the cycle, too late for
    // the current access, so the translation must use the pending value.
    // (The instruction two older is already in the array; the instruction
    // in MEM itself is the access being translated and must not be
    // bypassed — its write takes effect a cycle later.)
    assign crmd_eff  = (wb_csr_we && wb_csr_num == 14'h000) ? wb_csr_wdata : csr_crmd;
    assign dmw0_eff  = (wb_csr_we && wb_csr_num == 14'h180) ? wb_csr_wdata : csr_dmw0;
    assign dmw1_eff  = (wb_csr_we && wb_csr_num == 14'h181) ? wb_csr_wdata : csr_dmw1;

    // The effective DMW state is captured at the EX->MEM boundary with the
    // instruction: a combinational path from the WB stage through the
    // translate mux into the (combinational) LSU request made the WB->CSR
    // ->translate->arbiter->write-buffer-search cloud a 100MHz critical
    // path.  The registered values are equivalent to the EX-time bypass
    // (the 2-back's write lands at the capture edge).
    logic [31:0] crmd_eff_r, dmw0_eff_r, dmw1_eff_r;
    always_ff @(posedge clk) begin
        if (reset) begin
            crmd_eff_r <= 32'h00000008;
            dmw0_eff_r <= 32'd0;
            dmw1_eff_r <= 32'd0;
        end else begin
            crmd_eff_r <= crmd_eff;
            dmw0_eff_r <= dmw0_eff;
            dmw1_eff_r <= dmw1_eff;
        end
    end

    logic [31:0] mem_addr_eff0, mem_addr_eff1;
    logic        mem_cacheable0, mem_cacheable1;
    always_comb begin
        mem_addr_eff0  = ex_mem0_out.data.mem_addr;
        mem_cacheable0 = 1'b0;
        if (!crmd_eff_r[3] && crmd_eff_r[4]) begin
            if (ex_mem0_out.data.mem_addr[31:29] == dmw0_eff_r[31:29] && dmw0_eff_r[0]) begin
                mem_addr_eff0  = {dmw0_eff_r[27:25], ex_mem0_out.data.mem_addr[28:0]};
                mem_cacheable0 = 1'b1;
            end else if (ex_mem0_out.data.mem_addr[31:29] == dmw1_eff_r[31:29] && dmw1_eff_r[0]) begin
                mem_addr_eff0  = {dmw1_eff_r[27:25], ex_mem0_out.data.mem_addr[28:0]};
            end
        end
        mem_addr_eff1  = ex_mem1_out.data.mem_addr;
        mem_cacheable1 = 1'b0;
        if (!crmd_eff_r[3] && crmd_eff_r[4]) begin
            if (ex_mem1_out.data.mem_addr[31:29] == dmw0_eff_r[31:29] && dmw0_eff_r[0]) begin
                mem_addr_eff1  = {dmw0_eff_r[27:25], ex_mem1_out.data.mem_addr[28:0]};
                mem_cacheable1 = 1'b1;
            end else if (ex_mem1_out.data.mem_addr[31:29] == dmw1_eff_r[31:29] && dmw1_eff_r[0]) begin
                mem_addr_eff1  = {dmw1_eff_r[27:25], ex_mem1_out.data.mem_addr[28:0]};
            end
        end
    end

    lsu lsu_unit (
        .clk, .reset,
        .valid_in(mem_slot_is_slot0 ? ex_mem0_out.ctrl.valid : ex_mem1_out.ctrl.valid),
        .mem_re(mem_slot_is_slot0 ? ex_mem0_out.ctrl.mem_re : ex_mem1_out.ctrl.mem_re),
        .mem_we(mem_slot_is_slot0 ? ex_mem0_out.ctrl.mem_we : ex_mem1_out.ctrl.mem_we),
        .mem_size(mem_slot_is_slot0 ? ex_mem0_out.data.mem_size : ex_mem1_out.data.mem_size),
        .mem_unsigned(mem_slot_is_slot0 ? ex_mem0_out.data.mem_unsigned : ex_mem1_out.data.mem_unsigned),
        .addr(mem_slot_is_slot0 ? mem_addr_eff0 : mem_addr_eff1),
        .wdata(mem_slot_is_slot0 ? ex_mem0_out.data.rs2_val : ex_mem1_out.data.rs2_val),
        .cacheable(mem_slot_is_slot0 ? mem_cacheable0 : mem_cacheable1),
        .rdata_out(lsu_rdata), .lsu_ready,
        .dreq, .dresp
    );

    logic mem_valid0, mem_valid1;
    // Both slots advance with the LSU: a MEM-level load/store hold (e.g. a
    // dcache refill) stalls the whole memory stage, preserving the legacy
    // global-stall semantics.
    assign mem_valid0 = ex_mem0_out.ctrl.valid && lsu_ready && !ex_mem_stall;
    assign mem_valid1 = ex_mem1_out.ctrl.valid && lsu_ready && !ex_mem_stall;

    // The memory slot's load data is the lsu_rdata (0-cycle hit) or the
    // pass-through response; the WB stage re-extracts for L1 hits.
    logic [31:0] mem0_final_res, mem1_final_res;
    assign mem0_final_res = ex_mem0_out.ctrl.mem_re ? lsu_rdata : ex_mem0_out.data.alu_res;
    assign mem1_final_res = ex_mem1_out.ctrl.mem_re ? lsu_rdata : ex_mem1_out.data.alu_res;

    assign mem_wb0_in.ctrl.valid     = mem_valid0;
    assign mem_wb0_in.ctrl.rf_we     = ex_mem0_out.ctrl.rf_we & mem_valid0;
    assign mem_wb0_in.ctrl.mem_re    = ex_mem0_out.ctrl.mem_re & mem_valid0;
    assign mem_wb0_in.ctrl.mem_we    = ex_mem0_out.ctrl.mem_we & mem_valid0;
    assign mem_wb0_in.ctrl.is_cond_branch = ex_mem0_out.ctrl.is_cond_branch & mem_valid0;
    assign mem_wb0_in.ctrl.is_csrwr  = ex_mem0_out.ctrl.is_csrwr & mem_valid0;
    assign mem_wb0_in.ctrl.is_csrxchg = ex_mem0_out.ctrl.is_csrxchg & mem_valid0;
    assign mem_wb0_in.ctrl.mem_hit   = mem_valid0 && ex_mem0_out.ctrl.mem_re && dresp.hit;
    assign mem_wb0_in.ctrl.mem_hit_way = dresp.hit_way;
    assign mem_wb0_in.ctrl.mem_size  = ex_mem0_out.data.mem_size;
    assign mem_wb0_in.ctrl.mem_unsigned = ex_mem0_out.data.mem_unsigned;
    assign mem_wb0_in.data.pc        = ex_mem0_out.data.pc;
    assign mem_wb0_in.data.instr     = ex_mem0_out.data.instr;
    assign mem_wb0_in.data.rd        = ex_mem0_out.data.rd;
    assign mem_wb0_in.data.final_res = mem0_final_res;
    assign mem_wb0_in.data.mem_addr  = mem_addr_eff0;
    assign mem_wb0_in.data.csr_wdata = ex_mem0_out.data.csr_wdata;

    assign mem_wb1_in.ctrl.valid     = mem_valid1;
    assign mem_wb1_in.ctrl.rf_we     = ex_mem1_out.ctrl.rf_we & mem_valid1;
    assign mem_wb1_in.ctrl.mem_re    = ex_mem1_out.ctrl.mem_re & mem_valid1;
    assign mem_wb1_in.ctrl.mem_we    = ex_mem1_out.ctrl.mem_we & mem_valid1;
    assign mem_wb1_in.ctrl.is_cond_branch = ex_mem1_out.ctrl.is_cond_branch & mem_valid1;
    assign mem_wb1_in.ctrl.is_csrwr  = ex_mem1_out.ctrl.is_csrwr & mem_valid1;
    assign mem_wb1_in.ctrl.is_csrxchg = ex_mem1_out.ctrl.is_csrxchg & mem_valid1;
    assign mem_wb1_in.ctrl.mem_hit   = mem_valid1 && ex_mem1_out.ctrl.mem_re && dresp.hit;
    assign mem_wb1_in.ctrl.mem_hit_way = dresp.hit_way;
    assign mem_wb1_in.ctrl.mem_size  = ex_mem1_out.data.mem_size;
    assign mem_wb1_in.ctrl.mem_unsigned = ex_mem1_out.data.mem_unsigned;
    assign mem_wb1_in.data.pc        = ex_mem1_out.data.pc;
    assign mem_wb1_in.data.instr     = ex_mem1_out.data.instr;
    assign mem_wb1_in.data.rd        = ex_mem1_out.data.rd;
    assign mem_wb1_in.data.final_res = mem1_final_res;
    assign mem_wb1_in.data.mem_addr  = mem_addr_eff1;
    assign mem_wb1_in.data.csr_wdata = ex_mem1_out.data.csr_wdata;

    pipeline_reg #($bits(mem_wb_ctrl_t)) reg_mem_wb0_ctrl (
        .clk, .reset, .stall(1'b0), .flush(1'b0),
        .data_in(mem_wb0_in.ctrl), .data_out(mem_wb0_out.ctrl)
    );
    pipeline_reg #($bits(mem_wb_data_t)) reg_mem_wb0_data (
        .clk, .reset, .stall(1'b0), .flush(1'b0),
        .data_in(mem_wb0_in.data), .data_out(mem_wb0_out.data)
    );
    pipeline_reg #($bits(mem_wb_ctrl_t)) reg_mem_wb1_ctrl (
        .clk, .reset, .stall(1'b0), .flush(1'b0),
        .data_in(mem_wb1_in.ctrl), .data_out(mem_wb1_out.ctrl)
    );
    pipeline_reg #($bits(mem_wb_data_t)) reg_mem_wb1_data (
        .clk, .reset, .stall(1'b0), .flush(1'b0),
        .data_in(mem_wb1_in.data), .data_out(mem_wb1_out.data)
    );

    // ==================== WB load data (rvcpu-style sampling) ====================
    // For a 0-cycle hit (mem_hit) the data is not captured at MEM: the
    // registered BRAM read issued in the request cycle completes on the
    // cache's full data port exactly when the load is in WB, so the WB
    // stage re-extracts dcache_data_wb with the load's registered context
    // (way from mem_hit_way, word from mem_addr) — the extra read latency
    // is absorbed by the MEM->WB pipeline register.  The dresp.data mux
    // reflects the *current* request's way/word and cannot be used here.
    localparam int WB_WORD_WIDTH = $clog2(L1CACHE_WORDS);
    function automatic logic [31:0] wb_readdata(
        input word_t   d,
        input msize_t  size,
        input logic [1:0] off,
        input logic    unsign
    );
        case (size)
            MSIZE1: begin
                case (off)
                    2'b00: wb_readdata = unsign ? {24'd0, d[7:0]}  : {{24{d[7]}}, d[7:0]};
                    2'b01: wb_readdata = unsign ? {24'd0, d[15:8]} : {{24{d[15]}}, d[15:8]};
                    2'b10: wb_readdata = unsign ? {24'd0, d[23:16]} : {{24{d[23]}}, d[23:16]};
                    default: wb_readdata = unsign ? {24'd0, d[31:24]} : {{24{d[31]}}, d[31:24]};
                endcase
            end
            MSIZE2: begin
                if (!off[1])
                    wb_readdata = unsign ? {16'd0, d[15:0]} : {{16{d[15]}}, d[15:0]};
                else
                    wb_readdata = unsign ? {16'd0, d[31:16]} : {{16{d[31]}}, d[31:16]};
            end
            default:
                wb_readdata = d;
        endcase
    endfunction

    wire [31:0] wb_final_res0, wb_final_res1;
    generate
        if (L1CACHE_WORDS > 1) begin : g_wb_word_sel
            assign wb_final_res0 = mem_wb0_out.ctrl.mem_hit
                ? wb_readdata(dcache_data_wb[mem_wb0_out.ctrl.mem_hit_way]
                                           [mem_wb0_out.data.mem_addr[WB_WORD_WIDTH+1:2]],
                              mem_wb0_out.ctrl.mem_size,
                              mem_wb0_out.data.mem_addr[1:0], mem_wb0_out.ctrl.mem_unsigned)
                : mem_wb0_out.data.final_res;
            assign wb_final_res1 = mem_wb1_out.ctrl.mem_hit
                ? wb_readdata(dcache_data_wb[mem_wb1_out.ctrl.mem_hit_way]
                                           [mem_wb1_out.data.mem_addr[WB_WORD_WIDTH+1:2]],
                              mem_wb1_out.ctrl.mem_size,
                              mem_wb1_out.data.mem_addr[1:0], mem_wb1_out.ctrl.mem_unsigned)
                : mem_wb1_out.data.final_res;
        end else begin : g_wb_word_sel_1w
            assign wb_final_res0 = mem_wb0_out.ctrl.mem_hit
                ? wb_readdata(dcache_data_wb[mem_wb0_out.ctrl.mem_hit_way][0],
                              mem_wb0_out.ctrl.mem_size,
                              mem_wb0_out.data.mem_addr[1:0], mem_wb0_out.ctrl.mem_unsigned)
                : mem_wb0_out.data.final_res;
            assign wb_final_res1 = mem_wb1_out.ctrl.mem_hit
                ? wb_readdata(dcache_data_wb[mem_wb1_out.ctrl.mem_hit_way][0],
                              mem_wb1_out.ctrl.mem_size,
                              mem_wb1_out.data.mem_addr[1:0], mem_wb1_out.ctrl.mem_unsigned)
                : mem_wb1_out.data.final_res;
        end
    endgenerate

    // ==================== HAZARD ====================
    logic load_use_hazard;

    assign ex_stage_busy = csr_read_stall || mul_first_cycle;

    // Fetch hold when the queue is full with a fetch output pending (the
    // queue cannot absorb it); hazard_unit's own pc_stall covers the rest.
    // A queue flush also holds the fetch: the redirect target can be the
    // fetch's current pc (pc == ex_jump_pc suppresses the redirect), and
    // the target's output would be discarded by the flush while the fetch
    // advances past it (next_pc = target+4) — the target is permanently
    // lost (the 3467452 scenario, reproduced on mixed at 1c002250).  The
    // single-issue IF/ID capture never had this issue: the flush
    // overwrote the register, and the fetch re-delivered the target while
    // stalled on the empty queue ahead; the accumulating queue must not
    // advance past the target it just discarded.
    logic pc_stall_fetch;
    assign pc_stall_fetch = pc_stall || (fq_space == 3'd0 && fetch_valid0) || if_id_flush;

    hazard_unit hazard_ctrl (
        .if_not_ready(!iresp.data_ok),
        .ex_not_ready(ex_stage_busy),
        .lsu_not_ready(!lsu_ready),
        .cacop_not_ready(cacop_not_ready),
        .id_ex0_rd(id_ex0_out.data.rd),
        .id_ex0_mem_re(id_ex0_out.ctrl.mem_re),
        .id_ex1_rd(id_ex1_out.data.rd),
        .id_ex1_mem_re(id_ex1_out.ctrl.mem_re),
        .dec_rs1_0(dec_rs1_0), .dec_rs2_0(dec_rs2_0),
        .dec_rs1_1(dec_rs1_1), .dec_rs2_1(dec_rs2_1),
        .pc_stall, .if_id_stall, .id_ex_stall, .ex_mem_stall,
        .if_id_flush, .id_ex_flush,
        .load_use_hazard,
        .pipeline_stall,
        .jump_flush(ex_jump_flush_hazard),
        .id_jump_req(id_jump_req),
        .bp_do_jump(bp_do_jump),
        .wb_jump_req(1'b0),
        .if_id_in_valid(fetch_valid0),
        .if_id_in_pc(fetch_pc0),
        .fq_head_valid(fq_valid[0]),
        .fq_head_pc(fq_pc[0]),
        .pc_current(pc),
        .ex_jump_pc(ex_jump_pc),
        .id_jump_pc(id_jump_pc),
        .bp_jump_pc(bp_jump_pc)
    );

    // ==================== DEBUG OUTPUT ====================
    assign debug_wb_pc      = mem_wb0_out.data.pc;
    assign debug_wb_inst    = mem_wb0_out.data.instr;
    assign debug_wb_rf_wen  = mem_wb0_out.ctrl.rf_we && mem_wb0_out.ctrl.valid;
    assign debug_wb_rf_wnum = mem_wb0_out.data.rd;
    assign debug_wb_rf_wdata = wb_final_res0;


    // ==================== STALL COUNTERS ====================
    logic lsu_not_ready;
    assign lsu_not_ready = !lsu_ready;


    always_ff @(posedge clk) begin
        if (reset) begin
            stall_dcache_refill   <= 64'd0;
            stall_icache_refill   <= 64'd0;
            stall_load_use        <= 64'd0;
            stall_branch_flush    <= 64'd0;
            stall_dcache_hit_pipe <= 64'd0;
            stall_icache_hit_pipe <= 64'd0;
            stall_other           <= 64'd0;
            stall_other_fetch     <= 64'd0;
            stall_other_single    <= 64'd0;
            stall_other_dual      <= 64'd0;
            stall_other_noissue   <= 64'd0;
        end else if (!(mem_wb0_out.ctrl.valid || mem_wb1_out.ctrl.valid)) begin
            if (dcache_in_refill)
                stall_dcache_refill <= stall_dcache_refill + 64'd1;
            else if (icache_in_refill)
                stall_icache_refill <= stall_icache_refill + 64'd1;
            else if (load_use_hazard)
                stall_load_use <= stall_load_use + 64'd1;
            else if ((if_id_flush && (if_id_out.ctrl.valid || if_id1_out.ctrl.valid)) ||
                     (id_ex_flush && (id_ex0_out.ctrl.valid || id_ex1_out.ctrl.valid)))
                stall_branch_flush <= stall_branch_flush + 64'd1;
            else if (lsu_not_ready)
                stall_dcache_hit_pipe <= stall_dcache_hit_pipe + 64'd1;
            else if (!iresp.data_ok)
                stall_icache_hit_pipe <= stall_icache_hit_pipe + 64'd1;
            else begin
                // Other-bubble breakdown: the fetch queue empty (fetch not
                // supplying), single issue (slot1 held by a constraint),
                // dual issue yet nothing reaches WB (pipeline fill after a
                // flush), or a non-empty queue that does not advance.
                stall_other <= stall_other + 64'd1;
                if (!(fq_valid[0] || fq_valid[1]))
                    stall_other_fetch <= stall_other_fetch + 64'd1;
                else if (c0 && !c1)
                    stall_other_single <= stall_other_single + 64'd1;
                else if (c0 && c1)
                    stall_other_dual <= stall_other_dual + 64'd1;
                else
                    stall_other_noissue <= stall_other_noissue + 64'd1;
            end
        end
    end

    // ==================== DIFFTEST ====================
`ifdef VERILATOR
    DifftestArchIntRegState u_difftest_gpr (
        .clock(clk),
        .gpr_0(gpr_state[0]),  .gpr_1(gpr_state[1]),  .gpr_2(gpr_state[2]),  .gpr_3(gpr_state[3]),
        .gpr_4(gpr_state[4]),  .gpr_5(gpr_state[5]),  .gpr_6(gpr_state[6]),  .gpr_7(gpr_state[7]),
        .gpr_8(gpr_state[8]),  .gpr_9(gpr_state[9]),  .gpr_10(gpr_state[10]), .gpr_11(gpr_state[11]),
        .gpr_12(gpr_state[12]), .gpr_13(gpr_state[13]), .gpr_14(gpr_state[14]), .gpr_15(gpr_state[15]),
        .gpr_16(gpr_state[16]), .gpr_17(gpr_state[17]), .gpr_18(gpr_state[18]), .gpr_19(gpr_state[19]),
        .gpr_20(gpr_state[20]), .gpr_21(gpr_state[21]), .gpr_22(gpr_state[22]), .gpr_23(gpr_state[23]),
        .gpr_24(gpr_state[24]), .gpr_25(gpr_state[25]), .gpr_26(gpr_state[26]), .gpr_27(gpr_state[27]),
        .gpr_28(gpr_state[28]), .gpr_29(gpr_state[29]), .gpr_30(gpr_state[30]), .gpr_31(gpr_state[31])
    );

    DifftestInstrCommit u_difftest_commit0 (
        .clock(clk),
        .valid(mem_wb0_out.ctrl.valid),
        .pc(mem_wb0_out.data.pc),
        .instr(mem_wb0_out.data.instr),
        .wen(mem_wb0_out.ctrl.rf_we),
        .wdest(mem_wb0_out.data.rd),
        .wdata(wb_final_res0),
        .mem_addr(mem_wb0_out.data.mem_addr),
        .mem_re(mem_wb0_out.ctrl.mem_re)
    );

    DifftestInstrCommit1 u_difftest_commit1 (
        .clock(clk),
        .valid(mem_wb1_out.ctrl.valid),
        .pc(mem_wb1_out.data.pc),
        .instr(mem_wb1_out.data.instr),
        .wen(mem_wb1_out.ctrl.rf_we),
        .wdest(mem_wb1_out.data.rd),
        .wdata(wb_final_res1),
        .mem_addr(mem_wb1_out.data.mem_addr),
        .mem_re(mem_wb1_out.ctrl.mem_re)
    );

    DifftestIdlePC u_difftest_idle (
        .clock(clk),
        .idle_pc(mem_wb1_out.ctrl.valid ? mem_wb1_out.data.pc : mem_wb0_out.data.pc)
    );

    DifftestCSRState u_difftest_csr (
        .clock(clk),
        .crmd(csr_crmd),
        .prmd(csr_prmd),
        .euen(csr_euen),
        .ecfg(csr_ecfg),
        .estat(csr_estat),
        .era(csr_era),
        .badv(csr_badv),
        .eentry(csr_eentry),
        .tlbidx(csr_tlbidx),
        .tlbehi(csr_tlbehi),
        .tlbelo0(csr_tlbelo0),
        .tlbelo1(csr_tlbelo1),
        .asid(csr_asid),
        .pgdl(csr_pgdl),
        .pgdh(csr_pgdh),
        .save0(csr_save0),
        .save1(csr_save1),
        .save2(csr_save2),
        .save3(csr_save3),
        .tid(csr_tid),
        .tcfg(csr_tcfg),
        .tval(csr_tval),
        .llbctl(csr_llbctl),
        .tlbrentry(csr_tlbrentry),
        .dmw0(csr_dmw0),
        .dmw1(csr_dmw1)
    );

    logic [63:0] difftest_total_branches;
    logic [63:0] difftest_mispredictions;

    always_ff @(posedge clk) begin
        if (reset) begin
            difftest_total_branches <= 64'd0;
            difftest_mispredictions <= 64'd0;
        end else begin
            if (mem_wb0_out.ctrl.valid && mem_wb0_out.ctrl.is_cond_branch)
                difftest_total_branches <= difftest_total_branches + 64'd1;
            if (mem_wb1_out.ctrl.valid && mem_wb1_out.ctrl.is_cond_branch)
                difftest_total_branches <= difftest_total_branches + 64'd1;
            if (id_ex0_out.ctrl.valid && id_ex0_out.ctrl.is_cond_branch &&
                br_taken_0 != id_ex0_out.ctrl.predict_taken)
                difftest_mispredictions <= difftest_mispredictions + 64'd1;
        end
    end

    DifftestBranchState u_difftest_branch (
        .clock(clk),
        .total_branches(difftest_total_branches),
        .mispredictions(difftest_mispredictions)
    );

    DifftestStallState u_difftest_stall (
        .clock(clk),
        .stall_dcache_refill(stall_dcache_refill),
        .stall_icache_refill(stall_icache_refill),
        .stall_load_use(stall_load_use),
        .stall_branch_flush(stall_branch_flush),
        .stall_dcache_hit_pipe(stall_dcache_hit_pipe),
        .stall_icache_hit_pipe(stall_icache_hit_pipe),
        .stall_other(stall_other),
        .stall_other_fetch(stall_other_fetch),
        .stall_other_single(stall_other_single),
        .stall_other_dual(stall_other_dual),
        .stall_other_noissue(stall_other_noissue),
        .s1_hold_s0complex(s1_hold_s0complex),
        .s1_hold_s1complex(s1_hold_s1complex),
        .s1_hold_s0branch(s1_hold_s0branch),
        .s1_hold_s1branch(s1_hold_s1branch),
        .s1_hold_mem(s1_hold_mem),
        .s1_hold_dep0(s1_hold_dep0),
        .s1_hold_other(s1_hold_other)
    );
`endif

endmodule
