`include "common.sv"

module npc import la32_common::*; (
    input  logic [31:0] target_pc,
    input  logic [31:0] pc_plus_4,
    input  logic [31:0] rs1_val,
    input  logic [31:0] imm,
    input  logic        is_branch,
    input  logic        is_jal,
    input  logic        is_jalr,
    input  logic        is_ibar,
    input  logic        br_taken,
    output logic [31:0] next_pc,
    output logic        flush_req
);

    logic [31:0] jalr_target;
    assign jalr_target = (rs1_val + imm) & 32'hfffffffc;

    always_comb begin
        next_pc = pc_plus_4;
        flush_req = 1'b0;
        if (is_jal) begin
            next_pc = target_pc;
            flush_req = 1'b1;
        end else if (is_jalr) begin
            next_pc = jalr_target;
            flush_req = 1'b1;
        end else if (is_ibar) begin
            next_pc = pc_plus_4;
            flush_req = 1'b1;
        end else if (is_branch && br_taken) begin
            next_pc = target_pc;
            flush_req = 1'b1;
        end
    end

endmodule
