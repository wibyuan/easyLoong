`include "common.sv"

// axi_sram_direct — bypass the AXI CDC / crossbar / axi2sram chain for the
// async SRAM range (0x1c000000-0x1c7fffff), driving the BaseRAM/ExtRAM pins
// directly from the CPU clock domain.  All other addresses (UART / confreg
// MMIO) are forwarded unchanged to the existing AXI CDC + crossbar path.
//
// Write buffer: stores are accepted into a small FIFO (b fires on the
// accept, so the LSU retires in ~1 cycle) and drained to the async SRAM in
// the background with the 3-cycle write (address/data setup, WE pulse,
// hold — the real IS61WV102416 latches the address at the WE falling edge,
// zero setup corrupts write addresses on the board).  Loads are forwarded
// from the FIFO (newest store per byte wins): a load fully covered by
// pending stores completes in 1 cycle without touching the SRAM; a
// partially covered load reads the SRAM and merges the buffered bytes.
//
// Transactions are serialized by the arbiter (one read or write at a
// time); the LSU issues single-beat stores and loads only (no AXI write
// bursts in the no-dcache configuration).
module axi_sram_direct #(
    parameter int WB_DEPTH = 8
) (
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

    // ---- AR preview (from the arbiter): the pending read's address one
    // cycle before the accept, so the write-buffer full-cover flag is
    // precomputed into a register and arready never combinationally
    // depends on the 8-entry coverage search ----
    input  logic        ar_preview_valid,
    input  logic [31:0] ar_preview_addr,

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

    // ==================== Write buffer FIFO ====================
    localparam int WB_BITS = $clog2(WB_DEPTH);
    typedef struct packed {
        logic        valid;
        logic [31:0] addr;
        logic [31:0] data;
        logic [3:0]  be;
    } wb_entry_t;
    wb_entry_t          wb_q [WB_DEPTH];
    logic [WB_BITS-1:0] wb_head;        // oldest (drain side)
    logic [WB_BITS-1:0] wb_tail;        // next free (accept side)
    logic [WB_BITS:0]   wb_count;

    wire wb_full  = (wb_count == WB_DEPTH[WB_BITS:0]);
    wire wb_empty = (wb_count == 0);

    // ==================== In-flight state ====================
    logic        r_mmio;                 // MMIO read accepted, awaiting rlast
    logic        w_mmio;                 // MMIO write accepted, awaiting b
    logic [31:0] r_addr;
    logic [3:0]  r_id;
    logic        r_bank;
    logic [1:0]  rd_cnt;                 // 0 idle / 1 forward / 2 SRAM respond
    logic [31:0] w_addr;                 // drain context (head entry)
    logic [31:0] w_data;
    logic [3:0]  w_strb;
    logic        w_bank;
    logic [1:0]  wr_cnt;                 // 0 idle / 1 setup / 2 pulse / 3 hold
    logic        wb_push_b;              // b for the buffered store
    logic [3:0]  w_id;

    wire idle_ar = (rd_cnt == 2'd0) && !r_mmio && !w_mmio;
    wire ar_take = arvalid && arready;

    // ==================== Read forwarding from the write buffer ==========
    // Per-byte coverage and the newest-store data for a read address.
    // The search walks the FIFO from the newest entry (tail-1) down to the
    // oldest (head); a newer store to the same byte wins.
    // The search runs on the arbiter's preview address in R_IDLE (one
    // cycle before the accept) so the full-cover flag is a register by
    // the time arready is evaluated; the accept-time captures (wb_*_r)
    // always re-run the search on araddr, so they see the fresh state —
    // a stale preview only biases the full-forward-vs-SRAM decision, and
    // both paths produce correct data.
    logic [31:0] search_addr;
    // The accept-time search re-runs on the REGISTERED preview address
    // (the accept always follows its preview exactly one cycle later with
    // the same address — the arbiter's read FSM holds the request until
    // the accept), never on the combinational araddr: the LSU/arbiter
    // address muxes (slot0/slot1 select, DMW translation, icache-vs-LSU
    // select) must stay off the search->pin-drive accept chain (impl
    // critical family: ex_mem1.mem_addr -> those muxes -> the coverage
    // search -> bank_out_r/ram_addr_out_r, worst -0.339ns).  Zero-IPC:
    // the address value is identical, only its source is registered.
    logic [31:0] ar_preview_addr_r;
    always_ff @(posedge aclk) begin
        if (ar_preview_valid)
            ar_preview_addr_r <= ar_preview_addr;
    end
    assign search_addr = (rd_cnt == 2'd1) ? r_addr
                        : (ar_preview_valid ? ar_preview_addr : ar_preview_addr_r);

    logic [3:0]  wb_cover_ar;
    logic [31:0] wb_fwd_ar;
    logic        wb_full_pre_r;
    always_ff @(posedge aclk) begin
        if (!aresetn)
            wb_full_pre_r <= 1'b0;
        else if (ar_preview_valid)
            wb_full_pre_r <= (wb_cover_ar == 4'hf);
    end
    // Line-based coverage for the read RESPONSE: the 16-byte line's
    // per-byte coverage and forwarded data.  Captured at rd_cnt==1 (from
    // the registered r_addr) for the rd_cnt==2 SRAM-merge response —
    // entirely off the accept path.  The fully-forwarded response at
    // rd_cnt==1 uses the word-level captures below.  All requests here
    // are single-beat (the LSU and the icache issue arlen==0 only), so
    // the response's word always equals the accepted word.
    logic [15:0]  wb_cover_line;
    logic [127:0] wb_fwd_line;
    logic [15:0]  wb_cover_line_r;
    logic [127:0] wb_fwd_line_r;
    // Word-level coverage (the accepted word), captured at the accept for
    // the fully-forwarded response at rd_cnt==1.  Its D-side is the
    // shallow 4-byte word search, not the 16-byte line priority chain.
    logic [3:0]  wb_cover_w_r;
    logic [31:0] wb_fwd_w_r;
    logic        wb_full_w_r;
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            wb_cover_w_r    <= 4'd0;
            wb_fwd_w_r      <= 32'd0;
            wb_full_w_r     <= 1'b0;
            wb_cover_line_r <= 16'd0;
            wb_fwd_line_r   <= 128'd0;
        end else begin
            if (ar_go && ar_sram) begin
                wb_cover_w_r <= wb_cover_ar;
                wb_fwd_w_r   <= wb_fwd_ar;
                wb_full_w_r  <= (wb_cover_ar == 4'hf);
            end
            if (rd_cnt == 2'd1) begin
                wb_cover_line_r <= wb_cover_line;
                wb_fwd_line_r   <= wb_fwd_line;
            end
        end
    end
    wire [1:0]  r_word = r_addr[3:2];
    wire [3:0]  wb_cover_r = wb_cover_line_r[r_word*4 +: 4];
    wire [31:0] wb_fwd_r   = wb_fwd_line_r[r_word*32 +: 32];
    wire wb_full_ar = (wb_cover_ar == 4'hf);
    wire [31:0] wb_cover_r_byte = {{8{wb_cover_r[3]}}, {8{wb_cover_r[2]}},
                                   {8{wb_cover_r[1]}}, {8{wb_cover_r[0]}}};

    always_comb begin
        wb_cover_ar   = 4'd0;
        wb_fwd_ar     = 32'd0;
        wb_cover_line = 16'd0;
        wb_fwd_line   = 128'd0;
        for (int i = 0; i < WB_DEPTH; i++) begin
            automatic logic [WB_BITS-1:0] idx;
            idx = wb_tail - 1 - i[WB_BITS-1:0];
            if (i[WB_BITS:0] < wb_count && wb_q[idx].valid) begin
                // ---- AR address (word coverage for the accept) ----
                if (wb_q[idx].addr[31:2] == search_addr[31:2]) begin
                    if (wb_q[idx].be[0] && !wb_cover_ar[0]) begin wb_cover_ar[0] = 1'b1; wb_fwd_ar[7:0] = wb_q[idx].data[7:0]; end
                    if (wb_q[idx].be[1] && !wb_cover_ar[1]) begin wb_cover_ar[1] = 1'b1; wb_fwd_ar[15:8] = wb_q[idx].data[15:8]; end
                    if (wb_q[idx].be[2] && !wb_cover_ar[2]) begin wb_cover_ar[2] = 1'b1; wb_fwd_ar[23:16] = wb_q[idx].data[23:16]; end
                    if (wb_q[idx].be[3] && !wb_cover_ar[3]) begin wb_cover_ar[3] = 1'b1; wb_fwd_ar[31:24] = wb_q[idx].data[31:24]; end
                end
                // ---- AR address (line coverage for the response) ----
                if (wb_q[idx].addr[31:4] == search_addr[31:4]) begin
                    if (wb_q[idx].addr[3:2] == 2'd0) begin
                        if (wb_q[idx].be[0] && !wb_cover_line[0])  begin wb_cover_line[0]  = 1'b1; wb_fwd_line[7:0]   = wb_q[idx].data[7:0];   end
                        if (wb_q[idx].be[1] && !wb_cover_line[1])  begin wb_cover_line[1]  = 1'b1; wb_fwd_line[15:8]  = wb_q[idx].data[15:8];  end
                        if (wb_q[idx].be[2] && !wb_cover_line[2])  begin wb_cover_line[2]  = 1'b1; wb_fwd_line[23:16] = wb_q[idx].data[23:16]; end
                        if (wb_q[idx].be[3] && !wb_cover_line[3])  begin wb_cover_line[3]  = 1'b1; wb_fwd_line[31:24] = wb_q[idx].data[31:24]; end
                    end else if (wb_q[idx].addr[3:2] == 2'd1) begin
                        if (wb_q[idx].be[0] && !wb_cover_line[4])  begin wb_cover_line[4]  = 1'b1; wb_fwd_line[39:32] = wb_q[idx].data[7:0];   end
                        if (wb_q[idx].be[1] && !wb_cover_line[5])  begin wb_cover_line[5]  = 1'b1; wb_fwd_line[47:40] = wb_q[idx].data[15:8];  end
                        if (wb_q[idx].be[2] && !wb_cover_line[6])  begin wb_cover_line[6]  = 1'b1; wb_fwd_line[55:48] = wb_q[idx].data[23:16]; end
                        if (wb_q[idx].be[3] && !wb_cover_line[7])  begin wb_cover_line[7]  = 1'b1; wb_fwd_line[63:56] = wb_q[idx].data[31:24]; end
                    end else if (wb_q[idx].addr[3:2] == 2'd2) begin
                        if (wb_q[idx].be[0] && !wb_cover_line[8])  begin wb_cover_line[8]  = 1'b1; wb_fwd_line[71:64] = wb_q[idx].data[7:0];   end
                        if (wb_q[idx].be[1] && !wb_cover_line[9])  begin wb_cover_line[9]  = 1'b1; wb_fwd_line[79:72] = wb_q[idx].data[15:8];  end
                        if (wb_q[idx].be[2] && !wb_cover_line[10]) begin wb_cover_line[10] = 1'b1; wb_fwd_line[87:80] = wb_q[idx].data[23:16]; end
                        if (wb_q[idx].be[3] && !wb_cover_line[11]) begin wb_cover_line[11] = 1'b1; wb_fwd_line[95:88] = wb_q[idx].data[31:24]; end
                    end else begin
                        if (wb_q[idx].be[0] && !wb_cover_line[12]) begin wb_cover_line[12] = 1'b1; wb_fwd_line[103:96]  = wb_q[idx].data[7:0];   end
                        if (wb_q[idx].be[1] && !wb_cover_line[13]) begin wb_cover_line[13] = 1'b1; wb_fwd_line[111:104] = wb_q[idx].data[15:8];  end
                        if (wb_q[idx].be[2] && !wb_cover_line[14]) begin wb_cover_line[14] = 1'b1; wb_fwd_line[119:112] = wb_q[idx].data[23:16]; end
                        if (wb_q[idx].be[3] && !wb_cover_line[15]) begin wb_cover_line[15] = 1'b1; wb_fwd_line[127:120] = wb_q[idx].data[31:24]; end
                    end
                end
            end
        end
    end

    // ==================== Accept handshakes ====================
    // The arbiter's write FSM asserts wvalid combinationally INSIDE its
    // "if (awready)" branch, so awready must not depend on wvalid (a
    // circular dependency would deadlock the first beat forever).
    // A fully-forwarded read needs no SRAM pins and is accepted even while
    // the drain owns them; a partial/SRAM read yields to the drain.
    assign arready = idle_ar
        ? (ar_sram ? (wb_full_pre_r || (wr_cnt == 2'd0)) : mmio_arready) : 1'b0;
    assign awready = (idle_ar && !ar_take)
                     ? (aw_sram ? !wb_full : (mmio_awready && mmio_wready)) : 1'b0;
    assign wready  = (idle_ar && !ar_take)
                     ? (aw_sram ? !wb_full : (mmio_awready && mmio_wready)) : 1'b0;

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
    // Forwarded read responds at rd_cnt==1 (no SRAM access); a partial or
    // non-forwarded read responds at rd_cnt==2 with the SRAM data merged
    // with the buffered bytes.
    wire sram_fwd_resp = (rd_cnt == 2'd1) && wb_full_w_r && !r_mmio;
    wire sram_rd_resp  = (rd_cnt == 2'd2) && !r_mmio;
    wire sram_bresp    = wb_push_b && !w_mmio;

    assign rvalid = r_mmio ? mmio_rvalid : (sram_fwd_resp || sram_rd_resp);
    assign rlast  = r_mmio ? mmio_rlast  : 1'b1;
    assign rid    = r_mmio ? mmio_rid[3:0] : r_id;
    assign rresp  = r_mmio ? mmio_rresp  : 2'b00;
    assign rdata  = r_mmio ? mmio_rdata
                 : (sram_fwd_resp ? wb_fwd_w_r
                    : ((r_bank ? ext_ram_data : base_ram_data) & ~wb_cover_r_byte)
                      | (wb_fwd_r & wb_cover_r_byte));

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
        if (rd_cnt != 2'd0 && !(rd_cnt == 2'd1 && wb_full_w_r)) begin
            // SRAM read in flight (a fully-forwarded read needs no pins and
            // must NOT override the drain's in-progress write: asserting
            // the read address/OE mid-write glitches the WE pulse and
            // corrupts the SRAM write on the board).
            bank_out     = r_bank;
            ram_addr_out = r_addr[21:2];
            ram_be_out   = 4'b0000;
            ram_ce_out   = 1'b0;
            ram_oe_out   = 1'b0;
            ram_we_out   = 1'b1;
        end else if (wr_cnt != 2'd0) begin
            // Drain: 3-cycle write (setup / pulse / hold).  The real async
            // SRAM latches the address/data at the WE falling edge; WE must
            // not assert in the same cycle as the address (zero tAS/tSD
            // corrupts write addresses on the board).
            bank_out        = w_bank;
            ram_addr_out    = w_addr[21:2];
            ram_be_out      = ~w_strb;
            ram_ce_out      = 1'b0;
            ram_oe_out      = 1'b1;
            ram_we_out      = (wr_cnt == 2'd2) ? 1'b0 : 1'b1;
            ram_wdata_out   = w_data;
            ram_write_active = 1'b1;
        end else if (arvalid && ar_sram && idle_ar && !wb_full_ar && (wr_cnt == 2'd0)) begin
            // SRAM read accept: drive the pins
            bank_out        = araddr[22];
            ram_addr_out    = araddr[21:2];
            ram_be_out      = 4'b0000;
            ram_ce_out      = 1'b0;
            ram_oe_out      = 1'b0;
            ram_we_out      = 1'b1;
        end
    end

    always_comb begin
        base_ram_addr = ram_addr_out_r;
        base_ram_be_n = ram_be_out_r;
        base_ram_ce_n = ram_ce_out_r;
        base_ram_oe_n = ram_oe_out_r;
        base_ram_we_n = ram_we_out_r;
        ext_ram_addr  = ram_addr_out_r;
        ext_ram_be_n  = ram_be_out_r;
        ext_ram_ce_n  = ram_ce_out_r;
        ext_ram_oe_n  = ram_oe_out_r;
        ext_ram_we_n  = ram_we_out_r;
        if (bank_out_r) begin
            base_ram_ce_n = 1'b1;
        end else begin
            ext_ram_ce_n = 1'b1;
        end
    end

    // The data-bus tri-state select is precomputed one cycle ahead: the
    // bank/write-active AND of the drive mux is captured here so the 32
    // IOB tri-state enables (OBUFT T) read a single register instead of
    // the combinational AND (and its bank_out/write_active fanouts) — the
    // T path to the IOBs then starts at a register (pattern per
    // Wubian111/Wubian_la32r_cpu MemoryIO.v).  The bus is driven one cycle
    // later than the raw AND, still fully inside the registered write
    // window (WE pulses in the drain's cycle 2, data on the bus through
    // the WE's falling edge), so the SRAM's tSD/tDH margins hold.
    logic base_ram_sel_r, ext_ram_sel_r;
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            base_ram_sel_r <= 1'b0;
            ext_ram_sel_r  <= 1'b0;
        end else begin
            base_ram_sel_r <= (bank_out == 1'b0 && ram_write_active);
            ext_ram_sel_r  <= (bank_out == 1'b1 && ram_write_active);
        end
    end
    assign base_ram_data = base_ram_sel_r ? ram_wdata_out_r : 32'hz;
    assign ext_ram_data  = ext_ram_sel_r  ? ram_wdata_out_r : 32'hz;

    // ==================== Registered pin drive ====================
    // The SRAM pins are captured from the combo drive muxes at every edge
    // so they switch deterministically at the clock edge instead of
    // tracking the request/drain combinational logic (the write-buffer
    // FIFO read mux and the forwarding search make the raw drive path too
    // deep for 100MHz: ~19 logic levels to the OBUFT).  The pins are
    // stable for a full cycle before the SRAM's tAA/tWP measurement:
    //   read  : address at pins from cycle 1, sampled at rd_cnt==2 — the
    //           data capture edge is unchanged, the 2-cycle access holds
    //   write : address/data at pins from cycle 1 (setup), WE pulses in
    //           cycle 2, hold in cycle 3 — the background drain just
    //           completes one cycle later, bvalid already fired at accept
    logic [19:0] ram_addr_out_r;
    logic [3:0]  ram_be_out_r;
    logic        ram_ce_out_r, ram_oe_out_r, ram_we_out_r;
    logic [31:0] ram_wdata_out_r;
    logic        ram_write_active_r;
    logic        bank_out_r;
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            ram_addr_out_r     <= 20'd0;
            ram_be_out_r       <= 4'b0000;
            ram_ce_out_r       <= 1'b1;
            ram_oe_out_r       <= 1'b1;
            ram_we_out_r       <= 1'b1;
            ram_wdata_out_r    <= 32'd0;
            ram_write_active_r <= 1'b0;
            bank_out_r         <= 1'b0;
        end else begin
            ram_addr_out_r     <= ram_addr_out;
            ram_be_out_r       <= ram_be_out;
            ram_ce_out_r       <= ram_ce_out;
            ram_oe_out_r       <= ram_oe_out;
            ram_we_out_r       <= ram_we_out;
            ram_wdata_out_r    <= ram_wdata_out;
            ram_write_active_r <= ram_write_active;
            bank_out_r         <= bank_out;
        end
    end

    // ==================== Sequential logic ====================
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            r_mmio    <= 1'b0;
            w_mmio    <= 1'b0;
            rd_cnt    <= 2'd0;
            wr_cnt    <= 2'd0;
            wb_head   <= '0;
            wb_tail   <= '0;
            wb_count  <= '0;
            wb_push_b <= 1'b0;
            for (int i = 0; i < WB_DEPTH; i++)
                wb_q[i] <= '0;
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

            // ---- Write buffer: accept + push (b fires on the accept) ----
            if (aw_go && aw_sram) begin
                wb_q[wb_tail].addr  <= awaddr;
                wb_q[wb_tail].data  <= wdata;
                wb_q[wb_tail].be    <= wstrb;
                wb_q[wb_tail].valid <= 1'b1;
                wb_tail  <= wb_tail + 1'b1;
                // The push can coincide with the drain's dequeue (a store
                // accepted while the drain completes the last entry): the
                // count must net both, or the pushed entry is excluded from
                // the count and silently never drained.
                wb_count <= wb_count + 1'b1
                            - ((wr_cnt == 2'd3) ? 1'b1 : 1'b0);
                wb_push_b <= 1'b1;
                w_id     <= awid;
            end else if (wr_cnt == 2'd3) begin
                wb_count <= wb_count - 1'b1;
            end
            if (wb_push_b && bready) begin
                wb_push_b <= 1'b0;
            end

            // ---- Drain: dequeue the head into the 3-cycle write ----
            // The drain must not start in the same cycle a read is
            // accepted: the read's arready sees wr_cnt==0 (drain not yet
            // started) while the drain's start sees rd_cnt==0 (read not
            // yet accepted) — both start together and the read's pins
            // override the write's WE pulse, silently dropping the write.
            if (wr_cnt == 2'd0 && !wb_empty && rd_cnt == 2'd0 && !ar_go
                && !r_mmio && !w_mmio) begin
                wr_cnt <= 2'd1;
                w_addr <= wb_q[wb_head].addr;
                w_data <= wb_q[wb_head].data;
                w_strb <= wb_q[wb_head].be;
                w_bank <= wb_q[wb_head].addr[22];
            end else if (wr_cnt == 2'd1) begin
                wr_cnt <= 2'd2;
            end else if (wr_cnt == 2'd2) begin
                wr_cnt <= 2'd3;
            end else if (wr_cnt == 2'd3) begin
                // count update is handled together with the push (above):
                // a push coinciding with this dequeue must net both.
                wb_q[wb_head].valid <= 1'b0;
                wb_head  <= wb_head + 1'b1;
                wr_cnt   <= 2'd0;
            end

            // ---- SRAM read FSM (with the write-buffer forwarding) ----
            // Single-beat only: every requester here issues arlen==0 (the
            // LSU's burst_len is hardwired to 0 and the icache is always
            // single-beat), so r_addr is captured once and rlast is always
            // 1 — there is no burst advance, which keeps r_addr's D-side
            // (araddr, CE = ar_go) and reset trivially clean.
            if (ar_go && ar_sram) begin
                rd_cnt <= 2'd1;
                r_addr <= araddr;
                r_id   <= arid;
                r_bank <= araddr[22];
            end else if (rd_cnt == 2'd1) begin
                if (wb_full_w_r) begin
                    // fully forwarded: respond now, no SRAM access
                    if (rready) begin
                        rd_cnt <= 2'd0;
                    end
                end else begin
                    rd_cnt <= 2'd2;
                end
            end else if (rd_cnt == 2'd2) begin
                if (rready) begin
                    rd_cnt <= 2'd0;
                end
            end
        end
    end

endmodule
