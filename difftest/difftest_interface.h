#ifndef DIFFTEST_INTERFACE_H
#define DIFFTEST_INTERFACE_H

#include <cstdint>

#define DIFFTEST_NR_GPR 32
#define DIFFTEST_NR_CSR 26
#define DIFFTEST_REG_SIZE (sizeof(uint32_t) * (DIFFTEST_NR_GPR + 1 + DIFFTEST_NR_CSR))

struct difftest_core_state_t {
    uint32_t gpr[DIFFTEST_NR_GPR];
    uint32_t crmd;
    uint32_t prmd;
    uint32_t euen;
    uint32_t ecfg;
    uint32_t era;
    uint32_t badv;
    uint32_t eentry;
    uint32_t tlbidx;
    uint32_t tlbehi;
    uint32_t tlbelo0;
    uint32_t tlbelo1;
    uint32_t asid;
    uint32_t pgdl;
    uint32_t pgdh;
    uint32_t save0;
    uint32_t save1;
    uint32_t save2;
    uint32_t save3;
    uint32_t tid;
    uint32_t tcfg;
    uint32_t tval;
    uint32_t llbctl;
    uint32_t tlbrentry;
    uint32_t dmw0;
    uint32_t dmw1;
    uint32_t estat;
    uint32_t idle_pc;
};

struct difftest_commit_t {
    uint32_t valid;
    uint32_t pc;
    uint32_t instr;
    uint32_t wen;
    uint32_t wdest;
    uint32_t wdata;
    uint32_t mem_addr;
    uint32_t mem_re;
};

struct difftest_trap_t {
    uint32_t valid;
    uint32_t code;
    uint32_t pc;
    uint64_t cycleCnt;
    uint64_t instrCnt;
};

struct difftest_cache_state_t {
    uint64_t icache_access;
    uint64_t icache_hit;
    uint64_t icache_miss;
    uint64_t icache_wa_clear;
    uint64_t icache_s1_accept;
    uint64_t icache_cyc;
    uint64_t dcache_access;
    uint64_t dcache_hit;
    uint64_t dcache_miss;
    uint64_t dcache_writeback;
};

struct difftest_branch_state_t {
    uint64_t total_branches;
    uint64_t mispredictions;
};

struct difftest_stall_state_t {
    uint64_t stall_dcache_refill;
    uint64_t stall_icache_refill;
    uint64_t stall_load_use;
    uint64_t stall_branch_flush;
    uint64_t stall_dcache_hit_pipe;
    uint64_t stall_icache_hit_pipe;
    uint64_t stall_other;
};

uint32_t* difftest_state_buf();
difftest_commit_t* difftest_get_commit();
difftest_trap_t* difftest_get_trap();
difftest_cache_state_t* difftest_get_cache_state();
difftest_branch_state_t* difftest_get_branch_state();
difftest_stall_state_t* difftest_get_stall_state();
uint64_t* difftest_cycle_ptr();

#endif
