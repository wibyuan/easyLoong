`include "common.sv"

// axi_sram_direct — bypass the AXI CDC / crossbar / axi2sram chain for the
// async SRAM range (0x1c000000-0x1c7fffff), driving the BaseRAM/ExtRAM pins
// directly from the CPU clock domain with a fixed 2-cycle access (first word
// 2 cycles, back-to-back burst words 2 cycles each, no artificial latency).
// All other addresses (UART / confreg MMIO) are forwarded unchanged to the
// existing AXI CDC + crossbar path on the sys_clk side.
//
// The design assumes serialized transactions (one at a time): the caches
// issue at most one read or write burst at any moment.
module axi_sram_direct (
    input  logic       aclk,
    input  logic       aresetn,

    // ---- AXI4 slave (CPU master side, word-aligned INCR bursts) ----
    input  logic [3:0]  arid,
    input  logic [31:0] araddr,
    input  logic [7:0]  arlen,
    input  logic [2:0]  arsize,
    input  logic [1:0]  arburst,
    input  logic        arlock,
    input  logic [3:0]  arcache,
    input  logic [2:0]  arprot,
    input  logic        arvalid,
    output logic        arready,
    output logic [3:0]  rid,
    output logic [31:0] rdata,
    output logic [1:0]  rresp,
    output logic        rlast,
    output logic        rvalid,
    input  logic        rready,

    input  logic [3:0]  awid,
    input  logic [31:0] awaddr,
    input  logic [7:0]  awlen,
    input  logic [2:0]  awsize,
    input  logic [1:0]  awburst,
    input  logic        awlock,
    input  logic [3:0]  awcache,
    input  logic [2:0]  awprot,
    input  logic        awvalid,
    output logic        awready,
    input  logic [3:0]  wid,
    input  logic [31:0] wdata,
    input  logic [3:0]  wstrb,
    input  logic        wlast,
    input  logic        wvalid,
    output logic        wready,
    output logic [3:0]  bid,
    output logic [1:0]  bresp,
    output logic        bvalid,
    input  logic        bready,

    // ---- async SRAM pins ----
    output logic [19:0] base_ram_addr,
    output logic [3:0]  base_ram_be_n,
    output logic        base_ram_ce_n,
    output logic        base_ram_oe_n,
    output logic        base_ram_we_n,
    inout  wire  [31:0] base_ram_data,
    output logic [19:0] ext_ram_addr,
    output logic [3:0]  ext_ram_be_n,
    output logic        ext_ram_ce_n,
    output logic        ext_ram_oe_n,
    output logic        ext_ram_we_n,
    inout  wire  [31:0] ext_ram_data,

    // ---- MMIO AXI master (to the AXI CDC, 5-bit ids) ----
    output logic        mmio_arvalid,
    input  logic        mmio_arready,
    output logic [4:0]  mmio_arid,
    output logic [31:0] mmio_araddr,
    output logic [7:0]  mmio_arlen,
    output logic [2:0]  mmio_arsize,
    output logic [1:0]  mmio_arburst,
    output logic        mmio_arlock,
    output logic [3:0]  mmio_arcache,
    output logic [2:0]  mmio_arprot,
    input  logic [4:0]  mmio_rid,
    input  logic [31:0] mmio_rdata,
    input  logic [1:0]  mmio_rresp,
    input  logic        mmio_rlast,
    input  logic        mmio_rvalid,
    output logic        mmio_rready,
    output logic        mmio_awvalid,
    input  logic        mmio_awready,
    output logic [4:0]  mmio_awid,
    output logic [31:0] mmio_awaddr,
    output logic [7:0]  mmio_awlen,
    output logic [2:0]  mmio_awsize,
    output logic [1:0]  mmio_awburst,
    output logic        mmio_awlock,
    output logic [3:0]  mmio_awcache,
    output logic [2:0]  mmio_awprot,
    output logic        mmio_wvalid,
    input  logic        mmio_wready,
    output logic [4:0]  mmio_wid,
    output logic [31:0] mmio_wdata,
    output logic [3:0]  mmio_wstrb,
    output logic        mmio_wlast,
    input  logic [4:0]  mmio_bid,
    input  logic [1:0]  mmio_bresp,
    input  logic        mmio_bvalid,
    output logic        mmio_bready
);

    // ==================== Address decode ====================
    function automatic logic is_sram(input logic [31:0] a);
        return (a[31:24] == 8'h1c) && (a[23:22] != 2'b11);
    endfunction

    wire ar_sram = is_sram(araddr);
    wire aw_sram = is_sram(awaddr);

    // ==================== In-flight state ====================
    logic        r_mmio;                 // MMIO read accepted, awaiting rlast
    logic        w_mmio;                 // MMIO write accepted, awaiting b
    logic [31:0] r_addr;
    logic [7:0]  r_rem;
    logic [3:0]  r_id;
    logic        r_bank;
    logic [1:0]  rd_cnt;                 // 0 idle / 1 hold / 2 respond
    logic [31:0] w_addr;
    logic [31:0] w_data;
    logic [3:0]  w_strb;
    logic [7:0]  w_rem;
    logic [3:0]  w_id;
    logic        w_bank;
    logic [1:0]  wr_cnt;                 // 0 idle / 1 pins / 2 boundary

    wire idle_ar = (rd_cnt == 2'd0) && (wr_cnt == 2'd0) && !r_mmio && !w_mmio;
    // The arbiter serializes transactions; aw must only yield to an ar
    // accepted in the SAME cycle (the fetch presents arvalid nearly every
    // cycle, so gating on !arvalid would starve writes forever).
    wire ar_take = idle_ar && arvalid && (ar_sram || mmio_arready);

    // ==================== Accept handshakes ====================
    // The arbiter's write FSM asserts wvalid combinationally INSIDE its
    // "if (awready)" branch, so awready must not depend on wvalid (a
    // circular dependency would deadlock the first beat forever).
    assign arready = idle_ar ? (ar_sram || mmio_arready) : 1'b0;
    assign awready = (idle_ar && !ar_take)
                     ? (aw_sram || (mmio_awready && mmio_wready)) : 1'b0;
    assign wready  = (idle_ar && !ar_take)
                     ? (aw_sram || (mmio_awready && mmio_wready))
                     : ((wr_cnt == 2'd2) && (w_rem != 8'd0) && !w_mmio);

    wire ar_go = arvalid && arready;
    wire aw_go = awvalid && wvalid && awready;

    // ==================== MMIO forwarding ====================
    assign mmio_arvalid = idle_ar && arvalid && !ar_sram;
    assign mmio_araddr  = araddr;
    assign mmio_arlen   = arlen;
    assign mmio_arsize  = arsize;
    assign mmio_arburst = arburst;
    assign mmio_arlock  = arlock;
    assign mmio_arcache = arcache;
    assign mmio_arprot  = arprot;
    assign mmio_arid    = {1'b0, arid};
    assign mmio_rready  = rready;

    assign mmio_awvalid = (idle_ar && !ar_take) && awvalid && !aw_sram;
    assign mmio_awaddr  = awaddr;
    assign mmio_awlen   = awlen;
    assign mmio_awsize  = awsize;
    assign mmio_awburst = awburst;
    assign mmio_awlock  = awlock;
    assign mmio_awcache = awcache;
    assign mmio_awprot  = awprot;
    assign mmio_awid    = {1'b0, awid};
    assign mmio_wvalid  = (w_mmio || (idle_ar && !ar_take && awvalid && !aw_sram)) && wvalid;
    assign mmio_wdata   = wdata;
    assign mmio_wstrb   = wstrb;
    assign mmio_wlast   = wlast;
    assign mmio_wid     = {1'b0, wid};
    assign mmio_bready  = bready;

    // ==================== Response channels ====================
    wire sram_rresp = (rd_cnt == 2'd2) && !r_mmio;
    wire sram_bresp = (wr_cnt == 2'd2) && (w_rem == 8'd0) && !w_mmio;

    assign rvalid = r_mmio ? mmio_rvalid : sram_rresp;
    assign rdata  = r_mmio ? mmio_rdata  : (r_bank ? ext_ram_data : base_ram_data);
    assign rlast  = r_mmio ? mmio_rlast  : (r_rem == 8'd0);
    assign rid    = r_mmio ? mmio_rid[3:0] : r_id;
    assign rresp  = r_mmio ? mmio_rresp  : 2'b00;

    assign bvalid = w_mmio ? mmio_bvalid : sram_bresp;
    assign bid    = w_mmio ? mmio_bid[3:0] : w_id;
    assign bresp  = w_mmio ? mmio_bresp  : 2'b00;

    // ==================== SRAM pin drive ====================
    logic [19:0] ram_addr_out;
    logic [3:0]  ram_be_out;
    logic        ram_ce_out, ram_oe_out, ram_we_out;
    logic [31:0] ram_wdata_out;
    logic        ram_write_active;
    logic        bank_out;

    always_comb begin
        ram_addr_out    = 20'd0;
        ram_be_out      = 4'b0000;
        ram_ce_out      = 1'b1;
        ram_oe_out      = 1'b1;
        ram_we_out      = 1'b1;
        ram_wdata_out   = 32'd0;
        ram_write_active = 1'b0;
        bank_out        = 1'b0;
        if (rd_cnt != 2'd0) begin
            bank_out     = r_bank;
            ram_addr_out = r_addr[21:2];
            ram_be_out   = 4'b0000;
            ram_ce_out   = 1'b0;
            ram_oe_out   = 1'b0;
            ram_we_out   = 1'b1;
        end else if (wr_cnt != 2'd0) begin
            bank_out        = w_bank;
            ram_addr_out    = w_addr[21:2];
            ram_be_out      = ~w_strb;
            ram_ce_out      = 1'b0;
            ram_oe_out      = 1'b1;
            ram_we_out      = (wr_cnt == 2'd2) ? 1'b1 : 1'b0;
            ram_wdata_out   = w_data;
            ram_write_active = 1'b1;
        end else if (arvalid && ar_sram && idle_ar) begin
            bank_out        = araddr[22];
            ram_addr_out    = araddr[21:2];
            ram_be_out      = 4'b0000;
            ram_ce_out      = 1'b0;
            ram_oe_out      = 1'b0;
            ram_we_out      = 1'b1;
        end else if (awvalid && aw_sram && idle_ar && !ar_take) begin
            bank_out        = awaddr[22];
            ram_addr_out    = awaddr[21:2];
            ram_be_out      = ~wstrb;
            ram_ce_out      = 1'b0;
            ram_oe_out      = 1'b1;
            ram_we_out      = 1'b0;
            ram_wdata_out   = wdata;
            ram_write_active = 1'b1;
        end
    end

    always_comb begin
        base_ram_addr = ram_addr_out;
        base_ram_be_n = ram_be_out;
        base_ram_ce_n = ram_ce_out;
        base_ram_oe_n = ram_oe_out;
        base_ram_we_n = ram_we_out;
        ext_ram_addr  = ram_addr_out;
        ext_ram_be_n  = ram_be_out;
        ext_ram_ce_n  = ram_ce_out;
        ext_ram_oe_n  = ram_oe_out;
        ext_ram_we_n  = ram_we_out;
        if (bank_out) begin
            base_ram_ce_n = 1'b1;
        end else begin
            ext_ram_ce_n = 1'b1;
        end
    end

    assign base_ram_data = (bank_out == 1'b0 && ram_write_active) ? ram_wdata_out : 32'hz;
    assign ext_ram_data  = (bank_out == 1'b1 && ram_write_active) ? ram_wdata_out : 32'hz;

    // ==================== Sequential logic ====================
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            r_mmio <= 1'b0;
            w_mmio <= 1'b0;
            rd_cnt <= 2'd0;
            wr_cnt <= 2'd0;
            r_rem  <= 8'd0;
            w_rem  <= 8'd0;
        end else begin
            // ---- MMIO in-flight tracking ----
            if (ar_go && !ar_sram) begin
                r_mmio <= 1'b1;
                r_id   <= arid;
            end else if (r_mmio && rvalid && rready && rlast) begin
                r_mmio <= 1'b0;
            end
            if (aw_go && !aw_sram) begin
                w_mmio <= 1'b1;
                w_id   <= awid;
            end else if (w_mmio && bvalid && bready) begin
                w_mmio <= 1'b0;
            end

            // ---- SRAM read FSM ----
            if (ar_go && ar_sram) begin
                rd_cnt <= 2'd1;
                r_addr <= araddr;
                r_rem  <= arlen;
                r_id   <= arid;
                r_bank <= araddr[22];
            end else if (rd_cnt == 2'd1) begin
                rd_cnt <= 2'd2;
            end else if (rd_cnt == 2'd2) begin
                if (rready) begin
                    if (r_rem == 8'd0) begin
                        rd_cnt <= 2'd0;
                    end else begin
                        rd_cnt <= 2'd1;
                        r_addr <= r_addr + 32'd4;
                        r_rem  <= r_rem - 8'd1;
                    end
                end
            end

            // ---- SRAM write FSM ----
            if (aw_go && aw_sram) begin
                wr_cnt <= 2'd1;
                w_addr <= awaddr;
                w_data <= wdata;
                w_strb <= wstrb;
                w_rem  <= awlen;
                w_id   <= awid;
                w_bank <= awaddr[22];
            end else if (wr_cnt == 2'd1) begin
                wr_cnt <= 2'd2;
            end else if (wr_cnt == 2'd2) begin
                if (w_rem == 8'd0) begin
                    if (bready) begin
                        wr_cnt <= 2'd0;
                    end
                end else if (wvalid) begin
                    wr_cnt <= 2'd1;
                    w_addr <= w_addr + 32'd4;
                    w_data <= wdata;
                    w_strb <= wstrb;
                    w_rem  <= w_rem - 8'd1;
                end
            end
        end
    end

endmodule
