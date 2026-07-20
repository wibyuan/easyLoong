#include <regdef.h>
#include <exception.h>

/*==============================================================
 *                        TEST for MONITOR
 *  Built-in test program
 *  Entry symbol prefix 'UTEST_'
 *==============================================================*/
    

    .section .text.utest
    .p2align 2

    /*  Simple test program
     *  Write integer 1 to register a0
     */
UTEST_SIMPLE:
    addi.w      a0,a0,0x1
    jirl        zero,ra,0x0
    /* End of test */

    /*  STREAM test program
     *  Continous memory read/write
     */
UTEST_STREAM:
    li.w        a0,0x1c100000
    li.w        a1,0x1c400000
    li.w        a2,0x00300000
    add.w       a2,a0,a2
stream_next:
    ld.w        t0,a0,0x0
    st.w        t0,a1,0x0
    addi.w      a0,a0,0x4
    addi.w      a1,a1,0x4
    bne         a0,a2,stream_next

    b           FLUSH_DCACHE_AND_RETURN
    /* End of test */

    /*  MATRIX test program
     *  Matrix multiplication
     *  Reference C code:
        void matrix(int a[128][128],int b[128][128],int c[128][128],unsigned int n) {
            unsigned int i,j,k;
            for (k=0; k!=n; k++) {
                for (i=0; i!=n; i++) {
                    int r = a[i][k];
                    for (j=0; j!=n; j++)
                        c[i][j] += r * b[k][j];
                }
            }
        }
     */
UTEST_MATRIX:
    // set arguments
    li.w        a0, 0x1c400000
    li.w        a1, 0x1c410000
    li.w        a2, 0x1c420000
    li.w        a3, 96
    // a0 -> a
    // a1 -> b
    // a2 -> c
    // a3 -> n
    // t8 -> k
    // t1 -> i
    // t3 -> j, unrolled by 4
    // t7 -> r
    or          t8,zero,zero
loop1:
    beq         t8,a3,loop1end

    slli.w      t0,t8,2
    slli.w      t2,t8,9
    add.w       t0,a0,t0
    add.w       t2,a1,t2
    or          t1,zero,zero
loop2:
    beq         t1,a3,loop2end

    ld.w        t7,t0,0x0
    slli.w      a4,t1,9
    add.w       a4,a2,a4
    or          t4,t2,zero
    or          t3,zero,zero
loop3:
    beq         t3,a3,loop3end

    ld.w        t5,t4,0x0
    ld.w        t6,t4,0x4
    ld.w        s0,t4,0x8
    ld.w        s1,t4,0xc
    ld.w        s2,a4,0x0
    ld.w        s3,a4,0x4
    ld.w        s4,a4,0x8
    ld.w        s5,a4,0xc
    mul.w       t5,t7,t5
    mul.w       t6,t7,t6
    mul.w       s0,t7,s0
    mul.w       s1,t7,s1
    add.w       s2,s2,t5
    add.w       s3,s3,t6
    add.w       s4,s4,s0
    add.w       s5,s5,s1
    st.w        s2,a4,0x0
    st.w        s3,a4,0x4
    st.w        s4,a4,0x8
    st.w        s5,a4,0xc
    addi.w      t3,t3,4
    addi.w      a4,a4,16
    addi.w      t4,t4,16
    b           loop3

loop3end:
    addi.w      t1,t1,1
    addi.w      t0,t0,512
    b           loop2

loop2end:
    addi.w      t8,t8,1
    b           loop1

loop1end:
    b           FLUSH_DCACHE_AND_RETURN
    /* End of test */

    /*  CryptoNight test program
     *  Run simplified CryptoNight memory-hard loop
     *  Reference C code:
        void crn(int pad[],unsigned int a,unsigned int b,unsigned int n) {
            unsigned int k;
            for (k=0; k!=0x80000; k++)
                pad[k] = k;
            for (k=0; k!=n; k++) {
                unsigned int t, addr1, addr2;
                addr1 = a & 0x7FFFF;
                t = (a >> 1) ^ (pad[addr1] << 1); // Replace the AES step
                pad[addr1] = t ^ b;
                addr2 = t & 0x7FFFF;
                b = t;
                t = pad[addr2];
                a += b * t;
                pad[addr2] = a;
                a ^= t;
            } 
        }
     */
UTEST_CRYPTONIGHT:
    // a0 -> pad
    // a1 -> a
    // a2 -> b
    // a3 -> n
    li.w        a0, 0x1c400000
    li.w        a1, 0xdeadbeef
    li.w        a2, 0xfaceb00c
    li.w        a3, 0x100000
    or          t4,zero,a0
    or          t3,zero,zero
    li.w        t0,0x80000
fill_next:
    st.w        t3,t4,0
    addi.w      t3,t3,1
    addi.w      t4,t4,4
    bne         t3,t0,fill_next

    or          t1,zero,zero
    li.w        t2,0x7ffff
crn_hext:
    and         t0,a1,t2
    slli.w      t0,t0,2
    add.w       t0,a0,t0
    ld.w        t3,t0,0
    srli.w      t4,a1,1
    slli.w      t3,t3,1
    xor         t3,t3,t4
    and         t4,t3,t2
    xor         a2,t3,a2
    slli.w      t4,t4,2
    st.w        a2,t0,0
    add.w       t4,a0,t4
    ld.w        t0,t4,0
    or          a2,zero,t3
    mul.w       t3,t3,t0
    addi.w      t1,t1,1
    add.w       a1,t3,a1
    st.w        a1,t4,0
    xor         a1,t0,a1
    bne         a3,t1,crn_hext
crn_end:
    b           FLUSH_DCACHE_AND_RETURN
    /* End of test */

    /*  MIXED test program
     *  Balanced microbenchmark:
     *  - sequential stores to warm/dirty D-cache
     *  - unrolled independent loads/stores for D-cache throughput
     *  - pseudo-random indexed updates and data-dependent branches
     */
UTEST_MIXED:
    li.w        a0,0x1c500000           // scratch source
    li.w        a1,0x1c510000           // scratch destination
    li.w        a2,0x4000               // 16K words = 64 KiB
    or          t0,zero,zero
    li.w        t1,0x9e37
mixed_fill:
    xor         t2,t0,t1
    slli.w      t3,t0,3
    xor         t2,t2,t3
    st.w        t2,a0,0x0
    addi.w      a0,a0,4
    addi.w      t0,t0,1
    bne         t0,a2,mixed_fill

    li.w        a0,0x1c500000
    li.w        a1,0x1c510000
    or          t0,zero,zero
    or          s0,zero,zero
    or          s1,zero,zero
    or          s2,zero,zero
    or          s3,zero,zero
mixed_stream:
    ld.w        t4,a0,0x0
    ld.w        t5,a0,0x4
    ld.w        t6,a0,0x8
    ld.w        t7,a0,0xc
    add.w       s0,s0,t4
    xor         s1,s1,t5
    add.w       s2,s2,t6
    xor         s3,s3,t7
    st.w        s0,a1,0x0
    st.w        s1,a1,0x4
    st.w        s2,a1,0x8
    st.w        s3,a1,0xc
    addi.w      a0,a0,16
    addi.w      a1,a1,16
    addi.w      t0,t0,4
    bne         t0,a2,mixed_stream

    li.w        a0,0x1c500000
    li.w        t0,0x2000               // indexed update iterations
    li.w        t8,0x3fff               // 64 KiB word-index mask
    xor         t1,s0,s1                // pseudo-random state
mixed_stride:
    and         t2,t1,t8
    slli.w      t2,t2,2
    add.w       t3,a0,t2
    ld.w        t4,t3,0x0
    xor         t1,t1,t4
    slli.w      t5,t1,5
    xor         t1,t1,t5
    srli.w      t5,t1,7
    xor         t1,t1,t5
    andi        t5,t1,0x1
    beq         t5,zero,mixed_even
    add.w       s0,s0,t4
    b           mixed_join
mixed_even:
    xor         s1,s1,t4
mixed_join:
    st.w        t1,t3,0x0
    addi.w      t0,t0,-1
    bne         t0,zero,mixed_stride

    li.w        a0,0x1c520000
    st.w        s0,a0,0x0
    st.w        s1,a0,0x4
    st.w        s2,a0,0x8
    st.w        s3,a0,0xc
    st.w        t1,a0,0x10
    b           FLUSH_DCACHE_AND_RETURN
    /* End of test */

    .global FLUSH_DCACHE
FLUSH_DCACHE:
#ifdef SUPERVISOR_FORCE_UNCACHE
    jirl        zero,ra,0x0
#else
    // CachePathFlag is non-zero only when an L1 D-cache exists. The geometry
    // values are captured by START before DMW/PG setup and written after bss
    // initialization, so this path avoids re-reading CPUCFG after user code.
    la.global   t0, CachePathFlag
    ld.w        t0, t0, 0x0
    beq         t0, zero, 3f

    la.global   t0, DCacheTotalSets
    ld.w        t2, t0, 0x0             // total_sets
    la.global   t0, DCacheMaxWay
    ld.w        t5, t0, 0x0             // max_way
    la.global   t0, DCacheOffsetBits
    ld.w        t3, t0, 0x0             // offset_bits

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
    //         cacop(0x09, target_addr); // 0x09: D-Cache Index Writeback Invalidate
    cacop       0x09, t4, 0x0
    
    //         way++;
    addi.w      t6, t6, 1
    slt         t7, t5, t6
    beq         t7, zero, 2b
    //     } // end for way
    
    //     set++;
    addi.w      t0, t0, 1
    bne         t0, t2, 1b
    // } // end for set

    andi        zero, zero, 0x0
3:
    jirl        zero,ra,0x0
#endif

    .global FLUSH_DCACHE_AND_RETURN
FLUSH_DCACHE_AND_RETURN:
    jirl        zero,ra,0x0
