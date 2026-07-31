// Instruction ROM for beq_redirect_target unit test
module inst_rom (
    input  logic [31:0] addr,
    output logic [31:0] data
);

    logic [31:0] rom [0:15];

    initial begin
        // 0x1c000000: _start
        rom[0] = 32'h58000800;  // beq $r0,$r0,8 -> 0x1c000008
        rom[1] = 32'h03400000;  // andi $r0,$r0,0 (fall-through, wrong path)
        rom[2] = 32'h03815414;  // ori $r20,$r0,0x55 (the redirect target)
        // 0x1c00000c: end_loop
        rom[3] = 32'h50000000;  // b end_loop
        rom[4] = 32'h50000000;
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
