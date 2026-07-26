#include "difftest_interface.h"
#include <cstdio>
#include <cstring>

static difftest_core_state_t dut_state;
static difftest_commit_t    dut_commit;
static difftest_trap_t      dut_trap;
static difftest_cache_state_t dut_cache;
static difftest_branch_state_t dut_branch;
static difftest_stall_state_t  dut_stall;
static uint64_t             sim_cycle = 0;

uint32_t* difftest_state_buf()   { return (uint32_t*)&dut_state; }
difftest_commit_t* difftest_get_commit() { return &dut_commit; }
difftest_trap_t* difftest_get_trap()     { return &dut_trap; }
difftest_cache_state_t* difftest_get_cache_state() { return &dut_cache; }
difftest_branch_state_t* difftest_get_branch_state() { return &dut_branch; }
difftest_stall_state_t* difftest_get_stall_state() { return &dut_stall; }
uint64_t* difftest_cycle_ptr()  { return &sim_cycle; }

extern "C" {

void v_difftest_ArchIntRegState(
    int gpr_0,  int gpr_1,  int gpr_2,  int gpr_3,
    int gpr_4,  int gpr_5,  int gpr_6,  int gpr_7,
    int gpr_8,  int gpr_9,  int gpr_10, int gpr_11,
    int gpr_12, int gpr_13, int gpr_14, int gpr_15,
    int gpr_16, int gpr_17, int gpr_18, int gpr_19,
    int gpr_20, int gpr_21, int gpr_22, int gpr_23,
    int gpr_24, int gpr_25, int gpr_26, int gpr_27,
    int gpr_28, int gpr_29, int gpr_30, int gpr_31
) {
    int *dst = (int*)&dut_state.gpr[0];
    dst[0]  = gpr_0;  dst[1]  = gpr_1;  dst[2]  = gpr_2;  dst[3]  = gpr_3;
    dst[4]  = gpr_4;  dst[5]  = gpr_5;  dst[6]  = gpr_6;  dst[7]  = gpr_7;
    dst[8]  = gpr_8;  dst[9]  = gpr_9;  dst[10] = gpr_10; dst[11] = gpr_11;
    dst[12] = gpr_12; dst[13] = gpr_13; dst[14] = gpr_14; dst[15] = gpr_15;
    dst[16] = gpr_16; dst[17] = gpr_17; dst[18] = gpr_18; dst[19] = gpr_19;
    dst[20] = gpr_20; dst[21] = gpr_21; dst[22] = gpr_22; dst[23] = gpr_23;
    dst[24] = gpr_24; dst[25] = gpr_25; dst[26] = gpr_26; dst[27] = gpr_27;
    dst[28] = gpr_28; dst[29] = gpr_29; dst[30] = gpr_30; dst[31] = gpr_31;
}

void v_difftest_InstrCommit(
    int valid, int pc, int instr,
    int wen, int wdest, int wdata,
    int mem_addr, int mem_re
) {
    dut_commit.valid    = valid;
    dut_commit.pc       = pc;
    dut_commit.instr    = instr;
    dut_commit.wen      = wen;
    dut_commit.wdest    = wdest;
    dut_commit.wdata    = wdata;
    dut_commit.mem_addr = mem_addr;
    dut_commit.mem_re   = mem_re;
}

void v_difftest_CSRState(
    int crmd, int prmd, int euen, int ecfg,
    int era, int badv, int eentry,
    int tlbidx, int tlbehi, int tlbelo0, int tlbelo1,
    int asid, int pgdl, int pgdh,
    int save0, int save1, int save2, int save3,
    int tid, int tcfg, int tval,
    int llbctl, int tlbrentry, int dmw0, int dmw1,
    int estat
) {
    dut_state.crmd      = crmd;
    dut_state.prmd      = prmd;
    dut_state.euen      = euen;
    dut_state.ecfg      = ecfg;
    dut_state.era       = era;
    dut_state.badv      = badv;
    dut_state.eentry    = eentry;
    dut_state.tlbidx    = tlbidx;
    dut_state.tlbehi    = tlbehi;
    dut_state.tlbelo0   = tlbelo0;
    dut_state.tlbelo1   = tlbelo1;
    dut_state.asid      = asid;
    dut_state.pgdl      = pgdl;
    dut_state.pgdh      = pgdh;
    dut_state.save0     = save0;
    dut_state.save1     = save1;
    dut_state.save2     = save2;
    dut_state.save3     = save3;
    dut_state.tid       = tid;
    dut_state.tcfg      = tcfg;
    dut_state.tval      = tval;
    dut_state.llbctl    = llbctl;
    dut_state.tlbrentry = tlbrentry;
    dut_state.dmw0      = dmw0;
    dut_state.dmw1      = dmw1;
    dut_state.estat     = estat;
}

void v_difftest_IdlePC(int idle_pc) {
    dut_state.idle_pc = idle_pc;
}

void v_difftest_TrapEvent(
    int valid, int code, int pc,
    long long cycleCnt, long long instrCnt
) {
    dut_trap.valid    = valid;
    dut_trap.code     = code;
    dut_trap.pc       = pc;
    dut_trap.cycleCnt = cycleCnt;
    dut_trap.instrCnt = instrCnt;
}

void v_difftest_CacheState(
    long long icache_access,
    long long icache_hit,
    long long icache_miss,
    long long icache_wa_clear,
    long long icache_s1_accept,
    long long icache_cyc,
    long long dcache_access,
    long long dcache_hit,
    long long dcache_miss,
    long long dcache_writeback
) {
    dut_cache.icache_access    = (uint64_t)icache_access;
    dut_cache.icache_hit       = (uint64_t)icache_hit;
    dut_cache.icache_miss      = (uint64_t)icache_miss;
    dut_cache.icache_wa_clear  = (uint64_t)icache_wa_clear;
    dut_cache.icache_s1_accept = (uint64_t)icache_s1_accept;
    dut_cache.icache_cyc       = (uint64_t)icache_cyc;
    dut_cache.dcache_access    = (uint64_t)dcache_access;
    dut_cache.dcache_hit       = (uint64_t)dcache_hit;
    dut_cache.dcache_miss      = (uint64_t)dcache_miss;
    dut_cache.dcache_writeback = (uint64_t)dcache_writeback;
}

void v_difftest_BranchState(
    long long total_branches,
    long long mispredictions
) {
    dut_branch.total_branches = (uint64_t)total_branches;
    dut_branch.mispredictions = (uint64_t)mispredictions;
}

void v_difftest_StallState(
    long long stall_dcache_refill,
    long long stall_icache_refill,
    long long stall_load_use,
    long long stall_branch_flush,
    long long stall_other
) {
    dut_stall.stall_dcache_refill = (uint64_t)stall_dcache_refill;
    dut_stall.stall_icache_refill = (uint64_t)stall_icache_refill;
    dut_stall.stall_load_use      = (uint64_t)stall_load_use;
    dut_stall.stall_branch_flush  = (uint64_t)stall_branch_flush;
    dut_stall.stall_other         = (uint64_t)stall_other;
}

} // extern "C"
