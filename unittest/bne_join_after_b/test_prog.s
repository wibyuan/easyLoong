# Unit test: bne mispredict + fall-through B + join 2 instructions later.
# Reproduces the .TESTW/.WSERIAL pattern: the bne is predicted not-taken but
# taken (LSR TX-ready bit); its fall-through is an unconditional B back to
# the loop.  The join's first instruction is the .WSERIAL marker.
# With the registered EX redirect, the fall-through B (issued into EX during
# the flush window) re-fires ex_jump_flush one cycle later; if that flush is
# not suppressed for BR_NONE, the fetch is redirected back to the loop (the
# B's target), bouncing forever — the loop counter r14 over-counts vs NEMU.
    .text
    .globl _start
_start:
    lu12i.w $r13, 0x1f000         # r13 = 0x1f000000 (MMIO range)
    ori     $r13, $r13, 0x4        # r13 = 0x1f000004 (the "LSR")
    ori     $r14, $r0, 0           # counter = 0
loop:
    ld.w    $r12, $r13, 0          # LSR read -> 0x20 (tb + difftest injection)
    andi    $r12, $r12, 0x20
    addi.w  $r14, $r14, 1          # counter++
    bne     $r12, $r0, join        # forward, predicted not-taken, TAKEN
    b       loop                   # fall-through busy wait
join:
    pcaddu12i $r23, 1              # marker (r23 = 0x1c002000)
    ori     $r20, $r0, 0x55        # done marker
end_loop:
    b       end_loop
