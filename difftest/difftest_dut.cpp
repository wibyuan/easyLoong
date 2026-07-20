#include "difftest_dut.h"
#include "difftest_interface.h"
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <dlfcn.h>

#define RESET_VECTOR 0x1c000000

enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };

typedef uint32_t paddr_t;
typedef uint32_t word_t;

static void *so_handle = nullptr;

static void (*ref_memcpy)(paddr_t, void*, size_t, bool) = nullptr;
static void (*ref_regcpy)(void*, bool, bool) = nullptr;
static void (*ref_exec)(uint64_t) = nullptr;
static void (*ref_raise_intr)(uint64_t) = nullptr;

static bool has_commit = false;
static uint64_t instr_count = 0;
static bool difftest_enabled = true;

static const char* reg_name(int i) {
    static const char* names[] = {
        "r0",  "ra",  "tp",  "sp",  "a0",  "a1",  "a2",  "a3",
        "a4",  "a5",  "a6",  "a7",  "t0",  "t1",  "t2",  "t3",
        "t4",  "t5",  "t6",  "t7",  "t8",  " x",  "fp",  "s0",
        "s1",  "s2",  "s3",  "s4",  "s5",  "s6",  "s7",  "s8"
    };
    return (i >= 0 && i < 32) ? names[i] : "??";
}

static const uint8_t* program_img = nullptr;
static uint64_t program_size = 0;

void difftest_set_program(const uint8_t *img_data, uint64_t img_size) {
    program_img = img_data;
    program_size = img_size;
}

bool difftest_init(const char *ref_so_path, const char *img_path) {
    so_handle = dlopen(ref_so_path, RTLD_LAZY);
    if (!so_handle) {
        fprintf(stderr, "[difftest] dlopen(%s) failed: %s\n", ref_so_path, dlerror());
        return false;
    }

    ref_memcpy      = (void(*)(paddr_t, void*, size_t, bool))dlsym(so_handle, "difftest_memcpy");
    ref_regcpy      = (void(*)(void*, bool, bool))dlsym(so_handle, "difftest_regcpy");
    ref_exec        = (void(*)(uint64_t))dlsym(so_handle, "difftest_exec");
    ref_raise_intr  = (void(*)(uint64_t))dlsym(so_handle, "difftest_raise_intr");

    if (!ref_memcpy || !ref_regcpy || !ref_exec) {
        fprintf(stderr, "[difftest] dlsym failed: %s\n", dlerror());
        dlclose(so_handle);
        so_handle = nullptr;
        return false;
    }

    void (*ref_init)() = (void(*)())dlsym(so_handle, "difftest_init");
    if (!ref_init) {
        fprintf(stderr, "[difftest] dlsym(difftest_init) failed: %s\n", dlerror());
        dlclose(so_handle);
        so_handle = nullptr;
        return false;
    }

    ref_init();

    if (program_img && program_size > 0) {
        ref_memcpy(RESET_VECTOR, (void*)program_img, (size_t)program_size, DIFFTEST_TO_REF);
    }

    fprintf(stdout, "[difftest] initialized with %s\n", ref_so_path);
    return true;
}

static bool checkregs(uint32_t *ref_buf, uint32_t pc) {
    uint32_t *dut_buf = difftest_state_buf();
    int total_words = DIFFTEST_REG_SIZE / sizeof(uint32_t);
    if (memcmp(dut_buf + 1, ref_buf + 1, DIFFTEST_REG_SIZE - sizeof(uint32_t))) {
        for (int i = 1; i < total_words; i++) {
            if (dut_buf[i] != ref_buf[i]) {
                if (i < DIFFTEST_NR_GPR) {
                    fprintf(stderr, "[difftest] %s different at pc=0x%08x, "
                        "ref=0x%08x, dut=0x%08x\n",
                        reg_name(i), pc, ref_buf[i], dut_buf[i]);
                } else {
                    int csr_idx = i - DIFFTEST_NR_GPR;
                    if (csr_idx < DIFFTEST_NR_CSR) {
                        const char *csr_names[] = {
                            "crmd","prmd","euen","ecfg","era","badv","eentry",
                            "tlbidx","tlbehi","tlbelo0","tlbelo1","asid","pgdl","pgdh",
                            "save0","save1","save2","save3","tid","tcfg","tval",
                            "llbctl","tlbrentry","dmw0","dmw1","estat"
                        };
                        fprintf(stderr, "[difftest] %s different at pc=0x%08x, "
                            "ref=0x%08x, dut=0x%08x\n",
                            csr_names[csr_idx], pc, ref_buf[i], dut_buf[i]);
                    } else {
                        fprintf(stderr, "[difftest] idle_pc different at pc=0x%08x, "
                            "ref=0x%08x, dut=0x%08x\n",
                            pc, ref_buf[i], dut_buf[i]);
                    }
                }
            }
        }
        return false;
    }
    return true;
}

void difftest_step() {
    if (!difftest_enabled || !so_handle) return;

    difftest_commit_t *cmt = difftest_get_commit();

    if (!has_commit) {
        ref_regcpy((void*)difftest_state_buf(), DIFFTEST_TO_REF, true);
        has_commit = true;
        fprintf(stdout, "[difftest] state synced at startup\n");
    }

    if (!cmt->valid) return;

    uint32_t pc = cmt->pc;
    *difftest_cycle_ptr() += 1;

    ref_exec(1);

    uint32_t ref_buf[DIFFTEST_REG_SIZE / 4];
    ref_regcpy((void*)ref_buf, DIFFTEST_TO_DUT, true);

    if (!checkregs(ref_buf, pc)) {
        fprintf(stderr, "[difftest] mismatch at instruction #%lu, aborting\n",
            instr_count);
        difftest_enabled = false;
        exit(1);
    }

    instr_count++;
    if (instr_count % 10000 == 0) {
        fprintf(stdout, "[difftest] %lu instructions passed\n", instr_count);
    }
}

void difftest_finish() {
    if (!so_handle) return;
    fprintf(stdout, "[difftest] finished, %lu instructions checked\n", instr_count);
}
