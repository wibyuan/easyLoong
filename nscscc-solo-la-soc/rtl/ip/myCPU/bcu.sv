`include "common.sv"

module bcu import la32_common::*; (
    input  logic [31:0] rs1_val, rs2_val,
    input  br_type_t    br_type,
    output logic        br_taken
);

    always_comb begin
        case (br_type)
            BR_BEQ:  br_taken = (rs1_val == rs2_val);
            BR_BNE:  br_taken = (rs1_val != rs2_val);
            BR_BLT:  br_taken = ($signed(rs1_val) < $signed(rs2_val));
            BR_BGE:  br_taken = ($signed(rs1_val) >= $signed(rs2_val));
            BR_BLTU: br_taken = (rs1_val < rs2_val);
            BR_BGEU: br_taken = (rs1_val >= rs2_val);
            BR_NONE: br_taken = 1'b1; // unconditional (B)
            default: br_taken = 1'b0;
        endcase
    end

endmodule
