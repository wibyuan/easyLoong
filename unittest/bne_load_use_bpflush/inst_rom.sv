// Instruction ROM for bne_load_use_bpflush unit test
module inst_rom (
    input  logic [31:0] addr,
    output logic [31:0] data
);

    logic [31:0] rom [0:15];

    initial begin
        // 0x1c000000: _start
        rom[0] = 32'h03800014;  // ori $r20,$r0,0
        rom[1] = 32'h14380017;  // lu12i.w $r23,0x1c000
        // 0x1c000008: loop
        rom[2] = 32'h02800694;  // addi.w $r20,$r20,1
        rom[3] = 32'h280022e4;  // ld.b $r4,$r23,8
        rom[4] = 32'h5ffff880;  // bne $r4,$r0,-8 -> loop
        // 0x1c000014: end_loop
        rom[5] = 32'h50000000;  // b end_loop
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
