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

    output logic        in_refill
);

    parameter int NR_SETS = 256;
    parameter int NR_WAYS = 2;
    parameter int NR_WORDS = 4;
    localparam WORD_WIDTH  = $clog2(NR_WORDS);
    localparam LINE_OFFSET = WORD_WIDTH + 2;
    localparam INDEX_WIDTH = $clog2(NR_SETS);
    localparam TAG_WIDTH   = 32 - LINE_OFFSET - INDEX_WIDTH;
    localparam WAY_BITS    = $clog2(NR_WAYS);
    localparam CNT_WIDTH   = (NR_WORDS == 1) ? 1 : WORD_WIDTH;

    typedef logic [WORD_WIDTH-1:0] woffset_t;
    typedef logic [INDEX_WIDTH-1:0] index_t;
    typedef logic [TAG_WIDTH-1:0] tag_t;
    typedef logic [WAY_BITS-1:0] way_t;

    // ==================== Data BRAM ====================
    logic        data_rd_ena;
    index_t      data_rd_addr;
    logic [31:0] data_rd_out [0:NR_WAYS-1][0:NR_WORDS-1];
    logic        data_wr_ena;
    way_t        data_wr_way;
    index_t      data_wr_addr;
    woffset_t    data_wr_wo;
    logic [3:0]  data_wr_we;
    logic [31:0] data_wr_data;

    generate
        for (genvar gw = 0; gw < NR_WAYS; gw++) begin : g_data_way
            for (genvar gb = 0; gb < NR_WORDS; gb++) begin : g_data_word
                (* ram_style = "block" *) logic [31:0] mem [NR_SETS-1:0];
                logic wen;
                assign wen = data_wr_ena && (data_wr_way == way_t'(gw)) && (data_wr_wo == woffset_t'(gb));

                always_ff @(posedge clk) begin
                    if (wen) begin
                        if (data_wr_we[0]) mem[data_wr_addr][ 7: 0] <= data_wr_data[ 7: 0];
                        if (data_wr_we[1]) mem[data_wr_addr][15: 8] <= data_wr_data[15: 8];
                        if (data_wr_we[2]) mem[data_wr_addr][23:16] <= data_wr_data[23:16];
                        if (data_wr_we[3]) mem[data_wr_addr][31:24] <= data_wr_data[31:24];
                    end
                    if (data_rd_ena)
                        data_rd_out[gw][gb] <= mem[data_rd_addr];
                end
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

    always_ff @(posedge clk) begin
        if (tag_wr_ena)
            tag_mem[tag_wr_way][tag_wr_addr] <= tag_wr_data;
    end

    always_ff @(posedge clk) begin
        for (int w = 0; w < NR_WAYS; w++)
            tag_rd_data[w] <= tag_mem[w][tag_rd_addr];
    end

    // ==================== Dirty + PLRU ====================
    (* ram_style = "distributed" *) logic [NR_SETS-1:0] dirty [0:NR_WAYS-1];
    (* ram_style = "distributed" *) logic [NR_SETS-1:0] plru [0:NR_WAYS-2];

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
    assign req_wo  = cpu_req.addr[LINE_OFFSET-1:2];

    logic [TAG_WIDTH:0] req_tag_data [0:NR_WAYS-1];
    always_comb begin
        for (int w = 0; w < NR_WAYS; w++)
            req_tag_data[w] = tag_mem[w][req_idx];
    end

    logic req_hit;
    way_t req_hit_way;

    always_comb begin
        automatic logic [NR_WAYS-1:0] hit_vec;
        hit_vec = '0;
        for (int w = 0; w < NR_WAYS; w++)
            hit_vec[w] = req_tag_data[w][0]
                && (req_tag_data[w][TAG_WIDTH:1] == req_tag)
                && is_cachable(cpu_req.addr, cpu_req.cacheable);
        req_hit = |hit_vec && (state == S_IDLE);
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
    always_comb begin
        data_rd_ena = 1'b0;
        data_rd_addr = '0;
        tag_rd_addr  = '0;

        if (state == S_IDLE && s1_valid && is_cachable(s1_addr, s1_cacheable)) begin
            data_rd_ena = 1'b1;
            data_rd_addr = s1_idx;
            tag_rd_addr  = s1_idx;
        end
        if (state == S_MISS) begin
            data_rd_ena = 1'b1;
            data_rd_addr = m_idx;
            tag_rd_addr  = m_idx;
        end
        if (state == S_IDLE && cacop_req.valid && cacop_req.code[2:0] == 3'd1 && cacop_req.code[4:3] == 2'b01) begin
            data_rd_ena = 1'b1;
            data_rd_addr = cacop_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET];
            tag_rd_addr  = cacop_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET];
        end
    end

    // ==================== Fast-path cpu_resp (data_ok/addr_ok, 独立于 FSM) ====================
    always_comb begin
        cpu_resp.addr_ok  = 1'b0;
        cpu_resp.data_ok  = 1'b0;
        cpu_resp.data     = 32'd0;
        cpu_resp.data_last = 1'b0;

        if (state == S_IDLE && !s2_valid && cpu_req.valid && |cpu_req.strobe
            && is_cachable(cpu_req.addr, cpu_req.cacheable) && req_hit) begin
            cpu_resp.addr_ok = 1'b1;
            cpu_resp.data_ok = 1'b1;
        end

        if (state == S_IDLE && s2_valid && s2_hit && is_cachable(s2_addr, s2_cacheable)) begin
            cpu_resp.addr_ok = 1'b1;
            cpu_resp.data_ok = 1'b1;
            if (!s2_op)
                cpu_resp.data = data_rd_out[s2_hit_way][s2_wo];
        end

        if (state == S_UNCACHED && mem_resp.data_ok) begin
            cpu_resp.addr_ok = 1'b1;
            cpu_resp.data_ok = 1'b1;
            cpu_resp.data    = mem_resp.data;
        end

        if (state == S_REFILL_WAIT && mem_resp.data_ok
            && rf_cnt == m_wo && !rf_kw_sent && m_op == 1'b0) begin
            cpu_resp.addr_ok  = 1'b1;
            cpu_resp.data_ok  = 1'b1;
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
                end else if (!s2_valid && cpu_req.valid && |cpu_req.strobe
                           && is_cachable(cpu_req.addr, cpu_req.cacheable) && req_hit) begin
                    data_wr_ena  = 1'b1;
                    data_wr_way  = req_hit_way;
                    data_wr_addr = req_idx;
                    data_wr_wo   = req_wo;
                    data_wr_we   = cpu_req.strobe;
                    data_wr_data = cpu_req.data;
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
                next_state = S_WB_WRITE;
            end

            S_WB_WRITE: begin
                mem_req_next.valid  = 1'b1;
                mem_req_next.addr   = {m_etag, m_idx, {WORD_WIDTH{1'b0}}, 2'b00};
                mem_req_next.strobe = 4'b1111;
                mem_req_next.data   = wb_buf[wb_cnt];
                mem_req_next.burst_len = NR_WORDS - 1;
                if (mem_resp.addr_ok)
                    next_state = (wb_cnt == NR_WORDS - 1) ? S_REFILL_REQ : S_WB_WRITE;
            end

            S_REFILL_REQ: begin
                mem_req_next.valid  = 1'b1;
                mem_req_next.addr   = {m_tag, m_idx, {WORD_WIDTH{1'b0}}, 2'b00};
                mem_req_next.burst_len = NR_WORDS - 1;
                if (mem_resp.addr_ok)
                    next_state = S_REFILL_WAIT;
            end

            S_REFILL_WAIT: begin
                if (mem_resp.data_ok) begin
                    if (mem_resp.data_last)
                        next_state = S_REFILL_WRITE;
                end
            end

            S_REFILL_WRITE: begin
                data_wr_ena  = 1'b1;
                data_wr_way  = m_eway;
                data_wr_addr = m_idx;
                data_wr_wo   = rf_wr_cnt;
                data_wr_we   = 4'b1111;
                data_wr_data = rf_buf[rf_wr_cnt];
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
                mem_req_next.addr   = {cacop_etag, cacop_idx, cacop_wb_cnt, 2'b00};
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
                if (state == S_IDLE && !s2_valid && cpu_req.valid && |cpu_req.strobe
                    && is_cachable(cpu_req.addr, cpu_req.cacheable) && req_hit) begin
                    s1_valid <= 1'b0;
                end else begin
                s1_valid <= cpu_req.valid;
                s1_addr  <= cpu_req.addr;
                s1_op    <= |cpu_req.strobe;
                s1_size  <= cpu_req.size;
                s1_wdata <= cpu_req.data;
                s1_wstrb <= cpu_req.strobe;
                s1_wo    <= cpu_req.addr[LINE_OFFSET-1:2];
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

            if (state == S_IDLE && !s2_valid && cpu_req.valid && |cpu_req.strobe
                && is_cachable(cpu_req.addr, cpu_req.cacheable) && req_hit) begin
                just_hit <= 1'b1;
                last_hit_addr <= cpu_req.addr;
            end else begin
                just_hit <= s2_valid && s2_hit;
                if (s2_valid && s2_hit)
                    last_hit_addr <= s2_addr;
            end

            if (state == S_IDLE && !s2_valid && cpu_req.valid && |cpu_req.strobe
                && is_cachable(cpu_req.addr, cpu_req.cacheable) && req_hit) begin
                if (NR_WAYS == 2) begin
                    plru[0][req_idx] <= ~req_hit_way;
                end else begin
                    int node = 0;
                    for (int b = WAY_BITS-1; b >= 0; b--) begin
                        plru[node][req_idx] <= ~req_hit_way[b];
                        node = 2*node + 1 + int'(req_hit_way[b]);
                    end
                end
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
            end

            if (state == S_IDLE && cacop_req.valid
                && cacop_req.code[2:0] == 3'd1 && !s2_valid) begin
                cacop_way <= cacop_req.addr[WAY_BITS-1:0];
                cacop_idx <= cacop_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET];
                if (cacop_req.code[4:3] == 2'b00) begin
                    dirty[cacop_req.addr[WAY_BITS-1:0]][cacop_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET]] <= 1'b0;
                end
                if (cacop_req.code[4:3] == 2'b01) begin
                    cacop_edirty <= dirty[cacop_req.addr[WAY_BITS-1:0]][cacop_req.addr[INDEX_WIDTH+LINE_OFFSET-1:LINE_OFFSET]];
                    cacop_wb_cnt <= '0;
                end
            end

            if (state == S_MISS && next_state == S_REFILL_REQ) begin
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

            if (state == S_WB_WRITE && mem_resp.addr_ok) begin
                wb_cnt <= wb_cnt + 1;
                if (wb_cnt == NR_WORDS - 1) begin
                    rf_cnt     <= '0;
                    rf_fmask   <= '0;
                    rf_kw_sent <= 1'b0;
                end
            end

            if (state == S_REFILL_WAIT && mem_resp.data_ok) begin
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
                    dirty[m_eway][m_idx] <= 1'b0;
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

    logic [63:0] access_cnt, hit_cnt, miss_cnt, wb_cnt64;
    assign perf_access    = access_cnt;
    assign perf_hit       = hit_cnt;
    assign perf_miss      = miss_cnt;
    assign perf_writeback = wb_cnt64;

    always_ff @(posedge clk) begin
        if (reset) begin
            access_cnt <= 64'd0;
            hit_cnt    <= 64'd0;
            miss_cnt   <= 64'd0;
            wb_cnt64   <= 64'd0;
        end else begin
            if (state == S_IDLE && s2_valid && is_cachable(s2_addr, s2_cacheable)) begin
                access_cnt <= access_cnt + 64'd1;
                if (s2_hit)
                    hit_cnt <= hit_cnt + 64'd1;
                else
                    miss_cnt <= miss_cnt + 64'd1;
            end
            if (state == S_IDLE && !s2_valid && cpu_req.valid && |cpu_req.strobe
                && is_cachable(cpu_req.addr, cpu_req.cacheable) && req_hit) begin
                access_cnt <= access_cnt + 64'd1;
                hit_cnt <= hit_cnt + 64'd1;
            end
            if (state == S_WB_WRITE && mem_resp.addr_ok)
                wb_cnt64 <= wb_cnt64 + 64'd1;
            if (state == S_CACOP_WB_WRITE && mem_resp.addr_ok)
                wb_cnt64 <= wb_cnt64 + 64'd1;
        end
    end

endmodule
