// Instruction ROM for ex_mem_flush unit test
// Combinational read — always returns data in same cycle (mimics 0-cycle icache hit)
// Must match test_prog.bin (objdump output) byte-for-byte
module inst_rom (
    input  logic [31:0] addr,
    output logic [31:0] data
);

    logic [31:0] rom [0:15];

    initial begin
        // 0x1c000000: _start
        rom[0] = 32'h0380040e;  // ori   $r14,$r0,0x1
        rom[1] = 32'h0040a1ce;  // slli.w $r14,$r14,0x8
        rom[2] = 32'h0380100f;  // ori   $r15,$r0,0x4
        rom[3] = 32'h03800411;  // ori   $r17,$r0,0x1
        // 0x1c000010:
        rom[4] = 32'h50000400;  // b     4  -> 0x1c000014 (loop_entry)
        // 0x1c000014: loop_entry
        rom[5] = 32'h00173d8d;  // sll.w $r13,$r12,$r15
        rom[6] = 32'h00150012;  // move  $r18,$r0
        // 0x1c00001c: inner_loop
        rom[7] = 32'h001549b0;  // or    $r16,$r13,$r18  <-- duplicated commit target
        rom[8] = 32'h06000200;  // cacop 0x0,$r16,0
        rom[9] = 32'h02800652;  // addi.w $r18,$r18,1
        rom[10] = 32'h00124a33;  // slt   $r19,$r17,$r18
        rom[11] = 32'h5bfff260;  // beq   $r19,$r0,-16 -> inner_loop
        // 0x1c000030:
        rom[12] = 32'h0280058c;  // addi.w $r12,$r12,1
        rom[13] = 32'h5fffe18e;  // bne   $r12,$r14,-32 -> loop_entry
        // 0x1c000038: end_loop
        rom[14] = 32'h50000000;  // b     0  -> infinite loop
        rom[15] = 32'h50000000;  // padding
    end

    assign data = rom[addr[5:2]];

endmodule
