# Unit test: GPR forwarding across a stalled load (2-back RAW)
# Reproduces simple-test failure at WELCOME: addi.w $r23,$r23,0x44 -> ld.b $r4,$r23,0 -> addi.w $r23,$r23,1
    .text
    .globl _start
_start:
    lu12i.w $r23, 0x1c002        # r23 = 0x1c002000
    addi.w  $r23, $r23, 0x2ac    # r23 = 0x1c0022ac
    addi.w  $r23, $r23, 0x44     # r23 = 0x1c0022f0
    ld.b    $r4, $r23, 0         # load (stalls on delayed dresp.data_ok)
    addi.w  $r23, $r23, 1        # expect r23 = 0x1c0022f1
end_loop:
    b     end_loop
