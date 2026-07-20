#include <regdef.h>

    .p2align 2
    .section .text.init
    .global INITLOCATE
INITLOCATE:                         // 定位启动程序
    la.local     t0,START
    jirl        zero,t0,0x0
