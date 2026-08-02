`include "common.sv"

// 8KB-class L1 dcache as a 0-cycle fast-path overlay on the 1MB L2
// (l2dcache): 256 sets x 2 ways x 16B lines, filled word-by-word
// (per-word valid/dirty bits, a sector cache).
//
// Architecture (pass-through, "never worse than the single-level L2"):
//   - cacheable load/store HITS are answered in the request cycle
//     (0-cycle, rvcpu-style: combinational LUTRAM tag read + registered
//     data read re-extracted by the WB stage via data_wb).
//   - every request that does NOT hit (cacheable miss, or uncacheable)
//     is forwarded UNCHANGED to the L2's cpu port in the request cycle;
//     the L2's response is passed back to the LSU as-is, so the miss
//     path costs exactly the same as the single-level 1MB dcache
//     (1-cycle L2 hit, refill from memory otherwise).
//   - when the L2's response completes a cacheable request, the L1
//     opportunistically FILLS the request's word (word-sector fill):
//     the response data (load) or the store's own data (full-word
//     stores only; partial-byte stores are not filled) is written into
//     the L1's line and its per-word valid bit is set.  No burst
//     protocol between the levels is needed.
//   - a fill that must displace a line (the victim way, per PLRU)
//     captures the victim's words and writes the dirty ones back to
//     the L2 as single-word stores (write-back, write-allocate at both
//     levels).  A drain is never presented while the LSU's forwarded
//     request is outstanding, and its accept is never confused with
//     the outstanding request's response (the o_* completion/fill is
//     gated on !(dr_valid && dr_waiting)).
//
// Coherence: a line is either present in the L1 (its words are served
// there; the L2's copy of dirty words is stale but never read, since
// requests for present words hit) or absent (the L2's copy is
// authoritative and the request passes through).  The L1 is the only
// master of the L2's cpu port.
//
// CACOP (0x01 index invalidate / 0x09 index writeback-invalidate):
// the kernel's flush walk uses the L2 geometry (reported by CPUCFG);
// the walk covers every L1 line (L1 set = addr[11:4], L1 way = addr[0]
// are both fully enumerated by the walk), so the L1 invalidates its
// matching line per walk address, draining its dirty words to the L2
// first.  core_top gates the L2's cacop on the L1's completion
// (l1_cacop_done), so a dirty L1 line is merged into the L2 before the
// L2 flushes its own line to memory.
module l1dcache import la32_common::*; #(
    parameter int NR_SETS = 256,
    parameter int NR_WAYS = 2,
    parameter int NR_WORDS = 4
)(
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

    output logic        in_refill,

    // Full registered-read data port (rvcpu-style 0-cycle hit): the WB
    // stage selects the line/word with the registered instruction context
    // (mem_wb's mem_hit_way + mem_addr word bits), because the response
    // data mux reflects the *current* request's way/word and is stale one
    // cycle after the request.
    output logic [31:0] data_wb [0:NR_WAYS-1][0:NR_WORDS-1]
);

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

    // ==================== Data BRAM (registered read) ====================
    index_t      data_rd_addr;
    logic [31:0] data_rd_out [0:NR_WAYS-1][0:NR_WORDS-1];
    logic        data_wr_ena;
    way_t        data_wr_way;
    index_t      data_wr_addr;
    woffset_t    data_wr_wo;
    logic [3:0]  data_wr_we;
    logic [31:0] data_wr_data;

    // Declared in-module (not via ram_sdpram) so the registered read
    // samples data_rd_addr at the same edge as the tag/dirty arrays.
    (* ram_style = "block" *) logic [31:0] data_mem [0:NR_WAYS-1][0:NR_SETS-1][0:NR_WORDS-1];

    always_ff @(posedge clk) begin
        if (data_wr_ena)
            for (int b = 0; b < 4; b++)
                if (data_wr_we[b])
                    data_mem[data_wr_way][data_wr_addr][data_wr_wo][b*8 +: 8] <=
                        data_wr_data[b*8 +: 8];
    end

    generate
        for (genvar gw = 0; gw < NR_WAYS; gw++) begin : g_data_way
            for (genvar gb = 0; gb < NR_WORDS; gb++) begin : g_data_word
                always_ff @(posedge clk)
                    data_rd_out[gw][gb] <= data_mem[gw][data_rd_addr][gb];
            end
        end
    endgenerate

    // ==================== Tag LUTRAM {tag, v[NR_WORDS-1:0]} ============
    // Per-word valid bits in the low NR_WORDS bits, tag above.  A line is
    // valid for a word iff the word's v bit is set.
    (* ram_style = "distributed" *) logic [TAG_WIDTH+NR_WORDS-1:0] tag_mem [0:NR_WAYS-1][NR_SETS-1:0];
    logic        tag_wr_ena;
    way_t        tag_wr_way;
    index_t      tag_wr_addr;
    logic [TAG_WIDTH+NR_WORDS-1:0] tag_wr_data;

    generate
        for (genvar gw = 0; gw < NR_WAYS; gw++) begin : g_tag_way
            logic tag_wen;
            assign tag_wen = tag_wr_ena && (tag_wr_way == way_t'(gw));
            always_ff @(posedge clk) begin
                if (tag_wen)
                    tag_mem[gw][tag_wr_addr] <= tag_wr_data;
            end
        end
    endgenerate

    // ==================== Dirty LUTRAM (per-word) ====================
    (* ram_style = "distributed" *) logic [NR_WORDS-1:0] dirty_mem [0:NR_WAYS-1][NR_SETS-1:0];
    logic        dirty_wr_ena;
    way_t        dirty_wr_way;
    index_t      dirty_wr_addr;
    logic [NR_WORDS-1:0] dirty_wr_data;

    generate
        for (genvar gw = 0; gw < NR_WAYS; gw++) begin : g_dirty_way
            logic dwen;
            assign dwen = dirty_wr_ena && (dirty_wr_way == way_t'(gw));
            always_ff @(posedge clk) begin
                if (dwen)
                    dirty_mem[gw][dirty_wr_addr] <= dirty_wr_data;
            end
        end
    endgenerate

    // ==================== PLRU (NR_WAYS-1 tree nodes per set) ============
    (* ram_style = "distributed" *) logic [NR_SETS-1:0] plru [0:NR_WAYS-1];
    logic        plru_wr_ena  [0:NR_WAYS-2];
    index_t      plru_wr_addr;
    logic        plru_wr_data [0:NR_WAYS-2];

    generate
        for (genvar gn = 0; gn < NR_WAYS-1; gn++) begin : g_plru_node
            always_ff @(posedge clk) begin
                if (plru_wr_ena[gn])
                    plru[gn][plru_wr_addr] <= plru_wr_data[gn];
            end
        end
    endgenerate

    // ==================== State ====================
    enum logic [2:0] {
        S_INIT,
        S_IDLE,
        S_CACOP_WB_READ, S_CACOP_WB_WRITE, S_CACOP_INV
    } state, next_state;

    index_t init_addr;
    way_t   init_wr_way;

    // ==================== Helper functions ====================
    function automatic logic is_cachable(input word_t a, input logic c);
        return c && (a[31:24] == 8'h1c);
    endfunction

    function automatic way_t victim_way(input index_t i);
        automatic int node = 0;
        for (int b = WAY_BITS-1; b >= 0; b--) begin
            victim_way[b] = plru[node][i];
            node = 2*node + 1 + int'(plru[node][i]);
        end
    endfunction

    // ==================== Combinational request hit ====================
    wire index_t   req_idx;
    wire tag_t     req_tag;
    wire woffset_t req_wo;
    assign req_idx = cpu_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET];
    assign req_tag = cpu_req.addr[31:INDEX_WIDTH+LINE_OFFSET];
    generate
        if (NR_WORDS > 1) begin : g_req_wo
            assign req_wo = cpu_req.addr[LINE_OFFSET-1:2];
        end else begin : g_req_wo_1word
            assign req_wo = '0;
        end
    endgenerate

    logic [TAG_WIDTH+NR_WORDS-1:0] req_tag_data [0:NR_WAYS-1];
    always_comb begin
        for (int w = 0; w < NR_WAYS; w++)
            req_tag_data[w] = tag_mem[w][req_idx];
    end

    logic req_hit_any;
    way_t req_hit_way;
    logic req_hit;

    always_comb begin
        automatic logic [NR_WAYS-1:0] hit_vec;
        hit_vec = '0;
        for (int w = 0; w < NR_WAYS; w++)
            hit_vec[w] = req_tag_data[w][req_wo]
                && (req_tag_data[w][TAG_WIDTH+NR_WORDS-1:NR_WORDS] == req_tag)
                && is_cachable(cpu_req.addr, cpu_req.cacheable);
        req_hit_any = |hit_vec;
        req_hit = req_hit_any && (state == S_IDLE);
        req_hit_way = '0;
        for (int w = 0; w < NR_WAYS; w++)
            if (hit_vec[w]) req_hit_way = way_t'(w);
    end

    // ==================== Wire helpers ====================
    wire hit_read_req = cpu_req.valid && req_hit;
    wire store_hit_wr = cpu_req.valid && req_hit && |cpu_req.strobe;
    // Forward the LSU's request (cacheable miss or uncacheable access)
    // unchanged; the L2 answers exactly as it would in the single-level
    // design.  The L1's own fills/drains are never presented while the
    // LSU's request is presented or outstanding (o_valid), so the L2
    // processes one initiator transaction at a time.
    // Gated while a drain store is waiting for its accept: the drain's
    // store is presented continuously until the L2 captures it, and the
    // LSU's request (re-presented by the LSU until answered) waits.  If
    // the LSU's forward preempted an unaccepted drain store, the L2
    // would capture the LSU's request instead, and its response would
    // be mistaken for the drain's accept — the drain's store dropped
    // and the dirty word lost.
    wire lsu_forward_req = cpu_req.valid && !req_hit && !(dr_valid && dr_waiting);
    // The drain store is re-presented every cycle until the L2 accepts
    // it (captured requests are ignored by the L2's pipeline, so a
    // dropped presentation is harmless).
    wire drain_store_req = dr_valid && dr_mask[dr_word] && !o_valid && !lsu_forward_req;
    // CACOP drain store: re-presented until the L2 accepts it.  The first
    // S_CACOP_WB_WRITE cycle only CAPTURES cacop_wb_buf (the line read
    // issued in S_CACOP_WB_READ completes then); presenting in that cycle
    // would let the L2 capture the stale buffer value (the previous word).
    wire cacop_store_req = (state == S_CACOP_WB_WRITE)
        && !(cacop_wb_cnt == 0 && !cacop_waiting)
        && cacop_mask[cacop_wb_cnt];
    // The L2's response belongs to the outstanding forwarded request
    // only while no drain store is in flight (the drain's accept must
    // not complete/fill the o_* context).
    wire o_complete = o_valid && mem_resp.data_ok && !(dr_valid && dr_waiting);

    // Background op pending (blocks cacop acceptance and new fills).
    wire l1_busy = o_valid || f_valid || vc_valid || dr_valid;

    // Fill target way decision: a way whose tag already matches (a
    // partially-filled line) is reused instead of displacing a victim.
    wire [NR_WAYS-1:0] o_tag_match;
    wire [NR_WAYS-1:0] o_line_valid;
    generate
        for (genvar gw = 0; gw < NR_WAYS; gw++) begin : g_o_match
            assign o_tag_match[gw]  = (tag_mem[gw][o_idx][TAG_WIDTH+NR_WORDS-1:NR_WORDS] == o_tag);
            assign o_line_valid[gw] = |tag_mem[gw][o_idx][NR_WORDS-1:0];
        end
    endgenerate
    wire logic fill_is_partial = |o_tag_match;
    way_t fill_match_way;
    always_comb begin
        fill_match_way = '0;
        for (int w = 0; w < NR_WAYS; w++)
            if (o_tag_match[w]) fill_match_way = way_t'(w);
    end

    // ==================== Outstanding request (in-flight latch) ==========
    // At most ONE forwarded request is in flight at a time: the LSU holds
    // a request until its data_ok (load misses move to WAIT and present
    // nothing), so a new request is only presented after the previous one
    // completed.  The latch carries the context needed for the fill.
    logic o_valid;
    logic o_wait;
    logic o_op;
    logic o_cacheable;
    index_t   o_idx;
    tag_t     o_tag;
    woffset_t o_wo;
    word_t    o_data;
    logic [3:0] o_strobe;

    // ==================== Fill / victim-capture / drain ==================
    // Fill: write the response word into the L1 when the write port is
    // free (a store-hit owns it that cycle).  A fill that must displace a
    // line first captures the victim's words (vc) into wb_buf, then the
    // dirty ones are drained to the L2 as single-word stores (dr).  Fills
    // and drains are mutually exclusive (a drain's remaining words live
    // in wb_buf and must not be overwritten by a new victim capture).
    logic        f_valid;
    logic        f_partial;
    logic        f_store;
    way_t        f_way;
    index_t      f_idx;
    tag_t        f_tag;
    woffset_t    f_wo;
    word_t       f_data;

    logic        vc_valid;
    logic        vc_reading;
    way_t        vc_way;
    index_t      vc_idx;
    tag_t        vc_tag;
    logic [NR_WORDS-1:0] vc_mask;
    word_t       wb_buf [0:NR_WORDS-1];

    logic        dr_valid;
    logic        dr_waiting;
    logic [CNT_WIDTH-1:0] dr_word;
    logic [NR_WORDS-1:0] dr_mask;

    // ==================== CACOP context ====================
    way_t   cacop_way;
    index_t cacop_idx;
    logic [NR_WORDS-1:0] cacop_mask;
    logic [CNT_WIDTH-1:0] cacop_wb_cnt;
    logic        cacop_waiting;
    logic        cacop_finish;
    word_t       cacop_wb_buf [0:NR_WORDS-1];

    // ==================== FSM combinational ====================
    always_comb begin
        next_state = state;
        cacop_done = 1'b0;

        case (state)
            S_INIT: begin
                if (init_wr_way == NR_WAYS - 1 && init_addr == NR_SETS - 1)
                    next_state = S_IDLE;
            end

            S_IDLE: begin
                if (cacop_req.valid && cacop_req.code[2:0] == 3'd1 && !l1_busy) begin
                    if (cacop_req.code[4:3] == 2'b00)
                        next_state = S_CACOP_INV;
                    else
                        next_state = S_CACOP_WB_READ;
                end
            end

            S_CACOP_WB_READ: begin
                // Nothing valid to write back: straight to invalidate.
                // (Avoid `!|` — Vivado 2019.2's parser rejects it.)
                if (tag_mem[cacop_way][cacop_idx][NR_WORDS-1:0] == {NR_WORDS{1'b0}})
                    next_state = S_CACOP_INV;
                else
                    next_state = S_CACOP_WB_WRITE;
            end

            S_CACOP_WB_WRITE: begin
                if (cacop_finish)
                    next_state = S_CACOP_INV;
            end

            S_CACOP_INV: begin
                // Level done: stay here (cacop_done=1) until the pipeline
                // retires the cacop and its request drops (the walk's loop
                // instructions create a gap between two cacops).  The L2's
                // cacop request is gated (in core_top) on this level, so a
                // 1-cycle pulse could be MISSED while the L2 is still busy
                // (e.g. refilling a drained line that it had evicted) and
                // the flush walk would hang forever.
                cacop_done = 1'b1;
                if (!cacop_req.valid)
                    next_state = S_IDLE;
            end

            default: next_state = S_IDLE;
        endcase
    end

    // ==================== Response to the LSU ====================
    always_comb begin
        cpu_resp.addr_ok  = 1'b0;
        cpu_resp.rdata_ok = 1'b0;
        cpu_resp.data_ok  = 1'b0;
        cpu_resp.data_last = 1'b0;
        cpu_resp.data     = 32'd0;
        cpu_resp.hit      = 1'b0;
        cpu_resp.hit_way  = 1'b0;

        if (hit_read_req) begin
            // 0-cycle hit: answered in the request cycle.  The load's data
            // completes one cycle later on the registered read port and is
            // re-extracted by the WB stage (hit=1); the store is written
            // through the data write port this cycle.
            cpu_resp.addr_ok = 1'b1;
            cpu_resp.data_ok = 1'b1;
            if (!(|cpu_req.strobe)) begin
                cpu_resp.hit     = 1'b1;
                cpu_resp.hit_way = req_hit_way;
                cpu_resp.data    = data_rd_out[req_hit_way][req_wo];
            end
        end else if (!(dr_valid && dr_waiting)
                     && (o_valid || (cpu_req.valid && !req_hit))) begin
            // Pass-through: the L2's response to the forwarded request
            // (o_valid covers the load-miss keyword, delivered while the
            // LSU is in WAIT and no longer presenting the request).
            // Gated on the outstanding/presented request so a stray L2
            // response can never be mistaken for a response to an idle
            // LSU (the next request would complete with wrong data).
            // Also excluded while a drain store is in flight: its accept
            // belongs to the eviction, not to any request the LSU may
            // present that cycle (the L2 is still processing the drain,
            // so the presented request was NOT captured — letting it
            // complete on the drain's response would drop the request
            // and leave o_valid stuck, deadlocking the cacop walk).
            // hit is never asserted here — the WB stage only re-extracts
            // for L1 hits.
            cpu_resp.addr_ok   = mem_resp.addr_ok;
            cpu_resp.rdata_ok  = mem_resp.rdata_ok;
            cpu_resp.data_ok   = mem_resp.data_ok;
            cpu_resp.data_last = mem_resp.data_last;
            cpu_resp.data      = mem_resp.data;
        end
    end

    // ==================== mem_req (to the L2's cpu port) ================
    // CACOP drain target: the LINE's real address (tag_mem[cacop_way]
    // [cacop_idx] is the tag of the line at the walked index — NOT the
    // walk address itself, which only encodes the set/way; writing back
    // to addr[31:4] would push the dirty line's data into the wrong
    // memory line whenever the index holds a line of a different tag).
    // Eviction drain target: the victim line.
    wire [31:0] cacop_store_addr;
    wire [31:0] drain_store_addr;
    generate
        if (WORD_WIDTH > 0) begin : g_store_addr
            assign cacop_store_addr = {tag_mem[cacop_way][cacop_idx][TAG_WIDTH+NR_WORDS-1:NR_WORDS],
                                       cacop_idx, cacop_wb_cnt[WORD_WIDTH-1:0], 2'b00};
            assign drain_store_addr = {vc_tag, vc_idx, dr_word[WORD_WIDTH-1:0], 2'b00};
        end else begin : g_store_addr_1w
            assign cacop_store_addr = {tag_mem[cacop_way][cacop_idx][TAG_WIDTH+NR_WORDS-1:NR_WORDS],
                                       cacop_idx, 2'b00};
            assign drain_store_addr = {vc_tag, vc_idx, 2'b00};
        end
    endgenerate

    always_comb begin
        mem_req.valid     = 1'b0;
        mem_req.addr      = 32'd0;
        mem_req.size      = MSIZE4;
        mem_req.strobe    = 4'd0;
        mem_req.data      = 32'd0;
        mem_req.cacheable = 1'b1;
        mem_req.burst_len = 2'd0;

        if (lsu_forward_req) begin
            mem_req.valid     = 1'b1;
            mem_req.addr      = cpu_req.addr;
            mem_req.strobe    = cpu_req.strobe;
            mem_req.data      = cpu_req.data;
            mem_req.cacheable = cpu_req.cacheable;
            mem_req.size      = cpu_req.size;
        end else if (cacop_store_req) begin
            mem_req.valid     = 1'b1;
            mem_req.addr      = cacop_store_addr;
            mem_req.strobe    = 4'b1111;
            mem_req.data      = cacop_wb_buf[cacop_wb_cnt];
        end else if (drain_store_req) begin
            mem_req.valid     = 1'b1;
            mem_req.addr      = drain_store_addr;
            mem_req.strobe    = 4'b1111;
            mem_req.data      = wb_buf[dr_word];
        end
    end

    // ==================== BRAM read control ====================
    always_comb begin
        data_rd_addr = '0;
        if (hit_read_req) begin
            // 0-cycle hit: issue the line read for the WB re-extraction.
            data_rd_addr = req_idx;
        end else if (state == S_CACOP_WB_READ) begin
            data_rd_addr = cacop_idx;
        end else if (vc_valid && !vc_reading) begin
            // Victim capture read (background; yields to hits).
            data_rd_addr = vc_idx;
        end
    end

    // ==================== Data write control ====================
    // The fill write may happen in any cycle the write port is not owned
    // by a store hit; it must wait for a pending victim capture (the
    // victim's words are read before the fill overwrites its way).
    wire fill_wr = f_valid && !vc_valid && !store_hit_wr;

    always_comb begin
        data_wr_ena  = 1'b0;
        data_wr_way  = '0;
        data_wr_addr = '0;
        data_wr_wo   = '0;
        data_wr_we   = 4'd0;
        data_wr_data = 32'd0;

        if (store_hit_wr) begin
            // 0-cycle store hit.
            data_wr_ena  = 1'b1;
            data_wr_way  = req_hit_way;
            data_wr_addr = req_idx;
            data_wr_wo   = req_wo;
            data_wr_we   = cpu_req.strobe;
            data_wr_data = cpu_req.data;
        end else if (fill_wr) begin
            data_wr_ena  = 1'b1;
            data_wr_way  = f_way;
            data_wr_addr = f_idx;
            data_wr_wo   = f_wo;
            data_wr_we   = 4'b1111;
            data_wr_data = f_data;
        end
    end

    // ==================== Tag / dirty / PLRU write control ==============
    // The new v bits merge the existing ones for a partial line (the way
    // whose tag already matches), otherwise a fresh single-word line.
    // The new dirty word keeps the line's other dirty words and marks the
    // filled word only for store fills.
    wire [NR_WORDS-1:0] fill_new_v = f_partial
        ? (tag_mem[f_way][f_idx][NR_WORDS-1:0] | (1 << f_wo))
        : (1 << f_wo);
    // Dirty bits of the line AFTER the fill: a partial fill (same tag
    // already resident) keeps the line's other dirty words; a fresh fill
    // REPLACES the victim's line, whose words (and their dirty bits)
    // belong to the victim — merging them in would mark the stale data
    // words (never written by this fill) dirty and a later eviction
    // would drain garbage into the L2 at this line's address.
    wire [NR_WORDS-1:0] fill_new_dirty = f_partial
        ? ((dirty_mem[f_way][f_idx] & ~(1 << f_wo))
           | (f_store ? (1 << f_wo) : 1'b0))
        : (f_store ? (1 << f_wo) : 1'b0);

    always_comb begin
        tag_wr_ena   = 1'b0;
        tag_wr_way   = '0;
        tag_wr_addr  = '0;
        tag_wr_data  = '0;
        dirty_wr_ena  = 1'b0;
        dirty_wr_way  = '0;
        dirty_wr_addr = '0;
        dirty_wr_data = '0;
        plru_wr_ena[0] = 1'b0;
        plru_wr_data[0] = 1'b0;
        for (int gn = 1; gn < NR_WAYS-1; gn++) begin
            plru_wr_ena[gn] = 1'b0;
            plru_wr_data[gn] = 1'b0;
        end
        plru_wr_addr = '0;

        if (state == S_INIT) begin
            tag_wr_ena   = 1'b1;
            tag_wr_way   = init_wr_way;
            tag_wr_addr  = init_addr;
            tag_wr_data  = '0;
            dirty_wr_ena  = 1'b1;
            dirty_wr_way  = init_wr_way;
            dirty_wr_addr = init_addr;
            dirty_wr_data = '0;
            for (int gn = 0; gn < NR_WAYS-1; gn++)
                plru_wr_ena[gn] = 1'b1;
            plru_wr_addr = init_addr;
            for (int gn = 0; gn < NR_WAYS-1; gn++)
                plru_wr_data[gn] = 1'b0;
        end

        if (state == S_CACOP_INV) begin
            tag_wr_ena   = 1'b1;
            tag_wr_way   = cacop_way;
            tag_wr_addr  = cacop_idx;
            tag_wr_data  = '0;
            dirty_wr_ena  = 1'b1;
            dirty_wr_way  = cacop_way;
            dirty_wr_addr = cacop_idx;
            dirty_wr_data = '0;
        end

        if (store_hit_wr) begin
            dirty_wr_ena  = 1'b1;
            dirty_wr_way  = req_hit_way;
            dirty_wr_addr = req_idx;
            dirty_wr_data = dirty_mem[req_hit_way][req_idx] | (1 << req_wo);
        end

        if (fill_wr) begin
            tag_wr_ena   = 1'b1;
            tag_wr_way   = f_way;
            tag_wr_addr  = f_idx;
            tag_wr_data  = {f_tag, fill_new_v};
            dirty_wr_ena  = 1'b1;
            dirty_wr_way  = f_way;
            dirty_wr_addr = f_idx;
            dirty_wr_data = fill_new_dirty;
        end

        // PLRU (NR_WAYS-1 tree nodes): the hit update wins over the fill's
        // (a single write port per node).
        if (hit_read_req) begin
            begin : g_plru_hit
                automatic int node = 0;
                for (int b = WAY_BITS-1; b >= 0; b--) begin
                    plru_wr_ena[node]  = 1'b1;
                    plru_wr_data[node] = ~req_hit_way[b];
                    node = 2*node + 1 + int'(req_hit_way[b]);
                end
            end
            plru_wr_addr = req_idx;
        end else if (fill_wr) begin
            begin : g_plru_fill
                automatic int node = 0;
                for (int b = WAY_BITS-1; b >= 0; b--) begin
                    plru_wr_ena[node]  = 1'b1;
                    plru_wr_data[node] = ~f_way[b];
                    node = 2*node + 1 + int'(f_way[b]);
                end
            end
            plru_wr_addr = f_idx;
        end
    end

    // ==================== Sequential logic ====================
    always_ff @(posedge clk) begin
        if (reset) begin
            state          <= S_INIT;
            init_addr      <= '0;
            init_wr_way    <= '0;
            o_valid        <= 1'b0;
            o_wait         <= 1'b0;
            o_op           <= 1'b0;
            o_cacheable    <= 1'b0;
            o_idx          <= '0;
            o_tag          <= '0;
            o_wo           <= '0;
            o_data         <= 32'd0;
            o_strobe       <= 4'd0;
            f_valid        <= 1'b0;
            f_partial      <= 1'b0;
            f_store        <= 1'b0;
            f_way          <= '0;
            f_idx          <= '0;
            f_tag          <= '0;
            f_wo           <= '0;
            f_data         <= 32'd0;
            vc_valid       <= 1'b0;
            vc_reading     <= 1'b0;
            vc_way         <= '0;
            vc_idx         <= '0;
            vc_tag         <= '0;
            vc_mask        <= '0;
            dr_valid       <= 1'b0;
            dr_waiting     <= 1'b0;
            dr_word        <= '0;
            dr_mask        <= '0;
            cacop_wb_cnt   <= '0;
            cacop_waiting  <= 1'b0;
            cacop_finish   <= 1'b0;
        end else begin
            state <= next_state;

            if (state == S_INIT) begin
                if (init_wr_way == NR_WAYS - 1)
                    init_addr <= init_addr + 1;
                init_wr_way <= init_wr_way + 1;
            end

            // ==================== Outstanding request ====================
            if (o_complete) begin
                o_valid <= 1'b0;
                o_wait  <= 1'b0;
            end else if (!o_valid && lsu_forward_req) begin
                o_valid     <= 1'b1;
                o_idx       <= req_idx;
                o_tag       <= req_tag;
                o_wo        <= req_wo;
                o_op        <= |cpu_req.strobe;
                o_cacheable <= is_cachable(cpu_req.addr, cpu_req.cacheable);
                o_data      <= cpu_req.data;
                o_strobe    <= cpu_req.strobe;
            end
            // Load miss accepted with addr_ok only: the LSU waits for the
            // keyword (in_refill, counted as a DCache Refill stall).
            if (o_valid && !o_op && !o_wait && mem_resp.addr_ok && !mem_resp.data_ok)
                o_wait <= 1'b1;

            // ==================== Fill initiation (at the response) ======
            // The fill is background: it waits for any pending fill /
            // victim capture / drain to finish so wb_buf and the write
            // port are owned by one op at a time.
            if (o_complete && o_cacheable && !f_valid && !vc_valid && !dr_valid) begin
                // Fill only complete words: loads always, stores only with
                // a full strobe (a partial-byte store would leave garbage
                // in the unwritten bytes — the word is left invalid and
                // passes through to the L2 instead).
                if (!o_op || o_strobe == 4'b1111) begin
                    f_valid  <= 1'b1;
                    f_idx    <= o_idx;
                    f_tag    <= o_tag;
                    f_wo     <= o_wo;
                    f_way    <= fill_is_partial ? fill_match_way : victim_way(o_idx);
                    f_partial<= fill_is_partial;
                    f_store  <= o_op;
                    f_data   <= o_op ? o_data : mem_resp.data;
                    // The victim's dirty words must be captured before the
                    // fill overwrites its way (only when the victim is a
                    // live line with dirty words; clean or empty victims
                    // are dropped silently — their data equals memory).
                    if (!fill_is_partial
                        && o_line_valid[victim_way(o_idx)]
                        && |dirty_mem[victim_way(o_idx)][o_idx]) begin
                        vc_valid <= 1'b1;
                        vc_way   <= victim_way(o_idx);
                        vc_idx   <= o_idx;
                        vc_tag   <= tag_mem[victim_way(o_idx)][o_idx][TAG_WIDTH+NR_WORDS-1:NR_WORDS];
                        vc_mask  <= dirty_mem[victim_way(o_idx)][o_idx];
                    end
                end
            end

            // ==================== Victim capture ========================
            if (vc_valid && !vc_reading && !hit_read_req) begin
                // Issue the victim line read this cycle (the registered
                // output is valid one cycle later, in vc_reading).
                vc_reading <= 1'b1;
            end
            if (vc_reading) begin
                for (int n = 0; n < NR_WORDS; n++)
                    wb_buf[n] <= data_rd_out[vc_way][n];
                vc_valid   <= 1'b0;
                vc_reading <= 1'b0;
                dr_valid   <= 1'b1;
                dr_word    <= '0;
                dr_waiting <= 1'b0;
                dr_mask    <= vc_mask;
            end

            // ==================== Fill write =============================
            if (fill_wr) begin
                // The data write port is free (no store hit this cycle);
                // the tag/dirty/plru writes are combinational on the same
                // condition.
                f_valid <= 1'b0;
            end

            // ==================== Eviction drain ========================
            if (dr_valid) begin
                if (dr_waiting) begin
                    if (mem_resp.addr_ok) begin
                        dr_waiting <= 1'b0;
                        if (dr_word == NR_WORDS - 1) begin
                            dr_valid <= 1'b0;
                            dr_mask  <= '0;
                        end else
                            dr_word <= dr_word + 1;
                    end
                    // else: keep re-presenting the store until accepted.
                end else if (dr_mask[dr_word]) begin
                    // Dirty word: present it once the cpu port is free
                    // (the L1 is the only master of the L2, and the L2
                    // processes one initiator transaction at a time) and
                    // HOLD until the L2 accepts.  Advancing past a dirty
                    // word while the bus is busy would silently drop the
                    // store's data (observed in the test-12 storm: only
                    // drains whose dirty word sat at word 0 AND met a
                    // quiet LSU completed; all others lost the word).
                    if (!o_valid && !lsu_forward_req)
                        dr_waiting <= 1'b1;
                end else if (dr_word == NR_WORDS - 1) begin
                    dr_valid <= 1'b0;
                    dr_mask  <= '0;
                end else begin
                    dr_word <= dr_word + 1;
                end
            end

            // ==================== CACOP ================================
            if (state == S_IDLE && cacop_req.valid && cacop_req.code[2:0] == 3'd1 && !l1_busy) begin
                cacop_way <= cacop_req.addr[WAY_BITS-1:0];
                cacop_idx <= cacop_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET];
            end

            if (state == S_CACOP_WB_READ) begin
                // The line read (issued this cycle) completes one cycle
                // later; the mask comes from the async dirty read.
                cacop_mask    <= dirty_mem[cacop_way][cacop_idx];
                cacop_wb_cnt  <= '0;
                cacop_waiting <= 1'b0;
                cacop_finish  <= 1'b0;
            end

            if (state == S_CACOP_WB_WRITE) begin
                // The line data (read issued in S_CACOP_WB_READ) is valid
                // in this state's first cycle only (cacop_wb_cnt==0,
                // !cacop_waiting): latch it once, then drain the dirty
                // words as single-word stores (re-presented until
                // accepted).
                if (cacop_wb_cnt == 0 && !cacop_waiting) begin
                    for (int n = 0; n < NR_WORDS; n++)
                        cacop_wb_buf[n] <= data_rd_out[cacop_way][n];
                end
                if (cacop_waiting) begin
                    if (mem_resp.addr_ok) begin
                        cacop_waiting <= 1'b0;
                        if (cacop_wb_cnt == NR_WORDS - 1)
                            cacop_finish <= 1'b1;
                        else
                            cacop_wb_cnt <= cacop_wb_cnt + 1;
                    end
                end else if (cacop_mask[cacop_wb_cnt]) begin
                    cacop_waiting <= 1'b1;
                end else if (cacop_wb_cnt == NR_WORDS - 1) begin
                    cacop_finish <= 1'b1;
                end else begin
                    cacop_wb_cnt <= cacop_wb_cnt + 1;
                end
            end
        end
    end

    assign in_refill = o_valid && o_wait;
    assign data_wb   = data_rd_out;

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
            if (hit_read_req && is_cachable(cpu_req.addr, cpu_req.cacheable)) begin
                access_cnt <= access_cnt + 64'd1;
                hit_cnt    <= hit_cnt + 64'd1;
                if (!(|cpu_req.strobe))
                    fast_load_cnt <= fast_load_cnt + 64'd1;
                if (l1_busy)
                    fast_hum_cnt <= fast_hum_cnt + 64'd1;
            end
            if (!o_valid && lsu_forward_req && is_cachable(cpu_req.addr, cpu_req.cacheable)) begin
                access_cnt <= access_cnt + 64'd1;
                miss_cnt   <= miss_cnt + 64'd1;
            end
            if (dr_valid && dr_waiting && mem_resp.addr_ok)
                wb_cnt64 <= wb_cnt64 + 64'd1;
            if (state == S_CACOP_WB_WRITE && cacop_waiting && mem_resp.addr_ok)
                wb_cnt64 <= wb_cnt64 + 64'd1;
        end
    end

endmodule
