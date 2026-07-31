// Instruction ROM for icache_redirect_stale unit test
// Covers 0x1c000000 - 0x1c0000ff (64 words), must match test_prog.bin
module inst_rom (
    input  logic [31:0] addr,
    output logic [31:0] data
);

    logic [31:0] rom [0:63];

    initial begin
        // 0x1c000000: _start
        rom[0]  = 32'h0380001d;  // ori $r29,$r0,0
        rom[1]  = 32'h28840005;  // ld.w $r5,$r0,0x100 (dcache miss, pipeline stall)
        rom[2]  = 32'h580037a0;  // beq $r29,$r0,0x34 -> 0x1c00003c
        rom[3]  = 32'h03400000;  // andi $r0,$r0,0 (fall-through, wrong path, hit)
        rom[4]  = 32'h03815414;  // ori $r20,$r0,0x55 (fall-through line, wrong path)
        rom[5]  = 32'h03400000;
        rom[6]  = 32'h03400000;
        rom[7]  = 32'h03400000;
        rom[8]  = 32'h03400000;
        rom[9]  = 32'h03400000;
        rom[10] = 32'h03400000;
        rom[11] = 32'h03400000;
        rom[12] = 32'h03400000;
        rom[13] = 32'h03400000;
        rom[14] = 32'h03400000;
        rom[15] = 32'h0382a814;  // ori $r20,$r0,0xaa (redirect target marker)
        // 0x1c000040: end_loop
        rom[16] = 32'h50000000;  // b end_loop
        rom[17] = 32'h50000000;
        rom[18] = 32'h50000000;
        rom[19] = 32'h50000000;
        rom[20] = 32'h50000000;
        rom[21] = 32'h50000000;
        rom[22] = 32'h50000000;
        rom[23] = 32'h50000000;
        rom[24] = 32'h50000000;
        rom[25] = 32'h50000000;
        rom[26] = 32'h50000000;
        rom[27] = 32'h50000000;
        rom[28] = 32'h50000000;
        rom[29] = 32'h50000000;
        rom[30] = 32'h50000000;
        rom[31] = 32'h50000000;
        rom[32] = 32'h50000000;
        rom[33] = 32'h50000000;
        rom[34] = 32'h50000000;
        rom[35] = 32'h50000000;
        rom[36] = 32'h50000000;
        rom[37] = 32'h50000000;
        rom[38] = 32'h50000000;
        rom[39] = 32'h50000000;
        rom[40] = 32'h50000000;
        rom[41] = 32'h50000000;
        rom[42] = 32'h50000000;
        rom[43] = 32'h50000000;
        rom[44] = 32'h50000000;
        rom[45] = 32'h50000000;
        rom[46] = 32'h50000000;
        rom[47] = 32'h50000000;
        rom[48] = 32'h50000000;
        rom[49] = 32'h50000000;
        rom[50] = 32'h50000000;
        rom[51] = 32'h50000000;
        rom[52] = 32'h50000000;
        rom[53] = 32'h50000000;
        rom[54] = 32'h50000000;
        rom[55] = 32'h50000000;
        rom[56] = 32'h50000000;
        rom[57] = 32'h50000000;
        rom[58] = 32'h50000000;
        rom[59] = 32'h50000000;
        rom[60] = 32'h50000000;
        rom[61] = 32'h50000000;
        rom[62] = 32'h50000000;
        rom[63] = 32'h50000000;
    end

    assign data = rom[addr[7:2]];

endmodule
