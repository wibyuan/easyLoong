# Unit test: mixed_stride loop pattern — beq (predicted not-taken) + add.w +
# B +8 with the beq target between the B and the B's target; exercises the
# B ID-redirect against a fetch that streams into the B's target.
    .text
    .globl _start
_start:
    ori     $r12, $r0, 1000         # loop counter
    lu12i.w $r4, 0x1c400            # a0 = 0x1c400000 (empty memory)
    ori     $r13, $r0, 0x55          # t1 = 0x55 (non-zero: evolves)
    ori     $r23, $r0, 0            # s0 = 0
    ori     $r24, $r0, 0            # s1 = 0
loop:
    and     $r14, $r13, $r20        # t2 = t1 & 0
    slli.w  $r14, $r14, 2
    add.w   $r15, $r4, $r14         # t3 = a0 + idx
    ld.w    $r16, $r15, 0           # t4 = [t3] = 0
    xor     $r13, $r13, $r16
    slli.w  $r17, $r13, 5
    xor     $r13, $r13, $r17
    srli.w  $r17, $r13, 7
    xor     $r13, $r13, $r17
    andi    $r17, $r13, 1
    beq     $r17, $r0, even         # forward, predicted not-taken
    add.w   $r23, $r23, $r16
    b       join
even:
    xor     $r24, $r24, $r16
join:
    st.w    $r13, $r15, 0
    addi.w  $r12, $r12, -1
    bne     $r12, $r0, loop
done:
    ori     $r20, $r0, 0x55
end_loop:
    b       end_loop
