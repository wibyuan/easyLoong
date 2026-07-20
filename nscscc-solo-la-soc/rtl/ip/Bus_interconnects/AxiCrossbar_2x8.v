// Generator : SpinalHDL v1.10.1    git head : 2527c7c6b0fb0f95e5e1a5722a0be732b364ce43
// Component : AxiCrossbar_2x8


module AxiCrossbar_2x8 (
  input  wire          axiIn_0_awvalid,
  output wire          axiIn_0_awready,
  input  wire [31:0]   axiIn_0_awaddr,
  input  wire [3:0]    axiIn_0_awid,
  input  wire [7:0]    axiIn_0_awlen,
  input  wire [2:0]    axiIn_0_awsize,
  input  wire [1:0]    axiIn_0_awburst,
  input  wire [0:0]    axiIn_0_awlock,
  input  wire [3:0]    axiIn_0_awcache,
  input  wire [2:0]    axiIn_0_awprot,
  input  wire          axiIn_0_wvalid,
  output wire          axiIn_0_wready,
  input  wire [31:0]   axiIn_0_wdata,
  input  wire [3:0]    axiIn_0_wstrb,
  input  wire          axiIn_0_wlast,
  output wire          axiIn_0_bvalid,
  input  wire          axiIn_0_bready,
  output wire [3:0]    axiIn_0_bid,
  output wire [1:0]    axiIn_0_bresp,
  input  wire          axiIn_0_arvalid,
  output wire          axiIn_0_arready,
  input  wire [31:0]   axiIn_0_araddr,
  input  wire [3:0]    axiIn_0_arid,
  input  wire [7:0]    axiIn_0_arlen,
  input  wire [2:0]    axiIn_0_arsize,
  input  wire [1:0]    axiIn_0_arburst,
  input  wire [0:0]    axiIn_0_arlock,
  input  wire [3:0]    axiIn_0_arcache,
  input  wire [2:0]    axiIn_0_arprot,
  output wire          axiIn_0_rvalid,
  input  wire          axiIn_0_rready,
  output wire [31:0]   axiIn_0_rdata,
  output wire [3:0]    axiIn_0_rid,
  output wire [1:0]    axiIn_0_rresp,
  output wire          axiIn_0_rlast,
  input  wire          axiIn_1_awvalid,
  output wire          axiIn_1_awready,
  input  wire [31:0]   axiIn_1_awaddr,
  input  wire [3:0]    axiIn_1_awid,
  input  wire [7:0]    axiIn_1_awlen,
  input  wire [2:0]    axiIn_1_awsize,
  input  wire [1:0]    axiIn_1_awburst,
  input  wire [0:0]    axiIn_1_awlock,
  input  wire [3:0]    axiIn_1_awcache,
  input  wire [2:0]    axiIn_1_awprot,
  input  wire          axiIn_1_wvalid,
  output wire          axiIn_1_wready,
  input  wire [31:0]   axiIn_1_wdata,
  input  wire [3:0]    axiIn_1_wstrb,
  input  wire          axiIn_1_wlast,
  output wire          axiIn_1_bvalid,
  input  wire          axiIn_1_bready,
  output wire [3:0]    axiIn_1_bid,
  output wire [1:0]    axiIn_1_bresp,
  input  wire          axiIn_1_arvalid,
  output wire          axiIn_1_arready,
  input  wire [31:0]   axiIn_1_araddr,
  input  wire [3:0]    axiIn_1_arid,
  input  wire [7:0]    axiIn_1_arlen,
  input  wire [2:0]    axiIn_1_arsize,
  input  wire [1:0]    axiIn_1_arburst,
  input  wire [0:0]    axiIn_1_arlock,
  input  wire [3:0]    axiIn_1_arcache,
  input  wire [2:0]    axiIn_1_arprot,
  output wire          axiIn_1_rvalid,
  input  wire          axiIn_1_rready,
  output wire [31:0]   axiIn_1_rdata,
  output wire [3:0]    axiIn_1_rid,
  output wire [1:0]    axiIn_1_rresp,
  output wire          axiIn_1_rlast,
  output wire          axiOut_0_awvalid,
  input  wire          axiOut_0_awready,
  output wire [31:0]   axiOut_0_awaddr,
  output wire [4:0]    axiOut_0_awid,
  output wire [7:0]    axiOut_0_awlen,
  output wire [2:0]    axiOut_0_awsize,
  output wire [1:0]    axiOut_0_awburst,
  output wire [0:0]    axiOut_0_awlock,
  output wire [3:0]    axiOut_0_awcache,
  output wire [2:0]    axiOut_0_awprot,
  output wire          axiOut_0_wvalid,
  input  wire          axiOut_0_wready,
  output wire [31:0]   axiOut_0_wdata,
  output wire [3:0]    axiOut_0_wstrb,
  output wire          axiOut_0_wlast,
  input  wire          axiOut_0_bvalid,
  output wire          axiOut_0_bready,
  input  wire [4:0]    axiOut_0_bid,
  input  wire [1:0]    axiOut_0_bresp,
  output wire          axiOut_0_arvalid,
  input  wire          axiOut_0_arready,
  output wire [31:0]   axiOut_0_araddr,
  output wire [4:0]    axiOut_0_arid,
  output wire [7:0]    axiOut_0_arlen,
  output wire [2:0]    axiOut_0_arsize,
  output wire [1:0]    axiOut_0_arburst,
  output wire [0:0]    axiOut_0_arlock,
  output wire [3:0]    axiOut_0_arcache,
  output wire [2:0]    axiOut_0_arprot,
  input  wire          axiOut_0_rvalid,
  output wire          axiOut_0_rready,
  input  wire [31:0]   axiOut_0_rdata,
  input  wire [4:0]    axiOut_0_rid,
  input  wire [1:0]    axiOut_0_rresp,
  input  wire          axiOut_0_rlast,
  output wire          axiOut_1_awvalid,
  input  wire          axiOut_1_awready,
  output wire [31:0]   axiOut_1_awaddr,
  output wire [4:0]    axiOut_1_awid,
  output wire [7:0]    axiOut_1_awlen,
  output wire [2:0]    axiOut_1_awsize,
  output wire [1:0]    axiOut_1_awburst,
  output wire [0:0]    axiOut_1_awlock,
  output wire [3:0]    axiOut_1_awcache,
  output wire [2:0]    axiOut_1_awprot,
  output wire          axiOut_1_wvalid,
  input  wire          axiOut_1_wready,
  output wire [31:0]   axiOut_1_wdata,
  output wire [3:0]    axiOut_1_wstrb,
  output wire          axiOut_1_wlast,
  input  wire          axiOut_1_bvalid,
  output wire          axiOut_1_bready,
  input  wire [4:0]    axiOut_1_bid,
  input  wire [1:0]    axiOut_1_bresp,
  output wire          axiOut_1_arvalid,
  input  wire          axiOut_1_arready,
  output wire [31:0]   axiOut_1_araddr,
  output wire [4:0]    axiOut_1_arid,
  output wire [7:0]    axiOut_1_arlen,
  output wire [2:0]    axiOut_1_arsize,
  output wire [1:0]    axiOut_1_arburst,
  output wire [0:0]    axiOut_1_arlock,
  output wire [3:0]    axiOut_1_arcache,
  output wire [2:0]    axiOut_1_arprot,
  input  wire          axiOut_1_rvalid,
  output wire          axiOut_1_rready,
  input  wire [31:0]   axiOut_1_rdata,
  input  wire [4:0]    axiOut_1_rid,
  input  wire [1:0]    axiOut_1_rresp,
  input  wire          axiOut_1_rlast,
  output wire          axiOut_2_awvalid,
  input  wire          axiOut_2_awready,
  output wire [31:0]   axiOut_2_awaddr,
  output wire [4:0]    axiOut_2_awid,
  output wire [7:0]    axiOut_2_awlen,
  output wire [2:0]    axiOut_2_awsize,
  output wire [1:0]    axiOut_2_awburst,
  output wire [0:0]    axiOut_2_awlock,
  output wire [3:0]    axiOut_2_awcache,
  output wire [2:0]    axiOut_2_awprot,
  output wire          axiOut_2_wvalid,
  input  wire          axiOut_2_wready,
  output wire [31:0]   axiOut_2_wdata,
  output wire [3:0]    axiOut_2_wstrb,
  output wire          axiOut_2_wlast,
  input  wire          axiOut_2_bvalid,
  output wire          axiOut_2_bready,
  input  wire [4:0]    axiOut_2_bid,
  input  wire [1:0]    axiOut_2_bresp,
  output wire          axiOut_2_arvalid,
  input  wire          axiOut_2_arready,
  output wire [31:0]   axiOut_2_araddr,
  output wire [4:0]    axiOut_2_arid,
  output wire [7:0]    axiOut_2_arlen,
  output wire [2:0]    axiOut_2_arsize,
  output wire [1:0]    axiOut_2_arburst,
  output wire [0:0]    axiOut_2_arlock,
  output wire [3:0]    axiOut_2_arcache,
  output wire [2:0]    axiOut_2_arprot,
  input  wire          axiOut_2_rvalid,
  output wire          axiOut_2_rready,
  input  wire [31:0]   axiOut_2_rdata,
  input  wire [4:0]    axiOut_2_rid,
  input  wire [1:0]    axiOut_2_rresp,
  input  wire          axiOut_2_rlast,
  output wire          axiOut_3_awvalid,
  input  wire          axiOut_3_awready,
  output wire [31:0]   axiOut_3_awaddr,
  output wire [4:0]    axiOut_3_awid,
  output wire [7:0]    axiOut_3_awlen,
  output wire [2:0]    axiOut_3_awsize,
  output wire [1:0]    axiOut_3_awburst,
  output wire [0:0]    axiOut_3_awlock,
  output wire [3:0]    axiOut_3_awcache,
  output wire [2:0]    axiOut_3_awprot,
  output wire          axiOut_3_wvalid,
  input  wire          axiOut_3_wready,
  output wire [31:0]   axiOut_3_wdata,
  output wire [3:0]    axiOut_3_wstrb,
  output wire          axiOut_3_wlast,
  input  wire          axiOut_3_bvalid,
  output wire          axiOut_3_bready,
  input  wire [4:0]    axiOut_3_bid,
  input  wire [1:0]    axiOut_3_bresp,
  output wire          axiOut_3_arvalid,
  input  wire          axiOut_3_arready,
  output wire [31:0]   axiOut_3_araddr,
  output wire [4:0]    axiOut_3_arid,
  output wire [7:0]    axiOut_3_arlen,
  output wire [2:0]    axiOut_3_arsize,
  output wire [1:0]    axiOut_3_arburst,
  output wire [0:0]    axiOut_3_arlock,
  output wire [3:0]    axiOut_3_arcache,
  output wire [2:0]    axiOut_3_arprot,
  input  wire          axiOut_3_rvalid,
  output wire          axiOut_3_rready,
  input  wire [31:0]   axiOut_3_rdata,
  input  wire [4:0]    axiOut_3_rid,
  input  wire [1:0]    axiOut_3_rresp,
  input  wire          axiOut_3_rlast,
  output wire          axiOut_4_awvalid,
  input  wire          axiOut_4_awready,
  output wire [31:0]   axiOut_4_awaddr,
  output wire [4:0]    axiOut_4_awid,
  output wire [7:0]    axiOut_4_awlen,
  output wire [2:0]    axiOut_4_awsize,
  output wire [1:0]    axiOut_4_awburst,
  output wire [0:0]    axiOut_4_awlock,
  output wire [3:0]    axiOut_4_awcache,
  output wire [2:0]    axiOut_4_awprot,
  output wire          axiOut_4_wvalid,
  input  wire          axiOut_4_wready,
  output wire [31:0]   axiOut_4_wdata,
  output wire [3:0]    axiOut_4_wstrb,
  output wire          axiOut_4_wlast,
  input  wire          axiOut_4_bvalid,
  output wire          axiOut_4_bready,
  input  wire [4:0]    axiOut_4_bid,
  input  wire [1:0]    axiOut_4_bresp,
  output wire          axiOut_4_arvalid,
  input  wire          axiOut_4_arready,
  output wire [31:0]   axiOut_4_araddr,
  output wire [4:0]    axiOut_4_arid,
  output wire [7:0]    axiOut_4_arlen,
  output wire [2:0]    axiOut_4_arsize,
  output wire [1:0]    axiOut_4_arburst,
  output wire [0:0]    axiOut_4_arlock,
  output wire [3:0]    axiOut_4_arcache,
  output wire [2:0]    axiOut_4_arprot,
  input  wire          axiOut_4_rvalid,
  output wire          axiOut_4_rready,
  input  wire [31:0]   axiOut_4_rdata,
  input  wire [4:0]    axiOut_4_rid,
  input  wire [1:0]    axiOut_4_rresp,
  input  wire          axiOut_4_rlast,
  output wire          axiOut_5_awvalid,
  input  wire          axiOut_5_awready,
  output wire [31:0]   axiOut_5_awaddr,
  output wire [4:0]    axiOut_5_awid,
  output wire [7:0]    axiOut_5_awlen,
  output wire [2:0]    axiOut_5_awsize,
  output wire [1:0]    axiOut_5_awburst,
  output wire [0:0]    axiOut_5_awlock,
  output wire [3:0]    axiOut_5_awcache,
  output wire [2:0]    axiOut_5_awprot,
  output wire          axiOut_5_wvalid,
  input  wire          axiOut_5_wready,
  output wire [31:0]   axiOut_5_wdata,
  output wire [3:0]    axiOut_5_wstrb,
  output wire          axiOut_5_wlast,
  input  wire          axiOut_5_bvalid,
  output wire          axiOut_5_bready,
  input  wire [4:0]    axiOut_5_bid,
  input  wire [1:0]    axiOut_5_bresp,
  output wire          axiOut_5_arvalid,
  input  wire          axiOut_5_arready,
  output wire [31:0]   axiOut_5_araddr,
  output wire [4:0]    axiOut_5_arid,
  output wire [7:0]    axiOut_5_arlen,
  output wire [2:0]    axiOut_5_arsize,
  output wire [1:0]    axiOut_5_arburst,
  output wire [0:0]    axiOut_5_arlock,
  output wire [3:0]    axiOut_5_arcache,
  output wire [2:0]    axiOut_5_arprot,
  input  wire          axiOut_5_rvalid,
  output wire          axiOut_5_rready,
  input  wire [31:0]   axiOut_5_rdata,
  input  wire [4:0]    axiOut_5_rid,
  input  wire [1:0]    axiOut_5_rresp,
  input  wire          axiOut_5_rlast,
  output wire          axiOut_6_awvalid,
  input  wire          axiOut_6_awready,
  output wire [31:0]   axiOut_6_awaddr,
  output wire [4:0]    axiOut_6_awid,
  output wire [7:0]    axiOut_6_awlen,
  output wire [2:0]    axiOut_6_awsize,
  output wire [1:0]    axiOut_6_awburst,
  output wire [0:0]    axiOut_6_awlock,
  output wire [3:0]    axiOut_6_awcache,
  output wire [2:0]    axiOut_6_awprot,
  output wire          axiOut_6_wvalid,
  input  wire          axiOut_6_wready,
  output wire [31:0]   axiOut_6_wdata,
  output wire [3:0]    axiOut_6_wstrb,
  output wire          axiOut_6_wlast,
  input  wire          axiOut_6_bvalid,
  output wire          axiOut_6_bready,
  input  wire [4:0]    axiOut_6_bid,
  input  wire [1:0]    axiOut_6_bresp,
  output wire          axiOut_6_arvalid,
  input  wire          axiOut_6_arready,
  output wire [31:0]   axiOut_6_araddr,
  output wire [4:0]    axiOut_6_arid,
  output wire [7:0]    axiOut_6_arlen,
  output wire [2:0]    axiOut_6_arsize,
  output wire [1:0]    axiOut_6_arburst,
  output wire [0:0]    axiOut_6_arlock,
  output wire [3:0]    axiOut_6_arcache,
  output wire [2:0]    axiOut_6_arprot,
  input  wire          axiOut_6_rvalid,
  output wire          axiOut_6_rready,
  input  wire [31:0]   axiOut_6_rdata,
  input  wire [4:0]    axiOut_6_rid,
  input  wire [1:0]    axiOut_6_rresp,
  input  wire          axiOut_6_rlast,
  output wire          axiOut_7_awvalid,
  input  wire          axiOut_7_awready,
  output wire [31:0]   axiOut_7_awaddr,
  output wire [4:0]    axiOut_7_awid,
  output wire [7:0]    axiOut_7_awlen,
  output wire [2:0]    axiOut_7_awsize,
  output wire [1:0]    axiOut_7_awburst,
  output wire [0:0]    axiOut_7_awlock,
  output wire [3:0]    axiOut_7_awcache,
  output wire [2:0]    axiOut_7_awprot,
  output wire          axiOut_7_wvalid,
  input  wire          axiOut_7_wready,
  output wire [31:0]   axiOut_7_wdata,
  output wire [3:0]    axiOut_7_wstrb,
  output wire          axiOut_7_wlast,
  input  wire          axiOut_7_bvalid,
  output wire          axiOut_7_bready,
  input  wire [4:0]    axiOut_7_bid,
  input  wire [1:0]    axiOut_7_bresp,
  output wire          axiOut_7_arvalid,
  input  wire          axiOut_7_arready,
  output wire [31:0]   axiOut_7_araddr,
  output wire [4:0]    axiOut_7_arid,
  output wire [7:0]    axiOut_7_arlen,
  output wire [2:0]    axiOut_7_arsize,
  output wire [1:0]    axiOut_7_arburst,
  output wire [0:0]    axiOut_7_arlock,
  output wire [3:0]    axiOut_7_arcache,
  output wire [2:0]    axiOut_7_arprot,
  input  wire          axiOut_7_rvalid,
  output wire          axiOut_7_rready,
  input  wire [31:0]   axiOut_7_rdata,
  input  wire [4:0]    axiOut_7_rid,
  input  wire [1:0]    axiOut_7_rresp,
  input  wire          axiOut_7_rlast,
  input  wire          clk,
  input  wire          resetn
);

  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_2_r_payload_id;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_3_r_payload_id;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_4_r_payload_id;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_5_r_payload_id;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_2_b_payload_id;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_3_b_payload_id;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_4_b_payload_id;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_5_b_payload_id;
  wire                axiIn_0_readOnly_decoder_io_input_ar_ready;
  wire                axiIn_0_readOnly_decoder_io_input_r_valid;
  wire       [31:0]   axiIn_0_readOnly_decoder_io_input_r_payload_data;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_input_r_payload_id;
  wire       [1:0]    axiIn_0_readOnly_decoder_io_input_r_payload_resp;
  wire                axiIn_0_readOnly_decoder_io_input_r_payload_last;
  wire                axiIn_0_readOnly_decoder_io_outputs_0_ar_valid;
  wire       [31:0]   axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_addr;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_id;
  wire       [7:0]    axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_len;
  wire       [2:0]    axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_size;
  wire       [1:0]    axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_burst;
  wire       [0:0]    axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_lock;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_cache;
  wire       [2:0]    axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_prot;
  wire                axiIn_0_readOnly_decoder_io_outputs_0_r_ready;
  wire                axiIn_0_readOnly_decoder_io_outputs_1_ar_valid;
  wire       [31:0]   axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_addr;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_id;
  wire       [7:0]    axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_len;
  wire       [2:0]    axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_size;
  wire       [1:0]    axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_burst;
  wire       [0:0]    axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_lock;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_cache;
  wire       [2:0]    axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_prot;
  wire                axiIn_0_readOnly_decoder_io_outputs_1_r_ready;
  wire                axiIn_0_readOnly_decoder_io_outputs_2_ar_valid;
  wire       [31:0]   axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_addr;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_id;
  wire       [7:0]    axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_len;
  wire       [2:0]    axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_size;
  wire       [1:0]    axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_burst;
  wire       [0:0]    axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_lock;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_cache;
  wire       [2:0]    axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_prot;
  wire                axiIn_0_readOnly_decoder_io_outputs_2_r_ready;
  wire                axiIn_0_readOnly_decoder_io_outputs_3_ar_valid;
  wire       [31:0]   axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_addr;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_id;
  wire       [7:0]    axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_len;
  wire       [2:0]    axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_size;
  wire       [1:0]    axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_burst;
  wire       [0:0]    axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_lock;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_cache;
  wire       [2:0]    axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_prot;
  wire                axiIn_0_readOnly_decoder_io_outputs_3_r_ready;
  wire                axiIn_0_readOnly_decoder_io_outputs_4_ar_valid;
  wire       [31:0]   axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_addr;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_id;
  wire       [7:0]    axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_len;
  wire       [2:0]    axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_size;
  wire       [1:0]    axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_burst;
  wire       [0:0]    axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_lock;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_cache;
  wire       [2:0]    axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_prot;
  wire                axiIn_0_readOnly_decoder_io_outputs_4_r_ready;
  wire                axiIn_0_readOnly_decoder_io_outputs_5_ar_valid;
  wire       [31:0]   axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_addr;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_id;
  wire       [7:0]    axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_len;
  wire       [2:0]    axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_size;
  wire       [1:0]    axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_burst;
  wire       [0:0]    axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_lock;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_cache;
  wire       [2:0]    axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_prot;
  wire                axiIn_0_readOnly_decoder_io_outputs_5_r_ready;
  wire                axiIn_0_readOnly_decoder_io_outputs_6_ar_valid;
  wire       [31:0]   axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_addr;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_id;
  wire       [7:0]    axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_len;
  wire       [2:0]    axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_size;
  wire       [1:0]    axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_burst;
  wire       [0:0]    axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_lock;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_cache;
  wire       [2:0]    axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_prot;
  wire                axiIn_0_readOnly_decoder_io_outputs_6_r_ready;
  wire                axiIn_0_readOnly_decoder_io_outputs_7_ar_valid;
  wire       [31:0]   axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_addr;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_id;
  wire       [7:0]    axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_len;
  wire       [2:0]    axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_size;
  wire       [1:0]    axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_burst;
  wire       [0:0]    axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_lock;
  wire       [3:0]    axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_cache;
  wire       [2:0]    axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_prot;
  wire                axiIn_0_readOnly_decoder_io_outputs_7_r_ready;
  wire                axiIn_0_writeOnly_decoder_io_input_aw_ready;
  wire                axiIn_0_writeOnly_decoder_io_input_w_ready;
  wire                axiIn_0_writeOnly_decoder_io_input_b_valid;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_input_b_payload_id;
  wire       [1:0]    axiIn_0_writeOnly_decoder_io_input_b_payload_resp;
  wire                axiIn_0_writeOnly_decoder_io_outputs_0_aw_valid;
  wire       [31:0]   axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_addr;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_id;
  wire       [7:0]    axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_len;
  wire       [2:0]    axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_size;
  wire       [1:0]    axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_burst;
  wire       [0:0]    axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_lock;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_cache;
  wire       [2:0]    axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_prot;
  wire                axiIn_0_writeOnly_decoder_io_outputs_0_w_valid;
  wire       [31:0]   axiIn_0_writeOnly_decoder_io_outputs_0_w_payload_data;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_0_w_payload_strb;
  wire                axiIn_0_writeOnly_decoder_io_outputs_0_w_payload_last;
  wire                axiIn_0_writeOnly_decoder_io_outputs_0_b_ready;
  wire                axiIn_0_writeOnly_decoder_io_outputs_1_aw_valid;
  wire       [31:0]   axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_addr;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_id;
  wire       [7:0]    axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_len;
  wire       [2:0]    axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_size;
  wire       [1:0]    axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_burst;
  wire       [0:0]    axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_lock;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_cache;
  wire       [2:0]    axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_prot;
  wire                axiIn_0_writeOnly_decoder_io_outputs_1_w_valid;
  wire       [31:0]   axiIn_0_writeOnly_decoder_io_outputs_1_w_payload_data;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_1_w_payload_strb;
  wire                axiIn_0_writeOnly_decoder_io_outputs_1_w_payload_last;
  wire                axiIn_0_writeOnly_decoder_io_outputs_1_b_ready;
  wire                axiIn_0_writeOnly_decoder_io_outputs_2_aw_valid;
  wire       [31:0]   axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_addr;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_id;
  wire       [7:0]    axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_len;
  wire       [2:0]    axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_size;
  wire       [1:0]    axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_burst;
  wire       [0:0]    axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_lock;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_cache;
  wire       [2:0]    axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_prot;
  wire                axiIn_0_writeOnly_decoder_io_outputs_2_w_valid;
  wire       [31:0]   axiIn_0_writeOnly_decoder_io_outputs_2_w_payload_data;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_2_w_payload_strb;
  wire                axiIn_0_writeOnly_decoder_io_outputs_2_w_payload_last;
  wire                axiIn_0_writeOnly_decoder_io_outputs_2_b_ready;
  wire                axiIn_0_writeOnly_decoder_io_outputs_3_aw_valid;
  wire       [31:0]   axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_addr;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_id;
  wire       [7:0]    axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_len;
  wire       [2:0]    axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_size;
  wire       [1:0]    axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_burst;
  wire       [0:0]    axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_lock;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_cache;
  wire       [2:0]    axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_prot;
  wire                axiIn_0_writeOnly_decoder_io_outputs_3_w_valid;
  wire       [31:0]   axiIn_0_writeOnly_decoder_io_outputs_3_w_payload_data;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_3_w_payload_strb;
  wire                axiIn_0_writeOnly_decoder_io_outputs_3_w_payload_last;
  wire                axiIn_0_writeOnly_decoder_io_outputs_3_b_ready;
  wire                axiIn_0_writeOnly_decoder_io_outputs_4_aw_valid;
  wire       [31:0]   axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_addr;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_id;
  wire       [7:0]    axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_len;
  wire       [2:0]    axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_size;
  wire       [1:0]    axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_burst;
  wire       [0:0]    axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_lock;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_cache;
  wire       [2:0]    axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_prot;
  wire                axiIn_0_writeOnly_decoder_io_outputs_4_w_valid;
  wire       [31:0]   axiIn_0_writeOnly_decoder_io_outputs_4_w_payload_data;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_4_w_payload_strb;
  wire                axiIn_0_writeOnly_decoder_io_outputs_4_w_payload_last;
  wire                axiIn_0_writeOnly_decoder_io_outputs_4_b_ready;
  wire                axiIn_0_writeOnly_decoder_io_outputs_5_aw_valid;
  wire       [31:0]   axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_addr;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_id;
  wire       [7:0]    axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_len;
  wire       [2:0]    axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_size;
  wire       [1:0]    axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_burst;
  wire       [0:0]    axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_lock;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_cache;
  wire       [2:0]    axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_prot;
  wire                axiIn_0_writeOnly_decoder_io_outputs_5_w_valid;
  wire       [31:0]   axiIn_0_writeOnly_decoder_io_outputs_5_w_payload_data;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_5_w_payload_strb;
  wire                axiIn_0_writeOnly_decoder_io_outputs_5_w_payload_last;
  wire                axiIn_0_writeOnly_decoder_io_outputs_5_b_ready;
  wire                axiIn_0_writeOnly_decoder_io_outputs_6_aw_valid;
  wire       [31:0]   axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_addr;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_id;
  wire       [7:0]    axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_len;
  wire       [2:0]    axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_size;
  wire       [1:0]    axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_burst;
  wire       [0:0]    axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_lock;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_cache;
  wire       [2:0]    axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_prot;
  wire                axiIn_0_writeOnly_decoder_io_outputs_6_w_valid;
  wire       [31:0]   axiIn_0_writeOnly_decoder_io_outputs_6_w_payload_data;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_6_w_payload_strb;
  wire                axiIn_0_writeOnly_decoder_io_outputs_6_w_payload_last;
  wire                axiIn_0_writeOnly_decoder_io_outputs_6_b_ready;
  wire                axiIn_0_writeOnly_decoder_io_outputs_7_aw_valid;
  wire       [31:0]   axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_addr;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_id;
  wire       [7:0]    axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_len;
  wire       [2:0]    axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_size;
  wire       [1:0]    axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_burst;
  wire       [0:0]    axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_lock;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_cache;
  wire       [2:0]    axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_prot;
  wire                axiIn_0_writeOnly_decoder_io_outputs_7_w_valid;
  wire       [31:0]   axiIn_0_writeOnly_decoder_io_outputs_7_w_payload_data;
  wire       [3:0]    axiIn_0_writeOnly_decoder_io_outputs_7_w_payload_strb;
  wire                axiIn_0_writeOnly_decoder_io_outputs_7_w_payload_last;
  wire                axiIn_0_writeOnly_decoder_io_outputs_7_b_ready;
  wire                axiIn_1_readOnly_decoder_io_input_ar_ready;
  wire                axiIn_1_readOnly_decoder_io_input_r_valid;
  wire       [31:0]   axiIn_1_readOnly_decoder_io_input_r_payload_data;
  wire       [3:0]    axiIn_1_readOnly_decoder_io_input_r_payload_id;
  wire       [1:0]    axiIn_1_readOnly_decoder_io_input_r_payload_resp;
  wire                axiIn_1_readOnly_decoder_io_input_r_payload_last;
  wire                axiIn_1_readOnly_decoder_io_outputs_0_ar_valid;
  wire       [31:0]   axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_addr;
  wire       [3:0]    axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_id;
  wire       [7:0]    axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_len;
  wire       [2:0]    axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_size;
  wire       [1:0]    axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_burst;
  wire       [0:0]    axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_lock;
  wire       [3:0]    axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_cache;
  wire       [2:0]    axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_prot;
  wire                axiIn_1_readOnly_decoder_io_outputs_0_r_ready;
  wire                axiIn_1_readOnly_decoder_io_outputs_1_ar_valid;
  wire       [31:0]   axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_addr;
  wire       [3:0]    axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_id;
  wire       [7:0]    axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_len;
  wire       [2:0]    axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_size;
  wire       [1:0]    axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_burst;
  wire       [0:0]    axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_lock;
  wire       [3:0]    axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_cache;
  wire       [2:0]    axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_prot;
  wire                axiIn_1_readOnly_decoder_io_outputs_1_r_ready;
  wire                axiIn_1_readOnly_decoder_io_outputs_2_ar_valid;
  wire       [31:0]   axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_addr;
  wire       [3:0]    axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_id;
  wire       [7:0]    axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_len;
  wire       [2:0]    axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_size;
  wire       [1:0]    axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_burst;
  wire       [0:0]    axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_lock;
  wire       [3:0]    axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_cache;
  wire       [2:0]    axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_prot;
  wire                axiIn_1_readOnly_decoder_io_outputs_2_r_ready;
  wire                axiIn_1_readOnly_decoder_io_outputs_3_ar_valid;
  wire       [31:0]   axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_addr;
  wire       [3:0]    axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_id;
  wire       [7:0]    axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_len;
  wire       [2:0]    axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_size;
  wire       [1:0]    axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_burst;
  wire       [0:0]    axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_lock;
  wire       [3:0]    axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_cache;
  wire       [2:0]    axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_prot;
  wire                axiIn_1_readOnly_decoder_io_outputs_3_r_ready;
  wire                axiIn_1_writeOnly_decoder_io_input_aw_ready;
  wire                axiIn_1_writeOnly_decoder_io_input_w_ready;
  wire                axiIn_1_writeOnly_decoder_io_input_b_valid;
  wire       [3:0]    axiIn_1_writeOnly_decoder_io_input_b_payload_id;
  wire       [1:0]    axiIn_1_writeOnly_decoder_io_input_b_payload_resp;
  wire                axiIn_1_writeOnly_decoder_io_outputs_0_aw_valid;
  wire       [31:0]   axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_addr;
  wire       [3:0]    axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_id;
  wire       [7:0]    axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_len;
  wire       [2:0]    axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_size;
  wire       [1:0]    axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_burst;
  wire       [0:0]    axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_lock;
  wire       [3:0]    axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_cache;
  wire       [2:0]    axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_prot;
  wire                axiIn_1_writeOnly_decoder_io_outputs_0_w_valid;
  wire       [31:0]   axiIn_1_writeOnly_decoder_io_outputs_0_w_payload_data;
  wire       [3:0]    axiIn_1_writeOnly_decoder_io_outputs_0_w_payload_strb;
  wire                axiIn_1_writeOnly_decoder_io_outputs_0_w_payload_last;
  wire                axiIn_1_writeOnly_decoder_io_outputs_0_b_ready;
  wire                axiIn_1_writeOnly_decoder_io_outputs_1_aw_valid;
  wire       [31:0]   axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_addr;
  wire       [3:0]    axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_id;
  wire       [7:0]    axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_len;
  wire       [2:0]    axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_size;
  wire       [1:0]    axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_burst;
  wire       [0:0]    axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_lock;
  wire       [3:0]    axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_cache;
  wire       [2:0]    axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_prot;
  wire                axiIn_1_writeOnly_decoder_io_outputs_1_w_valid;
  wire       [31:0]   axiIn_1_writeOnly_decoder_io_outputs_1_w_payload_data;
  wire       [3:0]    axiIn_1_writeOnly_decoder_io_outputs_1_w_payload_strb;
  wire                axiIn_1_writeOnly_decoder_io_outputs_1_w_payload_last;
  wire                axiIn_1_writeOnly_decoder_io_outputs_1_b_ready;
  wire                axiIn_1_writeOnly_decoder_io_outputs_2_aw_valid;
  wire       [31:0]   axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_addr;
  wire       [3:0]    axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_id;
  wire       [7:0]    axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_len;
  wire       [2:0]    axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_size;
  wire       [1:0]    axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_burst;
  wire       [0:0]    axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_lock;
  wire       [3:0]    axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_cache;
  wire       [2:0]    axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_prot;
  wire                axiIn_1_writeOnly_decoder_io_outputs_2_w_valid;
  wire       [31:0]   axiIn_1_writeOnly_decoder_io_outputs_2_w_payload_data;
  wire       [3:0]    axiIn_1_writeOnly_decoder_io_outputs_2_w_payload_strb;
  wire                axiIn_1_writeOnly_decoder_io_outputs_2_w_payload_last;
  wire                axiIn_1_writeOnly_decoder_io_outputs_2_b_ready;
  wire                axiIn_1_writeOnly_decoder_io_outputs_3_aw_valid;
  wire       [31:0]   axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_addr;
  wire       [3:0]    axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_id;
  wire       [7:0]    axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_len;
  wire       [2:0]    axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_size;
  wire       [1:0]    axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_burst;
  wire       [0:0]    axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_lock;
  wire       [3:0]    axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_cache;
  wire       [2:0]    axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_prot;
  wire                axiIn_1_writeOnly_decoder_io_outputs_3_w_valid;
  wire       [31:0]   axiIn_1_writeOnly_decoder_io_outputs_3_w_payload_data;
  wire       [3:0]    axiIn_1_writeOnly_decoder_io_outputs_3_w_payload_strb;
  wire                axiIn_1_writeOnly_decoder_io_outputs_3_w_payload_last;
  wire                axiIn_1_writeOnly_decoder_io_outputs_3_b_ready;
  wire                axi4ReadOnlyArbiter_4_io_inputs_0_ar_ready;
  wire                axi4ReadOnlyArbiter_4_io_inputs_0_r_valid;
  wire       [31:0]   axi4ReadOnlyArbiter_4_io_inputs_0_r_payload_data;
  wire       [3:0]    axi4ReadOnlyArbiter_4_io_inputs_0_r_payload_id;
  wire       [1:0]    axi4ReadOnlyArbiter_4_io_inputs_0_r_payload_resp;
  wire                axi4ReadOnlyArbiter_4_io_inputs_0_r_payload_last;
  wire                axi4ReadOnlyArbiter_4_io_inputs_1_ar_ready;
  wire                axi4ReadOnlyArbiter_4_io_inputs_1_r_valid;
  wire       [31:0]   axi4ReadOnlyArbiter_4_io_inputs_1_r_payload_data;
  wire       [3:0]    axi4ReadOnlyArbiter_4_io_inputs_1_r_payload_id;
  wire       [1:0]    axi4ReadOnlyArbiter_4_io_inputs_1_r_payload_resp;
  wire                axi4ReadOnlyArbiter_4_io_inputs_1_r_payload_last;
  wire                axi4ReadOnlyArbiter_4_io_output_ar_valid;
  wire       [31:0]   axi4ReadOnlyArbiter_4_io_output_ar_payload_addr;
  wire       [4:0]    axi4ReadOnlyArbiter_4_io_output_ar_payload_id;
  wire       [7:0]    axi4ReadOnlyArbiter_4_io_output_ar_payload_len;
  wire       [2:0]    axi4ReadOnlyArbiter_4_io_output_ar_payload_size;
  wire       [1:0]    axi4ReadOnlyArbiter_4_io_output_ar_payload_burst;
  wire       [0:0]    axi4ReadOnlyArbiter_4_io_output_ar_payload_lock;
  wire       [3:0]    axi4ReadOnlyArbiter_4_io_output_ar_payload_cache;
  wire       [2:0]    axi4ReadOnlyArbiter_4_io_output_ar_payload_prot;
  wire                axi4ReadOnlyArbiter_4_io_output_r_ready;
  wire                axi4WriteOnlyArbiter_4_io_inputs_0_aw_ready;
  wire                axi4WriteOnlyArbiter_4_io_inputs_0_w_ready;
  wire                axi4WriteOnlyArbiter_4_io_inputs_0_b_valid;
  wire       [3:0]    axi4WriteOnlyArbiter_4_io_inputs_0_b_payload_id;
  wire       [1:0]    axi4WriteOnlyArbiter_4_io_inputs_0_b_payload_resp;
  wire                axi4WriteOnlyArbiter_4_io_inputs_1_aw_ready;
  wire                axi4WriteOnlyArbiter_4_io_inputs_1_w_ready;
  wire                axi4WriteOnlyArbiter_4_io_inputs_1_b_valid;
  wire       [3:0]    axi4WriteOnlyArbiter_4_io_inputs_1_b_payload_id;
  wire       [1:0]    axi4WriteOnlyArbiter_4_io_inputs_1_b_payload_resp;
  wire                axi4WriteOnlyArbiter_4_io_output_aw_valid;
  wire       [31:0]   axi4WriteOnlyArbiter_4_io_output_aw_payload_addr;
  wire       [4:0]    axi4WriteOnlyArbiter_4_io_output_aw_payload_id;
  wire       [7:0]    axi4WriteOnlyArbiter_4_io_output_aw_payload_len;
  wire       [2:0]    axi4WriteOnlyArbiter_4_io_output_aw_payload_size;
  wire       [1:0]    axi4WriteOnlyArbiter_4_io_output_aw_payload_burst;
  wire       [0:0]    axi4WriteOnlyArbiter_4_io_output_aw_payload_lock;
  wire       [3:0]    axi4WriteOnlyArbiter_4_io_output_aw_payload_cache;
  wire       [2:0]    axi4WriteOnlyArbiter_4_io_output_aw_payload_prot;
  wire                axi4WriteOnlyArbiter_4_io_output_w_valid;
  wire       [31:0]   axi4WriteOnlyArbiter_4_io_output_w_payload_data;
  wire       [3:0]    axi4WriteOnlyArbiter_4_io_output_w_payload_strb;
  wire                axi4WriteOnlyArbiter_4_io_output_w_payload_last;
  wire                axi4WriteOnlyArbiter_4_io_output_b_ready;
  wire                axi4ReadOnlyArbiter_5_io_inputs_0_ar_ready;
  wire                axi4ReadOnlyArbiter_5_io_inputs_0_r_valid;
  wire       [31:0]   axi4ReadOnlyArbiter_5_io_inputs_0_r_payload_data;
  wire       [3:0]    axi4ReadOnlyArbiter_5_io_inputs_0_r_payload_id;
  wire       [1:0]    axi4ReadOnlyArbiter_5_io_inputs_0_r_payload_resp;
  wire                axi4ReadOnlyArbiter_5_io_inputs_0_r_payload_last;
  wire                axi4ReadOnlyArbiter_5_io_inputs_1_ar_ready;
  wire                axi4ReadOnlyArbiter_5_io_inputs_1_r_valid;
  wire       [31:0]   axi4ReadOnlyArbiter_5_io_inputs_1_r_payload_data;
  wire       [3:0]    axi4ReadOnlyArbiter_5_io_inputs_1_r_payload_id;
  wire       [1:0]    axi4ReadOnlyArbiter_5_io_inputs_1_r_payload_resp;
  wire                axi4ReadOnlyArbiter_5_io_inputs_1_r_payload_last;
  wire                axi4ReadOnlyArbiter_5_io_output_ar_valid;
  wire       [31:0]   axi4ReadOnlyArbiter_5_io_output_ar_payload_addr;
  wire       [4:0]    axi4ReadOnlyArbiter_5_io_output_ar_payload_id;
  wire       [7:0]    axi4ReadOnlyArbiter_5_io_output_ar_payload_len;
  wire       [2:0]    axi4ReadOnlyArbiter_5_io_output_ar_payload_size;
  wire       [1:0]    axi4ReadOnlyArbiter_5_io_output_ar_payload_burst;
  wire       [0:0]    axi4ReadOnlyArbiter_5_io_output_ar_payload_lock;
  wire       [3:0]    axi4ReadOnlyArbiter_5_io_output_ar_payload_cache;
  wire       [2:0]    axi4ReadOnlyArbiter_5_io_output_ar_payload_prot;
  wire                axi4ReadOnlyArbiter_5_io_output_r_ready;
  wire                axi4WriteOnlyArbiter_5_io_inputs_0_aw_ready;
  wire                axi4WriteOnlyArbiter_5_io_inputs_0_w_ready;
  wire                axi4WriteOnlyArbiter_5_io_inputs_0_b_valid;
  wire       [3:0]    axi4WriteOnlyArbiter_5_io_inputs_0_b_payload_id;
  wire       [1:0]    axi4WriteOnlyArbiter_5_io_inputs_0_b_payload_resp;
  wire                axi4WriteOnlyArbiter_5_io_inputs_1_aw_ready;
  wire                axi4WriteOnlyArbiter_5_io_inputs_1_w_ready;
  wire                axi4WriteOnlyArbiter_5_io_inputs_1_b_valid;
  wire       [3:0]    axi4WriteOnlyArbiter_5_io_inputs_1_b_payload_id;
  wire       [1:0]    axi4WriteOnlyArbiter_5_io_inputs_1_b_payload_resp;
  wire                axi4WriteOnlyArbiter_5_io_output_aw_valid;
  wire       [31:0]   axi4WriteOnlyArbiter_5_io_output_aw_payload_addr;
  wire       [4:0]    axi4WriteOnlyArbiter_5_io_output_aw_payload_id;
  wire       [7:0]    axi4WriteOnlyArbiter_5_io_output_aw_payload_len;
  wire       [2:0]    axi4WriteOnlyArbiter_5_io_output_aw_payload_size;
  wire       [1:0]    axi4WriteOnlyArbiter_5_io_output_aw_payload_burst;
  wire       [0:0]    axi4WriteOnlyArbiter_5_io_output_aw_payload_lock;
  wire       [3:0]    axi4WriteOnlyArbiter_5_io_output_aw_payload_cache;
  wire       [2:0]    axi4WriteOnlyArbiter_5_io_output_aw_payload_prot;
  wire                axi4WriteOnlyArbiter_5_io_output_w_valid;
  wire       [31:0]   axi4WriteOnlyArbiter_5_io_output_w_payload_data;
  wire       [3:0]    axi4WriteOnlyArbiter_5_io_output_w_payload_strb;
  wire                axi4WriteOnlyArbiter_5_io_output_w_payload_last;
  wire                axi4WriteOnlyArbiter_5_io_output_b_ready;
  wire                axi4ReadOnlyArbiter_6_io_inputs_0_ar_ready;
  wire                axi4ReadOnlyArbiter_6_io_inputs_0_r_valid;
  wire       [31:0]   axi4ReadOnlyArbiter_6_io_inputs_0_r_payload_data;
  wire       [3:0]    axi4ReadOnlyArbiter_6_io_inputs_0_r_payload_id;
  wire       [1:0]    axi4ReadOnlyArbiter_6_io_inputs_0_r_payload_resp;
  wire                axi4ReadOnlyArbiter_6_io_inputs_0_r_payload_last;
  wire                axi4ReadOnlyArbiter_6_io_inputs_1_ar_ready;
  wire                axi4ReadOnlyArbiter_6_io_inputs_1_r_valid;
  wire       [31:0]   axi4ReadOnlyArbiter_6_io_inputs_1_r_payload_data;
  wire       [3:0]    axi4ReadOnlyArbiter_6_io_inputs_1_r_payload_id;
  wire       [1:0]    axi4ReadOnlyArbiter_6_io_inputs_1_r_payload_resp;
  wire                axi4ReadOnlyArbiter_6_io_inputs_1_r_payload_last;
  wire                axi4ReadOnlyArbiter_6_io_output_ar_valid;
  wire       [31:0]   axi4ReadOnlyArbiter_6_io_output_ar_payload_addr;
  wire       [4:0]    axi4ReadOnlyArbiter_6_io_output_ar_payload_id;
  wire       [7:0]    axi4ReadOnlyArbiter_6_io_output_ar_payload_len;
  wire       [2:0]    axi4ReadOnlyArbiter_6_io_output_ar_payload_size;
  wire       [1:0]    axi4ReadOnlyArbiter_6_io_output_ar_payload_burst;
  wire       [0:0]    axi4ReadOnlyArbiter_6_io_output_ar_payload_lock;
  wire       [3:0]    axi4ReadOnlyArbiter_6_io_output_ar_payload_cache;
  wire       [2:0]    axi4ReadOnlyArbiter_6_io_output_ar_payload_prot;
  wire                axi4ReadOnlyArbiter_6_io_output_r_ready;
  wire                axi4WriteOnlyArbiter_6_io_inputs_0_aw_ready;
  wire                axi4WriteOnlyArbiter_6_io_inputs_0_w_ready;
  wire                axi4WriteOnlyArbiter_6_io_inputs_0_b_valid;
  wire       [3:0]    axi4WriteOnlyArbiter_6_io_inputs_0_b_payload_id;
  wire       [1:0]    axi4WriteOnlyArbiter_6_io_inputs_0_b_payload_resp;
  wire                axi4WriteOnlyArbiter_6_io_inputs_1_aw_ready;
  wire                axi4WriteOnlyArbiter_6_io_inputs_1_w_ready;
  wire                axi4WriteOnlyArbiter_6_io_inputs_1_b_valid;
  wire       [3:0]    axi4WriteOnlyArbiter_6_io_inputs_1_b_payload_id;
  wire       [1:0]    axi4WriteOnlyArbiter_6_io_inputs_1_b_payload_resp;
  wire                axi4WriteOnlyArbiter_6_io_output_aw_valid;
  wire       [31:0]   axi4WriteOnlyArbiter_6_io_output_aw_payload_addr;
  wire       [4:0]    axi4WriteOnlyArbiter_6_io_output_aw_payload_id;
  wire       [7:0]    axi4WriteOnlyArbiter_6_io_output_aw_payload_len;
  wire       [2:0]    axi4WriteOnlyArbiter_6_io_output_aw_payload_size;
  wire       [1:0]    axi4WriteOnlyArbiter_6_io_output_aw_payload_burst;
  wire       [0:0]    axi4WriteOnlyArbiter_6_io_output_aw_payload_lock;
  wire       [3:0]    axi4WriteOnlyArbiter_6_io_output_aw_payload_cache;
  wire       [2:0]    axi4WriteOnlyArbiter_6_io_output_aw_payload_prot;
  wire                axi4WriteOnlyArbiter_6_io_output_w_valid;
  wire       [31:0]   axi4WriteOnlyArbiter_6_io_output_w_payload_data;
  wire       [3:0]    axi4WriteOnlyArbiter_6_io_output_w_payload_strb;
  wire                axi4WriteOnlyArbiter_6_io_output_w_payload_last;
  wire                axi4WriteOnlyArbiter_6_io_output_b_ready;
  wire                axi4ReadOnlyArbiter_7_io_inputs_0_ar_ready;
  wire                axi4ReadOnlyArbiter_7_io_inputs_0_r_valid;
  wire       [31:0]   axi4ReadOnlyArbiter_7_io_inputs_0_r_payload_data;
  wire       [3:0]    axi4ReadOnlyArbiter_7_io_inputs_0_r_payload_id;
  wire       [1:0]    axi4ReadOnlyArbiter_7_io_inputs_0_r_payload_resp;
  wire                axi4ReadOnlyArbiter_7_io_inputs_0_r_payload_last;
  wire                axi4ReadOnlyArbiter_7_io_inputs_1_ar_ready;
  wire                axi4ReadOnlyArbiter_7_io_inputs_1_r_valid;
  wire       [31:0]   axi4ReadOnlyArbiter_7_io_inputs_1_r_payload_data;
  wire       [3:0]    axi4ReadOnlyArbiter_7_io_inputs_1_r_payload_id;
  wire       [1:0]    axi4ReadOnlyArbiter_7_io_inputs_1_r_payload_resp;
  wire                axi4ReadOnlyArbiter_7_io_inputs_1_r_payload_last;
  wire                axi4ReadOnlyArbiter_7_io_output_ar_valid;
  wire       [31:0]   axi4ReadOnlyArbiter_7_io_output_ar_payload_addr;
  wire       [4:0]    axi4ReadOnlyArbiter_7_io_output_ar_payload_id;
  wire       [7:0]    axi4ReadOnlyArbiter_7_io_output_ar_payload_len;
  wire       [2:0]    axi4ReadOnlyArbiter_7_io_output_ar_payload_size;
  wire       [1:0]    axi4ReadOnlyArbiter_7_io_output_ar_payload_burst;
  wire       [0:0]    axi4ReadOnlyArbiter_7_io_output_ar_payload_lock;
  wire       [3:0]    axi4ReadOnlyArbiter_7_io_output_ar_payload_cache;
  wire       [2:0]    axi4ReadOnlyArbiter_7_io_output_ar_payload_prot;
  wire                axi4ReadOnlyArbiter_7_io_output_r_ready;
  wire                axi4WriteOnlyArbiter_7_io_inputs_0_aw_ready;
  wire                axi4WriteOnlyArbiter_7_io_inputs_0_w_ready;
  wire                axi4WriteOnlyArbiter_7_io_inputs_0_b_valid;
  wire       [3:0]    axi4WriteOnlyArbiter_7_io_inputs_0_b_payload_id;
  wire       [1:0]    axi4WriteOnlyArbiter_7_io_inputs_0_b_payload_resp;
  wire                axi4WriteOnlyArbiter_7_io_inputs_1_aw_ready;
  wire                axi4WriteOnlyArbiter_7_io_inputs_1_w_ready;
  wire                axi4WriteOnlyArbiter_7_io_inputs_1_b_valid;
  wire       [3:0]    axi4WriteOnlyArbiter_7_io_inputs_1_b_payload_id;
  wire       [1:0]    axi4WriteOnlyArbiter_7_io_inputs_1_b_payload_resp;
  wire                axi4WriteOnlyArbiter_7_io_output_aw_valid;
  wire       [31:0]   axi4WriteOnlyArbiter_7_io_output_aw_payload_addr;
  wire       [4:0]    axi4WriteOnlyArbiter_7_io_output_aw_payload_id;
  wire       [7:0]    axi4WriteOnlyArbiter_7_io_output_aw_payload_len;
  wire       [2:0]    axi4WriteOnlyArbiter_7_io_output_aw_payload_size;
  wire       [1:0]    axi4WriteOnlyArbiter_7_io_output_aw_payload_burst;
  wire       [0:0]    axi4WriteOnlyArbiter_7_io_output_aw_payload_lock;
  wire       [3:0]    axi4WriteOnlyArbiter_7_io_output_aw_payload_cache;
  wire       [2:0]    axi4WriteOnlyArbiter_7_io_output_aw_payload_prot;
  wire                axi4WriteOnlyArbiter_7_io_output_w_valid;
  wire       [31:0]   axi4WriteOnlyArbiter_7_io_output_w_payload_data;
  wire       [3:0]    axi4WriteOnlyArbiter_7_io_output_w_payload_strb;
  wire                axi4WriteOnlyArbiter_7_io_output_w_payload_last;
  wire                axi4WriteOnlyArbiter_7_io_output_b_ready;
  wire                axiIn_0_readOnly_ar_valid;
  wire                axiIn_0_readOnly_ar_ready;
  wire       [31:0]   axiIn_0_readOnly_ar_payload_addr;
  wire       [3:0]    axiIn_0_readOnly_ar_payload_id;
  wire       [7:0]    axiIn_0_readOnly_ar_payload_len;
  wire       [2:0]    axiIn_0_readOnly_ar_payload_size;
  wire       [1:0]    axiIn_0_readOnly_ar_payload_burst;
  wire       [0:0]    axiIn_0_readOnly_ar_payload_lock;
  wire       [3:0]    axiIn_0_readOnly_ar_payload_cache;
  wire       [2:0]    axiIn_0_readOnly_ar_payload_prot;
  wire                axiIn_0_readOnly_r_valid;
  wire                axiIn_0_readOnly_r_ready;
  wire       [31:0]   axiIn_0_readOnly_r_payload_data;
  wire       [3:0]    axiIn_0_readOnly_r_payload_id;
  wire       [1:0]    axiIn_0_readOnly_r_payload_resp;
  wire                axiIn_0_readOnly_r_payload_last;
  wire                axiIn_0_writeOnly_aw_valid;
  wire                axiIn_0_writeOnly_aw_ready;
  wire       [31:0]   axiIn_0_writeOnly_aw_payload_addr;
  wire       [3:0]    axiIn_0_writeOnly_aw_payload_id;
  wire       [7:0]    axiIn_0_writeOnly_aw_payload_len;
  wire       [2:0]    axiIn_0_writeOnly_aw_payload_size;
  wire       [1:0]    axiIn_0_writeOnly_aw_payload_burst;
  wire       [0:0]    axiIn_0_writeOnly_aw_payload_lock;
  wire       [3:0]    axiIn_0_writeOnly_aw_payload_cache;
  wire       [2:0]    axiIn_0_writeOnly_aw_payload_prot;
  wire                axiIn_0_writeOnly_w_valid;
  wire                axiIn_0_writeOnly_w_ready;
  wire       [31:0]   axiIn_0_writeOnly_w_payload_data;
  wire       [3:0]    axiIn_0_writeOnly_w_payload_strb;
  wire                axiIn_0_writeOnly_w_payload_last;
  wire                axiIn_0_writeOnly_b_valid;
  wire                axiIn_0_writeOnly_b_ready;
  wire       [3:0]    axiIn_0_writeOnly_b_payload_id;
  wire       [1:0]    axiIn_0_writeOnly_b_payload_resp;
  wire                axiIn_1_readOnly_ar_valid;
  wire                axiIn_1_readOnly_ar_ready;
  wire       [31:0]   axiIn_1_readOnly_ar_payload_addr;
  wire       [3:0]    axiIn_1_readOnly_ar_payload_id;
  wire       [7:0]    axiIn_1_readOnly_ar_payload_len;
  wire       [2:0]    axiIn_1_readOnly_ar_payload_size;
  wire       [1:0]    axiIn_1_readOnly_ar_payload_burst;
  wire       [0:0]    axiIn_1_readOnly_ar_payload_lock;
  wire       [3:0]    axiIn_1_readOnly_ar_payload_cache;
  wire       [2:0]    axiIn_1_readOnly_ar_payload_prot;
  wire                axiIn_1_readOnly_r_valid;
  wire                axiIn_1_readOnly_r_ready;
  wire       [31:0]   axiIn_1_readOnly_r_payload_data;
  wire       [3:0]    axiIn_1_readOnly_r_payload_id;
  wire       [1:0]    axiIn_1_readOnly_r_payload_resp;
  wire                axiIn_1_readOnly_r_payload_last;
  wire                axiIn_1_writeOnly_aw_valid;
  wire                axiIn_1_writeOnly_aw_ready;
  wire       [31:0]   axiIn_1_writeOnly_aw_payload_addr;
  wire       [3:0]    axiIn_1_writeOnly_aw_payload_id;
  wire       [7:0]    axiIn_1_writeOnly_aw_payload_len;
  wire       [2:0]    axiIn_1_writeOnly_aw_payload_size;
  wire       [1:0]    axiIn_1_writeOnly_aw_payload_burst;
  wire       [0:0]    axiIn_1_writeOnly_aw_payload_lock;
  wire       [3:0]    axiIn_1_writeOnly_aw_payload_cache;
  wire       [2:0]    axiIn_1_writeOnly_aw_payload_prot;
  wire                axiIn_1_writeOnly_w_valid;
  wire                axiIn_1_writeOnly_w_ready;
  wire       [31:0]   axiIn_1_writeOnly_w_payload_data;
  wire       [3:0]    axiIn_1_writeOnly_w_payload_strb;
  wire                axiIn_1_writeOnly_w_payload_last;
  wire                axiIn_1_writeOnly_b_valid;
  wire                axiIn_1_writeOnly_b_ready;
  wire       [3:0]    axiIn_1_writeOnly_b_payload_id;
  wire       [1:0]    axiIn_1_writeOnly_b_payload_resp;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_valid;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_prot;
  reg                 toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_rValid;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_fire;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_valid;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_prot;
  reg                 toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_rValid;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_fire;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_valid;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_prot;
  reg                 toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_rValid;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_fire;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_valid;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_prot;
  reg                 toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_rValid;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_fire;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_valid;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_prot;
  reg                 toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_rValid;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_fire;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_valid;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_prot;
  reg                 toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_rValid;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_fire;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_valid;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_prot;
  reg                 toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_rValid;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_fire;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_valid;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_prot;
  reg                 toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_rValid;
  wire                toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_fire;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_valid;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_prot;
  reg                 toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_rValid;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_fire;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_valid;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_prot;
  reg                 toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_rValid;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_fire;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_valid;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_prot;
  reg                 toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_rValid;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_fire;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_valid;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_prot;
  reg                 toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_rValid;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_fire;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_valid;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_prot;
  reg                 toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_rValid;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_fire;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_valid;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_prot;
  reg                 toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_rValid;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_fire;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_valid;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_prot;
  reg                 toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_rValid;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_fire;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_valid;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_prot;
  reg                 toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_rValid;
  wire                toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_fire;
  wire                toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_valid;
  wire                toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_prot;
  reg                 toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_rValid;
  wire                toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_fire;
  wire                toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_valid;
  wire                toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_prot;
  reg                 toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_rValid;
  wire                toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_fire;
  wire                toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_valid;
  wire                toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_prot;
  reg                 toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_rValid;
  wire                toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_fire;
  wire                toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_valid;
  wire                toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_prot;
  reg                 toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_rValid;
  wire                toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_fire;
  wire                toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_valid;
  wire                toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_prot;
  reg                 toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_rValid;
  wire                toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_fire;
  wire                toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_valid;
  wire                toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_prot;
  reg                 toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_rValid;
  wire                toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_fire;
  wire                toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_valid;
  wire                toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_prot;
  reg                 toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_rValid;
  wire                toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_fire;
  wire                toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_valid;
  wire                toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_ready;
  wire       [31:0]   toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_addr;
  wire       [3:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_id;
  wire       [7:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_len;
  wire       [2:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_size;
  wire       [1:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_burst;
  wire       [0:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_lock;
  wire       [3:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_cache;
  wire       [2:0]    toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_prot;
  reg                 toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_rValid;
  wire                toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_fire;

  Axi4ReadOnlyDecoder axiIn_0_readOnly_decoder (
    .io_input_ar_valid             (axiIn_0_readOnly_ar_valid                                       ), //i
    .io_input_ar_ready             (axiIn_0_readOnly_decoder_io_input_ar_ready                      ), //o
    .io_input_ar_payload_addr      (axiIn_0_readOnly_ar_payload_addr[31:0]                          ), //i
    .io_input_ar_payload_id        (axiIn_0_readOnly_ar_payload_id[3:0]                             ), //i
    .io_input_ar_payload_len       (axiIn_0_readOnly_ar_payload_len[7:0]                            ), //i
    .io_input_ar_payload_size      (axiIn_0_readOnly_ar_payload_size[2:0]                           ), //i
    .io_input_ar_payload_burst     (axiIn_0_readOnly_ar_payload_burst[1:0]                          ), //i
    .io_input_ar_payload_lock      (axiIn_0_readOnly_ar_payload_lock                                ), //i
    .io_input_ar_payload_cache     (axiIn_0_readOnly_ar_payload_cache[3:0]                          ), //i
    .io_input_ar_payload_prot      (axiIn_0_readOnly_ar_payload_prot[2:0]                           ), //i
    .io_input_r_valid              (axiIn_0_readOnly_decoder_io_input_r_valid                       ), //o
    .io_input_r_ready              (axiIn_0_readOnly_r_ready                                        ), //i
    .io_input_r_payload_data       (axiIn_0_readOnly_decoder_io_input_r_payload_data[31:0]          ), //o
    .io_input_r_payload_id         (axiIn_0_readOnly_decoder_io_input_r_payload_id[3:0]             ), //o
    .io_input_r_payload_resp       (axiIn_0_readOnly_decoder_io_input_r_payload_resp[1:0]           ), //o
    .io_input_r_payload_last       (axiIn_0_readOnly_decoder_io_input_r_payload_last                ), //o
    .io_outputs_0_ar_valid         (axiIn_0_readOnly_decoder_io_outputs_0_ar_valid                  ), //o
    .io_outputs_0_ar_ready         (toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_fire), //i
    .io_outputs_0_ar_payload_addr  (axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_addr[31:0]     ), //o
    .io_outputs_0_ar_payload_id    (axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_id[3:0]        ), //o
    .io_outputs_0_ar_payload_len   (axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_len[7:0]       ), //o
    .io_outputs_0_ar_payload_size  (axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_size[2:0]      ), //o
    .io_outputs_0_ar_payload_burst (axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_burst[1:0]     ), //o
    .io_outputs_0_ar_payload_lock  (axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_lock           ), //o
    .io_outputs_0_ar_payload_cache (axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_cache[3:0]     ), //o
    .io_outputs_0_ar_payload_prot  (axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_prot[2:0]      ), //o
    .io_outputs_0_r_valid          (axi4ReadOnlyArbiter_4_io_inputs_0_r_valid                       ), //i
    .io_outputs_0_r_ready          (axiIn_0_readOnly_decoder_io_outputs_0_r_ready                   ), //o
    .io_outputs_0_r_payload_data   (axi4ReadOnlyArbiter_4_io_inputs_0_r_payload_data[31:0]          ), //i
    .io_outputs_0_r_payload_id     (axi4ReadOnlyArbiter_4_io_inputs_0_r_payload_id[3:0]             ), //i
    .io_outputs_0_r_payload_resp   (axi4ReadOnlyArbiter_4_io_inputs_0_r_payload_resp[1:0]           ), //i
    .io_outputs_0_r_payload_last   (axi4ReadOnlyArbiter_4_io_inputs_0_r_payload_last                ), //i
    .io_outputs_1_ar_valid         (axiIn_0_readOnly_decoder_io_outputs_1_ar_valid                  ), //o
    .io_outputs_1_ar_ready         (toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_fire), //i
    .io_outputs_1_ar_payload_addr  (axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_addr[31:0]     ), //o
    .io_outputs_1_ar_payload_id    (axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_id[3:0]        ), //o
    .io_outputs_1_ar_payload_len   (axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_len[7:0]       ), //o
    .io_outputs_1_ar_payload_size  (axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_size[2:0]      ), //o
    .io_outputs_1_ar_payload_burst (axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_burst[1:0]     ), //o
    .io_outputs_1_ar_payload_lock  (axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_lock           ), //o
    .io_outputs_1_ar_payload_cache (axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_cache[3:0]     ), //o
    .io_outputs_1_ar_payload_prot  (axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_prot[2:0]      ), //o
    .io_outputs_1_r_valid          (axi4ReadOnlyArbiter_5_io_inputs_0_r_valid                       ), //i
    .io_outputs_1_r_ready          (axiIn_0_readOnly_decoder_io_outputs_1_r_ready                   ), //o
    .io_outputs_1_r_payload_data   (axi4ReadOnlyArbiter_5_io_inputs_0_r_payload_data[31:0]          ), //i
    .io_outputs_1_r_payload_id     (axi4ReadOnlyArbiter_5_io_inputs_0_r_payload_id[3:0]             ), //i
    .io_outputs_1_r_payload_resp   (axi4ReadOnlyArbiter_5_io_inputs_0_r_payload_resp[1:0]           ), //i
    .io_outputs_1_r_payload_last   (axi4ReadOnlyArbiter_5_io_inputs_0_r_payload_last                ), //i
    .io_outputs_2_ar_valid         (axiIn_0_readOnly_decoder_io_outputs_2_ar_valid                  ), //o
    .io_outputs_2_ar_ready         (toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_fire), //i
    .io_outputs_2_ar_payload_addr  (axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_addr[31:0]     ), //o
    .io_outputs_2_ar_payload_id    (axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_id[3:0]        ), //o
    .io_outputs_2_ar_payload_len   (axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_len[7:0]       ), //o
    .io_outputs_2_ar_payload_size  (axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_size[2:0]      ), //o
    .io_outputs_2_ar_payload_burst (axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_burst[1:0]     ), //o
    .io_outputs_2_ar_payload_lock  (axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_lock           ), //o
    .io_outputs_2_ar_payload_cache (axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_cache[3:0]     ), //o
    .io_outputs_2_ar_payload_prot  (axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_prot[2:0]      ), //o
    .io_outputs_2_r_valid          (axiOut_2_rvalid                                                 ), //i
    .io_outputs_2_r_ready          (axiIn_0_readOnly_decoder_io_outputs_2_r_ready                   ), //o
    .io_outputs_2_r_payload_data   (axiOut_2_rdata[31:0]                                            ), //i
    .io_outputs_2_r_payload_id     (axiIn_0_readOnly_decoder_io_outputs_2_r_payload_id[3:0]         ), //i
    .io_outputs_2_r_payload_resp   (axiOut_2_rresp[1:0]                                             ), //i
    .io_outputs_2_r_payload_last   (axiOut_2_rlast                                                  ), //i
    .io_outputs_3_ar_valid         (axiIn_0_readOnly_decoder_io_outputs_3_ar_valid                  ), //o
    .io_outputs_3_ar_ready         (toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_fire), //i
    .io_outputs_3_ar_payload_addr  (axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_addr[31:0]     ), //o
    .io_outputs_3_ar_payload_id    (axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_id[3:0]        ), //o
    .io_outputs_3_ar_payload_len   (axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_len[7:0]       ), //o
    .io_outputs_3_ar_payload_size  (axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_size[2:0]      ), //o
    .io_outputs_3_ar_payload_burst (axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_burst[1:0]     ), //o
    .io_outputs_3_ar_payload_lock  (axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_lock           ), //o
    .io_outputs_3_ar_payload_cache (axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_cache[3:0]     ), //o
    .io_outputs_3_ar_payload_prot  (axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_prot[2:0]      ), //o
    .io_outputs_3_r_valid          (axiOut_3_rvalid                                                 ), //i
    .io_outputs_3_r_ready          (axiIn_0_readOnly_decoder_io_outputs_3_r_ready                   ), //o
    .io_outputs_3_r_payload_data   (axiOut_3_rdata[31:0]                                            ), //i
    .io_outputs_3_r_payload_id     (axiIn_0_readOnly_decoder_io_outputs_3_r_payload_id[3:0]         ), //i
    .io_outputs_3_r_payload_resp   (axiOut_3_rresp[1:0]                                             ), //i
    .io_outputs_3_r_payload_last   (axiOut_3_rlast                                                  ), //i
    .io_outputs_4_ar_valid         (axiIn_0_readOnly_decoder_io_outputs_4_ar_valid                  ), //o
    .io_outputs_4_ar_ready         (toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_fire), //i
    .io_outputs_4_ar_payload_addr  (axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_addr[31:0]     ), //o
    .io_outputs_4_ar_payload_id    (axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_id[3:0]        ), //o
    .io_outputs_4_ar_payload_len   (axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_len[7:0]       ), //o
    .io_outputs_4_ar_payload_size  (axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_size[2:0]      ), //o
    .io_outputs_4_ar_payload_burst (axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_burst[1:0]     ), //o
    .io_outputs_4_ar_payload_lock  (axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_lock           ), //o
    .io_outputs_4_ar_payload_cache (axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_cache[3:0]     ), //o
    .io_outputs_4_ar_payload_prot  (axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_prot[2:0]      ), //o
    .io_outputs_4_r_valid          (axiOut_4_rvalid                                                 ), //i
    .io_outputs_4_r_ready          (axiIn_0_readOnly_decoder_io_outputs_4_r_ready                   ), //o
    .io_outputs_4_r_payload_data   (axiOut_4_rdata[31:0]                                            ), //i
    .io_outputs_4_r_payload_id     (axiIn_0_readOnly_decoder_io_outputs_4_r_payload_id[3:0]         ), //i
    .io_outputs_4_r_payload_resp   (axiOut_4_rresp[1:0]                                             ), //i
    .io_outputs_4_r_payload_last   (axiOut_4_rlast                                                  ), //i
    .io_outputs_5_ar_valid         (axiIn_0_readOnly_decoder_io_outputs_5_ar_valid                  ), //o
    .io_outputs_5_ar_ready         (toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_fire), //i
    .io_outputs_5_ar_payload_addr  (axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_addr[31:0]     ), //o
    .io_outputs_5_ar_payload_id    (axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_id[3:0]        ), //o
    .io_outputs_5_ar_payload_len   (axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_len[7:0]       ), //o
    .io_outputs_5_ar_payload_size  (axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_size[2:0]      ), //o
    .io_outputs_5_ar_payload_burst (axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_burst[1:0]     ), //o
    .io_outputs_5_ar_payload_lock  (axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_lock           ), //o
    .io_outputs_5_ar_payload_cache (axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_cache[3:0]     ), //o
    .io_outputs_5_ar_payload_prot  (axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_prot[2:0]      ), //o
    .io_outputs_5_r_valid          (axiOut_5_rvalid                                                 ), //i
    .io_outputs_5_r_ready          (axiIn_0_readOnly_decoder_io_outputs_5_r_ready                   ), //o
    .io_outputs_5_r_payload_data   (axiOut_5_rdata[31:0]                                            ), //i
    .io_outputs_5_r_payload_id     (axiIn_0_readOnly_decoder_io_outputs_5_r_payload_id[3:0]         ), //i
    .io_outputs_5_r_payload_resp   (axiOut_5_rresp[1:0]                                             ), //i
    .io_outputs_5_r_payload_last   (axiOut_5_rlast                                                  ), //i
    .io_outputs_6_ar_valid         (axiIn_0_readOnly_decoder_io_outputs_6_ar_valid                  ), //o
    .io_outputs_6_ar_ready         (toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_fire), //i
    .io_outputs_6_ar_payload_addr  (axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_addr[31:0]     ), //o
    .io_outputs_6_ar_payload_id    (axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_id[3:0]        ), //o
    .io_outputs_6_ar_payload_len   (axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_len[7:0]       ), //o
    .io_outputs_6_ar_payload_size  (axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_size[2:0]      ), //o
    .io_outputs_6_ar_payload_burst (axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_burst[1:0]     ), //o
    .io_outputs_6_ar_payload_lock  (axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_lock           ), //o
    .io_outputs_6_ar_payload_cache (axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_cache[3:0]     ), //o
    .io_outputs_6_ar_payload_prot  (axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_prot[2:0]      ), //o
    .io_outputs_6_r_valid          (axi4ReadOnlyArbiter_6_io_inputs_0_r_valid                       ), //i
    .io_outputs_6_r_ready          (axiIn_0_readOnly_decoder_io_outputs_6_r_ready                   ), //o
    .io_outputs_6_r_payload_data   (axi4ReadOnlyArbiter_6_io_inputs_0_r_payload_data[31:0]          ), //i
    .io_outputs_6_r_payload_id     (axi4ReadOnlyArbiter_6_io_inputs_0_r_payload_id[3:0]             ), //i
    .io_outputs_6_r_payload_resp   (axi4ReadOnlyArbiter_6_io_inputs_0_r_payload_resp[1:0]           ), //i
    .io_outputs_6_r_payload_last   (axi4ReadOnlyArbiter_6_io_inputs_0_r_payload_last                ), //i
    .io_outputs_7_ar_valid         (axiIn_0_readOnly_decoder_io_outputs_7_ar_valid                  ), //o
    .io_outputs_7_ar_ready         (toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_fire), //i
    .io_outputs_7_ar_payload_addr  (axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_addr[31:0]     ), //o
    .io_outputs_7_ar_payload_id    (axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_id[3:0]        ), //o
    .io_outputs_7_ar_payload_len   (axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_len[7:0]       ), //o
    .io_outputs_7_ar_payload_size  (axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_size[2:0]      ), //o
    .io_outputs_7_ar_payload_burst (axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_burst[1:0]     ), //o
    .io_outputs_7_ar_payload_lock  (axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_lock           ), //o
    .io_outputs_7_ar_payload_cache (axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_cache[3:0]     ), //o
    .io_outputs_7_ar_payload_prot  (axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_prot[2:0]      ), //o
    .io_outputs_7_r_valid          (axi4ReadOnlyArbiter_7_io_inputs_0_r_valid                       ), //i
    .io_outputs_7_r_ready          (axiIn_0_readOnly_decoder_io_outputs_7_r_ready                   ), //o
    .io_outputs_7_r_payload_data   (axi4ReadOnlyArbiter_7_io_inputs_0_r_payload_data[31:0]          ), //i
    .io_outputs_7_r_payload_id     (axi4ReadOnlyArbiter_7_io_inputs_0_r_payload_id[3:0]             ), //i
    .io_outputs_7_r_payload_resp   (axi4ReadOnlyArbiter_7_io_inputs_0_r_payload_resp[1:0]           ), //i
    .io_outputs_7_r_payload_last   (axi4ReadOnlyArbiter_7_io_inputs_0_r_payload_last                ), //i
    .clk                           (clk                                                             ), //i
    .resetn                        (resetn                                                          )  //i
  );
  Axi4WriteOnlyDecoder axiIn_0_writeOnly_decoder (
    .io_input_aw_valid             (axiIn_0_writeOnly_aw_valid                                       ), //i
    .io_input_aw_ready             (axiIn_0_writeOnly_decoder_io_input_aw_ready                      ), //o
    .io_input_aw_payload_addr      (axiIn_0_writeOnly_aw_payload_addr[31:0]                          ), //i
    .io_input_aw_payload_id        (axiIn_0_writeOnly_aw_payload_id[3:0]                             ), //i
    .io_input_aw_payload_len       (axiIn_0_writeOnly_aw_payload_len[7:0]                            ), //i
    .io_input_aw_payload_size      (axiIn_0_writeOnly_aw_payload_size[2:0]                           ), //i
    .io_input_aw_payload_burst     (axiIn_0_writeOnly_aw_payload_burst[1:0]                          ), //i
    .io_input_aw_payload_lock      (axiIn_0_writeOnly_aw_payload_lock                                ), //i
    .io_input_aw_payload_cache     (axiIn_0_writeOnly_aw_payload_cache[3:0]                          ), //i
    .io_input_aw_payload_prot      (axiIn_0_writeOnly_aw_payload_prot[2:0]                           ), //i
    .io_input_w_valid              (axiIn_0_writeOnly_w_valid                                        ), //i
    .io_input_w_ready              (axiIn_0_writeOnly_decoder_io_input_w_ready                       ), //o
    .io_input_w_payload_data       (axiIn_0_writeOnly_w_payload_data[31:0]                           ), //i
    .io_input_w_payload_strb       (axiIn_0_writeOnly_w_payload_strb[3:0]                            ), //i
    .io_input_w_payload_last       (axiIn_0_writeOnly_w_payload_last                                 ), //i
    .io_input_b_valid              (axiIn_0_writeOnly_decoder_io_input_b_valid                       ), //o
    .io_input_b_ready              (axiIn_0_writeOnly_b_ready                                        ), //i
    .io_input_b_payload_id         (axiIn_0_writeOnly_decoder_io_input_b_payload_id[3:0]             ), //o
    .io_input_b_payload_resp       (axiIn_0_writeOnly_decoder_io_input_b_payload_resp[1:0]           ), //o
    .io_outputs_0_aw_valid         (axiIn_0_writeOnly_decoder_io_outputs_0_aw_valid                  ), //o
    .io_outputs_0_aw_ready         (toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_fire), //i
    .io_outputs_0_aw_payload_addr  (axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_addr[31:0]     ), //o
    .io_outputs_0_aw_payload_id    (axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_id[3:0]        ), //o
    .io_outputs_0_aw_payload_len   (axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_len[7:0]       ), //o
    .io_outputs_0_aw_payload_size  (axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_size[2:0]      ), //o
    .io_outputs_0_aw_payload_burst (axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_burst[1:0]     ), //o
    .io_outputs_0_aw_payload_lock  (axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_lock           ), //o
    .io_outputs_0_aw_payload_cache (axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_cache[3:0]     ), //o
    .io_outputs_0_aw_payload_prot  (axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_prot[2:0]      ), //o
    .io_outputs_0_w_valid          (axiIn_0_writeOnly_decoder_io_outputs_0_w_valid                   ), //o
    .io_outputs_0_w_ready          (axi4WriteOnlyArbiter_4_io_inputs_0_w_ready                       ), //i
    .io_outputs_0_w_payload_data   (axiIn_0_writeOnly_decoder_io_outputs_0_w_payload_data[31:0]      ), //o
    .io_outputs_0_w_payload_strb   (axiIn_0_writeOnly_decoder_io_outputs_0_w_payload_strb[3:0]       ), //o
    .io_outputs_0_w_payload_last   (axiIn_0_writeOnly_decoder_io_outputs_0_w_payload_last            ), //o
    .io_outputs_0_b_valid          (axi4WriteOnlyArbiter_4_io_inputs_0_b_valid                       ), //i
    .io_outputs_0_b_ready          (axiIn_0_writeOnly_decoder_io_outputs_0_b_ready                   ), //o
    .io_outputs_0_b_payload_id     (axi4WriteOnlyArbiter_4_io_inputs_0_b_payload_id[3:0]             ), //i
    .io_outputs_0_b_payload_resp   (axi4WriteOnlyArbiter_4_io_inputs_0_b_payload_resp[1:0]           ), //i
    .io_outputs_1_aw_valid         (axiIn_0_writeOnly_decoder_io_outputs_1_aw_valid                  ), //o
    .io_outputs_1_aw_ready         (toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_fire), //i
    .io_outputs_1_aw_payload_addr  (axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_addr[31:0]     ), //o
    .io_outputs_1_aw_payload_id    (axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_id[3:0]        ), //o
    .io_outputs_1_aw_payload_len   (axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_len[7:0]       ), //o
    .io_outputs_1_aw_payload_size  (axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_size[2:0]      ), //o
    .io_outputs_1_aw_payload_burst (axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_burst[1:0]     ), //o
    .io_outputs_1_aw_payload_lock  (axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_lock           ), //o
    .io_outputs_1_aw_payload_cache (axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_cache[3:0]     ), //o
    .io_outputs_1_aw_payload_prot  (axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_prot[2:0]      ), //o
    .io_outputs_1_w_valid          (axiIn_0_writeOnly_decoder_io_outputs_1_w_valid                   ), //o
    .io_outputs_1_w_ready          (axi4WriteOnlyArbiter_5_io_inputs_0_w_ready                       ), //i
    .io_outputs_1_w_payload_data   (axiIn_0_writeOnly_decoder_io_outputs_1_w_payload_data[31:0]      ), //o
    .io_outputs_1_w_payload_strb   (axiIn_0_writeOnly_decoder_io_outputs_1_w_payload_strb[3:0]       ), //o
    .io_outputs_1_w_payload_last   (axiIn_0_writeOnly_decoder_io_outputs_1_w_payload_last            ), //o
    .io_outputs_1_b_valid          (axi4WriteOnlyArbiter_5_io_inputs_0_b_valid                       ), //i
    .io_outputs_1_b_ready          (axiIn_0_writeOnly_decoder_io_outputs_1_b_ready                   ), //o
    .io_outputs_1_b_payload_id     (axi4WriteOnlyArbiter_5_io_inputs_0_b_payload_id[3:0]             ), //i
    .io_outputs_1_b_payload_resp   (axi4WriteOnlyArbiter_5_io_inputs_0_b_payload_resp[1:0]           ), //i
    .io_outputs_2_aw_valid         (axiIn_0_writeOnly_decoder_io_outputs_2_aw_valid                  ), //o
    .io_outputs_2_aw_ready         (toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_fire), //i
    .io_outputs_2_aw_payload_addr  (axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_addr[31:0]     ), //o
    .io_outputs_2_aw_payload_id    (axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_id[3:0]        ), //o
    .io_outputs_2_aw_payload_len   (axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_len[7:0]       ), //o
    .io_outputs_2_aw_payload_size  (axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_size[2:0]      ), //o
    .io_outputs_2_aw_payload_burst (axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_burst[1:0]     ), //o
    .io_outputs_2_aw_payload_lock  (axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_lock           ), //o
    .io_outputs_2_aw_payload_cache (axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_cache[3:0]     ), //o
    .io_outputs_2_aw_payload_prot  (axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_prot[2:0]      ), //o
    .io_outputs_2_w_valid          (axiIn_0_writeOnly_decoder_io_outputs_2_w_valid                   ), //o
    .io_outputs_2_w_ready          (axiOut_2_wready                                                  ), //i
    .io_outputs_2_w_payload_data   (axiIn_0_writeOnly_decoder_io_outputs_2_w_payload_data[31:0]      ), //o
    .io_outputs_2_w_payload_strb   (axiIn_0_writeOnly_decoder_io_outputs_2_w_payload_strb[3:0]       ), //o
    .io_outputs_2_w_payload_last   (axiIn_0_writeOnly_decoder_io_outputs_2_w_payload_last            ), //o
    .io_outputs_2_b_valid          (axiOut_2_bvalid                                                  ), //i
    .io_outputs_2_b_ready          (axiIn_0_writeOnly_decoder_io_outputs_2_b_ready                   ), //o
    .io_outputs_2_b_payload_id     (axiIn_0_writeOnly_decoder_io_outputs_2_b_payload_id[3:0]         ), //i
    .io_outputs_2_b_payload_resp   (axiOut_2_bresp[1:0]                                              ), //i
    .io_outputs_3_aw_valid         (axiIn_0_writeOnly_decoder_io_outputs_3_aw_valid                  ), //o
    .io_outputs_3_aw_ready         (toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_fire), //i
    .io_outputs_3_aw_payload_addr  (axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_addr[31:0]     ), //o
    .io_outputs_3_aw_payload_id    (axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_id[3:0]        ), //o
    .io_outputs_3_aw_payload_len   (axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_len[7:0]       ), //o
    .io_outputs_3_aw_payload_size  (axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_size[2:0]      ), //o
    .io_outputs_3_aw_payload_burst (axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_burst[1:0]     ), //o
    .io_outputs_3_aw_payload_lock  (axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_lock           ), //o
    .io_outputs_3_aw_payload_cache (axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_cache[3:0]     ), //o
    .io_outputs_3_aw_payload_prot  (axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_prot[2:0]      ), //o
    .io_outputs_3_w_valid          (axiIn_0_writeOnly_decoder_io_outputs_3_w_valid                   ), //o
    .io_outputs_3_w_ready          (axiOut_3_wready                                                  ), //i
    .io_outputs_3_w_payload_data   (axiIn_0_writeOnly_decoder_io_outputs_3_w_payload_data[31:0]      ), //o
    .io_outputs_3_w_payload_strb   (axiIn_0_writeOnly_decoder_io_outputs_3_w_payload_strb[3:0]       ), //o
    .io_outputs_3_w_payload_last   (axiIn_0_writeOnly_decoder_io_outputs_3_w_payload_last            ), //o
    .io_outputs_3_b_valid          (axiOut_3_bvalid                                                  ), //i
    .io_outputs_3_b_ready          (axiIn_0_writeOnly_decoder_io_outputs_3_b_ready                   ), //o
    .io_outputs_3_b_payload_id     (axiIn_0_writeOnly_decoder_io_outputs_3_b_payload_id[3:0]         ), //i
    .io_outputs_3_b_payload_resp   (axiOut_3_bresp[1:0]                                              ), //i
    .io_outputs_4_aw_valid         (axiIn_0_writeOnly_decoder_io_outputs_4_aw_valid                  ), //o
    .io_outputs_4_aw_ready         (toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_fire), //i
    .io_outputs_4_aw_payload_addr  (axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_addr[31:0]     ), //o
    .io_outputs_4_aw_payload_id    (axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_id[3:0]        ), //o
    .io_outputs_4_aw_payload_len   (axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_len[7:0]       ), //o
    .io_outputs_4_aw_payload_size  (axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_size[2:0]      ), //o
    .io_outputs_4_aw_payload_burst (axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_burst[1:0]     ), //o
    .io_outputs_4_aw_payload_lock  (axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_lock           ), //o
    .io_outputs_4_aw_payload_cache (axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_cache[3:0]     ), //o
    .io_outputs_4_aw_payload_prot  (axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_prot[2:0]      ), //o
    .io_outputs_4_w_valid          (axiIn_0_writeOnly_decoder_io_outputs_4_w_valid                   ), //o
    .io_outputs_4_w_ready          (axiOut_4_wready                                                  ), //i
    .io_outputs_4_w_payload_data   (axiIn_0_writeOnly_decoder_io_outputs_4_w_payload_data[31:0]      ), //o
    .io_outputs_4_w_payload_strb   (axiIn_0_writeOnly_decoder_io_outputs_4_w_payload_strb[3:0]       ), //o
    .io_outputs_4_w_payload_last   (axiIn_0_writeOnly_decoder_io_outputs_4_w_payload_last            ), //o
    .io_outputs_4_b_valid          (axiOut_4_bvalid                                                  ), //i
    .io_outputs_4_b_ready          (axiIn_0_writeOnly_decoder_io_outputs_4_b_ready                   ), //o
    .io_outputs_4_b_payload_id     (axiIn_0_writeOnly_decoder_io_outputs_4_b_payload_id[3:0]         ), //i
    .io_outputs_4_b_payload_resp   (axiOut_4_bresp[1:0]                                              ), //i
    .io_outputs_5_aw_valid         (axiIn_0_writeOnly_decoder_io_outputs_5_aw_valid                  ), //o
    .io_outputs_5_aw_ready         (toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_fire), //i
    .io_outputs_5_aw_payload_addr  (axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_addr[31:0]     ), //o
    .io_outputs_5_aw_payload_id    (axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_id[3:0]        ), //o
    .io_outputs_5_aw_payload_len   (axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_len[7:0]       ), //o
    .io_outputs_5_aw_payload_size  (axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_size[2:0]      ), //o
    .io_outputs_5_aw_payload_burst (axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_burst[1:0]     ), //o
    .io_outputs_5_aw_payload_lock  (axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_lock           ), //o
    .io_outputs_5_aw_payload_cache (axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_cache[3:0]     ), //o
    .io_outputs_5_aw_payload_prot  (axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_prot[2:0]      ), //o
    .io_outputs_5_w_valid          (axiIn_0_writeOnly_decoder_io_outputs_5_w_valid                   ), //o
    .io_outputs_5_w_ready          (axiOut_5_wready                                                  ), //i
    .io_outputs_5_w_payload_data   (axiIn_0_writeOnly_decoder_io_outputs_5_w_payload_data[31:0]      ), //o
    .io_outputs_5_w_payload_strb   (axiIn_0_writeOnly_decoder_io_outputs_5_w_payload_strb[3:0]       ), //o
    .io_outputs_5_w_payload_last   (axiIn_0_writeOnly_decoder_io_outputs_5_w_payload_last            ), //o
    .io_outputs_5_b_valid          (axiOut_5_bvalid                                                  ), //i
    .io_outputs_5_b_ready          (axiIn_0_writeOnly_decoder_io_outputs_5_b_ready                   ), //o
    .io_outputs_5_b_payload_id     (axiIn_0_writeOnly_decoder_io_outputs_5_b_payload_id[3:0]         ), //i
    .io_outputs_5_b_payload_resp   (axiOut_5_bresp[1:0]                                              ), //i
    .io_outputs_6_aw_valid         (axiIn_0_writeOnly_decoder_io_outputs_6_aw_valid                  ), //o
    .io_outputs_6_aw_ready         (toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_fire), //i
    .io_outputs_6_aw_payload_addr  (axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_addr[31:0]     ), //o
    .io_outputs_6_aw_payload_id    (axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_id[3:0]        ), //o
    .io_outputs_6_aw_payload_len   (axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_len[7:0]       ), //o
    .io_outputs_6_aw_payload_size  (axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_size[2:0]      ), //o
    .io_outputs_6_aw_payload_burst (axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_burst[1:0]     ), //o
    .io_outputs_6_aw_payload_lock  (axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_lock           ), //o
    .io_outputs_6_aw_payload_cache (axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_cache[3:0]     ), //o
    .io_outputs_6_aw_payload_prot  (axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_prot[2:0]      ), //o
    .io_outputs_6_w_valid          (axiIn_0_writeOnly_decoder_io_outputs_6_w_valid                   ), //o
    .io_outputs_6_w_ready          (axi4WriteOnlyArbiter_6_io_inputs_0_w_ready                       ), //i
    .io_outputs_6_w_payload_data   (axiIn_0_writeOnly_decoder_io_outputs_6_w_payload_data[31:0]      ), //o
    .io_outputs_6_w_payload_strb   (axiIn_0_writeOnly_decoder_io_outputs_6_w_payload_strb[3:0]       ), //o
    .io_outputs_6_w_payload_last   (axiIn_0_writeOnly_decoder_io_outputs_6_w_payload_last            ), //o
    .io_outputs_6_b_valid          (axi4WriteOnlyArbiter_6_io_inputs_0_b_valid                       ), //i
    .io_outputs_6_b_ready          (axiIn_0_writeOnly_decoder_io_outputs_6_b_ready                   ), //o
    .io_outputs_6_b_payload_id     (axi4WriteOnlyArbiter_6_io_inputs_0_b_payload_id[3:0]             ), //i
    .io_outputs_6_b_payload_resp   (axi4WriteOnlyArbiter_6_io_inputs_0_b_payload_resp[1:0]           ), //i
    .io_outputs_7_aw_valid         (axiIn_0_writeOnly_decoder_io_outputs_7_aw_valid                  ), //o
    .io_outputs_7_aw_ready         (toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_fire), //i
    .io_outputs_7_aw_payload_addr  (axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_addr[31:0]     ), //o
    .io_outputs_7_aw_payload_id    (axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_id[3:0]        ), //o
    .io_outputs_7_aw_payload_len   (axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_len[7:0]       ), //o
    .io_outputs_7_aw_payload_size  (axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_size[2:0]      ), //o
    .io_outputs_7_aw_payload_burst (axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_burst[1:0]     ), //o
    .io_outputs_7_aw_payload_lock  (axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_lock           ), //o
    .io_outputs_7_aw_payload_cache (axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_cache[3:0]     ), //o
    .io_outputs_7_aw_payload_prot  (axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_prot[2:0]      ), //o
    .io_outputs_7_w_valid          (axiIn_0_writeOnly_decoder_io_outputs_7_w_valid                   ), //o
    .io_outputs_7_w_ready          (axi4WriteOnlyArbiter_7_io_inputs_0_w_ready                       ), //i
    .io_outputs_7_w_payload_data   (axiIn_0_writeOnly_decoder_io_outputs_7_w_payload_data[31:0]      ), //o
    .io_outputs_7_w_payload_strb   (axiIn_0_writeOnly_decoder_io_outputs_7_w_payload_strb[3:0]       ), //o
    .io_outputs_7_w_payload_last   (axiIn_0_writeOnly_decoder_io_outputs_7_w_payload_last            ), //o
    .io_outputs_7_b_valid          (axi4WriteOnlyArbiter_7_io_inputs_0_b_valid                       ), //i
    .io_outputs_7_b_ready          (axiIn_0_writeOnly_decoder_io_outputs_7_b_ready                   ), //o
    .io_outputs_7_b_payload_id     (axi4WriteOnlyArbiter_7_io_inputs_0_b_payload_id[3:0]             ), //i
    .io_outputs_7_b_payload_resp   (axi4WriteOnlyArbiter_7_io_inputs_0_b_payload_resp[1:0]           ), //i
    .clk                           (clk                                                              ), //i
    .resetn                        (resetn                                                           )  //i
  );
  Axi4ReadOnlyDecoder_1 axiIn_1_readOnly_decoder (
    .io_input_ar_valid             (axiIn_1_readOnly_ar_valid                                       ), //i
    .io_input_ar_ready             (axiIn_1_readOnly_decoder_io_input_ar_ready                      ), //o
    .io_input_ar_payload_addr      (axiIn_1_readOnly_ar_payload_addr[31:0]                          ), //i
    .io_input_ar_payload_id        (axiIn_1_readOnly_ar_payload_id[3:0]                             ), //i
    .io_input_ar_payload_len       (axiIn_1_readOnly_ar_payload_len[7:0]                            ), //i
    .io_input_ar_payload_size      (axiIn_1_readOnly_ar_payload_size[2:0]                           ), //i
    .io_input_ar_payload_burst     (axiIn_1_readOnly_ar_payload_burst[1:0]                          ), //i
    .io_input_ar_payload_lock      (axiIn_1_readOnly_ar_payload_lock                                ), //i
    .io_input_ar_payload_cache     (axiIn_1_readOnly_ar_payload_cache[3:0]                          ), //i
    .io_input_ar_payload_prot      (axiIn_1_readOnly_ar_payload_prot[2:0]                           ), //i
    .io_input_r_valid              (axiIn_1_readOnly_decoder_io_input_r_valid                       ), //o
    .io_input_r_ready              (axiIn_1_readOnly_r_ready                                        ), //i
    .io_input_r_payload_data       (axiIn_1_readOnly_decoder_io_input_r_payload_data[31:0]          ), //o
    .io_input_r_payload_id         (axiIn_1_readOnly_decoder_io_input_r_payload_id[3:0]             ), //o
    .io_input_r_payload_resp       (axiIn_1_readOnly_decoder_io_input_r_payload_resp[1:0]           ), //o
    .io_input_r_payload_last       (axiIn_1_readOnly_decoder_io_input_r_payload_last                ), //o
    .io_outputs_0_ar_valid         (axiIn_1_readOnly_decoder_io_outputs_0_ar_valid                  ), //o
    .io_outputs_0_ar_ready         (toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_fire), //i
    .io_outputs_0_ar_payload_addr  (axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_addr[31:0]     ), //o
    .io_outputs_0_ar_payload_id    (axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_id[3:0]        ), //o
    .io_outputs_0_ar_payload_len   (axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_len[7:0]       ), //o
    .io_outputs_0_ar_payload_size  (axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_size[2:0]      ), //o
    .io_outputs_0_ar_payload_burst (axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_burst[1:0]     ), //o
    .io_outputs_0_ar_payload_lock  (axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_lock           ), //o
    .io_outputs_0_ar_payload_cache (axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_cache[3:0]     ), //o
    .io_outputs_0_ar_payload_prot  (axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_prot[2:0]      ), //o
    .io_outputs_0_r_valid          (axi4ReadOnlyArbiter_4_io_inputs_1_r_valid                       ), //i
    .io_outputs_0_r_ready          (axiIn_1_readOnly_decoder_io_outputs_0_r_ready                   ), //o
    .io_outputs_0_r_payload_data   (axi4ReadOnlyArbiter_4_io_inputs_1_r_payload_data[31:0]          ), //i
    .io_outputs_0_r_payload_id     (axi4ReadOnlyArbiter_4_io_inputs_1_r_payload_id[3:0]             ), //i
    .io_outputs_0_r_payload_resp   (axi4ReadOnlyArbiter_4_io_inputs_1_r_payload_resp[1:0]           ), //i
    .io_outputs_0_r_payload_last   (axi4ReadOnlyArbiter_4_io_inputs_1_r_payload_last                ), //i
    .io_outputs_1_ar_valid         (axiIn_1_readOnly_decoder_io_outputs_1_ar_valid                  ), //o
    .io_outputs_1_ar_ready         (toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_fire), //i
    .io_outputs_1_ar_payload_addr  (axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_addr[31:0]     ), //o
    .io_outputs_1_ar_payload_id    (axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_id[3:0]        ), //o
    .io_outputs_1_ar_payload_len   (axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_len[7:0]       ), //o
    .io_outputs_1_ar_payload_size  (axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_size[2:0]      ), //o
    .io_outputs_1_ar_payload_burst (axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_burst[1:0]     ), //o
    .io_outputs_1_ar_payload_lock  (axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_lock           ), //o
    .io_outputs_1_ar_payload_cache (axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_cache[3:0]     ), //o
    .io_outputs_1_ar_payload_prot  (axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_prot[2:0]      ), //o
    .io_outputs_1_r_valid          (axi4ReadOnlyArbiter_5_io_inputs_1_r_valid                       ), //i
    .io_outputs_1_r_ready          (axiIn_1_readOnly_decoder_io_outputs_1_r_ready                   ), //o
    .io_outputs_1_r_payload_data   (axi4ReadOnlyArbiter_5_io_inputs_1_r_payload_data[31:0]          ), //i
    .io_outputs_1_r_payload_id     (axi4ReadOnlyArbiter_5_io_inputs_1_r_payload_id[3:0]             ), //i
    .io_outputs_1_r_payload_resp   (axi4ReadOnlyArbiter_5_io_inputs_1_r_payload_resp[1:0]           ), //i
    .io_outputs_1_r_payload_last   (axi4ReadOnlyArbiter_5_io_inputs_1_r_payload_last                ), //i
    .io_outputs_2_ar_valid         (axiIn_1_readOnly_decoder_io_outputs_2_ar_valid                  ), //o
    .io_outputs_2_ar_ready         (toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_fire), //i
    .io_outputs_2_ar_payload_addr  (axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_addr[31:0]     ), //o
    .io_outputs_2_ar_payload_id    (axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_id[3:0]        ), //o
    .io_outputs_2_ar_payload_len   (axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_len[7:0]       ), //o
    .io_outputs_2_ar_payload_size  (axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_size[2:0]      ), //o
    .io_outputs_2_ar_payload_burst (axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_burst[1:0]     ), //o
    .io_outputs_2_ar_payload_lock  (axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_lock           ), //o
    .io_outputs_2_ar_payload_cache (axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_cache[3:0]     ), //o
    .io_outputs_2_ar_payload_prot  (axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_prot[2:0]      ), //o
    .io_outputs_2_r_valid          (axi4ReadOnlyArbiter_6_io_inputs_1_r_valid                       ), //i
    .io_outputs_2_r_ready          (axiIn_1_readOnly_decoder_io_outputs_2_r_ready                   ), //o
    .io_outputs_2_r_payload_data   (axi4ReadOnlyArbiter_6_io_inputs_1_r_payload_data[31:0]          ), //i
    .io_outputs_2_r_payload_id     (axi4ReadOnlyArbiter_6_io_inputs_1_r_payload_id[3:0]             ), //i
    .io_outputs_2_r_payload_resp   (axi4ReadOnlyArbiter_6_io_inputs_1_r_payload_resp[1:0]           ), //i
    .io_outputs_2_r_payload_last   (axi4ReadOnlyArbiter_6_io_inputs_1_r_payload_last                ), //i
    .io_outputs_3_ar_valid         (axiIn_1_readOnly_decoder_io_outputs_3_ar_valid                  ), //o
    .io_outputs_3_ar_ready         (toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_fire), //i
    .io_outputs_3_ar_payload_addr  (axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_addr[31:0]     ), //o
    .io_outputs_3_ar_payload_id    (axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_id[3:0]        ), //o
    .io_outputs_3_ar_payload_len   (axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_len[7:0]       ), //o
    .io_outputs_3_ar_payload_size  (axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_size[2:0]      ), //o
    .io_outputs_3_ar_payload_burst (axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_burst[1:0]     ), //o
    .io_outputs_3_ar_payload_lock  (axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_lock           ), //o
    .io_outputs_3_ar_payload_cache (axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_cache[3:0]     ), //o
    .io_outputs_3_ar_payload_prot  (axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_prot[2:0]      ), //o
    .io_outputs_3_r_valid          (axi4ReadOnlyArbiter_7_io_inputs_1_r_valid                       ), //i
    .io_outputs_3_r_ready          (axiIn_1_readOnly_decoder_io_outputs_3_r_ready                   ), //o
    .io_outputs_3_r_payload_data   (axi4ReadOnlyArbiter_7_io_inputs_1_r_payload_data[31:0]          ), //i
    .io_outputs_3_r_payload_id     (axi4ReadOnlyArbiter_7_io_inputs_1_r_payload_id[3:0]             ), //i
    .io_outputs_3_r_payload_resp   (axi4ReadOnlyArbiter_7_io_inputs_1_r_payload_resp[1:0]           ), //i
    .io_outputs_3_r_payload_last   (axi4ReadOnlyArbiter_7_io_inputs_1_r_payload_last                ), //i
    .clk                           (clk                                                             ), //i
    .resetn                        (resetn                                                          )  //i
  );
  Axi4WriteOnlyDecoder_1 axiIn_1_writeOnly_decoder (
    .io_input_aw_valid             (axiIn_1_writeOnly_aw_valid                                       ), //i
    .io_input_aw_ready             (axiIn_1_writeOnly_decoder_io_input_aw_ready                      ), //o
    .io_input_aw_payload_addr      (axiIn_1_writeOnly_aw_payload_addr[31:0]                          ), //i
    .io_input_aw_payload_id        (axiIn_1_writeOnly_aw_payload_id[3:0]                             ), //i
    .io_input_aw_payload_len       (axiIn_1_writeOnly_aw_payload_len[7:0]                            ), //i
    .io_input_aw_payload_size      (axiIn_1_writeOnly_aw_payload_size[2:0]                           ), //i
    .io_input_aw_payload_burst     (axiIn_1_writeOnly_aw_payload_burst[1:0]                          ), //i
    .io_input_aw_payload_lock      (axiIn_1_writeOnly_aw_payload_lock                                ), //i
    .io_input_aw_payload_cache     (axiIn_1_writeOnly_aw_payload_cache[3:0]                          ), //i
    .io_input_aw_payload_prot      (axiIn_1_writeOnly_aw_payload_prot[2:0]                           ), //i
    .io_input_w_valid              (axiIn_1_writeOnly_w_valid                                        ), //i
    .io_input_w_ready              (axiIn_1_writeOnly_decoder_io_input_w_ready                       ), //o
    .io_input_w_payload_data       (axiIn_1_writeOnly_w_payload_data[31:0]                           ), //i
    .io_input_w_payload_strb       (axiIn_1_writeOnly_w_payload_strb[3:0]                            ), //i
    .io_input_w_payload_last       (axiIn_1_writeOnly_w_payload_last                                 ), //i
    .io_input_b_valid              (axiIn_1_writeOnly_decoder_io_input_b_valid                       ), //o
    .io_input_b_ready              (axiIn_1_writeOnly_b_ready                                        ), //i
    .io_input_b_payload_id         (axiIn_1_writeOnly_decoder_io_input_b_payload_id[3:0]             ), //o
    .io_input_b_payload_resp       (axiIn_1_writeOnly_decoder_io_input_b_payload_resp[1:0]           ), //o
    .io_outputs_0_aw_valid         (axiIn_1_writeOnly_decoder_io_outputs_0_aw_valid                  ), //o
    .io_outputs_0_aw_ready         (toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_fire), //i
    .io_outputs_0_aw_payload_addr  (axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_addr[31:0]     ), //o
    .io_outputs_0_aw_payload_id    (axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_id[3:0]        ), //o
    .io_outputs_0_aw_payload_len   (axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_len[7:0]       ), //o
    .io_outputs_0_aw_payload_size  (axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_size[2:0]      ), //o
    .io_outputs_0_aw_payload_burst (axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_burst[1:0]     ), //o
    .io_outputs_0_aw_payload_lock  (axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_lock           ), //o
    .io_outputs_0_aw_payload_cache (axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_cache[3:0]     ), //o
    .io_outputs_0_aw_payload_prot  (axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_prot[2:0]      ), //o
    .io_outputs_0_w_valid          (axiIn_1_writeOnly_decoder_io_outputs_0_w_valid                   ), //o
    .io_outputs_0_w_ready          (axi4WriteOnlyArbiter_4_io_inputs_1_w_ready                       ), //i
    .io_outputs_0_w_payload_data   (axiIn_1_writeOnly_decoder_io_outputs_0_w_payload_data[31:0]      ), //o
    .io_outputs_0_w_payload_strb   (axiIn_1_writeOnly_decoder_io_outputs_0_w_payload_strb[3:0]       ), //o
    .io_outputs_0_w_payload_last   (axiIn_1_writeOnly_decoder_io_outputs_0_w_payload_last            ), //o
    .io_outputs_0_b_valid          (axi4WriteOnlyArbiter_4_io_inputs_1_b_valid                       ), //i
    .io_outputs_0_b_ready          (axiIn_1_writeOnly_decoder_io_outputs_0_b_ready                   ), //o
    .io_outputs_0_b_payload_id     (axi4WriteOnlyArbiter_4_io_inputs_1_b_payload_id[3:0]             ), //i
    .io_outputs_0_b_payload_resp   (axi4WriteOnlyArbiter_4_io_inputs_1_b_payload_resp[1:0]           ), //i
    .io_outputs_1_aw_valid         (axiIn_1_writeOnly_decoder_io_outputs_1_aw_valid                  ), //o
    .io_outputs_1_aw_ready         (toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_fire), //i
    .io_outputs_1_aw_payload_addr  (axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_addr[31:0]     ), //o
    .io_outputs_1_aw_payload_id    (axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_id[3:0]        ), //o
    .io_outputs_1_aw_payload_len   (axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_len[7:0]       ), //o
    .io_outputs_1_aw_payload_size  (axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_size[2:0]      ), //o
    .io_outputs_1_aw_payload_burst (axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_burst[1:0]     ), //o
    .io_outputs_1_aw_payload_lock  (axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_lock           ), //o
    .io_outputs_1_aw_payload_cache (axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_cache[3:0]     ), //o
    .io_outputs_1_aw_payload_prot  (axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_prot[2:0]      ), //o
    .io_outputs_1_w_valid          (axiIn_1_writeOnly_decoder_io_outputs_1_w_valid                   ), //o
    .io_outputs_1_w_ready          (axi4WriteOnlyArbiter_5_io_inputs_1_w_ready                       ), //i
    .io_outputs_1_w_payload_data   (axiIn_1_writeOnly_decoder_io_outputs_1_w_payload_data[31:0]      ), //o
    .io_outputs_1_w_payload_strb   (axiIn_1_writeOnly_decoder_io_outputs_1_w_payload_strb[3:0]       ), //o
    .io_outputs_1_w_payload_last   (axiIn_1_writeOnly_decoder_io_outputs_1_w_payload_last            ), //o
    .io_outputs_1_b_valid          (axi4WriteOnlyArbiter_5_io_inputs_1_b_valid                       ), //i
    .io_outputs_1_b_ready          (axiIn_1_writeOnly_decoder_io_outputs_1_b_ready                   ), //o
    .io_outputs_1_b_payload_id     (axi4WriteOnlyArbiter_5_io_inputs_1_b_payload_id[3:0]             ), //i
    .io_outputs_1_b_payload_resp   (axi4WriteOnlyArbiter_5_io_inputs_1_b_payload_resp[1:0]           ), //i
    .io_outputs_2_aw_valid         (axiIn_1_writeOnly_decoder_io_outputs_2_aw_valid                  ), //o
    .io_outputs_2_aw_ready         (toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_fire), //i
    .io_outputs_2_aw_payload_addr  (axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_addr[31:0]     ), //o
    .io_outputs_2_aw_payload_id    (axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_id[3:0]        ), //o
    .io_outputs_2_aw_payload_len   (axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_len[7:0]       ), //o
    .io_outputs_2_aw_payload_size  (axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_size[2:0]      ), //o
    .io_outputs_2_aw_payload_burst (axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_burst[1:0]     ), //o
    .io_outputs_2_aw_payload_lock  (axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_lock           ), //o
    .io_outputs_2_aw_payload_cache (axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_cache[3:0]     ), //o
    .io_outputs_2_aw_payload_prot  (axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_prot[2:0]      ), //o
    .io_outputs_2_w_valid          (axiIn_1_writeOnly_decoder_io_outputs_2_w_valid                   ), //o
    .io_outputs_2_w_ready          (axi4WriteOnlyArbiter_6_io_inputs_1_w_ready                       ), //i
    .io_outputs_2_w_payload_data   (axiIn_1_writeOnly_decoder_io_outputs_2_w_payload_data[31:0]      ), //o
    .io_outputs_2_w_payload_strb   (axiIn_1_writeOnly_decoder_io_outputs_2_w_payload_strb[3:0]       ), //o
    .io_outputs_2_w_payload_last   (axiIn_1_writeOnly_decoder_io_outputs_2_w_payload_last            ), //o
    .io_outputs_2_b_valid          (axi4WriteOnlyArbiter_6_io_inputs_1_b_valid                       ), //i
    .io_outputs_2_b_ready          (axiIn_1_writeOnly_decoder_io_outputs_2_b_ready                   ), //o
    .io_outputs_2_b_payload_id     (axi4WriteOnlyArbiter_6_io_inputs_1_b_payload_id[3:0]             ), //i
    .io_outputs_2_b_payload_resp   (axi4WriteOnlyArbiter_6_io_inputs_1_b_payload_resp[1:0]           ), //i
    .io_outputs_3_aw_valid         (axiIn_1_writeOnly_decoder_io_outputs_3_aw_valid                  ), //o
    .io_outputs_3_aw_ready         (toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_fire), //i
    .io_outputs_3_aw_payload_addr  (axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_addr[31:0]     ), //o
    .io_outputs_3_aw_payload_id    (axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_id[3:0]        ), //o
    .io_outputs_3_aw_payload_len   (axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_len[7:0]       ), //o
    .io_outputs_3_aw_payload_size  (axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_size[2:0]      ), //o
    .io_outputs_3_aw_payload_burst (axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_burst[1:0]     ), //o
    .io_outputs_3_aw_payload_lock  (axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_lock           ), //o
    .io_outputs_3_aw_payload_cache (axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_cache[3:0]     ), //o
    .io_outputs_3_aw_payload_prot  (axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_prot[2:0]      ), //o
    .io_outputs_3_w_valid          (axiIn_1_writeOnly_decoder_io_outputs_3_w_valid                   ), //o
    .io_outputs_3_w_ready          (axi4WriteOnlyArbiter_7_io_inputs_1_w_ready                       ), //i
    .io_outputs_3_w_payload_data   (axiIn_1_writeOnly_decoder_io_outputs_3_w_payload_data[31:0]      ), //o
    .io_outputs_3_w_payload_strb   (axiIn_1_writeOnly_decoder_io_outputs_3_w_payload_strb[3:0]       ), //o
    .io_outputs_3_w_payload_last   (axiIn_1_writeOnly_decoder_io_outputs_3_w_payload_last            ), //o
    .io_outputs_3_b_valid          (axi4WriteOnlyArbiter_7_io_inputs_1_b_valid                       ), //i
    .io_outputs_3_b_ready          (axiIn_1_writeOnly_decoder_io_outputs_3_b_ready                   ), //o
    .io_outputs_3_b_payload_id     (axi4WriteOnlyArbiter_7_io_inputs_1_b_payload_id[3:0]             ), //i
    .io_outputs_3_b_payload_resp   (axi4WriteOnlyArbiter_7_io_inputs_1_b_payload_resp[1:0]           ), //i
    .clk                           (clk                                                              ), //i
    .resetn                        (resetn                                                           )  //i
  );
  Axi4ReadOnlyArbiter axi4ReadOnlyArbiter_4 (
    .io_inputs_0_ar_valid         (toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_valid             ), //i
    .io_inputs_0_ar_ready         (axi4ReadOnlyArbiter_4_io_inputs_0_ar_ready                                    ), //o
    .io_inputs_0_ar_payload_addr  (toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_addr[31:0]), //i
    .io_inputs_0_ar_payload_id    (toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_id[3:0]   ), //i
    .io_inputs_0_ar_payload_len   (toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_len[7:0]  ), //i
    .io_inputs_0_ar_payload_size  (toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_size[2:0] ), //i
    .io_inputs_0_ar_payload_burst (toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_burst[1:0]), //i
    .io_inputs_0_ar_payload_lock  (toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_lock      ), //i
    .io_inputs_0_ar_payload_cache (toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_cache[3:0]), //i
    .io_inputs_0_ar_payload_prot  (toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_prot[2:0] ), //i
    .io_inputs_0_r_valid          (axi4ReadOnlyArbiter_4_io_inputs_0_r_valid                                     ), //o
    .io_inputs_0_r_ready          (axiIn_0_readOnly_decoder_io_outputs_0_r_ready                                 ), //i
    .io_inputs_0_r_payload_data   (axi4ReadOnlyArbiter_4_io_inputs_0_r_payload_data[31:0]                        ), //o
    .io_inputs_0_r_payload_id     (axi4ReadOnlyArbiter_4_io_inputs_0_r_payload_id[3:0]                           ), //o
    .io_inputs_0_r_payload_resp   (axi4ReadOnlyArbiter_4_io_inputs_0_r_payload_resp[1:0]                         ), //o
    .io_inputs_0_r_payload_last   (axi4ReadOnlyArbiter_4_io_inputs_0_r_payload_last                              ), //o
    .io_inputs_1_ar_valid         (toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_valid             ), //i
    .io_inputs_1_ar_ready         (axi4ReadOnlyArbiter_4_io_inputs_1_ar_ready                                    ), //o
    .io_inputs_1_ar_payload_addr  (toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_addr[31:0]), //i
    .io_inputs_1_ar_payload_id    (toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_id[3:0]   ), //i
    .io_inputs_1_ar_payload_len   (toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_len[7:0]  ), //i
    .io_inputs_1_ar_payload_size  (toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_size[2:0] ), //i
    .io_inputs_1_ar_payload_burst (toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_burst[1:0]), //i
    .io_inputs_1_ar_payload_lock  (toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_lock      ), //i
    .io_inputs_1_ar_payload_cache (toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_cache[3:0]), //i
    .io_inputs_1_ar_payload_prot  (toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_prot[2:0] ), //i
    .io_inputs_1_r_valid          (axi4ReadOnlyArbiter_4_io_inputs_1_r_valid                                     ), //o
    .io_inputs_1_r_ready          (axiIn_1_readOnly_decoder_io_outputs_0_r_ready                                 ), //i
    .io_inputs_1_r_payload_data   (axi4ReadOnlyArbiter_4_io_inputs_1_r_payload_data[31:0]                        ), //o
    .io_inputs_1_r_payload_id     (axi4ReadOnlyArbiter_4_io_inputs_1_r_payload_id[3:0]                           ), //o
    .io_inputs_1_r_payload_resp   (axi4ReadOnlyArbiter_4_io_inputs_1_r_payload_resp[1:0]                         ), //o
    .io_inputs_1_r_payload_last   (axi4ReadOnlyArbiter_4_io_inputs_1_r_payload_last                              ), //o
    .io_output_ar_valid           (axi4ReadOnlyArbiter_4_io_output_ar_valid                                      ), //o
    .io_output_ar_ready           (axiOut_0_arready                                                              ), //i
    .io_output_ar_payload_addr    (axi4ReadOnlyArbiter_4_io_output_ar_payload_addr[31:0]                         ), //o
    .io_output_ar_payload_id      (axi4ReadOnlyArbiter_4_io_output_ar_payload_id[4:0]                            ), //o
    .io_output_ar_payload_len     (axi4ReadOnlyArbiter_4_io_output_ar_payload_len[7:0]                           ), //o
    .io_output_ar_payload_size    (axi4ReadOnlyArbiter_4_io_output_ar_payload_size[2:0]                          ), //o
    .io_output_ar_payload_burst   (axi4ReadOnlyArbiter_4_io_output_ar_payload_burst[1:0]                         ), //o
    .io_output_ar_payload_lock    (axi4ReadOnlyArbiter_4_io_output_ar_payload_lock                               ), //o
    .io_output_ar_payload_cache   (axi4ReadOnlyArbiter_4_io_output_ar_payload_cache[3:0]                         ), //o
    .io_output_ar_payload_prot    (axi4ReadOnlyArbiter_4_io_output_ar_payload_prot[2:0]                          ), //o
    .io_output_r_valid            (axiOut_0_rvalid                                                               ), //i
    .io_output_r_ready            (axi4ReadOnlyArbiter_4_io_output_r_ready                                       ), //o
    .io_output_r_payload_data     (axiOut_0_rdata[31:0]                                                          ), //i
    .io_output_r_payload_id       (axiOut_0_rid[4:0]                                                             ), //i
    .io_output_r_payload_resp     (axiOut_0_rresp[1:0]                                                           ), //i
    .io_output_r_payload_last     (axiOut_0_rlast                                                                ), //i
    .clk                          (clk                                                                           ), //i
    .resetn                       (resetn                                                                        )  //i
  );
  Axi4WriteOnlyArbiter axi4WriteOnlyArbiter_4 (
    .io_inputs_0_aw_valid         (toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_valid             ), //i
    .io_inputs_0_aw_ready         (axi4WriteOnlyArbiter_4_io_inputs_0_aw_ready                                    ), //o
    .io_inputs_0_aw_payload_addr  (toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_addr[31:0]), //i
    .io_inputs_0_aw_payload_id    (toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_id[3:0]   ), //i
    .io_inputs_0_aw_payload_len   (toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_len[7:0]  ), //i
    .io_inputs_0_aw_payload_size  (toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_size[2:0] ), //i
    .io_inputs_0_aw_payload_burst (toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_burst[1:0]), //i
    .io_inputs_0_aw_payload_lock  (toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_lock      ), //i
    .io_inputs_0_aw_payload_cache (toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_cache[3:0]), //i
    .io_inputs_0_aw_payload_prot  (toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_prot[2:0] ), //i
    .io_inputs_0_w_valid          (axiIn_0_writeOnly_decoder_io_outputs_0_w_valid                                 ), //i
    .io_inputs_0_w_ready          (axi4WriteOnlyArbiter_4_io_inputs_0_w_ready                                     ), //o
    .io_inputs_0_w_payload_data   (axiIn_0_writeOnly_decoder_io_outputs_0_w_payload_data[31:0]                    ), //i
    .io_inputs_0_w_payload_strb   (axiIn_0_writeOnly_decoder_io_outputs_0_w_payload_strb[3:0]                     ), //i
    .io_inputs_0_w_payload_last   (axiIn_0_writeOnly_decoder_io_outputs_0_w_payload_last                          ), //i
    .io_inputs_0_b_valid          (axi4WriteOnlyArbiter_4_io_inputs_0_b_valid                                     ), //o
    .io_inputs_0_b_ready          (axiIn_0_writeOnly_decoder_io_outputs_0_b_ready                                 ), //i
    .io_inputs_0_b_payload_id     (axi4WriteOnlyArbiter_4_io_inputs_0_b_payload_id[3:0]                           ), //o
    .io_inputs_0_b_payload_resp   (axi4WriteOnlyArbiter_4_io_inputs_0_b_payload_resp[1:0]                         ), //o
    .io_inputs_1_aw_valid         (toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_valid             ), //i
    .io_inputs_1_aw_ready         (axi4WriteOnlyArbiter_4_io_inputs_1_aw_ready                                    ), //o
    .io_inputs_1_aw_payload_addr  (toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_addr[31:0]), //i
    .io_inputs_1_aw_payload_id    (toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_id[3:0]   ), //i
    .io_inputs_1_aw_payload_len   (toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_len[7:0]  ), //i
    .io_inputs_1_aw_payload_size  (toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_size[2:0] ), //i
    .io_inputs_1_aw_payload_burst (toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_burst[1:0]), //i
    .io_inputs_1_aw_payload_lock  (toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_lock      ), //i
    .io_inputs_1_aw_payload_cache (toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_cache[3:0]), //i
    .io_inputs_1_aw_payload_prot  (toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_prot[2:0] ), //i
    .io_inputs_1_w_valid          (axiIn_1_writeOnly_decoder_io_outputs_0_w_valid                                 ), //i
    .io_inputs_1_w_ready          (axi4WriteOnlyArbiter_4_io_inputs_1_w_ready                                     ), //o
    .io_inputs_1_w_payload_data   (axiIn_1_writeOnly_decoder_io_outputs_0_w_payload_data[31:0]                    ), //i
    .io_inputs_1_w_payload_strb   (axiIn_1_writeOnly_decoder_io_outputs_0_w_payload_strb[3:0]                     ), //i
    .io_inputs_1_w_payload_last   (axiIn_1_writeOnly_decoder_io_outputs_0_w_payload_last                          ), //i
    .io_inputs_1_b_valid          (axi4WriteOnlyArbiter_4_io_inputs_1_b_valid                                     ), //o
    .io_inputs_1_b_ready          (axiIn_1_writeOnly_decoder_io_outputs_0_b_ready                                 ), //i
    .io_inputs_1_b_payload_id     (axi4WriteOnlyArbiter_4_io_inputs_1_b_payload_id[3:0]                           ), //o
    .io_inputs_1_b_payload_resp   (axi4WriteOnlyArbiter_4_io_inputs_1_b_payload_resp[1:0]                         ), //o
    .io_output_aw_valid           (axi4WriteOnlyArbiter_4_io_output_aw_valid                                      ), //o
    .io_output_aw_ready           (axiOut_0_awready                                                               ), //i
    .io_output_aw_payload_addr    (axi4WriteOnlyArbiter_4_io_output_aw_payload_addr[31:0]                         ), //o
    .io_output_aw_payload_id      (axi4WriteOnlyArbiter_4_io_output_aw_payload_id[4:0]                            ), //o
    .io_output_aw_payload_len     (axi4WriteOnlyArbiter_4_io_output_aw_payload_len[7:0]                           ), //o
    .io_output_aw_payload_size    (axi4WriteOnlyArbiter_4_io_output_aw_payload_size[2:0]                          ), //o
    .io_output_aw_payload_burst   (axi4WriteOnlyArbiter_4_io_output_aw_payload_burst[1:0]                         ), //o
    .io_output_aw_payload_lock    (axi4WriteOnlyArbiter_4_io_output_aw_payload_lock                               ), //o
    .io_output_aw_payload_cache   (axi4WriteOnlyArbiter_4_io_output_aw_payload_cache[3:0]                         ), //o
    .io_output_aw_payload_prot    (axi4WriteOnlyArbiter_4_io_output_aw_payload_prot[2:0]                          ), //o
    .io_output_w_valid            (axi4WriteOnlyArbiter_4_io_output_w_valid                                       ), //o
    .io_output_w_ready            (axiOut_0_wready                                                                ), //i
    .io_output_w_payload_data     (axi4WriteOnlyArbiter_4_io_output_w_payload_data[31:0]                          ), //o
    .io_output_w_payload_strb     (axi4WriteOnlyArbiter_4_io_output_w_payload_strb[3:0]                           ), //o
    .io_output_w_payload_last     (axi4WriteOnlyArbiter_4_io_output_w_payload_last                                ), //o
    .io_output_b_valid            (axiOut_0_bvalid                                                                ), //i
    .io_output_b_ready            (axi4WriteOnlyArbiter_4_io_output_b_ready                                       ), //o
    .io_output_b_payload_id       (axiOut_0_bid[4:0]                                                              ), //i
    .io_output_b_payload_resp     (axiOut_0_bresp[1:0]                                                            ), //i
    .clk                          (clk                                                                            ), //i
    .resetn                       (resetn                                                                         )  //i
  );
  Axi4ReadOnlyArbiter axi4ReadOnlyArbiter_5 (
    .io_inputs_0_ar_valid         (toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_valid             ), //i
    .io_inputs_0_ar_ready         (axi4ReadOnlyArbiter_5_io_inputs_0_ar_ready                                    ), //o
    .io_inputs_0_ar_payload_addr  (toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_addr[31:0]), //i
    .io_inputs_0_ar_payload_id    (toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_id[3:0]   ), //i
    .io_inputs_0_ar_payload_len   (toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_len[7:0]  ), //i
    .io_inputs_0_ar_payload_size  (toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_size[2:0] ), //i
    .io_inputs_0_ar_payload_burst (toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_burst[1:0]), //i
    .io_inputs_0_ar_payload_lock  (toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_lock      ), //i
    .io_inputs_0_ar_payload_cache (toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_cache[3:0]), //i
    .io_inputs_0_ar_payload_prot  (toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_prot[2:0] ), //i
    .io_inputs_0_r_valid          (axi4ReadOnlyArbiter_5_io_inputs_0_r_valid                                     ), //o
    .io_inputs_0_r_ready          (axiIn_0_readOnly_decoder_io_outputs_1_r_ready                                 ), //i
    .io_inputs_0_r_payload_data   (axi4ReadOnlyArbiter_5_io_inputs_0_r_payload_data[31:0]                        ), //o
    .io_inputs_0_r_payload_id     (axi4ReadOnlyArbiter_5_io_inputs_0_r_payload_id[3:0]                           ), //o
    .io_inputs_0_r_payload_resp   (axi4ReadOnlyArbiter_5_io_inputs_0_r_payload_resp[1:0]                         ), //o
    .io_inputs_0_r_payload_last   (axi4ReadOnlyArbiter_5_io_inputs_0_r_payload_last                              ), //o
    .io_inputs_1_ar_valid         (toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_valid             ), //i
    .io_inputs_1_ar_ready         (axi4ReadOnlyArbiter_5_io_inputs_1_ar_ready                                    ), //o
    .io_inputs_1_ar_payload_addr  (toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_addr[31:0]), //i
    .io_inputs_1_ar_payload_id    (toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_id[3:0]   ), //i
    .io_inputs_1_ar_payload_len   (toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_len[7:0]  ), //i
    .io_inputs_1_ar_payload_size  (toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_size[2:0] ), //i
    .io_inputs_1_ar_payload_burst (toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_burst[1:0]), //i
    .io_inputs_1_ar_payload_lock  (toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_lock      ), //i
    .io_inputs_1_ar_payload_cache (toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_cache[3:0]), //i
    .io_inputs_1_ar_payload_prot  (toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_prot[2:0] ), //i
    .io_inputs_1_r_valid          (axi4ReadOnlyArbiter_5_io_inputs_1_r_valid                                     ), //o
    .io_inputs_1_r_ready          (axiIn_1_readOnly_decoder_io_outputs_1_r_ready                                 ), //i
    .io_inputs_1_r_payload_data   (axi4ReadOnlyArbiter_5_io_inputs_1_r_payload_data[31:0]                        ), //o
    .io_inputs_1_r_payload_id     (axi4ReadOnlyArbiter_5_io_inputs_1_r_payload_id[3:0]                           ), //o
    .io_inputs_1_r_payload_resp   (axi4ReadOnlyArbiter_5_io_inputs_1_r_payload_resp[1:0]                         ), //o
    .io_inputs_1_r_payload_last   (axi4ReadOnlyArbiter_5_io_inputs_1_r_payload_last                              ), //o
    .io_output_ar_valid           (axi4ReadOnlyArbiter_5_io_output_ar_valid                                      ), //o
    .io_output_ar_ready           (axiOut_1_arready                                                              ), //i
    .io_output_ar_payload_addr    (axi4ReadOnlyArbiter_5_io_output_ar_payload_addr[31:0]                         ), //o
    .io_output_ar_payload_id      (axi4ReadOnlyArbiter_5_io_output_ar_payload_id[4:0]                            ), //o
    .io_output_ar_payload_len     (axi4ReadOnlyArbiter_5_io_output_ar_payload_len[7:0]                           ), //o
    .io_output_ar_payload_size    (axi4ReadOnlyArbiter_5_io_output_ar_payload_size[2:0]                          ), //o
    .io_output_ar_payload_burst   (axi4ReadOnlyArbiter_5_io_output_ar_payload_burst[1:0]                         ), //o
    .io_output_ar_payload_lock    (axi4ReadOnlyArbiter_5_io_output_ar_payload_lock                               ), //o
    .io_output_ar_payload_cache   (axi4ReadOnlyArbiter_5_io_output_ar_payload_cache[3:0]                         ), //o
    .io_output_ar_payload_prot    (axi4ReadOnlyArbiter_5_io_output_ar_payload_prot[2:0]                          ), //o
    .io_output_r_valid            (axiOut_1_rvalid                                                               ), //i
    .io_output_r_ready            (axi4ReadOnlyArbiter_5_io_output_r_ready                                       ), //o
    .io_output_r_payload_data     (axiOut_1_rdata[31:0]                                                          ), //i
    .io_output_r_payload_id       (axiOut_1_rid[4:0]                                                             ), //i
    .io_output_r_payload_resp     (axiOut_1_rresp[1:0]                                                           ), //i
    .io_output_r_payload_last     (axiOut_1_rlast                                                                ), //i
    .clk                          (clk                                                                           ), //i
    .resetn                       (resetn                                                                        )  //i
  );
  Axi4WriteOnlyArbiter_1 axi4WriteOnlyArbiter_5 (
    .io_inputs_0_aw_valid         (toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_valid             ), //i
    .io_inputs_0_aw_ready         (axi4WriteOnlyArbiter_5_io_inputs_0_aw_ready                                    ), //o
    .io_inputs_0_aw_payload_addr  (toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_addr[31:0]), //i
    .io_inputs_0_aw_payload_id    (toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_id[3:0]   ), //i
    .io_inputs_0_aw_payload_len   (toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_len[7:0]  ), //i
    .io_inputs_0_aw_payload_size  (toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_size[2:0] ), //i
    .io_inputs_0_aw_payload_burst (toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_burst[1:0]), //i
    .io_inputs_0_aw_payload_lock  (toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_lock      ), //i
    .io_inputs_0_aw_payload_cache (toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_cache[3:0]), //i
    .io_inputs_0_aw_payload_prot  (toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_prot[2:0] ), //i
    .io_inputs_0_w_valid          (axiIn_0_writeOnly_decoder_io_outputs_1_w_valid                                 ), //i
    .io_inputs_0_w_ready          (axi4WriteOnlyArbiter_5_io_inputs_0_w_ready                                     ), //o
    .io_inputs_0_w_payload_data   (axiIn_0_writeOnly_decoder_io_outputs_1_w_payload_data[31:0]                    ), //i
    .io_inputs_0_w_payload_strb   (axiIn_0_writeOnly_decoder_io_outputs_1_w_payload_strb[3:0]                     ), //i
    .io_inputs_0_w_payload_last   (axiIn_0_writeOnly_decoder_io_outputs_1_w_payload_last                          ), //i
    .io_inputs_0_b_valid          (axi4WriteOnlyArbiter_5_io_inputs_0_b_valid                                     ), //o
    .io_inputs_0_b_ready          (axiIn_0_writeOnly_decoder_io_outputs_1_b_ready                                 ), //i
    .io_inputs_0_b_payload_id     (axi4WriteOnlyArbiter_5_io_inputs_0_b_payload_id[3:0]                           ), //o
    .io_inputs_0_b_payload_resp   (axi4WriteOnlyArbiter_5_io_inputs_0_b_payload_resp[1:0]                         ), //o
    .io_inputs_1_aw_valid         (toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_valid             ), //i
    .io_inputs_1_aw_ready         (axi4WriteOnlyArbiter_5_io_inputs_1_aw_ready                                    ), //o
    .io_inputs_1_aw_payload_addr  (toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_addr[31:0]), //i
    .io_inputs_1_aw_payload_id    (toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_id[3:0]   ), //i
    .io_inputs_1_aw_payload_len   (toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_len[7:0]  ), //i
    .io_inputs_1_aw_payload_size  (toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_size[2:0] ), //i
    .io_inputs_1_aw_payload_burst (toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_burst[1:0]), //i
    .io_inputs_1_aw_payload_lock  (toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_lock      ), //i
    .io_inputs_1_aw_payload_cache (toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_cache[3:0]), //i
    .io_inputs_1_aw_payload_prot  (toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_prot[2:0] ), //i
    .io_inputs_1_w_valid          (axiIn_1_writeOnly_decoder_io_outputs_1_w_valid                                 ), //i
    .io_inputs_1_w_ready          (axi4WriteOnlyArbiter_5_io_inputs_1_w_ready                                     ), //o
    .io_inputs_1_w_payload_data   (axiIn_1_writeOnly_decoder_io_outputs_1_w_payload_data[31:0]                    ), //i
    .io_inputs_1_w_payload_strb   (axiIn_1_writeOnly_decoder_io_outputs_1_w_payload_strb[3:0]                     ), //i
    .io_inputs_1_w_payload_last   (axiIn_1_writeOnly_decoder_io_outputs_1_w_payload_last                          ), //i
    .io_inputs_1_b_valid          (axi4WriteOnlyArbiter_5_io_inputs_1_b_valid                                     ), //o
    .io_inputs_1_b_ready          (axiIn_1_writeOnly_decoder_io_outputs_1_b_ready                                 ), //i
    .io_inputs_1_b_payload_id     (axi4WriteOnlyArbiter_5_io_inputs_1_b_payload_id[3:0]                           ), //o
    .io_inputs_1_b_payload_resp   (axi4WriteOnlyArbiter_5_io_inputs_1_b_payload_resp[1:0]                         ), //o
    .io_output_aw_valid           (axi4WriteOnlyArbiter_5_io_output_aw_valid                                      ), //o
    .io_output_aw_ready           (axiOut_1_awready                                                               ), //i
    .io_output_aw_payload_addr    (axi4WriteOnlyArbiter_5_io_output_aw_payload_addr[31:0]                         ), //o
    .io_output_aw_payload_id      (axi4WriteOnlyArbiter_5_io_output_aw_payload_id[4:0]                            ), //o
    .io_output_aw_payload_len     (axi4WriteOnlyArbiter_5_io_output_aw_payload_len[7:0]                           ), //o
    .io_output_aw_payload_size    (axi4WriteOnlyArbiter_5_io_output_aw_payload_size[2:0]                          ), //o
    .io_output_aw_payload_burst   (axi4WriteOnlyArbiter_5_io_output_aw_payload_burst[1:0]                         ), //o
    .io_output_aw_payload_lock    (axi4WriteOnlyArbiter_5_io_output_aw_payload_lock                               ), //o
    .io_output_aw_payload_cache   (axi4WriteOnlyArbiter_5_io_output_aw_payload_cache[3:0]                         ), //o
    .io_output_aw_payload_prot    (axi4WriteOnlyArbiter_5_io_output_aw_payload_prot[2:0]                          ), //o
    .io_output_w_valid            (axi4WriteOnlyArbiter_5_io_output_w_valid                                       ), //o
    .io_output_w_ready            (axiOut_1_wready                                                                ), //i
    .io_output_w_payload_data     (axi4WriteOnlyArbiter_5_io_output_w_payload_data[31:0]                          ), //o
    .io_output_w_payload_strb     (axi4WriteOnlyArbiter_5_io_output_w_payload_strb[3:0]                           ), //o
    .io_output_w_payload_last     (axi4WriteOnlyArbiter_5_io_output_w_payload_last                                ), //o
    .io_output_b_valid            (axiOut_1_bvalid                                                                ), //i
    .io_output_b_ready            (axi4WriteOnlyArbiter_5_io_output_b_ready                                       ), //o
    .io_output_b_payload_id       (axiOut_1_bid[4:0]                                                              ), //i
    .io_output_b_payload_resp     (axiOut_1_bresp[1:0]                                                            ), //i
    .clk                          (clk                                                                            ), //i
    .resetn                       (resetn                                                                         )  //i
  );
  Axi4ReadOnlyArbiter axi4ReadOnlyArbiter_6 (
    .io_inputs_0_ar_valid         (toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_valid             ), //i
    .io_inputs_0_ar_ready         (axi4ReadOnlyArbiter_6_io_inputs_0_ar_ready                                    ), //o
    .io_inputs_0_ar_payload_addr  (toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_addr[31:0]), //i
    .io_inputs_0_ar_payload_id    (toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_id[3:0]   ), //i
    .io_inputs_0_ar_payload_len   (toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_len[7:0]  ), //i
    .io_inputs_0_ar_payload_size  (toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_size[2:0] ), //i
    .io_inputs_0_ar_payload_burst (toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_burst[1:0]), //i
    .io_inputs_0_ar_payload_lock  (toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_lock      ), //i
    .io_inputs_0_ar_payload_cache (toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_cache[3:0]), //i
    .io_inputs_0_ar_payload_prot  (toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_prot[2:0] ), //i
    .io_inputs_0_r_valid          (axi4ReadOnlyArbiter_6_io_inputs_0_r_valid                                     ), //o
    .io_inputs_0_r_ready          (axiIn_0_readOnly_decoder_io_outputs_6_r_ready                                 ), //i
    .io_inputs_0_r_payload_data   (axi4ReadOnlyArbiter_6_io_inputs_0_r_payload_data[31:0]                        ), //o
    .io_inputs_0_r_payload_id     (axi4ReadOnlyArbiter_6_io_inputs_0_r_payload_id[3:0]                           ), //o
    .io_inputs_0_r_payload_resp   (axi4ReadOnlyArbiter_6_io_inputs_0_r_payload_resp[1:0]                         ), //o
    .io_inputs_0_r_payload_last   (axi4ReadOnlyArbiter_6_io_inputs_0_r_payload_last                              ), //o
    .io_inputs_1_ar_valid         (toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_valid             ), //i
    .io_inputs_1_ar_ready         (axi4ReadOnlyArbiter_6_io_inputs_1_ar_ready                                    ), //o
    .io_inputs_1_ar_payload_addr  (toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_addr[31:0]), //i
    .io_inputs_1_ar_payload_id    (toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_id[3:0]   ), //i
    .io_inputs_1_ar_payload_len   (toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_len[7:0]  ), //i
    .io_inputs_1_ar_payload_size  (toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_size[2:0] ), //i
    .io_inputs_1_ar_payload_burst (toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_burst[1:0]), //i
    .io_inputs_1_ar_payload_lock  (toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_lock      ), //i
    .io_inputs_1_ar_payload_cache (toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_cache[3:0]), //i
    .io_inputs_1_ar_payload_prot  (toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_prot[2:0] ), //i
    .io_inputs_1_r_valid          (axi4ReadOnlyArbiter_6_io_inputs_1_r_valid                                     ), //o
    .io_inputs_1_r_ready          (axiIn_1_readOnly_decoder_io_outputs_2_r_ready                                 ), //i
    .io_inputs_1_r_payload_data   (axi4ReadOnlyArbiter_6_io_inputs_1_r_payload_data[31:0]                        ), //o
    .io_inputs_1_r_payload_id     (axi4ReadOnlyArbiter_6_io_inputs_1_r_payload_id[3:0]                           ), //o
    .io_inputs_1_r_payload_resp   (axi4ReadOnlyArbiter_6_io_inputs_1_r_payload_resp[1:0]                         ), //o
    .io_inputs_1_r_payload_last   (axi4ReadOnlyArbiter_6_io_inputs_1_r_payload_last                              ), //o
    .io_output_ar_valid           (axi4ReadOnlyArbiter_6_io_output_ar_valid                                      ), //o
    .io_output_ar_ready           (axiOut_6_arready                                                              ), //i
    .io_output_ar_payload_addr    (axi4ReadOnlyArbiter_6_io_output_ar_payload_addr[31:0]                         ), //o
    .io_output_ar_payload_id      (axi4ReadOnlyArbiter_6_io_output_ar_payload_id[4:0]                            ), //o
    .io_output_ar_payload_len     (axi4ReadOnlyArbiter_6_io_output_ar_payload_len[7:0]                           ), //o
    .io_output_ar_payload_size    (axi4ReadOnlyArbiter_6_io_output_ar_payload_size[2:0]                          ), //o
    .io_output_ar_payload_burst   (axi4ReadOnlyArbiter_6_io_output_ar_payload_burst[1:0]                         ), //o
    .io_output_ar_payload_lock    (axi4ReadOnlyArbiter_6_io_output_ar_payload_lock                               ), //o
    .io_output_ar_payload_cache   (axi4ReadOnlyArbiter_6_io_output_ar_payload_cache[3:0]                         ), //o
    .io_output_ar_payload_prot    (axi4ReadOnlyArbiter_6_io_output_ar_payload_prot[2:0]                          ), //o
    .io_output_r_valid            (axiOut_6_rvalid                                                               ), //i
    .io_output_r_ready            (axi4ReadOnlyArbiter_6_io_output_r_ready                                       ), //o
    .io_output_r_payload_data     (axiOut_6_rdata[31:0]                                                          ), //i
    .io_output_r_payload_id       (axiOut_6_rid[4:0]                                                             ), //i
    .io_output_r_payload_resp     (axiOut_6_rresp[1:0]                                                           ), //i
    .io_output_r_payload_last     (axiOut_6_rlast                                                                ), //i
    .clk                          (clk                                                                           ), //i
    .resetn                       (resetn                                                                        )  //i
  );
  Axi4WriteOnlyArbiter_2 axi4WriteOnlyArbiter_6 (
    .io_inputs_0_aw_valid         (toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_valid             ), //i
    .io_inputs_0_aw_ready         (axi4WriteOnlyArbiter_6_io_inputs_0_aw_ready                                    ), //o
    .io_inputs_0_aw_payload_addr  (toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_addr[31:0]), //i
    .io_inputs_0_aw_payload_id    (toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_id[3:0]   ), //i
    .io_inputs_0_aw_payload_len   (toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_len[7:0]  ), //i
    .io_inputs_0_aw_payload_size  (toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_size[2:0] ), //i
    .io_inputs_0_aw_payload_burst (toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_burst[1:0]), //i
    .io_inputs_0_aw_payload_lock  (toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_lock      ), //i
    .io_inputs_0_aw_payload_cache (toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_cache[3:0]), //i
    .io_inputs_0_aw_payload_prot  (toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_prot[2:0] ), //i
    .io_inputs_0_w_valid          (axiIn_0_writeOnly_decoder_io_outputs_6_w_valid                                 ), //i
    .io_inputs_0_w_ready          (axi4WriteOnlyArbiter_6_io_inputs_0_w_ready                                     ), //o
    .io_inputs_0_w_payload_data   (axiIn_0_writeOnly_decoder_io_outputs_6_w_payload_data[31:0]                    ), //i
    .io_inputs_0_w_payload_strb   (axiIn_0_writeOnly_decoder_io_outputs_6_w_payload_strb[3:0]                     ), //i
    .io_inputs_0_w_payload_last   (axiIn_0_writeOnly_decoder_io_outputs_6_w_payload_last                          ), //i
    .io_inputs_0_b_valid          (axi4WriteOnlyArbiter_6_io_inputs_0_b_valid                                     ), //o
    .io_inputs_0_b_ready          (axiIn_0_writeOnly_decoder_io_outputs_6_b_ready                                 ), //i
    .io_inputs_0_b_payload_id     (axi4WriteOnlyArbiter_6_io_inputs_0_b_payload_id[3:0]                           ), //o
    .io_inputs_0_b_payload_resp   (axi4WriteOnlyArbiter_6_io_inputs_0_b_payload_resp[1:0]                         ), //o
    .io_inputs_1_aw_valid         (toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_valid             ), //i
    .io_inputs_1_aw_ready         (axi4WriteOnlyArbiter_6_io_inputs_1_aw_ready                                    ), //o
    .io_inputs_1_aw_payload_addr  (toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_addr[31:0]), //i
    .io_inputs_1_aw_payload_id    (toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_id[3:0]   ), //i
    .io_inputs_1_aw_payload_len   (toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_len[7:0]  ), //i
    .io_inputs_1_aw_payload_size  (toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_size[2:0] ), //i
    .io_inputs_1_aw_payload_burst (toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_burst[1:0]), //i
    .io_inputs_1_aw_payload_lock  (toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_lock      ), //i
    .io_inputs_1_aw_payload_cache (toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_cache[3:0]), //i
    .io_inputs_1_aw_payload_prot  (toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_prot[2:0] ), //i
    .io_inputs_1_w_valid          (axiIn_1_writeOnly_decoder_io_outputs_2_w_valid                                 ), //i
    .io_inputs_1_w_ready          (axi4WriteOnlyArbiter_6_io_inputs_1_w_ready                                     ), //o
    .io_inputs_1_w_payload_data   (axiIn_1_writeOnly_decoder_io_outputs_2_w_payload_data[31:0]                    ), //i
    .io_inputs_1_w_payload_strb   (axiIn_1_writeOnly_decoder_io_outputs_2_w_payload_strb[3:0]                     ), //i
    .io_inputs_1_w_payload_last   (axiIn_1_writeOnly_decoder_io_outputs_2_w_payload_last                          ), //i
    .io_inputs_1_b_valid          (axi4WriteOnlyArbiter_6_io_inputs_1_b_valid                                     ), //o
    .io_inputs_1_b_ready          (axiIn_1_writeOnly_decoder_io_outputs_2_b_ready                                 ), //i
    .io_inputs_1_b_payload_id     (axi4WriteOnlyArbiter_6_io_inputs_1_b_payload_id[3:0]                           ), //o
    .io_inputs_1_b_payload_resp   (axi4WriteOnlyArbiter_6_io_inputs_1_b_payload_resp[1:0]                         ), //o
    .io_output_aw_valid           (axi4WriteOnlyArbiter_6_io_output_aw_valid                                      ), //o
    .io_output_aw_ready           (axiOut_6_awready                                                               ), //i
    .io_output_aw_payload_addr    (axi4WriteOnlyArbiter_6_io_output_aw_payload_addr[31:0]                         ), //o
    .io_output_aw_payload_id      (axi4WriteOnlyArbiter_6_io_output_aw_payload_id[4:0]                            ), //o
    .io_output_aw_payload_len     (axi4WriteOnlyArbiter_6_io_output_aw_payload_len[7:0]                           ), //o
    .io_output_aw_payload_size    (axi4WriteOnlyArbiter_6_io_output_aw_payload_size[2:0]                          ), //o
    .io_output_aw_payload_burst   (axi4WriteOnlyArbiter_6_io_output_aw_payload_burst[1:0]                         ), //o
    .io_output_aw_payload_lock    (axi4WriteOnlyArbiter_6_io_output_aw_payload_lock                               ), //o
    .io_output_aw_payload_cache   (axi4WriteOnlyArbiter_6_io_output_aw_payload_cache[3:0]                         ), //o
    .io_output_aw_payload_prot    (axi4WriteOnlyArbiter_6_io_output_aw_payload_prot[2:0]                          ), //o
    .io_output_w_valid            (axi4WriteOnlyArbiter_6_io_output_w_valid                                       ), //o
    .io_output_w_ready            (axiOut_6_wready                                                                ), //i
    .io_output_w_payload_data     (axi4WriteOnlyArbiter_6_io_output_w_payload_data[31:0]                          ), //o
    .io_output_w_payload_strb     (axi4WriteOnlyArbiter_6_io_output_w_payload_strb[3:0]                           ), //o
    .io_output_w_payload_last     (axi4WriteOnlyArbiter_6_io_output_w_payload_last                                ), //o
    .io_output_b_valid            (axiOut_6_bvalid                                                                ), //i
    .io_output_b_ready            (axi4WriteOnlyArbiter_6_io_output_b_ready                                       ), //o
    .io_output_b_payload_id       (axiOut_6_bid[4:0]                                                              ), //i
    .io_output_b_payload_resp     (axiOut_6_bresp[1:0]                                                            ), //i
    .clk                          (clk                                                                            ), //i
    .resetn                       (resetn                                                                         )  //i
  );
  Axi4ReadOnlyArbiter axi4ReadOnlyArbiter_7 (
    .io_inputs_0_ar_valid         (toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_valid             ), //i
    .io_inputs_0_ar_ready         (axi4ReadOnlyArbiter_7_io_inputs_0_ar_ready                                    ), //o
    .io_inputs_0_ar_payload_addr  (toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_addr[31:0]), //i
    .io_inputs_0_ar_payload_id    (toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_id[3:0]   ), //i
    .io_inputs_0_ar_payload_len   (toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_len[7:0]  ), //i
    .io_inputs_0_ar_payload_size  (toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_size[2:0] ), //i
    .io_inputs_0_ar_payload_burst (toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_burst[1:0]), //i
    .io_inputs_0_ar_payload_lock  (toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_lock      ), //i
    .io_inputs_0_ar_payload_cache (toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_cache[3:0]), //i
    .io_inputs_0_ar_payload_prot  (toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_prot[2:0] ), //i
    .io_inputs_0_r_valid          (axi4ReadOnlyArbiter_7_io_inputs_0_r_valid                                     ), //o
    .io_inputs_0_r_ready          (axiIn_0_readOnly_decoder_io_outputs_7_r_ready                                 ), //i
    .io_inputs_0_r_payload_data   (axi4ReadOnlyArbiter_7_io_inputs_0_r_payload_data[31:0]                        ), //o
    .io_inputs_0_r_payload_id     (axi4ReadOnlyArbiter_7_io_inputs_0_r_payload_id[3:0]                           ), //o
    .io_inputs_0_r_payload_resp   (axi4ReadOnlyArbiter_7_io_inputs_0_r_payload_resp[1:0]                         ), //o
    .io_inputs_0_r_payload_last   (axi4ReadOnlyArbiter_7_io_inputs_0_r_payload_last                              ), //o
    .io_inputs_1_ar_valid         (toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_valid             ), //i
    .io_inputs_1_ar_ready         (axi4ReadOnlyArbiter_7_io_inputs_1_ar_ready                                    ), //o
    .io_inputs_1_ar_payload_addr  (toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_addr[31:0]), //i
    .io_inputs_1_ar_payload_id    (toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_id[3:0]   ), //i
    .io_inputs_1_ar_payload_len   (toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_len[7:0]  ), //i
    .io_inputs_1_ar_payload_size  (toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_size[2:0] ), //i
    .io_inputs_1_ar_payload_burst (toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_burst[1:0]), //i
    .io_inputs_1_ar_payload_lock  (toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_lock      ), //i
    .io_inputs_1_ar_payload_cache (toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_cache[3:0]), //i
    .io_inputs_1_ar_payload_prot  (toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_prot[2:0] ), //i
    .io_inputs_1_r_valid          (axi4ReadOnlyArbiter_7_io_inputs_1_r_valid                                     ), //o
    .io_inputs_1_r_ready          (axiIn_1_readOnly_decoder_io_outputs_3_r_ready                                 ), //i
    .io_inputs_1_r_payload_data   (axi4ReadOnlyArbiter_7_io_inputs_1_r_payload_data[31:0]                        ), //o
    .io_inputs_1_r_payload_id     (axi4ReadOnlyArbiter_7_io_inputs_1_r_payload_id[3:0]                           ), //o
    .io_inputs_1_r_payload_resp   (axi4ReadOnlyArbiter_7_io_inputs_1_r_payload_resp[1:0]                         ), //o
    .io_inputs_1_r_payload_last   (axi4ReadOnlyArbiter_7_io_inputs_1_r_payload_last                              ), //o
    .io_output_ar_valid           (axi4ReadOnlyArbiter_7_io_output_ar_valid                                      ), //o
    .io_output_ar_ready           (axiOut_7_arready                                                              ), //i
    .io_output_ar_payload_addr    (axi4ReadOnlyArbiter_7_io_output_ar_payload_addr[31:0]                         ), //o
    .io_output_ar_payload_id      (axi4ReadOnlyArbiter_7_io_output_ar_payload_id[4:0]                            ), //o
    .io_output_ar_payload_len     (axi4ReadOnlyArbiter_7_io_output_ar_payload_len[7:0]                           ), //o
    .io_output_ar_payload_size    (axi4ReadOnlyArbiter_7_io_output_ar_payload_size[2:0]                          ), //o
    .io_output_ar_payload_burst   (axi4ReadOnlyArbiter_7_io_output_ar_payload_burst[1:0]                         ), //o
    .io_output_ar_payload_lock    (axi4ReadOnlyArbiter_7_io_output_ar_payload_lock                               ), //o
    .io_output_ar_payload_cache   (axi4ReadOnlyArbiter_7_io_output_ar_payload_cache[3:0]                         ), //o
    .io_output_ar_payload_prot    (axi4ReadOnlyArbiter_7_io_output_ar_payload_prot[2:0]                          ), //o
    .io_output_r_valid            (axiOut_7_rvalid                                                               ), //i
    .io_output_r_ready            (axi4ReadOnlyArbiter_7_io_output_r_ready                                       ), //o
    .io_output_r_payload_data     (axiOut_7_rdata[31:0]                                                          ), //i
    .io_output_r_payload_id       (axiOut_7_rid[4:0]                                                             ), //i
    .io_output_r_payload_resp     (axiOut_7_rresp[1:0]                                                           ), //i
    .io_output_r_payload_last     (axiOut_7_rlast                                                                ), //i
    .clk                          (clk                                                                           ), //i
    .resetn                       (resetn                                                                        )  //i
  );
  Axi4WriteOnlyArbiter_3 axi4WriteOnlyArbiter_7 (
    .io_inputs_0_aw_valid         (toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_valid             ), //i
    .io_inputs_0_aw_ready         (axi4WriteOnlyArbiter_7_io_inputs_0_aw_ready                                    ), //o
    .io_inputs_0_aw_payload_addr  (toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_addr[31:0]), //i
    .io_inputs_0_aw_payload_id    (toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_id[3:0]   ), //i
    .io_inputs_0_aw_payload_len   (toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_len[7:0]  ), //i
    .io_inputs_0_aw_payload_size  (toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_size[2:0] ), //i
    .io_inputs_0_aw_payload_burst (toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_burst[1:0]), //i
    .io_inputs_0_aw_payload_lock  (toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_lock      ), //i
    .io_inputs_0_aw_payload_cache (toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_cache[3:0]), //i
    .io_inputs_0_aw_payload_prot  (toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_prot[2:0] ), //i
    .io_inputs_0_w_valid          (axiIn_0_writeOnly_decoder_io_outputs_7_w_valid                                 ), //i
    .io_inputs_0_w_ready          (axi4WriteOnlyArbiter_7_io_inputs_0_w_ready                                     ), //o
    .io_inputs_0_w_payload_data   (axiIn_0_writeOnly_decoder_io_outputs_7_w_payload_data[31:0]                    ), //i
    .io_inputs_0_w_payload_strb   (axiIn_0_writeOnly_decoder_io_outputs_7_w_payload_strb[3:0]                     ), //i
    .io_inputs_0_w_payload_last   (axiIn_0_writeOnly_decoder_io_outputs_7_w_payload_last                          ), //i
    .io_inputs_0_b_valid          (axi4WriteOnlyArbiter_7_io_inputs_0_b_valid                                     ), //o
    .io_inputs_0_b_ready          (axiIn_0_writeOnly_decoder_io_outputs_7_b_ready                                 ), //i
    .io_inputs_0_b_payload_id     (axi4WriteOnlyArbiter_7_io_inputs_0_b_payload_id[3:0]                           ), //o
    .io_inputs_0_b_payload_resp   (axi4WriteOnlyArbiter_7_io_inputs_0_b_payload_resp[1:0]                         ), //o
    .io_inputs_1_aw_valid         (toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_valid             ), //i
    .io_inputs_1_aw_ready         (axi4WriteOnlyArbiter_7_io_inputs_1_aw_ready                                    ), //o
    .io_inputs_1_aw_payload_addr  (toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_addr[31:0]), //i
    .io_inputs_1_aw_payload_id    (toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_id[3:0]   ), //i
    .io_inputs_1_aw_payload_len   (toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_len[7:0]  ), //i
    .io_inputs_1_aw_payload_size  (toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_size[2:0] ), //i
    .io_inputs_1_aw_payload_burst (toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_burst[1:0]), //i
    .io_inputs_1_aw_payload_lock  (toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_lock      ), //i
    .io_inputs_1_aw_payload_cache (toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_cache[3:0]), //i
    .io_inputs_1_aw_payload_prot  (toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_prot[2:0] ), //i
    .io_inputs_1_w_valid          (axiIn_1_writeOnly_decoder_io_outputs_3_w_valid                                 ), //i
    .io_inputs_1_w_ready          (axi4WriteOnlyArbiter_7_io_inputs_1_w_ready                                     ), //o
    .io_inputs_1_w_payload_data   (axiIn_1_writeOnly_decoder_io_outputs_3_w_payload_data[31:0]                    ), //i
    .io_inputs_1_w_payload_strb   (axiIn_1_writeOnly_decoder_io_outputs_3_w_payload_strb[3:0]                     ), //i
    .io_inputs_1_w_payload_last   (axiIn_1_writeOnly_decoder_io_outputs_3_w_payload_last                          ), //i
    .io_inputs_1_b_valid          (axi4WriteOnlyArbiter_7_io_inputs_1_b_valid                                     ), //o
    .io_inputs_1_b_ready          (axiIn_1_writeOnly_decoder_io_outputs_3_b_ready                                 ), //i
    .io_inputs_1_b_payload_id     (axi4WriteOnlyArbiter_7_io_inputs_1_b_payload_id[3:0]                           ), //o
    .io_inputs_1_b_payload_resp   (axi4WriteOnlyArbiter_7_io_inputs_1_b_payload_resp[1:0]                         ), //o
    .io_output_aw_valid           (axi4WriteOnlyArbiter_7_io_output_aw_valid                                      ), //o
    .io_output_aw_ready           (axiOut_7_awready                                                               ), //i
    .io_output_aw_payload_addr    (axi4WriteOnlyArbiter_7_io_output_aw_payload_addr[31:0]                         ), //o
    .io_output_aw_payload_id      (axi4WriteOnlyArbiter_7_io_output_aw_payload_id[4:0]                            ), //o
    .io_output_aw_payload_len     (axi4WriteOnlyArbiter_7_io_output_aw_payload_len[7:0]                           ), //o
    .io_output_aw_payload_size    (axi4WriteOnlyArbiter_7_io_output_aw_payload_size[2:0]                          ), //o
    .io_output_aw_payload_burst   (axi4WriteOnlyArbiter_7_io_output_aw_payload_burst[1:0]                         ), //o
    .io_output_aw_payload_lock    (axi4WriteOnlyArbiter_7_io_output_aw_payload_lock                               ), //o
    .io_output_aw_payload_cache   (axi4WriteOnlyArbiter_7_io_output_aw_payload_cache[3:0]                         ), //o
    .io_output_aw_payload_prot    (axi4WriteOnlyArbiter_7_io_output_aw_payload_prot[2:0]                          ), //o
    .io_output_w_valid            (axi4WriteOnlyArbiter_7_io_output_w_valid                                       ), //o
    .io_output_w_ready            (axiOut_7_wready                                                                ), //i
    .io_output_w_payload_data     (axi4WriteOnlyArbiter_7_io_output_w_payload_data[31:0]                          ), //o
    .io_output_w_payload_strb     (axi4WriteOnlyArbiter_7_io_output_w_payload_strb[3:0]                           ), //o
    .io_output_w_payload_last     (axi4WriteOnlyArbiter_7_io_output_w_payload_last                                ), //o
    .io_output_b_valid            (axiOut_7_bvalid                                                                ), //i
    .io_output_b_ready            (axi4WriteOnlyArbiter_7_io_output_b_ready                                       ), //o
    .io_output_b_payload_id       (axiOut_7_bid[4:0]                                                              ), //i
    .io_output_b_payload_resp     (axiOut_7_bresp[1:0]                                                            ), //i
    .clk                          (clk                                                                            ), //i
    .resetn                       (resetn                                                                         )  //i
  );
  assign axiOut_0_arvalid = axi4ReadOnlyArbiter_4_io_output_ar_valid;
  assign axiOut_0_araddr = axi4ReadOnlyArbiter_4_io_output_ar_payload_addr;
  assign axiOut_0_arid = axi4ReadOnlyArbiter_4_io_output_ar_payload_id;
  assign axiOut_0_arlen = axi4ReadOnlyArbiter_4_io_output_ar_payload_len;
  assign axiOut_0_arsize = axi4ReadOnlyArbiter_4_io_output_ar_payload_size;
  assign axiOut_0_arburst = axi4ReadOnlyArbiter_4_io_output_ar_payload_burst;
  assign axiOut_0_arlock = axi4ReadOnlyArbiter_4_io_output_ar_payload_lock;
  assign axiOut_0_arcache = axi4ReadOnlyArbiter_4_io_output_ar_payload_cache;
  assign axiOut_0_arprot = axi4ReadOnlyArbiter_4_io_output_ar_payload_prot;
  assign axiOut_0_rready = axi4ReadOnlyArbiter_4_io_output_r_ready;
  assign axiOut_0_awvalid = axi4WriteOnlyArbiter_4_io_output_aw_valid;
  assign axiOut_0_awaddr = axi4WriteOnlyArbiter_4_io_output_aw_payload_addr;
  assign axiOut_0_awid = axi4WriteOnlyArbiter_4_io_output_aw_payload_id;
  assign axiOut_0_awlen = axi4WriteOnlyArbiter_4_io_output_aw_payload_len;
  assign axiOut_0_awsize = axi4WriteOnlyArbiter_4_io_output_aw_payload_size;
  assign axiOut_0_awburst = axi4WriteOnlyArbiter_4_io_output_aw_payload_burst;
  assign axiOut_0_awlock = axi4WriteOnlyArbiter_4_io_output_aw_payload_lock;
  assign axiOut_0_awcache = axi4WriteOnlyArbiter_4_io_output_aw_payload_cache;
  assign axiOut_0_awprot = axi4WriteOnlyArbiter_4_io_output_aw_payload_prot;
  assign axiOut_0_wvalid = axi4WriteOnlyArbiter_4_io_output_w_valid;
  assign axiOut_0_wdata = axi4WriteOnlyArbiter_4_io_output_w_payload_data;
  assign axiOut_0_wstrb = axi4WriteOnlyArbiter_4_io_output_w_payload_strb;
  assign axiOut_0_wlast = axi4WriteOnlyArbiter_4_io_output_w_payload_last;
  assign axiOut_0_bready = axi4WriteOnlyArbiter_4_io_output_b_ready;
  assign axiOut_1_arvalid = axi4ReadOnlyArbiter_5_io_output_ar_valid;
  assign axiOut_1_araddr = axi4ReadOnlyArbiter_5_io_output_ar_payload_addr;
  assign axiOut_1_arid = axi4ReadOnlyArbiter_5_io_output_ar_payload_id;
  assign axiOut_1_arlen = axi4ReadOnlyArbiter_5_io_output_ar_payload_len;
  assign axiOut_1_arsize = axi4ReadOnlyArbiter_5_io_output_ar_payload_size;
  assign axiOut_1_arburst = axi4ReadOnlyArbiter_5_io_output_ar_payload_burst;
  assign axiOut_1_arlock = axi4ReadOnlyArbiter_5_io_output_ar_payload_lock;
  assign axiOut_1_arcache = axi4ReadOnlyArbiter_5_io_output_ar_payload_cache;
  assign axiOut_1_arprot = axi4ReadOnlyArbiter_5_io_output_ar_payload_prot;
  assign axiOut_1_rready = axi4ReadOnlyArbiter_5_io_output_r_ready;
  assign axiOut_1_awvalid = axi4WriteOnlyArbiter_5_io_output_aw_valid;
  assign axiOut_1_awaddr = axi4WriteOnlyArbiter_5_io_output_aw_payload_addr;
  assign axiOut_1_awid = axi4WriteOnlyArbiter_5_io_output_aw_payload_id;
  assign axiOut_1_awlen = axi4WriteOnlyArbiter_5_io_output_aw_payload_len;
  assign axiOut_1_awsize = axi4WriteOnlyArbiter_5_io_output_aw_payload_size;
  assign axiOut_1_awburst = axi4WriteOnlyArbiter_5_io_output_aw_payload_burst;
  assign axiOut_1_awlock = axi4WriteOnlyArbiter_5_io_output_aw_payload_lock;
  assign axiOut_1_awcache = axi4WriteOnlyArbiter_5_io_output_aw_payload_cache;
  assign axiOut_1_awprot = axi4WriteOnlyArbiter_5_io_output_aw_payload_prot;
  assign axiOut_1_wvalid = axi4WriteOnlyArbiter_5_io_output_w_valid;
  assign axiOut_1_wdata = axi4WriteOnlyArbiter_5_io_output_w_payload_data;
  assign axiOut_1_wstrb = axi4WriteOnlyArbiter_5_io_output_w_payload_strb;
  assign axiOut_1_wlast = axi4WriteOnlyArbiter_5_io_output_w_payload_last;
  assign axiOut_1_bready = axi4WriteOnlyArbiter_5_io_output_b_ready;
  assign axiOut_2_arvalid = toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_valid;
  assign axiOut_2_araddr = toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_addr;
  assign axiOut_2_arid = {1'd0, toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_id};
  assign axiOut_2_arlen = toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_len;
  assign axiOut_2_arsize = toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_size;
  assign axiOut_2_arburst = toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_burst;
  assign axiOut_2_arlock = toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_lock;
  assign axiOut_2_arcache = toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_cache;
  assign axiOut_2_arprot = toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_prot;
  assign axiOut_2_rready = axiIn_0_readOnly_decoder_io_outputs_2_r_ready;
  assign axiOut_2_awvalid = toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_valid;
  assign axiOut_2_awaddr = toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_addr;
  assign axiOut_2_awid = {1'd0, toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_id};
  assign axiOut_2_awlen = toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_len;
  assign axiOut_2_awsize = toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_size;
  assign axiOut_2_awburst = toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_burst;
  assign axiOut_2_awlock = toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_lock;
  assign axiOut_2_awcache = toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_cache;
  assign axiOut_2_awprot = toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_prot;
  assign axiOut_2_wvalid = axiIn_0_writeOnly_decoder_io_outputs_2_w_valid;
  assign axiOut_2_wdata = axiIn_0_writeOnly_decoder_io_outputs_2_w_payload_data;
  assign axiOut_2_wstrb = axiIn_0_writeOnly_decoder_io_outputs_2_w_payload_strb;
  assign axiOut_2_wlast = axiIn_0_writeOnly_decoder_io_outputs_2_w_payload_last;
  assign axiOut_2_bready = axiIn_0_writeOnly_decoder_io_outputs_2_b_ready;
  assign axiOut_3_arvalid = toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_valid;
  assign axiOut_3_araddr = toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_addr;
  assign axiOut_3_arid = {1'd0, toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_id};
  assign axiOut_3_arlen = toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_len;
  assign axiOut_3_arsize = toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_size;
  assign axiOut_3_arburst = toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_burst;
  assign axiOut_3_arlock = toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_lock;
  assign axiOut_3_arcache = toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_cache;
  assign axiOut_3_arprot = toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_prot;
  assign axiOut_3_rready = axiIn_0_readOnly_decoder_io_outputs_3_r_ready;
  assign axiOut_3_awvalid = toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_valid;
  assign axiOut_3_awaddr = toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_addr;
  assign axiOut_3_awid = {1'd0, toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_id};
  assign axiOut_3_awlen = toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_len;
  assign axiOut_3_awsize = toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_size;
  assign axiOut_3_awburst = toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_burst;
  assign axiOut_3_awlock = toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_lock;
  assign axiOut_3_awcache = toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_cache;
  assign axiOut_3_awprot = toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_prot;
  assign axiOut_3_wvalid = axiIn_0_writeOnly_decoder_io_outputs_3_w_valid;
  assign axiOut_3_wdata = axiIn_0_writeOnly_decoder_io_outputs_3_w_payload_data;
  assign axiOut_3_wstrb = axiIn_0_writeOnly_decoder_io_outputs_3_w_payload_strb;
  assign axiOut_3_wlast = axiIn_0_writeOnly_decoder_io_outputs_3_w_payload_last;
  assign axiOut_3_bready = axiIn_0_writeOnly_decoder_io_outputs_3_b_ready;
  assign axiOut_4_arvalid = toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_valid;
  assign axiOut_4_araddr = toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_addr;
  assign axiOut_4_arid = {1'd0, toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_id};
  assign axiOut_4_arlen = toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_len;
  assign axiOut_4_arsize = toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_size;
  assign axiOut_4_arburst = toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_burst;
  assign axiOut_4_arlock = toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_lock;
  assign axiOut_4_arcache = toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_cache;
  assign axiOut_4_arprot = toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_prot;
  assign axiOut_4_rready = axiIn_0_readOnly_decoder_io_outputs_4_r_ready;
  assign axiOut_4_awvalid = toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_valid;
  assign axiOut_4_awaddr = toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_addr;
  assign axiOut_4_awid = {1'd0, toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_id};
  assign axiOut_4_awlen = toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_len;
  assign axiOut_4_awsize = toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_size;
  assign axiOut_4_awburst = toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_burst;
  assign axiOut_4_awlock = toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_lock;
  assign axiOut_4_awcache = toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_cache;
  assign axiOut_4_awprot = toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_prot;
  assign axiOut_4_wvalid = axiIn_0_writeOnly_decoder_io_outputs_4_w_valid;
  assign axiOut_4_wdata = axiIn_0_writeOnly_decoder_io_outputs_4_w_payload_data;
  assign axiOut_4_wstrb = axiIn_0_writeOnly_decoder_io_outputs_4_w_payload_strb;
  assign axiOut_4_wlast = axiIn_0_writeOnly_decoder_io_outputs_4_w_payload_last;
  assign axiOut_4_bready = axiIn_0_writeOnly_decoder_io_outputs_4_b_ready;
  assign axiOut_5_arvalid = toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_valid;
  assign axiOut_5_araddr = toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_addr;
  assign axiOut_5_arid = {1'd0, toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_id};
  assign axiOut_5_arlen = toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_len;
  assign axiOut_5_arsize = toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_size;
  assign axiOut_5_arburst = toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_burst;
  assign axiOut_5_arlock = toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_lock;
  assign axiOut_5_arcache = toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_cache;
  assign axiOut_5_arprot = toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_prot;
  assign axiOut_5_rready = axiIn_0_readOnly_decoder_io_outputs_5_r_ready;
  assign axiOut_5_awvalid = toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_valid;
  assign axiOut_5_awaddr = toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_addr;
  assign axiOut_5_awid = {1'd0, toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_id};
  assign axiOut_5_awlen = toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_len;
  assign axiOut_5_awsize = toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_size;
  assign axiOut_5_awburst = toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_burst;
  assign axiOut_5_awlock = toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_lock;
  assign axiOut_5_awcache = toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_cache;
  assign axiOut_5_awprot = toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_prot;
  assign axiOut_5_wvalid = axiIn_0_writeOnly_decoder_io_outputs_5_w_valid;
  assign axiOut_5_wdata = axiIn_0_writeOnly_decoder_io_outputs_5_w_payload_data;
  assign axiOut_5_wstrb = axiIn_0_writeOnly_decoder_io_outputs_5_w_payload_strb;
  assign axiOut_5_wlast = axiIn_0_writeOnly_decoder_io_outputs_5_w_payload_last;
  assign axiOut_5_bready = axiIn_0_writeOnly_decoder_io_outputs_5_b_ready;
  assign axiOut_6_arvalid = axi4ReadOnlyArbiter_6_io_output_ar_valid;
  assign axiOut_6_araddr = axi4ReadOnlyArbiter_6_io_output_ar_payload_addr;
  assign axiOut_6_arid = axi4ReadOnlyArbiter_6_io_output_ar_payload_id;
  assign axiOut_6_arlen = axi4ReadOnlyArbiter_6_io_output_ar_payload_len;
  assign axiOut_6_arsize = axi4ReadOnlyArbiter_6_io_output_ar_payload_size;
  assign axiOut_6_arburst = axi4ReadOnlyArbiter_6_io_output_ar_payload_burst;
  assign axiOut_6_arlock = axi4ReadOnlyArbiter_6_io_output_ar_payload_lock;
  assign axiOut_6_arcache = axi4ReadOnlyArbiter_6_io_output_ar_payload_cache;
  assign axiOut_6_arprot = axi4ReadOnlyArbiter_6_io_output_ar_payload_prot;
  assign axiOut_6_rready = axi4ReadOnlyArbiter_6_io_output_r_ready;
  assign axiOut_6_awvalid = axi4WriteOnlyArbiter_6_io_output_aw_valid;
  assign axiOut_6_awaddr = axi4WriteOnlyArbiter_6_io_output_aw_payload_addr;
  assign axiOut_6_awid = axi4WriteOnlyArbiter_6_io_output_aw_payload_id;
  assign axiOut_6_awlen = axi4WriteOnlyArbiter_6_io_output_aw_payload_len;
  assign axiOut_6_awsize = axi4WriteOnlyArbiter_6_io_output_aw_payload_size;
  assign axiOut_6_awburst = axi4WriteOnlyArbiter_6_io_output_aw_payload_burst;
  assign axiOut_6_awlock = axi4WriteOnlyArbiter_6_io_output_aw_payload_lock;
  assign axiOut_6_awcache = axi4WriteOnlyArbiter_6_io_output_aw_payload_cache;
  assign axiOut_6_awprot = axi4WriteOnlyArbiter_6_io_output_aw_payload_prot;
  assign axiOut_6_wvalid = axi4WriteOnlyArbiter_6_io_output_w_valid;
  assign axiOut_6_wdata = axi4WriteOnlyArbiter_6_io_output_w_payload_data;
  assign axiOut_6_wstrb = axi4WriteOnlyArbiter_6_io_output_w_payload_strb;
  assign axiOut_6_wlast = axi4WriteOnlyArbiter_6_io_output_w_payload_last;
  assign axiOut_6_bready = axi4WriteOnlyArbiter_6_io_output_b_ready;
  assign axiOut_7_arvalid = axi4ReadOnlyArbiter_7_io_output_ar_valid;
  assign axiOut_7_araddr = axi4ReadOnlyArbiter_7_io_output_ar_payload_addr;
  assign axiOut_7_arid = axi4ReadOnlyArbiter_7_io_output_ar_payload_id;
  assign axiOut_7_arlen = axi4ReadOnlyArbiter_7_io_output_ar_payload_len;
  assign axiOut_7_arsize = axi4ReadOnlyArbiter_7_io_output_ar_payload_size;
  assign axiOut_7_arburst = axi4ReadOnlyArbiter_7_io_output_ar_payload_burst;
  assign axiOut_7_arlock = axi4ReadOnlyArbiter_7_io_output_ar_payload_lock;
  assign axiOut_7_arcache = axi4ReadOnlyArbiter_7_io_output_ar_payload_cache;
  assign axiOut_7_arprot = axi4ReadOnlyArbiter_7_io_output_ar_payload_prot;
  assign axiOut_7_rready = axi4ReadOnlyArbiter_7_io_output_r_ready;
  assign axiOut_7_awvalid = axi4WriteOnlyArbiter_7_io_output_aw_valid;
  assign axiOut_7_awaddr = axi4WriteOnlyArbiter_7_io_output_aw_payload_addr;
  assign axiOut_7_awid = axi4WriteOnlyArbiter_7_io_output_aw_payload_id;
  assign axiOut_7_awlen = axi4WriteOnlyArbiter_7_io_output_aw_payload_len;
  assign axiOut_7_awsize = axi4WriteOnlyArbiter_7_io_output_aw_payload_size;
  assign axiOut_7_awburst = axi4WriteOnlyArbiter_7_io_output_aw_payload_burst;
  assign axiOut_7_awlock = axi4WriteOnlyArbiter_7_io_output_aw_payload_lock;
  assign axiOut_7_awcache = axi4WriteOnlyArbiter_7_io_output_aw_payload_cache;
  assign axiOut_7_awprot = axi4WriteOnlyArbiter_7_io_output_aw_payload_prot;
  assign axiOut_7_wvalid = axi4WriteOnlyArbiter_7_io_output_w_valid;
  assign axiOut_7_wdata = axi4WriteOnlyArbiter_7_io_output_w_payload_data;
  assign axiOut_7_wstrb = axi4WriteOnlyArbiter_7_io_output_w_payload_strb;
  assign axiOut_7_wlast = axi4WriteOnlyArbiter_7_io_output_w_payload_last;
  assign axiOut_7_bready = axi4WriteOnlyArbiter_7_io_output_b_ready;
  assign axiIn_0_readOnly_ar_valid = axiIn_0_arvalid;
  assign axiIn_0_arready = axiIn_0_readOnly_ar_ready;
  assign axiIn_0_readOnly_ar_payload_addr = axiIn_0_araddr;
  assign axiIn_0_readOnly_ar_payload_id = axiIn_0_arid;
  assign axiIn_0_readOnly_ar_payload_len = axiIn_0_arlen;
  assign axiIn_0_readOnly_ar_payload_size = axiIn_0_arsize;
  assign axiIn_0_readOnly_ar_payload_burst = axiIn_0_arburst;
  assign axiIn_0_readOnly_ar_payload_lock = axiIn_0_arlock;
  assign axiIn_0_readOnly_ar_payload_cache = axiIn_0_arcache;
  assign axiIn_0_readOnly_ar_payload_prot = axiIn_0_arprot;
  assign axiIn_0_rvalid = axiIn_0_readOnly_r_valid;
  assign axiIn_0_readOnly_r_ready = axiIn_0_rready;
  assign axiIn_0_rdata = axiIn_0_readOnly_r_payload_data;
  assign axiIn_0_rlast = axiIn_0_readOnly_r_payload_last;
  assign axiIn_0_rid = axiIn_0_readOnly_r_payload_id;
  assign axiIn_0_rresp = axiIn_0_readOnly_r_payload_resp;
  assign axiIn_0_writeOnly_aw_valid = axiIn_0_awvalid;
  assign axiIn_0_awready = axiIn_0_writeOnly_aw_ready;
  assign axiIn_0_writeOnly_aw_payload_addr = axiIn_0_awaddr;
  assign axiIn_0_writeOnly_aw_payload_id = axiIn_0_awid;
  assign axiIn_0_writeOnly_aw_payload_len = axiIn_0_awlen;
  assign axiIn_0_writeOnly_aw_payload_size = axiIn_0_awsize;
  assign axiIn_0_writeOnly_aw_payload_burst = axiIn_0_awburst;
  assign axiIn_0_writeOnly_aw_payload_lock = axiIn_0_awlock;
  assign axiIn_0_writeOnly_aw_payload_cache = axiIn_0_awcache;
  assign axiIn_0_writeOnly_aw_payload_prot = axiIn_0_awprot;
  assign axiIn_0_writeOnly_w_valid = axiIn_0_wvalid;
  assign axiIn_0_wready = axiIn_0_writeOnly_w_ready;
  assign axiIn_0_writeOnly_w_payload_data = axiIn_0_wdata;
  assign axiIn_0_writeOnly_w_payload_strb = axiIn_0_wstrb;
  assign axiIn_0_writeOnly_w_payload_last = axiIn_0_wlast;
  assign axiIn_0_bvalid = axiIn_0_writeOnly_b_valid;
  assign axiIn_0_writeOnly_b_ready = axiIn_0_bready;
  assign axiIn_0_bid = axiIn_0_writeOnly_b_payload_id;
  assign axiIn_0_bresp = axiIn_0_writeOnly_b_payload_resp;
  assign axiIn_1_readOnly_ar_valid = axiIn_1_arvalid;
  assign axiIn_1_arready = axiIn_1_readOnly_ar_ready;
  assign axiIn_1_readOnly_ar_payload_addr = axiIn_1_araddr;
  assign axiIn_1_readOnly_ar_payload_id = axiIn_1_arid;
  assign axiIn_1_readOnly_ar_payload_len = axiIn_1_arlen;
  assign axiIn_1_readOnly_ar_payload_size = axiIn_1_arsize;
  assign axiIn_1_readOnly_ar_payload_burst = axiIn_1_arburst;
  assign axiIn_1_readOnly_ar_payload_lock = axiIn_1_arlock;
  assign axiIn_1_readOnly_ar_payload_cache = axiIn_1_arcache;
  assign axiIn_1_readOnly_ar_payload_prot = axiIn_1_arprot;
  assign axiIn_1_rvalid = axiIn_1_readOnly_r_valid;
  assign axiIn_1_readOnly_r_ready = axiIn_1_rready;
  assign axiIn_1_rdata = axiIn_1_readOnly_r_payload_data;
  assign axiIn_1_rlast = axiIn_1_readOnly_r_payload_last;
  assign axiIn_1_rid = axiIn_1_readOnly_r_payload_id;
  assign axiIn_1_rresp = axiIn_1_readOnly_r_payload_resp;
  assign axiIn_1_writeOnly_aw_valid = axiIn_1_awvalid;
  assign axiIn_1_awready = axiIn_1_writeOnly_aw_ready;
  assign axiIn_1_writeOnly_aw_payload_addr = axiIn_1_awaddr;
  assign axiIn_1_writeOnly_aw_payload_id = axiIn_1_awid;
  assign axiIn_1_writeOnly_aw_payload_len = axiIn_1_awlen;
  assign axiIn_1_writeOnly_aw_payload_size = axiIn_1_awsize;
  assign axiIn_1_writeOnly_aw_payload_burst = axiIn_1_awburst;
  assign axiIn_1_writeOnly_aw_payload_lock = axiIn_1_awlock;
  assign axiIn_1_writeOnly_aw_payload_cache = axiIn_1_awcache;
  assign axiIn_1_writeOnly_aw_payload_prot = axiIn_1_awprot;
  assign axiIn_1_writeOnly_w_valid = axiIn_1_wvalid;
  assign axiIn_1_wready = axiIn_1_writeOnly_w_ready;
  assign axiIn_1_writeOnly_w_payload_data = axiIn_1_wdata;
  assign axiIn_1_writeOnly_w_payload_strb = axiIn_1_wstrb;
  assign axiIn_1_writeOnly_w_payload_last = axiIn_1_wlast;
  assign axiIn_1_bvalid = axiIn_1_writeOnly_b_valid;
  assign axiIn_1_writeOnly_b_ready = axiIn_1_bready;
  assign axiIn_1_bid = axiIn_1_writeOnly_b_payload_id;
  assign axiIn_1_bresp = axiIn_1_writeOnly_b_payload_resp;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_fire = (toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_valid && toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_ready);
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_valid = toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_rValid;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_addr = axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_addr;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_id = axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_id;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_len = axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_len;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_size = axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_size;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_burst = axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_burst;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_lock = axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_lock;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_cache = axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_cache;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_payload_prot = axiIn_0_readOnly_decoder_io_outputs_0_ar_payload_prot;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_ready = axi4ReadOnlyArbiter_4_io_inputs_0_ar_ready;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_fire = (toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_valid && toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_ready);
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_valid = toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_rValid;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_addr = axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_addr;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_id = axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_id;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_len = axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_len;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_size = axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_size;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_burst = axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_burst;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_lock = axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_lock;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_cache = axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_cache;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_payload_prot = axiIn_0_readOnly_decoder_io_outputs_1_ar_payload_prot;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_ready = axi4ReadOnlyArbiter_5_io_inputs_0_ar_ready;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_fire = (toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_valid && toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_ready);
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_valid = toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_rValid;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_addr = axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_addr;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_id = axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_id;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_len = axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_len;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_size = axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_size;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_burst = axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_burst;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_lock = axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_lock;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_cache = axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_cache;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_payload_prot = axiIn_0_readOnly_decoder_io_outputs_2_ar_payload_prot;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_ready = axiOut_2_arready;
  assign axiIn_0_readOnly_decoder_io_outputs_2_r_payload_id = axiOut_2_rid[3:0];
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_fire = (toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_valid && toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_ready);
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_valid = toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_rValid;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_addr = axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_addr;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_id = axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_id;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_len = axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_len;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_size = axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_size;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_burst = axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_burst;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_lock = axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_lock;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_cache = axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_cache;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_payload_prot = axiIn_0_readOnly_decoder_io_outputs_3_ar_payload_prot;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_ready = axiOut_3_arready;
  assign axiIn_0_readOnly_decoder_io_outputs_3_r_payload_id = axiOut_3_rid[3:0];
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_fire = (toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_valid && toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_ready);
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_valid = toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_rValid;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_addr = axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_addr;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_id = axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_id;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_len = axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_len;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_size = axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_size;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_burst = axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_burst;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_lock = axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_lock;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_cache = axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_cache;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_payload_prot = axiIn_0_readOnly_decoder_io_outputs_4_ar_payload_prot;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_ready = axiOut_4_arready;
  assign axiIn_0_readOnly_decoder_io_outputs_4_r_payload_id = axiOut_4_rid[3:0];
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_fire = (toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_valid && toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_ready);
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_valid = toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_rValid;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_addr = axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_addr;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_id = axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_id;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_len = axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_len;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_size = axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_size;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_burst = axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_burst;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_lock = axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_lock;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_cache = axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_cache;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_payload_prot = axiIn_0_readOnly_decoder_io_outputs_5_ar_payload_prot;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_ready = axiOut_5_arready;
  assign axiIn_0_readOnly_decoder_io_outputs_5_r_payload_id = axiOut_5_rid[3:0];
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_fire = (toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_valid && toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_ready);
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_valid = toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_rValid;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_addr = axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_addr;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_id = axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_id;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_len = axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_len;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_size = axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_size;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_burst = axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_burst;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_lock = axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_lock;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_cache = axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_cache;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_payload_prot = axiIn_0_readOnly_decoder_io_outputs_6_ar_payload_prot;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_ready = axi4ReadOnlyArbiter_6_io_inputs_0_ar_ready;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_fire = (toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_valid && toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_ready);
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_valid = toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_rValid;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_addr = axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_addr;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_id = axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_id;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_len = axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_len;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_size = axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_size;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_burst = axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_burst;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_lock = axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_lock;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_cache = axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_cache;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_payload_prot = axiIn_0_readOnly_decoder_io_outputs_7_ar_payload_prot;
  assign toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_ready = axi4ReadOnlyArbiter_7_io_inputs_0_ar_ready;
  assign axiIn_0_readOnly_ar_ready = axiIn_0_readOnly_decoder_io_input_ar_ready;
  assign axiIn_0_readOnly_r_valid = axiIn_0_readOnly_decoder_io_input_r_valid;
  assign axiIn_0_readOnly_r_payload_data = axiIn_0_readOnly_decoder_io_input_r_payload_data;
  assign axiIn_0_readOnly_r_payload_last = axiIn_0_readOnly_decoder_io_input_r_payload_last;
  assign axiIn_0_readOnly_r_payload_id = axiIn_0_readOnly_decoder_io_input_r_payload_id;
  assign axiIn_0_readOnly_r_payload_resp = axiIn_0_readOnly_decoder_io_input_r_payload_resp;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_fire = (toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_valid && toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_ready);
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_valid = toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_rValid;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_addr = axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_addr;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_id = axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_id;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_len = axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_len;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_size = axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_size;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_burst = axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_burst;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_lock = axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_lock;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_cache = axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_cache;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_prot = axiIn_0_writeOnly_decoder_io_outputs_0_aw_payload_prot;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_ready = axi4WriteOnlyArbiter_4_io_inputs_0_aw_ready;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_fire = (toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_valid && toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_ready);
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_valid = toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_rValid;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_addr = axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_addr;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_id = axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_id;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_len = axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_len;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_size = axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_size;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_burst = axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_burst;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_lock = axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_lock;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_cache = axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_cache;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_prot = axiIn_0_writeOnly_decoder_io_outputs_1_aw_payload_prot;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_ready = axi4WriteOnlyArbiter_5_io_inputs_0_aw_ready;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_fire = (toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_valid && toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_ready);
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_valid = toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_rValid;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_addr = axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_addr;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_id = axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_id;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_len = axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_len;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_size = axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_size;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_burst = axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_burst;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_lock = axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_lock;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_cache = axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_cache;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_prot = axiIn_0_writeOnly_decoder_io_outputs_2_aw_payload_prot;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_ready = axiOut_2_awready;
  assign axiIn_0_writeOnly_decoder_io_outputs_2_b_payload_id = axiOut_2_bid[3:0];
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_fire = (toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_valid && toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_ready);
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_valid = toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_rValid;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_addr = axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_addr;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_id = axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_id;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_len = axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_len;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_size = axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_size;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_burst = axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_burst;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_lock = axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_lock;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_cache = axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_cache;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_prot = axiIn_0_writeOnly_decoder_io_outputs_3_aw_payload_prot;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_ready = axiOut_3_awready;
  assign axiIn_0_writeOnly_decoder_io_outputs_3_b_payload_id = axiOut_3_bid[3:0];
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_fire = (toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_valid && toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_ready);
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_valid = toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_rValid;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_addr = axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_addr;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_id = axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_id;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_len = axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_len;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_size = axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_size;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_burst = axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_burst;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_lock = axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_lock;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_cache = axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_cache;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_payload_prot = axiIn_0_writeOnly_decoder_io_outputs_4_aw_payload_prot;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_ready = axiOut_4_awready;
  assign axiIn_0_writeOnly_decoder_io_outputs_4_b_payload_id = axiOut_4_bid[3:0];
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_fire = (toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_valid && toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_ready);
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_valid = toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_rValid;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_addr = axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_addr;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_id = axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_id;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_len = axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_len;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_size = axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_size;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_burst = axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_burst;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_lock = axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_lock;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_cache = axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_cache;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_payload_prot = axiIn_0_writeOnly_decoder_io_outputs_5_aw_payload_prot;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_ready = axiOut_5_awready;
  assign axiIn_0_writeOnly_decoder_io_outputs_5_b_payload_id = axiOut_5_bid[3:0];
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_fire = (toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_valid && toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_ready);
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_valid = toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_rValid;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_addr = axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_addr;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_id = axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_id;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_len = axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_len;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_size = axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_size;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_burst = axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_burst;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_lock = axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_lock;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_cache = axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_cache;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_payload_prot = axiIn_0_writeOnly_decoder_io_outputs_6_aw_payload_prot;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_ready = axi4WriteOnlyArbiter_6_io_inputs_0_aw_ready;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_fire = (toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_valid && toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_ready);
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_valid = toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_rValid;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_addr = axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_addr;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_id = axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_id;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_len = axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_len;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_size = axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_size;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_burst = axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_burst;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_lock = axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_lock;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_cache = axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_cache;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_payload_prot = axiIn_0_writeOnly_decoder_io_outputs_7_aw_payload_prot;
  assign toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_ready = axi4WriteOnlyArbiter_7_io_inputs_0_aw_ready;
  assign axiIn_0_writeOnly_aw_ready = axiIn_0_writeOnly_decoder_io_input_aw_ready;
  assign axiIn_0_writeOnly_w_ready = axiIn_0_writeOnly_decoder_io_input_w_ready;
  assign axiIn_0_writeOnly_b_valid = axiIn_0_writeOnly_decoder_io_input_b_valid;
  assign axiIn_0_writeOnly_b_payload_id = axiIn_0_writeOnly_decoder_io_input_b_payload_id;
  assign axiIn_0_writeOnly_b_payload_resp = axiIn_0_writeOnly_decoder_io_input_b_payload_resp;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_fire = (toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_valid && toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_ready);
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_valid = toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_rValid;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_addr = axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_addr;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_id = axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_id;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_len = axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_len;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_size = axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_size;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_burst = axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_burst;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_lock = axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_lock;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_cache = axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_cache;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_payload_prot = axiIn_1_readOnly_decoder_io_outputs_0_ar_payload_prot;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_ready = axi4ReadOnlyArbiter_4_io_inputs_1_ar_ready;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_fire = (toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_valid && toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_ready);
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_valid = toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_rValid;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_addr = axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_addr;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_id = axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_id;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_len = axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_len;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_size = axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_size;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_burst = axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_burst;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_lock = axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_lock;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_cache = axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_cache;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_payload_prot = axiIn_1_readOnly_decoder_io_outputs_1_ar_payload_prot;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_ready = axi4ReadOnlyArbiter_5_io_inputs_1_ar_ready;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_fire = (toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_valid && toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_ready);
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_valid = toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_rValid;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_addr = axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_addr;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_id = axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_id;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_len = axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_len;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_size = axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_size;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_burst = axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_burst;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_lock = axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_lock;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_cache = axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_cache;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_payload_prot = axiIn_1_readOnly_decoder_io_outputs_2_ar_payload_prot;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_ready = axi4ReadOnlyArbiter_6_io_inputs_1_ar_ready;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_fire = (toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_valid && toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_ready);
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_valid = toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_rValid;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_addr = axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_addr;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_id = axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_id;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_len = axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_len;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_size = axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_size;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_burst = axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_burst;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_lock = axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_lock;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_cache = axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_cache;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_payload_prot = axiIn_1_readOnly_decoder_io_outputs_3_ar_payload_prot;
  assign toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_ready = axi4ReadOnlyArbiter_7_io_inputs_1_ar_ready;
  assign axiIn_1_readOnly_ar_ready = axiIn_1_readOnly_decoder_io_input_ar_ready;
  assign axiIn_1_readOnly_r_valid = axiIn_1_readOnly_decoder_io_input_r_valid;
  assign axiIn_1_readOnly_r_payload_data = axiIn_1_readOnly_decoder_io_input_r_payload_data;
  assign axiIn_1_readOnly_r_payload_last = axiIn_1_readOnly_decoder_io_input_r_payload_last;
  assign axiIn_1_readOnly_r_payload_id = axiIn_1_readOnly_decoder_io_input_r_payload_id;
  assign axiIn_1_readOnly_r_payload_resp = axiIn_1_readOnly_decoder_io_input_r_payload_resp;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_fire = (toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_valid && toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_ready);
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_valid = toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_rValid;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_addr = axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_addr;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_id = axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_id;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_len = axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_len;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_size = axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_size;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_burst = axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_burst;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_lock = axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_lock;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_cache = axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_cache;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_payload_prot = axiIn_1_writeOnly_decoder_io_outputs_0_aw_payload_prot;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_ready = axi4WriteOnlyArbiter_4_io_inputs_1_aw_ready;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_fire = (toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_valid && toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_ready);
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_valid = toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_rValid;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_addr = axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_addr;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_id = axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_id;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_len = axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_len;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_size = axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_size;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_burst = axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_burst;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_lock = axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_lock;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_cache = axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_cache;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_payload_prot = axiIn_1_writeOnly_decoder_io_outputs_1_aw_payload_prot;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_ready = axi4WriteOnlyArbiter_5_io_inputs_1_aw_ready;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_fire = (toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_valid && toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_ready);
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_valid = toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_rValid;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_addr = axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_addr;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_id = axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_id;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_len = axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_len;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_size = axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_size;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_burst = axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_burst;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_lock = axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_lock;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_cache = axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_cache;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_payload_prot = axiIn_1_writeOnly_decoder_io_outputs_2_aw_payload_prot;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_ready = axi4WriteOnlyArbiter_6_io_inputs_1_aw_ready;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_fire = (toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_valid && toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_ready);
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_valid = toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_rValid;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_addr = axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_addr;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_id = axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_id;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_len = axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_len;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_size = axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_size;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_burst = axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_burst;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_lock = axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_lock;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_cache = axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_cache;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_payload_prot = axiIn_1_writeOnly_decoder_io_outputs_3_aw_payload_prot;
  assign toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_ready = axi4WriteOnlyArbiter_7_io_inputs_1_aw_ready;
  assign axiIn_1_writeOnly_aw_ready = axiIn_1_writeOnly_decoder_io_input_aw_ready;
  assign axiIn_1_writeOnly_w_ready = axiIn_1_writeOnly_decoder_io_input_w_ready;
  assign axiIn_1_writeOnly_b_valid = axiIn_1_writeOnly_decoder_io_input_b_valid;
  assign axiIn_1_writeOnly_b_payload_id = axiIn_1_writeOnly_decoder_io_input_b_payload_id;
  assign axiIn_1_writeOnly_b_payload_resp = axiIn_1_writeOnly_decoder_io_input_b_payload_resp;
  always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_rValid <= 1'b0;
      toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_rValid <= 1'b0;
      toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_rValid <= 1'b0;
      toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_rValid <= 1'b0;
      toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_rValid <= 1'b0;
      toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_rValid <= 1'b0;
      toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_rValid <= 1'b0;
      toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_rValid <= 1'b0;
      toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_rValid <= 1'b0;
      toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_rValid <= 1'b0;
      toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_rValid <= 1'b0;
      toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_rValid <= 1'b0;
      toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_rValid <= 1'b0;
      toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_rValid <= 1'b0;
      toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_rValid <= 1'b0;
      toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_rValid <= 1'b0;
      toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_rValid <= 1'b0;
      toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_rValid <= 1'b0;
      toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_rValid <= 1'b0;
      toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_rValid <= 1'b0;
      toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_rValid <= 1'b0;
      toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_rValid <= 1'b0;
      toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_rValid <= 1'b0;
      toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_rValid <= 1'b0;
    end else begin
      if(axiIn_0_readOnly_decoder_io_outputs_0_ar_valid) begin
        toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_rValid <= 1'b1;
      end
      if(toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_validPipe_fire) begin
        toplevel_axiIn_0_readOnly_decoder_io_outputs_0_ar_rValid <= 1'b0;
      end
      if(axiIn_0_readOnly_decoder_io_outputs_1_ar_valid) begin
        toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_rValid <= 1'b1;
      end
      if(toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_validPipe_fire) begin
        toplevel_axiIn_0_readOnly_decoder_io_outputs_1_ar_rValid <= 1'b0;
      end
      if(axiIn_0_readOnly_decoder_io_outputs_2_ar_valid) begin
        toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_rValid <= 1'b1;
      end
      if(toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_validPipe_fire) begin
        toplevel_axiIn_0_readOnly_decoder_io_outputs_2_ar_rValid <= 1'b0;
      end
      if(axiIn_0_readOnly_decoder_io_outputs_3_ar_valid) begin
        toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_rValid <= 1'b1;
      end
      if(toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_validPipe_fire) begin
        toplevel_axiIn_0_readOnly_decoder_io_outputs_3_ar_rValid <= 1'b0;
      end
      if(axiIn_0_readOnly_decoder_io_outputs_4_ar_valid) begin
        toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_rValid <= 1'b1;
      end
      if(toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_validPipe_fire) begin
        toplevel_axiIn_0_readOnly_decoder_io_outputs_4_ar_rValid <= 1'b0;
      end
      if(axiIn_0_readOnly_decoder_io_outputs_5_ar_valid) begin
        toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_rValid <= 1'b1;
      end
      if(toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_validPipe_fire) begin
        toplevel_axiIn_0_readOnly_decoder_io_outputs_5_ar_rValid <= 1'b0;
      end
      if(axiIn_0_readOnly_decoder_io_outputs_6_ar_valid) begin
        toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_rValid <= 1'b1;
      end
      if(toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_validPipe_fire) begin
        toplevel_axiIn_0_readOnly_decoder_io_outputs_6_ar_rValid <= 1'b0;
      end
      if(axiIn_0_readOnly_decoder_io_outputs_7_ar_valid) begin
        toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_rValid <= 1'b1;
      end
      if(toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_validPipe_fire) begin
        toplevel_axiIn_0_readOnly_decoder_io_outputs_7_ar_rValid <= 1'b0;
      end
      if(axiIn_0_writeOnly_decoder_io_outputs_0_aw_valid) begin
        toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_rValid <= 1'b1;
      end
      if(toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_validPipe_fire) begin
        toplevel_axiIn_0_writeOnly_decoder_io_outputs_0_aw_rValid <= 1'b0;
      end
      if(axiIn_0_writeOnly_decoder_io_outputs_1_aw_valid) begin
        toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_rValid <= 1'b1;
      end
      if(toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_validPipe_fire) begin
        toplevel_axiIn_0_writeOnly_decoder_io_outputs_1_aw_rValid <= 1'b0;
      end
      if(axiIn_0_writeOnly_decoder_io_outputs_2_aw_valid) begin
        toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_rValid <= 1'b1;
      end
      if(toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_validPipe_fire) begin
        toplevel_axiIn_0_writeOnly_decoder_io_outputs_2_aw_rValid <= 1'b0;
      end
      if(axiIn_0_writeOnly_decoder_io_outputs_3_aw_valid) begin
        toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_rValid <= 1'b1;
      end
      if(toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_validPipe_fire) begin
        toplevel_axiIn_0_writeOnly_decoder_io_outputs_3_aw_rValid <= 1'b0;
      end
      if(axiIn_0_writeOnly_decoder_io_outputs_4_aw_valid) begin
        toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_rValid <= 1'b1;
      end
      if(toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_validPipe_fire) begin
        toplevel_axiIn_0_writeOnly_decoder_io_outputs_4_aw_rValid <= 1'b0;
      end
      if(axiIn_0_writeOnly_decoder_io_outputs_5_aw_valid) begin
        toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_rValid <= 1'b1;
      end
      if(toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_validPipe_fire) begin
        toplevel_axiIn_0_writeOnly_decoder_io_outputs_5_aw_rValid <= 1'b0;
      end
      if(axiIn_0_writeOnly_decoder_io_outputs_6_aw_valid) begin
        toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_rValid <= 1'b1;
      end
      if(toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_validPipe_fire) begin
        toplevel_axiIn_0_writeOnly_decoder_io_outputs_6_aw_rValid <= 1'b0;
      end
      if(axiIn_0_writeOnly_decoder_io_outputs_7_aw_valid) begin
        toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_rValid <= 1'b1;
      end
      if(toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_validPipe_fire) begin
        toplevel_axiIn_0_writeOnly_decoder_io_outputs_7_aw_rValid <= 1'b0;
      end
      if(axiIn_1_readOnly_decoder_io_outputs_0_ar_valid) begin
        toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_rValid <= 1'b1;
      end
      if(toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_validPipe_fire) begin
        toplevel_axiIn_1_readOnly_decoder_io_outputs_0_ar_rValid <= 1'b0;
      end
      if(axiIn_1_readOnly_decoder_io_outputs_1_ar_valid) begin
        toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_rValid <= 1'b1;
      end
      if(toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_validPipe_fire) begin
        toplevel_axiIn_1_readOnly_decoder_io_outputs_1_ar_rValid <= 1'b0;
      end
      if(axiIn_1_readOnly_decoder_io_outputs_2_ar_valid) begin
        toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_rValid <= 1'b1;
      end
      if(toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_validPipe_fire) begin
        toplevel_axiIn_1_readOnly_decoder_io_outputs_2_ar_rValid <= 1'b0;
      end
      if(axiIn_1_readOnly_decoder_io_outputs_3_ar_valid) begin
        toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_rValid <= 1'b1;
      end
      if(toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_validPipe_fire) begin
        toplevel_axiIn_1_readOnly_decoder_io_outputs_3_ar_rValid <= 1'b0;
      end
      if(axiIn_1_writeOnly_decoder_io_outputs_0_aw_valid) begin
        toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_rValid <= 1'b1;
      end
      if(toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_validPipe_fire) begin
        toplevel_axiIn_1_writeOnly_decoder_io_outputs_0_aw_rValid <= 1'b0;
      end
      if(axiIn_1_writeOnly_decoder_io_outputs_1_aw_valid) begin
        toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_rValid <= 1'b1;
      end
      if(toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_validPipe_fire) begin
        toplevel_axiIn_1_writeOnly_decoder_io_outputs_1_aw_rValid <= 1'b0;
      end
      if(axiIn_1_writeOnly_decoder_io_outputs_2_aw_valid) begin
        toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_rValid <= 1'b1;
      end
      if(toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_validPipe_fire) begin
        toplevel_axiIn_1_writeOnly_decoder_io_outputs_2_aw_rValid <= 1'b0;
      end
      if(axiIn_1_writeOnly_decoder_io_outputs_3_aw_valid) begin
        toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_rValid <= 1'b1;
      end
      if(toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_validPipe_fire) begin
        toplevel_axiIn_1_writeOnly_decoder_io_outputs_3_aw_rValid <= 1'b0;
      end
    end
  end


endmodule

module Axi4WriteOnlyArbiter_3 (
  input  wire          io_inputs_0_aw_valid,
  output wire          io_inputs_0_aw_ready,
  input  wire [31:0]   io_inputs_0_aw_payload_addr,
  input  wire [3:0]    io_inputs_0_aw_payload_id,
  input  wire [7:0]    io_inputs_0_aw_payload_len,
  input  wire [2:0]    io_inputs_0_aw_payload_size,
  input  wire [1:0]    io_inputs_0_aw_payload_burst,
  input  wire [0:0]    io_inputs_0_aw_payload_lock,
  input  wire [3:0]    io_inputs_0_aw_payload_cache,
  input  wire [2:0]    io_inputs_0_aw_payload_prot,
  input  wire          io_inputs_0_w_valid,
  output wire          io_inputs_0_w_ready,
  input  wire [31:0]   io_inputs_0_w_payload_data,
  input  wire [3:0]    io_inputs_0_w_payload_strb,
  input  wire          io_inputs_0_w_payload_last,
  output wire          io_inputs_0_b_valid,
  input  wire          io_inputs_0_b_ready,
  output wire [3:0]    io_inputs_0_b_payload_id,
  output wire [1:0]    io_inputs_0_b_payload_resp,
  input  wire          io_inputs_1_aw_valid,
  output wire          io_inputs_1_aw_ready,
  input  wire [31:0]   io_inputs_1_aw_payload_addr,
  input  wire [3:0]    io_inputs_1_aw_payload_id,
  input  wire [7:0]    io_inputs_1_aw_payload_len,
  input  wire [2:0]    io_inputs_1_aw_payload_size,
  input  wire [1:0]    io_inputs_1_aw_payload_burst,
  input  wire [0:0]    io_inputs_1_aw_payload_lock,
  input  wire [3:0]    io_inputs_1_aw_payload_cache,
  input  wire [2:0]    io_inputs_1_aw_payload_prot,
  input  wire          io_inputs_1_w_valid,
  output wire          io_inputs_1_w_ready,
  input  wire [31:0]   io_inputs_1_w_payload_data,
  input  wire [3:0]    io_inputs_1_w_payload_strb,
  input  wire          io_inputs_1_w_payload_last,
  output wire          io_inputs_1_b_valid,
  input  wire          io_inputs_1_b_ready,
  output wire [3:0]    io_inputs_1_b_payload_id,
  output wire [1:0]    io_inputs_1_b_payload_resp,
  output wire          io_output_aw_valid,
  input  wire          io_output_aw_ready,
  output wire [31:0]   io_output_aw_payload_addr,
  output wire [4:0]    io_output_aw_payload_id,
  output wire [7:0]    io_output_aw_payload_len,
  output wire [2:0]    io_output_aw_payload_size,
  output wire [1:0]    io_output_aw_payload_burst,
  output wire [0:0]    io_output_aw_payload_lock,
  output wire [3:0]    io_output_aw_payload_cache,
  output wire [2:0]    io_output_aw_payload_prot,
  output wire          io_output_w_valid,
  input  wire          io_output_w_ready,
  output wire [31:0]   io_output_w_payload_data,
  output wire [3:0]    io_output_w_payload_strb,
  output wire          io_output_w_payload_last,
  input  wire          io_output_b_valid,
  output wire          io_output_b_ready,
  input  wire [4:0]    io_output_b_payload_id,
  input  wire [1:0]    io_output_b_payload_resp,
  input  wire          clk,
  input  wire          resetn
);

  reg                 cmdArbiter_io_output_ready;
  wire                cmdRouteFork_translated_fifo_io_pop_ready;
  wire                cmdRouteFork_translated_fifo_io_flush;
  wire                cmdArbiter_io_inputs_0_ready;
  wire                cmdArbiter_io_inputs_1_ready;
  wire                cmdArbiter_io_output_valid;
  wire       [31:0]   cmdArbiter_io_output_payload_addr;
  wire       [3:0]    cmdArbiter_io_output_payload_id;
  wire       [7:0]    cmdArbiter_io_output_payload_len;
  wire       [2:0]    cmdArbiter_io_output_payload_size;
  wire       [1:0]    cmdArbiter_io_output_payload_burst;
  wire       [0:0]    cmdArbiter_io_output_payload_lock;
  wire       [3:0]    cmdArbiter_io_output_payload_cache;
  wire       [2:0]    cmdArbiter_io_output_payload_prot;
  wire       [0:0]    cmdArbiter_io_chosen;
  wire       [1:0]    cmdArbiter_io_chosenOH;
  wire                cmdRouteFork_translated_fifo_io_push_ready;
  wire                cmdRouteFork_translated_fifo_io_pop_valid;
  wire       [0:0]    cmdRouteFork_translated_fifo_io_pop_payload;
  wire       [2:0]    cmdRouteFork_translated_fifo_io_occupancy;
  wire       [2:0]    cmdRouteFork_translated_fifo_io_availability;
  reg                 _zz_io_output_w_valid;
  reg        [31:0]   _zz_io_output_w_payload_data;
  reg        [3:0]    _zz_io_output_w_payload_strb;
  reg                 _zz_io_output_w_payload_last;
  reg                 _zz_io_output_b_ready;
  wire                cmdOutputFork_valid;
  wire                cmdOutputFork_ready;
  wire       [31:0]   cmdOutputFork_payload_addr;
  wire       [3:0]    cmdOutputFork_payload_id;
  wire       [7:0]    cmdOutputFork_payload_len;
  wire       [2:0]    cmdOutputFork_payload_size;
  wire       [1:0]    cmdOutputFork_payload_burst;
  wire       [0:0]    cmdOutputFork_payload_lock;
  wire       [3:0]    cmdOutputFork_payload_cache;
  wire       [2:0]    cmdOutputFork_payload_prot;
  wire                cmdRouteFork_valid;
  wire                cmdRouteFork_ready;
  wire       [31:0]   cmdRouteFork_payload_addr;
  wire       [3:0]    cmdRouteFork_payload_id;
  wire       [7:0]    cmdRouteFork_payload_len;
  wire       [2:0]    cmdRouteFork_payload_size;
  wire       [1:0]    cmdRouteFork_payload_burst;
  wire       [0:0]    cmdRouteFork_payload_lock;
  wire       [3:0]    cmdRouteFork_payload_cache;
  wire       [2:0]    cmdRouteFork_payload_prot;
  reg                 axi4WriteOnlyArbiter_7_cmdArbiter_io_output_fork2_logic_linkEnable_0;
  reg                 axi4WriteOnlyArbiter_7_cmdArbiter_io_output_fork2_logic_linkEnable_1;
  wire                when_Stream_l1020;
  wire                when_Stream_l1020_1;
  wire                cmdOutputFork_fire;
  wire                cmdRouteFork_fire;
  wire                cmdRouteFork_translated_valid;
  wire                cmdRouteFork_translated_ready;
  wire       [0:0]    cmdRouteFork_translated_payload;
  wire                io_output_w_fire;
  wire       [0:0]    writeRspIndex;
  wire                writeRspSels_0;
  wire                writeRspSels_1;

  StreamArbiter_7 cmdArbiter (
    .io_inputs_0_valid         (io_inputs_0_aw_valid                   ), //i
    .io_inputs_0_ready         (cmdArbiter_io_inputs_0_ready           ), //o
    .io_inputs_0_payload_addr  (io_inputs_0_aw_payload_addr[31:0]      ), //i
    .io_inputs_0_payload_id    (io_inputs_0_aw_payload_id[3:0]         ), //i
    .io_inputs_0_payload_len   (io_inputs_0_aw_payload_len[7:0]        ), //i
    .io_inputs_0_payload_size  (io_inputs_0_aw_payload_size[2:0]       ), //i
    .io_inputs_0_payload_burst (io_inputs_0_aw_payload_burst[1:0]      ), //i
    .io_inputs_0_payload_lock  (io_inputs_0_aw_payload_lock            ), //i
    .io_inputs_0_payload_cache (io_inputs_0_aw_payload_cache[3:0]      ), //i
    .io_inputs_0_payload_prot  (io_inputs_0_aw_payload_prot[2:0]       ), //i
    .io_inputs_1_valid         (io_inputs_1_aw_valid                   ), //i
    .io_inputs_1_ready         (cmdArbiter_io_inputs_1_ready           ), //o
    .io_inputs_1_payload_addr  (io_inputs_1_aw_payload_addr[31:0]      ), //i
    .io_inputs_1_payload_id    (io_inputs_1_aw_payload_id[3:0]         ), //i
    .io_inputs_1_payload_len   (io_inputs_1_aw_payload_len[7:0]        ), //i
    .io_inputs_1_payload_size  (io_inputs_1_aw_payload_size[2:0]       ), //i
    .io_inputs_1_payload_burst (io_inputs_1_aw_payload_burst[1:0]      ), //i
    .io_inputs_1_payload_lock  (io_inputs_1_aw_payload_lock            ), //i
    .io_inputs_1_payload_cache (io_inputs_1_aw_payload_cache[3:0]      ), //i
    .io_inputs_1_payload_prot  (io_inputs_1_aw_payload_prot[2:0]       ), //i
    .io_output_valid           (cmdArbiter_io_output_valid             ), //o
    .io_output_ready           (cmdArbiter_io_output_ready             ), //i
    .io_output_payload_addr    (cmdArbiter_io_output_payload_addr[31:0]), //o
    .io_output_payload_id      (cmdArbiter_io_output_payload_id[3:0]   ), //o
    .io_output_payload_len     (cmdArbiter_io_output_payload_len[7:0]  ), //o
    .io_output_payload_size    (cmdArbiter_io_output_payload_size[2:0] ), //o
    .io_output_payload_burst   (cmdArbiter_io_output_payload_burst[1:0]), //o
    .io_output_payload_lock    (cmdArbiter_io_output_payload_lock      ), //o
    .io_output_payload_cache   (cmdArbiter_io_output_payload_cache[3:0]), //o
    .io_output_payload_prot    (cmdArbiter_io_output_payload_prot[2:0] ), //o
    .io_chosen                 (cmdArbiter_io_chosen                   ), //o
    .io_chosenOH               (cmdArbiter_io_chosenOH[1:0]            ), //o
    .clk                       (clk                                    ), //i
    .resetn                    (resetn                                 )  //i
  );
  StreamFifoLowLatency_3 cmdRouteFork_translated_fifo (
    .io_push_valid   (cmdRouteFork_translated_valid                    ), //i
    .io_push_ready   (cmdRouteFork_translated_fifo_io_push_ready       ), //o
    .io_push_payload (cmdRouteFork_translated_payload                  ), //i
    .io_pop_valid    (cmdRouteFork_translated_fifo_io_pop_valid        ), //o
    .io_pop_ready    (cmdRouteFork_translated_fifo_io_pop_ready        ), //i
    .io_pop_payload  (cmdRouteFork_translated_fifo_io_pop_payload      ), //o
    .io_flush        (cmdRouteFork_translated_fifo_io_flush            ), //i
    .io_occupancy    (cmdRouteFork_translated_fifo_io_occupancy[2:0]   ), //o
    .io_availability (cmdRouteFork_translated_fifo_io_availability[2:0]), //o
    .clk             (clk                                              ), //i
    .resetn          (resetn                                           )  //i
  );
  always @(*) begin
    case(cmdRouteFork_translated_fifo_io_pop_payload)
      1'b0 : begin
        _zz_io_output_w_valid = io_inputs_0_w_valid;
        _zz_io_output_w_payload_data = io_inputs_0_w_payload_data;
        _zz_io_output_w_payload_strb = io_inputs_0_w_payload_strb;
        _zz_io_output_w_payload_last = io_inputs_0_w_payload_last;
      end
      default : begin
        _zz_io_output_w_valid = io_inputs_1_w_valid;
        _zz_io_output_w_payload_data = io_inputs_1_w_payload_data;
        _zz_io_output_w_payload_strb = io_inputs_1_w_payload_strb;
        _zz_io_output_w_payload_last = io_inputs_1_w_payload_last;
      end
    endcase
  end

  always @(*) begin
    case(writeRspIndex)
      1'b0 : _zz_io_output_b_ready = io_inputs_0_b_ready;
      default : _zz_io_output_b_ready = io_inputs_1_b_ready;
    endcase
  end

  assign io_inputs_0_aw_ready = cmdArbiter_io_inputs_0_ready;
  assign io_inputs_1_aw_ready = cmdArbiter_io_inputs_1_ready;
  always @(*) begin
    cmdArbiter_io_output_ready = 1'b1;
    if(when_Stream_l1020) begin
      cmdArbiter_io_output_ready = 1'b0;
    end
    if(when_Stream_l1020_1) begin
      cmdArbiter_io_output_ready = 1'b0;
    end
  end

  assign when_Stream_l1020 = ((! cmdOutputFork_ready) && axi4WriteOnlyArbiter_7_cmdArbiter_io_output_fork2_logic_linkEnable_0);
  assign when_Stream_l1020_1 = ((! cmdRouteFork_ready) && axi4WriteOnlyArbiter_7_cmdArbiter_io_output_fork2_logic_linkEnable_1);
  assign cmdOutputFork_valid = (cmdArbiter_io_output_valid && axi4WriteOnlyArbiter_7_cmdArbiter_io_output_fork2_logic_linkEnable_0);
  assign cmdOutputFork_payload_addr = cmdArbiter_io_output_payload_addr;
  assign cmdOutputFork_payload_id = cmdArbiter_io_output_payload_id;
  assign cmdOutputFork_payload_len = cmdArbiter_io_output_payload_len;
  assign cmdOutputFork_payload_size = cmdArbiter_io_output_payload_size;
  assign cmdOutputFork_payload_burst = cmdArbiter_io_output_payload_burst;
  assign cmdOutputFork_payload_lock = cmdArbiter_io_output_payload_lock;
  assign cmdOutputFork_payload_cache = cmdArbiter_io_output_payload_cache;
  assign cmdOutputFork_payload_prot = cmdArbiter_io_output_payload_prot;
  assign cmdOutputFork_fire = (cmdOutputFork_valid && cmdOutputFork_ready);
  assign cmdRouteFork_valid = (cmdArbiter_io_output_valid && axi4WriteOnlyArbiter_7_cmdArbiter_io_output_fork2_logic_linkEnable_1);
  assign cmdRouteFork_payload_addr = cmdArbiter_io_output_payload_addr;
  assign cmdRouteFork_payload_id = cmdArbiter_io_output_payload_id;
  assign cmdRouteFork_payload_len = cmdArbiter_io_output_payload_len;
  assign cmdRouteFork_payload_size = cmdArbiter_io_output_payload_size;
  assign cmdRouteFork_payload_burst = cmdArbiter_io_output_payload_burst;
  assign cmdRouteFork_payload_lock = cmdArbiter_io_output_payload_lock;
  assign cmdRouteFork_payload_cache = cmdArbiter_io_output_payload_cache;
  assign cmdRouteFork_payload_prot = cmdArbiter_io_output_payload_prot;
  assign cmdRouteFork_fire = (cmdRouteFork_valid && cmdRouteFork_ready);
  assign io_output_aw_valid = cmdOutputFork_valid;
  assign cmdOutputFork_ready = io_output_aw_ready;
  assign io_output_aw_payload_addr = cmdOutputFork_payload_addr;
  assign io_output_aw_payload_len = cmdOutputFork_payload_len;
  assign io_output_aw_payload_size = cmdOutputFork_payload_size;
  assign io_output_aw_payload_burst = cmdOutputFork_payload_burst;
  assign io_output_aw_payload_lock = cmdOutputFork_payload_lock;
  assign io_output_aw_payload_cache = cmdOutputFork_payload_cache;
  assign io_output_aw_payload_prot = cmdOutputFork_payload_prot;
  assign io_output_aw_payload_id = {cmdArbiter_io_chosen,cmdArbiter_io_output_payload_id};
  assign cmdRouteFork_translated_valid = cmdRouteFork_valid;
  assign cmdRouteFork_ready = cmdRouteFork_translated_ready;
  assign cmdRouteFork_translated_payload = cmdArbiter_io_chosen;
  assign cmdRouteFork_translated_ready = cmdRouteFork_translated_fifo_io_push_ready;
  assign io_output_w_valid = (cmdRouteFork_translated_fifo_io_pop_valid && _zz_io_output_w_valid);
  assign io_output_w_payload_data = _zz_io_output_w_payload_data;
  assign io_output_w_payload_strb = _zz_io_output_w_payload_strb;
  assign io_output_w_payload_last = _zz_io_output_w_payload_last;
  assign io_inputs_0_w_ready = ((cmdRouteFork_translated_fifo_io_pop_valid && io_output_w_ready) && (cmdRouteFork_translated_fifo_io_pop_payload == 1'b0));
  assign io_inputs_1_w_ready = ((cmdRouteFork_translated_fifo_io_pop_valid && io_output_w_ready) && (cmdRouteFork_translated_fifo_io_pop_payload == 1'b1));
  assign io_output_w_fire = (io_output_w_valid && io_output_w_ready);
  assign cmdRouteFork_translated_fifo_io_pop_ready = (io_output_w_fire && io_output_w_payload_last);
  assign writeRspIndex = io_output_b_payload_id[4 : 4];
  assign writeRspSels_0 = (writeRspIndex == 1'b0);
  assign writeRspSels_1 = (writeRspIndex == 1'b1);
  assign io_inputs_0_b_valid = (io_output_b_valid && writeRspSels_0);
  assign io_inputs_0_b_payload_resp = io_output_b_payload_resp;
  assign io_inputs_0_b_payload_id = io_output_b_payload_id[3 : 0];
  assign io_inputs_1_b_valid = (io_output_b_valid && writeRspSels_1);
  assign io_inputs_1_b_payload_resp = io_output_b_payload_resp;
  assign io_inputs_1_b_payload_id = io_output_b_payload_id[3 : 0];
  assign io_output_b_ready = _zz_io_output_b_ready;
  assign cmdRouteFork_translated_fifo_io_flush = 1'b0;
  always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      axi4WriteOnlyArbiter_7_cmdArbiter_io_output_fork2_logic_linkEnable_0 <= 1'b1;
      axi4WriteOnlyArbiter_7_cmdArbiter_io_output_fork2_logic_linkEnable_1 <= 1'b1;
    end else begin
      if(cmdOutputFork_fire) begin
        axi4WriteOnlyArbiter_7_cmdArbiter_io_output_fork2_logic_linkEnable_0 <= 1'b0;
      end
      if(cmdRouteFork_fire) begin
        axi4WriteOnlyArbiter_7_cmdArbiter_io_output_fork2_logic_linkEnable_1 <= 1'b0;
      end
      if(cmdArbiter_io_output_ready) begin
        axi4WriteOnlyArbiter_7_cmdArbiter_io_output_fork2_logic_linkEnable_0 <= 1'b1;
        axi4WriteOnlyArbiter_7_cmdArbiter_io_output_fork2_logic_linkEnable_1 <= 1'b1;
      end
    end
  end


endmodule

//Axi4ReadOnlyArbiter_3 replaced by Axi4ReadOnlyArbiter

module Axi4WriteOnlyArbiter_2 (
  input  wire          io_inputs_0_aw_valid,
  output wire          io_inputs_0_aw_ready,
  input  wire [31:0]   io_inputs_0_aw_payload_addr,
  input  wire [3:0]    io_inputs_0_aw_payload_id,
  input  wire [7:0]    io_inputs_0_aw_payload_len,
  input  wire [2:0]    io_inputs_0_aw_payload_size,
  input  wire [1:0]    io_inputs_0_aw_payload_burst,
  input  wire [0:0]    io_inputs_0_aw_payload_lock,
  input  wire [3:0]    io_inputs_0_aw_payload_cache,
  input  wire [2:0]    io_inputs_0_aw_payload_prot,
  input  wire          io_inputs_0_w_valid,
  output wire          io_inputs_0_w_ready,
  input  wire [31:0]   io_inputs_0_w_payload_data,
  input  wire [3:0]    io_inputs_0_w_payload_strb,
  input  wire          io_inputs_0_w_payload_last,
  output wire          io_inputs_0_b_valid,
  input  wire          io_inputs_0_b_ready,
  output wire [3:0]    io_inputs_0_b_payload_id,
  output wire [1:0]    io_inputs_0_b_payload_resp,
  input  wire          io_inputs_1_aw_valid,
  output wire          io_inputs_1_aw_ready,
  input  wire [31:0]   io_inputs_1_aw_payload_addr,
  input  wire [3:0]    io_inputs_1_aw_payload_id,
  input  wire [7:0]    io_inputs_1_aw_payload_len,
  input  wire [2:0]    io_inputs_1_aw_payload_size,
  input  wire [1:0]    io_inputs_1_aw_payload_burst,
  input  wire [0:0]    io_inputs_1_aw_payload_lock,
  input  wire [3:0]    io_inputs_1_aw_payload_cache,
  input  wire [2:0]    io_inputs_1_aw_payload_prot,
  input  wire          io_inputs_1_w_valid,
  output wire          io_inputs_1_w_ready,
  input  wire [31:0]   io_inputs_1_w_payload_data,
  input  wire [3:0]    io_inputs_1_w_payload_strb,
  input  wire          io_inputs_1_w_payload_last,
  output wire          io_inputs_1_b_valid,
  input  wire          io_inputs_1_b_ready,
  output wire [3:0]    io_inputs_1_b_payload_id,
  output wire [1:0]    io_inputs_1_b_payload_resp,
  output wire          io_output_aw_valid,
  input  wire          io_output_aw_ready,
  output wire [31:0]   io_output_aw_payload_addr,
  output wire [4:0]    io_output_aw_payload_id,
  output wire [7:0]    io_output_aw_payload_len,
  output wire [2:0]    io_output_aw_payload_size,
  output wire [1:0]    io_output_aw_payload_burst,
  output wire [0:0]    io_output_aw_payload_lock,
  output wire [3:0]    io_output_aw_payload_cache,
  output wire [2:0]    io_output_aw_payload_prot,
  output wire          io_output_w_valid,
  input  wire          io_output_w_ready,
  output wire [31:0]   io_output_w_payload_data,
  output wire [3:0]    io_output_w_payload_strb,
  output wire          io_output_w_payload_last,
  input  wire          io_output_b_valid,
  output wire          io_output_b_ready,
  input  wire [4:0]    io_output_b_payload_id,
  input  wire [1:0]    io_output_b_payload_resp,
  input  wire          clk,
  input  wire          resetn
);

  reg                 cmdArbiter_io_output_ready;
  wire                cmdRouteFork_translated_fifo_io_pop_ready;
  wire                cmdRouteFork_translated_fifo_io_flush;
  wire                cmdArbiter_io_inputs_0_ready;
  wire                cmdArbiter_io_inputs_1_ready;
  wire                cmdArbiter_io_output_valid;
  wire       [31:0]   cmdArbiter_io_output_payload_addr;
  wire       [3:0]    cmdArbiter_io_output_payload_id;
  wire       [7:0]    cmdArbiter_io_output_payload_len;
  wire       [2:0]    cmdArbiter_io_output_payload_size;
  wire       [1:0]    cmdArbiter_io_output_payload_burst;
  wire       [0:0]    cmdArbiter_io_output_payload_lock;
  wire       [3:0]    cmdArbiter_io_output_payload_cache;
  wire       [2:0]    cmdArbiter_io_output_payload_prot;
  wire       [0:0]    cmdArbiter_io_chosen;
  wire       [1:0]    cmdArbiter_io_chosenOH;
  wire                cmdRouteFork_translated_fifo_io_push_ready;
  wire                cmdRouteFork_translated_fifo_io_pop_valid;
  wire       [0:0]    cmdRouteFork_translated_fifo_io_pop_payload;
  wire       [2:0]    cmdRouteFork_translated_fifo_io_occupancy;
  wire       [2:0]    cmdRouteFork_translated_fifo_io_availability;
  reg                 _zz_io_output_w_valid;
  reg        [31:0]   _zz_io_output_w_payload_data;
  reg        [3:0]    _zz_io_output_w_payload_strb;
  reg                 _zz_io_output_w_payload_last;
  reg                 _zz_io_output_b_ready;
  wire                cmdOutputFork_valid;
  wire                cmdOutputFork_ready;
  wire       [31:0]   cmdOutputFork_payload_addr;
  wire       [3:0]    cmdOutputFork_payload_id;
  wire       [7:0]    cmdOutputFork_payload_len;
  wire       [2:0]    cmdOutputFork_payload_size;
  wire       [1:0]    cmdOutputFork_payload_burst;
  wire       [0:0]    cmdOutputFork_payload_lock;
  wire       [3:0]    cmdOutputFork_payload_cache;
  wire       [2:0]    cmdOutputFork_payload_prot;
  wire                cmdRouteFork_valid;
  wire                cmdRouteFork_ready;
  wire       [31:0]   cmdRouteFork_payload_addr;
  wire       [3:0]    cmdRouteFork_payload_id;
  wire       [7:0]    cmdRouteFork_payload_len;
  wire       [2:0]    cmdRouteFork_payload_size;
  wire       [1:0]    cmdRouteFork_payload_burst;
  wire       [0:0]    cmdRouteFork_payload_lock;
  wire       [3:0]    cmdRouteFork_payload_cache;
  wire       [2:0]    cmdRouteFork_payload_prot;
  reg                 axi4WriteOnlyArbiter_6_cmdArbiter_io_output_fork2_logic_linkEnable_0;
  reg                 axi4WriteOnlyArbiter_6_cmdArbiter_io_output_fork2_logic_linkEnable_1;
  wire                when_Stream_l1020;
  wire                when_Stream_l1020_1;
  wire                cmdOutputFork_fire;
  wire                cmdRouteFork_fire;
  wire                cmdRouteFork_translated_valid;
  wire                cmdRouteFork_translated_ready;
  wire       [0:0]    cmdRouteFork_translated_payload;
  wire                io_output_w_fire;
  wire       [0:0]    writeRspIndex;
  wire                writeRspSels_0;
  wire                writeRspSels_1;

  StreamArbiter_7 cmdArbiter (
    .io_inputs_0_valid         (io_inputs_0_aw_valid                   ), //i
    .io_inputs_0_ready         (cmdArbiter_io_inputs_0_ready           ), //o
    .io_inputs_0_payload_addr  (io_inputs_0_aw_payload_addr[31:0]      ), //i
    .io_inputs_0_payload_id    (io_inputs_0_aw_payload_id[3:0]         ), //i
    .io_inputs_0_payload_len   (io_inputs_0_aw_payload_len[7:0]        ), //i
    .io_inputs_0_payload_size  (io_inputs_0_aw_payload_size[2:0]       ), //i
    .io_inputs_0_payload_burst (io_inputs_0_aw_payload_burst[1:0]      ), //i
    .io_inputs_0_payload_lock  (io_inputs_0_aw_payload_lock            ), //i
    .io_inputs_0_payload_cache (io_inputs_0_aw_payload_cache[3:0]      ), //i
    .io_inputs_0_payload_prot  (io_inputs_0_aw_payload_prot[2:0]       ), //i
    .io_inputs_1_valid         (io_inputs_1_aw_valid                   ), //i
    .io_inputs_1_ready         (cmdArbiter_io_inputs_1_ready           ), //o
    .io_inputs_1_payload_addr  (io_inputs_1_aw_payload_addr[31:0]      ), //i
    .io_inputs_1_payload_id    (io_inputs_1_aw_payload_id[3:0]         ), //i
    .io_inputs_1_payload_len   (io_inputs_1_aw_payload_len[7:0]        ), //i
    .io_inputs_1_payload_size  (io_inputs_1_aw_payload_size[2:0]       ), //i
    .io_inputs_1_payload_burst (io_inputs_1_aw_payload_burst[1:0]      ), //i
    .io_inputs_1_payload_lock  (io_inputs_1_aw_payload_lock            ), //i
    .io_inputs_1_payload_cache (io_inputs_1_aw_payload_cache[3:0]      ), //i
    .io_inputs_1_payload_prot  (io_inputs_1_aw_payload_prot[2:0]       ), //i
    .io_output_valid           (cmdArbiter_io_output_valid             ), //o
    .io_output_ready           (cmdArbiter_io_output_ready             ), //i
    .io_output_payload_addr    (cmdArbiter_io_output_payload_addr[31:0]), //o
    .io_output_payload_id      (cmdArbiter_io_output_payload_id[3:0]   ), //o
    .io_output_payload_len     (cmdArbiter_io_output_payload_len[7:0]  ), //o
    .io_output_payload_size    (cmdArbiter_io_output_payload_size[2:0] ), //o
    .io_output_payload_burst   (cmdArbiter_io_output_payload_burst[1:0]), //o
    .io_output_payload_lock    (cmdArbiter_io_output_payload_lock      ), //o
    .io_output_payload_cache   (cmdArbiter_io_output_payload_cache[3:0]), //o
    .io_output_payload_prot    (cmdArbiter_io_output_payload_prot[2:0] ), //o
    .io_chosen                 (cmdArbiter_io_chosen                   ), //o
    .io_chosenOH               (cmdArbiter_io_chosenOH[1:0]            ), //o
    .clk                       (clk                                    ), //i
    .resetn                    (resetn                                 )  //i
  );
  StreamFifoLowLatency_3 cmdRouteFork_translated_fifo (
    .io_push_valid   (cmdRouteFork_translated_valid                    ), //i
    .io_push_ready   (cmdRouteFork_translated_fifo_io_push_ready       ), //o
    .io_push_payload (cmdRouteFork_translated_payload                  ), //i
    .io_pop_valid    (cmdRouteFork_translated_fifo_io_pop_valid        ), //o
    .io_pop_ready    (cmdRouteFork_translated_fifo_io_pop_ready        ), //i
    .io_pop_payload  (cmdRouteFork_translated_fifo_io_pop_payload      ), //o
    .io_flush        (cmdRouteFork_translated_fifo_io_flush            ), //i
    .io_occupancy    (cmdRouteFork_translated_fifo_io_occupancy[2:0]   ), //o
    .io_availability (cmdRouteFork_translated_fifo_io_availability[2:0]), //o
    .clk             (clk                                              ), //i
    .resetn          (resetn                                           )  //i
  );
  always @(*) begin
    case(cmdRouteFork_translated_fifo_io_pop_payload)
      1'b0 : begin
        _zz_io_output_w_valid = io_inputs_0_w_valid;
        _zz_io_output_w_payload_data = io_inputs_0_w_payload_data;
        _zz_io_output_w_payload_strb = io_inputs_0_w_payload_strb;
        _zz_io_output_w_payload_last = io_inputs_0_w_payload_last;
      end
      default : begin
        _zz_io_output_w_valid = io_inputs_1_w_valid;
        _zz_io_output_w_payload_data = io_inputs_1_w_payload_data;
        _zz_io_output_w_payload_strb = io_inputs_1_w_payload_strb;
        _zz_io_output_w_payload_last = io_inputs_1_w_payload_last;
      end
    endcase
  end

  always @(*) begin
    case(writeRspIndex)
      1'b0 : _zz_io_output_b_ready = io_inputs_0_b_ready;
      default : _zz_io_output_b_ready = io_inputs_1_b_ready;
    endcase
  end

  assign io_inputs_0_aw_ready = cmdArbiter_io_inputs_0_ready;
  assign io_inputs_1_aw_ready = cmdArbiter_io_inputs_1_ready;
  always @(*) begin
    cmdArbiter_io_output_ready = 1'b1;
    if(when_Stream_l1020) begin
      cmdArbiter_io_output_ready = 1'b0;
    end
    if(when_Stream_l1020_1) begin
      cmdArbiter_io_output_ready = 1'b0;
    end
  end

  assign when_Stream_l1020 = ((! cmdOutputFork_ready) && axi4WriteOnlyArbiter_6_cmdArbiter_io_output_fork2_logic_linkEnable_0);
  assign when_Stream_l1020_1 = ((! cmdRouteFork_ready) && axi4WriteOnlyArbiter_6_cmdArbiter_io_output_fork2_logic_linkEnable_1);
  assign cmdOutputFork_valid = (cmdArbiter_io_output_valid && axi4WriteOnlyArbiter_6_cmdArbiter_io_output_fork2_logic_linkEnable_0);
  assign cmdOutputFork_payload_addr = cmdArbiter_io_output_payload_addr;
  assign cmdOutputFork_payload_id = cmdArbiter_io_output_payload_id;
  assign cmdOutputFork_payload_len = cmdArbiter_io_output_payload_len;
  assign cmdOutputFork_payload_size = cmdArbiter_io_output_payload_size;
  assign cmdOutputFork_payload_burst = cmdArbiter_io_output_payload_burst;
  assign cmdOutputFork_payload_lock = cmdArbiter_io_output_payload_lock;
  assign cmdOutputFork_payload_cache = cmdArbiter_io_output_payload_cache;
  assign cmdOutputFork_payload_prot = cmdArbiter_io_output_payload_prot;
  assign cmdOutputFork_fire = (cmdOutputFork_valid && cmdOutputFork_ready);
  assign cmdRouteFork_valid = (cmdArbiter_io_output_valid && axi4WriteOnlyArbiter_6_cmdArbiter_io_output_fork2_logic_linkEnable_1);
  assign cmdRouteFork_payload_addr = cmdArbiter_io_output_payload_addr;
  assign cmdRouteFork_payload_id = cmdArbiter_io_output_payload_id;
  assign cmdRouteFork_payload_len = cmdArbiter_io_output_payload_len;
  assign cmdRouteFork_payload_size = cmdArbiter_io_output_payload_size;
  assign cmdRouteFork_payload_burst = cmdArbiter_io_output_payload_burst;
  assign cmdRouteFork_payload_lock = cmdArbiter_io_output_payload_lock;
  assign cmdRouteFork_payload_cache = cmdArbiter_io_output_payload_cache;
  assign cmdRouteFork_payload_prot = cmdArbiter_io_output_payload_prot;
  assign cmdRouteFork_fire = (cmdRouteFork_valid && cmdRouteFork_ready);
  assign io_output_aw_valid = cmdOutputFork_valid;
  assign cmdOutputFork_ready = io_output_aw_ready;
  assign io_output_aw_payload_addr = cmdOutputFork_payload_addr;
  assign io_output_aw_payload_len = cmdOutputFork_payload_len;
  assign io_output_aw_payload_size = cmdOutputFork_payload_size;
  assign io_output_aw_payload_burst = cmdOutputFork_payload_burst;
  assign io_output_aw_payload_lock = cmdOutputFork_payload_lock;
  assign io_output_aw_payload_cache = cmdOutputFork_payload_cache;
  assign io_output_aw_payload_prot = cmdOutputFork_payload_prot;
  assign io_output_aw_payload_id = {cmdArbiter_io_chosen,cmdArbiter_io_output_payload_id};
  assign cmdRouteFork_translated_valid = cmdRouteFork_valid;
  assign cmdRouteFork_ready = cmdRouteFork_translated_ready;
  assign cmdRouteFork_translated_payload = cmdArbiter_io_chosen;
  assign cmdRouteFork_translated_ready = cmdRouteFork_translated_fifo_io_push_ready;
  assign io_output_w_valid = (cmdRouteFork_translated_fifo_io_pop_valid && _zz_io_output_w_valid);
  assign io_output_w_payload_data = _zz_io_output_w_payload_data;
  assign io_output_w_payload_strb = _zz_io_output_w_payload_strb;
  assign io_output_w_payload_last = _zz_io_output_w_payload_last;
  assign io_inputs_0_w_ready = ((cmdRouteFork_translated_fifo_io_pop_valid && io_output_w_ready) && (cmdRouteFork_translated_fifo_io_pop_payload == 1'b0));
  assign io_inputs_1_w_ready = ((cmdRouteFork_translated_fifo_io_pop_valid && io_output_w_ready) && (cmdRouteFork_translated_fifo_io_pop_payload == 1'b1));
  assign io_output_w_fire = (io_output_w_valid && io_output_w_ready);
  assign cmdRouteFork_translated_fifo_io_pop_ready = (io_output_w_fire && io_output_w_payload_last);
  assign writeRspIndex = io_output_b_payload_id[4 : 4];
  assign writeRspSels_0 = (writeRspIndex == 1'b0);
  assign writeRspSels_1 = (writeRspIndex == 1'b1);
  assign io_inputs_0_b_valid = (io_output_b_valid && writeRspSels_0);
  assign io_inputs_0_b_payload_resp = io_output_b_payload_resp;
  assign io_inputs_0_b_payload_id = io_output_b_payload_id[3 : 0];
  assign io_inputs_1_b_valid = (io_output_b_valid && writeRspSels_1);
  assign io_inputs_1_b_payload_resp = io_output_b_payload_resp;
  assign io_inputs_1_b_payload_id = io_output_b_payload_id[3 : 0];
  assign io_output_b_ready = _zz_io_output_b_ready;
  assign cmdRouteFork_translated_fifo_io_flush = 1'b0;
  always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      axi4WriteOnlyArbiter_6_cmdArbiter_io_output_fork2_logic_linkEnable_0 <= 1'b1;
      axi4WriteOnlyArbiter_6_cmdArbiter_io_output_fork2_logic_linkEnable_1 <= 1'b1;
    end else begin
      if(cmdOutputFork_fire) begin
        axi4WriteOnlyArbiter_6_cmdArbiter_io_output_fork2_logic_linkEnable_0 <= 1'b0;
      end
      if(cmdRouteFork_fire) begin
        axi4WriteOnlyArbiter_6_cmdArbiter_io_output_fork2_logic_linkEnable_1 <= 1'b0;
      end
      if(cmdArbiter_io_output_ready) begin
        axi4WriteOnlyArbiter_6_cmdArbiter_io_output_fork2_logic_linkEnable_0 <= 1'b1;
        axi4WriteOnlyArbiter_6_cmdArbiter_io_output_fork2_logic_linkEnable_1 <= 1'b1;
      end
    end
  end


endmodule

//Axi4ReadOnlyArbiter_2 replaced by Axi4ReadOnlyArbiter

module Axi4WriteOnlyArbiter_1 (
  input  wire          io_inputs_0_aw_valid,
  output wire          io_inputs_0_aw_ready,
  input  wire [31:0]   io_inputs_0_aw_payload_addr,
  input  wire [3:0]    io_inputs_0_aw_payload_id,
  input  wire [7:0]    io_inputs_0_aw_payload_len,
  input  wire [2:0]    io_inputs_0_aw_payload_size,
  input  wire [1:0]    io_inputs_0_aw_payload_burst,
  input  wire [0:0]    io_inputs_0_aw_payload_lock,
  input  wire [3:0]    io_inputs_0_aw_payload_cache,
  input  wire [2:0]    io_inputs_0_aw_payload_prot,
  input  wire          io_inputs_0_w_valid,
  output wire          io_inputs_0_w_ready,
  input  wire [31:0]   io_inputs_0_w_payload_data,
  input  wire [3:0]    io_inputs_0_w_payload_strb,
  input  wire          io_inputs_0_w_payload_last,
  output wire          io_inputs_0_b_valid,
  input  wire          io_inputs_0_b_ready,
  output wire [3:0]    io_inputs_0_b_payload_id,
  output wire [1:0]    io_inputs_0_b_payload_resp,
  input  wire          io_inputs_1_aw_valid,
  output wire          io_inputs_1_aw_ready,
  input  wire [31:0]   io_inputs_1_aw_payload_addr,
  input  wire [3:0]    io_inputs_1_aw_payload_id,
  input  wire [7:0]    io_inputs_1_aw_payload_len,
  input  wire [2:0]    io_inputs_1_aw_payload_size,
  input  wire [1:0]    io_inputs_1_aw_payload_burst,
  input  wire [0:0]    io_inputs_1_aw_payload_lock,
  input  wire [3:0]    io_inputs_1_aw_payload_cache,
  input  wire [2:0]    io_inputs_1_aw_payload_prot,
  input  wire          io_inputs_1_w_valid,
  output wire          io_inputs_1_w_ready,
  input  wire [31:0]   io_inputs_1_w_payload_data,
  input  wire [3:0]    io_inputs_1_w_payload_strb,
  input  wire          io_inputs_1_w_payload_last,
  output wire          io_inputs_1_b_valid,
  input  wire          io_inputs_1_b_ready,
  output wire [3:0]    io_inputs_1_b_payload_id,
  output wire [1:0]    io_inputs_1_b_payload_resp,
  output wire          io_output_aw_valid,
  input  wire          io_output_aw_ready,
  output wire [31:0]   io_output_aw_payload_addr,
  output wire [4:0]    io_output_aw_payload_id,
  output wire [7:0]    io_output_aw_payload_len,
  output wire [2:0]    io_output_aw_payload_size,
  output wire [1:0]    io_output_aw_payload_burst,
  output wire [0:0]    io_output_aw_payload_lock,
  output wire [3:0]    io_output_aw_payload_cache,
  output wire [2:0]    io_output_aw_payload_prot,
  output wire          io_output_w_valid,
  input  wire          io_output_w_ready,
  output wire [31:0]   io_output_w_payload_data,
  output wire [3:0]    io_output_w_payload_strb,
  output wire          io_output_w_payload_last,
  input  wire          io_output_b_valid,
  output wire          io_output_b_ready,
  input  wire [4:0]    io_output_b_payload_id,
  input  wire [1:0]    io_output_b_payload_resp,
  input  wire          clk,
  input  wire          resetn
);

  reg                 cmdArbiter_io_output_ready;
  wire                cmdRouteFork_translated_fifo_io_pop_ready;
  wire                cmdRouteFork_translated_fifo_io_flush;
  wire                cmdArbiter_io_inputs_0_ready;
  wire                cmdArbiter_io_inputs_1_ready;
  wire                cmdArbiter_io_output_valid;
  wire       [31:0]   cmdArbiter_io_output_payload_addr;
  wire       [3:0]    cmdArbiter_io_output_payload_id;
  wire       [7:0]    cmdArbiter_io_output_payload_len;
  wire       [2:0]    cmdArbiter_io_output_payload_size;
  wire       [1:0]    cmdArbiter_io_output_payload_burst;
  wire       [0:0]    cmdArbiter_io_output_payload_lock;
  wire       [3:0]    cmdArbiter_io_output_payload_cache;
  wire       [2:0]    cmdArbiter_io_output_payload_prot;
  wire       [0:0]    cmdArbiter_io_chosen;
  wire       [1:0]    cmdArbiter_io_chosenOH;
  wire                cmdRouteFork_translated_fifo_io_push_ready;
  wire                cmdRouteFork_translated_fifo_io_pop_valid;
  wire       [0:0]    cmdRouteFork_translated_fifo_io_pop_payload;
  wire       [2:0]    cmdRouteFork_translated_fifo_io_occupancy;
  wire       [2:0]    cmdRouteFork_translated_fifo_io_availability;
  reg                 _zz_io_output_w_valid;
  reg        [31:0]   _zz_io_output_w_payload_data;
  reg        [3:0]    _zz_io_output_w_payload_strb;
  reg                 _zz_io_output_w_payload_last;
  reg                 _zz_io_output_b_ready;
  wire                cmdOutputFork_valid;
  wire                cmdOutputFork_ready;
  wire       [31:0]   cmdOutputFork_payload_addr;
  wire       [3:0]    cmdOutputFork_payload_id;
  wire       [7:0]    cmdOutputFork_payload_len;
  wire       [2:0]    cmdOutputFork_payload_size;
  wire       [1:0]    cmdOutputFork_payload_burst;
  wire       [0:0]    cmdOutputFork_payload_lock;
  wire       [3:0]    cmdOutputFork_payload_cache;
  wire       [2:0]    cmdOutputFork_payload_prot;
  wire                cmdRouteFork_valid;
  wire                cmdRouteFork_ready;
  wire       [31:0]   cmdRouteFork_payload_addr;
  wire       [3:0]    cmdRouteFork_payload_id;
  wire       [7:0]    cmdRouteFork_payload_len;
  wire       [2:0]    cmdRouteFork_payload_size;
  wire       [1:0]    cmdRouteFork_payload_burst;
  wire       [0:0]    cmdRouteFork_payload_lock;
  wire       [3:0]    cmdRouteFork_payload_cache;
  wire       [2:0]    cmdRouteFork_payload_prot;
  reg                 axi4WriteOnlyArbiter_5_cmdArbiter_io_output_fork2_logic_linkEnable_0;
  reg                 axi4WriteOnlyArbiter_5_cmdArbiter_io_output_fork2_logic_linkEnable_1;
  wire                when_Stream_l1020;
  wire                when_Stream_l1020_1;
  wire                cmdOutputFork_fire;
  wire                cmdRouteFork_fire;
  wire                cmdRouteFork_translated_valid;
  wire                cmdRouteFork_translated_ready;
  wire       [0:0]    cmdRouteFork_translated_payload;
  wire                io_output_w_fire;
  wire       [0:0]    writeRspIndex;
  wire                writeRspSels_0;
  wire                writeRspSels_1;

  StreamArbiter_7 cmdArbiter (
    .io_inputs_0_valid         (io_inputs_0_aw_valid                   ), //i
    .io_inputs_0_ready         (cmdArbiter_io_inputs_0_ready           ), //o
    .io_inputs_0_payload_addr  (io_inputs_0_aw_payload_addr[31:0]      ), //i
    .io_inputs_0_payload_id    (io_inputs_0_aw_payload_id[3:0]         ), //i
    .io_inputs_0_payload_len   (io_inputs_0_aw_payload_len[7:0]        ), //i
    .io_inputs_0_payload_size  (io_inputs_0_aw_payload_size[2:0]       ), //i
    .io_inputs_0_payload_burst (io_inputs_0_aw_payload_burst[1:0]      ), //i
    .io_inputs_0_payload_lock  (io_inputs_0_aw_payload_lock            ), //i
    .io_inputs_0_payload_cache (io_inputs_0_aw_payload_cache[3:0]      ), //i
    .io_inputs_0_payload_prot  (io_inputs_0_aw_payload_prot[2:0]       ), //i
    .io_inputs_1_valid         (io_inputs_1_aw_valid                   ), //i
    .io_inputs_1_ready         (cmdArbiter_io_inputs_1_ready           ), //o
    .io_inputs_1_payload_addr  (io_inputs_1_aw_payload_addr[31:0]      ), //i
    .io_inputs_1_payload_id    (io_inputs_1_aw_payload_id[3:0]         ), //i
    .io_inputs_1_payload_len   (io_inputs_1_aw_payload_len[7:0]        ), //i
    .io_inputs_1_payload_size  (io_inputs_1_aw_payload_size[2:0]       ), //i
    .io_inputs_1_payload_burst (io_inputs_1_aw_payload_burst[1:0]      ), //i
    .io_inputs_1_payload_lock  (io_inputs_1_aw_payload_lock            ), //i
    .io_inputs_1_payload_cache (io_inputs_1_aw_payload_cache[3:0]      ), //i
    .io_inputs_1_payload_prot  (io_inputs_1_aw_payload_prot[2:0]       ), //i
    .io_output_valid           (cmdArbiter_io_output_valid             ), //o
    .io_output_ready           (cmdArbiter_io_output_ready             ), //i
    .io_output_payload_addr    (cmdArbiter_io_output_payload_addr[31:0]), //o
    .io_output_payload_id      (cmdArbiter_io_output_payload_id[3:0]   ), //o
    .io_output_payload_len     (cmdArbiter_io_output_payload_len[7:0]  ), //o
    .io_output_payload_size    (cmdArbiter_io_output_payload_size[2:0] ), //o
    .io_output_payload_burst   (cmdArbiter_io_output_payload_burst[1:0]), //o
    .io_output_payload_lock    (cmdArbiter_io_output_payload_lock      ), //o
    .io_output_payload_cache   (cmdArbiter_io_output_payload_cache[3:0]), //o
    .io_output_payload_prot    (cmdArbiter_io_output_payload_prot[2:0] ), //o
    .io_chosen                 (cmdArbiter_io_chosen                   ), //o
    .io_chosenOH               (cmdArbiter_io_chosenOH[1:0]            ), //o
    .clk                       (clk                                    ), //i
    .resetn                    (resetn                                 )  //i
  );
  StreamFifoLowLatency_3 cmdRouteFork_translated_fifo (
    .io_push_valid   (cmdRouteFork_translated_valid                    ), //i
    .io_push_ready   (cmdRouteFork_translated_fifo_io_push_ready       ), //o
    .io_push_payload (cmdRouteFork_translated_payload                  ), //i
    .io_pop_valid    (cmdRouteFork_translated_fifo_io_pop_valid        ), //o
    .io_pop_ready    (cmdRouteFork_translated_fifo_io_pop_ready        ), //i
    .io_pop_payload  (cmdRouteFork_translated_fifo_io_pop_payload      ), //o
    .io_flush        (cmdRouteFork_translated_fifo_io_flush            ), //i
    .io_occupancy    (cmdRouteFork_translated_fifo_io_occupancy[2:0]   ), //o
    .io_availability (cmdRouteFork_translated_fifo_io_availability[2:0]), //o
    .clk             (clk                                              ), //i
    .resetn          (resetn                                           )  //i
  );
  always @(*) begin
    case(cmdRouteFork_translated_fifo_io_pop_payload)
      1'b0 : begin
        _zz_io_output_w_valid = io_inputs_0_w_valid;
        _zz_io_output_w_payload_data = io_inputs_0_w_payload_data;
        _zz_io_output_w_payload_strb = io_inputs_0_w_payload_strb;
        _zz_io_output_w_payload_last = io_inputs_0_w_payload_last;
      end
      default : begin
        _zz_io_output_w_valid = io_inputs_1_w_valid;
        _zz_io_output_w_payload_data = io_inputs_1_w_payload_data;
        _zz_io_output_w_payload_strb = io_inputs_1_w_payload_strb;
        _zz_io_output_w_payload_last = io_inputs_1_w_payload_last;
      end
    endcase
  end

  always @(*) begin
    case(writeRspIndex)
      1'b0 : _zz_io_output_b_ready = io_inputs_0_b_ready;
      default : _zz_io_output_b_ready = io_inputs_1_b_ready;
    endcase
  end

  assign io_inputs_0_aw_ready = cmdArbiter_io_inputs_0_ready;
  assign io_inputs_1_aw_ready = cmdArbiter_io_inputs_1_ready;
  always @(*) begin
    cmdArbiter_io_output_ready = 1'b1;
    if(when_Stream_l1020) begin
      cmdArbiter_io_output_ready = 1'b0;
    end
    if(when_Stream_l1020_1) begin
      cmdArbiter_io_output_ready = 1'b0;
    end
  end

  assign when_Stream_l1020 = ((! cmdOutputFork_ready) && axi4WriteOnlyArbiter_5_cmdArbiter_io_output_fork2_logic_linkEnable_0);
  assign when_Stream_l1020_1 = ((! cmdRouteFork_ready) && axi4WriteOnlyArbiter_5_cmdArbiter_io_output_fork2_logic_linkEnable_1);
  assign cmdOutputFork_valid = (cmdArbiter_io_output_valid && axi4WriteOnlyArbiter_5_cmdArbiter_io_output_fork2_logic_linkEnable_0);
  assign cmdOutputFork_payload_addr = cmdArbiter_io_output_payload_addr;
  assign cmdOutputFork_payload_id = cmdArbiter_io_output_payload_id;
  assign cmdOutputFork_payload_len = cmdArbiter_io_output_payload_len;
  assign cmdOutputFork_payload_size = cmdArbiter_io_output_payload_size;
  assign cmdOutputFork_payload_burst = cmdArbiter_io_output_payload_burst;
  assign cmdOutputFork_payload_lock = cmdArbiter_io_output_payload_lock;
  assign cmdOutputFork_payload_cache = cmdArbiter_io_output_payload_cache;
  assign cmdOutputFork_payload_prot = cmdArbiter_io_output_payload_prot;
  assign cmdOutputFork_fire = (cmdOutputFork_valid && cmdOutputFork_ready);
  assign cmdRouteFork_valid = (cmdArbiter_io_output_valid && axi4WriteOnlyArbiter_5_cmdArbiter_io_output_fork2_logic_linkEnable_1);
  assign cmdRouteFork_payload_addr = cmdArbiter_io_output_payload_addr;
  assign cmdRouteFork_payload_id = cmdArbiter_io_output_payload_id;
  assign cmdRouteFork_payload_len = cmdArbiter_io_output_payload_len;
  assign cmdRouteFork_payload_size = cmdArbiter_io_output_payload_size;
  assign cmdRouteFork_payload_burst = cmdArbiter_io_output_payload_burst;
  assign cmdRouteFork_payload_lock = cmdArbiter_io_output_payload_lock;
  assign cmdRouteFork_payload_cache = cmdArbiter_io_output_payload_cache;
  assign cmdRouteFork_payload_prot = cmdArbiter_io_output_payload_prot;
  assign cmdRouteFork_fire = (cmdRouteFork_valid && cmdRouteFork_ready);
  assign io_output_aw_valid = cmdOutputFork_valid;
  assign cmdOutputFork_ready = io_output_aw_ready;
  assign io_output_aw_payload_addr = cmdOutputFork_payload_addr;
  assign io_output_aw_payload_len = cmdOutputFork_payload_len;
  assign io_output_aw_payload_size = cmdOutputFork_payload_size;
  assign io_output_aw_payload_burst = cmdOutputFork_payload_burst;
  assign io_output_aw_payload_lock = cmdOutputFork_payload_lock;
  assign io_output_aw_payload_cache = cmdOutputFork_payload_cache;
  assign io_output_aw_payload_prot = cmdOutputFork_payload_prot;
  assign io_output_aw_payload_id = {cmdArbiter_io_chosen,cmdArbiter_io_output_payload_id};
  assign cmdRouteFork_translated_valid = cmdRouteFork_valid;
  assign cmdRouteFork_ready = cmdRouteFork_translated_ready;
  assign cmdRouteFork_translated_payload = cmdArbiter_io_chosen;
  assign cmdRouteFork_translated_ready = cmdRouteFork_translated_fifo_io_push_ready;
  assign io_output_w_valid = (cmdRouteFork_translated_fifo_io_pop_valid && _zz_io_output_w_valid);
  assign io_output_w_payload_data = _zz_io_output_w_payload_data;
  assign io_output_w_payload_strb = _zz_io_output_w_payload_strb;
  assign io_output_w_payload_last = _zz_io_output_w_payload_last;
  assign io_inputs_0_w_ready = ((cmdRouteFork_translated_fifo_io_pop_valid && io_output_w_ready) && (cmdRouteFork_translated_fifo_io_pop_payload == 1'b0));
  assign io_inputs_1_w_ready = ((cmdRouteFork_translated_fifo_io_pop_valid && io_output_w_ready) && (cmdRouteFork_translated_fifo_io_pop_payload == 1'b1));
  assign io_output_w_fire = (io_output_w_valid && io_output_w_ready);
  assign cmdRouteFork_translated_fifo_io_pop_ready = (io_output_w_fire && io_output_w_payload_last);
  assign writeRspIndex = io_output_b_payload_id[4 : 4];
  assign writeRspSels_0 = (writeRspIndex == 1'b0);
  assign writeRspSels_1 = (writeRspIndex == 1'b1);
  assign io_inputs_0_b_valid = (io_output_b_valid && writeRspSels_0);
  assign io_inputs_0_b_payload_resp = io_output_b_payload_resp;
  assign io_inputs_0_b_payload_id = io_output_b_payload_id[3 : 0];
  assign io_inputs_1_b_valid = (io_output_b_valid && writeRspSels_1);
  assign io_inputs_1_b_payload_resp = io_output_b_payload_resp;
  assign io_inputs_1_b_payload_id = io_output_b_payload_id[3 : 0];
  assign io_output_b_ready = _zz_io_output_b_ready;
  assign cmdRouteFork_translated_fifo_io_flush = 1'b0;
  always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      axi4WriteOnlyArbiter_5_cmdArbiter_io_output_fork2_logic_linkEnable_0 <= 1'b1;
      axi4WriteOnlyArbiter_5_cmdArbiter_io_output_fork2_logic_linkEnable_1 <= 1'b1;
    end else begin
      if(cmdOutputFork_fire) begin
        axi4WriteOnlyArbiter_5_cmdArbiter_io_output_fork2_logic_linkEnable_0 <= 1'b0;
      end
      if(cmdRouteFork_fire) begin
        axi4WriteOnlyArbiter_5_cmdArbiter_io_output_fork2_logic_linkEnable_1 <= 1'b0;
      end
      if(cmdArbiter_io_output_ready) begin
        axi4WriteOnlyArbiter_5_cmdArbiter_io_output_fork2_logic_linkEnable_0 <= 1'b1;
        axi4WriteOnlyArbiter_5_cmdArbiter_io_output_fork2_logic_linkEnable_1 <= 1'b1;
      end
    end
  end


endmodule

//Axi4ReadOnlyArbiter_1 replaced by Axi4ReadOnlyArbiter

module Axi4WriteOnlyArbiter (
  input  wire          io_inputs_0_aw_valid,
  output wire          io_inputs_0_aw_ready,
  input  wire [31:0]   io_inputs_0_aw_payload_addr,
  input  wire [3:0]    io_inputs_0_aw_payload_id,
  input  wire [7:0]    io_inputs_0_aw_payload_len,
  input  wire [2:0]    io_inputs_0_aw_payload_size,
  input  wire [1:0]    io_inputs_0_aw_payload_burst,
  input  wire [0:0]    io_inputs_0_aw_payload_lock,
  input  wire [3:0]    io_inputs_0_aw_payload_cache,
  input  wire [2:0]    io_inputs_0_aw_payload_prot,
  input  wire          io_inputs_0_w_valid,
  output wire          io_inputs_0_w_ready,
  input  wire [31:0]   io_inputs_0_w_payload_data,
  input  wire [3:0]    io_inputs_0_w_payload_strb,
  input  wire          io_inputs_0_w_payload_last,
  output wire          io_inputs_0_b_valid,
  input  wire          io_inputs_0_b_ready,
  output wire [3:0]    io_inputs_0_b_payload_id,
  output wire [1:0]    io_inputs_0_b_payload_resp,
  input  wire          io_inputs_1_aw_valid,
  output wire          io_inputs_1_aw_ready,
  input  wire [31:0]   io_inputs_1_aw_payload_addr,
  input  wire [3:0]    io_inputs_1_aw_payload_id,
  input  wire [7:0]    io_inputs_1_aw_payload_len,
  input  wire [2:0]    io_inputs_1_aw_payload_size,
  input  wire [1:0]    io_inputs_1_aw_payload_burst,
  input  wire [0:0]    io_inputs_1_aw_payload_lock,
  input  wire [3:0]    io_inputs_1_aw_payload_cache,
  input  wire [2:0]    io_inputs_1_aw_payload_prot,
  input  wire          io_inputs_1_w_valid,
  output wire          io_inputs_1_w_ready,
  input  wire [31:0]   io_inputs_1_w_payload_data,
  input  wire [3:0]    io_inputs_1_w_payload_strb,
  input  wire          io_inputs_1_w_payload_last,
  output wire          io_inputs_1_b_valid,
  input  wire          io_inputs_1_b_ready,
  output wire [3:0]    io_inputs_1_b_payload_id,
  output wire [1:0]    io_inputs_1_b_payload_resp,
  output wire          io_output_aw_valid,
  input  wire          io_output_aw_ready,
  output wire [31:0]   io_output_aw_payload_addr,
  output wire [4:0]    io_output_aw_payload_id,
  output wire [7:0]    io_output_aw_payload_len,
  output wire [2:0]    io_output_aw_payload_size,
  output wire [1:0]    io_output_aw_payload_burst,
  output wire [0:0]    io_output_aw_payload_lock,
  output wire [3:0]    io_output_aw_payload_cache,
  output wire [2:0]    io_output_aw_payload_prot,
  output wire          io_output_w_valid,
  input  wire          io_output_w_ready,
  output wire [31:0]   io_output_w_payload_data,
  output wire [3:0]    io_output_w_payload_strb,
  output wire          io_output_w_payload_last,
  input  wire          io_output_b_valid,
  output wire          io_output_b_ready,
  input  wire [4:0]    io_output_b_payload_id,
  input  wire [1:0]    io_output_b_payload_resp,
  input  wire          clk,
  input  wire          resetn
);

  reg                 cmdArbiter_io_output_ready;
  wire                cmdRouteFork_translated_fifo_io_pop_ready;
  wire                cmdRouteFork_translated_fifo_io_flush;
  wire                cmdArbiter_io_inputs_0_ready;
  wire                cmdArbiter_io_inputs_1_ready;
  wire                cmdArbiter_io_output_valid;
  wire       [31:0]   cmdArbiter_io_output_payload_addr;
  wire       [3:0]    cmdArbiter_io_output_payload_id;
  wire       [7:0]    cmdArbiter_io_output_payload_len;
  wire       [2:0]    cmdArbiter_io_output_payload_size;
  wire       [1:0]    cmdArbiter_io_output_payload_burst;
  wire       [0:0]    cmdArbiter_io_output_payload_lock;
  wire       [3:0]    cmdArbiter_io_output_payload_cache;
  wire       [2:0]    cmdArbiter_io_output_payload_prot;
  wire       [0:0]    cmdArbiter_io_chosen;
  wire       [1:0]    cmdArbiter_io_chosenOH;
  wire                cmdRouteFork_translated_fifo_io_push_ready;
  wire                cmdRouteFork_translated_fifo_io_pop_valid;
  wire       [0:0]    cmdRouteFork_translated_fifo_io_pop_payload;
  wire       [2:0]    cmdRouteFork_translated_fifo_io_occupancy;
  wire       [2:0]    cmdRouteFork_translated_fifo_io_availability;
  reg                 _zz_io_output_w_valid;
  reg        [31:0]   _zz_io_output_w_payload_data;
  reg        [3:0]    _zz_io_output_w_payload_strb;
  reg                 _zz_io_output_w_payload_last;
  reg                 _zz_io_output_b_ready;
  wire                cmdOutputFork_valid;
  wire                cmdOutputFork_ready;
  wire       [31:0]   cmdOutputFork_payload_addr;
  wire       [3:0]    cmdOutputFork_payload_id;
  wire       [7:0]    cmdOutputFork_payload_len;
  wire       [2:0]    cmdOutputFork_payload_size;
  wire       [1:0]    cmdOutputFork_payload_burst;
  wire       [0:0]    cmdOutputFork_payload_lock;
  wire       [3:0]    cmdOutputFork_payload_cache;
  wire       [2:0]    cmdOutputFork_payload_prot;
  wire                cmdRouteFork_valid;
  wire                cmdRouteFork_ready;
  wire       [31:0]   cmdRouteFork_payload_addr;
  wire       [3:0]    cmdRouteFork_payload_id;
  wire       [7:0]    cmdRouteFork_payload_len;
  wire       [2:0]    cmdRouteFork_payload_size;
  wire       [1:0]    cmdRouteFork_payload_burst;
  wire       [0:0]    cmdRouteFork_payload_lock;
  wire       [3:0]    cmdRouteFork_payload_cache;
  wire       [2:0]    cmdRouteFork_payload_prot;
  reg                 axi4WriteOnlyArbiter_4_cmdArbiter_io_output_fork2_logic_linkEnable_0;
  reg                 axi4WriteOnlyArbiter_4_cmdArbiter_io_output_fork2_logic_linkEnable_1;
  wire                when_Stream_l1020;
  wire                when_Stream_l1020_1;
  wire                cmdOutputFork_fire;
  wire                cmdRouteFork_fire;
  wire                cmdRouteFork_translated_valid;
  wire                cmdRouteFork_translated_ready;
  wire       [0:0]    cmdRouteFork_translated_payload;
  wire                io_output_w_fire;
  wire       [0:0]    writeRspIndex;
  wire                writeRspSels_0;
  wire                writeRspSels_1;

  StreamArbiter_7 cmdArbiter (
    .io_inputs_0_valid         (io_inputs_0_aw_valid                   ), //i
    .io_inputs_0_ready         (cmdArbiter_io_inputs_0_ready           ), //o
    .io_inputs_0_payload_addr  (io_inputs_0_aw_payload_addr[31:0]      ), //i
    .io_inputs_0_payload_id    (io_inputs_0_aw_payload_id[3:0]         ), //i
    .io_inputs_0_payload_len   (io_inputs_0_aw_payload_len[7:0]        ), //i
    .io_inputs_0_payload_size  (io_inputs_0_aw_payload_size[2:0]       ), //i
    .io_inputs_0_payload_burst (io_inputs_0_aw_payload_burst[1:0]      ), //i
    .io_inputs_0_payload_lock  (io_inputs_0_aw_payload_lock            ), //i
    .io_inputs_0_payload_cache (io_inputs_0_aw_payload_cache[3:0]      ), //i
    .io_inputs_0_payload_prot  (io_inputs_0_aw_payload_prot[2:0]       ), //i
    .io_inputs_1_valid         (io_inputs_1_aw_valid                   ), //i
    .io_inputs_1_ready         (cmdArbiter_io_inputs_1_ready           ), //o
    .io_inputs_1_payload_addr  (io_inputs_1_aw_payload_addr[31:0]      ), //i
    .io_inputs_1_payload_id    (io_inputs_1_aw_payload_id[3:0]         ), //i
    .io_inputs_1_payload_len   (io_inputs_1_aw_payload_len[7:0]        ), //i
    .io_inputs_1_payload_size  (io_inputs_1_aw_payload_size[2:0]       ), //i
    .io_inputs_1_payload_burst (io_inputs_1_aw_payload_burst[1:0]      ), //i
    .io_inputs_1_payload_lock  (io_inputs_1_aw_payload_lock            ), //i
    .io_inputs_1_payload_cache (io_inputs_1_aw_payload_cache[3:0]      ), //i
    .io_inputs_1_payload_prot  (io_inputs_1_aw_payload_prot[2:0]       ), //i
    .io_output_valid           (cmdArbiter_io_output_valid             ), //o
    .io_output_ready           (cmdArbiter_io_output_ready             ), //i
    .io_output_payload_addr    (cmdArbiter_io_output_payload_addr[31:0]), //o
    .io_output_payload_id      (cmdArbiter_io_output_payload_id[3:0]   ), //o
    .io_output_payload_len     (cmdArbiter_io_output_payload_len[7:0]  ), //o
    .io_output_payload_size    (cmdArbiter_io_output_payload_size[2:0] ), //o
    .io_output_payload_burst   (cmdArbiter_io_output_payload_burst[1:0]), //o
    .io_output_payload_lock    (cmdArbiter_io_output_payload_lock      ), //o
    .io_output_payload_cache   (cmdArbiter_io_output_payload_cache[3:0]), //o
    .io_output_payload_prot    (cmdArbiter_io_output_payload_prot[2:0] ), //o
    .io_chosen                 (cmdArbiter_io_chosen                   ), //o
    .io_chosenOH               (cmdArbiter_io_chosenOH[1:0]            ), //o
    .clk                       (clk                                    ), //i
    .resetn                    (resetn                                 )  //i
  );
  StreamFifoLowLatency_3 cmdRouteFork_translated_fifo (
    .io_push_valid   (cmdRouteFork_translated_valid                    ), //i
    .io_push_ready   (cmdRouteFork_translated_fifo_io_push_ready       ), //o
    .io_push_payload (cmdRouteFork_translated_payload                  ), //i
    .io_pop_valid    (cmdRouteFork_translated_fifo_io_pop_valid        ), //o
    .io_pop_ready    (cmdRouteFork_translated_fifo_io_pop_ready        ), //i
    .io_pop_payload  (cmdRouteFork_translated_fifo_io_pop_payload      ), //o
    .io_flush        (cmdRouteFork_translated_fifo_io_flush            ), //i
    .io_occupancy    (cmdRouteFork_translated_fifo_io_occupancy[2:0]   ), //o
    .io_availability (cmdRouteFork_translated_fifo_io_availability[2:0]), //o
    .clk             (clk                                              ), //i
    .resetn          (resetn                                           )  //i
  );
  always @(*) begin
    case(cmdRouteFork_translated_fifo_io_pop_payload)
      1'b0 : begin
        _zz_io_output_w_valid = io_inputs_0_w_valid;
        _zz_io_output_w_payload_data = io_inputs_0_w_payload_data;
        _zz_io_output_w_payload_strb = io_inputs_0_w_payload_strb;
        _zz_io_output_w_payload_last = io_inputs_0_w_payload_last;
      end
      default : begin
        _zz_io_output_w_valid = io_inputs_1_w_valid;
        _zz_io_output_w_payload_data = io_inputs_1_w_payload_data;
        _zz_io_output_w_payload_strb = io_inputs_1_w_payload_strb;
        _zz_io_output_w_payload_last = io_inputs_1_w_payload_last;
      end
    endcase
  end

  always @(*) begin
    case(writeRspIndex)
      1'b0 : _zz_io_output_b_ready = io_inputs_0_b_ready;
      default : _zz_io_output_b_ready = io_inputs_1_b_ready;
    endcase
  end

  assign io_inputs_0_aw_ready = cmdArbiter_io_inputs_0_ready;
  assign io_inputs_1_aw_ready = cmdArbiter_io_inputs_1_ready;
  always @(*) begin
    cmdArbiter_io_output_ready = 1'b1;
    if(when_Stream_l1020) begin
      cmdArbiter_io_output_ready = 1'b0;
    end
    if(when_Stream_l1020_1) begin
      cmdArbiter_io_output_ready = 1'b0;
    end
  end

  assign when_Stream_l1020 = ((! cmdOutputFork_ready) && axi4WriteOnlyArbiter_4_cmdArbiter_io_output_fork2_logic_linkEnable_0);
  assign when_Stream_l1020_1 = ((! cmdRouteFork_ready) && axi4WriteOnlyArbiter_4_cmdArbiter_io_output_fork2_logic_linkEnable_1);
  assign cmdOutputFork_valid = (cmdArbiter_io_output_valid && axi4WriteOnlyArbiter_4_cmdArbiter_io_output_fork2_logic_linkEnable_0);
  assign cmdOutputFork_payload_addr = cmdArbiter_io_output_payload_addr;
  assign cmdOutputFork_payload_id = cmdArbiter_io_output_payload_id;
  assign cmdOutputFork_payload_len = cmdArbiter_io_output_payload_len;
  assign cmdOutputFork_payload_size = cmdArbiter_io_output_payload_size;
  assign cmdOutputFork_payload_burst = cmdArbiter_io_output_payload_burst;
  assign cmdOutputFork_payload_lock = cmdArbiter_io_output_payload_lock;
  assign cmdOutputFork_payload_cache = cmdArbiter_io_output_payload_cache;
  assign cmdOutputFork_payload_prot = cmdArbiter_io_output_payload_prot;
  assign cmdOutputFork_fire = (cmdOutputFork_valid && cmdOutputFork_ready);
  assign cmdRouteFork_valid = (cmdArbiter_io_output_valid && axi4WriteOnlyArbiter_4_cmdArbiter_io_output_fork2_logic_linkEnable_1);
  assign cmdRouteFork_payload_addr = cmdArbiter_io_output_payload_addr;
  assign cmdRouteFork_payload_id = cmdArbiter_io_output_payload_id;
  assign cmdRouteFork_payload_len = cmdArbiter_io_output_payload_len;
  assign cmdRouteFork_payload_size = cmdArbiter_io_output_payload_size;
  assign cmdRouteFork_payload_burst = cmdArbiter_io_output_payload_burst;
  assign cmdRouteFork_payload_lock = cmdArbiter_io_output_payload_lock;
  assign cmdRouteFork_payload_cache = cmdArbiter_io_output_payload_cache;
  assign cmdRouteFork_payload_prot = cmdArbiter_io_output_payload_prot;
  assign cmdRouteFork_fire = (cmdRouteFork_valid && cmdRouteFork_ready);
  assign io_output_aw_valid = cmdOutputFork_valid;
  assign cmdOutputFork_ready = io_output_aw_ready;
  assign io_output_aw_payload_addr = cmdOutputFork_payload_addr;
  assign io_output_aw_payload_len = cmdOutputFork_payload_len;
  assign io_output_aw_payload_size = cmdOutputFork_payload_size;
  assign io_output_aw_payload_burst = cmdOutputFork_payload_burst;
  assign io_output_aw_payload_lock = cmdOutputFork_payload_lock;
  assign io_output_aw_payload_cache = cmdOutputFork_payload_cache;
  assign io_output_aw_payload_prot = cmdOutputFork_payload_prot;
  assign io_output_aw_payload_id = {cmdArbiter_io_chosen,cmdArbiter_io_output_payload_id};
  assign cmdRouteFork_translated_valid = cmdRouteFork_valid;
  assign cmdRouteFork_ready = cmdRouteFork_translated_ready;
  assign cmdRouteFork_translated_payload = cmdArbiter_io_chosen;
  assign cmdRouteFork_translated_ready = cmdRouteFork_translated_fifo_io_push_ready;
  assign io_output_w_valid = (cmdRouteFork_translated_fifo_io_pop_valid && _zz_io_output_w_valid);
  assign io_output_w_payload_data = _zz_io_output_w_payload_data;
  assign io_output_w_payload_strb = _zz_io_output_w_payload_strb;
  assign io_output_w_payload_last = _zz_io_output_w_payload_last;
  assign io_inputs_0_w_ready = ((cmdRouteFork_translated_fifo_io_pop_valid && io_output_w_ready) && (cmdRouteFork_translated_fifo_io_pop_payload == 1'b0));
  assign io_inputs_1_w_ready = ((cmdRouteFork_translated_fifo_io_pop_valid && io_output_w_ready) && (cmdRouteFork_translated_fifo_io_pop_payload == 1'b1));
  assign io_output_w_fire = (io_output_w_valid && io_output_w_ready);
  assign cmdRouteFork_translated_fifo_io_pop_ready = (io_output_w_fire && io_output_w_payload_last);
  assign writeRspIndex = io_output_b_payload_id[4 : 4];
  assign writeRspSels_0 = (writeRspIndex == 1'b0);
  assign writeRspSels_1 = (writeRspIndex == 1'b1);
  assign io_inputs_0_b_valid = (io_output_b_valid && writeRspSels_0);
  assign io_inputs_0_b_payload_resp = io_output_b_payload_resp;
  assign io_inputs_0_b_payload_id = io_output_b_payload_id[3 : 0];
  assign io_inputs_1_b_valid = (io_output_b_valid && writeRspSels_1);
  assign io_inputs_1_b_payload_resp = io_output_b_payload_resp;
  assign io_inputs_1_b_payload_id = io_output_b_payload_id[3 : 0];
  assign io_output_b_ready = _zz_io_output_b_ready;
  assign cmdRouteFork_translated_fifo_io_flush = 1'b0;
  always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      axi4WriteOnlyArbiter_4_cmdArbiter_io_output_fork2_logic_linkEnable_0 <= 1'b1;
      axi4WriteOnlyArbiter_4_cmdArbiter_io_output_fork2_logic_linkEnable_1 <= 1'b1;
    end else begin
      if(cmdOutputFork_fire) begin
        axi4WriteOnlyArbiter_4_cmdArbiter_io_output_fork2_logic_linkEnable_0 <= 1'b0;
      end
      if(cmdRouteFork_fire) begin
        axi4WriteOnlyArbiter_4_cmdArbiter_io_output_fork2_logic_linkEnable_1 <= 1'b0;
      end
      if(cmdArbiter_io_output_ready) begin
        axi4WriteOnlyArbiter_4_cmdArbiter_io_output_fork2_logic_linkEnable_0 <= 1'b1;
        axi4WriteOnlyArbiter_4_cmdArbiter_io_output_fork2_logic_linkEnable_1 <= 1'b1;
      end
    end
  end


endmodule

module Axi4ReadOnlyArbiter (
  input  wire          io_inputs_0_ar_valid,
  output wire          io_inputs_0_ar_ready,
  input  wire [31:0]   io_inputs_0_ar_payload_addr,
  input  wire [3:0]    io_inputs_0_ar_payload_id,
  input  wire [7:0]    io_inputs_0_ar_payload_len,
  input  wire [2:0]    io_inputs_0_ar_payload_size,
  input  wire [1:0]    io_inputs_0_ar_payload_burst,
  input  wire [0:0]    io_inputs_0_ar_payload_lock,
  input  wire [3:0]    io_inputs_0_ar_payload_cache,
  input  wire [2:0]    io_inputs_0_ar_payload_prot,
  output wire          io_inputs_0_r_valid,
  input  wire          io_inputs_0_r_ready,
  output wire [31:0]   io_inputs_0_r_payload_data,
  output wire [3:0]    io_inputs_0_r_payload_id,
  output wire [1:0]    io_inputs_0_r_payload_resp,
  output wire          io_inputs_0_r_payload_last,
  input  wire          io_inputs_1_ar_valid,
  output wire          io_inputs_1_ar_ready,
  input  wire [31:0]   io_inputs_1_ar_payload_addr,
  input  wire [3:0]    io_inputs_1_ar_payload_id,
  input  wire [7:0]    io_inputs_1_ar_payload_len,
  input  wire [2:0]    io_inputs_1_ar_payload_size,
  input  wire [1:0]    io_inputs_1_ar_payload_burst,
  input  wire [0:0]    io_inputs_1_ar_payload_lock,
  input  wire [3:0]    io_inputs_1_ar_payload_cache,
  input  wire [2:0]    io_inputs_1_ar_payload_prot,
  output wire          io_inputs_1_r_valid,
  input  wire          io_inputs_1_r_ready,
  output wire [31:0]   io_inputs_1_r_payload_data,
  output wire [3:0]    io_inputs_1_r_payload_id,
  output wire [1:0]    io_inputs_1_r_payload_resp,
  output wire          io_inputs_1_r_payload_last,
  output wire          io_output_ar_valid,
  input  wire          io_output_ar_ready,
  output wire [31:0]   io_output_ar_payload_addr,
  output wire [4:0]    io_output_ar_payload_id,
  output wire [7:0]    io_output_ar_payload_len,
  output wire [2:0]    io_output_ar_payload_size,
  output wire [1:0]    io_output_ar_payload_burst,
  output wire [0:0]    io_output_ar_payload_lock,
  output wire [3:0]    io_output_ar_payload_cache,
  output wire [2:0]    io_output_ar_payload_prot,
  input  wire          io_output_r_valid,
  output wire          io_output_r_ready,
  input  wire [31:0]   io_output_r_payload_data,
  input  wire [4:0]    io_output_r_payload_id,
  input  wire [1:0]    io_output_r_payload_resp,
  input  wire          io_output_r_payload_last,
  input  wire          clk,
  input  wire          resetn
);

  wire                cmdArbiter_io_inputs_0_ready;
  wire                cmdArbiter_io_inputs_1_ready;
  wire                cmdArbiter_io_output_valid;
  wire       [31:0]   cmdArbiter_io_output_payload_addr;
  wire       [3:0]    cmdArbiter_io_output_payload_id;
  wire       [7:0]    cmdArbiter_io_output_payload_len;
  wire       [2:0]    cmdArbiter_io_output_payload_size;
  wire       [1:0]    cmdArbiter_io_output_payload_burst;
  wire       [0:0]    cmdArbiter_io_output_payload_lock;
  wire       [3:0]    cmdArbiter_io_output_payload_cache;
  wire       [2:0]    cmdArbiter_io_output_payload_prot;
  wire       [0:0]    cmdArbiter_io_chosen;
  wire       [1:0]    cmdArbiter_io_chosenOH;
  reg                 _zz_io_output_r_ready;
  wire       [0:0]    readRspIndex;
  wire                readRspSels_0;
  wire                readRspSels_1;

  StreamArbiter_7 cmdArbiter (
    .io_inputs_0_valid         (io_inputs_0_ar_valid                   ), //i
    .io_inputs_0_ready         (cmdArbiter_io_inputs_0_ready           ), //o
    .io_inputs_0_payload_addr  (io_inputs_0_ar_payload_addr[31:0]      ), //i
    .io_inputs_0_payload_id    (io_inputs_0_ar_payload_id[3:0]         ), //i
    .io_inputs_0_payload_len   (io_inputs_0_ar_payload_len[7:0]        ), //i
    .io_inputs_0_payload_size  (io_inputs_0_ar_payload_size[2:0]       ), //i
    .io_inputs_0_payload_burst (io_inputs_0_ar_payload_burst[1:0]      ), //i
    .io_inputs_0_payload_lock  (io_inputs_0_ar_payload_lock            ), //i
    .io_inputs_0_payload_cache (io_inputs_0_ar_payload_cache[3:0]      ), //i
    .io_inputs_0_payload_prot  (io_inputs_0_ar_payload_prot[2:0]       ), //i
    .io_inputs_1_valid         (io_inputs_1_ar_valid                   ), //i
    .io_inputs_1_ready         (cmdArbiter_io_inputs_1_ready           ), //o
    .io_inputs_1_payload_addr  (io_inputs_1_ar_payload_addr[31:0]      ), //i
    .io_inputs_1_payload_id    (io_inputs_1_ar_payload_id[3:0]         ), //i
    .io_inputs_1_payload_len   (io_inputs_1_ar_payload_len[7:0]        ), //i
    .io_inputs_1_payload_size  (io_inputs_1_ar_payload_size[2:0]       ), //i
    .io_inputs_1_payload_burst (io_inputs_1_ar_payload_burst[1:0]      ), //i
    .io_inputs_1_payload_lock  (io_inputs_1_ar_payload_lock            ), //i
    .io_inputs_1_payload_cache (io_inputs_1_ar_payload_cache[3:0]      ), //i
    .io_inputs_1_payload_prot  (io_inputs_1_ar_payload_prot[2:0]       ), //i
    .io_output_valid           (cmdArbiter_io_output_valid             ), //o
    .io_output_ready           (io_output_ar_ready                     ), //i
    .io_output_payload_addr    (cmdArbiter_io_output_payload_addr[31:0]), //o
    .io_output_payload_id      (cmdArbiter_io_output_payload_id[3:0]   ), //o
    .io_output_payload_len     (cmdArbiter_io_output_payload_len[7:0]  ), //o
    .io_output_payload_size    (cmdArbiter_io_output_payload_size[2:0] ), //o
    .io_output_payload_burst   (cmdArbiter_io_output_payload_burst[1:0]), //o
    .io_output_payload_lock    (cmdArbiter_io_output_payload_lock      ), //o
    .io_output_payload_cache   (cmdArbiter_io_output_payload_cache[3:0]), //o
    .io_output_payload_prot    (cmdArbiter_io_output_payload_prot[2:0] ), //o
    .io_chosen                 (cmdArbiter_io_chosen                   ), //o
    .io_chosenOH               (cmdArbiter_io_chosenOH[1:0]            ), //o
    .clk                       (clk                                    ), //i
    .resetn                    (resetn                                 )  //i
  );
  always @(*) begin
    case(readRspIndex)
      1'b0 : _zz_io_output_r_ready = io_inputs_0_r_ready;
      default : _zz_io_output_r_ready = io_inputs_1_r_ready;
    endcase
  end

  assign io_inputs_0_ar_ready = cmdArbiter_io_inputs_0_ready;
  assign io_inputs_1_ar_ready = cmdArbiter_io_inputs_1_ready;
  assign io_output_ar_valid = cmdArbiter_io_output_valid;
  assign io_output_ar_payload_addr = cmdArbiter_io_output_payload_addr;
  assign io_output_ar_payload_len = cmdArbiter_io_output_payload_len;
  assign io_output_ar_payload_size = cmdArbiter_io_output_payload_size;
  assign io_output_ar_payload_burst = cmdArbiter_io_output_payload_burst;
  assign io_output_ar_payload_lock = cmdArbiter_io_output_payload_lock;
  assign io_output_ar_payload_cache = cmdArbiter_io_output_payload_cache;
  assign io_output_ar_payload_prot = cmdArbiter_io_output_payload_prot;
  assign io_output_ar_payload_id = {cmdArbiter_io_chosen,cmdArbiter_io_output_payload_id};
  assign readRspIndex = io_output_r_payload_id[4 : 4];
  assign readRspSels_0 = (readRspIndex == 1'b0);
  assign readRspSels_1 = (readRspIndex == 1'b1);
  assign io_inputs_0_r_valid = (io_output_r_valid && readRspSels_0);
  assign io_inputs_0_r_payload_data = io_output_r_payload_data;
  assign io_inputs_0_r_payload_resp = io_output_r_payload_resp;
  assign io_inputs_0_r_payload_last = io_output_r_payload_last;
  assign io_inputs_0_r_payload_id = io_output_r_payload_id[3 : 0];
  assign io_inputs_1_r_valid = (io_output_r_valid && readRspSels_1);
  assign io_inputs_1_r_payload_data = io_output_r_payload_data;
  assign io_inputs_1_r_payload_resp = io_output_r_payload_resp;
  assign io_inputs_1_r_payload_last = io_output_r_payload_last;
  assign io_inputs_1_r_payload_id = io_output_r_payload_id[3 : 0];
  assign io_output_r_ready = _zz_io_output_r_ready;

endmodule

module Axi4WriteOnlyDecoder_1 (
  input  wire          io_input_aw_valid,
  output wire          io_input_aw_ready,
  input  wire [31:0]   io_input_aw_payload_addr,
  input  wire [3:0]    io_input_aw_payload_id,
  input  wire [7:0]    io_input_aw_payload_len,
  input  wire [2:0]    io_input_aw_payload_size,
  input  wire [1:0]    io_input_aw_payload_burst,
  input  wire [0:0]    io_input_aw_payload_lock,
  input  wire [3:0]    io_input_aw_payload_cache,
  input  wire [2:0]    io_input_aw_payload_prot,
  input  wire          io_input_w_valid,
  output wire          io_input_w_ready,
  input  wire [31:0]   io_input_w_payload_data,
  input  wire [3:0]    io_input_w_payload_strb,
  input  wire          io_input_w_payload_last,
  output wire          io_input_b_valid,
  input  wire          io_input_b_ready,
  output reg  [3:0]    io_input_b_payload_id,
  output reg  [1:0]    io_input_b_payload_resp,
  output wire          io_outputs_0_aw_valid,
  input  wire          io_outputs_0_aw_ready,
  output wire [31:0]   io_outputs_0_aw_payload_addr,
  output wire [3:0]    io_outputs_0_aw_payload_id,
  output wire [7:0]    io_outputs_0_aw_payload_len,
  output wire [2:0]    io_outputs_0_aw_payload_size,
  output wire [1:0]    io_outputs_0_aw_payload_burst,
  output wire [0:0]    io_outputs_0_aw_payload_lock,
  output wire [3:0]    io_outputs_0_aw_payload_cache,
  output wire [2:0]    io_outputs_0_aw_payload_prot,
  output wire          io_outputs_0_w_valid,
  input  wire          io_outputs_0_w_ready,
  output wire [31:0]   io_outputs_0_w_payload_data,
  output wire [3:0]    io_outputs_0_w_payload_strb,
  output wire          io_outputs_0_w_payload_last,
  input  wire          io_outputs_0_b_valid,
  output wire          io_outputs_0_b_ready,
  input  wire [3:0]    io_outputs_0_b_payload_id,
  input  wire [1:0]    io_outputs_0_b_payload_resp,
  output wire          io_outputs_1_aw_valid,
  input  wire          io_outputs_1_aw_ready,
  output wire [31:0]   io_outputs_1_aw_payload_addr,
  output wire [3:0]    io_outputs_1_aw_payload_id,
  output wire [7:0]    io_outputs_1_aw_payload_len,
  output wire [2:0]    io_outputs_1_aw_payload_size,
  output wire [1:0]    io_outputs_1_aw_payload_burst,
  output wire [0:0]    io_outputs_1_aw_payload_lock,
  output wire [3:0]    io_outputs_1_aw_payload_cache,
  output wire [2:0]    io_outputs_1_aw_payload_prot,
  output wire          io_outputs_1_w_valid,
  input  wire          io_outputs_1_w_ready,
  output wire [31:0]   io_outputs_1_w_payload_data,
  output wire [3:0]    io_outputs_1_w_payload_strb,
  output wire          io_outputs_1_w_payload_last,
  input  wire          io_outputs_1_b_valid,
  output wire          io_outputs_1_b_ready,
  input  wire [3:0]    io_outputs_1_b_payload_id,
  input  wire [1:0]    io_outputs_1_b_payload_resp,
  output wire          io_outputs_2_aw_valid,
  input  wire          io_outputs_2_aw_ready,
  output wire [31:0]   io_outputs_2_aw_payload_addr,
  output wire [3:0]    io_outputs_2_aw_payload_id,
  output wire [7:0]    io_outputs_2_aw_payload_len,
  output wire [2:0]    io_outputs_2_aw_payload_size,
  output wire [1:0]    io_outputs_2_aw_payload_burst,
  output wire [0:0]    io_outputs_2_aw_payload_lock,
  output wire [3:0]    io_outputs_2_aw_payload_cache,
  output wire [2:0]    io_outputs_2_aw_payload_prot,
  output wire          io_outputs_2_w_valid,
  input  wire          io_outputs_2_w_ready,
  output wire [31:0]   io_outputs_2_w_payload_data,
  output wire [3:0]    io_outputs_2_w_payload_strb,
  output wire          io_outputs_2_w_payload_last,
  input  wire          io_outputs_2_b_valid,
  output wire          io_outputs_2_b_ready,
  input  wire [3:0]    io_outputs_2_b_payload_id,
  input  wire [1:0]    io_outputs_2_b_payload_resp,
  output wire          io_outputs_3_aw_valid,
  input  wire          io_outputs_3_aw_ready,
  output wire [31:0]   io_outputs_3_aw_payload_addr,
  output wire [3:0]    io_outputs_3_aw_payload_id,
  output wire [7:0]    io_outputs_3_aw_payload_len,
  output wire [2:0]    io_outputs_3_aw_payload_size,
  output wire [1:0]    io_outputs_3_aw_payload_burst,
  output wire [0:0]    io_outputs_3_aw_payload_lock,
  output wire [3:0]    io_outputs_3_aw_payload_cache,
  output wire [2:0]    io_outputs_3_aw_payload_prot,
  output wire          io_outputs_3_w_valid,
  input  wire          io_outputs_3_w_ready,
  output wire [31:0]   io_outputs_3_w_payload_data,
  output wire [3:0]    io_outputs_3_w_payload_strb,
  output wire          io_outputs_3_w_payload_last,
  input  wire          io_outputs_3_b_valid,
  output wire          io_outputs_3_b_ready,
  input  wire [3:0]    io_outputs_3_b_payload_id,
  input  wire [1:0]    io_outputs_3_b_payload_resp,
  input  wire          clk,
  input  wire          resetn
);

  wire                errorSlave_io_axi_aw_valid;
  wire                errorSlave_io_axi_w_valid;
  wire                errorSlave_io_axi_aw_ready;
  wire                errorSlave_io_axi_w_ready;
  wire                errorSlave_io_axi_b_valid;
  wire       [3:0]    errorSlave_io_axi_b_payload_id;
  wire       [1:0]    errorSlave_io_axi_b_payload_resp;
  wire       [31:0]   _zz_decodedCmdSels;
  wire       [31:0]   _zz_decodedCmdSels_1;
  wire       [31:0]   _zz_decodedCmdSels_2;
  wire       [31:0]   _zz_decodedCmdSels_3;
  wire       [31:0]   _zz_decodedCmdSels_4;
  wire       [31:0]   _zz_decodedCmdSels_5;
  reg        [3:0]    _zz_io_input_b_payload_id;
  reg        [1:0]    _zz_io_input_b_payload_resp;
  wire                cmdAllowedStart;
  wire                io_input_aw_fire;
  wire                io_input_b_fire;
  reg                 pendingCmdCounter_incrementIt;
  reg                 pendingCmdCounter_decrementIt;
  wire       [2:0]    pendingCmdCounter_valueNext;
  reg        [2:0]    pendingCmdCounter_value;
  wire                pendingCmdCounter_mayOverflow;
  wire                pendingCmdCounter_willOverflowIfInc;
  wire                pendingCmdCounter_willOverflow;
  reg        [2:0]    pendingCmdCounter_finalIncrement;
  wire                when_Utils_l723;
  wire                when_Utils_l725;
  wire                io_input_w_fire;
  wire                when_Utils_l697;
  reg                 pendingDataCounter_incrementIt;
  reg                 pendingDataCounter_decrementIt;
  wire       [2:0]    pendingDataCounter_valueNext;
  reg        [2:0]    pendingDataCounter_value;
  wire                pendingDataCounter_mayOverflow;
  wire                pendingDataCounter_willOverflowIfInc;
  wire                pendingDataCounter_willOverflow;
  reg        [2:0]    pendingDataCounter_finalIncrement;
  wire                when_Utils_l723_1;
  wire                when_Utils_l725_1;
  wire       [3:0]    decodedCmdSels;
  wire                decodedCmdError;
  reg        [3:0]    pendingSels;
  reg                 pendingError;
  wire                allowCmd;
  wire                allowData;
  reg                 _zz_cmdAllowedStart;
  wire                _zz_io_outputs_1_w_valid;
  wire                _zz_io_outputs_2_w_valid;
  wire                _zz_io_outputs_3_w_valid;
  wire                _zz_writeRspIndex;
  wire                _zz_writeRspIndex_1;
  wire       [1:0]    writeRspIndex;

  assign _zz_decodedCmdSels = 32'h000fffff;
  assign _zz_decodedCmdSels_1 = (~ 32'h000fffff);
  assign _zz_decodedCmdSels_2 = (io_input_aw_payload_addr & (~ 32'h007fffff));
  assign _zz_decodedCmdSels_3 = 32'h00000000;
  assign _zz_decodedCmdSels_4 = (io_input_aw_payload_addr & (~ 32'h007fffff));
  assign _zz_decodedCmdSels_5 = 32'h1c000000;
  Axi4WriteOnlyErrorSlave_1 errorSlave (
    .io_axi_aw_valid         (errorSlave_io_axi_aw_valid           ), //i
    .io_axi_aw_ready         (errorSlave_io_axi_aw_ready           ), //o
    .io_axi_aw_payload_addr  (io_input_aw_payload_addr[31:0]       ), //i
    .io_axi_aw_payload_id    (io_input_aw_payload_id[3:0]          ), //i
    .io_axi_aw_payload_len   (io_input_aw_payload_len[7:0]         ), //i
    .io_axi_aw_payload_size  (io_input_aw_payload_size[2:0]        ), //i
    .io_axi_aw_payload_burst (io_input_aw_payload_burst[1:0]       ), //i
    .io_axi_aw_payload_lock  (io_input_aw_payload_lock             ), //i
    .io_axi_aw_payload_cache (io_input_aw_payload_cache[3:0]       ), //i
    .io_axi_aw_payload_prot  (io_input_aw_payload_prot[2:0]        ), //i
    .io_axi_w_valid          (errorSlave_io_axi_w_valid            ), //i
    .io_axi_w_ready          (errorSlave_io_axi_w_ready            ), //o
    .io_axi_w_payload_data   (io_input_w_payload_data[31:0]        ), //i
    .io_axi_w_payload_strb   (io_input_w_payload_strb[3:0]         ), //i
    .io_axi_w_payload_last   (io_input_w_payload_last              ), //i
    .io_axi_b_valid          (errorSlave_io_axi_b_valid            ), //o
    .io_axi_b_ready          (io_input_b_ready                     ), //i
    .io_axi_b_payload_id     (errorSlave_io_axi_b_payload_id[3:0]  ), //o
    .io_axi_b_payload_resp   (errorSlave_io_axi_b_payload_resp[1:0]), //o
    .clk                     (clk                                  ), //i
    .resetn                  (resetn                               )  //i
  );
  always @(*) begin
    case(writeRspIndex)
      2'b00 : begin
        _zz_io_input_b_payload_id = io_outputs_0_b_payload_id;
        _zz_io_input_b_payload_resp = io_outputs_0_b_payload_resp;
      end
      2'b01 : begin
        _zz_io_input_b_payload_id = io_outputs_1_b_payload_id;
        _zz_io_input_b_payload_resp = io_outputs_1_b_payload_resp;
      end
      2'b10 : begin
        _zz_io_input_b_payload_id = io_outputs_2_b_payload_id;
        _zz_io_input_b_payload_resp = io_outputs_2_b_payload_resp;
      end
      default : begin
        _zz_io_input_b_payload_id = io_outputs_3_b_payload_id;
        _zz_io_input_b_payload_resp = io_outputs_3_b_payload_resp;
      end
    endcase
  end

  assign io_input_aw_fire = (io_input_aw_valid && io_input_aw_ready);
  assign io_input_b_fire = (io_input_b_valid && io_input_b_ready);
  always @(*) begin
    pendingCmdCounter_incrementIt = 1'b0;
    if(io_input_aw_fire) begin
      pendingCmdCounter_incrementIt = 1'b1;
    end
  end

  always @(*) begin
    pendingCmdCounter_decrementIt = 1'b0;
    if(io_input_b_fire) begin
      pendingCmdCounter_decrementIt = 1'b1;
    end
  end

  assign pendingCmdCounter_mayOverflow = (pendingCmdCounter_value == 3'b111);
  assign pendingCmdCounter_willOverflowIfInc = (pendingCmdCounter_mayOverflow && (! pendingCmdCounter_decrementIt));
  assign pendingCmdCounter_willOverflow = (pendingCmdCounter_willOverflowIfInc && pendingCmdCounter_incrementIt);
  assign when_Utils_l723 = (pendingCmdCounter_incrementIt && (! pendingCmdCounter_decrementIt));
  always @(*) begin
    if(when_Utils_l723) begin
      pendingCmdCounter_finalIncrement = 3'b001;
    end else begin
      if(when_Utils_l725) begin
        pendingCmdCounter_finalIncrement = 3'b111;
      end else begin
        pendingCmdCounter_finalIncrement = 3'b000;
      end
    end
  end

  assign when_Utils_l725 = ((! pendingCmdCounter_incrementIt) && pendingCmdCounter_decrementIt);
  assign pendingCmdCounter_valueNext = (pendingCmdCounter_value + pendingCmdCounter_finalIncrement);
  assign io_input_w_fire = (io_input_w_valid && io_input_w_ready);
  assign when_Utils_l697 = (io_input_w_fire && io_input_w_payload_last);
  always @(*) begin
    pendingDataCounter_incrementIt = 1'b0;
    if(cmdAllowedStart) begin
      pendingDataCounter_incrementIt = 1'b1;
    end
  end

  always @(*) begin
    pendingDataCounter_decrementIt = 1'b0;
    if(when_Utils_l697) begin
      pendingDataCounter_decrementIt = 1'b1;
    end
  end

  assign pendingDataCounter_mayOverflow = (pendingDataCounter_value == 3'b111);
  assign pendingDataCounter_willOverflowIfInc = (pendingDataCounter_mayOverflow && (! pendingDataCounter_decrementIt));
  assign pendingDataCounter_willOverflow = (pendingDataCounter_willOverflowIfInc && pendingDataCounter_incrementIt);
  assign when_Utils_l723_1 = (pendingDataCounter_incrementIt && (! pendingDataCounter_decrementIt));
  always @(*) begin
    if(when_Utils_l723_1) begin
      pendingDataCounter_finalIncrement = 3'b001;
    end else begin
      if(when_Utils_l725_1) begin
        pendingDataCounter_finalIncrement = 3'b111;
      end else begin
        pendingDataCounter_finalIncrement = 3'b000;
      end
    end
  end

  assign when_Utils_l725_1 = ((! pendingDataCounter_incrementIt) && pendingDataCounter_decrementIt);
  assign pendingDataCounter_valueNext = (pendingDataCounter_value + pendingDataCounter_finalIncrement);
  assign decodedCmdSels = {(((io_input_aw_payload_addr & (~ _zz_decodedCmdSels)) == 32'h1f500000) && io_input_aw_valid),{(((io_input_aw_payload_addr & _zz_decodedCmdSels_1) == 32'h1f400000) && io_input_aw_valid),{((_zz_decodedCmdSels_2 == _zz_decodedCmdSels_3) && io_input_aw_valid),((_zz_decodedCmdSels_4 == _zz_decodedCmdSels_5) && io_input_aw_valid)}}};
  assign decodedCmdError = (decodedCmdSels == 4'b0000);
  assign allowCmd = ((pendingCmdCounter_value == 3'b000) || ((pendingCmdCounter_value != 3'b111) && (pendingSels == decodedCmdSels)));
  assign allowData = (pendingDataCounter_value != 3'b000);
  assign cmdAllowedStart = ((io_input_aw_valid && allowCmd) && _zz_cmdAllowedStart);
  assign io_input_aw_ready = (((|(decodedCmdSels & {io_outputs_3_aw_ready,{io_outputs_2_aw_ready,{io_outputs_1_aw_ready,io_outputs_0_aw_ready}}})) || (decodedCmdError && errorSlave_io_axi_aw_ready)) && allowCmd);
  assign errorSlave_io_axi_aw_valid = ((io_input_aw_valid && decodedCmdError) && allowCmd);
  assign io_outputs_0_aw_valid = ((io_input_aw_valid && decodedCmdSels[0]) && allowCmd);
  assign io_outputs_0_aw_payload_addr = io_input_aw_payload_addr;
  assign io_outputs_0_aw_payload_id = io_input_aw_payload_id;
  assign io_outputs_0_aw_payload_len = io_input_aw_payload_len;
  assign io_outputs_0_aw_payload_size = io_input_aw_payload_size;
  assign io_outputs_0_aw_payload_burst = io_input_aw_payload_burst;
  assign io_outputs_0_aw_payload_lock = io_input_aw_payload_lock;
  assign io_outputs_0_aw_payload_cache = io_input_aw_payload_cache;
  assign io_outputs_0_aw_payload_prot = io_input_aw_payload_prot;
  assign io_outputs_1_aw_valid = ((io_input_aw_valid && decodedCmdSels[1]) && allowCmd);
  assign io_outputs_1_aw_payload_addr = io_input_aw_payload_addr;
  assign io_outputs_1_aw_payload_id = io_input_aw_payload_id;
  assign io_outputs_1_aw_payload_len = io_input_aw_payload_len;
  assign io_outputs_1_aw_payload_size = io_input_aw_payload_size;
  assign io_outputs_1_aw_payload_burst = io_input_aw_payload_burst;
  assign io_outputs_1_aw_payload_lock = io_input_aw_payload_lock;
  assign io_outputs_1_aw_payload_cache = io_input_aw_payload_cache;
  assign io_outputs_1_aw_payload_prot = io_input_aw_payload_prot;
  assign io_outputs_2_aw_valid = ((io_input_aw_valid && decodedCmdSels[2]) && allowCmd);
  assign io_outputs_2_aw_payload_addr = io_input_aw_payload_addr;
  assign io_outputs_2_aw_payload_id = io_input_aw_payload_id;
  assign io_outputs_2_aw_payload_len = io_input_aw_payload_len;
  assign io_outputs_2_aw_payload_size = io_input_aw_payload_size;
  assign io_outputs_2_aw_payload_burst = io_input_aw_payload_burst;
  assign io_outputs_2_aw_payload_lock = io_input_aw_payload_lock;
  assign io_outputs_2_aw_payload_cache = io_input_aw_payload_cache;
  assign io_outputs_2_aw_payload_prot = io_input_aw_payload_prot;
  assign io_outputs_3_aw_valid = ((io_input_aw_valid && decodedCmdSels[3]) && allowCmd);
  assign io_outputs_3_aw_payload_addr = io_input_aw_payload_addr;
  assign io_outputs_3_aw_payload_id = io_input_aw_payload_id;
  assign io_outputs_3_aw_payload_len = io_input_aw_payload_len;
  assign io_outputs_3_aw_payload_size = io_input_aw_payload_size;
  assign io_outputs_3_aw_payload_burst = io_input_aw_payload_burst;
  assign io_outputs_3_aw_payload_lock = io_input_aw_payload_lock;
  assign io_outputs_3_aw_payload_cache = io_input_aw_payload_cache;
  assign io_outputs_3_aw_payload_prot = io_input_aw_payload_prot;
  assign io_input_w_ready = (((|(pendingSels & {io_outputs_3_w_ready,{io_outputs_2_w_ready,{io_outputs_1_w_ready,io_outputs_0_w_ready}}})) || (pendingError && errorSlave_io_axi_w_ready)) && allowData);
  assign errorSlave_io_axi_w_valid = ((io_input_w_valid && pendingError) && allowData);
  assign _zz_io_outputs_1_w_valid = pendingSels[1];
  assign _zz_io_outputs_2_w_valid = pendingSels[2];
  assign _zz_io_outputs_3_w_valid = pendingSels[3];
  assign io_outputs_0_w_valid = ((io_input_w_valid && pendingSels[0]) && allowData);
  assign io_outputs_0_w_payload_data = io_input_w_payload_data;
  assign io_outputs_0_w_payload_strb = io_input_w_payload_strb;
  assign io_outputs_0_w_payload_last = io_input_w_payload_last;
  assign io_outputs_1_w_valid = ((io_input_w_valid && _zz_io_outputs_1_w_valid) && allowData);
  assign io_outputs_1_w_payload_data = io_input_w_payload_data;
  assign io_outputs_1_w_payload_strb = io_input_w_payload_strb;
  assign io_outputs_1_w_payload_last = io_input_w_payload_last;
  assign io_outputs_2_w_valid = ((io_input_w_valid && _zz_io_outputs_2_w_valid) && allowData);
  assign io_outputs_2_w_payload_data = io_input_w_payload_data;
  assign io_outputs_2_w_payload_strb = io_input_w_payload_strb;
  assign io_outputs_2_w_payload_last = io_input_w_payload_last;
  assign io_outputs_3_w_valid = ((io_input_w_valid && _zz_io_outputs_3_w_valid) && allowData);
  assign io_outputs_3_w_payload_data = io_input_w_payload_data;
  assign io_outputs_3_w_payload_strb = io_input_w_payload_strb;
  assign io_outputs_3_w_payload_last = io_input_w_payload_last;
  assign _zz_writeRspIndex = (_zz_io_outputs_1_w_valid || _zz_io_outputs_3_w_valid);
  assign _zz_writeRspIndex_1 = (_zz_io_outputs_2_w_valid || _zz_io_outputs_3_w_valid);
  assign writeRspIndex = {_zz_writeRspIndex_1,_zz_writeRspIndex};
  assign io_input_b_valid = ((|{io_outputs_3_b_valid,{io_outputs_2_b_valid,{io_outputs_1_b_valid,io_outputs_0_b_valid}}}) || errorSlave_io_axi_b_valid);
  always @(*) begin
    io_input_b_payload_id = _zz_io_input_b_payload_id;
    if(pendingError) begin
      io_input_b_payload_id = errorSlave_io_axi_b_payload_id;
    end
  end

  always @(*) begin
    io_input_b_payload_resp = _zz_io_input_b_payload_resp;
    if(pendingError) begin
      io_input_b_payload_resp = errorSlave_io_axi_b_payload_resp;
    end
  end

  assign io_outputs_0_b_ready = io_input_b_ready;
  assign io_outputs_1_b_ready = io_input_b_ready;
  assign io_outputs_2_b_ready = io_input_b_ready;
  assign io_outputs_3_b_ready = io_input_b_ready;
  always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      pendingCmdCounter_value <= 3'b000;
      pendingDataCounter_value <= 3'b000;
      pendingSels <= 4'b0000;
      pendingError <= 1'b0;
      _zz_cmdAllowedStart <= 1'b1;
    end else begin
      pendingCmdCounter_value <= pendingCmdCounter_valueNext;
      pendingDataCounter_value <= pendingDataCounter_valueNext;
      if(cmdAllowedStart) begin
        pendingSels <= decodedCmdSels;
      end
      if(cmdAllowedStart) begin
        pendingError <= decodedCmdError;
      end
      if(cmdAllowedStart) begin
        _zz_cmdAllowedStart <= 1'b0;
      end
      if(io_input_aw_ready) begin
        _zz_cmdAllowedStart <= 1'b1;
      end
    end
  end


endmodule

module Axi4ReadOnlyDecoder_1 (
  input  wire          io_input_ar_valid,
  output wire          io_input_ar_ready,
  input  wire [31:0]   io_input_ar_payload_addr,
  input  wire [3:0]    io_input_ar_payload_id,
  input  wire [7:0]    io_input_ar_payload_len,
  input  wire [2:0]    io_input_ar_payload_size,
  input  wire [1:0]    io_input_ar_payload_burst,
  input  wire [0:0]    io_input_ar_payload_lock,
  input  wire [3:0]    io_input_ar_payload_cache,
  input  wire [2:0]    io_input_ar_payload_prot,
  output reg           io_input_r_valid,
  input  wire          io_input_r_ready,
  output wire [31:0]   io_input_r_payload_data,
  output reg  [3:0]    io_input_r_payload_id,
  output reg  [1:0]    io_input_r_payload_resp,
  output reg           io_input_r_payload_last,
  output wire          io_outputs_0_ar_valid,
  input  wire          io_outputs_0_ar_ready,
  output wire [31:0]   io_outputs_0_ar_payload_addr,
  output wire [3:0]    io_outputs_0_ar_payload_id,
  output wire [7:0]    io_outputs_0_ar_payload_len,
  output wire [2:0]    io_outputs_0_ar_payload_size,
  output wire [1:0]    io_outputs_0_ar_payload_burst,
  output wire [0:0]    io_outputs_0_ar_payload_lock,
  output wire [3:0]    io_outputs_0_ar_payload_cache,
  output wire [2:0]    io_outputs_0_ar_payload_prot,
  input  wire          io_outputs_0_r_valid,
  output wire          io_outputs_0_r_ready,
  input  wire [31:0]   io_outputs_0_r_payload_data,
  input  wire [3:0]    io_outputs_0_r_payload_id,
  input  wire [1:0]    io_outputs_0_r_payload_resp,
  input  wire          io_outputs_0_r_payload_last,
  output wire          io_outputs_1_ar_valid,
  input  wire          io_outputs_1_ar_ready,
  output wire [31:0]   io_outputs_1_ar_payload_addr,
  output wire [3:0]    io_outputs_1_ar_payload_id,
  output wire [7:0]    io_outputs_1_ar_payload_len,
  output wire [2:0]    io_outputs_1_ar_payload_size,
  output wire [1:0]    io_outputs_1_ar_payload_burst,
  output wire [0:0]    io_outputs_1_ar_payload_lock,
  output wire [3:0]    io_outputs_1_ar_payload_cache,
  output wire [2:0]    io_outputs_1_ar_payload_prot,
  input  wire          io_outputs_1_r_valid,
  output wire          io_outputs_1_r_ready,
  input  wire [31:0]   io_outputs_1_r_payload_data,
  input  wire [3:0]    io_outputs_1_r_payload_id,
  input  wire [1:0]    io_outputs_1_r_payload_resp,
  input  wire          io_outputs_1_r_payload_last,
  output wire          io_outputs_2_ar_valid,
  input  wire          io_outputs_2_ar_ready,
  output wire [31:0]   io_outputs_2_ar_payload_addr,
  output wire [3:0]    io_outputs_2_ar_payload_id,
  output wire [7:0]    io_outputs_2_ar_payload_len,
  output wire [2:0]    io_outputs_2_ar_payload_size,
  output wire [1:0]    io_outputs_2_ar_payload_burst,
  output wire [0:0]    io_outputs_2_ar_payload_lock,
  output wire [3:0]    io_outputs_2_ar_payload_cache,
  output wire [2:0]    io_outputs_2_ar_payload_prot,
  input  wire          io_outputs_2_r_valid,
  output wire          io_outputs_2_r_ready,
  input  wire [31:0]   io_outputs_2_r_payload_data,
  input  wire [3:0]    io_outputs_2_r_payload_id,
  input  wire [1:0]    io_outputs_2_r_payload_resp,
  input  wire          io_outputs_2_r_payload_last,
  output wire          io_outputs_3_ar_valid,
  input  wire          io_outputs_3_ar_ready,
  output wire [31:0]   io_outputs_3_ar_payload_addr,
  output wire [3:0]    io_outputs_3_ar_payload_id,
  output wire [7:0]    io_outputs_3_ar_payload_len,
  output wire [2:0]    io_outputs_3_ar_payload_size,
  output wire [1:0]    io_outputs_3_ar_payload_burst,
  output wire [0:0]    io_outputs_3_ar_payload_lock,
  output wire [3:0]    io_outputs_3_ar_payload_cache,
  output wire [2:0]    io_outputs_3_ar_payload_prot,
  input  wire          io_outputs_3_r_valid,
  output wire          io_outputs_3_r_ready,
  input  wire [31:0]   io_outputs_3_r_payload_data,
  input  wire [3:0]    io_outputs_3_r_payload_id,
  input  wire [1:0]    io_outputs_3_r_payload_resp,
  input  wire          io_outputs_3_r_payload_last,
  input  wire          clk,
  input  wire          resetn
);

  wire                errorSlave_io_axi_ar_valid;
  wire                errorSlave_io_axi_ar_ready;
  wire                errorSlave_io_axi_r_valid;
  wire       [31:0]   errorSlave_io_axi_r_payload_data;
  wire       [3:0]    errorSlave_io_axi_r_payload_id;
  wire       [1:0]    errorSlave_io_axi_r_payload_resp;
  wire                errorSlave_io_axi_r_payload_last;
  wire       [31:0]   _zz_decodedCmdSels;
  wire       [31:0]   _zz_decodedCmdSels_1;
  wire       [31:0]   _zz_decodedCmdSels_2;
  wire       [31:0]   _zz_decodedCmdSels_3;
  wire       [31:0]   _zz_decodedCmdSels_4;
  wire       [31:0]   _zz_decodedCmdSels_5;
  reg        [31:0]   _zz_io_input_r_payload_data;
  reg        [3:0]    _zz_io_input_r_payload_id;
  reg        [1:0]    _zz_io_input_r_payload_resp;
  reg                 _zz_io_input_r_payload_last;
  wire                io_input_ar_fire;
  wire                io_input_r_fire;
  wire                when_Utils_l697;
  reg                 pendingCmdCounter_incrementIt;
  reg                 pendingCmdCounter_decrementIt;
  wire       [2:0]    pendingCmdCounter_valueNext;
  reg        [2:0]    pendingCmdCounter_value;
  wire                pendingCmdCounter_mayOverflow;
  wire                pendingCmdCounter_willOverflowIfInc;
  wire                pendingCmdCounter_willOverflow;
  reg        [2:0]    pendingCmdCounter_finalIncrement;
  wire                when_Utils_l723;
  wire                when_Utils_l725;
  wire       [3:0]    decodedCmdSels;
  wire                decodedCmdError;
  reg        [3:0]    pendingSels;
  reg                 pendingError;
  wire                allowCmd;
  wire                _zz_readRspIndex;
  wire                _zz_readRspIndex_1;
  wire                _zz_readRspIndex_2;
  wire       [1:0]    readRspIndex;

  assign _zz_decodedCmdSels = 32'h000fffff;
  assign _zz_decodedCmdSels_1 = (~ 32'h000fffff);
  assign _zz_decodedCmdSels_2 = (io_input_ar_payload_addr & (~ 32'h007fffff));
  assign _zz_decodedCmdSels_3 = 32'h00000000;
  assign _zz_decodedCmdSels_4 = (io_input_ar_payload_addr & (~ 32'h007fffff));
  assign _zz_decodedCmdSels_5 = 32'h1c000000;
  Axi4ReadOnlyErrorSlave_1 errorSlave (
    .io_axi_ar_valid         (errorSlave_io_axi_ar_valid            ), //i
    .io_axi_ar_ready         (errorSlave_io_axi_ar_ready            ), //o
    .io_axi_ar_payload_addr  (io_input_ar_payload_addr[31:0]        ), //i
    .io_axi_ar_payload_id    (io_input_ar_payload_id[3:0]           ), //i
    .io_axi_ar_payload_len   (io_input_ar_payload_len[7:0]          ), //i
    .io_axi_ar_payload_size  (io_input_ar_payload_size[2:0]         ), //i
    .io_axi_ar_payload_burst (io_input_ar_payload_burst[1:0]        ), //i
    .io_axi_ar_payload_lock  (io_input_ar_payload_lock              ), //i
    .io_axi_ar_payload_cache (io_input_ar_payload_cache[3:0]        ), //i
    .io_axi_ar_payload_prot  (io_input_ar_payload_prot[2:0]         ), //i
    .io_axi_r_valid          (errorSlave_io_axi_r_valid             ), //o
    .io_axi_r_ready          (io_input_r_ready                      ), //i
    .io_axi_r_payload_data   (errorSlave_io_axi_r_payload_data[31:0]), //o
    .io_axi_r_payload_id     (errorSlave_io_axi_r_payload_id[3:0]   ), //o
    .io_axi_r_payload_resp   (errorSlave_io_axi_r_payload_resp[1:0] ), //o
    .io_axi_r_payload_last   (errorSlave_io_axi_r_payload_last      ), //o
    .clk                     (clk                                   ), //i
    .resetn                  (resetn                                )  //i
  );
  always @(*) begin
    case(readRspIndex)
      2'b00 : begin
        _zz_io_input_r_payload_data = io_outputs_0_r_payload_data;
        _zz_io_input_r_payload_id = io_outputs_0_r_payload_id;
        _zz_io_input_r_payload_resp = io_outputs_0_r_payload_resp;
        _zz_io_input_r_payload_last = io_outputs_0_r_payload_last;
      end
      2'b01 : begin
        _zz_io_input_r_payload_data = io_outputs_1_r_payload_data;
        _zz_io_input_r_payload_id = io_outputs_1_r_payload_id;
        _zz_io_input_r_payload_resp = io_outputs_1_r_payload_resp;
        _zz_io_input_r_payload_last = io_outputs_1_r_payload_last;
      end
      2'b10 : begin
        _zz_io_input_r_payload_data = io_outputs_2_r_payload_data;
        _zz_io_input_r_payload_id = io_outputs_2_r_payload_id;
        _zz_io_input_r_payload_resp = io_outputs_2_r_payload_resp;
        _zz_io_input_r_payload_last = io_outputs_2_r_payload_last;
      end
      default : begin
        _zz_io_input_r_payload_data = io_outputs_3_r_payload_data;
        _zz_io_input_r_payload_id = io_outputs_3_r_payload_id;
        _zz_io_input_r_payload_resp = io_outputs_3_r_payload_resp;
        _zz_io_input_r_payload_last = io_outputs_3_r_payload_last;
      end
    endcase
  end

  assign io_input_ar_fire = (io_input_ar_valid && io_input_ar_ready);
  assign io_input_r_fire = (io_input_r_valid && io_input_r_ready);
  assign when_Utils_l697 = (io_input_r_fire && io_input_r_payload_last);
  always @(*) begin
    pendingCmdCounter_incrementIt = 1'b0;
    if(io_input_ar_fire) begin
      pendingCmdCounter_incrementIt = 1'b1;
    end
  end

  always @(*) begin
    pendingCmdCounter_decrementIt = 1'b0;
    if(when_Utils_l697) begin
      pendingCmdCounter_decrementIt = 1'b1;
    end
  end

  assign pendingCmdCounter_mayOverflow = (pendingCmdCounter_value == 3'b111);
  assign pendingCmdCounter_willOverflowIfInc = (pendingCmdCounter_mayOverflow && (! pendingCmdCounter_decrementIt));
  assign pendingCmdCounter_willOverflow = (pendingCmdCounter_willOverflowIfInc && pendingCmdCounter_incrementIt);
  assign when_Utils_l723 = (pendingCmdCounter_incrementIt && (! pendingCmdCounter_decrementIt));
  always @(*) begin
    if(when_Utils_l723) begin
      pendingCmdCounter_finalIncrement = 3'b001;
    end else begin
      if(when_Utils_l725) begin
        pendingCmdCounter_finalIncrement = 3'b111;
      end else begin
        pendingCmdCounter_finalIncrement = 3'b000;
      end
    end
  end

  assign when_Utils_l725 = ((! pendingCmdCounter_incrementIt) && pendingCmdCounter_decrementIt);
  assign pendingCmdCounter_valueNext = (pendingCmdCounter_value + pendingCmdCounter_finalIncrement);
  assign decodedCmdSels = {(((io_input_ar_payload_addr & (~ _zz_decodedCmdSels)) == 32'h1f500000) && io_input_ar_valid),{(((io_input_ar_payload_addr & _zz_decodedCmdSels_1) == 32'h1f400000) && io_input_ar_valid),{((_zz_decodedCmdSels_2 == _zz_decodedCmdSels_3) && io_input_ar_valid),((_zz_decodedCmdSels_4 == _zz_decodedCmdSels_5) && io_input_ar_valid)}}};
  assign decodedCmdError = (decodedCmdSels == 4'b0000);
  assign allowCmd = ((pendingCmdCounter_value == 3'b000) || ((pendingCmdCounter_value != 3'b111) && (pendingSels == decodedCmdSels)));
  assign io_input_ar_ready = (((|(decodedCmdSels & {io_outputs_3_ar_ready,{io_outputs_2_ar_ready,{io_outputs_1_ar_ready,io_outputs_0_ar_ready}}})) || (decodedCmdError && errorSlave_io_axi_ar_ready)) && allowCmd);
  assign errorSlave_io_axi_ar_valid = ((io_input_ar_valid && decodedCmdError) && allowCmd);
  assign io_outputs_0_ar_valid = ((io_input_ar_valid && decodedCmdSels[0]) && allowCmd);
  assign io_outputs_0_ar_payload_addr = io_input_ar_payload_addr;
  assign io_outputs_0_ar_payload_id = io_input_ar_payload_id;
  assign io_outputs_0_ar_payload_len = io_input_ar_payload_len;
  assign io_outputs_0_ar_payload_size = io_input_ar_payload_size;
  assign io_outputs_0_ar_payload_burst = io_input_ar_payload_burst;
  assign io_outputs_0_ar_payload_lock = io_input_ar_payload_lock;
  assign io_outputs_0_ar_payload_cache = io_input_ar_payload_cache;
  assign io_outputs_0_ar_payload_prot = io_input_ar_payload_prot;
  assign io_outputs_1_ar_valid = ((io_input_ar_valid && decodedCmdSels[1]) && allowCmd);
  assign io_outputs_1_ar_payload_addr = io_input_ar_payload_addr;
  assign io_outputs_1_ar_payload_id = io_input_ar_payload_id;
  assign io_outputs_1_ar_payload_len = io_input_ar_payload_len;
  assign io_outputs_1_ar_payload_size = io_input_ar_payload_size;
  assign io_outputs_1_ar_payload_burst = io_input_ar_payload_burst;
  assign io_outputs_1_ar_payload_lock = io_input_ar_payload_lock;
  assign io_outputs_1_ar_payload_cache = io_input_ar_payload_cache;
  assign io_outputs_1_ar_payload_prot = io_input_ar_payload_prot;
  assign io_outputs_2_ar_valid = ((io_input_ar_valid && decodedCmdSels[2]) && allowCmd);
  assign io_outputs_2_ar_payload_addr = io_input_ar_payload_addr;
  assign io_outputs_2_ar_payload_id = io_input_ar_payload_id;
  assign io_outputs_2_ar_payload_len = io_input_ar_payload_len;
  assign io_outputs_2_ar_payload_size = io_input_ar_payload_size;
  assign io_outputs_2_ar_payload_burst = io_input_ar_payload_burst;
  assign io_outputs_2_ar_payload_lock = io_input_ar_payload_lock;
  assign io_outputs_2_ar_payload_cache = io_input_ar_payload_cache;
  assign io_outputs_2_ar_payload_prot = io_input_ar_payload_prot;
  assign io_outputs_3_ar_valid = ((io_input_ar_valid && decodedCmdSels[3]) && allowCmd);
  assign io_outputs_3_ar_payload_addr = io_input_ar_payload_addr;
  assign io_outputs_3_ar_payload_id = io_input_ar_payload_id;
  assign io_outputs_3_ar_payload_len = io_input_ar_payload_len;
  assign io_outputs_3_ar_payload_size = io_input_ar_payload_size;
  assign io_outputs_3_ar_payload_burst = io_input_ar_payload_burst;
  assign io_outputs_3_ar_payload_lock = io_input_ar_payload_lock;
  assign io_outputs_3_ar_payload_cache = io_input_ar_payload_cache;
  assign io_outputs_3_ar_payload_prot = io_input_ar_payload_prot;
  assign _zz_readRspIndex = pendingSels[3];
  assign _zz_readRspIndex_1 = (pendingSels[1] || _zz_readRspIndex);
  assign _zz_readRspIndex_2 = (pendingSels[2] || _zz_readRspIndex);
  assign readRspIndex = {_zz_readRspIndex_2,_zz_readRspIndex_1};
  always @(*) begin
    io_input_r_valid = (|{io_outputs_3_r_valid,{io_outputs_2_r_valid,{io_outputs_1_r_valid,io_outputs_0_r_valid}}});
    if(errorSlave_io_axi_r_valid) begin
      io_input_r_valid = 1'b1;
    end
  end

  assign io_input_r_payload_data = _zz_io_input_r_payload_data;
  always @(*) begin
    io_input_r_payload_id = _zz_io_input_r_payload_id;
    if(pendingError) begin
      io_input_r_payload_id = errorSlave_io_axi_r_payload_id;
    end
  end

  always @(*) begin
    io_input_r_payload_resp = _zz_io_input_r_payload_resp;
    if(pendingError) begin
      io_input_r_payload_resp = errorSlave_io_axi_r_payload_resp;
    end
  end

  always @(*) begin
    io_input_r_payload_last = _zz_io_input_r_payload_last;
    if(pendingError) begin
      io_input_r_payload_last = errorSlave_io_axi_r_payload_last;
    end
  end

  assign io_outputs_0_r_ready = io_input_r_ready;
  assign io_outputs_1_r_ready = io_input_r_ready;
  assign io_outputs_2_r_ready = io_input_r_ready;
  assign io_outputs_3_r_ready = io_input_r_ready;
  always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      pendingCmdCounter_value <= 3'b000;
      pendingSels <= 4'b0000;
      pendingError <= 1'b0;
    end else begin
      pendingCmdCounter_value <= pendingCmdCounter_valueNext;
      if(io_input_ar_ready) begin
        pendingSels <= decodedCmdSels;
      end
      if(io_input_ar_ready) begin
        pendingError <= decodedCmdError;
      end
    end
  end


endmodule

module Axi4WriteOnlyDecoder (
  input  wire          io_input_aw_valid,
  output wire          io_input_aw_ready,
  input  wire [31:0]   io_input_aw_payload_addr,
  input  wire [3:0]    io_input_aw_payload_id,
  input  wire [7:0]    io_input_aw_payload_len,
  input  wire [2:0]    io_input_aw_payload_size,
  input  wire [1:0]    io_input_aw_payload_burst,
  input  wire [0:0]    io_input_aw_payload_lock,
  input  wire [3:0]    io_input_aw_payload_cache,
  input  wire [2:0]    io_input_aw_payload_prot,
  input  wire          io_input_w_valid,
  output wire          io_input_w_ready,
  input  wire [31:0]   io_input_w_payload_data,
  input  wire [3:0]    io_input_w_payload_strb,
  input  wire          io_input_w_payload_last,
  output wire          io_input_b_valid,
  input  wire          io_input_b_ready,
  output reg  [3:0]    io_input_b_payload_id,
  output reg  [1:0]    io_input_b_payload_resp,
  output wire          io_outputs_0_aw_valid,
  input  wire          io_outputs_0_aw_ready,
  output wire [31:0]   io_outputs_0_aw_payload_addr,
  output wire [3:0]    io_outputs_0_aw_payload_id,
  output wire [7:0]    io_outputs_0_aw_payload_len,
  output wire [2:0]    io_outputs_0_aw_payload_size,
  output wire [1:0]    io_outputs_0_aw_payload_burst,
  output wire [0:0]    io_outputs_0_aw_payload_lock,
  output wire [3:0]    io_outputs_0_aw_payload_cache,
  output wire [2:0]    io_outputs_0_aw_payload_prot,
  output wire          io_outputs_0_w_valid,
  input  wire          io_outputs_0_w_ready,
  output wire [31:0]   io_outputs_0_w_payload_data,
  output wire [3:0]    io_outputs_0_w_payload_strb,
  output wire          io_outputs_0_w_payload_last,
  input  wire          io_outputs_0_b_valid,
  output wire          io_outputs_0_b_ready,
  input  wire [3:0]    io_outputs_0_b_payload_id,
  input  wire [1:0]    io_outputs_0_b_payload_resp,
  output wire          io_outputs_1_aw_valid,
  input  wire          io_outputs_1_aw_ready,
  output wire [31:0]   io_outputs_1_aw_payload_addr,
  output wire [3:0]    io_outputs_1_aw_payload_id,
  output wire [7:0]    io_outputs_1_aw_payload_len,
  output wire [2:0]    io_outputs_1_aw_payload_size,
  output wire [1:0]    io_outputs_1_aw_payload_burst,
  output wire [0:0]    io_outputs_1_aw_payload_lock,
  output wire [3:0]    io_outputs_1_aw_payload_cache,
  output wire [2:0]    io_outputs_1_aw_payload_prot,
  output wire          io_outputs_1_w_valid,
  input  wire          io_outputs_1_w_ready,
  output wire [31:0]   io_outputs_1_w_payload_data,
  output wire [3:0]    io_outputs_1_w_payload_strb,
  output wire          io_outputs_1_w_payload_last,
  input  wire          io_outputs_1_b_valid,
  output wire          io_outputs_1_b_ready,
  input  wire [3:0]    io_outputs_1_b_payload_id,
  input  wire [1:0]    io_outputs_1_b_payload_resp,
  output wire          io_outputs_2_aw_valid,
  input  wire          io_outputs_2_aw_ready,
  output wire [31:0]   io_outputs_2_aw_payload_addr,
  output wire [3:0]    io_outputs_2_aw_payload_id,
  output wire [7:0]    io_outputs_2_aw_payload_len,
  output wire [2:0]    io_outputs_2_aw_payload_size,
  output wire [1:0]    io_outputs_2_aw_payload_burst,
  output wire [0:0]    io_outputs_2_aw_payload_lock,
  output wire [3:0]    io_outputs_2_aw_payload_cache,
  output wire [2:0]    io_outputs_2_aw_payload_prot,
  output wire          io_outputs_2_w_valid,
  input  wire          io_outputs_2_w_ready,
  output wire [31:0]   io_outputs_2_w_payload_data,
  output wire [3:0]    io_outputs_2_w_payload_strb,
  output wire          io_outputs_2_w_payload_last,
  input  wire          io_outputs_2_b_valid,
  output wire          io_outputs_2_b_ready,
  input  wire [3:0]    io_outputs_2_b_payload_id,
  input  wire [1:0]    io_outputs_2_b_payload_resp,
  output wire          io_outputs_3_aw_valid,
  input  wire          io_outputs_3_aw_ready,
  output wire [31:0]   io_outputs_3_aw_payload_addr,
  output wire [3:0]    io_outputs_3_aw_payload_id,
  output wire [7:0]    io_outputs_3_aw_payload_len,
  output wire [2:0]    io_outputs_3_aw_payload_size,
  output wire [1:0]    io_outputs_3_aw_payload_burst,
  output wire [0:0]    io_outputs_3_aw_payload_lock,
  output wire [3:0]    io_outputs_3_aw_payload_cache,
  output wire [2:0]    io_outputs_3_aw_payload_prot,
  output wire          io_outputs_3_w_valid,
  input  wire          io_outputs_3_w_ready,
  output wire [31:0]   io_outputs_3_w_payload_data,
  output wire [3:0]    io_outputs_3_w_payload_strb,
  output wire          io_outputs_3_w_payload_last,
  input  wire          io_outputs_3_b_valid,
  output wire          io_outputs_3_b_ready,
  input  wire [3:0]    io_outputs_3_b_payload_id,
  input  wire [1:0]    io_outputs_3_b_payload_resp,
  output wire          io_outputs_4_aw_valid,
  input  wire          io_outputs_4_aw_ready,
  output wire [31:0]   io_outputs_4_aw_payload_addr,
  output wire [3:0]    io_outputs_4_aw_payload_id,
  output wire [7:0]    io_outputs_4_aw_payload_len,
  output wire [2:0]    io_outputs_4_aw_payload_size,
  output wire [1:0]    io_outputs_4_aw_payload_burst,
  output wire [0:0]    io_outputs_4_aw_payload_lock,
  output wire [3:0]    io_outputs_4_aw_payload_cache,
  output wire [2:0]    io_outputs_4_aw_payload_prot,
  output wire          io_outputs_4_w_valid,
  input  wire          io_outputs_4_w_ready,
  output wire [31:0]   io_outputs_4_w_payload_data,
  output wire [3:0]    io_outputs_4_w_payload_strb,
  output wire          io_outputs_4_w_payload_last,
  input  wire          io_outputs_4_b_valid,
  output wire          io_outputs_4_b_ready,
  input  wire [3:0]    io_outputs_4_b_payload_id,
  input  wire [1:0]    io_outputs_4_b_payload_resp,
  output wire          io_outputs_5_aw_valid,
  input  wire          io_outputs_5_aw_ready,
  output wire [31:0]   io_outputs_5_aw_payload_addr,
  output wire [3:0]    io_outputs_5_aw_payload_id,
  output wire [7:0]    io_outputs_5_aw_payload_len,
  output wire [2:0]    io_outputs_5_aw_payload_size,
  output wire [1:0]    io_outputs_5_aw_payload_burst,
  output wire [0:0]    io_outputs_5_aw_payload_lock,
  output wire [3:0]    io_outputs_5_aw_payload_cache,
  output wire [2:0]    io_outputs_5_aw_payload_prot,
  output wire          io_outputs_5_w_valid,
  input  wire          io_outputs_5_w_ready,
  output wire [31:0]   io_outputs_5_w_payload_data,
  output wire [3:0]    io_outputs_5_w_payload_strb,
  output wire          io_outputs_5_w_payload_last,
  input  wire          io_outputs_5_b_valid,
  output wire          io_outputs_5_b_ready,
  input  wire [3:0]    io_outputs_5_b_payload_id,
  input  wire [1:0]    io_outputs_5_b_payload_resp,
  output wire          io_outputs_6_aw_valid,
  input  wire          io_outputs_6_aw_ready,
  output wire [31:0]   io_outputs_6_aw_payload_addr,
  output wire [3:0]    io_outputs_6_aw_payload_id,
  output wire [7:0]    io_outputs_6_aw_payload_len,
  output wire [2:0]    io_outputs_6_aw_payload_size,
  output wire [1:0]    io_outputs_6_aw_payload_burst,
  output wire [0:0]    io_outputs_6_aw_payload_lock,
  output wire [3:0]    io_outputs_6_aw_payload_cache,
  output wire [2:0]    io_outputs_6_aw_payload_prot,
  output wire          io_outputs_6_w_valid,
  input  wire          io_outputs_6_w_ready,
  output wire [31:0]   io_outputs_6_w_payload_data,
  output wire [3:0]    io_outputs_6_w_payload_strb,
  output wire          io_outputs_6_w_payload_last,
  input  wire          io_outputs_6_b_valid,
  output wire          io_outputs_6_b_ready,
  input  wire [3:0]    io_outputs_6_b_payload_id,
  input  wire [1:0]    io_outputs_6_b_payload_resp,
  output wire          io_outputs_7_aw_valid,
  input  wire          io_outputs_7_aw_ready,
  output wire [31:0]   io_outputs_7_aw_payload_addr,
  output wire [3:0]    io_outputs_7_aw_payload_id,
  output wire [7:0]    io_outputs_7_aw_payload_len,
  output wire [2:0]    io_outputs_7_aw_payload_size,
  output wire [1:0]    io_outputs_7_aw_payload_burst,
  output wire [0:0]    io_outputs_7_aw_payload_lock,
  output wire [3:0]    io_outputs_7_aw_payload_cache,
  output wire [2:0]    io_outputs_7_aw_payload_prot,
  output wire          io_outputs_7_w_valid,
  input  wire          io_outputs_7_w_ready,
  output wire [31:0]   io_outputs_7_w_payload_data,
  output wire [3:0]    io_outputs_7_w_payload_strb,
  output wire          io_outputs_7_w_payload_last,
  input  wire          io_outputs_7_b_valid,
  output wire          io_outputs_7_b_ready,
  input  wire [3:0]    io_outputs_7_b_payload_id,
  input  wire [1:0]    io_outputs_7_b_payload_resp,
  input  wire          clk,
  input  wire          resetn
);

  wire                errorSlave_io_axi_aw_valid;
  wire                errorSlave_io_axi_w_valid;
  wire                errorSlave_io_axi_aw_ready;
  wire                errorSlave_io_axi_w_ready;
  wire                errorSlave_io_axi_b_valid;
  wire       [3:0]    errorSlave_io_axi_b_payload_id;
  wire       [1:0]    errorSlave_io_axi_b_payload_resp;
  wire       [31:0]   _zz_decodedCmdSels;
  wire       [31:0]   _zz_decodedCmdSels_1;
  wire       [31:0]   _zz_decodedCmdSels_2;
  wire       [31:0]   _zz_decodedCmdSels_3;
  wire                _zz_decodedCmdSels_4;
  wire                _zz_decodedCmdSels_5;
  wire       [0:0]    _zz_decodedCmdSels_6;
  wire       [1:0]    _zz_decodedCmdSels_7;
  wire       [31:0]   _zz_decodedCmdSels_8;
  wire       [31:0]   _zz_decodedCmdSels_9;
  reg        [3:0]    _zz_io_input_b_payload_id;
  reg        [1:0]    _zz_io_input_b_payload_resp;
  wire                cmdAllowedStart;
  wire                io_input_aw_fire;
  wire                io_input_b_fire;
  reg                 pendingCmdCounter_incrementIt;
  reg                 pendingCmdCounter_decrementIt;
  wire       [2:0]    pendingCmdCounter_valueNext;
  reg        [2:0]    pendingCmdCounter_value;
  wire                pendingCmdCounter_mayOverflow;
  wire                pendingCmdCounter_willOverflowIfInc;
  wire                pendingCmdCounter_willOverflow;
  reg        [2:0]    pendingCmdCounter_finalIncrement;
  wire                when_Utils_l723;
  wire                when_Utils_l725;
  wire                io_input_w_fire;
  wire                when_Utils_l697;
  reg                 pendingDataCounter_incrementIt;
  reg                 pendingDataCounter_decrementIt;
  wire       [2:0]    pendingDataCounter_valueNext;
  reg        [2:0]    pendingDataCounter_value;
  wire                pendingDataCounter_mayOverflow;
  wire                pendingDataCounter_willOverflowIfInc;
  wire                pendingDataCounter_willOverflow;
  reg        [2:0]    pendingDataCounter_finalIncrement;
  wire                when_Utils_l723_1;
  wire                when_Utils_l725_1;
  wire       [7:0]    decodedCmdSels;
  wire                decodedCmdError;
  reg        [7:0]    pendingSels;
  reg                 pendingError;
  wire                allowCmd;
  wire                allowData;
  reg                 _zz_cmdAllowedStart;
  wire                _zz_io_outputs_1_w_valid;
  wire                _zz_io_outputs_2_w_valid;
  wire                _zz_io_outputs_3_w_valid;
  wire                _zz_io_outputs_4_w_valid;
  wire                _zz_io_outputs_5_w_valid;
  wire                _zz_io_outputs_6_w_valid;
  wire                _zz_io_outputs_7_w_valid;
  wire                _zz_writeRspIndex;
  wire                _zz_writeRspIndex_1;
  wire                _zz_writeRspIndex_2;
  wire       [2:0]    writeRspIndex;

  assign _zz_decodedCmdSels = 32'h000fffff;
  assign _zz_decodedCmdSels_1 = (~ 32'h000fffff);
  assign _zz_decodedCmdSels_2 = (io_input_aw_payload_addr & (~ 32'h000fffff));
  assign _zz_decodedCmdSels_3 = 32'h1f300000;
  assign _zz_decodedCmdSels_4 = ((io_input_aw_payload_addr & (~ 32'h000fffff)) == 32'h1f200000);
  assign _zz_decodedCmdSels_5 = (((io_input_aw_payload_addr & (~ 32'h000fffff)) == 32'h1f100000) && io_input_aw_valid);
  assign _zz_decodedCmdSels_6 = (((io_input_aw_payload_addr & (~ 32'h000fffff)) == 32'h1f000000) && io_input_aw_valid);
  assign _zz_decodedCmdSels_7 = {(((io_input_aw_payload_addr & (~ _zz_decodedCmdSels_8)) == 32'h00000000) && io_input_aw_valid),(((io_input_aw_payload_addr & (~ _zz_decodedCmdSels_9)) == 32'h1c000000) && io_input_aw_valid)};
  assign _zz_decodedCmdSels_8 = 32'h007fffff;
  assign _zz_decodedCmdSels_9 = 32'h007fffff;
  Axi4WriteOnlyErrorSlave_1 errorSlave (
    .io_axi_aw_valid         (errorSlave_io_axi_aw_valid           ), //i
    .io_axi_aw_ready         (errorSlave_io_axi_aw_ready           ), //o
    .io_axi_aw_payload_addr  (io_input_aw_payload_addr[31:0]       ), //i
    .io_axi_aw_payload_id    (io_input_aw_payload_id[3:0]          ), //i
    .io_axi_aw_payload_len   (io_input_aw_payload_len[7:0]         ), //i
    .io_axi_aw_payload_size  (io_input_aw_payload_size[2:0]        ), //i
    .io_axi_aw_payload_burst (io_input_aw_payload_burst[1:0]       ), //i
    .io_axi_aw_payload_lock  (io_input_aw_payload_lock             ), //i
    .io_axi_aw_payload_cache (io_input_aw_payload_cache[3:0]       ), //i
    .io_axi_aw_payload_prot  (io_input_aw_payload_prot[2:0]        ), //i
    .io_axi_w_valid          (errorSlave_io_axi_w_valid            ), //i
    .io_axi_w_ready          (errorSlave_io_axi_w_ready            ), //o
    .io_axi_w_payload_data   (io_input_w_payload_data[31:0]        ), //i
    .io_axi_w_payload_strb   (io_input_w_payload_strb[3:0]         ), //i
    .io_axi_w_payload_last   (io_input_w_payload_last              ), //i
    .io_axi_b_valid          (errorSlave_io_axi_b_valid            ), //o
    .io_axi_b_ready          (io_input_b_ready                     ), //i
    .io_axi_b_payload_id     (errorSlave_io_axi_b_payload_id[3:0]  ), //o
    .io_axi_b_payload_resp   (errorSlave_io_axi_b_payload_resp[1:0]), //o
    .clk                     (clk                                  ), //i
    .resetn                  (resetn                               )  //i
  );
  always @(*) begin
    case(writeRspIndex)
      3'b000 : begin
        _zz_io_input_b_payload_id = io_outputs_0_b_payload_id;
        _zz_io_input_b_payload_resp = io_outputs_0_b_payload_resp;
      end
      3'b001 : begin
        _zz_io_input_b_payload_id = io_outputs_1_b_payload_id;
        _zz_io_input_b_payload_resp = io_outputs_1_b_payload_resp;
      end
      3'b010 : begin
        _zz_io_input_b_payload_id = io_outputs_2_b_payload_id;
        _zz_io_input_b_payload_resp = io_outputs_2_b_payload_resp;
      end
      3'b011 : begin
        _zz_io_input_b_payload_id = io_outputs_3_b_payload_id;
        _zz_io_input_b_payload_resp = io_outputs_3_b_payload_resp;
      end
      3'b100 : begin
        _zz_io_input_b_payload_id = io_outputs_4_b_payload_id;
        _zz_io_input_b_payload_resp = io_outputs_4_b_payload_resp;
      end
      3'b101 : begin
        _zz_io_input_b_payload_id = io_outputs_5_b_payload_id;
        _zz_io_input_b_payload_resp = io_outputs_5_b_payload_resp;
      end
      3'b110 : begin
        _zz_io_input_b_payload_id = io_outputs_6_b_payload_id;
        _zz_io_input_b_payload_resp = io_outputs_6_b_payload_resp;
      end
      default : begin
        _zz_io_input_b_payload_id = io_outputs_7_b_payload_id;
        _zz_io_input_b_payload_resp = io_outputs_7_b_payload_resp;
      end
    endcase
  end

  assign io_input_aw_fire = (io_input_aw_valid && io_input_aw_ready);
  assign io_input_b_fire = (io_input_b_valid && io_input_b_ready);
  always @(*) begin
    pendingCmdCounter_incrementIt = 1'b0;
    if(io_input_aw_fire) begin
      pendingCmdCounter_incrementIt = 1'b1;
    end
  end

  always @(*) begin
    pendingCmdCounter_decrementIt = 1'b0;
    if(io_input_b_fire) begin
      pendingCmdCounter_decrementIt = 1'b1;
    end
  end

  assign pendingCmdCounter_mayOverflow = (pendingCmdCounter_value == 3'b111);
  assign pendingCmdCounter_willOverflowIfInc = (pendingCmdCounter_mayOverflow && (! pendingCmdCounter_decrementIt));
  assign pendingCmdCounter_willOverflow = (pendingCmdCounter_willOverflowIfInc && pendingCmdCounter_incrementIt);
  assign when_Utils_l723 = (pendingCmdCounter_incrementIt && (! pendingCmdCounter_decrementIt));
  always @(*) begin
    if(when_Utils_l723) begin
      pendingCmdCounter_finalIncrement = 3'b001;
    end else begin
      if(when_Utils_l725) begin
        pendingCmdCounter_finalIncrement = 3'b111;
      end else begin
        pendingCmdCounter_finalIncrement = 3'b000;
      end
    end
  end

  assign when_Utils_l725 = ((! pendingCmdCounter_incrementIt) && pendingCmdCounter_decrementIt);
  assign pendingCmdCounter_valueNext = (pendingCmdCounter_value + pendingCmdCounter_finalIncrement);
  assign io_input_w_fire = (io_input_w_valid && io_input_w_ready);
  assign when_Utils_l697 = (io_input_w_fire && io_input_w_payload_last);
  always @(*) begin
    pendingDataCounter_incrementIt = 1'b0;
    if(cmdAllowedStart) begin
      pendingDataCounter_incrementIt = 1'b1;
    end
  end

  always @(*) begin
    pendingDataCounter_decrementIt = 1'b0;
    if(when_Utils_l697) begin
      pendingDataCounter_decrementIt = 1'b1;
    end
  end

  assign pendingDataCounter_mayOverflow = (pendingDataCounter_value == 3'b111);
  assign pendingDataCounter_willOverflowIfInc = (pendingDataCounter_mayOverflow && (! pendingDataCounter_decrementIt));
  assign pendingDataCounter_willOverflow = (pendingDataCounter_willOverflowIfInc && pendingDataCounter_incrementIt);
  assign when_Utils_l723_1 = (pendingDataCounter_incrementIt && (! pendingDataCounter_decrementIt));
  always @(*) begin
    if(when_Utils_l723_1) begin
      pendingDataCounter_finalIncrement = 3'b001;
    end else begin
      if(when_Utils_l725_1) begin
        pendingDataCounter_finalIncrement = 3'b111;
      end else begin
        pendingDataCounter_finalIncrement = 3'b000;
      end
    end
  end

  assign when_Utils_l725_1 = ((! pendingDataCounter_incrementIt) && pendingDataCounter_decrementIt);
  assign pendingDataCounter_valueNext = (pendingDataCounter_value + pendingDataCounter_finalIncrement);
  assign decodedCmdSels = {(((io_input_aw_payload_addr & (~ _zz_decodedCmdSels)) == 32'h1f500000) && io_input_aw_valid),{(((io_input_aw_payload_addr & _zz_decodedCmdSels_1) == 32'h1f400000) && io_input_aw_valid),{((_zz_decodedCmdSels_2 == _zz_decodedCmdSels_3) && io_input_aw_valid),{(_zz_decodedCmdSels_4 && io_input_aw_valid),{_zz_decodedCmdSels_5,{_zz_decodedCmdSels_6,_zz_decodedCmdSels_7}}}}}};
  assign decodedCmdError = (decodedCmdSels == 8'h00);
  assign allowCmd = ((pendingCmdCounter_value == 3'b000) || ((pendingCmdCounter_value != 3'b111) && (pendingSels == decodedCmdSels)));
  assign allowData = (pendingDataCounter_value != 3'b000);
  assign cmdAllowedStart = ((io_input_aw_valid && allowCmd) && _zz_cmdAllowedStart);
  assign io_input_aw_ready = (((|(decodedCmdSels & {io_outputs_7_aw_ready,{io_outputs_6_aw_ready,{io_outputs_5_aw_ready,{io_outputs_4_aw_ready,{io_outputs_3_aw_ready,{io_outputs_2_aw_ready,{io_outputs_1_aw_ready,io_outputs_0_aw_ready}}}}}}})) || (decodedCmdError && errorSlave_io_axi_aw_ready)) && allowCmd);
  assign errorSlave_io_axi_aw_valid = ((io_input_aw_valid && decodedCmdError) && allowCmd);
  assign io_outputs_0_aw_valid = ((io_input_aw_valid && decodedCmdSels[0]) && allowCmd);
  assign io_outputs_0_aw_payload_addr = io_input_aw_payload_addr;
  assign io_outputs_0_aw_payload_id = io_input_aw_payload_id;
  assign io_outputs_0_aw_payload_len = io_input_aw_payload_len;
  assign io_outputs_0_aw_payload_size = io_input_aw_payload_size;
  assign io_outputs_0_aw_payload_burst = io_input_aw_payload_burst;
  assign io_outputs_0_aw_payload_lock = io_input_aw_payload_lock;
  assign io_outputs_0_aw_payload_cache = io_input_aw_payload_cache;
  assign io_outputs_0_aw_payload_prot = io_input_aw_payload_prot;
  assign io_outputs_1_aw_valid = ((io_input_aw_valid && decodedCmdSels[1]) && allowCmd);
  assign io_outputs_1_aw_payload_addr = io_input_aw_payload_addr;
  assign io_outputs_1_aw_payload_id = io_input_aw_payload_id;
  assign io_outputs_1_aw_payload_len = io_input_aw_payload_len;
  assign io_outputs_1_aw_payload_size = io_input_aw_payload_size;
  assign io_outputs_1_aw_payload_burst = io_input_aw_payload_burst;
  assign io_outputs_1_aw_payload_lock = io_input_aw_payload_lock;
  assign io_outputs_1_aw_payload_cache = io_input_aw_payload_cache;
  assign io_outputs_1_aw_payload_prot = io_input_aw_payload_prot;
  assign io_outputs_2_aw_valid = ((io_input_aw_valid && decodedCmdSels[2]) && allowCmd);
  assign io_outputs_2_aw_payload_addr = io_input_aw_payload_addr;
  assign io_outputs_2_aw_payload_id = io_input_aw_payload_id;
  assign io_outputs_2_aw_payload_len = io_input_aw_payload_len;
  assign io_outputs_2_aw_payload_size = io_input_aw_payload_size;
  assign io_outputs_2_aw_payload_burst = io_input_aw_payload_burst;
  assign io_outputs_2_aw_payload_lock = io_input_aw_payload_lock;
  assign io_outputs_2_aw_payload_cache = io_input_aw_payload_cache;
  assign io_outputs_2_aw_payload_prot = io_input_aw_payload_prot;
  assign io_outputs_3_aw_valid = ((io_input_aw_valid && decodedCmdSels[3]) && allowCmd);
  assign io_outputs_3_aw_payload_addr = io_input_aw_payload_addr;
  assign io_outputs_3_aw_payload_id = io_input_aw_payload_id;
  assign io_outputs_3_aw_payload_len = io_input_aw_payload_len;
  assign io_outputs_3_aw_payload_size = io_input_aw_payload_size;
  assign io_outputs_3_aw_payload_burst = io_input_aw_payload_burst;
  assign io_outputs_3_aw_payload_lock = io_input_aw_payload_lock;
  assign io_outputs_3_aw_payload_cache = io_input_aw_payload_cache;
  assign io_outputs_3_aw_payload_prot = io_input_aw_payload_prot;
  assign io_outputs_4_aw_valid = ((io_input_aw_valid && decodedCmdSels[4]) && allowCmd);
  assign io_outputs_4_aw_payload_addr = io_input_aw_payload_addr;
  assign io_outputs_4_aw_payload_id = io_input_aw_payload_id;
  assign io_outputs_4_aw_payload_len = io_input_aw_payload_len;
  assign io_outputs_4_aw_payload_size = io_input_aw_payload_size;
  assign io_outputs_4_aw_payload_burst = io_input_aw_payload_burst;
  assign io_outputs_4_aw_payload_lock = io_input_aw_payload_lock;
  assign io_outputs_4_aw_payload_cache = io_input_aw_payload_cache;
  assign io_outputs_4_aw_payload_prot = io_input_aw_payload_prot;
  assign io_outputs_5_aw_valid = ((io_input_aw_valid && decodedCmdSels[5]) && allowCmd);
  assign io_outputs_5_aw_payload_addr = io_input_aw_payload_addr;
  assign io_outputs_5_aw_payload_id = io_input_aw_payload_id;
  assign io_outputs_5_aw_payload_len = io_input_aw_payload_len;
  assign io_outputs_5_aw_payload_size = io_input_aw_payload_size;
  assign io_outputs_5_aw_payload_burst = io_input_aw_payload_burst;
  assign io_outputs_5_aw_payload_lock = io_input_aw_payload_lock;
  assign io_outputs_5_aw_payload_cache = io_input_aw_payload_cache;
  assign io_outputs_5_aw_payload_prot = io_input_aw_payload_prot;
  assign io_outputs_6_aw_valid = ((io_input_aw_valid && decodedCmdSels[6]) && allowCmd);
  assign io_outputs_6_aw_payload_addr = io_input_aw_payload_addr;
  assign io_outputs_6_aw_payload_id = io_input_aw_payload_id;
  assign io_outputs_6_aw_payload_len = io_input_aw_payload_len;
  assign io_outputs_6_aw_payload_size = io_input_aw_payload_size;
  assign io_outputs_6_aw_payload_burst = io_input_aw_payload_burst;
  assign io_outputs_6_aw_payload_lock = io_input_aw_payload_lock;
  assign io_outputs_6_aw_payload_cache = io_input_aw_payload_cache;
  assign io_outputs_6_aw_payload_prot = io_input_aw_payload_prot;
  assign io_outputs_7_aw_valid = ((io_input_aw_valid && decodedCmdSels[7]) && allowCmd);
  assign io_outputs_7_aw_payload_addr = io_input_aw_payload_addr;
  assign io_outputs_7_aw_payload_id = io_input_aw_payload_id;
  assign io_outputs_7_aw_payload_len = io_input_aw_payload_len;
  assign io_outputs_7_aw_payload_size = io_input_aw_payload_size;
  assign io_outputs_7_aw_payload_burst = io_input_aw_payload_burst;
  assign io_outputs_7_aw_payload_lock = io_input_aw_payload_lock;
  assign io_outputs_7_aw_payload_cache = io_input_aw_payload_cache;
  assign io_outputs_7_aw_payload_prot = io_input_aw_payload_prot;
  assign io_input_w_ready = (((|(pendingSels & {io_outputs_7_w_ready,{io_outputs_6_w_ready,{io_outputs_5_w_ready,{io_outputs_4_w_ready,{io_outputs_3_w_ready,{io_outputs_2_w_ready,{io_outputs_1_w_ready,io_outputs_0_w_ready}}}}}}})) || (pendingError && errorSlave_io_axi_w_ready)) && allowData);
  assign errorSlave_io_axi_w_valid = ((io_input_w_valid && pendingError) && allowData);
  assign _zz_io_outputs_1_w_valid = pendingSels[1];
  assign _zz_io_outputs_2_w_valid = pendingSels[2];
  assign _zz_io_outputs_3_w_valid = pendingSels[3];
  assign _zz_io_outputs_4_w_valid = pendingSels[4];
  assign _zz_io_outputs_5_w_valid = pendingSels[5];
  assign _zz_io_outputs_6_w_valid = pendingSels[6];
  assign _zz_io_outputs_7_w_valid = pendingSels[7];
  assign io_outputs_0_w_valid = ((io_input_w_valid && pendingSels[0]) && allowData);
  assign io_outputs_0_w_payload_data = io_input_w_payload_data;
  assign io_outputs_0_w_payload_strb = io_input_w_payload_strb;
  assign io_outputs_0_w_payload_last = io_input_w_payload_last;
  assign io_outputs_1_w_valid = ((io_input_w_valid && _zz_io_outputs_1_w_valid) && allowData);
  assign io_outputs_1_w_payload_data = io_input_w_payload_data;
  assign io_outputs_1_w_payload_strb = io_input_w_payload_strb;
  assign io_outputs_1_w_payload_last = io_input_w_payload_last;
  assign io_outputs_2_w_valid = ((io_input_w_valid && _zz_io_outputs_2_w_valid) && allowData);
  assign io_outputs_2_w_payload_data = io_input_w_payload_data;
  assign io_outputs_2_w_payload_strb = io_input_w_payload_strb;
  assign io_outputs_2_w_payload_last = io_input_w_payload_last;
  assign io_outputs_3_w_valid = ((io_input_w_valid && _zz_io_outputs_3_w_valid) && allowData);
  assign io_outputs_3_w_payload_data = io_input_w_payload_data;
  assign io_outputs_3_w_payload_strb = io_input_w_payload_strb;
  assign io_outputs_3_w_payload_last = io_input_w_payload_last;
  assign io_outputs_4_w_valid = ((io_input_w_valid && _zz_io_outputs_4_w_valid) && allowData);
  assign io_outputs_4_w_payload_data = io_input_w_payload_data;
  assign io_outputs_4_w_payload_strb = io_input_w_payload_strb;
  assign io_outputs_4_w_payload_last = io_input_w_payload_last;
  assign io_outputs_5_w_valid = ((io_input_w_valid && _zz_io_outputs_5_w_valid) && allowData);
  assign io_outputs_5_w_payload_data = io_input_w_payload_data;
  assign io_outputs_5_w_payload_strb = io_input_w_payload_strb;
  assign io_outputs_5_w_payload_last = io_input_w_payload_last;
  assign io_outputs_6_w_valid = ((io_input_w_valid && _zz_io_outputs_6_w_valid) && allowData);
  assign io_outputs_6_w_payload_data = io_input_w_payload_data;
  assign io_outputs_6_w_payload_strb = io_input_w_payload_strb;
  assign io_outputs_6_w_payload_last = io_input_w_payload_last;
  assign io_outputs_7_w_valid = ((io_input_w_valid && _zz_io_outputs_7_w_valid) && allowData);
  assign io_outputs_7_w_payload_data = io_input_w_payload_data;
  assign io_outputs_7_w_payload_strb = io_input_w_payload_strb;
  assign io_outputs_7_w_payload_last = io_input_w_payload_last;
  assign _zz_writeRspIndex = (((_zz_io_outputs_1_w_valid || _zz_io_outputs_3_w_valid) || _zz_io_outputs_5_w_valid) || _zz_io_outputs_7_w_valid);
  assign _zz_writeRspIndex_1 = (((_zz_io_outputs_2_w_valid || _zz_io_outputs_3_w_valid) || _zz_io_outputs_6_w_valid) || _zz_io_outputs_7_w_valid);
  assign _zz_writeRspIndex_2 = (((_zz_io_outputs_4_w_valid || _zz_io_outputs_5_w_valid) || _zz_io_outputs_6_w_valid) || _zz_io_outputs_7_w_valid);
  assign writeRspIndex = {_zz_writeRspIndex_2,{_zz_writeRspIndex_1,_zz_writeRspIndex}};
  assign io_input_b_valid = ((|{io_outputs_7_b_valid,{io_outputs_6_b_valid,{io_outputs_5_b_valid,{io_outputs_4_b_valid,{io_outputs_3_b_valid,{io_outputs_2_b_valid,{io_outputs_1_b_valid,io_outputs_0_b_valid}}}}}}}) || errorSlave_io_axi_b_valid);
  always @(*) begin
    io_input_b_payload_id = _zz_io_input_b_payload_id;
    if(pendingError) begin
      io_input_b_payload_id = errorSlave_io_axi_b_payload_id;
    end
  end

  always @(*) begin
    io_input_b_payload_resp = _zz_io_input_b_payload_resp;
    if(pendingError) begin
      io_input_b_payload_resp = errorSlave_io_axi_b_payload_resp;
    end
  end

  assign io_outputs_0_b_ready = io_input_b_ready;
  assign io_outputs_1_b_ready = io_input_b_ready;
  assign io_outputs_2_b_ready = io_input_b_ready;
  assign io_outputs_3_b_ready = io_input_b_ready;
  assign io_outputs_4_b_ready = io_input_b_ready;
  assign io_outputs_5_b_ready = io_input_b_ready;
  assign io_outputs_6_b_ready = io_input_b_ready;
  assign io_outputs_7_b_ready = io_input_b_ready;
  always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      pendingCmdCounter_value <= 3'b000;
      pendingDataCounter_value <= 3'b000;
      pendingSels <= 8'h00;
      pendingError <= 1'b0;
      _zz_cmdAllowedStart <= 1'b1;
    end else begin
      pendingCmdCounter_value <= pendingCmdCounter_valueNext;
      pendingDataCounter_value <= pendingDataCounter_valueNext;
      if(cmdAllowedStart) begin
        pendingSels <= decodedCmdSels;
      end
      if(cmdAllowedStart) begin
        pendingError <= decodedCmdError;
      end
      if(cmdAllowedStart) begin
        _zz_cmdAllowedStart <= 1'b0;
      end
      if(io_input_aw_ready) begin
        _zz_cmdAllowedStart <= 1'b1;
      end
    end
  end


endmodule

module Axi4ReadOnlyDecoder (
  input  wire          io_input_ar_valid,
  output wire          io_input_ar_ready,
  input  wire [31:0]   io_input_ar_payload_addr,
  input  wire [3:0]    io_input_ar_payload_id,
  input  wire [7:0]    io_input_ar_payload_len,
  input  wire [2:0]    io_input_ar_payload_size,
  input  wire [1:0]    io_input_ar_payload_burst,
  input  wire [0:0]    io_input_ar_payload_lock,
  input  wire [3:0]    io_input_ar_payload_cache,
  input  wire [2:0]    io_input_ar_payload_prot,
  output reg           io_input_r_valid,
  input  wire          io_input_r_ready,
  output wire [31:0]   io_input_r_payload_data,
  output reg  [3:0]    io_input_r_payload_id,
  output reg  [1:0]    io_input_r_payload_resp,
  output reg           io_input_r_payload_last,
  output wire          io_outputs_0_ar_valid,
  input  wire          io_outputs_0_ar_ready,
  output wire [31:0]   io_outputs_0_ar_payload_addr,
  output wire [3:0]    io_outputs_0_ar_payload_id,
  output wire [7:0]    io_outputs_0_ar_payload_len,
  output wire [2:0]    io_outputs_0_ar_payload_size,
  output wire [1:0]    io_outputs_0_ar_payload_burst,
  output wire [0:0]    io_outputs_0_ar_payload_lock,
  output wire [3:0]    io_outputs_0_ar_payload_cache,
  output wire [2:0]    io_outputs_0_ar_payload_prot,
  input  wire          io_outputs_0_r_valid,
  output wire          io_outputs_0_r_ready,
  input  wire [31:0]   io_outputs_0_r_payload_data,
  input  wire [3:0]    io_outputs_0_r_payload_id,
  input  wire [1:0]    io_outputs_0_r_payload_resp,
  input  wire          io_outputs_0_r_payload_last,
  output wire          io_outputs_1_ar_valid,
  input  wire          io_outputs_1_ar_ready,
  output wire [31:0]   io_outputs_1_ar_payload_addr,
  output wire [3:0]    io_outputs_1_ar_payload_id,
  output wire [7:0]    io_outputs_1_ar_payload_len,
  output wire [2:0]    io_outputs_1_ar_payload_size,
  output wire [1:0]    io_outputs_1_ar_payload_burst,
  output wire [0:0]    io_outputs_1_ar_payload_lock,
  output wire [3:0]    io_outputs_1_ar_payload_cache,
  output wire [2:0]    io_outputs_1_ar_payload_prot,
  input  wire          io_outputs_1_r_valid,
  output wire          io_outputs_1_r_ready,
  input  wire [31:0]   io_outputs_1_r_payload_data,
  input  wire [3:0]    io_outputs_1_r_payload_id,
  input  wire [1:0]    io_outputs_1_r_payload_resp,
  input  wire          io_outputs_1_r_payload_last,
  output wire          io_outputs_2_ar_valid,
  input  wire          io_outputs_2_ar_ready,
  output wire [31:0]   io_outputs_2_ar_payload_addr,
  output wire [3:0]    io_outputs_2_ar_payload_id,
  output wire [7:0]    io_outputs_2_ar_payload_len,
  output wire [2:0]    io_outputs_2_ar_payload_size,
  output wire [1:0]    io_outputs_2_ar_payload_burst,
  output wire [0:0]    io_outputs_2_ar_payload_lock,
  output wire [3:0]    io_outputs_2_ar_payload_cache,
  output wire [2:0]    io_outputs_2_ar_payload_prot,
  input  wire          io_outputs_2_r_valid,
  output wire          io_outputs_2_r_ready,
  input  wire [31:0]   io_outputs_2_r_payload_data,
  input  wire [3:0]    io_outputs_2_r_payload_id,
  input  wire [1:0]    io_outputs_2_r_payload_resp,
  input  wire          io_outputs_2_r_payload_last,
  output wire          io_outputs_3_ar_valid,
  input  wire          io_outputs_3_ar_ready,
  output wire [31:0]   io_outputs_3_ar_payload_addr,
  output wire [3:0]    io_outputs_3_ar_payload_id,
  output wire [7:0]    io_outputs_3_ar_payload_len,
  output wire [2:0]    io_outputs_3_ar_payload_size,
  output wire [1:0]    io_outputs_3_ar_payload_burst,
  output wire [0:0]    io_outputs_3_ar_payload_lock,
  output wire [3:0]    io_outputs_3_ar_payload_cache,
  output wire [2:0]    io_outputs_3_ar_payload_prot,
  input  wire          io_outputs_3_r_valid,
  output wire          io_outputs_3_r_ready,
  input  wire [31:0]   io_outputs_3_r_payload_data,
  input  wire [3:0]    io_outputs_3_r_payload_id,
  input  wire [1:0]    io_outputs_3_r_payload_resp,
  input  wire          io_outputs_3_r_payload_last,
  output wire          io_outputs_4_ar_valid,
  input  wire          io_outputs_4_ar_ready,
  output wire [31:0]   io_outputs_4_ar_payload_addr,
  output wire [3:0]    io_outputs_4_ar_payload_id,
  output wire [7:0]    io_outputs_4_ar_payload_len,
  output wire [2:0]    io_outputs_4_ar_payload_size,
  output wire [1:0]    io_outputs_4_ar_payload_burst,
  output wire [0:0]    io_outputs_4_ar_payload_lock,
  output wire [3:0]    io_outputs_4_ar_payload_cache,
  output wire [2:0]    io_outputs_4_ar_payload_prot,
  input  wire          io_outputs_4_r_valid,
  output wire          io_outputs_4_r_ready,
  input  wire [31:0]   io_outputs_4_r_payload_data,
  input  wire [3:0]    io_outputs_4_r_payload_id,
  input  wire [1:0]    io_outputs_4_r_payload_resp,
  input  wire          io_outputs_4_r_payload_last,
  output wire          io_outputs_5_ar_valid,
  input  wire          io_outputs_5_ar_ready,
  output wire [31:0]   io_outputs_5_ar_payload_addr,
  output wire [3:0]    io_outputs_5_ar_payload_id,
  output wire [7:0]    io_outputs_5_ar_payload_len,
  output wire [2:0]    io_outputs_5_ar_payload_size,
  output wire [1:0]    io_outputs_5_ar_payload_burst,
  output wire [0:0]    io_outputs_5_ar_payload_lock,
  output wire [3:0]    io_outputs_5_ar_payload_cache,
  output wire [2:0]    io_outputs_5_ar_payload_prot,
  input  wire          io_outputs_5_r_valid,
  output wire          io_outputs_5_r_ready,
  input  wire [31:0]   io_outputs_5_r_payload_data,
  input  wire [3:0]    io_outputs_5_r_payload_id,
  input  wire [1:0]    io_outputs_5_r_payload_resp,
  input  wire          io_outputs_5_r_payload_last,
  output wire          io_outputs_6_ar_valid,
  input  wire          io_outputs_6_ar_ready,
  output wire [31:0]   io_outputs_6_ar_payload_addr,
  output wire [3:0]    io_outputs_6_ar_payload_id,
  output wire [7:0]    io_outputs_6_ar_payload_len,
  output wire [2:0]    io_outputs_6_ar_payload_size,
  output wire [1:0]    io_outputs_6_ar_payload_burst,
  output wire [0:0]    io_outputs_6_ar_payload_lock,
  output wire [3:0]    io_outputs_6_ar_payload_cache,
  output wire [2:0]    io_outputs_6_ar_payload_prot,
  input  wire          io_outputs_6_r_valid,
  output wire          io_outputs_6_r_ready,
  input  wire [31:0]   io_outputs_6_r_payload_data,
  input  wire [3:0]    io_outputs_6_r_payload_id,
  input  wire [1:0]    io_outputs_6_r_payload_resp,
  input  wire          io_outputs_6_r_payload_last,
  output wire          io_outputs_7_ar_valid,
  input  wire          io_outputs_7_ar_ready,
  output wire [31:0]   io_outputs_7_ar_payload_addr,
  output wire [3:0]    io_outputs_7_ar_payload_id,
  output wire [7:0]    io_outputs_7_ar_payload_len,
  output wire [2:0]    io_outputs_7_ar_payload_size,
  output wire [1:0]    io_outputs_7_ar_payload_burst,
  output wire [0:0]    io_outputs_7_ar_payload_lock,
  output wire [3:0]    io_outputs_7_ar_payload_cache,
  output wire [2:0]    io_outputs_7_ar_payload_prot,
  input  wire          io_outputs_7_r_valid,
  output wire          io_outputs_7_r_ready,
  input  wire [31:0]   io_outputs_7_r_payload_data,
  input  wire [3:0]    io_outputs_7_r_payload_id,
  input  wire [1:0]    io_outputs_7_r_payload_resp,
  input  wire          io_outputs_7_r_payload_last,
  input  wire          clk,
  input  wire          resetn
);

  wire                errorSlave_io_axi_ar_valid;
  wire                errorSlave_io_axi_ar_ready;
  wire                errorSlave_io_axi_r_valid;
  wire       [31:0]   errorSlave_io_axi_r_payload_data;
  wire       [3:0]    errorSlave_io_axi_r_payload_id;
  wire       [1:0]    errorSlave_io_axi_r_payload_resp;
  wire                errorSlave_io_axi_r_payload_last;
  wire       [31:0]   _zz_decodedCmdSels;
  wire       [31:0]   _zz_decodedCmdSels_1;
  wire       [31:0]   _zz_decodedCmdSels_2;
  wire       [31:0]   _zz_decodedCmdSels_3;
  wire                _zz_decodedCmdSels_4;
  wire                _zz_decodedCmdSels_5;
  wire       [0:0]    _zz_decodedCmdSels_6;
  wire       [1:0]    _zz_decodedCmdSels_7;
  wire       [31:0]   _zz_decodedCmdSels_8;
  wire       [31:0]   _zz_decodedCmdSels_9;
  reg        [31:0]   _zz_io_input_r_payload_data;
  reg        [3:0]    _zz_io_input_r_payload_id;
  reg        [1:0]    _zz_io_input_r_payload_resp;
  reg                 _zz_io_input_r_payload_last;
  wire                io_input_ar_fire;
  wire                io_input_r_fire;
  wire                when_Utils_l697;
  reg                 pendingCmdCounter_incrementIt;
  reg                 pendingCmdCounter_decrementIt;
  wire       [2:0]    pendingCmdCounter_valueNext;
  reg        [2:0]    pendingCmdCounter_value;
  wire                pendingCmdCounter_mayOverflow;
  wire                pendingCmdCounter_willOverflowIfInc;
  wire                pendingCmdCounter_willOverflow;
  reg        [2:0]    pendingCmdCounter_finalIncrement;
  wire                when_Utils_l723;
  wire                when_Utils_l725;
  wire       [7:0]    decodedCmdSels;
  wire                decodedCmdError;
  reg        [7:0]    pendingSels;
  reg                 pendingError;
  wire                allowCmd;
  wire                _zz_readRspIndex;
  wire                _zz_readRspIndex_1;
  wire                _zz_readRspIndex_2;
  wire                _zz_readRspIndex_3;
  wire                _zz_readRspIndex_4;
  wire                _zz_readRspIndex_5;
  wire                _zz_readRspIndex_6;
  wire       [2:0]    readRspIndex;

  assign _zz_decodedCmdSels = 32'h000fffff;
  assign _zz_decodedCmdSels_1 = (~ 32'h000fffff);
  assign _zz_decodedCmdSels_2 = (io_input_ar_payload_addr & (~ 32'h000fffff));
  assign _zz_decodedCmdSels_3 = 32'h1f300000;
  assign _zz_decodedCmdSels_4 = ((io_input_ar_payload_addr & (~ 32'h000fffff)) == 32'h1f200000);
  assign _zz_decodedCmdSels_5 = (((io_input_ar_payload_addr & (~ 32'h000fffff)) == 32'h1f100000) && io_input_ar_valid);
  assign _zz_decodedCmdSels_6 = (((io_input_ar_payload_addr & (~ 32'h000fffff)) == 32'h1f000000) && io_input_ar_valid);
  assign _zz_decodedCmdSels_7 = {(((io_input_ar_payload_addr & (~ _zz_decodedCmdSels_8)) == 32'h00000000) && io_input_ar_valid),(((io_input_ar_payload_addr & (~ _zz_decodedCmdSels_9)) == 32'h1c000000) && io_input_ar_valid)};
  assign _zz_decodedCmdSels_8 = 32'h007fffff;
  assign _zz_decodedCmdSels_9 = 32'h007fffff;
  Axi4ReadOnlyErrorSlave_1 errorSlave (
    .io_axi_ar_valid         (errorSlave_io_axi_ar_valid            ), //i
    .io_axi_ar_ready         (errorSlave_io_axi_ar_ready            ), //o
    .io_axi_ar_payload_addr  (io_input_ar_payload_addr[31:0]        ), //i
    .io_axi_ar_payload_id    (io_input_ar_payload_id[3:0]           ), //i
    .io_axi_ar_payload_len   (io_input_ar_payload_len[7:0]          ), //i
    .io_axi_ar_payload_size  (io_input_ar_payload_size[2:0]         ), //i
    .io_axi_ar_payload_burst (io_input_ar_payload_burst[1:0]        ), //i
    .io_axi_ar_payload_lock  (io_input_ar_payload_lock              ), //i
    .io_axi_ar_payload_cache (io_input_ar_payload_cache[3:0]        ), //i
    .io_axi_ar_payload_prot  (io_input_ar_payload_prot[2:0]         ), //i
    .io_axi_r_valid          (errorSlave_io_axi_r_valid             ), //o
    .io_axi_r_ready          (io_input_r_ready                      ), //i
    .io_axi_r_payload_data   (errorSlave_io_axi_r_payload_data[31:0]), //o
    .io_axi_r_payload_id     (errorSlave_io_axi_r_payload_id[3:0]   ), //o
    .io_axi_r_payload_resp   (errorSlave_io_axi_r_payload_resp[1:0] ), //o
    .io_axi_r_payload_last   (errorSlave_io_axi_r_payload_last      ), //o
    .clk                     (clk                                   ), //i
    .resetn                  (resetn                                )  //i
  );
  always @(*) begin
    case(readRspIndex)
      3'b000 : begin
        _zz_io_input_r_payload_data = io_outputs_0_r_payload_data;
        _zz_io_input_r_payload_id = io_outputs_0_r_payload_id;
        _zz_io_input_r_payload_resp = io_outputs_0_r_payload_resp;
        _zz_io_input_r_payload_last = io_outputs_0_r_payload_last;
      end
      3'b001 : begin
        _zz_io_input_r_payload_data = io_outputs_1_r_payload_data;
        _zz_io_input_r_payload_id = io_outputs_1_r_payload_id;
        _zz_io_input_r_payload_resp = io_outputs_1_r_payload_resp;
        _zz_io_input_r_payload_last = io_outputs_1_r_payload_last;
      end
      3'b010 : begin
        _zz_io_input_r_payload_data = io_outputs_2_r_payload_data;
        _zz_io_input_r_payload_id = io_outputs_2_r_payload_id;
        _zz_io_input_r_payload_resp = io_outputs_2_r_payload_resp;
        _zz_io_input_r_payload_last = io_outputs_2_r_payload_last;
      end
      3'b011 : begin
        _zz_io_input_r_payload_data = io_outputs_3_r_payload_data;
        _zz_io_input_r_payload_id = io_outputs_3_r_payload_id;
        _zz_io_input_r_payload_resp = io_outputs_3_r_payload_resp;
        _zz_io_input_r_payload_last = io_outputs_3_r_payload_last;
      end
      3'b100 : begin
        _zz_io_input_r_payload_data = io_outputs_4_r_payload_data;
        _zz_io_input_r_payload_id = io_outputs_4_r_payload_id;
        _zz_io_input_r_payload_resp = io_outputs_4_r_payload_resp;
        _zz_io_input_r_payload_last = io_outputs_4_r_payload_last;
      end
      3'b101 : begin
        _zz_io_input_r_payload_data = io_outputs_5_r_payload_data;
        _zz_io_input_r_payload_id = io_outputs_5_r_payload_id;
        _zz_io_input_r_payload_resp = io_outputs_5_r_payload_resp;
        _zz_io_input_r_payload_last = io_outputs_5_r_payload_last;
      end
      3'b110 : begin
        _zz_io_input_r_payload_data = io_outputs_6_r_payload_data;
        _zz_io_input_r_payload_id = io_outputs_6_r_payload_id;
        _zz_io_input_r_payload_resp = io_outputs_6_r_payload_resp;
        _zz_io_input_r_payload_last = io_outputs_6_r_payload_last;
      end
      default : begin
        _zz_io_input_r_payload_data = io_outputs_7_r_payload_data;
        _zz_io_input_r_payload_id = io_outputs_7_r_payload_id;
        _zz_io_input_r_payload_resp = io_outputs_7_r_payload_resp;
        _zz_io_input_r_payload_last = io_outputs_7_r_payload_last;
      end
    endcase
  end

  assign io_input_ar_fire = (io_input_ar_valid && io_input_ar_ready);
  assign io_input_r_fire = (io_input_r_valid && io_input_r_ready);
  assign when_Utils_l697 = (io_input_r_fire && io_input_r_payload_last);
  always @(*) begin
    pendingCmdCounter_incrementIt = 1'b0;
    if(io_input_ar_fire) begin
      pendingCmdCounter_incrementIt = 1'b1;
    end
  end

  always @(*) begin
    pendingCmdCounter_decrementIt = 1'b0;
    if(when_Utils_l697) begin
      pendingCmdCounter_decrementIt = 1'b1;
    end
  end

  assign pendingCmdCounter_mayOverflow = (pendingCmdCounter_value == 3'b111);
  assign pendingCmdCounter_willOverflowIfInc = (pendingCmdCounter_mayOverflow && (! pendingCmdCounter_decrementIt));
  assign pendingCmdCounter_willOverflow = (pendingCmdCounter_willOverflowIfInc && pendingCmdCounter_incrementIt);
  assign when_Utils_l723 = (pendingCmdCounter_incrementIt && (! pendingCmdCounter_decrementIt));
  always @(*) begin
    if(when_Utils_l723) begin
      pendingCmdCounter_finalIncrement = 3'b001;
    end else begin
      if(when_Utils_l725) begin
        pendingCmdCounter_finalIncrement = 3'b111;
      end else begin
        pendingCmdCounter_finalIncrement = 3'b000;
      end
    end
  end

  assign when_Utils_l725 = ((! pendingCmdCounter_incrementIt) && pendingCmdCounter_decrementIt);
  assign pendingCmdCounter_valueNext = (pendingCmdCounter_value + pendingCmdCounter_finalIncrement);
  assign decodedCmdSels = {(((io_input_ar_payload_addr & (~ _zz_decodedCmdSels)) == 32'h1f500000) && io_input_ar_valid),{(((io_input_ar_payload_addr & _zz_decodedCmdSels_1) == 32'h1f400000) && io_input_ar_valid),{((_zz_decodedCmdSels_2 == _zz_decodedCmdSels_3) && io_input_ar_valid),{(_zz_decodedCmdSels_4 && io_input_ar_valid),{_zz_decodedCmdSels_5,{_zz_decodedCmdSels_6,_zz_decodedCmdSels_7}}}}}};
  assign decodedCmdError = (decodedCmdSels == 8'h00);
  assign allowCmd = ((pendingCmdCounter_value == 3'b000) || ((pendingCmdCounter_value != 3'b111) && (pendingSels == decodedCmdSels)));
  assign io_input_ar_ready = (((|(decodedCmdSels & {io_outputs_7_ar_ready,{io_outputs_6_ar_ready,{io_outputs_5_ar_ready,{io_outputs_4_ar_ready,{io_outputs_3_ar_ready,{io_outputs_2_ar_ready,{io_outputs_1_ar_ready,io_outputs_0_ar_ready}}}}}}})) || (decodedCmdError && errorSlave_io_axi_ar_ready)) && allowCmd);
  assign errorSlave_io_axi_ar_valid = ((io_input_ar_valid && decodedCmdError) && allowCmd);
  assign io_outputs_0_ar_valid = ((io_input_ar_valid && decodedCmdSels[0]) && allowCmd);
  assign io_outputs_0_ar_payload_addr = io_input_ar_payload_addr;
  assign io_outputs_0_ar_payload_id = io_input_ar_payload_id;
  assign io_outputs_0_ar_payload_len = io_input_ar_payload_len;
  assign io_outputs_0_ar_payload_size = io_input_ar_payload_size;
  assign io_outputs_0_ar_payload_burst = io_input_ar_payload_burst;
  assign io_outputs_0_ar_payload_lock = io_input_ar_payload_lock;
  assign io_outputs_0_ar_payload_cache = io_input_ar_payload_cache;
  assign io_outputs_0_ar_payload_prot = io_input_ar_payload_prot;
  assign io_outputs_1_ar_valid = ((io_input_ar_valid && decodedCmdSels[1]) && allowCmd);
  assign io_outputs_1_ar_payload_addr = io_input_ar_payload_addr;
  assign io_outputs_1_ar_payload_id = io_input_ar_payload_id;
  assign io_outputs_1_ar_payload_len = io_input_ar_payload_len;
  assign io_outputs_1_ar_payload_size = io_input_ar_payload_size;
  assign io_outputs_1_ar_payload_burst = io_input_ar_payload_burst;
  assign io_outputs_1_ar_payload_lock = io_input_ar_payload_lock;
  assign io_outputs_1_ar_payload_cache = io_input_ar_payload_cache;
  assign io_outputs_1_ar_payload_prot = io_input_ar_payload_prot;
  assign io_outputs_2_ar_valid = ((io_input_ar_valid && decodedCmdSels[2]) && allowCmd);
  assign io_outputs_2_ar_payload_addr = io_input_ar_payload_addr;
  assign io_outputs_2_ar_payload_id = io_input_ar_payload_id;
  assign io_outputs_2_ar_payload_len = io_input_ar_payload_len;
  assign io_outputs_2_ar_payload_size = io_input_ar_payload_size;
  assign io_outputs_2_ar_payload_burst = io_input_ar_payload_burst;
  assign io_outputs_2_ar_payload_lock = io_input_ar_payload_lock;
  assign io_outputs_2_ar_payload_cache = io_input_ar_payload_cache;
  assign io_outputs_2_ar_payload_prot = io_input_ar_payload_prot;
  assign io_outputs_3_ar_valid = ((io_input_ar_valid && decodedCmdSels[3]) && allowCmd);
  assign io_outputs_3_ar_payload_addr = io_input_ar_payload_addr;
  assign io_outputs_3_ar_payload_id = io_input_ar_payload_id;
  assign io_outputs_3_ar_payload_len = io_input_ar_payload_len;
  assign io_outputs_3_ar_payload_size = io_input_ar_payload_size;
  assign io_outputs_3_ar_payload_burst = io_input_ar_payload_burst;
  assign io_outputs_3_ar_payload_lock = io_input_ar_payload_lock;
  assign io_outputs_3_ar_payload_cache = io_input_ar_payload_cache;
  assign io_outputs_3_ar_payload_prot = io_input_ar_payload_prot;
  assign io_outputs_4_ar_valid = ((io_input_ar_valid && decodedCmdSels[4]) && allowCmd);
  assign io_outputs_4_ar_payload_addr = io_input_ar_payload_addr;
  assign io_outputs_4_ar_payload_id = io_input_ar_payload_id;
  assign io_outputs_4_ar_payload_len = io_input_ar_payload_len;
  assign io_outputs_4_ar_payload_size = io_input_ar_payload_size;
  assign io_outputs_4_ar_payload_burst = io_input_ar_payload_burst;
  assign io_outputs_4_ar_payload_lock = io_input_ar_payload_lock;
  assign io_outputs_4_ar_payload_cache = io_input_ar_payload_cache;
  assign io_outputs_4_ar_payload_prot = io_input_ar_payload_prot;
  assign io_outputs_5_ar_valid = ((io_input_ar_valid && decodedCmdSels[5]) && allowCmd);
  assign io_outputs_5_ar_payload_addr = io_input_ar_payload_addr;
  assign io_outputs_5_ar_payload_id = io_input_ar_payload_id;
  assign io_outputs_5_ar_payload_len = io_input_ar_payload_len;
  assign io_outputs_5_ar_payload_size = io_input_ar_payload_size;
  assign io_outputs_5_ar_payload_burst = io_input_ar_payload_burst;
  assign io_outputs_5_ar_payload_lock = io_input_ar_payload_lock;
  assign io_outputs_5_ar_payload_cache = io_input_ar_payload_cache;
  assign io_outputs_5_ar_payload_prot = io_input_ar_payload_prot;
  assign io_outputs_6_ar_valid = ((io_input_ar_valid && decodedCmdSels[6]) && allowCmd);
  assign io_outputs_6_ar_payload_addr = io_input_ar_payload_addr;
  assign io_outputs_6_ar_payload_id = io_input_ar_payload_id;
  assign io_outputs_6_ar_payload_len = io_input_ar_payload_len;
  assign io_outputs_6_ar_payload_size = io_input_ar_payload_size;
  assign io_outputs_6_ar_payload_burst = io_input_ar_payload_burst;
  assign io_outputs_6_ar_payload_lock = io_input_ar_payload_lock;
  assign io_outputs_6_ar_payload_cache = io_input_ar_payload_cache;
  assign io_outputs_6_ar_payload_prot = io_input_ar_payload_prot;
  assign io_outputs_7_ar_valid = ((io_input_ar_valid && decodedCmdSels[7]) && allowCmd);
  assign io_outputs_7_ar_payload_addr = io_input_ar_payload_addr;
  assign io_outputs_7_ar_payload_id = io_input_ar_payload_id;
  assign io_outputs_7_ar_payload_len = io_input_ar_payload_len;
  assign io_outputs_7_ar_payload_size = io_input_ar_payload_size;
  assign io_outputs_7_ar_payload_burst = io_input_ar_payload_burst;
  assign io_outputs_7_ar_payload_lock = io_input_ar_payload_lock;
  assign io_outputs_7_ar_payload_cache = io_input_ar_payload_cache;
  assign io_outputs_7_ar_payload_prot = io_input_ar_payload_prot;
  assign _zz_readRspIndex = pendingSels[3];
  assign _zz_readRspIndex_1 = pendingSels[5];
  assign _zz_readRspIndex_2 = pendingSels[6];
  assign _zz_readRspIndex_3 = pendingSels[7];
  assign _zz_readRspIndex_4 = (((pendingSels[1] || _zz_readRspIndex) || _zz_readRspIndex_1) || _zz_readRspIndex_3);
  assign _zz_readRspIndex_5 = (((pendingSels[2] || _zz_readRspIndex) || _zz_readRspIndex_2) || _zz_readRspIndex_3);
  assign _zz_readRspIndex_6 = (((pendingSels[4] || _zz_readRspIndex_1) || _zz_readRspIndex_2) || _zz_readRspIndex_3);
  assign readRspIndex = {_zz_readRspIndex_6,{_zz_readRspIndex_5,_zz_readRspIndex_4}};
  always @(*) begin
    io_input_r_valid = (|{io_outputs_7_r_valid,{io_outputs_6_r_valid,{io_outputs_5_r_valid,{io_outputs_4_r_valid,{io_outputs_3_r_valid,{io_outputs_2_r_valid,{io_outputs_1_r_valid,io_outputs_0_r_valid}}}}}}});
    if(errorSlave_io_axi_r_valid) begin
      io_input_r_valid = 1'b1;
    end
  end

  assign io_input_r_payload_data = _zz_io_input_r_payload_data;
  always @(*) begin
    io_input_r_payload_id = _zz_io_input_r_payload_id;
    if(pendingError) begin
      io_input_r_payload_id = errorSlave_io_axi_r_payload_id;
    end
  end

  always @(*) begin
    io_input_r_payload_resp = _zz_io_input_r_payload_resp;
    if(pendingError) begin
      io_input_r_payload_resp = errorSlave_io_axi_r_payload_resp;
    end
  end

  always @(*) begin
    io_input_r_payload_last = _zz_io_input_r_payload_last;
    if(pendingError) begin
      io_input_r_payload_last = errorSlave_io_axi_r_payload_last;
    end
  end

  assign io_outputs_0_r_ready = io_input_r_ready;
  assign io_outputs_1_r_ready = io_input_r_ready;
  assign io_outputs_2_r_ready = io_input_r_ready;
  assign io_outputs_3_r_ready = io_input_r_ready;
  assign io_outputs_4_r_ready = io_input_r_ready;
  assign io_outputs_5_r_ready = io_input_r_ready;
  assign io_outputs_6_r_ready = io_input_r_ready;
  assign io_outputs_7_r_ready = io_input_r_ready;
  always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      pendingCmdCounter_value <= 3'b000;
      pendingSels <= 8'h00;
      pendingError <= 1'b0;
    end else begin
      pendingCmdCounter_value <= pendingCmdCounter_valueNext;
      if(io_input_ar_ready) begin
        pendingSels <= decodedCmdSels;
      end
      if(io_input_ar_ready) begin
        pendingError <= decodedCmdError;
      end
    end
  end


endmodule

//StreamFifoLowLatency replaced by StreamFifoLowLatency_3

//StreamArbiter replaced by StreamArbiter_7

//StreamArbiter_1 replaced by StreamArbiter_7

//StreamFifoLowLatency_1 replaced by StreamFifoLowLatency_3

//StreamArbiter_2 replaced by StreamArbiter_7

//StreamArbiter_3 replaced by StreamArbiter_7

//StreamFifoLowLatency_2 replaced by StreamFifoLowLatency_3

//StreamArbiter_4 replaced by StreamArbiter_7

//StreamArbiter_5 replaced by StreamArbiter_7

module StreamFifoLowLatency_3 (
  input  wire          io_push_valid,
  output wire          io_push_ready,
  input  wire [0:0]    io_push_payload,
  output wire          io_pop_valid,
  input  wire          io_pop_ready,
  output wire [0:0]    io_pop_payload,
  input  wire          io_flush,
  output wire [2:0]    io_occupancy,
  output wire [2:0]    io_availability,
  input  wire          clk,
  input  wire          resetn
);

  wire                fifo_io_push_ready;
  wire                fifo_io_pop_valid;
  wire       [0:0]    fifo_io_pop_payload;
  wire       [2:0]    fifo_io_occupancy;
  wire       [2:0]    fifo_io_availability;

  StreamFifo_3 fifo (
    .io_push_valid   (io_push_valid            ), //i
    .io_push_ready   (fifo_io_push_ready       ), //o
    .io_push_payload (io_push_payload          ), //i
    .io_pop_valid    (fifo_io_pop_valid        ), //o
    .io_pop_ready    (io_pop_ready             ), //i
    .io_pop_payload  (fifo_io_pop_payload      ), //o
    .io_flush        (io_flush                 ), //i
    .io_occupancy    (fifo_io_occupancy[2:0]   ), //o
    .io_availability (fifo_io_availability[2:0]), //o
    .clk             (clk                      ), //i
    .resetn          (resetn                   )  //i
  );
  assign io_push_ready = fifo_io_push_ready;
  assign io_pop_valid = fifo_io_pop_valid;
  assign io_pop_payload = fifo_io_pop_payload;
  assign io_occupancy = fifo_io_occupancy;
  assign io_availability = fifo_io_availability;

endmodule

//StreamArbiter_6 replaced by StreamArbiter_7

module StreamArbiter_7 (
  input  wire          io_inputs_0_valid,
  output wire          io_inputs_0_ready,
  input  wire [31:0]   io_inputs_0_payload_addr,
  input  wire [3:0]    io_inputs_0_payload_id,
  input  wire [7:0]    io_inputs_0_payload_len,
  input  wire [2:0]    io_inputs_0_payload_size,
  input  wire [1:0]    io_inputs_0_payload_burst,
  input  wire [0:0]    io_inputs_0_payload_lock,
  input  wire [3:0]    io_inputs_0_payload_cache,
  input  wire [2:0]    io_inputs_0_payload_prot,
  input  wire          io_inputs_1_valid,
  output wire          io_inputs_1_ready,
  input  wire [31:0]   io_inputs_1_payload_addr,
  input  wire [3:0]    io_inputs_1_payload_id,
  input  wire [7:0]    io_inputs_1_payload_len,
  input  wire [2:0]    io_inputs_1_payload_size,
  input  wire [1:0]    io_inputs_1_payload_burst,
  input  wire [0:0]    io_inputs_1_payload_lock,
  input  wire [3:0]    io_inputs_1_payload_cache,
  input  wire [2:0]    io_inputs_1_payload_prot,
  output wire          io_output_valid,
  input  wire          io_output_ready,
  output wire [31:0]   io_output_payload_addr,
  output wire [3:0]    io_output_payload_id,
  output wire [7:0]    io_output_payload_len,
  output wire [2:0]    io_output_payload_size,
  output wire [1:0]    io_output_payload_burst,
  output wire [0:0]    io_output_payload_lock,
  output wire [3:0]    io_output_payload_cache,
  output wire [2:0]    io_output_payload_prot,
  output wire [0:0]    io_chosen,
  output wire [1:0]    io_chosenOH,
  input  wire          clk,
  input  wire          resetn
);

  wire       [3:0]    _zz__zz_maskProposal_0_2;
  wire       [3:0]    _zz__zz_maskProposal_0_2_1;
  wire       [1:0]    _zz__zz_maskProposal_0_2_2;
  reg                 locked;
  wire                maskProposal_0;
  wire                maskProposal_1;
  reg                 maskLocked_0;
  reg                 maskLocked_1;
  wire                maskRouted_0;
  wire                maskRouted_1;
  wire       [1:0]    _zz_maskProposal_0;
  wire       [3:0]    _zz_maskProposal_0_1;
  wire       [3:0]    _zz_maskProposal_0_2;
  wire       [1:0]    _zz_maskProposal_0_3;
  wire                io_output_fire;
  wire                _zz_io_chosen;

  assign _zz__zz_maskProposal_0_2 = (_zz_maskProposal_0_1 - _zz__zz_maskProposal_0_2_1);
  assign _zz__zz_maskProposal_0_2_2 = {maskLocked_0,maskLocked_1};
  assign _zz__zz_maskProposal_0_2_1 = {2'd0, _zz__zz_maskProposal_0_2_2};
  assign maskRouted_0 = (locked ? maskLocked_0 : maskProposal_0);
  assign maskRouted_1 = (locked ? maskLocked_1 : maskProposal_1);
  assign _zz_maskProposal_0 = {io_inputs_1_valid,io_inputs_0_valid};
  assign _zz_maskProposal_0_1 = {_zz_maskProposal_0,_zz_maskProposal_0};
  assign _zz_maskProposal_0_2 = (_zz_maskProposal_0_1 & (~ _zz__zz_maskProposal_0_2));
  assign _zz_maskProposal_0_3 = (_zz_maskProposal_0_2[3 : 2] | _zz_maskProposal_0_2[1 : 0]);
  assign maskProposal_0 = _zz_maskProposal_0_3[0];
  assign maskProposal_1 = _zz_maskProposal_0_3[1];
  assign io_output_fire = (io_output_valid && io_output_ready);
  assign io_output_valid = ((io_inputs_0_valid && maskRouted_0) || (io_inputs_1_valid && maskRouted_1));
  assign io_output_payload_addr = (maskRouted_0 ? io_inputs_0_payload_addr : io_inputs_1_payload_addr);
  assign io_output_payload_id = (maskRouted_0 ? io_inputs_0_payload_id : io_inputs_1_payload_id);
  assign io_output_payload_len = (maskRouted_0 ? io_inputs_0_payload_len : io_inputs_1_payload_len);
  assign io_output_payload_size = (maskRouted_0 ? io_inputs_0_payload_size : io_inputs_1_payload_size);
  assign io_output_payload_burst = (maskRouted_0 ? io_inputs_0_payload_burst : io_inputs_1_payload_burst);
  assign io_output_payload_lock = (maskRouted_0 ? io_inputs_0_payload_lock : io_inputs_1_payload_lock);
  assign io_output_payload_cache = (maskRouted_0 ? io_inputs_0_payload_cache : io_inputs_1_payload_cache);
  assign io_output_payload_prot = (maskRouted_0 ? io_inputs_0_payload_prot : io_inputs_1_payload_prot);
  assign io_inputs_0_ready = (maskRouted_0 && io_output_ready);
  assign io_inputs_1_ready = (maskRouted_1 && io_output_ready);
  assign io_chosenOH = {maskRouted_1,maskRouted_0};
  assign _zz_io_chosen = io_chosenOH[1];
  assign io_chosen = _zz_io_chosen;
  always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      locked <= 1'b0;
      maskLocked_0 <= 1'b0;
      maskLocked_1 <= 1'b1;
    end else begin
      if(io_output_valid) begin
        maskLocked_0 <= maskRouted_0;
        maskLocked_1 <= maskRouted_1;
      end
      if(io_output_valid) begin
        locked <= 1'b1;
      end
      if(io_output_fire) begin
        locked <= 1'b0;
      end
    end
  end


endmodule

//Axi4WriteOnlyErrorSlave replaced by Axi4WriteOnlyErrorSlave_1

//Axi4ReadOnlyErrorSlave replaced by Axi4ReadOnlyErrorSlave_1

module Axi4WriteOnlyErrorSlave_1 (
  input  wire          io_axi_aw_valid,
  output wire          io_axi_aw_ready,
  input  wire [31:0]   io_axi_aw_payload_addr,
  input  wire [3:0]    io_axi_aw_payload_id,
  input  wire [7:0]    io_axi_aw_payload_len,
  input  wire [2:0]    io_axi_aw_payload_size,
  input  wire [1:0]    io_axi_aw_payload_burst,
  input  wire [0:0]    io_axi_aw_payload_lock,
  input  wire [3:0]    io_axi_aw_payload_cache,
  input  wire [2:0]    io_axi_aw_payload_prot,
  input  wire          io_axi_w_valid,
  output wire          io_axi_w_ready,
  input  wire [31:0]   io_axi_w_payload_data,
  input  wire [3:0]    io_axi_w_payload_strb,
  input  wire          io_axi_w_payload_last,
  output wire          io_axi_b_valid,
  input  wire          io_axi_b_ready,
  output wire [3:0]    io_axi_b_payload_id,
  output wire [1:0]    io_axi_b_payload_resp,
  input  wire          clk,
  input  wire          resetn
);

  reg                 consumeData;
  reg                 sendRsp;
  reg        [3:0]    id;
  wire                io_axi_aw_fire;
  wire                io_axi_w_fire;
  wire                when_Axi4ErrorSlave_l24;
  wire                io_axi_b_fire;

  assign io_axi_aw_ready = (! (consumeData || sendRsp));
  assign io_axi_aw_fire = (io_axi_aw_valid && io_axi_aw_ready);
  assign io_axi_w_ready = consumeData;
  assign io_axi_w_fire = (io_axi_w_valid && io_axi_w_ready);
  assign when_Axi4ErrorSlave_l24 = (io_axi_w_fire && io_axi_w_payload_last);
  assign io_axi_b_valid = sendRsp;
  assign io_axi_b_payload_resp = 2'b11;
  assign io_axi_b_payload_id = id;
  assign io_axi_b_fire = (io_axi_b_valid && io_axi_b_ready);
  always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      consumeData <= 1'b0;
      sendRsp <= 1'b0;
    end else begin
      if(io_axi_aw_fire) begin
        consumeData <= 1'b1;
      end
      if(when_Axi4ErrorSlave_l24) begin
        consumeData <= 1'b0;
        sendRsp <= 1'b1;
      end
      if(io_axi_b_fire) begin
        sendRsp <= 1'b0;
      end
    end
  end

  always @(posedge clk) begin
    if(io_axi_aw_fire) begin
      id <= io_axi_aw_payload_id;
    end
  end


endmodule

module Axi4ReadOnlyErrorSlave_1 (
  input  wire          io_axi_ar_valid,
  output wire          io_axi_ar_ready,
  input  wire [31:0]   io_axi_ar_payload_addr,
  input  wire [3:0]    io_axi_ar_payload_id,
  input  wire [7:0]    io_axi_ar_payload_len,
  input  wire [2:0]    io_axi_ar_payload_size,
  input  wire [1:0]    io_axi_ar_payload_burst,
  input  wire [0:0]    io_axi_ar_payload_lock,
  input  wire [3:0]    io_axi_ar_payload_cache,
  input  wire [2:0]    io_axi_ar_payload_prot,
  output wire          io_axi_r_valid,
  input  wire          io_axi_r_ready,
  output wire [31:0]   io_axi_r_payload_data,
  output wire [3:0]    io_axi_r_payload_id,
  output wire [1:0]    io_axi_r_payload_resp,
  output wire          io_axi_r_payload_last,
  input  wire          clk,
  input  wire          resetn
);

  reg                 sendRsp;
  reg        [3:0]    id;
  reg        [7:0]    remaining;
  wire                remainingZero;
  wire                io_axi_ar_fire;

  assign remainingZero = (remaining == 8'h00);
  assign io_axi_ar_ready = (! sendRsp);
  assign io_axi_ar_fire = (io_axi_ar_valid && io_axi_ar_ready);
  assign io_axi_r_valid = sendRsp;
  assign io_axi_r_payload_id = id;
  assign io_axi_r_payload_resp = 2'b11;
  assign io_axi_r_payload_last = remainingZero;
  always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      sendRsp <= 1'b0;
    end else begin
      if(io_axi_ar_fire) begin
        sendRsp <= 1'b1;
      end
      if(sendRsp) begin
        if(io_axi_r_ready) begin
          if(remainingZero) begin
            sendRsp <= 1'b0;
          end
        end
      end
    end
  end

  always @(posedge clk) begin
    if(io_axi_ar_fire) begin
      remaining <= io_axi_ar_payload_len;
      id <= io_axi_ar_payload_id;
    end
    if(sendRsp) begin
      if(io_axi_r_ready) begin
        remaining <= (remaining - 8'h01);
      end
    end
  end


endmodule

//StreamFifo replaced by StreamFifo_3

//StreamFifo_1 replaced by StreamFifo_3

//StreamFifo_2 replaced by StreamFifo_3

module StreamFifo_3 (
  input  wire          io_push_valid,
  output wire          io_push_ready,
  input  wire [0:0]    io_push_payload,
  output reg           io_pop_valid,
  input  wire          io_pop_ready,
  output reg  [0:0]    io_pop_payload,
  input  wire          io_flush,
  output wire [2:0]    io_occupancy,
  output wire [2:0]    io_availability,
  input  wire          clk,
  input  wire          resetn
);

  wire       [0:0]    _zz_logic_ram_port1;
  wire       [0:0]    _zz_logic_ram_port;
  reg                 _zz_1;
  reg                 logic_ptr_doPush;
  wire                logic_ptr_doPop;
  wire                logic_ptr_full;
  wire                logic_ptr_empty;
  reg        [2:0]    logic_ptr_push;
  reg        [2:0]    logic_ptr_pop;
  wire       [2:0]    logic_ptr_occupancy;
  wire       [2:0]    logic_ptr_popOnIo;
  wire                when_Stream_l1205;
  reg                 logic_ptr_wentUp;
  wire                io_push_fire;
  wire                logic_push_onRam_write_valid;
  wire       [1:0]    logic_push_onRam_write_payload_address;
  wire       [0:0]    logic_push_onRam_write_payload_data;
  wire                logic_pop_addressGen_valid;
  wire                logic_pop_addressGen_ready;
  wire       [1:0]    logic_pop_addressGen_payload;
  wire                logic_pop_addressGen_fire;
  wire       [0:0]    logic_pop_async_readed;
  wire                logic_pop_addressGen_translated_valid;
  wire                logic_pop_addressGen_translated_ready;
  wire       [0:0]    logic_pop_addressGen_translated_payload;
  (* ram_style = "distributed" *) reg [0:0] logic_ram [0:3];

  assign _zz_logic_ram_port = logic_push_onRam_write_payload_data;
  always @(posedge clk) begin
    if(_zz_1) begin
      logic_ram[logic_push_onRam_write_payload_address] <= _zz_logic_ram_port;
    end
  end

  assign _zz_logic_ram_port1 = logic_ram[logic_pop_addressGen_payload];
  always @(*) begin
    _zz_1 = 1'b0;
    if(logic_push_onRam_write_valid) begin
      _zz_1 = 1'b1;
    end
  end

  assign when_Stream_l1205 = (logic_ptr_doPush != logic_ptr_doPop);
  assign logic_ptr_full = (((logic_ptr_push ^ logic_ptr_popOnIo) ^ 3'b100) == 3'b000);
  assign logic_ptr_empty = (logic_ptr_push == logic_ptr_pop);
  assign logic_ptr_occupancy = (logic_ptr_push - logic_ptr_popOnIo);
  assign io_push_ready = (! logic_ptr_full);
  assign io_push_fire = (io_push_valid && io_push_ready);
  always @(*) begin
    logic_ptr_doPush = io_push_fire;
    if(logic_ptr_empty) begin
      if(io_pop_ready) begin
        logic_ptr_doPush = 1'b0;
      end
    end
  end

  assign logic_push_onRam_write_valid = io_push_fire;
  assign logic_push_onRam_write_payload_address = logic_ptr_push[1:0];
  assign logic_push_onRam_write_payload_data = io_push_payload;
  assign logic_pop_addressGen_valid = (! logic_ptr_empty);
  assign logic_pop_addressGen_payload = logic_ptr_pop[1:0];
  assign logic_pop_addressGen_fire = (logic_pop_addressGen_valid && logic_pop_addressGen_ready);
  assign logic_ptr_doPop = logic_pop_addressGen_fire;
  assign logic_pop_async_readed = _zz_logic_ram_port1;
  assign logic_pop_addressGen_translated_valid = logic_pop_addressGen_valid;
  assign logic_pop_addressGen_ready = logic_pop_addressGen_translated_ready;
  assign logic_pop_addressGen_translated_payload = logic_pop_async_readed;
  always @(*) begin
    io_pop_valid = logic_pop_addressGen_translated_valid;
    if(logic_ptr_empty) begin
      io_pop_valid = io_push_valid;
    end
  end

  assign logic_pop_addressGen_translated_ready = io_pop_ready;
  always @(*) begin
    io_pop_payload = logic_pop_addressGen_translated_payload;
    if(logic_ptr_empty) begin
      io_pop_payload = io_push_payload;
    end
  end

  assign logic_ptr_popOnIo = logic_ptr_pop;
  assign io_occupancy = logic_ptr_occupancy;
  assign io_availability = (3'b100 - logic_ptr_occupancy);
  always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      logic_ptr_push <= 3'b000;
      logic_ptr_pop <= 3'b000;
      logic_ptr_wentUp <= 1'b0;
    end else begin
      if(when_Stream_l1205) begin
        logic_ptr_wentUp <= logic_ptr_doPush;
      end
      if(io_flush) begin
        logic_ptr_wentUp <= 1'b0;
      end
      if(logic_ptr_doPush) begin
        logic_ptr_push <= (logic_ptr_push + 3'b001);
      end
      if(logic_ptr_doPop) begin
        logic_ptr_pop <= (logic_ptr_pop + 3'b001);
      end
      if(io_flush) begin
        logic_ptr_push <= 3'b000;
        logic_ptr_pop <= 3'b000;
      end
    end
  end


endmodule
