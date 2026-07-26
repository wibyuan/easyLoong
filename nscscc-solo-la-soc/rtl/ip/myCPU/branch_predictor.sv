`include "common.sv"

module branch_predictor import la32_common::*; (
    input  logic [31:0] pc,
    input  logic [31:0] imm,
    input  br_type_t    br_type,
    output logic        predict_taken
);

    always_comb begin
        if (br_type == BR_NONE)
            predict_taken = 1'b1;
        else
            predict_taken = $signed(imm) < 0;
    end

endmodule
