`timescale 1ns / 1ps
`include "config.h"

module verilator_tb (
    input         clk,
    input         reset,
    input         uart_rx,
    output        uart_tx,
    output        uart_display,
    output [7:0]  uart_data,
    output        ext_ram_write_fire,
    output [19:0] ext_ram_write_addr,
    output [31:0] ext_ram_write_data,
    output [3:0]  ext_ram_write_be_n,
    input  [19:0] ext_ram_dump_addr,
    output [31:0] ext_ram_dump_data,
    output [31:0] debug_wb_pc,
    output [31:0] debug_wb_inst,
    output [3:0]  debug_wb_rf_wen,
    output [4:0]  debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata,
    output        cpu_ar_fire,
    output [31:0] cpu_ar_addr,
    output        cpu_aw_fire,
    output [31:0] cpu_aw_addr,
    output        data_uncache_en,
    output        data_valid,
    output        data_op,
    output        data_addr_ok,
    output [7:0]  data_index,
    output [19:0] data_tag,
    output [3:0]  data_offset,
    output [3:0]  data_wstrb,
    output [31:0] data_wdata,
    output [31:0] data_rd_addr,
    output [31:0] data_vaddr,
    output        data_wr_req,
    output [31:0] data_wr_addr,
    output [127:0] data_wr_data,
    output [4:0]  dcache_main_state,
    output        dcache_cache_hit,
    output [1:0]  dcache_way_hit,
    output        dcache_write_full,
    output        dcache_req_op,
    output [7:0]  dcache_req_index,
    output [3:0]  dcache_req_offset,
    output [31:0] dcache_req_wdata,
    output [7:0]  dcache_write_index,
    output [3:0]  dcache_write_offset,
    output [31:0] dcache_write_wdata,
    output [1:0]  dcache_write_way,
    output        dcache_req_dcacop,
    output [1:0]  dcache_req_cacop_mode,
    output [1:0]  dcache_way_d,
    output [1:0]  dcache_replace_way,
    output        dcache_replace_d,
    output        dcache_replace_v,
    output [19:0] dcache_replace_tag,
    output        csr_da,
    output        csr_pg,
    output [31:0] csr_dmw1
);

wire [2:0]  video_red;
wire [2:0]  video_green;
wire [1:0]  video_blue;
wire        video_hsync;
wire        video_vsync;
wire        video_clk;
wire        video_de;
wire [15:0] leds;
wire [7:0]  dpy0;
wire [7:0]  dpy1;

wire [19:0] base_ram_addr;
wire [3:0]  base_ram_be_n;
wire        base_ram_ce_n;
wire        base_ram_oe_n;
wire        base_ram_we_n;
wire [31:0] base_ram_data;

wire [19:0] ext_ram_addr;
wire [3:0]  ext_ram_be_n;
wire        ext_ram_ce_n;
wire        ext_ram_oe_n;
wire        ext_ram_we_n;
wire [31:0] ext_ram_data;

wire [3:0]  touch_btn = 4'h0;
wire [31:0] dip_sw    = 32'h0000_abcd;
wire        uart_rx_line;

assign uart_rx_line = uart_rx;

soc_top #(.SIMULATION(1'b1)) u_soc_top (
    .clk           (clk),
    .reset         (reset),
    .video_red     (video_red),
    .video_green   (video_green),
    .video_blue    (video_blue),
    .video_hsync   (video_hsync),
    .video_vsync   (video_vsync),
    .video_clk     (video_clk),
    .video_de      (video_de),
    .touch_btn     (touch_btn),
    .dip_sw        (dip_sw),
    .leds          (leds),
    .dpy0          (dpy0),
    .dpy1          (dpy1),
    .base_ram_data (base_ram_data),
    .base_ram_addr (base_ram_addr),
    .base_ram_be_n (base_ram_be_n),
    .base_ram_ce_n (base_ram_ce_n),
    .base_ram_oe_n (base_ram_oe_n),
    .base_ram_we_n (base_ram_we_n),
    .ext_ram_data  (ext_ram_data),
    .ext_ram_addr  (ext_ram_addr),
    .ext_ram_be_n  (ext_ram_be_n),
    .ext_ram_ce_n  (ext_ram_ce_n),
    .ext_ram_oe_n  (ext_ram_oe_n),
    .ext_ram_we_n  (ext_ram_we_n),
    .UART_RX       (uart_rx_line),
    .UART_TX       (uart_tx)
);

sram_sp #(
    .AW        (20),
    .Init_File ("none"),
    .Init_Plusarg("base_ram_mif=%s"))
base_sram_sp (
    .ram_addr (base_ram_addr),
    .ram_be_n (base_ram_be_n),
    .ram_ce_n (base_ram_ce_n),
    .ram_oe_n (base_ram_oe_n),
    .ram_we_n (base_ram_we_n),
    .ram_data (base_ram_data)
);

sram_sp #(
    .AW        (20),
    .Init_File ("none"),
    .Init_Plusarg("ext_ram_mif=%s"))
ext_sram_sp (
    .ram_addr (ext_ram_addr),
    .ram_be_n (ext_ram_be_n),
    .ram_ce_n (ext_ram_ce_n),
    .ram_oe_n (ext_ram_oe_n),
    .ram_we_n (ext_ram_we_n),
    .ram_data (ext_ram_data)
);

wire uart_wen = u_soc_top.u_axi_uart_controller.uart0.PSEL &&
                u_soc_top.u_axi_uart_controller.uart0.PENABLE &&
                u_soc_top.u_axi_uart_controller.uart0.PWRITE;

assign uart_display = uart_wen &&
                      (u_soc_top.u_axi_uart_controller.uart0.PADDR[7:0] == 8'h0) &&
                      !u_soc_top.u_axi_uart_controller.uart0.regs.lcr[7];
assign uart_data    = u_soc_top.u_axi_uart_controller.uart0.PWDATA[7:0];

assign ext_ram_write_fire = (ext_ram_ce_n === 1'b0) && (ext_ram_we_n === 1'b0);
assign ext_ram_write_addr = ext_ram_addr;
assign ext_ram_write_data = ext_ram_data;
assign ext_ram_write_be_n = ext_ram_be_n;
assign ext_ram_dump_data  = ext_sram_sp.BRAM[ext_ram_dump_addr[19:0]];
assign debug_wb_pc        = u_soc_top.debug_wb_pc;
assign debug_wb_inst      = u_soc_top.debug_wb_inst;
assign debug_wb_rf_wen    = u_soc_top.debug_wb_rf_wen;
assign debug_wb_rf_wnum   = u_soc_top.debug_wb_rf_wnum;
assign debug_wb_rf_wdata  = u_soc_top.debug_wb_rf_wdata;
assign cpu_ar_fire        = u_soc_top.cpu_arvalid && u_soc_top.cpu_arready;
assign cpu_ar_addr        = u_soc_top.cpu_araddr;
assign cpu_aw_fire        = u_soc_top.cpu_awvalid && u_soc_top.cpu_awready;
assign cpu_aw_addr        = u_soc_top.cpu_awaddr;

`ifdef MYCPU_OPENLA500_PROBES
assign data_uncache_en    = u_soc_top.u_cpu.data_uncache_en;
assign data_valid         = u_soc_top.u_cpu.data_valid;
assign data_op            = u_soc_top.u_cpu.data_op;
assign data_addr_ok       = u_soc_top.u_cpu.data_addr_ok;
assign data_index         = u_soc_top.u_cpu.data_index;
assign data_tag           = u_soc_top.u_cpu.data_tag;
assign data_offset        = u_soc_top.u_cpu.data_offset;
assign data_wstrb         = u_soc_top.u_cpu.data_wstrb;
assign data_wdata         = u_soc_top.u_cpu.data_wdata;
assign data_rd_addr       = u_soc_top.u_cpu.data_rd_addr;
assign data_vaddr         = u_soc_top.u_cpu.data_vaddr;
assign data_wr_req        = u_soc_top.u_cpu.data_wr_req;
assign data_wr_addr       = u_soc_top.u_cpu.data_wr_addr;
assign data_wr_data       = u_soc_top.u_cpu.data_wr_data;
assign dcache_main_state  = u_soc_top.u_cpu.dcache.main_state;
assign dcache_cache_hit   = u_soc_top.u_cpu.dcache.cache_hit;
assign dcache_way_hit     = u_soc_top.u_cpu.dcache.way_hit;
assign dcache_write_full  = u_soc_top.u_cpu.dcache.write_state_is_full;
assign dcache_req_op      = u_soc_top.u_cpu.dcache.request_buffer_op;
assign dcache_req_index   = u_soc_top.u_cpu.dcache.request_buffer_index;
assign dcache_req_offset  = u_soc_top.u_cpu.dcache.request_buffer_offset;
assign dcache_req_wdata   = u_soc_top.u_cpu.dcache.request_buffer_wdata;
assign dcache_write_index = u_soc_top.u_cpu.dcache.write_buffer_index;
assign dcache_write_offset= u_soc_top.u_cpu.dcache.write_buffer_offset;
assign dcache_write_wdata = u_soc_top.u_cpu.dcache.write_buffer_wdata;
assign dcache_write_way   = u_soc_top.u_cpu.dcache.write_buffer_way;
assign dcache_req_dcacop  = u_soc_top.u_cpu.dcache.request_buffer_dcacop;
assign dcache_req_cacop_mode = u_soc_top.u_cpu.dcache.request_buffer_cacop_op_mode;
assign dcache_way_d       = u_soc_top.u_cpu.dcache.way_d;
assign dcache_replace_way = u_soc_top.u_cpu.dcache.replace_way;
assign dcache_replace_d   = u_soc_top.u_cpu.dcache.replace_d;
assign dcache_replace_v   = u_soc_top.u_cpu.dcache.replace_v;
assign dcache_replace_tag = u_soc_top.u_cpu.dcache.replace_tag;
assign csr_da             = u_soc_top.u_cpu.csr_da;
assign csr_pg             = u_soc_top.u_cpu.csr_pg;
assign csr_dmw1           = u_soc_top.u_cpu.csr_dmw1;
`else
assign data_uncache_en    = 1'b0;
assign data_valid         = 1'b0;
assign data_op            = 1'b0;
assign data_addr_ok       = 1'b0;
assign data_index         = 8'b0;
assign data_tag           = 20'b0;
assign data_offset        = 4'b0;
assign data_wstrb         = 4'b0;
assign data_wdata         = 32'b0;
assign data_rd_addr       = 32'b0;
assign data_vaddr         = 32'b0;
assign data_wr_req        = 1'b0;
assign data_wr_addr       = 32'b0;
assign data_wr_data       = 128'b0;
assign dcache_main_state  = 5'b0;
assign dcache_cache_hit   = 1'b0;
assign dcache_way_hit     = 2'b0;
assign dcache_write_full  = 1'b0;
assign dcache_req_op      = 1'b0;
assign dcache_req_index   = 8'b0;
assign dcache_req_offset  = 4'b0;
assign dcache_req_wdata   = 32'b0;
assign dcache_write_index = 8'b0;
assign dcache_write_offset= 4'b0;
assign dcache_write_wdata = 32'b0;
assign dcache_write_way   = 2'b0;
assign dcache_req_dcacop  = 1'b0;
assign dcache_req_cacop_mode = 2'b0;
assign dcache_way_d       = 2'b0;
assign dcache_replace_way = 2'b0;
assign dcache_replace_d   = 1'b0;
assign dcache_replace_v   = 1'b0;
assign dcache_replace_tag = 20'b0;
assign csr_da             = 1'b0;
assign csr_pg             = 1'b0;
assign csr_dmw1           = 32'b0;
`endif

endmodule
