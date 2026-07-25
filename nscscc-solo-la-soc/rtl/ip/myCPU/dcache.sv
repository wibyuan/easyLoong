`include "common.sv"

module dcache import la32_common::*; (
    input  logic       clk,
    input  logic       reset,

    input  dbus_req_t  cpu_req,
    output dbus_resp_t cpu_resp,

    output dbus_req_t  mem_req,
    input  dbus_resp_t mem_resp
);

    localparam NR_SETS  = 256;
    localparam NR_WORDS = 4;

    typedef logic [1:0] woffset_t;
    typedef logic [7:0] index_t;
    typedef logic [19:0] tag_t;

    // ==================== Data BRAM (registered read, 8 banks) ====================
    (* ram_style = "block" *) logic [31:0] data_mem [0:1][0:3][NR_SETS-1:0];
    logic        data_rd_ena;
    index_t      data_rd_addr;
    logic [31:0] data_rd_out [0:1][0:3];
    logic        data_wr_ena;
    logic        data_wr_way;
    index_t      data_wr_addr;
    logic [1:0]  data_wr_wo;
    logic [3:0]  data_wr_we;
    logic [31:0] data_wr_data;

    always_ff @(posedge clk) begin
        if (data_wr_ena) begin
            if (data_wr_we[0]) data_mem[data_wr_way][data_wr_wo][data_wr_addr][ 7: 0] <= data_wr_data[ 7: 0];
            if (data_wr_we[1]) data_mem[data_wr_way][data_wr_wo][data_wr_addr][15: 8] <= data_wr_data[15: 8];
            if (data_wr_we[2]) data_mem[data_wr_way][data_wr_wo][data_wr_addr][23:16] <= data_wr_data[23:16];
            if (data_wr_we[3]) data_mem[data_wr_way][data_wr_wo][data_wr_addr][31:24] <= data_wr_data[31:24];
        end
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

    // ==================== Tag BRAM (registered read, 2 ways) ====================
    (* ram_style = "block" *) logic [20:0] tag_mem [0:1][NR_SETS-1:0];
    logic        tag_rd_ena;
    index_t      tag_rd_addr;
    logic [20:0] tag_rd_data [0:1];
    logic        tag_wr_ena;
    logic        tag_wr_way;
    index_t      tag_wr_addr;
    logic [20:0] tag_wr_data;

    always_ff @(posedge clk) begin
        if (tag_wr_ena)
            tag_mem[tag_wr_way][tag_wr_addr] <= tag_wr_data;
        if (tag_rd_ena) begin
            tag_rd_data[0] <= tag_mem[0][tag_rd_addr];
            tag_rd_data[1] <= tag_mem[1][tag_rd_addr];
        end
    end

    // ==================== Dirty + PLRU ====================
    logic [NR_SETS-1:0] dirty [0:1];
    logic [NR_SETS-1:0] plru;

    // ==================== State ====================
    enum logic [3:0] {
        S_INIT,
        S_IDLE,
        S_UNCACHED,
        S_MISS,
        S_WB_READ, S_WB_WRITE,
        S_REFILL_SEND, S_REFILL_ACK, S_REFILL_WAIT, S_REFILL_WRITE,
        S_STORE_FINAL
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

    logic       s2_valid;
    word_t      s2_addr;
    logic       s2_op;
    msize_t     s2_size;
    word_t      s2_wdata;
    logic [3:0] s2_wstrb;
    woffset_t   s2_wo;
    index_t     s2_idx;
    tag_t       s2_tag;

    // ==================== Miss context ====================
    logic       m_op;
    msize_t     m_size;
    word_t      m_wdata;
    logic [3:0] m_wstrb;
    woffset_t   m_wo;
    index_t     m_idx;
    tag_t       m_tag;
    logic       m_eway;
    logic       m_edirty;
    tag_t       m_etag;

    // ==================== Work registers ====================
    logic [1:0] wb_cnt;
    logic [1:0] rf_cnt;
    logic [1:0] rf_wr_cnt;
    logic [3:0] rf_fmask;
    logic       rf_kw_sent;
    word_t      rf_buf [0:3];
    word_t      wb_buf [0:3];

    // ==================== Init registers ====================
    index_t init_addr;
    logic   init_wr_way;

    // ==================== Helper functions ====================
    function automatic logic is_cachable(input word_t a);
        return (a[31:24] == 8'h1c);
    endfunction

    function automatic logic victim_way(input index_t i);
        return ~plru[i];
    endfunction

    // ==================== S2 hit (uses combinational tag read) ====================
    wire [19:0] tag_r_tag [0:1];
    wire        tag_r_v   [0:1];
    assign tag_r_tag[0] = tag_rd_data[0][20:1];
    assign tag_r_tag[1] = tag_rd_data[1][20:1];
    assign tag_r_v[0] = tag_rd_data[0][0];
    assign tag_r_v[1] = tag_rd_data[1][0];

    logic s2_hit, s2_hit_way;

    always_comb begin
        automatic logic h0, h1;
        h0 = s2_valid && tag_r_v[0] && (tag_r_tag[0] == s2_tag) && is_cachable(s2_addr);
        h1 = s2_valid && tag_r_v[1] && (tag_r_tag[1] == s2_tag) && is_cachable(s2_addr);
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
        else if (s2_valid && s2_hit && s2_op && is_cachable(s2_addr))
            s1_stall = 1'b1;
    end

    // ==================== BRAM read control ====================
    always_comb begin
        data_rd_ena = 1'b0;
        data_rd_addr = 8'd0;
        tag_rd_ena  = 1'b0;
        tag_rd_addr  = 8'd0;

        if (state == S_IDLE && s1_valid && is_cachable(s1_addr)) begin
            data_rd_ena = 1'b1;
            data_rd_addr = s1_idx;
            tag_rd_ena  = 1'b1;
            tag_rd_addr  = s1_idx;
        end
        if (state == S_MISS) begin
            data_rd_ena = 1'b1;
            data_rd_addr = m_idx;
            tag_rd_ena  = 1'b1;
            tag_rd_addr  = m_idx;
        end
    end

    // ==================== FSM combinational ====================
    always_comb begin
        next_state = state;

        cpu_resp.addr_ok = 1'b0;
        cpu_resp.data_ok = 1'b0;
        cpu_resp.data    = 32'd0;

        mem_req_next.valid  = 1'b0;
        mem_req_next.addr   = 32'd0;
        mem_req_next.size   = MSIZE4;
        mem_req_next.strobe = 4'd0;
        mem_req_next.data   = 32'd0;

        data_wr_ena  = 1'b0;
        data_wr_way  = 1'b0;
        data_wr_addr = 8'd0;
        data_wr_wo   = 2'd0;
        data_wr_we   = 4'd0;
        data_wr_data = 32'd0;

        tag_wr_ena  = 1'b0;
        tag_wr_way  = 1'b0;
        tag_wr_addr = 8'd0;
        tag_wr_data = 21'd0;

        case (state)

            S_INIT: begin
                tag_wr_ena  = 1'b1;
                tag_wr_way  = init_wr_way;
                tag_wr_addr = init_addr;
                tag_wr_data = 21'd0;
                if (init_wr_way == 1'b1 && init_addr == 8'd255)
                    next_state = S_IDLE;
            end

            S_IDLE: begin
                if (s2_valid) begin
                    if (!is_cachable(s2_addr)) begin
                        mem_req_next.valid  = 1'b1;
                        mem_req_next.addr   = {s2_addr[31:2], 2'b00};
                        mem_req_next.strobe = s2_op ? s2_wstrb : 4'd0;
                        mem_req_next.data   = s2_wdata;
                        if (mem_resp.addr_ok && mem_resp.data_ok) begin
                            cpu_resp.addr_ok = 1'b1;
                            cpu_resp.data_ok = 1'b1;
                            cpu_resp.data    = mem_resp.data;
                        end else begin
                            next_state = S_UNCACHED;
                        end
                    end else if (s2_hit) begin
                        cpu_resp.addr_ok = 1'b1;
                        cpu_resp.data_ok = 1'b1;
                        if (s2_op) begin
                            data_wr_ena  = 1'b1;
                            data_wr_way  = s2_hit_way;
                            data_wr_addr = s2_idx;
                            data_wr_wo   = s2_wo;
                            data_wr_we   = s2_wstrb;
                            data_wr_data = s2_wdata;
                        end else begin
                            cpu_resp.data = data_rd_out[s2_hit_way][s2_wo];
                        end
                    end else begin
                        next_state = S_MISS;
                    end
                end
            end

            S_UNCACHED: begin
                if (mem_resp.data_ok) begin
                    cpu_resp.addr_ok = 1'b1;
                    cpu_resp.data_ok = 1'b1;
                    cpu_resp.data    = mem_resp.data;
                    next_state = S_IDLE;
                end else if (!mem_resp.addr_ok) begin
                    mem_req_next.valid  = 1'b1;
                    mem_req_next.addr   = {s2_addr[31:2], 2'b00};
                    mem_req_next.strobe = s2_op ? s2_wstrb : 4'd0;
                    mem_req_next.data   = s2_wdata;
                end
            end

            S_MISS: begin
                next_state = m_edirty ? S_WB_READ : S_REFILL_SEND;
            end

            S_WB_READ: begin
                next_state = S_WB_WRITE;
            end

            S_WB_WRITE: begin
                mem_req_next.valid  = 1'b1;
                mem_req_next.addr   = {m_etag, m_idx, wb_cnt, 2'b00};
                mem_req_next.strobe = 4'b1111;
                mem_req_next.data   = wb_buf[wb_cnt];
                if (mem_resp.addr_ok)
                    next_state = (wb_cnt == 2'd3) ? S_REFILL_SEND : S_WB_WRITE;
            end

            S_REFILL_SEND: begin
                mem_req_next.valid = 1'b1;
                mem_req_next.addr  = {m_tag, m_idx, rf_cnt, 2'b00};
                next_state = S_REFILL_ACK;
            end

            S_REFILL_ACK: begin
                mem_req_next.valid = 1'b1;
                mem_req_next.addr  = {m_tag, m_idx, rf_cnt, 2'b00};
                if (mem_resp.addr_ok)
                    next_state = S_REFILL_WAIT;
            end

            S_REFILL_WAIT: begin
                if (mem_resp.data_ok) begin
                    if (rf_cnt == m_wo && !rf_kw_sent && m_op == 1'b0) begin
                        cpu_resp.addr_ok = 1'b1;
                        cpu_resp.data_ok = 1'b1;
                        cpu_resp.data    = mem_resp.data;
                    end
                    next_state = (&(rf_fmask | (4'd1 << rf_cnt)))
                        ? S_REFILL_WRITE : S_REFILL_SEND;
                end
            end

            S_REFILL_WRITE: begin
                data_wr_ena  = 1'b1;
                data_wr_way  = m_eway;
                data_wr_addr = m_idx;
                data_wr_wo   = rf_wr_cnt;
                data_wr_we   = 4'b1111;
                data_wr_data = rf_buf[rf_wr_cnt];
                if (rf_wr_cnt == 2'd0) begin
                    tag_wr_ena  = 1'b1;
                    tag_wr_way  = m_eway;
                    tag_wr_addr = m_idx;
                    tag_wr_data = {m_tag, 1'b1};
                end
                next_state = (rf_wr_cnt == 2'd3)
                    ? (m_op ? S_STORE_FINAL : S_IDLE)
                    : S_REFILL_WRITE;
            end

            S_STORE_FINAL: begin
                data_wr_ena  = 1'b1;
                data_wr_way  = m_eway;
                data_wr_addr = m_idx;
                data_wr_wo   = m_wo;
                data_wr_we   = m_wstrb;
                data_wr_data = m_wdata;
                cpu_resp.addr_ok = 1'b1;
                cpu_resp.data_ok = 1'b1;
                next_state = S_IDLE;
            end

            default: next_state = S_IDLE;
        endcase
    end

    // ==================== Sequential logic ====================
    always_ff @(posedge clk) begin
        if (reset) begin
            state      <= S_INIT;
            s1_valid   <= 1'b0;
            s2_valid   <= 1'b0;
            dirty[0]   <= '0;
            dirty[1]   <= '0;
            plru       <= '0;
            rf_fmask   <= 4'd0;
            wb_cnt     <= 2'd0;
            rf_cnt     <= 2'd0;
            rf_wr_cnt  <= 2'd0;
            rf_kw_sent <= 1'b0;
            mem_req_r  <= '{valid: 1'b0, addr: 32'd0, size: MSIZE4, strobe: 4'd0, data: 32'd0};
            init_addr    <= 8'd0;
            init_wr_way  <= 1'b0;
        end else begin
            state <= next_state;
            mem_req_r <= mem_req_next;

            if (state == S_INIT) begin
                if (init_wr_way == 1'b1)
                    init_addr <= init_addr + 1;
                init_wr_way <= ~init_wr_way;
            end

            if (!s1_stall) begin
                s1_valid <= cpu_req.valid;
                s1_addr  <= cpu_req.addr;
                s1_op    <= |cpu_req.strobe;
                s1_size  <= cpu_req.size;
                s1_wdata <= cpu_req.data;
                s1_wstrb <= cpu_req.strobe;
                s1_wo    <= cpu_req.addr[3:2];
                s1_idx   <= cpu_req.addr[11:4];
                s1_tag   <= cpu_req.addr[31:12];

                if (s2_valid && s2_hit && !s2_op && is_cachable(s2_addr)) begin
                    s2_valid <= 1'b0;
                    s1_valid <= 1'b0;
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
                end
            end else if (state != S_IDLE) begin
                s1_valid <= 1'b0;
                s2_valid <= 1'b0;
            end else if (s2_valid) begin
                s2_valid <= 1'b0;
                s1_valid <= 1'b0;
            end

            if (state == S_IDLE && s2_valid && s2_hit && is_cachable(s2_addr)) begin
                plru[s2_idx] <= s2_hit_way;
                if (s2_op)
                    dirty[s2_hit_way][s2_idx] <= 1'b1;
            end

            if (state == S_IDLE && s2_valid && !s2_hit && is_cachable(s2_addr)
                && next_state == S_MISS) begin
                m_op     <= s2_op;
                m_size   <= s2_size;
                m_wdata  <= s2_wdata;
                m_wstrb  <= s2_wstrb;
                m_wo     <= s2_wo;
                m_idx    <= s2_idx;
                m_tag    <= s2_tag;
                m_eway   <= victim_way(s2_idx);
                m_edirty <= dirty[victim_way(s2_idx)][s2_idx];
                m_etag   <= (victim_way(s2_idx) == 1'b0)
                            ? tag_r_tag[0] : tag_r_tag[1];
            end

            if (state == S_MISS && next_state == S_REFILL_SEND) begin
                rf_cnt     <= m_wo;
                rf_fmask   <= 4'd0;
                rf_kw_sent <= 1'b0;
            end


            if (state == S_MISS && next_state == S_WB_READ)
                wb_cnt <= 2'd0;

            if (state == S_WB_READ) begin
                wb_buf[0] <= data_rd_out[m_eway][0];
                wb_buf[1] <= data_rd_out[m_eway][1];
                wb_buf[2] <= data_rd_out[m_eway][2];
                wb_buf[3] <= data_rd_out[m_eway][3];
            end

            if (state == S_WB_WRITE && mem_resp.addr_ok) begin
                wb_cnt <= wb_cnt + 1;
                if (wb_cnt == 2'd3) begin
                    rf_cnt     <= m_wo;
                    rf_fmask   <= 4'd0;
                    rf_kw_sent <= 1'b0;
                end
            end

            if (state == S_REFILL_WAIT && mem_resp.data_ok) begin
                rf_buf[rf_cnt]       <= mem_resp.data;
                rf_fmask[rf_cnt]     <= 1'b1;
                if (rf_cnt == m_wo && !rf_kw_sent && m_op == 1'b0)
                    rf_kw_sent <= 1'b1;
                rf_cnt <= (rf_cnt == 2'd3) ? 2'd0 : (rf_cnt + 1);
            end

            if (state == S_REFILL_WAIT && next_state == S_REFILL_WRITE)
                rf_wr_cnt <= 2'd0;

            if (state == S_REFILL_WRITE) begin
                rf_wr_cnt <= rf_wr_cnt + 1;
                if (rf_wr_cnt == 2'd3) begin
                    dirty[m_eway][m_idx] <= 1'b0;
                    plru[m_idx]          <= m_eway;
                end
            end

            if (state == S_STORE_FINAL)
                dirty[m_eway][m_idx] <= 1'b1;
        end
    end

    assign mem_req = mem_req_r;

endmodule
