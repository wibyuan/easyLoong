# Unit test: verify csrwr DMW0 clear takes effect before next csrwr commit
    .text
    .globl _start
_start:
    ori   $r12, $r0, 0x19        # r12 = 0x19
    csrwr $r12, 0x180            # set DMW0 = 0x19
    csrwr $r0, 0x180             # clear DMW0 = 0
    addi.w $r13, $r0, 1          # r13 = 1 (marker: DMW0 should be 0 here)
end_loop:
    b     end_loop
