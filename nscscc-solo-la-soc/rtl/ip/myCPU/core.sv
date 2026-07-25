`include "common.sv"

module core import la32_common::*; (
    input  logic       clk,
    input  logic       reset,
    output ibus_req_t  ireq,
    input  ibus_resp_t iresp,
    output dbus_req_t  dreq,
    input  dbus_resp_t dresp,
    output cacop_req_t cacop_req,
    input  logic       cacop_done,
    output logic [31:0] debug_wb_pc,
    output logic [31:0] debug_wb_inst,
    output logic        debug_wb_rf_wen,
    output logic [4:0]  debug_wb_rf_wnum,
    output logic [31:0] debug_wb_rf_wdata
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
        logic [31:0] rd1, rd2;
        logic        fw_a_ex_hit, fw_a_mem_hit, fw_b_ex_hit, fw_b_mem_hit;
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
    } mem_wb_ctrl_t;
    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] instr;
        logic [4:0]  rd;
        logic [31:0] final_res;
        logic [31:0] mem_addr;
    } mem_wb_data_t;
    typedef struct packed {
        mem_wb_ctrl_t ctrl;
        mem_wb_data_t data;
    } mem_wb_t;

    logic [31:0] pc, next_pc_reg;
    if_id_t  if_id_in,  if_id_out;
    id_ex_t  id_ex_in,  id_ex_out;
    ex_mem_t ex_mem_in, ex_mem_out;
    mem_wb_t mem_wb_in, mem_wb_out;

    logic pc_stall, if_id_stall, id_ex_stall, ex_mem_stall;
    logic if_id_flush, id_ex_flush, ex_jump_flush;
    logic [31:0] ex_jump_pc, id_jump_pc;
    logic id_jump_req;
    logic ex_stage_busy;
    logic ex_jump_flush_hazard;

    // ==================== FETCH ====================
    logic do_ex_flush;
    assign do_ex_flush = ex_jump_flush && !ex_mem_stall;

    assign ex_jump_flush_hazard = ex_jump_flush && !id_ex_out.ctrl.is_jal;

    fetch_unit if_stage (
        .clk, .reset,
        .pc_stall, .pc_current(pc),
        .wb_jump_req(1'b0), .wb_jump_pc(32'd0),
        .do_ex_flush(do_ex_flush), .ex_jump_pc,
        .do_id_jump(id_jump_req && !id_ex_stall), .id_jump_pc,
        .ireq, .iresp,
        .next_pc(next_pc_reg),
        .if_pc_valid(),
        .if_pc(if_id_in.data.pc),
        .if_instr(if_id_in.data.instr),
        .if_valid(if_id_in.ctrl.valid)
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

    pipeline_reg #($bits(if_id_ctrl_t)) reg_if_id_ctrl (
        .clk, .reset, .stall(if_id_stall), .flush(if_id_flush),
        .data_in(if_id_in.ctrl), .data_out(if_id_out.ctrl)
    );
    pipeline_reg #($bits(if_id_data_t)) reg_if_id_data (
        .clk, .reset, .stall(if_id_stall), .flush(1'b0),
        .data_in(if_id_in.data), .data_out(if_id_out.data)
    );

    // ==================== DECODE ====================
    logic [4:0] dec_rs1, dec_rs2, dec_rd;
    logic       dec_rf_we, dec_alu_src_sel;
    logic       dec_mem_re, dec_mem_we, dec_mem_unsigned;
    logic       dec_is_branch, dec_is_jal, dec_is_jalr, dec_is_pcadd, dec_is_cpucfg;
    logic       dec_is_csrrd, dec_is_csrwr, dec_is_csrxchg, dec_is_cacop, dec_is_ibar, dec_is_illegal;
    logic [31:0] dec_imm;
    alu_op_t    dec_alu_op;
    br_type_t   dec_br_type;
    msize_t     dec_mem_size;

    decode dec_unit (
        .instr(if_id_out.data.instr),
        .rs1(dec_rs1), .rs2(dec_rs2), .rd(dec_rd),
        .rf_we(dec_rf_we), .imm(dec_imm),
        .alu_op(dec_alu_op), .alu_src_sel(dec_alu_src_sel),
        .is_word_op(),
        .mem_we(dec_mem_we), .mem_re(dec_mem_re),
        .mem_size(dec_mem_size), .mem_unsigned(dec_mem_unsigned),
        .is_branch(dec_is_branch), .is_jal(dec_is_jal), .is_jalr(dec_is_jalr),
        .br_type(dec_br_type),
        .is_pcadd(dec_is_pcadd),
        .is_cpucfg(dec_is_cpucfg),
        .is_csrrd(dec_is_csrrd),
        .is_csrwr(dec_is_csrwr),
        .is_csrxchg(dec_is_csrxchg),
        .is_cacop(dec_is_cacop),
        .is_ibar(dec_is_ibar),
        .is_illegal(dec_is_illegal)
    );

    assign id_jump_req = dec_is_jal && if_id_out.ctrl.valid;
    assign id_jump_pc  = if_id_out.data.pc + dec_imm;

    logic [31:0] dec_rd1, dec_rd2;
    logic [31:0] gpr_state [31:0];
    regfile rf_unit (
        .clk,
        .ra1(dec_rs1), .ra2(dec_rs2), .rd1(dec_rd1), .rd2(dec_rd2),
        .wa(mem_wb_out.data.rd), .wd(mem_wb_out.data.final_res),
        .wen(mem_wb_out.ctrl.rf_we && mem_wb_out.ctrl.valid),
        .gpr_dbg(gpr_state)
    );

    logic id_valid;
    assign id_valid = if_id_out.ctrl.valid;

    assign id_ex_in.ctrl.valid      = id_valid;
    assign id_ex_in.ctrl.rf_we      = dec_rf_we & id_valid;
    assign id_ex_in.ctrl.mem_re     = dec_mem_re & id_valid;
    assign id_ex_in.ctrl.mem_we     = dec_mem_we & id_valid;
    assign id_ex_in.ctrl.is_branch  = dec_is_branch & id_valid;
    assign id_ex_in.ctrl.is_jal     = dec_is_jal & id_valid;
    assign id_ex_in.ctrl.is_jalr    = dec_is_jalr & id_valid;
    assign id_ex_in.ctrl.is_pcadd   = dec_is_pcadd & id_valid;
    assign id_ex_in.ctrl.is_cpucfg  = dec_is_cpucfg & id_valid;
    assign id_ex_in.ctrl.is_csrrd   = dec_is_csrrd & id_valid;
    assign id_ex_in.ctrl.is_csrwr   = dec_is_csrwr & id_valid;
    assign id_ex_in.ctrl.is_csrxchg = dec_is_csrxchg & id_valid;
    assign id_ex_in.ctrl.is_cacop   = dec_is_cacop & id_valid;
    assign id_ex_in.ctrl.is_ibar    = dec_is_ibar  & id_valid;

    assign id_ex_in.data.fw_a_ex_hit  = (dec_rs1 != 5'd0) && (dec_rs1 == id_ex_out.data.rd);
    assign id_ex_in.data.fw_a_mem_hit = (dec_rs1 != 5'd0) && (dec_rs1 == ex_mem_out.data.rd);
    assign id_ex_in.data.fw_b_ex_hit  = (dec_rs2 != 5'd0) && (dec_rs2 == id_ex_out.data.rd);
    assign id_ex_in.data.fw_b_mem_hit = (dec_rs2 != 5'd0) && (dec_rs2 == ex_mem_out.data.rd);

    assign id_ex_in.data.pc         = if_id_out.data.pc;
    assign id_ex_in.data.instr      = if_id_out.data.instr;
    assign id_ex_in.data.rs1        = dec_rs1;
    assign id_ex_in.data.rs2        = dec_rs2;
    assign id_ex_in.data.rd         = dec_rd;
    assign id_ex_in.data.imm        = dec_imm;
    assign id_ex_in.data.target_pc  = if_id_out.data.pc + dec_imm;
    assign id_ex_in.data.pc_plus_4  = if_id_out.data.pc + 32'd4;
    assign id_ex_in.data.rd1        = dec_rd1;
    assign id_ex_in.data.rd2        = dec_rd2;
    assign id_ex_in.data.alu_op     = dec_alu_op;
    assign id_ex_in.data.br_type    = dec_br_type;
    assign id_ex_in.data.alu_src_sel = dec_alu_src_sel;
    assign id_ex_in.data.mem_size   = dec_mem_size;
    assign id_ex_in.data.mem_unsigned = dec_mem_unsigned;

    pipeline_reg #($bits(id_ex_ctrl_t)) reg_id_ex_ctrl (
        .clk, .reset, .stall(id_ex_stall), .flush(id_ex_flush),
        .data_in(id_ex_in.ctrl), .data_out(id_ex_out.ctrl)
    );
    pipeline_reg #($bits(id_ex_data_t)) reg_id_ex_data (
        .clk, .reset, .stall(id_ex_stall), .flush(1'b0),
        .data_in(id_ex_in.data), .data_out(id_ex_out.data)
    );

    // ==================== EXECUTE ====================
    logic [31:0] forward_a, forward_b, alu_result;
    logic fw_a_em, fw_a_mw, fw_b_em, fw_b_mw;
    assign fw_a_em = id_ex_out.data.fw_a_ex_hit  && ex_mem_out.ctrl.rf_we && ex_mem_out.ctrl.valid && !ex_mem_out.ctrl.mem_re;
    assign fw_a_mw = id_ex_out.data.fw_a_mem_hit && mem_wb_out.ctrl.rf_we && mem_wb_out.ctrl.valid;
    assign fw_b_em = id_ex_out.data.fw_b_ex_hit  && ex_mem_out.ctrl.rf_we && ex_mem_out.ctrl.valid && !ex_mem_out.ctrl.mem_re;
    assign fw_b_mw = id_ex_out.data.fw_b_mem_hit && mem_wb_out.ctrl.rf_we && mem_wb_out.ctrl.valid;

    always_comb begin
        if (fw_a_em)      forward_a = ex_mem_out.data.alu_res;
        else if (fw_a_mw) forward_a = mem_wb_out.data.final_res;
        else              forward_a = id_ex_out.data.rd1;

        if (fw_b_em)      forward_b = ex_mem_out.data.alu_res;
        else if (fw_b_mw) forward_b = mem_wb_out.data.final_res;
        else              forward_b = id_ex_out.data.rd2;
    end

    alu alu_unit (
        .a(forward_a),
        .b(id_ex_out.data.alu_src_sel ? id_ex_out.data.imm : forward_b),
        .op(id_ex_out.data.alu_op),
        .res(alu_result)
    );

    logic br_taken;
    bcu bcu_unit (
        .rs1_val(forward_a), .rs2_val(forward_b),
        .br_type(id_ex_out.data.br_type), .br_taken(br_taken)
    );

    npc npc_unit (
        .target_pc(id_ex_out.data.target_pc),
        .pc_plus_4(id_ex_out.data.pc_plus_4),
        .rs1_val(forward_a),
        .imm(id_ex_out.data.imm),
        .is_branch(id_ex_out.ctrl.is_branch),
        .is_jal(id_ex_out.ctrl.is_jal),
        .is_jalr(id_ex_out.ctrl.is_jalr),
        .is_ibar(id_ex_out.ctrl.is_ibar),
        .br_taken(br_taken),
        .next_pc(ex_jump_pc),
        .flush_req(ex_jump_flush)
    );

    logic cacop_not_ready;
    logic cacop_in_ex;
    assign cacop_in_ex = id_ex_out.ctrl.is_cacop && id_ex_out.ctrl.valid;
    assign cacop_req.valid = cacop_in_ex;
    assign cacop_req.code  = id_ex_out.data.instr[4:0];
    assign cacop_req.addr  = alu_result;
    assign cacop_not_ready = cacop_in_ex && !cacop_done;

    // ==================== CSR REGISTER FILE ====================
    logic [13:0] csr_num;
    logic [31:0] csr_rdata, csr_wdata;
    logic        csr_we;
    logic [31:0] csr_crmd, csr_dmw0, csr_dmw1;
    logic [31:0] csr_prmd, csr_euen, csr_ecfg, csr_estat, csr_era, csr_badv, csr_eentry;
    logic [31:0] csr_tlbidx, csr_tlbehi, csr_tlbelo0, csr_tlbelo1, csr_asid, csr_pgdl, csr_pgdh;
    logic [31:0] csr_save0, csr_save1, csr_save2, csr_save3;
    logic [31:0] csr_tid, csr_tcfg, csr_tval, csr_llbctl, csr_tlbrentry;

    assign csr_num = id_ex_out.data.instr[23:10];

    csr_regfile csr_rf (
        .clk, .reset,
        .csr_num,
        .csr_rdata,
        .csr_we,
        .csr_waddr(csr_num),
        .csr_wdata,
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
        if (id_ex_out.ctrl.is_csrwr)
            csr_wdata = forward_a;
        else if (id_ex_out.ctrl.is_csrxchg)
            csr_wdata = (csr_rdata & ~forward_a) | (forward_b & forward_a);
        else
            csr_wdata = 32'd0;
    end

    assign csr_we = id_ex_out.ctrl.valid && (id_ex_out.ctrl.is_csrwr || id_ex_out.ctrl.is_csrxchg);

    // ==================== EXECUTE (continued) ====================
    logic ex_valid;
    assign ex_valid = id_ex_out.ctrl.valid;

    assign ex_mem_in.ctrl.valid     = ex_valid;
    assign ex_mem_in.ctrl.rf_we     = id_ex_out.ctrl.rf_we & ex_valid;
    assign ex_mem_in.ctrl.mem_re    = id_ex_out.ctrl.mem_re & ex_valid;
    assign ex_mem_in.ctrl.mem_we    = id_ex_out.ctrl.mem_we & ex_valid;

    assign ex_mem_in.data.pc        = id_ex_out.data.pc;
    assign ex_mem_in.data.instr     = id_ex_out.data.instr;
    assign ex_mem_in.data.rd        = id_ex_out.data.rd;

    logic [31:0] cpucfg_result;
    always_comb begin
        cpucfg_result = 32'd0;
        case (forward_a)
            32'd16: cpucfg_result = 32'h00000010;
            default: cpucfg_result = 32'd0;
        endcase
    end

    always_comb begin
        if (id_ex_out.ctrl.is_cpucfg)
            ex_mem_in.data.alu_res = cpucfg_result;
        else if (id_ex_out.ctrl.is_csrrd || id_ex_out.ctrl.is_csrwr || id_ex_out.ctrl.is_csrxchg)
            ex_mem_in.data.alu_res = csr_rdata;
        else if (id_ex_out.ctrl.is_jal || id_ex_out.ctrl.is_jalr)
            ex_mem_in.data.alu_res = id_ex_out.data.pc_plus_4;
        else if (id_ex_out.ctrl.is_pcadd)
            ex_mem_in.data.alu_res = id_ex_out.data.pc + id_ex_out.data.imm;
        else
            ex_mem_in.data.alu_res = alu_result;
    end

    assign ex_mem_in.data.rs2_val   = forward_b;

    logic [31:0] ex_mem_addr;
    always_comb begin
        ex_mem_addr = alu_result;
        if (!csr_crmd[3] && csr_crmd[4]) begin
            if (alu_result[31:29] == csr_dmw0[31:29] && csr_dmw0[0])
                ex_mem_addr = {csr_dmw0[27:25], alu_result[28:0]};
            else if (alu_result[31:29] == csr_dmw1[31:29] && csr_dmw1[0])
                ex_mem_addr = {csr_dmw1[27:25], alu_result[28:0]};
        end
    end

    assign ex_mem_in.data.mem_addr  = ex_mem_addr;
    assign ex_mem_in.data.mem_size  = id_ex_out.data.mem_size;
    assign ex_mem_in.data.mem_unsigned = id_ex_out.data.mem_unsigned;

    pipeline_reg #($bits(ex_mem_ctrl_t)) reg_ex_mem_ctrl (
        .clk, .reset, .stall(ex_mem_stall), .flush(1'b0),
        .data_in(ex_mem_in.ctrl), .data_out(ex_mem_out.ctrl)
    );
    pipeline_reg #($bits(ex_mem_data_t)) reg_ex_mem_data (
        .clk, .reset, .stall(ex_mem_stall), .flush(1'b0),
        .data_in(ex_mem_in.data), .data_out(ex_mem_out.data)
    );

    // ==================== MEMORY ====================
    logic [31:0] lsu_rdata;
    logic lsu_ready;

    lsu lsu_unit (
        .clk, .reset,
        .valid_in(ex_mem_out.ctrl.valid),
        .mem_re(ex_mem_out.ctrl.mem_re), .mem_we(ex_mem_out.ctrl.mem_we),
        .mem_size(ex_mem_out.data.mem_size), .mem_unsigned(ex_mem_out.data.mem_unsigned),
        .addr(ex_mem_out.data.mem_addr), .wdata(ex_mem_out.data.rs2_val),
        .rdata_out(lsu_rdata), .lsu_ready,
        .dreq, .dresp
    );

    logic mem_valid;
    assign mem_valid = ex_mem_out.ctrl.valid && lsu_ready;

    assign mem_wb_in.ctrl.valid     = mem_valid;
    assign mem_wb_in.ctrl.rf_we     = ex_mem_out.ctrl.rf_we & mem_valid;
    assign mem_wb_in.ctrl.mem_re    = ex_mem_out.ctrl.mem_re & mem_valid;
    assign mem_wb_in.ctrl.mem_we    = ex_mem_out.ctrl.mem_we & mem_valid;

    assign mem_wb_in.data.pc        = ex_mem_out.data.pc;
    assign mem_wb_in.data.instr     = ex_mem_out.data.instr;
    assign mem_wb_in.data.rd        = ex_mem_out.data.rd;
    assign mem_wb_in.data.final_res = ex_mem_out.ctrl.mem_re ? lsu_rdata : ex_mem_out.data.alu_res;
    assign mem_wb_in.data.mem_addr  = ex_mem_out.data.mem_addr;

    pipeline_reg #($bits(mem_wb_ctrl_t)) reg_mem_wb_ctrl (
        .clk, .reset, .stall(1'b0), .flush(1'b0),
        .data_in(mem_wb_in.ctrl), .data_out(mem_wb_out.ctrl)
    );
    pipeline_reg #($bits(mem_wb_data_t)) reg_mem_wb_data (
        .clk, .reset, .stall(1'b0), .flush(1'b0),
        .data_in(mem_wb_in.data), .data_out(mem_wb_out.data)
    );

    // ==================== HAZARD ====================
    assign ex_stage_busy = 1'b0;

    hazard_unit hazard_ctrl (
        .if_not_ready(!iresp.data_ok),
        .ex_not_ready(ex_stage_busy),
        .lsu_not_ready(!lsu_ready),
        .cacop_not_ready(cacop_not_ready),
        .id_ex_rd(id_ex_out.data.rd),
        .id_ex_mem_re(id_ex_out.ctrl.mem_re),
        .dec_rs1(dec_rs1), .dec_rs2(dec_rs2),
        .pc_stall, .if_id_stall, .id_ex_stall, .ex_mem_stall,
        .if_id_flush, .id_ex_flush,
        .jump_flush(ex_jump_flush_hazard),
        .id_jump_req(id_jump_req),
        .wb_jump_req(1'b0)
    );

    // ==================== DEBUG OUTPUT ====================
    assign debug_wb_pc      = mem_wb_out.data.pc;
    assign debug_wb_inst    = mem_wb_out.data.instr;
    assign debug_wb_rf_wen  = mem_wb_out.ctrl.rf_we && mem_wb_out.ctrl.valid;
    assign debug_wb_rf_wnum = mem_wb_out.data.rd;
    assign debug_wb_rf_wdata = mem_wb_out.data.final_res;

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

    DifftestInstrCommit u_difftest_commit (
        .clock(clk),
        .valid(mem_wb_out.ctrl.valid),
        .pc(mem_wb_out.data.pc),
        .instr(mem_wb_out.data.instr),
        .wen(mem_wb_out.ctrl.rf_we),
        .wdest(mem_wb_out.data.rd),
        .wdata(mem_wb_out.data.final_res),
        .mem_addr(mem_wb_out.data.mem_addr),
        .mem_re(mem_wb_out.ctrl.mem_re)
    );

    DifftestIdlePC u_difftest_idle (
        .clock(clk),
        .idle_pc(mem_wb_out.data.pc)
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
`endif

endmodule
