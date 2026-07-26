`include "common.sv"

module branch_predictor import la32_common::*; (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] id_pc,
    input  logic [31:0] id_imm,
    input  br_type_t    id_br_type,
    input  logic        id_is_cond_branch,
    input  logic        id_valid,
    input  logic        id_stall,
    input  logic        ex_br_taken,
    input  logic        ex_valid,
    input  logic        ex_predict_taken,
    output logic        predict_taken,
    output logic        bp_redirect,
    output logic [31:0] bp_target,
    output logic        bp_mispredict,
    output logic [31:0] bp_correct_pc
);

    assign predict_taken = (id_br_type != BR_NONE) && ($signed(id_imm) < 0);

    assign bp_redirect  = id_valid && id_is_cond_branch && predict_taken && !id_stall;
    assign bp_target    = id_pc + id_imm;

    logic ex_mispredict;
    assign ex_mispredict = ex_valid && (ex_predict_taken != ex_br_taken);
    assign bp_mispredict = ex_mispredict;
    assign bp_correct_pc = ex_br_taken ? 32'd0 : 32'd0;

endmodule
