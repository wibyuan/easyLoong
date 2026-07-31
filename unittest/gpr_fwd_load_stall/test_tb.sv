// Unit test: csr_dmw0_loop — csrwr with cacop stall intervening
`include "common.sv"

module test_gpr_fwd_load_stall (
    input  logic clk,
    input  logic reset
);
    import la32_common::*;

    ibus_req_t  ireq;
    ibus_resp_t iresp;
    dbus_req_t  dreq;
    dbus_resp_t dresp;

    cacop_req_t  cacop_req;
    logic        cacop_done;
    logic        dcache_in_refill;
    logic        icache_in_refill;

    logic [31:0] core_debug_wb_pc;
    logic [31:0] core_debug_wb_inst;
    logic        core_debug_wb_rf_wen;
    logic [4:0]  core_debug_wb_rf_wnum;
    logic [31:0] core_debug_wb_rf_wdata;

    logic [63:0] stall_s0, stall_s1, stall_s2, stall_s3, stall_s4, stall_s5, stall_s6;

    core #(.ICACHE_SETS(256), .DCACHE_SETS(256)) u_core (
        .clk, .reset,
        .ireq, .iresp,
        .dreq, .dresp,
        .cacop_req, .cacop_done,
        .dcache_in_refill, .icache_in_refill,
        .debug_wb_pc      (core_debug_wb_pc),
        .debug_wb_inst    (core_debug_wb_inst),
        .debug_wb_rf_wen  (core_debug_wb_rf_wen),
        .debug_wb_rf_wnum (core_debug_wb_rf_wnum),
        .debug_wb_rf_wdata(core_debug_wb_rf_wdata),
        .stall_dcache_refill(stall_s0),
        .stall_icache_refill(stall_s1),
        .stall_load_use(stall_s2),
        .stall_branch_flush(stall_s3),
        .stall_dcache_hit_pipe(stall_s4),
        .stall_icache_hit_pipe(stall_s5),
        .stall_other(stall_s6)
    );

    inst_rom u_inst_rom (
        .addr(ireq.addr),
        .data(iresp.data)
    );

    assign iresp.addr_ok = 1'b1;
    wire rom_hit = (ireq.addr >= 32'h1c000000) && (ireq.addr < 32'h1c000100);
    logic data_ok_en;
    always_ff @(posedge clk) begin
        if (reset) data_ok_en <= 1'b0;
        else       data_ok_en <= 1'b1;
    end
    assign iresp.data_ok = rom_hit && data_ok_en;

    assign dresp.addr_ok   = 1'b1;
        // load response: 1-cycle delay to simulate dcache pipeline stall
    logic dresp_data_ok_r;
    always_ff @(posedge clk) begin
        if (reset) dresp_data_ok_r <= 1'b0;
        else       dresp_data_ok_r <= dreq.valid;
    end
    assign dresp.data_ok   = dresp_data_ok_r;
    assign dresp.data_last = 1'b1;
    assign dresp.data      = 32'd0;

    // CACOP: 1-cycle delay — mimics real icache communication
    logic cacop_done_r;
    always_ff @(posedge clk) begin
        if (reset) cacop_done_r <= 1'b0;
        else       cacop_done_r <= cacop_req.valid;
    end
    assign cacop_done = cacop_done_r;

    assign icache_in_refill = 1'b0;
    assign dcache_in_refill = 1'b0;

    // ===== pipeline debug trace =====
    logic [7:0] debug_cycle;
    always_ff @(posedge clk) begin
        if (reset) debug_cycle <= 0;
        else       debug_cycle <= debug_cycle + 1;
        if (!reset && debug_cycle < 40) begin
            $display("[CYC%0d] pc=%08x next_pc=%08x", debug_cycle, u_core.pc, u_core.next_pc_reg);
            $display("  IF_ID_OUT: v=%0d pc=%08x", u_core.if_id_out.ctrl.valid, u_core.if_id_out.data.pc);
            $display("  ID_EX_OUT: v=%0d pc=%08x fw_ex=%0d fw_mem=%0d", u_core.id_ex_out.ctrl.valid, u_core.id_ex_out.data.pc, u_core.id_ex_out.data.fw_a_ex_hit, u_core.id_ex_out.data.fw_a_mem_hit);
            $display("  EX_MEM_OUT: v=%0d pc=%08x alu=%08x rf_we=%0d mem_re=%0d", u_core.ex_mem_out.ctrl.valid, u_core.ex_mem_out.data.pc, u_core.ex_mem_out.data.alu_res, u_core.ex_mem_out.ctrl.rf_we, u_core.ex_mem_out.ctrl.mem_re);
            $display("  MEM_WB_OUT: v=%0d pc=%08x res=%08x rf_we=%0d rd=%0d", u_core.mem_wb_out.ctrl.valid, u_core.mem_wb_out.data.pc, u_core.mem_wb_out.data.final_res, u_core.mem_wb_out.ctrl.rf_we, u_core.mem_wb_out.data.rd);
            $display("  FWD: fw_a_em=%0d fw_a_mw=%0d forward_a=%08x", u_core.fw_a_em, u_core.fw_a_mw, u_core.forward_a);
            $display("  STALL: pc=%0d if_id=%0d id_ex=%0d ex_mem=%0d lsu_ready=%0d", u_core.pc_stall, u_core.if_id_stall, u_core.id_ex_stall, u_core.ex_mem_stall, u_core.lsu_ready);
        end
    end

endmodule
