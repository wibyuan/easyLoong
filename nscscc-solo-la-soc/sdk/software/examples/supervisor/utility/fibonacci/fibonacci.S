    .text
    .p2align 2
    .global fibonacci

/*
 * Loaded by the supervisor A command at 0x1c300000.
 * Writes eight Fibonacci numbers to ExtRAM at 0x1c400000, then returns.
 */
fibonacci:
    addi.w  $t0, $zero, 1
    addi.w  $t1, $zero, 1
    lu12i.w $a0, 0x1c400
    addi.w  $a1, $a0, 0x20

.Lloop:
    add.w   $t2, $t0, $t1
    addi.w  $t0, $t1, 0
    addi.w  $t1, $t2, 0
    st.w    $t2, $a0, 0
    addi.w  $a0, $a0, 4
    bne     $a0, $a1, .Lloop
    jirl    $zero, $ra, 0
