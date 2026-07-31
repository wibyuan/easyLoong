// Instruction ROM for csr_dmw0 unit test
module inst_rom (
    input  logic [31:0] addr,
    output logic [31:0] data
);

    logic [31:0] rom [0:15];

    initial begin
        // 0x1c000000: _start
        rom[0] = 32'h0380640c;  // ori $r12,$r0,0x19
        rom[1] = 32'h0406002c;  // csrwr $r12,0x180  (set DMW0=0x19)
        rom[2] = 32'h04060020;  // csrwr $r0,0x180   (clear DMW0=0)
        rom[3] = 32'h0280040d;  // addi.w $r13,$r0,1 (marker)
        // 0x1c000010: end_loop
        rom[4] = 32'h50000000;  // b end_loop
        rom[5] = 32'h50000000;
        rom[6] = 32'h50000000;
        rom[7] = 32'h50000000;
        rom[8] = 32'h50000000;
        rom[9] = 32'h50000000;
        rom[10] = 32'h50000000;
        rom[11] = 32'h50000000;
        rom[12] = 32'h50000000;
        rom[13] = 32'h50000000;
        rom[14] = 32'h50000000;
        rom[15] = 32'h50000000;
    end

    assign data = rom[addr[5:2]];

endmodule
