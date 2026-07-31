# Unit test: redirect during icache refill (Bug 8 closure)
#
# The load at 0x1c000004 misses the dcache (slow dresp) and stalls the
# pipeline while the beq at 0x1c000008 sits in EX (ex_mem_stall gates
# do_ex_flush, so the branch cannot redirect yet). During the stall the
# fetch issues the fall-through 0x1c000010, which misses the icache — the
# refill is in flight when the dcache responds and the beq finally
# redirects to 0x1c00003c. The refill's keyword forward must NOT deliver
# the fall-through instruction (wrong path): the fetch_unit abandons the
# stale WAIT_DATA once pc moves, and the icache suppresses the forward
# while cpu_req.addr no longer matches the refill address. Without the
# fix the fall-through ori $r20,0x55 survives, commits, and r20 mismatches
# NEMU (ref 0xAA).
    .text
    .globl _start
_start:
    ori     $r29, $r0, 0        # 0x1c000000: branch condition (taken)
    ld.w    $r5, $r0, 0x100     # 0x1c000004: dcache miss, stalls pipeline
    beq     $r29, $r0, 0x34     # 0x1c000008: forward, always taken -> 0x1c00003c
    nop                         # 0x1c00000c: fall-through (wrong path, hit)
    ori     $r20, $r0, 0x55     # 0x1c000010: fall-through line (wrong path, misses)
    nop                         # 0x1c000014
    nop                         # 0x1c000018
    nop                         # 0x1c00001c
    nop                         # 0x1c000020
    nop                         # 0x1c000024
    nop                         # 0x1c000028
    nop                         # 0x1c00002c
    nop                         # 0x1c000030
    nop                         # 0x1c000034
    nop                         # 0x1c000038
    ori     $r20, $r0, 0xaa     # 0x1c00003c: redirect target marker r20=0xAA
end_loop:
    b       end_loop            # 0x1c000040
