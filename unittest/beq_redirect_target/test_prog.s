# Unit test: EX redirect target == current fetch pc (0-cycle icache)
# beq at 0x1c000000, target 0x1c000008: the fetch reaches the target the
# same cycle the EX redirect fires; if_id_flush must not kill it.
    .text
    .globl _start
_start:
    beq     $r0, $r0, 8     # 0x1c000000: always taken -> target 0x1c000008
    nop                     # 0x1c000004: fall-through (wrong path)
    ori     $r20, $r0, 0x55 # 0x1c000008: the target, marker r20=0x55
end_loop:
    b       end_loop
