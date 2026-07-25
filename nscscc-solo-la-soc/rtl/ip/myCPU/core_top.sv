
`include "common.sv"

module core_top #(
    parameter TLBNUM = 32
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
    dbus_req_t  dreq_mem;
    dbus_resp_t dresp_mem;
    ibus_req_t  icache_mem_req;
    ibus_resp_t icache_mem_resp;

    logic [31:0] core_debug_wb_pc;
    logic [31:0] core_debug_wb_inst;
    logic        core_debug_wb_rf_wen;
    logic [4:0]  core_debug_wb_rf_wnum;
    logic [31:0] core_debug_wb_rf_wdata;

    cacop_req_t core_cacop_req;
    logic       core_cacop_done;
    logic       dcache_cacop_done;
    logic       icache_cacop_done;

    logic [63:0] icache_access, icache_hit, icache_miss;
    logic [63:0] icache_wa_clear, icache_s1_accept, icache_cyc;
    logic [63:0] dcache_access, dcache_hit, dcache_miss, dcache_wb;

    core u_core (
        .clk,
        .reset(~aresetn),
        .ireq,
        .iresp,
        .dreq,
        .dresp,
        .cacop_req(core_cacop_req),
        .cacop_done(core_cacop_done),
        .debug_wb_pc      (core_debug_wb_pc),
        .debug_wb_inst    (core_debug_wb_inst),
        .debug_wb_rf_wen  (core_debug_wb_rf_wen),
        .debug_wb_rf_wnum (core_debug_wb_rf_wnum),
        .debug_wb_rf_wdata(core_debug_wb_rf_wdata)
    );

    dcache u_dcache (
        .clk,
        .reset(~aresetn),
        .cpu_req(dreq),
        .cpu_resp(dresp),
        .mem_req(dreq_mem),
        .mem_resp(dresp_mem),
        .cacop_req(core_cacop_req),
        .cacop_done(dcache_cacop_done),
        .perf_access(dcache_access),
        .perf_hit(dcache_hit),
        .perf_miss(dcache_miss),
        .perf_writeback(dcache_wb)
    );

    icache u_icache (
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
        .perf_cyc(icache_cyc)
    );

    assign core_cacop_done = dcache_cacop_done || icache_cacop_done ||
        (core_cacop_req.valid && core_cacop_req.code[2:0] != 3'd0 && core_cacop_req.code[2:0] != 3'd1);

    axibus_arbiter u_arbiter (
        .clk,
        .resetn(aresetn),
        .ireq(icache_mem_req),
        .iresp(icache_mem_resp),
        .dreq(dreq_mem),
        .dresp(dresp_mem),
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
        .dcache_writeback(dcache_wb)
    );
`endif

endmodule
