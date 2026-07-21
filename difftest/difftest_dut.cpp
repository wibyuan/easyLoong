#include "difftest_dut.h"
#include "difftest_interface.h"
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <dlfcn.h>

#define RESET_VECTOR 0x1c000000

enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };

// ==================== RefProxy ====================

bool RefProxy::init(const char *ref_so_path) {
    handle = dlopen(ref_so_path, RTLD_LAZY);
    if (!handle) {
        fprintf(stderr, "[difftest] dlopen(%s) failed: %s\n", ref_so_path, dlerror());
        return false;
    }

    memcpy = (void(*)(uint32_t, void*, size_t, bool))dlsym(handle, "difftest_memcpy");
    regcpy = (void(*)(void*, bool, bool))dlsym(handle, "difftest_regcpy");
    exec   = (void(*)(uint64_t))dlsym(handle, "difftest_exec");
    raise_intr = (void(*)(uint64_t))dlsym(handle, "difftest_raise_intr");
    isa_reg_display = (void(*)())dlsym(handle, "isa_reg_display");

    if (!memcpy || !regcpy || !exec) {
        fprintf(stderr, "[difftest] dlsym failed: %s\n", dlerror());
        dlclose(handle);
        handle = nullptr;
        return false;
    }

    void (*ref_init)() = (void(*)())dlsym(handle, "difftest_init");
    if (!ref_init) {
        fprintf(stderr, "[difftest] dlsym(difftest_init) failed: %s\n", dlerror());
        dlclose(handle);
        handle = nullptr;
        return false;
    }
    ref_init();

    return true;
}

// ==================== DiffState ====================

DiffState::DiffState() {
    memset(retire_group_pc_queue,  0, sizeof(retire_group_pc_queue));
    memset(retire_group_cnt_queue, 0, sizeof(retire_group_cnt_queue));
    memset(retire_inst_pc_queue,   0, sizeof(retire_inst_pc_queue));
    memset(retire_inst_inst_queue, 0, sizeof(retire_inst_inst_queue));
    memset(retire_inst_wen_queue,  0, sizeof(retire_inst_wen_queue));
    memset(retire_inst_wdst_queue, 0, sizeof(retire_inst_wdst_queue));
    memset(retire_inst_wdata_queue,0, sizeof(retire_inst_wdata_queue));
    memset(retire_inst_type_queue, 0, sizeof(retire_inst_type_queue));
}

void DiffState::record_group(uint32_t pc, uint32_t count) {
    retire_group_pc_queue[retire_group_pointer]  = pc;
    retire_group_cnt_queue[retire_group_pointer] = count;
    retire_group_pointer = (retire_group_pointer + 1) % DEBUG_GROUP_TRACE_SIZE;
}

void DiffState::record_inst(uint32_t pc, uint32_t inst,
                            uint32_t wen, uint32_t wdest, uint32_t wdata) {
    int p = retire_inst_pointer;
    retire_inst_pc_queue[p]    = pc;
    retire_inst_inst_queue[p]  = inst;
    retire_inst_wen_queue[p]   = wen;
    retire_inst_wdst_queue[p]  = wdest;
    retire_inst_wdata_queue[p] = wdata;
    retire_inst_type_queue[p]  = RET_NORMAL;
    retire_inst_pointer = (p + 1) % DEBUG_INST_TRACE_SIZE;
}

void DiffState::record_abnormal_inst(uint32_t pc, uint32_t inst,
                                     uint32_t type, uint32_t cause) {
    int p = retire_inst_pointer;
    retire_inst_pc_queue[p]    = pc;
    retire_inst_inst_queue[p]  = inst;
    retire_inst_wdata_queue[p] = cause;
    retire_inst_type_queue[p]  = type;
    retire_inst_pointer = (p + 1) % DEBUG_INST_TRACE_SIZE;
}

void DiffState::display(int coreid) {
    printf("\n============== Commit Group Trace (Core %d) ==============\n", coreid);
    for (int j = 0; j < DEBUG_GROUP_TRACE_SIZE; j++) {
        printf("commit group [%x]: pc %08x cmtcnt %u %s\n",
            j, retire_group_pc_queue[j], retire_group_cnt_queue[j],
            (j == ((retire_group_pointer - 1 + DEBUG_GROUP_TRACE_SIZE) % DEBUG_GROUP_TRACE_SIZE)) ? "<--" : "");
    }

    printf("\n============== Commit Instr Trace ==============\n");
    for (int j = 0; j < DEBUG_INST_TRACE_SIZE; j++) {
        switch (retire_inst_type_queue[j]) {
        case RET_NORMAL:
            printf("commit inst [%x]: pc %08x inst %08x wen %u dst %08x data %08x ",
                j, retire_inst_pc_queue[j], retire_inst_inst_queue[j],
                retire_inst_wen_queue[j] != 0,
                retire_inst_wdst_queue[j], retire_inst_wdata_queue[j]);
            break;
        case RET_EXC:
            printf("exception   [%x]: pc %08x inst %08x cause %08x ",
                j, retire_inst_pc_queue[j], retire_inst_inst_queue[j],
                retire_inst_wdata_queue[j]);
            break;
        case RET_INT:
            printf("interrupt   [%x]: pc %08x inst %08x cause %08x ",
                j, retire_inst_pc_queue[j], retire_inst_inst_queue[j],
                retire_inst_wdata_queue[j]);
            break;
        }
        printf("%s\n", (j == ((retire_inst_pointer - 1 + DEBUG_INST_TRACE_SIZE) % DEBUG_INST_TRACE_SIZE)) ? "<--" : "");
    }
    fflush(stdout);
}

// ==================== DifftestEngine ====================

static const char* reg_name(int i) {
    static const char* names[] = {
        "r0",  "ra",  "tp",  "sp",  "a0",  "a1",  "a2",  "a3",
        "a4",  "a5",  "a6",  "a7",  "t0",  "t1",  "t2",  "t3",
        "t4",  "t5",  "t6",  "t7",  "t8",  " x",  "fp",  "s0",
        "s1",  "s2",  "s3",  "s4",  "s5",  "s6",  "s7",  "s8"
    };
    return (i >= 0 && i < 32) ? names[i] : "??";
}

static const char* csr_name(int idx) {
    static const char* names[] = {
        "crmd","prmd","euen","ecfg","era","badv","eentry",
        "tlbidx","tlbehi","tlbelo0","tlbelo1","asid","pgdl","pgdh",
        "save0","save1","save2","save3","tid","tcfg","tval",
        "llbctl","tlbrentry","dmw0","dmw1","estat"
    };
    return (idx >= 0 && idx < 26) ? names[idx] : "??";
}

DifftestEngine::DifftestEngine()
    : enabled_(true), has_commit_(false), instr_count_(0),
      ticks_(0), last_commit_(0),
      last_commit_pc_(0), last_commit_instr_(0), last_commit_valid_(false),
      program_img_(nullptr), program_size_(0) {}

void DifftestEngine::set_program(const uint8_t *img_data, uint64_t img_size) {
    program_img_ = img_data;
    program_size_ = img_size;
}

bool DifftestEngine::init(const char *ref_so_path, const char * /*img_path*/) {
    if (!proxy_.init(ref_so_path)) {
        return false;
    }

    if (program_img_ && program_size_ > 0) {
        proxy_.memcpy(RESET_VECTOR, (void*)program_img_,
                      (size_t)program_size_, DIFFTEST_TO_REF);
    }

    fprintf(stdout, "[difftest] initialized with %s\n", ref_so_path);
    return true;
}

bool DifftestEngine::checkregs(uint32_t *ref_buf) {
    uint32_t *dut_buf = difftest_state_buf();
    return (memcmp(dut_buf + 1, ref_buf + 1,
                   DIFFTEST_REG_SIZE - sizeof(uint32_t)) == 0);
}

void DifftestEngine::display(uint32_t *ref_buf, uint32_t pc) {
    state_.display(0);

    uint32_t *dut_buf = difftest_state_buf();
    int total_words = DIFFTEST_REG_SIZE / sizeof(uint32_t);

    fprintf(stderr, "\n==============  Register Diff  ==============\n");
    for (int i = 1; i < total_words; i++) {
        if (dut_buf[i] != ref_buf[i]) {
            if (i < DIFFTEST_NR_GPR) {
                fprintf(stderr, "[difftest] %s different at pc=0x%08x, "
                    "ref=0x%08x, dut=0x%08x\n",
                    reg_name(i), pc, ref_buf[i], dut_buf[i]);
            } else {
                int csr_idx = i - DIFFTEST_NR_GPR;
                if (csr_idx < DIFFTEST_NR_CSR) {
                    fprintf(stderr, "[difftest] %s different at pc=0x%08x, "
                        "ref=0x%08x, dut=0x%08x\n",
                        csr_name(csr_idx), pc, ref_buf[i], dut_buf[i]);
                } else {
                    fprintf(stderr, "[difftest] idle_pc different at pc=0x%08x, "
                        "ref=0x%08x, dut=0x%08x\n",
                        pc, ref_buf[i], dut_buf[i]);
                }
            }
        }
    }

    fprintf(stderr, "\n==============  REF Regs  ==============\n");
    fflush(stderr);
    if (proxy_.isa_reg_display) {
        proxy_.isa_reg_display();
    } else {
        fprintf(stderr, "[difftest] isa_reg_display not available\n");
    }
    fflush(stderr);
}

int DifftestEngine::check_timeout() {
    if (!has_commit_ && ticks_ > last_commit_ + kFirstCommitLimit) {
        fprintf(stderr, "[difftest] No instruction commits for %lu cycles. "
            "Check the first instruction.\n", kFirstCommitLimit);
        uint32_t ref_buf[DIFFTEST_REG_SIZE / 4];
        memset(ref_buf, 0, sizeof(ref_buf));
        display(ref_buf, 0);
        return 1;
    }

    if (has_commit_ && ticks_ > last_commit_ + kStuckLimit) {
        fprintf(stderr, "[difftest] No instruction commits for %lu cycles, "
            "maybe stuck.\n", kStuckLimit);
        fprintf(stderr, "[difftest] Let REF run one more instruction.\n");
        proxy_.exec(1);
        uint32_t ref_buf[DIFFTEST_REG_SIZE / 4];
        proxy_.regcpy((void*)ref_buf, DIFFTEST_TO_DUT, true);
        display(ref_buf, last_commit_pc_);
        return 1;
    }

    return 0;
}

void DifftestEngine::do_first_instr_commit() {
    if (!has_commit_) {
        uint32_t *dut_buf = difftest_state_buf();
        proxy_.regcpy((void*)dut_buf, DIFFTEST_TO_REF, true);
        has_commit_ = true;
        fprintf(stdout, "[difftest] state synced at startup\n");
    }
}

void DifftestEngine::step() {
    if (!enabled_ || !proxy_.loaded()) return;

    ticks_++;

    if (check_timeout()) {
        enabled_ = false;
        exit(1);
    }

    difftest_commit_t *cmt = difftest_get_commit();

    do_first_instr_commit();

    if (!cmt->valid) return;

    uint32_t pc = cmt->pc;
    last_commit_pc_ = pc;
    last_commit_instr_ = cmt->instr;
    last_commit_valid_ = true;
    last_commit_ = ticks_;

    *difftest_cycle_ptr() += 1;

    state_.record_inst(cmt->pc, cmt->instr, cmt->wen, cmt->wdest, cmt->wdata);

    state_.record_group(pc, 1);

    proxy_.exec(1);

    uint32_t ref_buf[DIFFTEST_REG_SIZE / 4];
    proxy_.regcpy((void*)ref_buf, DIFFTEST_TO_DUT, true);

    if (!checkregs(ref_buf)) {
        fprintf(stderr, "[difftest] mismatch at instruction #%lu\n",
            instr_count_);

        display(ref_buf, pc);

        fprintf(stderr, "[difftest] aborting\n");
        enabled_ = false;
        exit(1);
    }

    instr_count_++;
    if (instr_count_ % 10000 == 0) {
        fprintf(stdout, "[difftest] %lu instructions passed\n", instr_count_);
    }
}

void DifftestEngine::finish() {
    if (!proxy_.loaded()) return;
    fprintf(stdout, "[difftest] finished, %lu instructions checked\n", instr_count_);
}

void DifftestEngine::dump_state() {
    if (!proxy_.loaded()) return;
    fprintf(stdout, "[difftest] --- State dump ---\n");
    fprintf(stdout, "[difftest] total instructions checked: %lu\n", instr_count_);
    fprintf(stdout, "[difftest] total cycles: %lu\n", ticks_);
    if (last_commit_valid_) {
        fprintf(stdout, "[difftest] last committed: pc=0x%08x instr=0x%08x\n",
                last_commit_pc_, last_commit_instr_);
        fprintf(stdout, "[difftest] DUT state:\n");
        uint32_t *dut_buf = difftest_state_buf();
        for (int i = 0; i < DIFFTEST_NR_GPR; i++) {
            if (dut_buf[i] != 0) {
                fprintf(stdout, "  %s = 0x%08x\n", reg_name(i), dut_buf[i]);
            }
        }
    } else {
        fprintf(stdout, "[difftest] no instruction committed yet\n");
    }
    fflush(stdout);
}

// ==================== Public API ====================

static DifftestEngine *g_engine = nullptr;

DifftestEngine* difftest = nullptr;

void difftest_set_program(const uint8_t *img_data, uint64_t img_size) {
    if (!g_engine) g_engine = new DifftestEngine();
    g_engine->set_program(img_data, img_size);
}

bool difftest_init(const char *ref_so_path, const char *img_path) {
    if (!g_engine) return false;
    bool ok = g_engine->init(ref_so_path, img_path);
    if (ok) {
        difftest = g_engine;
        *difftest_cycle_ptr() = 0;
    }
    return ok;
}

void difftest_step() {
    if (difftest) difftest->step();
}

void difftest_finish() {
    if (difftest) difftest->finish();
}

bool difftest_is_running() {
    return difftest && difftest->is_running();
}

int difftest_trap_code() {
    difftest_trap_t *trap = difftest_get_trap();
    return (trap && trap->valid) ? (int)trap->code : -1;
}

void difftest_dump_state() {
    if (difftest) difftest->dump_state();
}
