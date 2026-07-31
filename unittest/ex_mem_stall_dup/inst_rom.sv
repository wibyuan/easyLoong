// Instruction ROM for ex_mem_stall_dup unit test
module inst_rom (
    input  logic [31:0] addr,
    output logic [31:0] data
);

    logic [31:0] rom [0:15];

    initial begin
        // 0x1c000000: _start
        rom[0] = 32'h0380040e;  // ori $r14,$r0,0x1
        rom[1] = 32'h0040a1ce;  // slli.w $r14,$r14,0x8
        rom[2] = 32'h0380100f;  // ori $r15,$r0,0x4
        rom[3] = 32'h03800411;  // ori $r17,$r0,0x1
        // 0x1c000010:
        rom[4] = 32'h0015000c;  // move $r12,$r0
        rom[5] = 32'h00173d8d;  // sll.w $r13,$r12,$r15
        rom[6] = 32'h00150012;  // move $r18,$r0
        // 0x1c00001c:
        rom[7] = 32'h001549b0;  // or $r16,$r13,$r18   <-- duplicate commit target
        rom[8] = 32'h06000200;  // cacop 0x0,$r16,0      <-- stall source
        rom[9] = 32'h02800413;  // addi.w $r19,$r0,1
        // 0x1c000028: end_loop
        rom[10] = 32'h50000000;  // b end_loop
        rom[11] = 32'h50000000;  // padding
        rom[12] = 32'h50000000;
        rom[13] = 32'h50000000;
        rom[14] = 32'h50000000;
        rom[15] = 32'h50000000;
    end

    assign data = rom[addr[5:2]];

endmodule
