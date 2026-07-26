`include "common.sv"

module lsu import la32_common::*; (
    input  logic        clk,
    input  logic        reset,
    input  logic        valid_in,
    input  logic        mem_re,
    input  logic        mem_we,
    input  msize_t      mem_size,
    input  logic        mem_unsigned,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic        cacheable,
    output logic [31:0] rdata_out,
    output logic        lsu_ready,
    output dbus_req_t   dreq,
    input  dbus_resp_t  dresp
);

    enum logic [1:0] {
        IDLE, REQ, WAIT
    } state, next_state;

    logic [31:0] wdata_shifted;
    logic [3:0]  strobe;

    always_comb begin
        strobe = 4'd0;
        wdata_shifted = 32'd0;
        case (mem_size)
            MSIZE1: begin
                wdata_shifted = {4{wdata[7:0]}};
                case (addr[1:0])
                    2'b00: strobe = 4'b0001;
                    2'b01: strobe = 4'b0010;
                    2'b10: strobe = 4'b0100;
                    2'b11: strobe = 4'b1000;
                endcase
            end
            MSIZE2: begin
                wdata_shifted = {2{wdata[15:0]}};
                case (addr[1])
                    1'b0: strobe = 4'b0011;
                    1'b1: strobe = 4'b1100;
                endcase
            end
            MSIZE4: begin
                wdata_shifted = wdata;
                strobe = 4'b1111;
            end
        endcase
    end

    always_comb begin
        dreq.valid  = 1'b0;
        dreq.addr   = 32'd0;
        dreq.size   = MSIZE4;
        dreq.strobe = 4'd0;
        dreq.data   = 32'd0;
        dreq.cacheable = 1'b0;

        case (state)
            IDLE: begin
                if (valid_in && (mem_re || mem_we) && !dresp.data_ok) begin
                    dreq.valid  = 1'b1;
                    dreq.addr   = {addr[31:2], 2'b00};
                    dreq.size   = MSIZE4;
                dreq.strobe = mem_we ? strobe : 4'd0;
                dreq.data   = wdata_shifted;
                dreq.cacheable = cacheable;
            end
            end
            WAIT: begin
                dreq.valid  = 1'b0;
                dreq.addr   = 32'd0;
                dreq.size   = MSIZE4;
                dreq.strobe = 4'd0;
                dreq.data   = 32'd0;
            end
        endcase
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (valid_in && (mem_re || mem_we)) begin
                    if (dresp.addr_ok && !dresp.data_ok)
                        next_state = WAIT;
                    else if (dresp.data_ok)
                        next_state = IDLE;
                    else
                        next_state = IDLE; // stay until addr_ok
                end
            end
            WAIT: begin
                if (dresp.data_ok)
                    next_state = IDLE;
            end
        endcase
        if (reset)
            next_state = IDLE;
    end

    always_ff @(posedge clk)
        state <= next_state;

    assign lsu_ready = ~valid_in || ~(mem_re || mem_we) ||
                       (state == IDLE && dresp.data_ok) ||
                       (state == WAIT && dresp.data_ok);

    always_comb begin
        rdata_out = 32'd0;
        if (dresp.data_ok) begin
            case (mem_size)
                MSIZE1: begin
                    case (addr[1:0])
                        2'b00: rdata_out = mem_unsigned ? {24'd0, dresp.data[7:0]}  : {{24{dresp.data[7]}}, dresp.data[7:0]};
                        2'b01: rdata_out = mem_unsigned ? {24'd0, dresp.data[15:8]} : {{24{dresp.data[15]}}, dresp.data[15:8]};
                        2'b10: rdata_out = mem_unsigned ? {24'd0, dresp.data[23:16]} : {{24{dresp.data[23]}}, dresp.data[23:16]};
                        2'b11: rdata_out = mem_unsigned ? {24'd0, dresp.data[31:24]} : {{24{dresp.data[31]}}, dresp.data[31:24]};
                    endcase
                end
                MSIZE2: begin
                    case (addr[1])
                        1'b0: rdata_out = mem_unsigned ? {16'd0, dresp.data[15:0]}  : {{16{dresp.data[15]}}, dresp.data[15:0]};
                        1'b1: rdata_out = mem_unsigned ? {16'd0, dresp.data[31:16]} : {{16{dresp.data[31]}}, dresp.data[31:16]};
                    endcase
                end
                MSIZE4: begin
                    rdata_out = dresp.data;
                end
            endcase
        end
    end

endmodule
