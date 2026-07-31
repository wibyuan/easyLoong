# Unit test: load-fed backward branch killed by its own bp_do_jump flush
# while held in ID by the load_use hazard (the WELCOME loop's bne loss).
# ld.b loads mem[0x1c000008] = 0x04 (byte 0 of the ld.b's own encoding);
# the testbench dresp.data must equal 0x04 to match NEMU.
    .text
    .globl _start
_start:
    ori     $r20, $r0, 0        # r20 = 0
    lu12i.w $r23, 0x1c000       # r23 = 0x1c000000
loop:
    addi.w  $r20, $r20, 1       # r20++ each iteration
    ld.b    $r4, $r23, 8        # r4 = mem[0x1c000008] = 0x04
    bne     $r4, $r0, loop      # backward, predicted taken, load_use on r4
end_loop:
    b       end_loop
