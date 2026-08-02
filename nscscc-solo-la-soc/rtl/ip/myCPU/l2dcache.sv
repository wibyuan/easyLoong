`include "common.sv"

// 1MB-class L2 dcache: all storage (data/tag/dirty/PLRU) in BRAM so the
// tag depth (16384 sets) does not blow up LUTRAM/mux trees.  The hit path
// is a 2-stage pipeline: the request cycle issues the tag + data reads and
// latches the request (p_*), the response cycle compares the registered
// tag and answers (data_ok + data same cycle), so every cacheable access
// costs one extra cycle (the L1 holds the request).
// The cpu port is now driven by the L1 dcache's mem port: the L1 refills
// its line word-by-word and writes back word-by-word, so every request is
// a single-word transaction (burst_len ignored).  Load responses also
// assert rdata_ok (read-channel data valid) so the L1's beat collection /
// keyword forwarding works exactly as it did against the AXI arbiter.
// Coherence with the L1 is write-back / write-allocate at both levels:
// the L1 refills from here, L1 evictions write back here, and this level
// drains to memory; a line is never modified while a stale L1 copy of it
// can hold newer data because L1 evictions always pass through here.
// The cacop request is gated (in core_top) on the L1's cacop completion
// so a dirty L1 line is merged into this level before its writeback to
// memory during a flush walk.
module l2dcache import la32_common::*; (
    input  logic       clk,
    input  logic       reset,

    input  dbus_req_t  cpu_req,
    output dbus_resp_t cpu_resp,

    output dbus_req_t  mem_req,
    input  dbus_resp_t mem_resp,

    input  cacop_req_t cacop_req,
    output logic       cacop_done,

    output logic [63:0] perf_access,
    output logic [63:0] perf_hit,
    output logic [63:0] perf_miss,
    output logic [63:0] perf_writeback,
    output logic [63:0] perf_fast_load,
    output logic [63:0] perf_fast_hum,

    output logic        in_refill
);

    parameter int NR_SETS = 256;
    parameter int NR_WAYS = 4;
    parameter int NR_WORDS = 4;
    localparam WORD_WIDTH  = $clog2(NR_WORDS);
    localparam LINE_OFFSET = WORD_WIDTH + 2;
    localparam WOFF_MASK   = (LINE_OFFSET > 2) ? ((1 << (LINE_OFFSET - 2)) - 1) : 0;
    localparam INDEX_WIDTH = $clog2(NR_SETS);
    localparam TAG_WIDTH   = 32 - LINE_OFFSET - INDEX_WIDTH;
    localparam WAY_BITS    = $clog2(NR_WAYS);
    localparam CNT_WIDTH   = (NR_WORDS == 1) ? 1 : WORD_WIDTH;

    typedef logic [WORD_WIDTH-1:0] woffset_t;
    typedef logic [INDEX_WIDTH-1:0] index_t;
    typedef logic [TAG_WIDTH-1:0] tag_t;
    typedef logic [WAY_BITS-1:0] way_t;

    // ==================== Data BRAM ====================
    index_t      data_rd_addr;
    logic [31:0] data_rd_out [0:NR_WAYS-1][0:NR_WORDS-1];
    logic        data_wr_ena;
    way_t        data_wr_way;
    index_t      data_wr_addr;
    woffset_t    data_wr_wo;
    logic [3:0]  data_wr_we;
    logic [31:0] data_wr_data;

    // Data array as per-way x per-word ram_sdpram instances: a single
    // in-module array would be 4x16384x4x32 = 8M bits, over Vivado
    // 2019.2's 1M-bit variable limit (Synth 8-4556); the per-instance
    // arrays are 512K bits each.  The registered read samples
    // data_rd_addr at the same edge as the tag/dirty ram_sdpram ports.
    generate
        for (genvar gw = 0; gw < NR_WAYS; gw++) begin : g_data_way
            for (genvar gb = 0; gb < NR_WORDS; gb++) begin : g_data_word
                logic wen;
                assign wen = data_wr_ena && (data_wr_way == way_t'(gw))
                             && (data_wr_wo == woffset_t'(gb));
                ram_sdpram #(
                    .ADDR_WIDTH(INDEX_WIDTH),
                    .DATA_WIDTH(32),
                    .BYTE_WIDTH(8),
                    .READ_LATENCY(1)
                ) u_data_ram (
                    .clk,
                    .raddr(data_rd_addr),
                    .waddr(data_wr_addr),
                    .en(wen),
                    .strobe(data_wr_we),
                    .wdata(data_wr_data),
                    .rdata(data_rd_out[gw][gb])
                );
            end
        end
    endgenerate

    // ==================== Tag BRAM (registered read) ====================
    index_t      tag_rd_addr;
    logic [TAG_WIDTH:0] tag_rd_data [0:NR_WAYS-1];
    logic        tag_wr_ena;
    way_t        tag_wr_way;
    index_t      tag_wr_addr;
    logic [TAG_WIDTH:0] tag_wr_data;

    generate
        for (genvar gw = 0; gw < NR_WAYS; gw++) begin : g_tag_way
            logic tag_wen;
            assign tag_wen = tag_wr_ena && (tag_wr_way == way_t'(gw));
            ram_sdpram #(
                .ADDR_WIDTH(INDEX_WIDTH),
                .DATA_WIDTH(TAG_WIDTH + 1),
                .BYTE_WIDTH(TAG_WIDTH + 1),
                .READ_LATENCY(1)
            ) u_tag_ram (
                .clk,
                .raddr(tag_rd_addr),
                .waddr(tag_wr_addr),
                .en(tag_wen),
                .strobe(1'b1),
                .wdata(tag_wr_data),
                .rdata(tag_rd_data[gw])
            );
        end
    endgenerate

    // ==================== Dirty BRAM ====================
    index_t dirty_rd_addr;
    logic   dirty_rd_data [0:NR_WAYS-1];
    logic   dirty_wr_ena;
    way_t   dirty_wr_way;
    index_t dirty_wr_addr;
    logic   dirty_wr_data;

    generate
        for (genvar gw = 0; gw < NR_WAYS; gw++) begin : g_dirty_way
            logic dwen;
            assign dwen = dirty_wr_ena && (dirty_wr_way == way_t'(gw));
            ram_sdpram #(
                .ADDR_WIDTH(INDEX_WIDTH),
                .DATA_WIDTH(1),
                .BYTE_WIDTH(1),
                .READ_LATENCY(1)
            ) u_dirty_ram (
                .clk,
                .raddr(dirty_rd_addr),
                .waddr(dirty_wr_addr),
                .en(dwen),
                .strobe(1'b1),
                .wdata(dirty_wr_data),
                .rdata(dirty_rd_data[gw])
            );
        end
    endgenerate

    // ==================== PLRU BRAM (NR_WAYS-1 tree nodes) ====================
    index_t plru_rd_addr;
    logic   plru_rd_data [0:NR_WAYS-2];
    logic   plru_wr_ena  [0:NR_WAYS-2];
    index_t plru_wr_addr;
    logic   plru_wr_data [0:NR_WAYS-2];

    generate
        for (genvar gn = 0; gn < NR_WAYS-1; gn++) begin : g_plru_node
            ram_sdpram #(
                .ADDR_WIDTH(INDEX_WIDTH),
                .DATA_WIDTH(1),
                .BYTE_WIDTH(1),
                .READ_LATENCY(1)
            ) u_plru_ram (
                .clk,
                .raddr(plru_rd_addr),
                .waddr(plru_wr_addr),
                .en(plru_wr_ena[gn]),
                .strobe(1'b1),
                .wdata(plru_wr_data[gn]),
                .rdata(plru_rd_data[gn])
            );
        end
    endgenerate

    // ==================== State ====================
    enum logic [3:0] {
        S_INIT,
        S_IDLE,
        S_UNCACHED,
        S_MISS,
        S_WB_READ, S_WB_WRITE,
        S_REFILL_REQ, S_REFILL_WAIT, S_REFILL_WRITE,
        // One settling cycle after the refill's last data write: a request
        // for the refilled line held during the refill (p_refilling) is
        // answered at S_IDLE from the registered data read, which was
        // issued at the last in_refill cycle — the SAME cycle as the last
        // word's write.  The read-first RAM returns the pre-write value
        // for that word (observed: word 3 of a line answered as 0).  The
        // extra cycle lets the read see the completed line.
        S_REFILL_DONE,
        S_CACOP_ST,
        S_CACOP_WB_READ, S_CACOP_WB_WRITE, S_CACOP_INV
    } state, next_state;

    dbus_req_t mem_req_next;
    dbus_req_t mem_req_r;

    // ==================== Request pipeline (2-stage fast path) ====================
    // REQ stage: issue tag/data/dirty/plru reads for the request index and
    // latch the request; RESP stage (one cycle later): compare the
    // registered tag and answer / start the miss.
    logic       p_valid;
    word_t      p_addr;
    logic       p_op;
    msize_t     p_size;
    logic [3:0] p_strobe;
    word_t      p_data;
    logic       p_cacheable;

    wire index_t   p_idx  = p_addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET];
    wire tag_t     p_tag  = p_addr[31:INDEX_WIDTH+LINE_OFFSET];
    wire woffset_t p_wo   = woffset_t'((p_addr >> 2) & WOFF_MASK);

    // ==================== RESP-stage combinational hit ====================
    logic p_hit_any;
    way_t p_hit_way;
    logic p_hit;

    always_comb begin
        automatic logic [NR_WAYS-1:0] hit_vec;
        hit_vec = '0;
        for (int w = 0; w < NR_WAYS; w++)
            hit_vec[w] = tag_rd_data[w][0]
                && (tag_rd_data[w][TAG_WIDTH:1] == p_tag)
                && is_cachable(p_addr, p_cacheable);
        p_hit_any = |hit_vec;
        p_hit = p_valid && p_hit_any;
        p_hit_way = '0;
        for (int w = 0; w < NR_WAYS; w++)
            if (hit_vec[w]) p_hit_way = way_t'(w);
    end

    // PLRU victim (registered read, valid in the RESP stage).
    function automatic way_t victim_way();
        automatic int node = 0;
        for (int b = WAY_BITS-1; b >= 0; b--) begin
            victim_way[b] = plru_rd_data[node];
            node = 2*node + 1 + int'(plru_rd_data[node]);
        end
    endfunction

    // ==================== Miss context ====================
    logic       m_op;
    woffset_t   m_wo;
    index_t     m_idx;
    tag_t       m_tag;
    way_t       m_eway;
    logic       m_edirty;
    tag_t       m_etag;
    word_t      m_wdata;
    logic [3:0] m_wstrb;

    logic        st_merge_pending;
    woffset_t    st_merge_wo;
    word_t       st_merge_data;
    logic [3:0]  st_merge_strb;

    // ==================== Work registers ====================
    logic [CNT_WIDTH-1:0] wb_cnt;
    logic [CNT_WIDTH-1:0] rf_cnt;
    logic [CNT_WIDTH-1:0] rf_wr_cnt;
    logic [NR_WORDS-1:0]  rf_fmask;
    logic                 rf_kw_sent;
    word_t                rf_buf [0:NR_WORDS-1];
    word_t                wb_buf [0:NR_WORDS-1];

    way_t                 cacop_way;
    index_t               cacop_idx;
    tag_t                 cacop_etag;
    logic [CNT_WIDTH-1:0] cacop_wb_cnt;
    word_t                cacop_wb_buf [0:NR_WORDS-1];

    wire [31:0] cacop_wb_addr;
    generate
        if (WORD_WIDTH > 0) begin : g_cacop_wb_addr
            assign cacop_wb_addr = {cacop_etag, cacop_idx,
                                    cacop_wb_cnt[WORD_WIDTH-1:0], 2'b00};
        end else begin : g_cacop_wb_addr_1w
            assign cacop_wb_addr = {cacop_etag, cacop_idx, 2'b00};
        end
    endgenerate

    index_t init_addr;
    way_t   init_wr_way;

    // ==================== Helper functions ====================
    function automatic logic is_cachable(input word_t a, input logic c);
        return c && (a[31:24] == 8'h1c);
    endfunction

    // ==================== Refill status ====================
    assign in_refill = state inside {S_MISS, S_WB_READ, S_WB_WRITE,
                                     S_REFILL_REQ, S_REFILL_WAIT, S_REFILL_WRITE,
                                     S_REFILL_DONE};

    wire cacop_d_pending = cacop_req.valid && (cacop_req.code[2:0] == 3'd1);
    // The line being refilled must not be served as a normal hit (its data
    // RAM is only partially written while its tag can already match).
    wire p_refilling = (p_idx == m_idx) && (p_hit_way == m_eway) && in_refill;
    wire p_hum_hit    = p_hit && in_refill && !p_refilling;
    // Read-back store to the refilling line: merge into the refill write.
    // S_REFILL_DONE is excluded: the refill's write window (S_REFILL_WRITE)
    // has already closed, so a store whose RESP stage lands there would set
    // st_merge_pending without anyone ever consuming it (the clear only
    // runs in S_REFILL_WRITE) and the stale merge would corrupt the NEXT
    // refill's line.  Such a store keeps p_valid and re-hits in S_IDLE.
    wire p_st_merge   = p_valid && in_refill && p_op
        && (state != S_REFILL_DONE)
        && (p_idx == m_idx) && (p_tag == m_tag)
        && ((state != S_REFILL_WRITE) || (rf_wr_cnt < p_wo))
        && !st_merge_pending;

    // No hit-under-miss while the keyword of an outstanding load miss is
    // forwarded (the pipeline is stalled on that load anyway).
    wire hum_keyword = (state inside {S_WB_WRITE, S_REFILL_WAIT})
                       && mem_resp.rdata_ok
                       && (rf_cnt == m_wo) && !rf_kw_sent && (m_op == 1'b0);
    // Refill complete when all beats arrived (mask full, possibly during
    // the writeback drain) or the current beat completes the mask.
    wire refill_fmask_done = (&rf_fmask) ||
                             (mem_resp.rdata_ok && (&(rf_fmask | (1 << rf_cnt))));
    // A request can be latched in S_IDLE or during a refill (hit-under-miss),
    // but never while another request is in the RESP stage, during cacop,
    // during the keyword forward, or in S_REFILL_WRITE when the write port
    // is owned by the refill (store hits are deferred to S_IDLE).  S_MISS is
    // excluded: the data RAM read port is busy that cycle issuing the
    // victim's line read for the writeback capture (S_WB_READ samples
    // data_rd_out one cycle later), so a hum request latched here would
    // steal the read and the writeback would drain the wrong line.
    wire p_capture_ok = !p_valid && !cacop_d_pending && !hum_keyword
                        && ((state == S_IDLE) ||
                            (in_refill && (state != S_MISS)
                             && (p_op ? (state != S_REFILL_WRITE) : 1'b1)));

    // ==================== RESP response ====================

    always_comb begin
        cpu_resp.addr_ok  = 1'b0;
        cpu_resp.data_ok  = 1'b0;
        cpu_resp.rdata_ok = 1'b0;
        cpu_resp.data     = 32'd0;
        cpu_resp.data_last = 1'b0;

        if (p_valid && !in_refill && (state == S_IDLE)) begin
            // Fast path: hit answered with data same cycle (both reads were
            // issued in the REQ cycle); load miss gets addr_ok only (data via
            // the keyword forward), store miss completes immediately.
            if (p_hit) begin
                cpu_resp.addr_ok = 1'b1;
                cpu_resp.data_ok = 1'b1;
                if (!p_op) begin
                    cpu_resp.rdata_ok = 1'b1;
                    cpu_resp.data = data_rd_out[p_hit_way][p_wo];
                end
            end else if (is_cachable(p_addr, p_cacheable)) begin
                cpu_resp.addr_ok = 1'b1;
                if (p_op)
                    cpu_resp.data_ok = 1'b1;
            end
        end

        if (p_valid && in_refill) begin
            // Hit-under-miss: hits to other lines served (loads always,
            // stores when the write port is free — a store whose RESP stage
            // lands in S_REFILL_WRITE is refused and re-hits in S_IDLE once
            // the refill completes, because the data write port is owned by
            // the refill that cycle); refill-line stores merge.
            if (p_st_merge) begin
                cpu_resp.addr_ok = 1'b1;
                cpu_resp.data_ok = 1'b1;
            end else if (p_hum_hit
                         && (p_op ? (state != S_REFILL_WRITE) : 1'b1)) begin
                cpu_resp.addr_ok = 1'b1;
                cpu_resp.data_ok = 1'b1;
                if (!p_op) begin
                    cpu_resp.rdata_ok = 1'b1;
                    cpu_resp.data = data_rd_out[p_hit_way][p_wo];
                end
            end
        end

        if (state == S_UNCACHED && mem_resp.data_ok) begin
            cpu_resp.addr_ok = 1'b1;
            cpu_resp.data_ok = 1'b1;
            cpu_resp.rdata_ok = !p_op;
            cpu_resp.data    = mem_resp.data;
        end

        if ((state inside {S_WB_WRITE, S_REFILL_WAIT}) && mem_resp.rdata_ok
            && !(&rf_fmask)
            && rf_cnt == m_wo && !rf_kw_sent && m_op == 1'b0) begin
            cpu_resp.addr_ok  = 1'b1;
            cpu_resp.data_ok  = 1'b1;
            cpu_resp.rdata_ok = 1'b1;
            cpu_resp.data     = mem_resp.data;
        end
    end

    // ==================== FSM combinational ====================
    always_comb begin
        next_state = state;

        cacop_done = 1'b0;

        mem_req_next.valid  = 1'b0;
        mem_req_next.addr   = 32'd0;
        mem_req_next.size   = MSIZE4;
        mem_req_next.strobe = 4'd0;
        mem_req_next.data   = 32'd0;
        mem_req_next.burst_len = 2'd0;

        data_wr_ena  = 1'b0;
        data_wr_way  = '0;
        data_wr_addr = '0;
        data_wr_wo   = '0;
        data_wr_we   = 4'd0;
        data_wr_data = 32'd0;

        tag_wr_ena  = 1'b0;
        tag_wr_way  = '0;
        tag_wr_addr = '0;
        tag_wr_data = '0;

        case (state)

            S_INIT: begin
                // Clear tag + dirty + PLRU in one walk (NR_SETS*NR_WAYS
                // cycles); all BRAM write ports write in parallel (PLRU
                // nodes are re-cleared per way iteration, harmless).
                tag_wr_ena   = 1'b1;
                tag_wr_way   = init_wr_way;
                tag_wr_addr  = init_addr;
                tag_wr_data  = '0;
                if (init_wr_way == NR_WAYS - 1 && init_addr == NR_SETS - 1)
                    next_state = S_IDLE;
            end

            S_IDLE: begin
                if (cacop_req.valid && cacop_req.code[2:0] == 3'd1 && !p_valid) begin
                    if (cacop_req.code[4:3] == 2'b00)
                        next_state = S_CACOP_ST;
                    else if (cacop_req.code[4:3] == 2'b01)
                        next_state = S_CACOP_WB_READ;
                end else if (p_capture_ok && cpu_req.valid) begin
                    if (!is_cachable(cpu_req.addr, cpu_req.cacheable))
                        next_state = S_UNCACHED;   // uncached: answer in S_UNCACHED
                    // else: REQ stage, response in the RESP stage (p_valid)
                end else if (p_valid) begin
                    // RESP stage: hit or miss
                    if (p_hit) begin
                        if (p_op) begin
                            data_wr_ena  = 1'b1;
                            data_wr_way  = p_hit_way;
                            data_wr_addr = p_idx;
                            data_wr_wo   = p_wo;
                            data_wr_we   = p_strobe;
                            data_wr_data = p_data;
                        end
                    end else if (is_cachable(p_addr, p_cacheable)) begin
                        next_state = S_MISS;
                    end
                end
            end

            S_UNCACHED: begin
                if (mem_resp.data_ok) begin
                    next_state = S_IDLE;
                end else if (!mem_resp.addr_ok) begin
                    mem_req_next.valid  = 1'b1;
                    mem_req_next.addr   = {p_addr[31:2], 2'b00};
                    mem_req_next.strobe = p_op ? p_strobe : 4'd0;
                    mem_req_next.data   = p_data;
                end
            end

            S_MISS: begin
                next_state = m_edirty ? S_WB_READ : S_REFILL_REQ;
            end

            S_WB_READ: begin
                next_state = S_REFILL_REQ;
            end

            S_WB_WRITE: begin
                mem_req_next.valid  = 1'b1;
                mem_req_next.addr   = {m_etag, m_idx, {WORD_WIDTH{1'b0}}, 2'b00};
                mem_req_next.strobe = 4'b1111;
                mem_req_next.data   = wb_buf[wb_cnt];
                mem_req_next.burst_len = NR_WORDS - 1;
                if (mem_resp.addr_ok)
                    next_state = (wb_cnt == NR_WORDS - 1) ? S_REFILL_WAIT : S_WB_WRITE;
            end

            S_REFILL_REQ: begin
                mem_req_next.valid  = 1'b1;
                mem_req_next.addr   = {m_tag, m_idx, {WORD_WIDTH{1'b0}}, 2'b00};
                mem_req_next.burst_len = NR_WORDS - 1;
                if (mem_resp.addr_ok)
                    next_state = m_edirty ? S_WB_WRITE : S_REFILL_WAIT;
            end

            S_REFILL_WAIT: begin
                if (refill_fmask_done)
                    next_state = S_REFILL_WRITE;
            end

            S_REFILL_WRITE: begin
                data_wr_ena  = 1'b1;
                data_wr_way  = m_eway;
                data_wr_addr = m_idx;
                data_wr_wo   = rf_wr_cnt;
                if (st_merge_pending && rf_wr_cnt == st_merge_wo) begin
                    // Merge the read-back store into the refilled word: the
                    // whole word is written so rf_buf's other bytes survive
                    // (writing only the store's bytes would leave the BRAM's
                    // pre-refill value in the remaining lanes).
                    data_wr_we = 4'b1111;
                    for (int b = 0; b < 4; b++)
                        data_wr_data[b*8 +: 8] = st_merge_strb[b]
                            ? st_merge_data[b*8 +: 8]
                            : rf_buf[rf_wr_cnt][b*8 +: 8];
                end else if (m_op && rf_wr_cnt == m_wo) begin
                    // Same for the accepted store miss's own word.
                    data_wr_we = 4'b1111;
                    for (int b = 0; b < 4; b++)
                        data_wr_data[b*8 +: 8] = m_wstrb[b]
                            ? m_wdata[b*8 +: 8]
                            : rf_buf[rf_wr_cnt][b*8 +: 8];
                end else begin
                    data_wr_we   = 4'b1111;
                    data_wr_data = rf_buf[rf_wr_cnt];
                end
                if (rf_wr_cnt == 0) begin
                    tag_wr_ena  = 1'b1;
                    tag_wr_way  = m_eway;
                    tag_wr_addr = m_idx;
                    tag_wr_data = {m_tag, 1'b1};
                end
                next_state = (rf_wr_cnt == NR_WORDS - 1)
                    ? S_REFILL_DONE
                    : S_REFILL_WRITE;
            end

            S_REFILL_DONE: begin
                next_state = S_IDLE;
            end

            S_CACOP_ST: begin
                tag_wr_ena  = 1'b1;
                tag_wr_way  = cacop_way;
                tag_wr_addr = cacop_idx;
                tag_wr_data = '0;
                cacop_done  = 1'b1;
                next_state  = S_IDLE;
            end

            S_CACOP_WB_READ: begin
                // The cacop request cycle issued the tag/dirty/data reads;
                // their registered outputs are valid now.
                next_state = dirty_rd_data[cacop_way] ? S_CACOP_WB_WRITE : S_CACOP_INV;
            end

            S_CACOP_WB_WRITE: begin
                mem_req_next.valid  = 1'b1;
                mem_req_next.addr   = cacop_wb_addr;
                mem_req_next.strobe = 4'b1111;
                mem_req_next.data   = cacop_wb_buf[cacop_wb_cnt];
                if (mem_resp.addr_ok)
                    next_state = (cacop_wb_cnt == NR_WORDS - 1) ? S_CACOP_INV : S_CACOP_WB_WRITE;
            end

            S_CACOP_INV: begin
                tag_wr_ena  = 1'b1;
                tag_wr_way  = cacop_way;
                tag_wr_addr = cacop_idx;
                tag_wr_data = '0;
                cacop_done  = 1'b1;
                next_state  = S_IDLE;
            end

            default: next_state = S_IDLE;
        endcase

        // Hit-under-miss store hit: write port free in every state except
        // S_REFILL_WRITE (where the port is owned by the refill — a hum
        // store whose RESP stage lands there is refused and re-hits in
        // S_IDLE once the refill completes; without the gate the hum
        // store would overwrite the refill's write and drop a word of
        // the refilled line).  PLRU/dirty are updated in the dirty/PLRU
        // write-control block on the same p_hum_hit condition.
        if (p_valid && in_refill && p_hum_hit && p_op
            && (state != S_REFILL_WRITE)) begin
            data_wr_ena  = 1'b1;
            data_wr_way  = p_hit_way;
            data_wr_addr = p_idx;
            data_wr_wo   = p_wo;
            data_wr_we   = p_strobe;
            data_wr_data = p_data;
        end
    end

    // ==================== BRAM read control ====================
    // Reads are issued one cycle before the output is consumed.  The REQ
    // stage issues tag/data/dirty/plru reads for the request index; the
    // RESP stage consumes them.  S_MISS issues the victim data read for the
    // writeback capture (S_WB_READ samples data_rd_out one cycle later);
    // cacop issues its tag/dirty/data reads one cycle before
    // S_CACOP_WB_READ.
    always_comb begin
        data_rd_addr  = '0;
        tag_rd_addr   = '0;
        dirty_rd_addr = '0;
        plru_rd_addr  = '0;

        // REQ stage (S_IDLE or in-refill hum request): read the request
        // index (also the cacop index when a cacop is being taken).
        if ((state == S_IDLE) && !p_valid && cacop_req.valid
            && (cacop_req.code[2:0] == 3'd1)) begin
            data_rd_addr  = cacop_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET];
            tag_rd_addr   = cacop_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET];
            dirty_rd_addr = cacop_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET];
        end else if (p_capture_ok && cpu_req.valid
                     && is_cachable(cpu_req.addr, cpu_req.cacheable)) begin
            data_rd_addr  = cpu_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET];
            tag_rd_addr   = cpu_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET];
            dirty_rd_addr = cpu_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET];
            plru_rd_addr  = cpu_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET];
        end else if (p_valid && in_refill) begin
            // Hit-under-miss: keep the request's read addresses live so
            // the registered outputs (tag/data) are not displaced by the
            // intermediate refill states before the RESP answer.
            data_rd_addr  = p_idx;
            tag_rd_addr   = p_idx;
            dirty_rd_addr = p_idx;
            plru_rd_addr  = p_idx;
        end else if (p_valid && (state == S_IDLE)) begin
            // RESP stage: keep the REQ stage's read addresses live until
            // the response is consumed.
            data_rd_addr  = p_idx;
            tag_rd_addr   = p_idx;
            dirty_rd_addr = p_idx;
            plru_rd_addr  = p_idx;
        end else if (state inside {S_CACOP_WB_READ, S_CACOP_WB_WRITE}) begin
            // Keep the cacop line's reads live through the writeback drain
            // (the data capture in S_CACOP_WB_WRITE samples data_rd_out).
            data_rd_addr  = cacop_idx;
            tag_rd_addr   = cacop_idx;
            dirty_rd_addr = cacop_idx;
        end else if (state == S_MISS) begin
            data_rd_addr = m_idx;
        end
    end

    // ==================== Sequential logic ====================
    always_ff @(posedge clk) begin
        if (reset) begin
            state       <= S_INIT;
            p_valid     <= 1'b0;
            p_addr      <= 32'd0;
            p_op        <= 1'b0;
            p_size      <= MSIZE4;
            p_strobe    <= 4'd0;
            p_data      <= 32'd0;
            p_cacheable <= 1'b0;
            rf_fmask    <= '0;
            wb_cnt      <= '0;
            rf_cnt      <= '0;
            rf_wr_cnt   <= '0;
            rf_kw_sent  <= 1'b0;
            m_wdata     <= 32'd0;
            m_wstrb     <= 4'd0;
            st_merge_pending <= 1'b0;
            st_merge_wo      <= '0;
            st_merge_data    <= 32'd0;
            st_merge_strb    <= 4'd0;
            mem_req_r   <= '{valid: 1'b0, addr: 32'd0, size: MSIZE4, strobe: 4'd0, data: 32'd0, cacheable: 1'b0, burst_len: 2'd0};
            init_addr    <= '0;
            init_wr_way  <= '0;
        end else begin
            state <= next_state;
            mem_req_r <= mem_req_next;

            if (state == S_INIT) begin
                if (init_wr_way == NR_WAYS - 1)
                    init_addr <= init_addr + 1;
                init_wr_way <= init_wr_way + 1;
            end

            // REQ stage capture: latch the request and the miss/uncached
            // context is decided in the RESP stage.
            if (p_capture_ok && cpu_req.valid) begin
                p_valid     <= 1'b1;
                p_addr      <= cpu_req.addr;
                p_op        <= |cpu_req.strobe;
                p_size      <= cpu_req.size;
                p_strobe    <= cpu_req.strobe;
                p_data      <= cpu_req.data;
                p_cacheable <= cpu_req.cacheable;
            end else if (!in_refill && (state == S_IDLE) && p_valid) begin
                // RESP stage consumed: clear.  (HUM misses keep p_valid so
                // the LSU re-presents; p_valid clears when the request is
                // answered or a miss/uncached flow starts.)
                p_valid <= 1'b0;
            end else if (p_valid && in_refill && p_st_merge) begin
                p_valid <= 1'b0;
            end else if (p_valid && in_refill && p_hum_hit
                         && (p_op ? (state != S_REFILL_WRITE) : 1'b1)) begin
                // A store refused in S_REFILL_WRITE (write port owned by
                // the refill) keeps p_valid and re-hits in S_IDLE.
                p_valid <= 1'b0;
            end

            // Miss context capture (RESP stage of a fast-path miss).
            if (p_valid && !in_refill && (state == S_IDLE)
                && !p_hit && is_cachable(p_addr, p_cacheable)
                && next_state == S_MISS) begin
                m_op     <= p_op;
                m_wo     <= p_wo;
                m_idx    <= p_idx;
                m_tag    <= p_tag;
                m_eway   <= victim_way();
                m_edirty <= dirty_rd_data[victim_way()];
                m_etag   <= tag_rd_data[victim_way()][TAG_WIDTH:1];
                m_wdata  <= p_data;
                m_wstrb  <= p_strobe;
            end

            if (state == S_IDLE && cacop_req.valid
                && cacop_req.code[2:0] == 3'd1 && !p_valid) begin
                cacop_way <= cacop_req.addr[WAY_BITS-1:0];
                cacop_idx <= cacop_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET];
                if (cacop_req.code[4:3] == 2'b01)
                    cacop_wb_cnt <= '0;
            end

            if (state == S_CACOP_WB_READ) begin
                cacop_etag      <= tag_rd_data[cacop_way][TAG_WIDTH:1];
                for (int n = 0; n < NR_WORDS; n++)
                    cacop_wb_buf[n] <= data_rd_out[cacop_way][n];
            end

            if (state == S_UNCACHED && mem_resp.data_ok)
                p_valid <= 1'b0;

            if (next_state == S_REFILL_REQ) begin
                rf_cnt     <= '0;
                rf_fmask   <= '0;
                rf_kw_sent <= 1'b0;
            end

            if (state == S_MISS && next_state == S_WB_READ)
                wb_cnt <= '0;

            if (state == S_WB_READ) begin
                for (int n = 0; n < NR_WORDS; n++)
                    wb_buf[n] <= data_rd_out[m_eway][n];
            end

            if (state == S_WB_WRITE && mem_resp.addr_ok)
                wb_cnt <= wb_cnt + 1;

            if ((state inside {S_WB_WRITE, S_REFILL_WAIT}) && mem_resp.rdata_ok
                && !(&rf_fmask)) begin
                rf_buf[rf_cnt]       <= mem_resp.data;
                rf_fmask[rf_cnt]     <= 1'b1;
                if (rf_cnt == m_wo && !rf_kw_sent && m_op == 1'b0)
                    rf_kw_sent <= 1'b1;
                rf_cnt <= rf_cnt + 1;
            end

            if (state == S_REFILL_WAIT && next_state == S_REFILL_WRITE)
                rf_wr_cnt <= '0;

            if (state == S_REFILL_WRITE) begin
                rf_wr_cnt <= rf_wr_cnt + 1;
                if (rf_wr_cnt == NR_WORDS - 1)
                    st_merge_pending <= 1'b0;
            end

            if (p_st_merge) begin
                st_merge_pending <= 1'b1;
                st_merge_wo      <= p_wo;
                st_merge_data    <= p_data;
                st_merge_strb    <= p_strobe;
            end

            if (state == S_CACOP_WB_WRITE && mem_resp.addr_ok) begin
                cacop_wb_cnt <= cacop_wb_cnt + 1;
            end
        end
    end

    // The registered request (mem_req_r) lags the FSM's combinational
    // mem_req_next by one cycle, so it would stay asserted for one extra
    // cycle after the FSM leaves the presenting state.  An idle bus (the
    // memory model / AXI arbiter) samples that phantom request as a NEW
    // transaction: after a writeback burst it re-writes the line with the
    // last word's data at word 0 and zero-fills the remaining words
    // (observed: word 0 of the evicted line corrupted with the keyword).
    // Gate the registered valid with the states that actually present.
    assign mem_req.valid = mem_req_r.valid
        && (state inside {S_UNCACHED, S_WB_WRITE, S_REFILL_REQ, S_CACOP_WB_WRITE});
    assign mem_req.addr      = mem_req_r.addr;
    assign mem_req.size      = mem_req_r.size;
    assign mem_req.strobe    = mem_req_r.strobe;
    assign mem_req.data      = mem_req_r.data;
    assign mem_req.cacheable = mem_req_r.cacheable;
    assign mem_req.burst_len = mem_req_r.burst_len;

    // ==================== Dirty/PLRU write control ====================
    // Single combinational driver for both write ports: S_INIT clear,
    // cacop invalidate, fast-path hit update and refill completion update.
    // (They were previously split across the FSM comb block and the
    // sequential block, which the DRC flagged as multiple drivers.)
    always_comb begin
        dirty_wr_ena  = 1'b0;
        dirty_wr_way  = '0;
        dirty_wr_addr = '0;
        dirty_wr_data = 1'b0;
        plru_wr_ena  = '{default: 1'b0};
        plru_wr_addr = '0;
        plru_wr_data = '{default: 1'b0};

        if (state == S_INIT) begin
            dirty_wr_ena  = 1'b1;
            dirty_wr_way  = init_wr_way;
            dirty_wr_addr = init_addr;
            dirty_wr_data = 1'b0;
            for (int gn = 0; gn < NR_WAYS-1; gn++)
                plru_wr_ena[gn] = 1'b1;
            plru_wr_addr = init_addr;
            plru_wr_data = '{default: 1'b0};
        end

        if (state == S_CACOP_INV) begin
            dirty_wr_ena  = 1'b1;
            dirty_wr_way  = cacop_way;
            dirty_wr_addr = cacop_idx;
            dirty_wr_data = 1'b0;
        end

        // Fast-path hit update (RESP stage): the PLRU tree path from the
        // root to the hit way is written with ~way[b] at each node.
        if (p_valid && !in_refill && (state == S_IDLE) && p_hit) begin
            begin : g_plru_hit_upd
                automatic int node = 0;
                for (int b = WAY_BITS-1; b >= 0; b--) begin
                    plru_wr_ena[node] = 1'b1;
                    plru_wr_data[node] = ~p_hit_way[b];
                    node = 2*node + 1 + int'(p_hit_way[b]);
                end
            end
            plru_wr_addr = p_idx;
            if (p_op) begin
                dirty_wr_ena  = 1'b1;
                dirty_wr_way  = p_hit_way;
                dirty_wr_addr = p_idx;
                dirty_wr_data = 1'b1;
            end
        end

        // Hit-under-miss hit update: same PLRU/dirty semantics as the
        // fast-path hit, applied in the RESP stage while a refill is in
        // flight.  Without the dirty update a hum store hit would leave
        // the line marked clean and the eviction writeback would silently
        // drop the store's data.  A store refused in S_REFILL_WRITE (see
        // the response block) is not updated here — it re-hits and is
        // accounted for by the S_IDLE fast path.
        if (p_valid && in_refill && p_hum_hit
            && (p_op ? (state != S_REFILL_WRITE) : 1'b1)) begin
            begin : g_plru_hum_upd
                automatic int node = 0;
                for (int b = WAY_BITS-1; b >= 0; b--) begin
                    plru_wr_ena[node] = 1'b1;
                    plru_wr_data[node] = ~p_hit_way[b];
                    node = 2*node + 1 + int'(p_hit_way[b]);
                end
            end
            plru_wr_addr = p_idx;
            if (p_op) begin
                dirty_wr_ena  = 1'b1;
                dirty_wr_way  = p_hit_way;
                dirty_wr_addr = p_idx;
                dirty_wr_data = 1'b1;
            end
        end

        if (state == S_REFILL_WRITE && rf_wr_cnt == NR_WORDS - 1) begin
            dirty_wr_ena  = 1'b1;
            dirty_wr_way  = m_eway;
            dirty_wr_addr = m_idx;
            dirty_wr_data = m_op || st_merge_pending;
            begin : g_plru_refill_upd
                automatic int node = 0;
                for (int b = WAY_BITS-1; b >= 0; b--) begin
                    plru_wr_ena[node] = 1'b1;
                    plru_wr_data[node] = ~m_eway[b];
                    node = 2*node + 1 + int'(m_eway[b]);
                end
            end
            plru_wr_addr = m_idx;
        end
    end

    // ==================== Performance counters ====================
    logic [63:0] access_cnt, hit_cnt, miss_cnt, wb_cnt64;
    logic [63:0] fast_load_cnt, fast_hum_cnt;
    assign perf_access    = access_cnt;
    assign perf_hit       = hit_cnt;
    assign perf_miss      = miss_cnt;
    assign perf_writeback = wb_cnt64;
    assign perf_fast_load = fast_load_cnt;
    assign perf_fast_hum  = fast_hum_cnt;

    always_ff @(posedge clk) begin
        if (reset) begin
            access_cnt    <= 64'd0;
            hit_cnt       <= 64'd0;
            miss_cnt      <= 64'd0;
            wb_cnt64      <= 64'd0;
            fast_load_cnt <= 64'd0;
            fast_hum_cnt  <= 64'd0;
        end else begin
            // Fast-path RESP stage (S_IDLE): hit or miss.
            if (p_valid && !in_refill && (state == S_IDLE)
                && is_cachable(p_addr, p_cacheable)) begin
                access_cnt <= access_cnt + 64'd1;
                if (p_hit) begin
                    hit_cnt <= hit_cnt + 64'd1;
                    if (!p_op)
                        fast_load_cnt <= fast_load_cnt + 64'd1;
                end else
                    miss_cnt <= miss_cnt + 64'd1;
            end
            // Hit-under-miss / refill-line store merge (counted with the
            // same gating as the response, so a store refused in
            // S_REFILL_WRITE is counted once when it re-hits in S_IDLE).
            if (p_valid && in_refill
                && (p_st_merge
                    || (p_hum_hit
                        && (p_op ? (state != S_REFILL_WRITE) : 1'b1)))) begin
                access_cnt    <= access_cnt + 64'd1;
                hit_cnt       <= hit_cnt + 64'd1;
                fast_hum_cnt  <= fast_hum_cnt + 64'd1;
                if (!p_op)
                    fast_load_cnt <= fast_load_cnt + 64'd1;
            end
            if (state == S_WB_WRITE && mem_resp.addr_ok)
                wb_cnt64 <= wb_cnt64 + 64'd1;
            if (state == S_CACOP_WB_WRITE && mem_resp.addr_ok)
                wb_cnt64 <= wb_cnt64 + 64'd1;
        end
    end

endmodule
