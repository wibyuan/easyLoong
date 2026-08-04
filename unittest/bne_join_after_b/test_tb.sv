// Unit test: bne mispredict with a fall-through B and the join 2
// instructions later (the .TESTW/.WSERIAL pattern).  The "LSR" load reads
// 0x20 from the data memory model; the difftest injects the DUT's MMIO
// load value into NEMU, so both sides agree on 0x20 (bit 5 set -> the bne
// is TAKEN on both sides).
`include "common.sv"

module test_bne_join_after_b (
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
        .data(iresp.data),
        .data1(iresp.data1)
    );

    assign iresp.addr_ok = 1'b1;
    wire rom_hit = (ireq.addr >= 32'h1c000000) && (ireq.addr < 32'h1c000100);
    logic data_ok_en;
    always_ff @(posedge clk) begin
        if (reset) data_ok_en <= 1'b0;
        else       data_ok_en <= 1'b1;
    end
    assign iresp.data_ok  = rom_hit && data_ok_en;
    // 2-wide fetch mirroring the real icache (16B line).
    assign iresp.valid1   = rom_hit && data_ok_en && (ireq.addr[3:2] != 2'b11);

    // Data memory model: the "LSR" at 0x1f000004 returns 0x20 (TX-ready bit
    // set).  The LSU requests the aligned word 0x1f000004 -> dmem index 1.
    logic [31:0] dmem [0:255];
    logic [31:0] ddata_r;
    logic        dreq_r;
    initial begin
        dmem[1] = 32'h20;
    end
    always_ff @(posedge clk) begin
        if (reset) begin
            dreq_r  <= 1'b0;
            ddata_r <= 32'd0;
        end else begin
            dreq_r  <= dreq.valid;
            if (dreq.valid)
                ddata_r <= dmem[dreq.addr[9:2]];
        end
    end
    always_ff @(posedge clk) begin
        if (dreq.valid && |dreq.strobe)
            dmem[dreq.addr[9:2]] <= dreq.data;
    end

    assign dresp.addr_ok   = 1'b1;
    assign dresp.data_ok   = dreq_r;
    assign dresp.data_last = 1'b1;
    assign dresp.data      = ddata_r;

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
