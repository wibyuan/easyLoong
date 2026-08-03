
`include "common.sv"

module core_top #(
    parameter TLBNUM = 32,
    // L2 (backing) dcache geometry — also reported by CPUCFG.0x12: the
    // kernel's cacop flush walk uses it and covers both levels (the L1's
    // ways/sets are a subset of the L2 walk).
    parameter int DCACHE_SETS = 16384,
    parameter int ICACHE_SETS = 256,
    parameter int DCACHE_WAYS = 4,
    parameter int DCACHE_WORDS = 4,
    // L1 dcache geometry (0-cycle hit, LUTRAM tags).
    parameter int L1CACHE_SETS = 256,
    parameter int L1CACHE_WAYS = 2,
    parameter int L1CACHE_WORDS = 4
)(
    input           aclk,
    input           aresetn,
    input  [7:0]    intrpt,

    output [3:0]    arid,
    output [31:0]   araddr,
    output [7:0]    arlen,
    output [2:0]    arsize,
    output [1:0]    arburst,
    output [1:0]    arlock,
    output [3:0]    arcache,
    output [2:0]    arprot,
    output          arvalid,
    input           arready,
    input  [3:0]    rid,
    input  [31:0]   rdata,
    input  [1:0]    rresp,
    input           rlast,
    input           rvalid,
    output          rready,

    output [3:0]    awid,
    output [31:0]   awaddr,
    output [7:0]    awlen,
    output [2:0]    awsize,
    output [1:0]    awburst,
    output [1:0]    awlock,
    output [3:0]    awcache,
    output [2:0]    awprot,
    output          awvalid,
    input           awready,
    output [3:0]    wid,
    output [31:0]   wdata,
    output [3:0]    wstrb,
    output          wlast,
    output          wvalid,
    input           wready,
    input  [3:0]    bid,
    input  [1:0]    bresp,
    input           bvalid,
    output          bready,

    input           break_point,
    input           infor_flag,
    input  [4:0]    reg_num,
    output          ws_valid,
    output [31:0]   rf_rdata,

    output [31:0]   debug0_wb_pc,
    output [3:0]    debug0_wb_rf_wen,
    output [4:0]    debug0_wb_rf_wnum,
    output [31:0]   debug0_wb_rf_wdata,
    output [31:0]   debug0_wb_inst
);

    import la32_common::*;

    logic clk;
    assign clk = aclk;

    ibus_req_t  ireq;
    ibus_resp_t iresp;
    dbus_req_t  dreq;
    dbus_resp_t dresp;
    // L1 <-> L2 interface: the L1's mem port drives the L2's cpu port.
    dbus_req_t  l1_mem_req;
    dbus_resp_t l1_mem_resp;
    dbus_req_t  l2_mem_req;
    dbus_resp_t l2_mem_resp;
    ibus_req_t  icache_mem_req;
    ibus_resp_t icache_mem_resp;


    logic [31:0] core_debug_wb_pc;
    logic [31:0] core_debug_wb_inst;
    logic        core_debug_wb_rf_wen;
    logic [4:0]  core_debug_wb_rf_wnum;
    logic [31:0] core_debug_wb_rf_wdata;

    cacop_req_t core_cacop_req;
    logic       core_cacop_done;
    logic       l1_cacop_done;
    logic       l2_cacop_done;
    logic       icache_cacop_done;
    // The L2's cacop request is gated on the L1's completion: a dirty L1
    // line is first merged into the L2 (the L1's cacop writeback drain),
    // and only then does the L2 write back / invalidate its own line.

    logic [31:0] dcache_data_wb [0:L1CACHE_WAYS-1][0:L1CACHE_WORDS-1];

    logic [63:0] icache_access, icache_hit, icache_miss;
    logic [63:0] icache_wa_clear, icache_s1_accept, icache_cyc;
    logic [63:0] dcache_access, dcache_hit, dcache_miss, dcache_wb;
    logic [63:0] dcache_fast_load, dcache_fast_hum;

    logic dcache_in_refill, icache_in_refill;

    logic [63:0] stall_dcache_refill, stall_icache_refill;
    logic [63:0] stall_load_use, stall_branch_flush;
    logic [63:0] stall_dcache_hit_pipe, stall_icache_hit_pipe;
    logic [63:0] stall_other;

    core #(.ICACHE_SETS(ICACHE_SETS), .DCACHE_SETS(DCACHE_SETS),
           .DCACHE_WAYS(DCACHE_WAYS), .DCACHE_WORDS(DCACHE_WORDS),
           .L1CACHE_WAYS(L1CACHE_WAYS), .L1CACHE_WORDS(L1CACHE_WORDS)) u_core (
        .clk,
        .reset(~aresetn),
        .ireq,
        .iresp,
        .dreq,
        .dresp,
        .dcache_data_wb(dcache_data_wb),
        .cacop_req(core_cacop_req),
        .cacop_done(core_cacop_done),
        .dcache_in_refill(dcache_in_refill),
        .icache_in_refill(icache_in_refill),
        .debug_wb_pc      (core_debug_wb_pc),
        .debug_wb_inst    (core_debug_wb_inst),
        .debug_wb_rf_wen  (core_debug_wb_rf_wen),
        .debug_wb_rf_wnum (core_debug_wb_rf_wnum),
        .debug_wb_rf_wdata(core_debug_wb_rf_wdata),
        .stall_dcache_refill(stall_dcache_refill),
        .stall_icache_refill(stall_icache_refill),
        .stall_load_use(stall_load_use),
        .stall_branch_flush(stall_branch_flush),
        .stall_dcache_hit_pipe(stall_dcache_hit_pipe),
        .stall_icache_hit_pipe(stall_icache_hit_pipe),
        .stall_other(stall_other)
    );

    // ==================== No-dcache bypass (wip/no-dcache) ============
    // The LSU's requests go straight to the AXI arbiter: with the direct
    // async-SRAM path at a fixed 2-cycle access, the L1/L2 hierarchy is
    // bypassed entirely (all accesses are uncached pass-throughs).
    assign l2_mem_req = dreq;
    assign dresp      = l2_mem_resp;
    assign dresp.hit      = 1'b0;
    assign dresp.hit_way  = 1'b0;
    // No dcache to flush: cacop codes 0x01/0x09 complete instantly; the
    // icache's 0x00 invalidation keeps its own completion handshake.
    assign core_cacop_done = (core_cacop_req.valid && core_cacop_req.code[2:0] == 3'd0)
        ? icache_cacop_done : 1'b1;
    assign dcache_in_refill = 1'b0;
    assign dcache_access    = 64'd0;
    assign dcache_hit       = 64'd0;
    assign dcache_miss      = 64'd0;
    assign dcache_wb        = 64'd0;
    assign dcache_fast_load = 64'd0;
    assign dcache_fast_hum  = 64'd0;
    for (genvar gw = 0; gw < L1CACHE_WAYS; gw++)
        for (genvar gw2 = 0; gw2 < L1CACHE_WORDS; gw2++)
            assign dcache_data_wb[gw][gw2] = 32'd0;

    icache #(.NR_SETS(ICACHE_SETS)) u_icache (
        .clk,
        .reset(~aresetn),
        .inv_all(1'b0),
        .cpu_req(ireq),
        .cpu_resp(iresp),
        .mem_req(icache_mem_req),
        .mem_resp(icache_mem_resp),
        .cacop_req(core_cacop_req),
        .cacop_done(icache_cacop_done),
        .perf_access(icache_access),
        .perf_hit(icache_hit),
        .perf_miss(icache_miss),
        .perf_wa_clear(icache_wa_clear),
        .perf_s1_accept(icache_s1_accept),
        .perf_cyc(icache_cyc),
        .in_refill(icache_in_refill)
    );

    // dcache cacop (0x08/0x09/...): retire on the L2's completion.  The
    // L2's cacop is gated on the L1's completion, so by the time the L2
    // finishes, the L1's dirty line has already been merged into the L2
    // and the L2's writeback to memory is up to date.  The L2's done is a
    // pulse at its completion while the cacop is still stalled in EX
    // (done=0 until then), so the instruction retires exactly then and
    // the walk proceeds strictly level-by-level (the L2 is always idle
    // at each cacop boundary, no request can be lost).
    // Other codes retire immediately (icache ibar/cacop handled by the
    // icache, which pulses done on its own).  Superseded by the no-dcache
    // bypass assign above.

    axibus_arbiter u_arbiter (
        .clk,
        .resetn(aresetn),
        .ireq(icache_mem_req),
        .iresp(icache_mem_resp),
        .dreq(l2_mem_req),
        .dresp(l2_mem_resp),
        .arid,     .araddr,   .arlen,   .arsize, .arburst,
        .arlock,   .arcache,  .arprot,  .arvalid, .arready,
        .rid,      .rdata,    .rresp,   .rlast,   .rvalid, .rready,
        .awid,     .awaddr,   .awlen,   .awsize, .awburst,
        .awlock,   .awcache,  .awprot,  .awvalid, .awready,
        .wid,      .wdata_out(wdata), .wstrb,   .wlast,   .wvalid, .wready,
        .bid,      .bresp,    .bvalid,  .bready
    );

    assign ws_valid = 1'b0;
    assign rf_rdata = 32'd0;
    assign debug0_wb_pc      = core_debug_wb_pc;
    assign debug0_wb_rf_wen  = {3'd0, core_debug_wb_rf_wen};
    assign debug0_wb_rf_wnum = core_debug_wb_rf_wnum;
    assign debug0_wb_rf_wdata = core_debug_wb_rf_wdata;
    assign debug0_wb_inst    = core_debug_wb_inst;

`ifdef VERILATOR
    DifftestCacheState u_difftest_cache (
        .clock(clk),
        .icache_access(icache_access),
        .icache_hit(icache_hit),
        .icache_miss(icache_miss),
        .icache_wa_clear(icache_wa_clear),
        .icache_s1_accept(icache_s1_accept),
        .icache_cyc(icache_cyc),
        .dcache_access(dcache_access),
        .dcache_hit(dcache_hit),
        .dcache_miss(dcache_miss),
        .dcache_writeback(dcache_wb),
        .dcache_fast_load(dcache_fast_load),
        .dcache_fast_hum(dcache_fast_hum)
    );
`endif

endmodule
