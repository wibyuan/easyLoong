`include "common.sv"

module icache import la32_common::*; (
    input  logic       clk,
    input  logic       reset,
    input  logic       inv_all,

    input  ibus_req_t  cpu_req,
    output ibus_resp_t cpu_resp,

    output ibus_req_t  mem_req,
    input  ibus_resp_t mem_resp
);

    localparam NR_SETS  = 256;
    localparam NR_WORDS = 4;

    typedef logic [1:0] woffset_t;
    typedef logic [7:0] index_t;
    typedef logic [19:0] tag_t;

    // ==================== Data BRAM ====================
    (* ram_style = "block" *) logic [31:0] data_mem [0:1][0:3][NR_SETS-1:0];
    logic        data_rd_ena;
    index_t      data_rd_addr;
    logic [31:0] data_rd_out [0:1][0:3];
    logic        data_wr_ena;
    logic        data_wr_way;
    index_t      data_wr_addr;
    logic [1:0]  data_wr_wo;
    logic [31:0] data_wr_data;

    always_ff @(posedge clk) begin
        if (data_wr_ena)
            data_mem[data_wr_way][data_wr_wo][data_wr_addr] <= data_wr_data;
        if (data_rd_ena) begin
            data_rd_out[0][0] <= data_mem[0][0][data_rd_addr];
            data_rd_out[0][1] <= data_mem[0][1][data_rd_addr];
            data_rd_out[0][2] <= data_mem[0][2][data_rd_addr];
            data_rd_out[0][3] <= data_mem[0][3][data_rd_addr];
            data_rd_out[1][0] <= data_mem[1][0][data_rd_addr];
            data_rd_out[1][1] <= data_mem[1][1][data_rd_addr];
            data_rd_out[1][2] <= data_mem[1][2][data_rd_addr];
            data_rd_out[1][3] <= data_mem[1][3][data_rd_addr];
        end
    end

    // ==================== Tag BRAM ====================
    (* ram_style = "block" *) logic [20:0] tag_mem [0:1][NR_SETS-1:0];
    logic        tag_rd_ena;
    index_t      tag_rd_addr;
    logic [20:0] tag_rd_data [0:1];
    logic [1:0]  tag_wr_ena;
    index_t      tag_wr_addr;
    logic [20:0] tag_wr_data [0:1];

    always_ff @(posedge clk) begin
        if (tag_wr_ena[0])
            tag_mem[0][tag_wr_addr] <= tag_wr_data[0];
        if (tag_wr_ena[1])
            tag_mem[1][tag_wr_addr] <= tag_wr_data[1];
        if (tag_rd_ena) begin
            tag_rd_data[0] <= tag_mem[0][tag_rd_addr];
            tag_rd_data[1] <= tag_mem[1][tag_rd_addr];
        end
    end

    // ==================== PLRU ====================
    logic [NR_SETS-1:0] plru;

    // ==================== State ====================
    enum logic [2:0] {
        S_INIT,
        S_IDLE,
        S_MISS,
        S_REFILL_REQ, S_REFILL_WAIT, S_REFILL_WRITE
    } state, next_state;

    ibus_req_t  mem_req_next;
    ibus_req_t  mem_req_r;

    // ==================== Pipeline ====================
    logic       s1_valid;
    word_t      s1_addr;
    woffset_t   s1_wo;
    index_t     s1_idx;
    tag_t       s1_tag;

    logic       s2_valid;
    word_t      s2_addr;
    woffset_t   s2_wo;
    index_t     s2_idx;
    tag_t       s2_tag;

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

    // ==================== Helper functions ====================
    function automatic logic victim_way(input index_t i);
        return ~plru[i];
    endfunction

    // ==================== S2 hit ====================
    wire [19:0] tag_r_tag [0:1];
    wire        tag_r_v   [0:1];
    assign tag_r_tag[0] = tag_rd_data[0][20:1];
    assign tag_r_tag[1] = tag_rd_data[1][20:1];
    assign tag_r_v[0] = tag_rd_data[0][0];
    assign tag_r_v[1] = tag_rd_data[1][0];

    logic s2_hit, s2_hit_way;

    always_comb begin
        automatic logic h0, h1;
        h0 = s2_valid && tag_r_v[0] && (tag_r_tag[0] == s2_tag);
        h1 = s2_valid && tag_r_v[1] && (tag_r_tag[1] == s2_tag);
        s2_hit = h0 || h1;
        s2_hit_way = h0 ? 1'b0 : 1'b1;
    end

    // ==================== Stall condition ====================
    logic s1_stall;
    always_comb begin
        s1_stall = 1'b0;
        if (state == S_INIT)
            s1_stall = 1'b1;
        else if (state != S_IDLE)
            s1_stall = 1'b1;
    end

    // ==================== BRAM read control ====================
    always_comb begin
        data_rd_ena  = 1'b0;
        data_rd_addr = 8'd0;
        tag_rd_ena   = 1'b0;
        tag_rd_addr  = 8'd0;

        if (state == S_IDLE && s1_valid) begin
            data_rd_ena  = 1'b1;
            data_rd_addr = s1_idx;
            tag_rd_ena   = 1'b1;
            tag_rd_addr  = s1_idx;
        end
        if (state == S_MISS) begin
            data_rd_ena  = 1'b1;
            data_rd_addr = m_idx;
            tag_rd_ena   = 1'b1;
            tag_rd_addr  = m_idx;
        end
    end

    // ==================== FSM combinational ====================
    always_comb begin
        next_state = state;

        cpu_resp.addr_ok = 1'b0;
        cpu_resp.data_ok = 1'b0;
        cpu_resp.data    = 32'd0;

        mem_req_next.valid = 1'b0;
        mem_req_next.addr  = 32'd0;

        data_wr_ena  = 1'b0;
        data_wr_way  = 1'b0;
        data_wr_addr = 8'd0;
        data_wr_wo   = 2'd0;
        data_wr_data = 32'd0;

        tag_wr_ena     = 2'b00;
        tag_wr_addr    = 8'd0;
        tag_wr_data[0] = 21'd0;
        tag_wr_data[1] = 21'd0;

        case (state)

            S_INIT: begin
                tag_wr_ena     = 2'b11;
                tag_wr_addr    = init_addr;
                tag_wr_data[0] = 21'd0;
                tag_wr_data[1] = 21'd0;
                if (init_addr == 8'd255)
                    next_state = S_IDLE;
            end

            S_IDLE: begin
                if (s2_valid) begin
                    if (s2_hit) begin
                        cpu_resp.addr_ok = 1'b1;
                        cpu_resp.data_ok = 1'b1;
                        cpu_resp.data    = data_rd_out[s2_hit_way][s2_wo];
                    end else begin
                        next_state = S_MISS;
                    end
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
                    if (rf_cnt == m_wo && !rf_kw_sent) begin
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
                    tag_wr_ena[m_eway]   = 1'b1;
                    tag_wr_addr          = m_idx;
                    tag_wr_data[m_eway]  = {m_tag, 1'b1};
                end
                next_state = (rf_cnt == 2'd3)
                    ? S_IDLE
                    : S_REFILL_WRITE;
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
            plru        <= '0;
            rf_fmask    <= 4'd0;
            rf_cnt      <= 2'd0;
            rf_kw_sent  <= 1'b0;
            mem_req_r   <= '{valid: 1'b0, addr: 32'd0};
            init_addr   <= 8'd0;
        end else begin
            state <= next_state;
            mem_req_r <= mem_req_next;

            if (inv_all) begin
                state <= S_INIT;
                init_addr <= 8'd0;
                plru      <= '0;
            end

            if (state == S_INIT) begin
                if (init_addr != 8'd255)
                    init_addr <= init_addr + 1;
                else begin
                    init_addr <= 8'd0;
                    plru      <= '0;
                end
            end

            if (!s1_stall) begin
                s1_valid <= cpu_req.valid;
                s1_addr  <= cpu_req.addr;
                s1_wo    <= cpu_req.addr[3:2];
                s1_idx   <= cpu_req.addr[11:4];
                s1_tag   <= cpu_req.addr[31:12];
            end else if (state != S_IDLE) begin
                s1_valid <= 1'b0;
                s2_valid <= 1'b0;
            end

            if (!s1_stall && !s2_hit) begin
                s2_valid <= s1_valid;
                s2_addr  <= s1_addr;
                s2_wo    <= s1_wo;
                s2_idx   <= s1_idx;
                s2_tag   <= s1_tag;
            end else begin
                s2_valid <= 1'b0;
                if (!s1_stall && s2_hit)
                    s1_valid <= 1'b0;
            end

            if (state == S_IDLE && s2_valid && s2_hit) begin
                plru[s2_idx] <= s2_hit_way;
            end

            if (state == S_IDLE && s2_valid && !s2_hit
                && next_state == S_MISS) begin
                m_wo   <= s2_wo;
                m_idx  <= s2_idx;
                m_tag  <= s2_tag;
                m_eway <= victim_way(s2_idx);
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

            if (state == S_REFILL_WAIT && next_state == S_REFILL_WRITE)
                rf_cnt <= 2'd0;

            if (state == S_REFILL_WRITE) begin
                rf_cnt <= rf_cnt + 1;
                if (rf_cnt == 2'd3) begin
                    plru[m_idx] <= m_eway;
                end
            end
        end
    end

    assign mem_req = mem_req_r;

endmodule
