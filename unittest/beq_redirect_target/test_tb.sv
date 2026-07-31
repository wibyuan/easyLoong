// Unit test: csr_dmw0_loop — csrwr with cacop stall intervening
`include "common.sv"

module test_beq_redirect_target (
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
    assign dresp.data_ok   = 1'b1;
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

endmodule
