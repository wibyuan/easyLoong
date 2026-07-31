// Unit test: icache_redirect_stale — redirect during icache refill.
// Instantiates the REAL icache between core and a slow fake memory so the
// keyword-forward timing (refill in flight when the EX redirect fires) is
// reproduced exactly as in the fibonacci failure.
`include "common.sv"

module test_icache_redirect_stale (
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

    // ==================== Real icache in the fetch path ====================
    ibus_req_t  imem_req;
    ibus_resp_t imem_resp;

    icache u_icache (
        .clk, .reset,
        .inv_all(1'b0),
        .cpu_req(ireq), .cpu_resp(iresp),
        .mem_req(imem_req), .mem_resp(imem_resp),
        .cacop_req, .cacop_done,
        .perf_access(), .perf_hit(), .perf_miss(),
        .perf_wa_clear(), .perf_s1_accept(), .perf_cyc(),
        .in_refill(icache_in_refill)
    );

    // ==================== Fake memory (0-delay addr_ok, delayed data) =====
    // addr_ok is ack'ed in the request cycle (like the arbiter), data_ok
    // arrives MEM_DELAY cycles later with the word for the sampled request —
    // models the SRAM/arbiter latency that keeps the refill in flight past
    // the EX branch resolution (the fibonacci failure's timing).
    localparam int MEM_DELAY = 10;

    wire [31:0] pend_data;
    inst_rom u_inst_rom (
        .addr(pend_addr),
        .data(pend_data)
    );

    logic [31:0] pend_addr;
    logic [7:0]  pend_cnt;
    logic        pend_valid;
    logic        mem_req_prev;

    always_ff @(posedge clk) begin
        if (reset) begin
            pend_valid   <= 1'b0;
            pend_cnt     <= 8'd0;
            mem_req_prev <= 1'b0;
        end else begin
            mem_req_prev <= imem_req.valid;
            if (imem_req.valid && !mem_req_prev) begin
                pend_addr  <= imem_req.addr;
                pend_cnt   <= MEM_DELAY[7:0];
                pend_valid <= 1'b1;
            end else if (pend_valid) begin
                if (pend_cnt == 8'd1)
                    pend_valid <= 1'b0;
                else
                    pend_cnt <= pend_cnt - 8'd1;
            end
        end
    end

    assign imem_resp.addr_ok = imem_req.valid;
    assign imem_resp.data_ok = pend_valid && (pend_cnt == 8'd1);
    assign imem_resp.data    = pend_data;

    // ==================== D-side: slow response for the load address ======
    // The load at 0x1c000100 misses (delayed data_ok), holding the pipeline
    // (ex_mem_stall) while the beq sits in EX and the fall-through icache
    // refill runs — the fibonacci failure's exact timing.
    localparam int DDELAY = 5;

    logic [31:0] dpend_addr;
    logic [7:0]  dpend_cnt;
    logic        dpend_valid;
    logic        dreq_prev;

    always_ff @(posedge clk) begin
        if (reset) begin
            dpend_valid <= 1'b0;
            dpend_cnt   <= 8'd0;
            dreq_prev   <= 1'b0;
        end else begin
            dreq_prev <= dreq.valid;
            if (dreq.valid && !dreq_prev) begin
                dpend_addr  <= dreq.addr;
                dpend_cnt   <= DDELAY[7:0];
                dpend_valid <= 1'b1;
            end else if (dpend_valid) begin
                if (dpend_cnt == 8'd1)
                    dpend_valid <= 1'b0;
                else
                    dpend_cnt <= dpend_cnt - 8'd1;
            end
        end
    end

    assign dresp.addr_ok   = 1'b1;
    assign dresp.data_ok   = dpend_valid && (dpend_cnt == 8'd1);
    assign dresp.data_last = 1'b1;
    assign dresp.data      = 32'd0;

    assign dcache_in_refill = 1'b0;

endmodule
