`include "common.sv"

module bcu import la32_common::*; (
    input  logic [31:0] rs1_val, rs2_val,
    input  br_type_t    br_type,
    output logic        br_taken
);

    // Unsigned magnitude compare (carry chain) plus the sign precheck for
    // the signed branch types: the sign-bit decision is a single mux that
    // does not wait for the full 32-bit subtract's borrow chain.
    logic ltu, lt;
    assign ltu = (rs1_val < rs2_val);
    assign lt  = (rs1_val[31] != rs2_val[31]) ? rs1_val[31] : ltu;

    always_comb begin
        case (br_type)
            BR_BEQ:  br_taken = (rs1_val == rs2_val);
            BR_BNE:  br_taken = (rs1_val != rs2_val);
            BR_BLT:  br_taken = lt;
            BR_BGE:  br_taken = !lt;
            BR_BLTU: br_taken = ltu;
            BR_BGEU: br_taken = !ltu;
            BR_NONE: br_taken = 1'b1; // unconditional (B)
            default: br_taken = 1'b0;
        endcase
    end

endmodule
