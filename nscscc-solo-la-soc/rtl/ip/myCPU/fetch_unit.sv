`include "common.sv"

module fetch_unit import la32_common::*; (
    input  logic        clk,
    input  logic        reset,
    input  logic        pc_stall,
    input  logic [31:0] pc_current,
    input  logic        wb_jump_req,
    input  logic [31:0] wb_jump_pc,
    input  logic        do_ex_flush,
    input  logic [31:0] ex_jump_pc,
    input  logic        do_id_jump,
    input  logic [31:0] id_jump_pc,
    input  logic        bp_do_jump,
    input  logic [31:0] bp_jump_pc,
    output ibus_req_t   ireq,
    input  ibus_resp_t  iresp,
    output logic [31:0] next_pc,
    output logic        if_pc_valid,
    output logic [31:0] if_pc,
    output logic [31:0] if_instr,
    output logic        if_valid
);

    enum logic [1:0] {
        IDLE, REQ, WAIT_DATA
    } state, next_state;

    logic [31:0] captured_pc;
    logic [31:0] captured_instr;

    always_comb begin
        ireq.valid = 1'b0;
        ireq.addr  = 32'd0;

        case (state)
            IDLE: begin
                ireq.valid = 1'b0;
                ireq.addr  = 32'd0;
            end
            REQ: begin
                if (iresp.data_ok || do_ex_flush || (do_id_jump && pc_current != id_jump_pc)
                    || (bp_do_jump && pc_current != bp_jump_pc)) begin
                    ireq.valid = 1'b0;
                    ireq.addr  = 32'd0;
                end else begin
                    ireq.valid = 1'b1;
                    ireq.addr  = pc_current;
                end
            end
            WAIT_DATA: begin
                ireq.valid = 1'b0;
                ireq.addr  = 32'd0;
            end
        endcase
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                next_state = REQ;
            end
            REQ: begin
                if (iresp.addr_ok && !iresp.data_ok)
                    next_state = WAIT_DATA;
                else if (iresp.data_ok)
                    next_state = REQ;
            end
            WAIT_DATA: begin
                if (iresp.data_ok)
                    next_state = REQ;
            end
        endcase
        if (reset)
            next_state = IDLE;
    end

    always_ff @(posedge clk) begin
        state <= next_state;
        if (state == REQ && iresp.addr_ok) begin
            captured_pc <= pc_current;
            if (iresp.data_ok)
                captured_instr <= iresp.data;
        end
        if (state == WAIT_DATA && iresp.data_ok) begin
            captured_instr <= iresp.data;
        end
    end

    assign if_valid = (state == REQ && iresp.data_ok) || (state == WAIT_DATA && iresp.data_ok);
    assign if_pc = iresp.data_ok ? ((state == REQ) ? pc_current : captured_pc) : captured_pc;
    assign if_instr = iresp.data_ok ? iresp.data : captured_instr;
    assign if_pc_valid = 1'b1;

    always_comb begin
        next_pc = pc_current + 32'd4;
        if (wb_jump_req)
            next_pc = wb_jump_pc;
        else if (do_ex_flush && pc_current != ex_jump_pc)
            next_pc = ex_jump_pc;
        else if (do_id_jump && pc_current != id_jump_pc)
            next_pc = id_jump_pc;
        else if (bp_do_jump && pc_current != bp_jump_pc)
            next_pc = bp_jump_pc;
        else if (pc_stall)
            next_pc = pc_current;
    end

endmodule
