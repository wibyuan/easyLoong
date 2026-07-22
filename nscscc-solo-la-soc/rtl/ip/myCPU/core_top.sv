
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

    logic [31:0] core_debug_wb_pc;
    logic [31:0] core_debug_wb_inst;
    logic        core_debug_wb_rf_wen;
    logic [4:0]  core_debug_wb_rf_wnum;
    logic [31:0] core_debug_wb_rf_wdata;

    core u_core (
        .clk,
        .reset(~aresetn),
        .ireq,
        .iresp,
        .dreq,
        .dresp,
        .debug_wb_pc      (core_debug_wb_pc),
        .debug_wb_inst    (core_debug_wb_inst),
        .debug_wb_rf_wen  (core_debug_wb_rf_wen),
        .debug_wb_rf_wnum (core_debug_wb_rf_wnum),
        .debug_wb_rf_wdata(core_debug_wb_rf_wdata)
    );

    axibus_arbiter u_arbiter (
        .clk,
        .resetn(aresetn),
        .ireq,
        .iresp,
        .dreq,
        .dresp,
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

endmodule
