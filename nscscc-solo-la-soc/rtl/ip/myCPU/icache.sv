`include "common.sv"

module icache import la32_common::*; (
    input  logic       clk,
    input  logic       reset,
    input  logic       inv_all,

    input  ibus_req_t  cpu_req,
    output ibus_resp_t cpu_resp,

    output ibus_req_t  mem_req,
    input  ibus_resp_t mem_resp,

    input  cacop_req_t cacop_req,
    output logic       cacop_done,

    output logic [63:0] perf_access,
    output logic [63:0] perf_hit,
    output logic [63:0] perf_miss,
    output logic [63:0] perf_wa_clear,
    output logic [63:0] perf_s1_accept,
    output logic [63:0] perf_cyc,

    output logic        in_refill
);

    parameter int NR_SETS = 256;
    localparam NR_WORDS = 4;
    localparam INDEX_WIDTH = $clog2(NR_SETS);
    localparam TAG_WIDTH = 32 - 4 - INDEX_WIDTH;

    typedef logic [1:0] woffset_t;
    typedef logic [INDEX_WIDTH-1:0] index_t;
    typedef logic [TAG_WIDTH-1:0] tag_t;

    // ==================== Request extraction ====================
    wire index_t   req_idx;
    wire tag_t     req_tag;
    wire woffset_t req_wo;
    assign req_idx = cpu_req.addr[INDEX_WIDTH+3:4];
    assign req_tag = cpu_req.addr[31:INDEX_WIDTH+4];
    assign req_wo  = cpu_req.addr[3:2];

    // ==================== Data LUTRAM (combinational read) ====================
    logic        data_wr_ena;
    logic        data_wr_way;
    index_t      data_wr_addr;
    logic [1:0]  data_wr_wo;
    logic [31:0] data_wr_data;

    logic [31:0] data_rd_out [0:1][0:3];

    generate
        for (genvar gw = 0; gw < 2; gw++) begin : g_data_way
            for (genvar gb = 0; gb < 4; gb++) begin : g_data_word
                logic wen;
                assign wen = data_wr_ena && (data_wr_way == 1'(gw)) && (data_wr_wo == 2'(gb));

                // 0-cycle hit: the instruction must be valid in the same
                // cycle as data_ok (the fetch unit captures it at the
                // IF/ID edge), so the data read is combinational
                // (READ_LATENCY = 0 -> distributed RAM).
                ram_sdpram #(
                    .ADDR_WIDTH(INDEX_WIDTH),
                    .DATA_WIDTH(32),
                    .BYTE_WIDTH(8),
                    .READ_LATENCY(0)
                ) u_data_ram (
                    .clk,
                    .raddr(req_idx),
                    .waddr(data_wr_addr),
                    .en(wen),
                    .strobe(4'hf),
                    .wdata(data_wr_data),
                    .rdata(data_rd_out[gw][gb])
                );
            end
        end
    endgenerate

    // ==================== Tag LUTRAM (combinational read) ====================
    logic [1:0]         tag_wr_ena;
    index_t             tag_wr_addr;
    logic [TAG_WIDTH:0] tag_wr_data [0:1];

    logic [TAG_WIDTH:0] tag_rd_data [0:1];

    generate
        for (genvar gw = 0; gw < 2; gw++) begin : g_tag_way
            ram_sdpram #(
                .ADDR_WIDTH(INDEX_WIDTH),
                .DATA_WIDTH(TAG_WIDTH + 1),
                .BYTE_WIDTH(TAG_WIDTH + 1),
                .READ_LATENCY(0)
            ) u_tag_ram (
                .clk,
                .raddr(req_idx),
                .waddr(tag_wr_addr),
                .en(tag_wr_ena[gw]),
                .strobe(1'b1),
                .wdata(tag_wr_data[gw]),
                .rdata(tag_rd_data[gw])
            );
        end
    endgenerate

    logic [TAG_WIDTH:0] req_tag_data [0:1];
    always_comb begin
        req_tag_data[0] = tag_rd_data[0];
        req_tag_data[1] = tag_rd_data[1];
    end

    // ==================== PLRU (distributed RAM) ====================
    (* ram_style = "distributed" *) logic [NR_SETS-1:0] plru;

    // ==================== State ====================
    enum logic [2:0] {
        S_INIT,
        S_IDLE,
        S_MISS,
        S_REFILL_REQ, S_REFILL_WAIT, S_REFILL_WRITE,
        S_CACOP_ST
    } state, next_state;

    ibus_req_t  mem_req_next;
    ibus_req_t  mem_req_r;

    // ==================== Combinational hit detection ====================
    logic req_hit;
    logic req_hit_way;

    always_comb begin
        automatic logic h0, h1;
        h0 = req_tag_data[0][0] && (req_tag_data[0][TAG_WIDTH:1] == req_tag);
        h1 = req_tag_data[1][0] && (req_tag_data[1][TAG_WIDTH:1] == req_tag);
        req_hit = (state == S_IDLE) && (h0 || h1);
        req_hit_way = h0 ? 1'b0 : 1'b1;
    end

    // ==================== Ghost hit prevention ====================
    logic       just_hit;
    word_t      last_hit_addr;
    wire        ghost;
    assign ghost = just_hit && (cpu_req.addr == last_hit_addr);

    // ==================== PLRU victim ====================
    function automatic logic victim_way(input index_t i);
        return ~plru[i];
    endfunction

    // ==================== Miss context ====================
    woffset_t   m_wo;
    index_t     m_idx;
    tag_t       m_tag;
    logic       m_eway;

    // ==================== Refill registers ====================
    logic [1:0] rf_cnt;
    logic [3:0] rf_fmask;
    logic       rf_kw_sent;
    word_t      rf_buf [0:3];

    // ==================== Init registers ====================
    index_t init_addr;

    // ==================== FSM combinational ====================
    always_comb begin
        next_state = state;

        cpu_resp.addr_ok = 1'b0;
        cpu_resp.data_ok = 1'b0;
        cpu_resp.data    = 32'd0;

        cacop_done = 1'b0;

        mem_req_next.valid = 1'b0;
        mem_req_next.addr  = 32'd0;

        data_wr_ena  = 1'b0;
        data_wr_way  = 1'b0;
        data_wr_addr = '0;
        data_wr_wo   = 2'd0;
        data_wr_data = 32'd0;

        tag_wr_ena     = 2'b00;
        tag_wr_addr    = '0;
        tag_wr_data[0] = '0;
        tag_wr_data[1] = '0;

        case (state)

            S_INIT: begin
                tag_wr_ena     = 2'b11;
                tag_wr_addr    = init_addr;
                tag_wr_data[0] = '0;
                tag_wr_data[1] = '0;
                if (init_addr == NR_SETS - 1)
                    next_state = S_IDLE;
            end

            S_IDLE: begin
                if (cacop_req.valid && cacop_req.code[2:0] == 3'd0) begin
                    next_state = S_CACOP_ST;
                end else if (req_hit) begin
                    cpu_resp.addr_ok = 1'b1;
                    cpu_resp.data_ok = 1'b1;
                    cpu_resp.data    = data_rd_out[req_hit_way][req_wo];
                end else if (cpu_req.valid && !ghost) begin
                    // Acknowledge the miss so the fetch_unit enters WAIT_DATA
                    // and latches the missing fetch's pc (captured_pc). The
                    // refill keyword forward is then paired with that pc —
                    // without the ack, the forward pairs with whatever
                    // pc_current is at the keyword's arrival, which can be a
                    // redirect target, corrupting the fetched instruction.
                    cpu_resp.addr_ok = 1'b1;
                    next_state = S_MISS;
                end
            end

            S_MISS: begin
                next_state = S_REFILL_REQ;
            end

            S_REFILL_REQ: begin
                mem_req_next.valid = 1'b1;
                mem_req_next.addr  = {m_tag, m_idx, rf_cnt, 2'b00};
                if (mem_resp.addr_ok)
                    next_state = S_REFILL_WAIT;
            end

            S_REFILL_WAIT: begin
                if (mem_resp.data_ok) begin
                    // Forward the keyword only while the requester still
                    // wants this address: a redirect (EX branch mispredict /
                    // ID / BP redirect) can move cpu_req.addr away from the
                    // refilling line while the refill is in flight. The
                    // forward would otherwise be captured against the new
                    // pc, silently replacing the redirected target's
                    // instruction (the fetch_unit abandons the stale wait
                    // and re-issues for the current pc).
                    if (rf_cnt == m_wo && !rf_kw_sent &&
                        cpu_req.addr[31:2] == {m_tag, m_idx, m_wo}) begin
                        cpu_resp.addr_ok = 1'b1;
                        cpu_resp.data_ok = 1'b1;
                        cpu_resp.data    = mem_resp.data;
                    end
                    next_state = (&(rf_fmask | (4'd1 << rf_cnt)))
                        ? S_REFILL_WRITE : S_REFILL_REQ;
                end
            end

            S_REFILL_WRITE: begin
                data_wr_ena  = 1'b1;
                data_wr_way  = m_eway;
                data_wr_addr = m_idx;
                data_wr_wo   = rf_cnt;
                data_wr_data = rf_buf[rf_cnt];
                if (rf_cnt == 2'd0) begin
                    tag_wr_ena[m_eway]  = 1'b1;
                    tag_wr_addr         = m_idx;
                    tag_wr_data[m_eway] = {m_tag, 1'b1};
                end
                next_state = (rf_cnt == 2'd3)
                    ? S_IDLE
                    : S_REFILL_WRITE;
            end

            S_CACOP_ST: begin
                tag_wr_ena[cacop_req.addr[0]]   = 1'b1;
                tag_wr_addr                      = cacop_req.addr[INDEX_WIDTH+3:4];
                tag_wr_data[cacop_req.addr[0]]   = '0;
                cacop_done = 1'b1;
                next_state = S_IDLE;
            end

            default: next_state = S_IDLE;
        endcase
    end

    // ==================== Sequential logic ====================
    always_ff @(posedge clk) begin
        if (reset) begin
            state       <= S_INIT;
            just_hit    <= 1'b0;
            plru        <= '0;
            rf_fmask    <= 4'd0;
            rf_cnt      <= 2'd0;
            rf_kw_sent  <= 1'b0;
            mem_req_r   <= '{valid: 1'b0, addr: 32'd0};
            init_addr   <= '0;
        end else begin
            state <= next_state;
            mem_req_r <= mem_req_next;

            if (inv_all) begin
                state <= S_INIT;
                init_addr <= '0;
                plru      <= '0;
            end

            if (state == S_INIT) begin
                if (init_addr != NR_SETS - 1)
                    init_addr <= init_addr + 1;
                else begin
                    init_addr <= '0;
                    plru      <= '0;
                end
            end

            just_hit <= cpu_resp.data_ok;
            if (cpu_resp.data_ok)
                last_hit_addr <= cpu_req.addr;

            if (state == S_IDLE && req_hit) begin
                plru[req_idx] <= req_hit_way;
            end

            if (state == S_IDLE && cpu_req.valid && !ghost && !req_hit
                && next_state == S_MISS) begin
                m_wo   <= req_wo;
                m_idx  <= req_idx;
                m_tag  <= req_tag;
                m_eway <= victim_way(req_idx);
            end

            if (state == S_MISS && next_state == S_REFILL_REQ) begin
                rf_cnt     <= m_wo;
                rf_fmask   <= 4'd0;
                rf_kw_sent <= 1'b0;
            end

            if (state == S_REFILL_WAIT && mem_resp.data_ok) begin
                rf_buf[rf_cnt]   <= mem_resp.data;
                rf_fmask[rf_cnt] <= 1'b1;
                if (rf_cnt == m_wo && !rf_kw_sent)
                    rf_kw_sent <= 1'b1;
                rf_cnt <= (rf_cnt == 2'd3) ? 2'd0 : (rf_cnt + 1);
            end

            if (state == S_REFILL_WRITE) begin
                rf_cnt <= rf_cnt + 1;
                if (rf_cnt == 2'd3) begin
                    plru[m_idx] <= m_eway;
                end
            end
        end
    end

    assign mem_req = mem_req_r;

    // ==================== Performance counters ====================
    logic [63:0] access_cnt, hit_cnt, miss_cnt;
    logic [63:0] wa_clear_cnt, s1_accept_cnt, cyc_cnt;
    assign perf_access    = access_cnt;
    assign perf_hit       = hit_cnt;
    assign perf_miss      = miss_cnt;
    assign perf_wa_clear  = wa_clear_cnt;
    assign perf_s1_accept = s1_accept_cnt;
    assign perf_cyc       = cyc_cnt;

    always_ff @(posedge clk) begin
        if (reset) begin
            access_cnt    <= 64'd0;
            hit_cnt       <= 64'd0;
            miss_cnt      <= 64'd0;
            wa_clear_cnt  <= 64'd0;
            s1_accept_cnt <= 64'd0;
            cyc_cnt       <= 64'd0;
        end else begin
            cyc_cnt <= cyc_cnt + 64'd1;

            if (state == S_IDLE && !ghost) begin
                access_cnt <= access_cnt + 64'd1;
                if (req_hit) begin
                    hit_cnt <= hit_cnt + 64'd1;
                    wa_clear_cnt <= wa_clear_cnt + 64'd1;
                end else begin
                    miss_cnt <= miss_cnt + 64'd1;
                end
            end

            if (state == S_IDLE)
                s1_accept_cnt <= s1_accept_cnt + 64'd1;
        end
    end

endmodule
