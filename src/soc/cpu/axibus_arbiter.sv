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
        W_IDLE, W_ARB, W_WREQ, W_RESP
    } wstate, wnext;

    logic        r_for_d_r;
    logic [31:0] r_addr_r;

    // ==================== Read channel ====================
    always_comb begin
        rnext  = rstate;
        arid    = 4'd0;
        araddr  = 32'd0;
        arlen   = 8'd0;
        arsize  = 3'b010; // 4 bytes
        arburst = 2'b01;  // INCR
        arlock  = 2'd0;
        arcache = 4'd0;
        arprot  = 3'd0;
        arvalid = 1'b0;
        rready  = 1'b0;
        iresp.addr_ok = 1'b0;
        iresp.data_ok = 1'b0;
        iresp.data    = 32'd0;
        dresp.addr_ok = 1'b0;
        dresp.data_ok = 1'b0;
        dresp.data    = 32'd0;

        case (rstate)
            R_IDLE: begin
                if (ireq.valid && dreq.valid) begin
                    rnext = R_ARB;
                end else if (ireq.valid) begin
                    rnext = R_IREQ;
                end else if (dreq.valid) begin
                    rnext = R_DREQ;
                end
            end
            R_ARB: begin
                araddr  = ireq.valid ? ireq.addr : dreq.addr;
                arvalid = 1'b1;
                if (arready) begin
                    rnext = R_WAIT;
                end
            end
            R_IREQ: begin
                araddr  = ireq.addr;
                arvalid = 1'b1;
                if (arready) begin
                    rnext = R_WAIT;
                end
            end
            R_DREQ: begin
                araddr  = dreq.addr;
                arvalid = 1'b1;
                if (arready) begin
                    rnext = R_WAIT;
                end
            end
            R_WAIT: begin
                rready = 1'b1;
                if (rvalid) begin
                    if (r_for_d_r) begin
                        dresp.data_ok = 1'b1;
                        dresp.data = rdata;
                    end else begin
                        iresp.data_ok = 1'b1;
                        iresp.data = rdata;
                    end
                    rnext = R_IDLE;
                end
            end
            default: rnext = R_IDLE;
        endcase
    end

    always_ff @(posedge clk) begin
        if (!resetn) begin
            rstate     <= R_IDLE;
            r_for_d_r  <= 1'b0;
            r_addr_r   <= 32'd0;
        end else begin
            rstate <= rnext;
            if (rstate == R_ARB && arready) begin
                r_for_d_r <= dreq.valid && !ireq.valid;
                r_addr_r  <= ireq.valid ? ireq.addr : dreq.addr;
            end else if (rstate == R_IREQ && arready) begin
                r_for_d_r <= 1'b0;
                r_addr_r  <= ireq.addr;
            end else if (rstate == R_DREQ && arready) begin
                r_for_d_r <= 1'b1;
                r_addr_r  <= dreq.addr;
            end
        end
    end

    // ==================== Write channel ====================
    logic [31:0] waddr_stored;
    logic [31:0] wdata_stored;
    logic [3:0]  wstrb_stored;

    always_comb begin
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
        dresp.addr_ok = 1'b0;
        dresp.data_ok = 1'b0;

        case (wstate)
            W_IDLE: begin
                if (dreq.valid) begin
                    awaddr  = dreq.addr;
                    awvalid = 1'b1;
                    if (awready) begin
                        wdata_out = dreq.data;
                        wstrb = dreq.strobe;
                        wvalid = 1'b1;
                        if (wready) begin
                            dresp.addr_ok = 1'b1;
                            bready = 1'b1;
                            wnext = W_RESP;
                        end else begin
                            wnext = W_WREQ;
                        end
                    end else begin
                        wnext = W_IDLE;
                    end
                end else begin
                    wnext = W_IDLE;
                end
            end
            W_WREQ: begin
                wdata_out = wdata_stored;
                wstrb = wstrb_stored;
                wvalid = 1'b1;
                if (wready) begin
                    dresp.addr_ok = 1'b1;
                    bready = 1'b1;
                    wnext = W_RESP;
                end else begin
                    wnext = W_WREQ;
                end
            end
            W_RESP: begin
                bready = 1'b1;
                if (bvalid) begin
                    dresp.data_ok = 1'b1;
                    wnext = W_IDLE;
                end else begin
                    wnext = W_RESP;
                end
            end
            default: wnext = W_IDLE;
        endcase
    end

    always_ff @(posedge clk) begin
        if (!resetn) begin
            wstate       <= W_IDLE;
            waddr_stored <= 32'd0;
            wdata_stored <= 32'd0;
            wstrb_stored <= 4'd0;
        end else begin
            wstate <= wnext;
            if (wstate == W_IDLE && dreq.valid) begin
                waddr_stored <= dreq.addr;
                wdata_stored <= dreq.data;
                wstrb_stored <= dreq.strobe;
            end
        end
    end

endmodule
