# Unit test: csrwr set→cacop→csrwr clear with cacop pipeline stall
    .text
    .globl _start
_start:
    ori   $r26, $r0, 0x19        # r26 = 0x19
    csrwr $r26, 0x180            # set DMW0 = 0x19
    cacop 0x0, $r0, 0            # cacop (multi-cycle stall from testbench)
    csrwr $r0, 0x180             # clear DMW0 = 0
    addi.w $r13, $r0, 1          # marker: DMW0 should be 0 here
end_loop:
    b     end_loop
