/* mycpu_tb_post_impl.v — Post-implementation timing simulation testbench.
 * Replaces XMR-based UART monitoring with physical UART_TX pin decoding
 * so it works with gate-level netlists where internal module signals are
 * renamed or optimized away.
 */
`timescale 1ns / 1ps
`include "config.h"

module tb_top_post_impl();
reg reset;
reg clk;
reg   [3:0]  touch_btn;
reg   [31:0]  dip_sw;

wire         UART_RX;
wire         UART_TX;
reg          uart_rx_drv;
wire  [2:0]  video_red;
wire  [2:0]  video_green;
wire  [1:0]  video_blue;
wire  video_hsync;
wire  video_vsync;
wire  video_clk;
wire  video_de;
wire  [15:0]  leds;
wire  [7:0]  dpy0;
wire  [7:0]  dpy1;
wire  [19:0]  base_ram_addr;
wire  [ 3:0]  base_ram_be_n;
wire  base_ram_ce_n;
wire  base_ram_oe_n;
wire  base_ram_we_n;
wire  [19:0]  ext_ram_addr;
wire  [ 3:0]  ext_ram_be_n;
wire  ext_ram_ce_n;
wire  ext_ram_oe_n;
wire  ext_ram_we_n;
wire  [31:0]  base_ram_data;
wire  [31:0]  ext_ram_data;

assign UART_RX = uart_rx_drv;

initial begin
    clk = 1'b0;
    reset = 1'b1;
    dip_sw = 32'h0;
    uart_rx_drv = 1'b1;
    #2000;
    reset = 1'b0;
end
always #10 clk=~clk;    // 50 MHz (matches PLL input clock constraint)

initial begin
    touch_btn = 4'h0;
    dip_sw    = 32'h0000_abcd;
    #3000000;
    #100000 touch_btn = 4'b0001; #50 touch_btn = 4'b0000;
    #100000 touch_btn = 4'b0010; #50 touch_btn = 4'b0000;
    #100000 touch_btn = 4'b0100; #50 touch_btn = 4'b0000;
    #100000 touch_btn = 4'b1000; #50 touch_btn = 4'b0000;
end

soc_top  u_soc_top (
    .clk                     ( clk           ),
    .reset                   ( reset         ),
    .touch_btn               ( touch_btn     ),
    .dip_sw                  ( dip_sw        ),
    .video_red               ( video_red     ),
    .video_green             ( video_green   ),
    .video_blue              ( video_blue    ),
    .video_hsync             ( video_hsync   ),
    .video_vsync             ( video_vsync   ),
    .video_clk               ( video_clk     ),
    .video_de                ( video_de      ),
    .leds                    ( leds          ),
    .dpy0                    ( dpy0          ),
    .dpy1                    ( dpy1          ),
    .base_ram_addr           ( base_ram_addr   ),
    .base_ram_be_n           ( base_ram_be_n   ),
    .base_ram_ce_n           ( base_ram_ce_n   ),
    .base_ram_oe_n           ( base_ram_oe_n   ),
    .base_ram_we_n           ( base_ram_we_n   ),
    .ext_ram_addr            ( ext_ram_addr    ),
    .ext_ram_be_n            ( ext_ram_be_n    ),
    .ext_ram_ce_n            ( ext_ram_ce_n    ),
    .ext_ram_oe_n            ( ext_ram_oe_n    ),
    .ext_ram_we_n            ( ext_ram_we_n    ),
    .base_ram_data           ( base_ram_data   ),
    .ext_ram_data            ( ext_ram_data    ),
    .UART_RX                 ( UART_RX       ),
    .UART_TX                 ( UART_TX       )
);

sram_sp #(
    .AW        ( 20     ),
    .Init_File ("none"),
    .Init_Plusarg("base_ram_mif=%s"))
base_sram_sp (
    .ram_addr                ( base_ram_addr   ),
    .ram_be_n                ( base_ram_be_n   ),
    .ram_ce_n                ( base_ram_ce_n   ),
    .ram_oe_n                ( base_ram_oe_n   ),
    .ram_we_n                ( base_ram_we_n   ),
    .ram_data                ( base_ram_data   )
);

sram_sp #(
    .AW        ( 20     ),
    .Init_File ("none"),
    .Init_Plusarg("ext_ram_mif=%s"))
ext_sram_sp (
    .ram_addr                ( ext_ram_addr   ),
    .ram_be_n                ( ext_ram_be_n   ),
    .ram_ce_n                ( ext_ram_ce_n   ),
    .ram_oe_n                ( ext_ram_oe_n   ),
    .ram_we_n                ( ext_ram_we_n   ),
    .ram_data                ( ext_ram_data   )
);

wire        ext_ram_write_fire = (ext_ram_ce_n === 1'b0) && (ext_ram_we_n === 1'b0);
wire [31:0] ext_ram_byte_addr  = {10'b0, ext_ram_addr, 2'b00};
wire [31:0] ext_ram_phys_addr  = 32'h1c400000 + ext_ram_byte_addr;
integer     ext_ram_write_count;
integer     ext_ram_write_limit;
reg         ext_ram_log_all;
reg         ext_ram_log_enable;
reg         ext_ram_log_range_enable;
reg         ext_ram_log_truncated;
reg  [31:0] ext_ram_log_start;
reg  [31:0] ext_ram_log_size;
reg  [31:0] ext_ram_log_end;
wire        ext_ram_write_in_log_range =
    !ext_ram_log_range_enable ||
    (ext_ram_byte_addr >= ext_ram_log_start &&
     ext_ram_byte_addr < ext_ram_log_end);

reg         compare_ext_enable;
reg         compare_ext_failed;
reg  [31:0] compare_ext_addr;
reg  [31:0] compare_ext_size;
reg  [31:0] compare_ext_end;
reg  [31:0] compare_mismatch_limit;
reg [8*1024-1:0] compare_ext_file;
reg  [7:0] compare_ext_data [0:4194303];
integer     compare_ext_fd;
integer     compare_ext_bytes;
integer     compare_ext_i;
integer     compare_mismatch_count;
reg  [31:0] compare_word;
reg  [7:0]  compare_actual;
localparam [1:0] TB_RUNNING = 2'd0;
localparam [1:0] TB_PASS    = 2'd1;
localparam [1:0] TB_FAIL    = 2'd2;
reg [1:0] tb_status;

task compare_ext_ram;
    begin
        compare_ext_failed = 1'b0;
        if (compare_ext_enable) begin
            compare_ext_fd = $fopen(compare_ext_file, "rb");
            if (compare_ext_fd == 0) begin
                $display("[TB] Compare FAIL: cannot open %0s", compare_ext_file);
                compare_ext_failed = 1'b1;
            end
            else begin
                compare_ext_bytes = $fread(compare_ext_data, compare_ext_fd);
                $fclose(compare_ext_fd);
                if (compare_ext_bytes <= 0) begin
                    $display("[TB] Compare FAIL: empty reference file %0s", compare_ext_file);
                    compare_ext_failed = 1'b1;
                end
                else if (compare_ext_size != 32'h0 && compare_ext_size < compare_ext_bytes) begin
                    compare_ext_bytes = compare_ext_size;
                end
                if (!compare_ext_failed) begin
                    compare_ext_end = compare_ext_addr + compare_ext_bytes;
                    if (compare_ext_addr >= 32'h00400000 ||
                        compare_ext_end > 32'h00400000 ||
                        compare_ext_end < compare_ext_addr) begin
                        $display("[TB] Compare FAIL: ExtRAM range 0x%08h..0x%08h is outside 4 MiB",
                                 compare_ext_addr, compare_ext_end);
                        compare_ext_failed = 1'b1;
                    end
                end
                if (!compare_ext_failed) begin
                    compare_mismatch_count = 0;
                    for (compare_ext_i = 0; compare_ext_i < compare_ext_bytes; compare_ext_i = compare_ext_i + 1) begin
                        compare_word = ext_sram_sp.BRAM[(compare_ext_addr + compare_ext_i) >> 2];
                        case ((compare_ext_addr + compare_ext_i) & 32'h3)
                            32'h0: compare_actual = compare_word[7:0];
                            32'h1: compare_actual = compare_word[15:8];
                            32'h2: compare_actual = compare_word[23:16];
                            default: compare_actual = compare_word[31:24];
                        endcase
                        if (compare_actual !== compare_ext_data[compare_ext_i]) begin
                            if (compare_mismatch_count < compare_mismatch_limit) begin
                                $display("[TB] Mismatch[%0d]: +0x%08h expected=0x%02h actual=0x%02h",
                                         compare_mismatch_count, compare_ext_i,
                                         compare_ext_data[compare_ext_i], compare_actual);
                            end
                            compare_mismatch_count = compare_mismatch_count + 1;
                        end
                    end
                    if (compare_mismatch_count == 0) begin
                        $display("[TB] Compare PASS: ExtRAM byte offset 0x%08h matches %0d bytes from %0s",
                                 compare_ext_addr, compare_ext_bytes, compare_ext_file);
                    end
                    else begin
                        $display("[TB] Compare FAIL: %0d mismatches in %0d bytes from %0s",
                                 compare_mismatch_count, compare_ext_bytes, compare_ext_file);
                        compare_ext_failed = 1'b1;
                    end
                end
            end
        end
    end
endtask

initial begin
    ext_ram_write_count = 0;
    ext_ram_write_limit = 2048;
    ext_ram_log_all = $test$plusargs("log_ext_ram_all");
    ext_ram_log_range_enable = $value$plusargs("log_ext_ram_addr=%h", ext_ram_log_start);
    ext_ram_log_enable = (ext_ram_log_all ||
                          $test$plusargs("log_ext_ram_write") ||
                          ext_ram_log_range_enable) &&
                         !$test$plusargs("no_ext_ram_write_log");
    ext_ram_log_truncated = 1'b0;
    if (!$value$plusargs("ext_ram_write_log_limit=%d", ext_ram_write_limit)) begin
        ext_ram_write_limit = 2048;
    end
    if (!$value$plusargs("log_ext_ram_size=%h", ext_ram_log_size)) begin
        ext_ram_log_size = 32'h4;
    end
    if (ext_ram_log_size == 32'h0) begin
        ext_ram_log_size = 32'h4;
    end
    if (ext_ram_log_range_enable &&
        ext_ram_log_start >= 32'h1c400000 &&
        ext_ram_log_start < 32'h1c800000) begin
        ext_ram_log_start = ext_ram_log_start - 32'h1c400000;
    end
    ext_ram_log_end = ext_ram_log_start + ext_ram_log_size;

    compare_ext_failed = 1'b0;
    compare_ext_addr = 32'h0;
    compare_ext_size = 32'h0;
    compare_mismatch_limit = 32'h10;
    compare_ext_enable = $value$plusargs("compare_ext_file=%s", compare_ext_file);
    if (!$value$plusargs("compare_ext_addr=%h", compare_ext_addr)) begin
        compare_ext_addr = 32'h0;
    end
    if (!$value$plusargs("compare_ext_size=%h", compare_ext_size)) begin
        compare_ext_size = 32'h0;
    end
    if (!$value$plusargs("compare_mismatch_limit=%d", compare_mismatch_limit)) begin
        compare_mismatch_limit = 32'h10;
    end
    if (compare_ext_addr >= 32'h1c400000 && compare_ext_addr < 32'h1c800000) begin
        compare_ext_addr = compare_ext_addr - 32'h1c400000;
    end
end

always @(posedge clk) begin
    if (reset) begin
        ext_ram_write_count <= 0;
        ext_ram_log_truncated <= 1'b0;
    end
    else if (ext_ram_log_enable && ext_ram_write_fire &&
             (ext_ram_log_all || ext_ram_write_in_log_range)) begin
        if (ext_ram_write_count < ext_ram_write_limit) begin
            $display("[EXT_W] t=%0t word_addr=%05h phys=%08h be=%b data=%08h",
                     $time, ext_ram_addr, ext_ram_phys_addr, ~ext_ram_be_n, ext_ram_data);
        end
        else if (!ext_ram_log_truncated) begin
            $display("[EXT_W] log truncated at %0d writes; use +ext_ram_write_log_limit=<N> to raise the limit",
                     ext_ram_write_limit);
            ext_ram_log_truncated <= 1'b1;
        end
        ext_ram_write_count <= ext_ram_write_count + 1;
    end
end

// ---------------------------------------------------------------------------
// UART TX monitor — decode the physical UART_TX pin instead of using XMRs
// ---------------------------------------------------------------------------
localparam integer UART_BIT_TIME = 4800;      // 50 MHz sys_clk, divisor 14, 208.3 kbaud
localparam integer UART_FAST_BIT_TIME = 640;

reg supervisor_fast_uart;
reg uart_rx_byte_valid;
reg [7:0] uart_rx_byte;           // bytes received from supervisor via UART_TX

// Detect start bit on UART_TX
reg        uart_tx_prev;
reg [15:0] uart_tx_low_count;      // count low cycles on UART_TX
reg [31:0] uart_bit_timer;
reg [ 3:0] uart_bit_idx;
reg        uart_rx_active;
reg [ 7:0] uart_rx_shift;

wire uart_rx_start_bit = uart_tx_prev && !UART_TX;  // falling edge = start bit

always @(posedge clk) begin
    uart_tx_prev <= UART_TX;
    uart_rx_byte_valid <= 1'b0;

    if (reset) begin
        uart_tx_low_count <= 0;
        uart_bit_timer <= 0;
        uart_rx_active <= 1'b0;
    end
    else if (uart_rx_active) begin
        uart_bit_timer <= uart_bit_timer + 1;
        // Sample at mid-bit: half of bit time + n * bit time
        if (uart_bit_timer == (UART_BIT_TIME / 2 + UART_BIT_TIME * uart_bit_idx)) begin
            if (uart_bit_idx < 8) begin
                uart_rx_shift[uart_bit_idx] = UART_TX;
            end
            uart_bit_idx <= uart_bit_idx + 1;
        end
        // Stop bit check
        if (uart_bit_idx == 8 && uart_bit_timer == (UART_BIT_TIME / 2 + UART_BIT_TIME * 8 + UART_BIT_TIME / 2)) begin
            uart_rx_active <= 1'b0;
            uart_rx_byte <= uart_rx_shift;
            uart_rx_byte_valid <= 1'b1;
        end
    end
    else if (uart_rx_start_bit) begin
        // Wait for start bit to stabilize (sample middle of start bit)
        if (uart_tx_low_count >= 10) begin
            uart_tx_low_count <= 0;
            uart_rx_active <= 1'b1;
            uart_bit_timer <= UART_BIT_TIME / 2;
            uart_bit_idx <= 0;
        end
        else begin
            uart_tx_low_count <= uart_tx_low_count + 1;
        end
    end
    else begin
        uart_tx_low_count <= 0;
    end
end

// UART TX (to supervisor) — physical UART_RX pin
localparam integer WELCOME_LEN = 38;
integer welcome_match;
reg [31:0] supervisor_g_addr;
reg supervisor_auto_enable;
reg supervisor_g_sent;
reg supervisor_program_started;
reg supervisor_a_enable;
reg [31:0] supervisor_a_addr;
reg [31:0] supervisor_a_words [0:1023];
reg [8*1024-1:0] supervisor_a_file;
integer supervisor_a_count;
integer supervisor_a_i;
integer supervisor_a_fd;

function [7:0] welcome_char;
    input integer idx;
    begin
        case (idx)
            0:  welcome_char = 8'h4d; // M
            1:  welcome_char = 8'h4f; // O
            2:  welcome_char = 8'h4e; // N
            3:  welcome_char = 8'h49; // I
            4:  welcome_char = 8'h54; // T
            5:  welcome_char = 8'h4f; // O
            6:  welcome_char = 8'h52; // R
            7:  welcome_char = 8'h20; //  
            8:  welcome_char = 8'h66; // f
            9:  welcome_char = 8'h6f; // o
            10: welcome_char = 8'h72; // r
            11: welcome_char = 8'h20; //  
            12: welcome_char = 8'h4c; // L
            13: welcome_char = 8'h6f; // o
            14: welcome_char = 8'h6f; // o
            15: welcome_char = 8'h6e; // n
            16: welcome_char = 8'h67; // g
            17: welcome_char = 8'h61; // a
            18: welcome_char = 8'h72; // r
            19: welcome_char = 8'h63; // c
            20: welcome_char = 8'h68; // h
            21: welcome_char = 8'h33; // 3
            22: welcome_char = 8'h32; // 2
            23: welcome_char = 8'h20; //  
            24: welcome_char = 8'h2d; // -
            25: welcome_char = 8'h20; //  
            26: welcome_char = 8'h69; // i
            27: welcome_char = 8'h6e; // n
            28: welcome_char = 8'h69; // i
            29: welcome_char = 8'h74; // t
            30: welcome_char = 8'h69; // i
            31: welcome_char = 8'h61; // a
            32: welcome_char = 8'h6c; // l
            33: welcome_char = 8'h69; // i
            34: welcome_char = 8'h7a; // z
            35: welcome_char = 8'h65; // e
            36: welcome_char = 8'h64; // d
            37: welcome_char = 8'h2e; // .
            default: welcome_char = 8'h00;
        endcase
    end
endfunction

task uart_send_byte;
    input [7:0] data;
    integer i;
    begin
        uart_rx_drv = 1'b0;
        #(UART_BIT_TIME);
        for (i = 0; i < 8; i = i + 1) begin
            uart_rx_drv = data[i];
            #(UART_BIT_TIME);
        end
        uart_rx_drv = 1'b1;
        #(UART_BIT_TIME);
    end
endtask

task uart_send_word_le;
    input [31:0] data;
    begin
        uart_send_byte(data[ 7: 0]);
        uart_send_byte(data[15: 8]);
        uart_send_byte(data[23:16]);
        uart_send_byte(data[31:24]);
    end
endtask

task supervisor_send_a_program;
    begin
        uart_send_byte(8'h41); // A
        uart_send_word_le(supervisor_a_addr);
        uart_send_word_le(supervisor_a_count * 4);
        for (supervisor_a_i = 0;
             supervisor_a_i < supervisor_a_count;
             supervisor_a_i = supervisor_a_i + 1) begin
            uart_send_word_le(supervisor_a_words[supervisor_a_i]);
        end
    end
endtask

task supervisor_send_g_command;
    begin
        #(20 * UART_BIT_TIME);
        $display("\n[TB] Send supervisor command: G 0x%08h", supervisor_g_addr);
        uart_send_byte(8'h47); // G
        uart_send_word_le(supervisor_g_addr);
    end
endtask

task supervisor_send_commands;
    begin
        if (supervisor_a_enable) begin
            #(20 * UART_BIT_TIME);
            $display("\n[TB] Send supervisor A command: %0d words at 0x%08h from %0s",
                     supervisor_a_count, supervisor_a_addr, supervisor_a_file);
            supervisor_send_a_program();
        end
        supervisor_send_g_command();
    end
endtask

initial begin
    tb_status = TB_RUNNING;
    welcome_match = 0;
    supervisor_a_enable = $value$plusargs("supervisor_a_file=%s", supervisor_a_file);
    if (!$value$plusargs("supervisor_a_addr=%h", supervisor_a_addr)) begin
        supervisor_a_addr = 32'h1c300000;
    end
    if (!$value$plusargs("supervisor_a_count=%d", supervisor_a_count)) begin
        supervisor_a_count = 0;
    end
    if (supervisor_a_enable) begin
        if (supervisor_a_count <= 0 || supervisor_a_count > 1024) begin
            tb_status = TB_FAIL;
            $fatal(1, "[TB] Invalid supervisor_a_count=%0d (valid range: 1..1024)",
                   supervisor_a_count);
        end
        supervisor_a_fd = $fopen(supervisor_a_file, "r");
        if (supervisor_a_fd == 0) begin
            tb_status = TB_FAIL;
            $fatal(1, "[TB] Cannot open supervisor A program: %0s", supervisor_a_file);
        end
        $fclose(supervisor_a_fd);
        $readmemh(supervisor_a_file, supervisor_a_words, 0, supervisor_a_count - 1);
        $display("[TB] Supervisor A program enabled: addr=0x%08h count=%0d file=%0s",
                 supervisor_a_addr, supervisor_a_count, supervisor_a_file);
    end
    supervisor_g_addr = 32'h0;
    supervisor_auto_enable = $value$plusargs("supervisor_entry=%h", supervisor_g_addr);
    if (supervisor_auto_enable) begin
        $display("[TB] Override supervisor G address: 0x%08h", supervisor_g_addr);
    end
    else if (supervisor_a_enable) begin
        supervisor_g_addr = supervisor_a_addr;
        supervisor_auto_enable = 1'b1;
    end
    supervisor_g_sent = 1'b0;
    supervisor_program_started = 1'b0;
end

reg [63:0] supervisor_max_time;
initial begin
    supervisor_max_time = 64'd200000000000;
    if ($value$plusargs("max_time=%d", supervisor_max_time)) begin
        $display("[TB] Simulation timeout: %0d ns", supervisor_max_time);
    end
    if (supervisor_max_time != 0) begin
        #(supervisor_max_time);
        if (tb_status == TB_RUNNING) begin
            tb_status = TB_FAIL;
            $fatal(1, "[TB] Simulation timed out after %0d ns", supervisor_max_time);
        end
    end
end

initial begin
    wait(supervisor_g_sent);
    supervisor_send_commands();
end

always @(posedge clk) begin
    if (uart_rx_byte_valid) begin
        if (uart_rx_byte == 8'hff) begin
            ; // $finish
        end
        else begin
            $write("%c", uart_rx_byte);
            if (supervisor_g_sent && uart_rx_byte == 8'h06) begin
                supervisor_program_started = 1'b1;
                $display("\n[TB] Supervisor program started.");
            end
            else if (supervisor_program_started && uart_rx_byte == 8'h07) begin
                $display("\n[TB] Supervisor program finished.");
                compare_ext_ram();
                $display("==============================================================");
                if (compare_ext_failed || tb_status == TB_FAIL) begin
                    tb_status = TB_FAIL;
                    $fatal(1, "Test failed!");
                end
                else begin
                    tb_status = TB_PASS;
                    $display("Test end!");
                    $finish;
                end
            end
            if (supervisor_auto_enable && !supervisor_g_sent) begin
                if (uart_rx_byte == welcome_char(welcome_match)) begin
                    welcome_match = welcome_match + 1;
                    if (welcome_match == WELCOME_LEN) begin
                        supervisor_g_sent = 1'b1;
                    end
                end
                else begin
                    welcome_match = (uart_rx_byte == welcome_char(0)) ? 1 : 0;
                end
            end
        end
    end
end

endmodule
