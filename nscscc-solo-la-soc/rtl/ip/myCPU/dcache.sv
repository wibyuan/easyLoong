`include "common.sv"

module dcache import la32_common::*; (
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

    parameter int NR_SETS = 256;
    parameter int NR_WAYS = 2;
    parameter int NR_WORDS = 4;
    localparam WORD_WIDTH  = $clog2(NR_WORDS);
    localparam LINE_OFFSET = WORD_WIDTH + 2;
    // (1 << (LINE_OFFSET-2)) - 1: word-offset mask.  Zero for a 1-word
    // line so the offset expression never slices a backward range.
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
    // Registered read port only (rvcpu-style 0-cycle hit): the load hit is
    // acknowledged in the request cycle through the asynchronous tag read
    // (data_ok), while the data completes one cycle later on this port and
    // is re-extracted by the WB stage from dresp.data (dresp.hit).  With no
    // combinational read port the 256x32 arrays infer as block RAM again.
    logic        data_wr_ena;
    way_t        data_wr_way;
    index_t      data_wr_addr;
    woffset_t    data_wr_wo;
    logic [3:0]  data_wr_we;
    logic [31:0] data_wr_data;

    generate
        for (genvar gw = 0; gw < NR_WAYS; gw++) begin : g_data_way
            for (genvar gb = 0; gb < NR_WORDS; gb++) begin : g_data_word
                logic wen;
                assign wen = data_wr_ena && (data_wr_way == way_t'(gw)) && (data_wr_wo == woffset_t'(gb));

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

    // ==================== Tag LUTRAM ====================
    (* ram_style = "distributed" *) logic [TAG_WIDTH:0] tag_mem [0:NR_WAYS-1][NR_SETS-1:0];
    index_t      tag_rd_addr;
    logic [TAG_WIDTH:0] tag_rd_data [0:NR_WAYS-1];
    logic        tag_wr_ena;
    way_t        tag_wr_way;
    index_t      tag_wr_addr;
    logic [TAG_WIDTH:0] tag_wr_data;

    // Per-way write enables with a constant first index: a single write
    // with a variable way index (tag_mem[tag_wr_way][...]) defeats Vivado's
    // RAM inference and degrades to a register array ("3D RAM not
    // supported"); the per-way form infers as distributed RAM.
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

    always_ff @(posedge clk) begin
        for (int w = 0; w < NR_WAYS; w++)
            tag_rd_data[w] <= tag_mem[w][tag_rd_addr];
    end

    // ==================== Dirty + PLRU ====================
    (* ram_style = "distributed" *) logic [NR_SETS-1:0] dirty [0:NR_WAYS-1];
    // Sized NR_WAYS-1 so a direct-mapped (NR_WAYS=1) cache keeps a valid
    // (empty at runtime) array declaration; all PLRU reads/writes are
    // gated by NR_WAYS>1 conditions and never touch the array in 1-way.
    (* ram_style = "distributed" *) logic [NR_SETS-1:0] plru [0:NR_WAYS-1];

    // ==================== State ====================
    enum logic [3:0] {
        S_INIT,
        S_IDLE,
        S_UNCACHED,
        S_MISS,
        S_WB_READ, S_WB_WRITE,
        S_REFILL_REQ, S_REFILL_WAIT, S_REFILL_WRITE,
        S_CACOP_ST,
        S_CACOP_WB_READ, S_CACOP_WB_WRITE, S_CACOP_INV
    } state, next_state;

    dbus_req_t mem_req_next;
    dbus_req_t mem_req_r;

    // ==================== Pipeline ====================
    logic       s1_valid;
    word_t      s1_addr;
    logic       s1_op;
    msize_t     s1_size;
    word_t      s1_wdata;
    logic [3:0] s1_wstrb;
    woffset_t   s1_wo;
    index_t     s1_idx;
    tag_t       s1_tag;
    logic       s1_cacheable;

    logic       s2_valid;
    word_t      s2_addr;
    logic       s2_op;
    msize_t     s2_size;
    word_t      s2_wdata;
    logic [3:0] s2_wstrb;
    woffset_t   s2_wo;
    index_t     s2_idx;
    tag_t       s2_tag;
    logic       s2_cacheable;

    logic       just_hit;
    word_t      last_hit_addr;

    // ==================== Miss context ====================
    logic       m_op;
    woffset_t   m_wo;
    index_t     m_idx;
    tag_t       m_tag;
    way_t       m_eway;
    logic       m_edirty;
    tag_t       m_etag;
    // Accepted store miss data, merged into the refilled line at
    // S_REFILL_WRITE (store misses are completed in the request cycle).
    word_t      m_wdata;
    logic [3:0] m_wstrb;

    // Second merge slot: a store hitting the line being refilled (the
    // read-back-store pattern) is accepted in-cycle and merged into the
    // refill write, instead of stalling until the refill completes.
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
    logic                 cacop_edirty;
    logic [CNT_WIDTH-1:0] cacop_wb_cnt;
    word_t                cacop_wb_buf [0:NR_WORDS-1];

    // Writeback target address of the cacop 0x09 flow, per-word for
    // multi-word lines, base address for the 1-word line.  Generated so
    // the empty-slice form (WORD_WIDTH=0) is never elaborated.
    wire [31:0] cacop_wb_addr;
    generate
        if (WORD_WIDTH > 0) begin : g_cacop_wb_addr
            assign cacop_wb_addr = {cacop_etag, cacop_idx,
                                    cacop_wb_cnt[WORD_WIDTH-1:0], 2'b00};
        end else begin : g_cacop_wb_addr_1w
            assign cacop_wb_addr = {cacop_etag, cacop_idx, 2'b00};
        end
    endgenerate

    // ==================== Init registers ====================
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
    // With a 1-word line the word-offset field is empty (addr[1:2] is a
    // backward range that some verilator versions reject); generate both
    // forms so only the active one is elaborated.
    generate
        if (NR_WORDS > 1) begin : g_req_wo
            assign req_wo = cpu_req.addr[LINE_OFFSET-1:2];
        end else begin : g_req_wo_1word
            assign req_wo = '0;
        end
    endgenerate

    logic [TAG_WIDTH:0] req_tag_data [0:NR_WAYS-1];
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
            hit_vec[w] = req_tag_data[w][0]
                && (req_tag_data[w][TAG_WIDTH:1] == req_tag)
                && is_cachable(cpu_req.addr, cpu_req.cacheable);
        req_hit_any = |hit_vec;
        req_hit = req_hit_any && (state == S_IDLE);
        req_hit_way = '0;
        for (int w = 0; w < NR_WAYS; w++)
            if (hit_vec[w]) req_hit_way = way_t'(w);
    end

    // ==================== S2 hit ====================
    wire [TAG_WIDTH-1:0] tag_r_tag [0:NR_WAYS-1];
    wire                 tag_r_v   [0:NR_WAYS-1];
    for (genvar gw = 0; gw < NR_WAYS; gw++) begin : tag_extract
        assign tag_r_tag[gw] = tag_rd_data[gw][TAG_WIDTH:1];
        assign tag_r_v[gw]   = tag_rd_data[gw][0];
    end

    logic s2_hit;
    way_t  s2_hit_way;

    always_comb begin
        automatic logic [NR_WAYS-1:0] hit_vec;
        hit_vec = '0;
        for (int w = 0; w < NR_WAYS; w++)
            hit_vec[w] = s2_valid && tag_r_v[w] && (tag_r_tag[w] == s2_tag) && is_cachable(s2_addr, s2_cacheable);
        s2_hit = |hit_vec;
        s2_hit_way = '0;
        for (int w = 0; w < NR_WAYS; w++)
            if (hit_vec[w]) s2_hit_way = way_t'(w);
    end

    // ==================== Refill status ====================
    assign in_refill = state inside {S_MISS, S_WB_READ, S_WB_WRITE,
                                     S_REFILL_REQ, S_REFILL_WAIT, S_REFILL_WRITE};

    // ==================== Non-blocking (hit-under-miss) ====================
    // One miss may be in flight while the pipeline keeps running: store
    // misses are accepted in the request cycle (their data is merged into
    // the refilled line), so the LSU is free to issue further requests
    // during the refill.  Hits to lines other than the one being refilled
    // are served in the request cycle; any request that does not hit must
    // wait for the in-flight miss to complete (single MSHR).
    wire cacop_d_pending = cacop_req.valid && (cacop_req.code[2:0] == 3'd1);
    // Every cacheable request is answered combinationally in S_IDLE: a hit
    // (load/store) or a miss accept (store: full accept; load: addr_ok only,
    // data via the keyword forward).  Miss accepts must not fire while a
    // dcache cacop is pending — the FSM gives the cacop priority and no
    // refill would start, leaving an accepted request to hang.
    wire fast_path_req   = (state == S_IDLE) && !s2_valid && cpu_req.valid
                           && is_cachable(cpu_req.addr, cpu_req.cacheable);
    wire fast_path_miss  = fast_path_req && !req_hit && !cacop_d_pending;
    // The line being refilled must not be served: its data RAM is only
    // partially (or not yet) written while its tag can already match.
    wire hum_refilling   = (req_idx == m_idx) && (req_hit_way == m_eway);
    // No hit-under-miss while the keyword of an outstanding load miss is
    // forwarded (the pipeline is stalled on that load, so no second request
    // can exist — defensive guard).  The keyword may fire during the
    // overlapped writeback drain (S_WB_WRITE) as well as S_REFILL_WAIT;
    // qualified on rdata_ok (read-channel only) so the writeback
    // completion cannot masquerade as a keyword.
    wire hum_keyword     = (state inside {S_WB_WRITE, S_REFILL_WAIT})
                           && mem_resp.rdata_ok
                           && (rf_cnt == m_wo) && !rf_kw_sent && (m_op == 1'b0);
    // Refill complete when all beats arrived (mask full, possibly during
    // the writeback drain) or the current beat completes the mask.
    wire refill_fmask_done = (&rf_fmask) ||
                             (mem_resp.rdata_ok && (&(rf_fmask | (1 << rf_cnt))));
    // S_MISS is excluded: the data RAM read port is busy that cycle issuing
    // the victim's line read for the writeback capture (S_WB_READ samples
    // data_rd_out one cycle later), so a hum load accepted in-cycle would
    // have its registered read overwritten and the writeback would drain
    // the wrong line.  The LSU simply holds the request and re-presents it
    // at S_WB_READ / S_REFILL_WAIT, where the port is free.
    wire hum_req         = in_refill && (state != S_MISS) && !hum_keyword
                           && cpu_req.valid
                           && is_cachable(cpu_req.addr, cpu_req.cacheable)
                           && req_hit_any && !hum_refilling;
    // Store hits need the data write port, which the refill owns during
    // S_REFILL_WRITE; such hits are deferred (they stall at most a few
    // cycles and then hit again in S_IDLE).  Loads are always served.
    wire hum_ok          = hum_req && ((state != S_REFILL_WRITE) || !(|cpu_req.strobe));
    // A store to the line being refilled (read-back-store) is accepted
    // in-cycle as long as its word has not been written to the data RAM
    // yet; it is merged into the refill write (second merge slot, the
    // later store wins over the store-miss merge at the same word).
    // There is exactly ONE merge slot: a second store arriving while a
    // merge is already pending must be refused (the LSU holds it and it
    // hits normally once the refill completes).  Accepting it would
    // overwrite the pending merge and silently lose the first store —
    // with a 1-word line every store maps to the same word offset, so
    // the old "same word" guard (req_wo != st_merge_wo) never fired.
    wire store_refill_ok = in_refill && cpu_req.valid && |cpu_req.strobe
        && is_cachable(cpu_req.addr, cpu_req.cacheable)
        && (req_idx == m_idx) && (req_tag == m_tag)
        && ((state != S_REFILL_WRITE) ||
            (rf_wr_cnt < req_wo))
        && !st_merge_pending;

    // ==================== Stall condition ====================
    logic s1_stall;
    always_comb begin
        s1_stall = 1'b0;
        if (state == S_INIT)
            s1_stall = 1'b1;
        else if (state != S_IDLE)
            s1_stall = 1'b1;
        else if (cacop_req.valid && cacop_req.code[2:0] == 3'd1 && !s2_valid)
            s1_stall = 1'b1;
    end

    // ==================== BRAM read control ====================
    // The data RAM read port (registered output, one-cycle latency) is
    // issued in the cycle before the output is consumed.  The 0-cycle load
    // hit paths (fast path, hit-under-miss) issue the read in the request
    // cycle with the request index, so the line data is ready when the WB
    // stage re-extracts dresp.data one cycle later (dresp.hit).
    always_comb begin
        data_rd_addr = '0;
        tag_rd_addr  = '0;

        // Priority: the 0-cycle request reads (fast path, hum) are listed
        // LAST so they win over the stale s1 read — with s2 cleared by a
        // hit the previous cycle, s1 can still hold the re-captured ghost
        // of the just-completed request, whose read must not displace the
        // current request's (the WB stage samples dresp.data one cycle
        // after the request; the read issued here is exactly that data).
        if (state == S_IDLE && s1_valid && is_cachable(s1_addr, s1_cacheable)) begin
            data_rd_addr = s1_idx;
            tag_rd_addr  = s1_idx;
        end
        if (state == S_MISS) begin
            data_rd_addr = m_idx;
            tag_rd_addr  = m_idx;
        end
        if (state == S_IDLE && cacop_req.valid && cacop_req.code[2:0] == 3'd1 && cacop_req.code[4:3] == 2'b01) begin
            data_rd_addr = cacop_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET];
            tag_rd_addr  = cacop_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET];
        end
        if (fast_path_req) begin
            data_rd_addr = req_idx;
        end
        if (hum_ok && !(|cpu_req.strobe)) begin
            data_rd_addr = req_idx;
        end
    end

    // ==================== Fast-path cpu_resp (data_ok/addr_ok, 独立于 FSM) ====================
    always_comb begin
        cpu_resp.addr_ok  = 1'b0;
        cpu_resp.data_ok  = 1'b0;
        cpu_resp.data     = 32'd0;
        cpu_resp.data_last = 1'b0;
        cpu_resp.hit      = 1'b0;
        cpu_resp.hit_way  = 1'b0;

        // Store AND load hits are served in the request cycle (0-cycle, the
        // store fast path + the load-hit fast path bypass the S1/S2 pipe).
        // Misses are accepted in the request cycle too (non-blocking): a
        // store miss completes immediately (data merged into the refilled
        // line), a load miss is acknowledged with addr_ok and receives its
        // data via the refill keyword forward.
        if (fast_path_req) begin
            if (req_hit) begin
                cpu_resp.addr_ok = 1'b1;
                cpu_resp.data_ok = 1'b1;
                if (!(|cpu_req.strobe)) begin
                    // Load hit: data_ok fires in the request cycle but the
                    // data (registered BRAM read) completes one cycle
                    // later; the WB stage re-extracts it from the full
                    // data port (dresp.hit + hit_way).
                    cpu_resp.hit     = 1'b1;
                    cpu_resp.hit_way = req_hit_way;
                    cpu_resp.data    = data_rd_out[req_hit_way][req_wo];
                end
            end else if (!cacop_d_pending) begin
                cpu_resp.addr_ok = 1'b1;
                if (|cpu_req.strobe)
                    cpu_resp.data_ok = 1'b1;
            end
        end

        if (state == S_IDLE && s2_valid && s2_hit && is_cachable(s2_addr, s2_cacheable)) begin
            cpu_resp.addr_ok = 1'b1;
            cpu_resp.data_ok = 1'b1;
            if (!s2_op) begin
                // S2 hit: the data read was issued at S1 and completes
                // exactly now — data_ok and data are same-cycle (0-delay
                // semantics), so the MEM stage captures it as usual
                // (hit=0, no WB re-extraction).
                cpu_resp.data = data_rd_out[s2_hit_way][s2_wo];
            end
        end

        if (state == S_UNCACHED && mem_resp.data_ok) begin
            // data_ok (combined): covers both uncached reads (rdata_ok)
            // and uncached writes (write completion); no other transaction
            // can be in flight in S_UNCACHED.
            cpu_resp.addr_ok = 1'b1;
            cpu_resp.data_ok = 1'b1;
            cpu_resp.data    = mem_resp.data;
        end

        if ((state inside {S_WB_WRITE, S_REFILL_WAIT}) && mem_resp.rdata_ok
            && !(&rf_fmask)
            && rf_cnt == m_wo && !rf_kw_sent && m_op == 1'b0) begin
            cpu_resp.addr_ok  = 1'b1;
            cpu_resp.data_ok  = 1'b1;
            cpu_resp.data     = mem_resp.data;
        end

        // Hit-under-miss: while a miss refills, hits to other lines are
        // served in the request cycle (loads always, stores when the data
        // write port is free).
        if (hum_ok) begin
            cpu_resp.addr_ok = 1'b1;
            cpu_resp.data_ok = 1'b1;
            if (!(|cpu_req.strobe)) begin
                // Registered-read load hit: data completes one cycle later
                // (read issued this cycle), consumed by the WB stage.
                cpu_resp.hit     = 1'b1;
                cpu_resp.hit_way = req_hit_way;
                cpu_resp.data    = data_rd_out[req_hit_way][req_wo];
            end
        end

        // Read-back store to the line being refilled: accept in-cycle and
        // merge into the refill write.
        if (store_refill_ok) begin
            cpu_resp.addr_ok = 1'b1;
            cpu_resp.data_ok = 1'b1;
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
                tag_wr_ena  = 1'b1;
                tag_wr_way  = init_wr_way;
                tag_wr_addr = init_addr;
                tag_wr_data = '0;
                if (init_wr_way == NR_WAYS - 1 && init_addr == NR_SETS - 1)
                    next_state = S_IDLE;
            end

            S_IDLE: begin
                if (cacop_req.valid && cacop_req.code[2:0] == 3'd1 && !s2_valid) begin
                    if (cacop_req.code[4:3] == 2'b00)
                        next_state = S_CACOP_ST;
                    else if (cacop_req.code[4:3] == 2'b01)
                        next_state = S_CACOP_WB_READ;
                end else if (fast_path_req) begin
                    if (req_hit) begin
                        if (|cpu_req.strobe) begin
                            data_wr_ena  = 1'b1;
                            data_wr_way  = req_hit_way;
                            data_wr_addr = req_idx;
                            data_wr_wo   = req_wo;
                            data_wr_we   = cpu_req.strobe;
                            data_wr_data = cpu_req.data;
                        end
                    end else if (!cacop_d_pending) begin
                        // Combinational miss accept: start the refill while
                        // the request is completed in the request cycle.
                        next_state = S_MISS;
                    end
                end else if (s2_valid) begin
                    if (!is_cachable(s2_addr, s2_cacheable)) begin
                        mem_req_next.valid  = 1'b1;
                        mem_req_next.addr   = {s2_addr[31:2], 2'b00};
                        mem_req_next.strobe = s2_op ? s2_wstrb : 4'd0;
                        mem_req_next.data   = s2_wdata;
                        if (mem_resp.addr_ok && mem_resp.data_ok)
                            ;
                        else
                            next_state = S_UNCACHED;
                    end else if (s2_hit) begin
                        if (s2_op) begin
                            data_wr_ena  = 1'b1;
                            data_wr_way  = s2_hit_way;
                            data_wr_addr = s2_idx;
                            data_wr_wo   = s2_wo;
                            data_wr_we   = s2_wstrb;
                            data_wr_data = s2_wdata;
                        end
                    end else begin
                        next_state = S_MISS;
                    end
                end
            end

            S_UNCACHED: begin
                if (mem_resp.data_ok) begin
                    next_state = S_IDLE;
                end else if (!mem_resp.addr_ok) begin
                    mem_req_next.valid  = 1'b1;
                    mem_req_next.addr   = {s2_addr[31:2], 2'b00};
                    mem_req_next.strobe = s2_op ? s2_wstrb : 4'd0;
                    mem_req_next.data   = s2_wdata;
                end
            end

            S_MISS: begin
                next_state = m_edirty ? S_WB_READ : S_REFILL_REQ;
            end

            S_WB_READ: begin
                // Capture the victim data only; issue the refill read FIRST.
                // The AXI read/write channels are independent, so the
                // writeback drain (S_WB_WRITE) overlaps the refill read in
                // flight and the load's keyword fires as soon as the read
                // completes — the writeback leaves the critical path.
                next_state = S_REFILL_REQ;
            end

            S_WB_WRITE: begin
                // Writeback drain on the AXI write channel, concurrent with
                // the refill read already in flight; refill beats arriving
                // here are collected (rf_buf/fmask/keyword forward, gated
                // on mem_resp.rdata_ok so the write completion cannot
                // corrupt the refill data path).
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
                // Exit on the beat mask: the refill may have completed
                // during the overlapped writeback drain.
                if (refill_fmask_done)
                    next_state = S_REFILL_WRITE;
            end

            S_REFILL_WRITE: begin
                data_wr_ena  = 1'b1;
                data_wr_way  = m_eway;
                data_wr_addr = m_idx;
                data_wr_wo   = rf_wr_cnt;
                if (st_merge_pending && rf_wr_cnt == st_merge_wo) begin
                    // Read-back store merged over the refill data (a later
                    // store than the store-miss merge, so it wins).
                    data_wr_we   = st_merge_strb;
                    data_wr_data = st_merge_data;
                end else if (m_op && rf_wr_cnt == m_wo) begin
                    // Merge the accepted store miss's bytes into the
                    // refilled line (write-allocate store completion).
                    data_wr_we   = m_wstrb;
                    data_wr_data = m_wdata;
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
                    ? S_IDLE
                    : S_REFILL_WRITE;
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
                next_state = cacop_edirty ? S_CACOP_WB_WRITE : S_CACOP_INV;
            end

            S_CACOP_WB_WRITE: begin
                mem_req_next.valid  = 1'b1;
                // cacop_wb_addr is built in a generate (below): with a
                // 1-word line WORD_WIDTH is 0 and the empty slice
                // cacop_wb_cnt[WORD_WIDTH-1:0] (= [-1:0]) is rejected by
                // some verilator versions and/or widened to 2 bits (the
                // concat then drops the top two tag bits of the writeback
                // address), so the 1-word form must not be elaborated.
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

        // Hit-under-miss store hit: the data write port is free in every
        // state except S_REFILL_WRITE (hum_ok already gates that out).
        if (hum_ok && |cpu_req.strobe) begin
            data_wr_ena  = 1'b1;
            data_wr_way  = req_hit_way;
            data_wr_addr = req_idx;
            data_wr_wo   = req_wo;
            data_wr_we   = cpu_req.strobe;
            data_wr_data = cpu_req.data;
        end
    end

    // ==================== Sequential logic ====================
    always_ff @(posedge clk) begin
        if (reset) begin
            state       <= S_INIT;
            s1_valid    <= 1'b0;
            s2_valid    <= 1'b0;
            just_hit    <= 1'b0;
            last_hit_addr <= 32'd0;
            for (int w = 0; w < NR_WAYS; w++)
                dirty[w]  <= '0;
            for (int p = 0; p < NR_WAYS-1; p++)
                plru[p]  <= '0;
            rf_fmask   <= '0;
            wb_cnt     <= '0;
            rf_cnt     <= '0;
            rf_wr_cnt  <= '0;
            rf_kw_sent <= 1'b0;
            m_wdata    <= 32'd0;
            m_wstrb    <= 4'd0;
            st_merge_pending <= 1'b0;
            st_merge_wo      <= '0;
            st_merge_data    <= 32'd0;
            st_merge_strb    <= 4'd0;
            mem_req_r  <= '{valid: 1'b0, addr: 32'd0, size: MSIZE4, strobe: 4'd0, data: 32'd0, cacheable: 1'b0, burst_len: 2'd0};
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

            if (!s1_stall) begin
                if (fast_path_req) begin
                    s1_valid <= 1'b0;
                end else begin
                s1_valid <= cpu_req.valid;
                s1_addr  <= cpu_req.addr;
                s1_op    <= |cpu_req.strobe;
                s1_size  <= cpu_req.size;
                s1_wdata <= cpu_req.data;
                s1_wstrb <= cpu_req.strobe;
                // Word offset as (addr >> 2) & mask: the slice form
                // addr[LINE_OFFSET-1:2] is a backward range when the line
                // is 1 word wide (rejected by some verilator versions);
                // the mask is 0 in that case, selecting word 0.
                s1_wo    <= woffset_t'((cpu_req.addr >> 2) & WOFF_MASK);
                s1_idx   <= cpu_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET];
                s1_tag   <= cpu_req.addr[31:INDEX_WIDTH+LINE_OFFSET];
                s1_cacheable <= cpu_req.cacheable;

                if (s2_hit || (just_hit && s1_addr == last_hit_addr)) begin
                    s2_valid <= 1'b0;
                end else begin
                    s2_valid <= s1_valid;
                    s2_addr  <= s1_addr;
                    s2_op    <= s1_op;
                    s2_size  <= s1_size;
                    s2_wdata <= s1_wdata;
                    s2_wstrb <= s1_wstrb;
                    s2_wo    <= s1_wo;
                    s2_idx   <= s1_idx;
                    s2_tag   <= s1_tag;
                    s2_cacheable <= s1_cacheable;
                end
                end
            end else if (state != S_IDLE) begin
                s1_valid <= 1'b0;
                s2_valid <= 1'b0;
            end else if (s2_valid) begin
                s2_valid <= 1'b0;
                s1_valid <= 1'b0;
            end

            if (fast_path_req) begin
                just_hit <= 1'b1;
                last_hit_addr <= cpu_req.addr;
            end else begin
                just_hit <= s2_valid && s2_hit;
                if (s2_valid && s2_hit)
                    last_hit_addr <= s2_addr;
            end

            if (fast_path_req && req_hit) begin
                if (NR_WAYS == 2) begin
                    plru[0][req_idx] <= ~req_hit_way;
                end else begin
                    int node = 0;
                    for (int b = WAY_BITS-1; b >= 0; b--) begin
                        plru[node][req_idx] <= ~req_hit_way[b];
                        node = 2*node + 1 + int'(req_hit_way[b]);
                    end
                end
                if (|cpu_req.strobe)
                    dirty[req_hit_way][req_idx] <= 1'b1;
            end

            // Hit-under-miss hits update PLRU/dirty like the S_IDLE hits.
            if (hum_ok) begin
                if (NR_WAYS == 2) begin
                    plru[0][req_idx] <= ~req_hit_way;
                end else begin
                    int node = 0;
                    for (int b = WAY_BITS-1; b >= 0; b--) begin
                        plru[node][req_idx] <= ~req_hit_way[b];
                        node = 2*node + 1 + int'(req_hit_way[b]);
                    end
                end
                if (|cpu_req.strobe)
                    dirty[req_hit_way][req_idx] <= 1'b1;
            end

            if (state == S_IDLE && s2_valid && s2_hit && is_cachable(s2_addr, s2_cacheable)) begin
                if (NR_WAYS == 2) begin
                    plru[0][s2_idx] <= ~s2_hit_way;
                end else begin
                    int node = 0;
                    for (int b = WAY_BITS-1; b >= 0; b--) begin
                        plru[node][s2_idx] <= ~s2_hit_way[b];
                        node = 2*node + 1 + int'(s2_hit_way[b]);
                    end
                end
                if (s2_op)
                    dirty[s2_hit_way][s2_idx] <= 1'b1;
            end

            if (state == S_IDLE && s2_valid && !s2_hit && is_cachable(s2_addr, s2_cacheable)
                && next_state == S_MISS) begin
                m_op     <= s2_op;
                m_wo     <= s2_wo;
                m_idx    <= s2_idx;
                m_tag    <= s2_tag;
                m_eway   <= victim_way(s2_idx);
                m_edirty <= dirty[victim_way(s2_idx)][s2_idx];
                m_etag   <= tag_r_tag[victim_way(s2_idx)];
                // The S2 miss path is taken for cacheable requests that
                // could not use the combinational fast path (a previous
                // request still in the S2 stage).  A store reaching the
                // S2 miss path must carry its data/strb to the refill
                // merge exactly like the fast-path miss accept does;
                // without this the refill writes stale m_wdata/m_wstrb
                // and the store's data is silently lost.
                m_wdata  <= s2_wdata;
                m_wstrb  <= s2_wstrb;
            end

            // Combinational miss accept: capture the miss context from the
            // request itself (the S1/S2 pipe is bypassed for cacheable
            // requests).  m_wdata/m_wstrb carry the accepted store's bytes
            // to the S_REFILL_WRITE merge.
            if (fast_path_miss && next_state == S_MISS) begin
                m_op     <= |cpu_req.strobe;
                m_wo     <= req_wo;
                m_idx    <= req_idx;
                m_tag    <= req_tag;
                m_eway   <= victim_way(req_idx);
                m_edirty <= dirty[victim_way(req_idx)][req_idx];
                m_etag   <= req_tag_data[victim_way(req_idx)][TAG_WIDTH:1];
                m_wdata  <= cpu_req.data;
                m_wstrb  <= cpu_req.strobe;
            end

            if (state == S_IDLE && cacop_req.valid
                && cacop_req.code[2:0] == 3'd1 && !s2_valid) begin
                cacop_way <= cacop_req.addr[WAY_BITS-1:0];
                // Index-based cacop ops decode the set with the SAME
                // parameterized line geometry as the data arrays.  The
                // CPUCFG-reported geometry (which the kernel's flush walk
                // follows) is parameterized in lockstep with the dcache
                // line size, so the walk covers every row exactly once.
                cacop_idx <= cacop_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET];
                // The dirty probe must decode from the CURRENT cycle's
                // address (like cacop_way above): using the registered
                // cacop_idx mixes this cycle's way with the PREVIOUS
                // cacop's set, which makes back-to-back flush ops read
                // the wrong row's dirty bit and drop the writeback.
                if (cacop_req.code[4:3] == 2'b00) begin
                    dirty[cacop_req.addr[WAY_BITS-1:0]][cacop_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET]] <= 1'b0;
                end
                if (cacop_req.code[4:3] == 2'b01) begin
                    cacop_edirty <= dirty[cacop_req.addr[WAY_BITS-1:0]][cacop_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET]];
                    cacop_wb_cnt <= '0;
                end
            end

            // Reset the refill context on ENTERING S_REFILL_REQ from any
            // state: with the writeback moved after the refill read, a
            // dirty miss reaches S_REFILL_REQ via S_WB_READ (S_MISS's
            // next_state is S_WB_READ), and the stale fmask must not gate
            // the new refill's beat collection.
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

            // Collect refill beats (read channel) — gated on rdata_ok and
            // the beat mask so the write channel's completion (bvalid,
            // data_ok) cannot corrupt rf_buf while the writeback drain
            // overlaps the refill read.
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
                if (rf_wr_cnt == NR_WORDS - 1) begin
                    // An accepted store miss and/or a merged read-back store
                    // modified the line, so it must be written back when
                    // evicted; a plain load refill leaves the line clean.
                    dirty[m_eway][m_idx] <= m_op || st_merge_pending;
                    st_merge_pending <= 1'b0;
                    if (NR_WAYS == 2) begin
                        plru[0][m_idx] <= ~m_eway;
                    end else begin
                        int node = 0;
                        for (int b = WAY_BITS-1; b >= 0; b--) begin
                            plru[node][m_idx] <= ~m_eway[b];
                            node = 2*node + 1 + int'(m_eway[b]);
                        end
                    end
                end
            end

            // Read-back store to the refilling line: latch the merge slot.
            // The flag is held until the refill completes (not cleared at
            // the merge) so the dirty bit at the completion sees it — a
            // merged store modified the line and it must be written back
            // when evicted.
            if (store_refill_ok) begin
                st_merge_pending <= 1'b1;
                st_merge_wo      <= req_wo;
                st_merge_data    <= cpu_req.data;
                st_merge_strb    <= cpu_req.strobe;
            end

            if (state == S_CACOP_WB_READ) begin
                cacop_etag      <= tag_r_tag[cacop_way];
                for (int n = 0; n < NR_WORDS; n++)
                    cacop_wb_buf[n] <= data_rd_out[cacop_way][n];
            end

            if (state == S_CACOP_WB_WRITE && mem_resp.addr_ok) begin
                cacop_wb_cnt <= cacop_wb_cnt + 1;
            end

            if (state == S_CACOP_INV) begin
                dirty[cacop_way][cacop_idx] <= 1'b0;
            end
        end
    end

    assign mem_req = mem_req_r;
    assign data_wb = data_rd_out;

    logic [63:0] access_cnt, hit_cnt, miss_cnt, wb_cnt64;
    logic [63:0] fast_load_cnt;
    logic [63:0] fast_hum_cnt;
    assign perf_access    = access_cnt;
    assign perf_hit       = hit_cnt;
    assign perf_miss      = miss_cnt;
    assign perf_writeback = wb_cnt64;
    assign perf_fast_load = fast_load_cnt;
    assign perf_fast_hum  = fast_hum_cnt;

    always_ff @(posedge clk) begin
        if (reset) begin
            access_cnt <= 64'd0;
            hit_cnt    <= 64'd0;
            miss_cnt   <= 64'd0;
            wb_cnt64   <= 64'd0;
            fast_load_cnt <= 64'd0;
            fast_hum_cnt  <= 64'd0;
        end else begin
            if (state == S_IDLE && s2_valid && is_cachable(s2_addr, s2_cacheable)) begin
                access_cnt <= access_cnt + 64'd1;
                if (s2_hit)
                    hit_cnt <= hit_cnt + 64'd1;
                else
                    miss_cnt <= miss_cnt + 64'd1;
            end
            if (fast_path_req) begin
                access_cnt <= access_cnt + 64'd1;
                if (req_hit) begin
                    hit_cnt <= hit_cnt + 64'd1;
                    if (!(|cpu_req.strobe))
                        fast_load_cnt <= fast_load_cnt + 64'd1;
                end else
                    miss_cnt <= miss_cnt + 64'd1;
            end
            if (hum_ok) begin
                access_cnt <= access_cnt + 64'd1;
                hit_cnt    <= hit_cnt + 64'd1;
                fast_hum_cnt <= fast_hum_cnt + 64'd1;
                if (!(|cpu_req.strobe))
                    fast_load_cnt <= fast_load_cnt + 64'd1;
            end
            if (store_refill_ok) begin
                access_cnt <= access_cnt + 64'd1;
                hit_cnt    <= hit_cnt + 64'd1;
                fast_hum_cnt <= fast_hum_cnt + 64'd1;
            end
            if (state == S_WB_WRITE && mem_resp.addr_ok)
                wb_cnt64 <= wb_cnt64 + 64'd1;
            if (state == S_CACOP_WB_WRITE && mem_resp.addr_ok)
                wb_cnt64 <= wb_cnt64 + 64'd1;
        end
    end

endmodule
