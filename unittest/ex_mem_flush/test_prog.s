# Unit test: reproduce EX/MEM flush bug causing duplicate commit
# Derived from kernel.s ICACHE_INIT loop at make test failure
    .text
    .globl _start
_start:
    ori   $r14, $r0, 0x1
    slli.w $r14, $r14, 8        # r14 = 0x100 (outer loop bound)
    ori   $r15, $r0, 0x4        # r15 = 4 (shift amount)
    ori   $r17, $r0, 0x1        # r17 = 1 (inner loop bound)

    # Jump to the loop entry (matching kernel.s address)
    b     loop_entry

loop_entry:
    sll.w $r13, $r12, $r15      # r13 = r12 << r15
    move  $r18, $r0              # r18 = 0

inner_loop:
    or    $r16, $r13, $r18       # r16 = r13 | r18  <-- duplicated commit here
    cacop 0x0, $r16, 0
    addi.w $r18, $r18, 1
    slt   $r19, $r17, $r18
    beq   $r19, $r0, inner_loop

    addi.w $r12, $r12, 1
    bne   $r12, $r14, loop_entry

    # Test passed (we'll detect pass/fail externally)
end_loop:
    b     end_loop
