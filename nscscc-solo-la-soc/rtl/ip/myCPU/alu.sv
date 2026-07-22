`include "common.sv"

module alu import la32_common::*; (
    input  logic [31:0] a, b,
    input  alu_op_t     op,
    output logic [31:0] res
);

    always_comb begin
        case (op)
            ALU_ADD:  res = a + b;
            ALU_SUB:  res = a - b;
            ALU_SLT:  res = {31'd0, $signed(a) < $signed(b)};
            ALU_SLTU: res = {31'd0, a < b};
            ALU_AND:  res = a & b;
            ALU_NOR:  res = ~(a | b);
            ALU_OR:   res = a | b;
            ALU_XOR:  res = a ^ b;
            ALU_SLL:  res = a << b[4:0];
            ALU_SRL:  res = a >> b[4:0];
            ALU_SRA:  res = $signed(a) >>> b[4:0];
            ALU_LUI:  res = b;             // LU12I.W: b already shifted
            ALU_PCADD: res = a + b;        // PCADDU12I
            default:  res = 32'd0;
        endcase
    end

endmodule
