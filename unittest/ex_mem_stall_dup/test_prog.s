# Unit test: ex_mem_stall duplicate commit
# Reproduces: or→cacop in EX/MEM pipeline stall causes dual WB capture
    .text
    .globl _start
_start:
    # Initialize registers matching the difftest REF Regs state
    ori   $r14, $r0, 0x1
    slli.w $r14, $r14, 8        # r14 = 0x100
    ori   $r15, $r0, 0x4        # r15 = 4
    ori   $r17, $r0, 0x1        # r17 = 1
    move  $r12, $r0              # r12 = 0
    sll.w $r13, $r12, $r15      # r13 = r12 << 4 = 0
    move  $r18, $r0              # r18 = 0
    or    $r16, $r13, $r18       # r16 = 0  <-- duplicate commit target
    cacop 0x0, $r16, 0           # cacop → multi-cycle stall
    addi.w $r19, $r0, 1          # r19 = 1 (only if no duplicate or pipeline corruption)
end_loop:
    b     end_loop
