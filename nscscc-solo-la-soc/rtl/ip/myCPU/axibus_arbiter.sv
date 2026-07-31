`include "common.sv"

module axibus_arbiter import la32_common::*; (
    input  logic       clk,
    input  logic       resetn,

    input  ibus_req_t  ireq,
    output ibus_resp_t iresp,
    input  dbus_req_t  dreq,
    output dbus_resp_t dresp,

    output logic [3:0]  arid,
    output logic [31:0] araddr,
    output logic [7:0]  arlen,
    output logic [2:0]  arsize,
    output logic [1:0]  arburst,
    output logic [1:0]  arlock,
    output logic [3:0]  arcache,
    output logic [2:0]  arprot,
    output logic        arvalid,
    input  logic        arready,
    input  logic [3:0]  rid,
    input  logic [31:0] rdata,
    input  logic [1:0]  rresp,
    input  logic        rlast,
    input  logic        rvalid,
    output logic        rready,

    output logic [3:0]  awid,
    output logic [31:0] awaddr,
    output logic [7:0]  awlen,
    output logic [2:0]  awsize,
    output logic [1:0]  awburst,
    output logic [1:0]  awlock,
    output logic [3:0]  awcache,
    output logic [2:0]  awprot,
    output logic        awvalid,
    input  logic        awready,
    output logic [3:0]  wid,
    output logic [31:0] wdata_out,
    output logic [3:0]  wstrb,
    output logic        wlast,
    output logic        wvalid,
    input  logic        wready,
    input  logic [3:0]  bid,
    input  logic [1:0]  bresp,
    input  logic        bvalid,
    output logic        bready
);

    enum logic [2:0] {
        R_IDLE, R_ARB, R_IREQ, R_DREQ, R_WAIT
    } rstate, rnext;

    enum logic [2:0] {
        W_IDLE, W_ARB, W_WREQ, W_RESP,
        W_BURST_SEND, W_BURST_GAP, W_BURST_DATA, W_BURST_RESP
    } wstate, wnext;

    logic [1:0] wbeat_cnt, wbeat_cnt_next;
    logic [1:0] wburst_len_r;

    logic        r_for_d_r;
    logic [31:0] r_addr_r;

    // ==================== Combinational logic ====================
    logic r_dresp_addr_ok, r_dresp_data_ok, r_dresp_data_last;
    logic r_iresp_addr_ok, r_iresp_data_ok;
    logic [31:0] r_dresp_data, r_iresp_data;
    logic w_dresp_addr_ok, w_dresp_data_ok;
    logic dreq_read_pending;

    always_comb begin

        // ----- Read channel defaults -----
        rnext   = rstate;
        arid    = 4'd0;
        araddr  = 32'd0;
        arlen   = 8'd0;
        arsize  = 3'b010;
        arburst = 2'b01;
        arlock  = 2'd0;
        arcache = 4'd0;
        arprot  = 3'd0;
        arvalid = 1'b0;
        rready  = 1'b0;

        r_iresp_addr_ok  = 1'b0;
        r_iresp_data_ok  = 1'b0;
        r_iresp_data     = 32'd0;
        r_dresp_addr_ok  = 1'b0;
        r_dresp_data_ok  = 1'b0;
        r_dresp_data_last = 1'b0;
        r_dresp_data     = 32'd0;

        // ----- Read channel FSM -----
        case (rstate)
            R_IDLE: begin
                if (ireq.valid && (dreq.valid && dreq.strobe == 4'd0)) begin
                    rnext = R_ARB;
                end else if (ireq.valid) begin
                    rnext = R_IREQ;
                end else if (dreq.valid && dreq.strobe == 4'd0) begin
                    rnext = R_DREQ;
                end
            end
            R_ARB: begin
                // Either requester can be served here; the dcache refill
                // needs its burst length (the icache is always single-beat).
                araddr  = (dreq.valid && dreq.strobe == 4'd0) ? dreq.addr : ireq.addr;
                arlen   = (dreq.valid && dreq.strobe == 4'd0) ? {6'd0, dreq.burst_len} : 8'd0;
                arvalid = 1'b1;
                if (arready) begin
                    rnext = R_WAIT;
                    if (dreq.valid && dreq.strobe == 4'd0)
                        r_dresp_addr_ok = 1'b1;
                    else
                        r_iresp_addr_ok = 1'b1;
                end
            end
            R_IREQ: begin
                araddr  = ireq.addr;
                arlen   = 8'd0;
                arvalid = 1'b1;
                if (arready) begin
                    r_iresp_addr_ok = 1'b1;
                    rnext = R_WAIT;
                end
            end
            R_DREQ: begin
                araddr  = dreq.addr;
                arlen   = {6'd0, dreq.burst_len};
                arvalid = 1'b1;
                if (arready) begin
                    r_dresp_addr_ok = 1'b1;
                    rnext = R_WAIT;
                end
            end
            R_WAIT: begin
                rready = 1'b1;
                if (rvalid) begin
                    if (r_for_d_r) begin
                        r_dresp_data_ok   = 1'b1;
                        r_dresp_data_last  = rlast;
                        r_dresp_data      = rdata;
                    end else begin
                        r_iresp_data_ok = 1'b1;
                        r_iresp_data = rdata;
                    end
                    if (rlast)
                        rnext = R_IDLE;
                end
            end
            default: rnext = R_IDLE;
        endcase

        // ----- Write channel FSM -----
        wnext   = wstate;
        awid    = 4'd0;
        awaddr  = 32'd0;
        awlen   = 8'd0;
        awsize  = 3'b010;
        awburst = 2'b01;
        awlock  = 2'd0;
        awcache = 4'd0;
        awprot  = 3'd0;
        awvalid = 1'b0;
        wid     = 4'd0;
        wdata_out = 32'd0;
        wstrb   = 4'd0;
        wlast   = 1'b1;
        wvalid  = 1'b0;
        bready  = 1'b0;

        w_dresp_addr_ok = 1'b0;
        w_dresp_data_ok = 1'b0;
        wbeat_cnt_next  = wbeat_cnt;

        case (wstate)
            W_IDLE: begin
                if (dreq.valid && |dreq.strobe) begin
                    awaddr  = dreq.addr;
                    awlen   = {6'd0, dreq.burst_len};
                    awvalid = 1'b1;
                    if (awready) begin
                        wdata_out = dreq.data;
                        wstrb = dreq.strobe;
                        wvalid = 1'b1;
                        if (wready) begin
                            w_dresp_addr_ok = 1'b1;
                            if (dreq.burst_len == 2'd0) begin
                                wlast = 1'b1;
                                bready = 1'b1;
                                wnext = W_RESP;
                            end else begin
                                wlast = 1'b0;
                                wbeat_cnt_next = 2'd1;
                                wnext = W_BURST_GAP;
                            end
                        end else begin
                            wnext = W_WREQ;
                        end
                    end
                end
            end
            W_WREQ: begin
                wdata_out = wdata_stored;
                wstrb = wstrb_stored;
                wvalid = 1'b1;
                if (wready) begin
                    w_dresp_addr_ok = 1'b1;
                    if (wburst_len_r == 2'd0) begin
                        wlast = 1'b1;
                        bready = 1'b1;
                        wnext = W_RESP;
                    end else begin
                        wlast = 1'b0;
                        wbeat_cnt_next = 2'd1;
                        wnext = W_BURST_GAP;
                    end
                end
            end
            W_RESP: begin
                bready = 1'b1;
                if (bvalid) begin
                    w_dresp_data_ok = 1'b1;
                    wnext = W_IDLE;
                end
            end
            W_BURST_GAP: begin
                wnext = W_BURST_DATA;
            end
            W_BURST_DATA: begin
                wvalid = 1'b1;
                wdata_out = dreq.data;
                wstrb = dreq.strobe;
                if (wready) begin
                    w_dresp_addr_ok = 1'b1;
                    if (wbeat_cnt == wburst_len_r) begin
                        wlast = 1'b1;
                        bready = 1'b1;
                        wnext = W_BURST_RESP;
                    end else begin
                        wlast = 1'b0;
                        wbeat_cnt_next = wbeat_cnt + 2'd1;
                        wnext = W_BURST_GAP;
                    end
                end
            end
            W_BURST_RESP: begin
                bready = 1'b1;
                if (bvalid) begin
                    w_dresp_data_ok = 1'b1;
                    wnext = W_IDLE;
                end
            end
            default: wnext = W_IDLE;
        endcase

        // ----- Combine read and write responses -----
        iresp.addr_ok = r_iresp_addr_ok;
        iresp.data_ok = r_iresp_data_ok;
        iresp.data    = r_iresp_data;

        dresp.addr_ok   = r_dresp_addr_ok || w_dresp_addr_ok;
        dresp.data_ok   = r_dresp_data_ok || (w_dresp_data_ok && !dreq_read_pending);
        dresp.data_last = r_dresp_data_last;
        dresp.data      = r_dresp_data;
    end

    // ==================== Sequential logic ====================
    always_ff @(posedge clk) begin
        if (!resetn) begin
            rstate     <= R_IDLE;
            r_for_d_r  <= 1'b0;
            r_addr_r   <= 32'd0;
        end else begin
            rstate <= rnext;
            if (rstate == R_ARB && arready) begin
                r_for_d_r <= (dreq.valid && dreq.strobe == 4'd0);
                r_addr_r  <= (dreq.valid && dreq.strobe == 4'd0) ? dreq.addr : ireq.addr;
            end else if (rstate == R_IREQ && arready) begin
                r_for_d_r <= 1'b0;
                r_addr_r  <= ireq.addr;
            end else if (rstate == R_DREQ && arready) begin
                r_for_d_r <= 1'b1;
                r_addr_r  <= dreq.addr;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!resetn) begin
            dreq_read_pending <= 1'b0;
        end else begin
            if (r_dresp_addr_ok && dreq.valid && dreq.strobe == 4'd0)
                dreq_read_pending <= 1'b1;
            else if (r_dresp_data_ok && rlast)
                dreq_read_pending <= 1'b0;
        end
    end

    logic [31:0] waddr_stored;
    logic [31:0] wdata_stored;
    logic [3:0]  wstrb_stored;

    always_ff @(posedge clk) begin
        if (!resetn) begin
            wstate       <= W_IDLE;
            waddr_stored <= 32'd0;
            wdata_stored <= 32'd0;
            wstrb_stored <= 4'd0;
            wbeat_cnt    <= 2'd0;
            wburst_len_r <= 2'd0;
        end else begin
            wstate    <= wnext;
            wbeat_cnt <= wbeat_cnt_next;
            if (wstate == W_IDLE && dreq.valid) begin
                waddr_stored <= dreq.addr;
                wdata_stored <= dreq.data;
                wstrb_stored <= dreq.strobe;
                wburst_len_r <= dreq.burst_len;
            end
        end
    end

endmodule
