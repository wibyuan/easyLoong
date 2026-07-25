module thinpad_top (
    input           clk_50M,
    input           clk_11M0592,
    input           clock_btn,
    input           reset_btn,
    input  [3:0]    touch_btn,
    input  [31:0]   dip_sw,
    output [15:0]   leds,
    output [7:0]    dpy1,
    output [7:0]    dpy0,
    inout           txd,
    inout           rxd,
    inout  [31:0]   base_ram_data,
    output [19:0]   base_ram_addr,
    output          base_ram_ce_n,
    output          base_ram_oe_n,
    output          base_ram_we_n,
    output [3:0]    base_ram_be_n,
    inout  [31:0]   ext_ram_data,
    output [19:0]   ext_ram_addr,
    output          ext_ram_ce_n,
    output          ext_ram_oe_n,
    output          ext_ram_we_n,
    output [3:0]    ext_ram_be_n,

    output [2:0]    video_red,
    output [2:0]    video_green,
    output [1:0]    video_blue,
    output          video_hsync,
    output          video_vsync,
    output          video_clk,
    output          video_de
);

soc_top #(
    .SIMULATION(1'b0)
) u_soc_top (
    .clk            (clk_50M),
    .reset          (reset_btn),
    .video_red      (video_red),
    .video_green    (video_green),
    .video_blue     (video_blue),
    .video_hsync    (video_hsync),
    .video_vsync    (video_vsync),
    .video_clk      (video_clk),
    .video_de       (video_de),
    .touch_btn      (touch_btn),
    .dip_sw         (dip_sw),
    .leds           (leds),
    .dpy0           (dpy0),
    .dpy1           (dpy1),
    .base_ram_data  (base_ram_data),
    .base_ram_addr  (base_ram_addr),
    .base_ram_be_n  (base_ram_be_n),
    .base_ram_ce_n  (base_ram_ce_n),
    .base_ram_oe_n  (base_ram_oe_n),
    .base_ram_we_n  (base_ram_we_n),
    .ext_ram_data   (ext_ram_data),
    .ext_ram_addr   (ext_ram_addr),
    .ext_ram_be_n   (ext_ram_be_n),
    .ext_ram_ce_n   (ext_ram_ce_n),
    .ext_ram_oe_n   (ext_ram_oe_n),
    .ext_ram_we_n   (ext_ram_we_n),
    .UART_RX        (rxd),
    .UART_TX        (txd)
);

endmodule


