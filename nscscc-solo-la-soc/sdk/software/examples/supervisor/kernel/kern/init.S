#include <regdef.h>

#define CSR_CRMD 0x0
#define CSR_DMW0 0x180
#define CSR_DMW1 0x181

#define CRMD_IE 0x4
#define CRMD_DA 0x8
#define CRMD_PG 0x10
#define CRMD_DA_PG_MASK 0x18

    /*
     * DMW format used here:
     *   VA[31:29] must match VSEG, then PA = {PSEG, VA[28:0]}.
     *   MAT=1 is cacheable in this SoC/CPU, MAT=0 is uncached.
     *
     * DMW0: VA 0x00000000-0x1fffffff -> PA 0x00000000-0x1fffffff, cacheable.
     * DMW1: VA 0xa0000000-0xbfffffff -> PA 0x00000000-0x1fffffff, uncached.
     *       UART uses this alias: VA 0xbf000000 -> PA 0x1f000000.
     */
#define DMW0_LOW512M_CACHEABLE 0x00000019
#define DMW1_LOW512M_UNCACHED 0xa0000009

    .section .rodata
    .p2align 2
monitor_version:
    .asciz "MONITOR for Loongarch32 - initialized."

    /* start address for the .bss section. defined in linker script */
    .word   _sbss
    /* end address for the .bss section. defined in linker script */
    .word   _ebss

    .text
    .p2align 2

.macro CPUCFG_WAIT
    andi        zero,zero,0x0
    andi        zero,zero,0x0
    andi        zero,zero,0x0
.endm

.macro INIT_CACHE cache_type, cacop_code, present_mask
    // if (!(cpucfg[0x10] & present_mask)) return;
    li.w        t0, 0x10
    cpucfg      t0, t0
    CPUCFG_WAIT
    andi        t0, t0, \present_mask
    beq         t0, zero, 3f

    // int config = cpucfg[cache_type];
    li.w        t0, \cache_type
    cpucfg      t0, t0
    CPUCFG_WAIT

    // int offset_bits = config[30:24]; 
    srli.w      t3, t0, 24
    andi        t3, t3, 0x7f
    
    // int index_bits = config[23:16];
    srli.w      t4, t0, 16
    andi        t4, t4, 0xff
    
    // int total_sets = 1 << index_bits;
    li.w        t2, 1
    sll.w       t2, t2, t4
    
    // int max_way = config[15:0]; 
    slli.w      t5, t0, 16
    srli.w      t5, t5, 16

    // for (int set = 0; set < total_sets; set++) {
    li.w        t0, 0
1:
    //     int set_addr = set << offset_bits;
    sll.w       t1, t0, t3
    
    //     for (int way = 0; way <= max_way; way++) {
    li.w        t6, 0
2:
    //         int target_addr = set_addr | way;
    or          t4, t1, t6
    //         cacop(cacop_code, target_addr);
    cacop       \cacop_code, t4, 0x0
    
    //         way++;
    addi.w      t6, t6, 1
    slt         t7, t5, t6
    beq         t7, zero, 2b
    //     } // end for way
    
    //     set++;
    addi.w      t0, t0, 1
    bne         t0, t2, 1b
    // } // end for set
3:
.endm

    .global START
START:                                  // kernel init
#ifdef SUPERVISOR_FORCE_UNCACHE
    /* Forced uncache build: do not read CPUCFG or touch cache/MMU CSRs. */
    li.w        s6, 0x0
    li.w        s7, 0x0
    b           runtime_init
#else
    /* 1. CPUCFG: only enable cache path when L1 I-cache or D-cache exists. */
    li.w        t0, 0x10
    cpucfg      t0, t0
    CPUCFG_WAIT
    andi        s6, t0, 0x4             // remember whether L1 D-cache exists
    andi        t1, t0, 0x5             // bit0: L1 I-cache, bit2: L1 D-cache
    beq         t1, zero, no_cache_mmu
    li.w        s7, 0x1                 // remember that DMW/cache path is active

    /* 2. cache 初始化 (通过 cpucfg 动态获取参数清空 I/D Cache) */
    INIT_CACHE  0x11, 0x00, 0x1         // L1 I-cache present: CPUCFG.0x10 bit 0
    INIT_CACHE  0x12, 0x01, 0x4         // L1 D-cache present: CPUCFG.0x10 bit 2

    /* Save D-cache geometry before entering DMW/PG mode. */
    beq         s6, zero, dcache_regs_done
    li.w        t0,0x12
    cpucfg      t0,t0
    CPUCFG_WAIT
    srli.w      s2,t0,24
    andi        s2,s2,0x7f              // offset_bits
    srli.w      t4,t0,16
    andi        t4,t4,0xff              // index_bits
    li.w        s3,1
    sll.w       s3,s3,t4                // total_sets
    slli.w      s4,t0,16
    srli.w      s4,s4,16                // max_way
dcache_regs_done:

    /* 3. 配置 DMW：进入 PG 模式后用 DMW 做固定窗口映射。 */
    li.w        t0,CRMD_DA
    li.w        t1,CRMD_DA_PG_MASK
    csrxchg     t0,t1,CSR_CRMD          // temporarily use direct-address mode

    csrwr       zero,CSR_DMW0
    csrwr       zero,CSR_DMW1           // clear dmw0, dmw1
    li.w        t0,DMW0_LOW512M_CACHEABLE
    csrwr       t0,CSR_DMW0             // low 512 MiB identity map, cacheable
    li.w        t0,DMW1_LOW512M_UNCACHED
    csrwr       t0,CSR_DMW1             // 0xa0000000 alias to low 512 MiB, uncached

    li.w        t0,CRMD_PG
    li.w        t1,CRMD_DA_PG_MASK
    csrxchg     t0,t1,CSR_CRMD          // enable PG mode so DMW entries take effect
    b           crmd_init

no_cache_mmu:
    /* No I/D cache: rely on reset direct-address mode, no CSR writes. */
    li.w        s6, 0x0
    li.w        s7, 0x0
    b           runtime_init

crmd_init:
    /* 4. 配置 CSR.CRMD */
    li.w        t1, CRMD_IE
    csrxchg     t1, t1, CSR_CRMD        // csr_crmd
#endif

runtime_init:
    /* 5. 运行程序 */
    la.local    t0,_sbss
    la.local    t1,_ebss
bss_init:
    beq         t0,t1,bss_init_done
    st.w        zero,t0,0x0
    addi.w      t0,t0,0x4
    b           bss_init

bss_init_done:
    /* Save early CPUCFG-derived D-cache parameters for the user-test return flush path. */
    la.global   t1,CachePathFlag
    st.w        s6,t1,0x0
    beq         s6,zero,dcache_param_done

    la.global   t1,DCacheOffsetBits
    st.w        s2,t1,0x0
    la.global   t1,DCacheTotalSets
    st.w        s3,t1,0x0
    la.global   t1,DCacheMaxWay
    st.w        s4,t1,0x0

dcache_param_done:

    /* Select UART address according to whether DMW is enabled. */
    beq         s7, zero, serial_addr_direct

    la.global   t1,SerialDataAddr
    la.global   t2,SerialData
    st.w        t2,t1,0x0
    la.global   t1,SerialStatAddr
    la.global   t2,SerialStat
    st.w        t2,t1,0x0
    b           serial_addr_done

serial_addr_direct:
    la.global   t1,SerialDataAddr
    li.w        t2,0x1f000000
    st.w        t2,t1,0x0
    la.global   t1,SerialStatAddr
    li.w        t2,0x1f000005
    st.w        t2,t1,0x0

serial_addr_done:
    la.global   sp,KERNEL_STACK_INIT    // 设置内核栈
    or          fp,sp,zero
    la.global   t0,USER_STACK_INIT      // 设置用户栈
    la.global   t1,uregs_sp             // 写入用户空间备份
    st.w        t0,t1,0x0
    la.global   t1,uregs_fp
    st.w        t0,t1,0x0

    /* init serial */
    la.global   t1, SerialDataAddr
    ld.w        t1, t1, 0
    li.w        t2, 0x07   
    st.b        t2, t1, 2               // FCR = 0x07 (Enable FIFO, clear RX/TX)
    li.w        t2, 0x80
    st.b        t2, t1, 3               // LCR = 0x80 (Enable DLAB)
    li.w        t2, 0x00 
    st.b        t2, t1, 1               // DLH = 0x00
    li.w        t2, 0x0e
    st.b        t2, t1, 0               // DLL = 0x0e (25 MHz UART clock, ~115200 baud)
    li.w        t2, 0x03 
    st.b        t2, t1, 3               // LCR = 0x03 (8 data bits, no parity, 1 stop bit)
    li.w        t2, 0x00 
    st.b        t2, t1, 4               // MCR = 0x00

    b           WELCOME                 // 进入主线程

WELCOME:
    la.local    s0,monitor_version      // 装入启动信息
    ld.b        a0,s0,0x0
.Loop0:
    addi.w      s0,s0,0x1
    la.global   t0,WRITESERIAL          // 调用串口写函数
    jirl        ra,t0,0x0
    ld.b        a0,s0,0x0
    bne         a0,zero,.Loop0          // 打印循环至0结束符
    la.global   t0,SHELL                // 开始交互
    jirl        zero,t0,0x0
