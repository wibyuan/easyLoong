`default_nettype none

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

    core u_core (
        .clk,
        .reset(~aresetn),
        .ireq,
        .iresp,
        .dreq,
        .dresp
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
    assign debug0_wb_pc      = 32'd0;
    assign debug0_wb_rf_wen  = 4'd0;
    assign debug0_wb_rf_wnum = 5'd0;
    assign debug0_wb_rf_wdata = 32'd0;
    assign debug0_wb_inst    = 32'd0;

endmodule
