#ifndef DIFFTEST_DUT_H
#define DIFFTEST_DUT_H

#include <cstdint>
#include <cstddef>

#define DEBUG_INST_TRACE_SIZE  16
#define DEBUG_GROUP_TRACE_SIZE 16

class RefProxy {
public:
    bool init(const char *ref_so_path);

    void (*memcpy)(uint32_t nemu_addr, void *dut_buf, size_t n, bool direction) = nullptr;
    void (*regcpy)(void *dut, bool direction, bool do_csr) = nullptr;
    void (*exec)(uint64_t n) = nullptr;
    void (*raise_intr)(uint64_t no) = nullptr;
    void (*isa_reg_display)() = nullptr;

    bool loaded() const { return handle != nullptr; }

private:
    void *handle = nullptr;
};

enum retire_inst_type {
    RET_NORMAL = 0,
    RET_INT,
    RET_EXC
};

class DiffState {
public:
    DiffState();

    void record_group(uint32_t pc, uint32_t count);
    void record_inst(uint32_t pc, uint32_t inst,
                     uint32_t wen, uint32_t wdest, uint32_t wdata);
    void record_abnormal_inst(uint32_t pc, uint32_t inst,
                              uint32_t type, uint32_t cause);
    void display(int coreid);

private:
    int retire_group_pointer = 0;
    uint32_t retire_group_pc_queue[DEBUG_GROUP_TRACE_SIZE];
    uint32_t retire_group_cnt_queue[DEBUG_GROUP_TRACE_SIZE];

    int retire_inst_pointer = 0;
    uint32_t retire_inst_pc_queue[DEBUG_INST_TRACE_SIZE];
    uint32_t retire_inst_inst_queue[DEBUG_INST_TRACE_SIZE];
    uint32_t retire_inst_wen_queue[DEBUG_INST_TRACE_SIZE];
    uint32_t retire_inst_wdst_queue[DEBUG_INST_TRACE_SIZE];
    uint32_t retire_inst_wdata_queue[DEBUG_INST_TRACE_SIZE];
    uint32_t retire_inst_type_queue[DEBUG_INST_TRACE_SIZE];
};

class DifftestEngine {
public:
    DifftestEngine();

    bool init(const char *ref_so_path, const char *img_path);
    void step();
    void finish();
    void dump_state();
    bool is_running() const { return enabled_; }

    void set_program(const uint8_t *img_data, uint64_t img_size);

private:
    static const uint64_t kFirstCommitLimit = 5000;
    static const uint64_t kStuckLimit       = 5000;

    RefProxy   proxy_;
    DiffState  state_;
    bool       enabled_ = true;
    bool       has_commit_ = false;
    uint64_t   instr_count_ = 0;
    uint64_t   ticks_ = 0;
    uint64_t   last_commit_ = 0;
    uint32_t   last_commit_pc_ = 0;
    uint32_t   last_commit_instr_ = 0;
    bool       last_commit_valid_ = false;

    const uint8_t *program_img_ = nullptr;
    uint64_t        program_size_ = 0;

    bool checkregs(uint32_t *ref_buf);
    void display(uint32_t *ref_buf, uint32_t pc);
    int  check_timeout();
    void do_first_instr_commit();
};

extern DifftestEngine* difftest;

bool difftest_init(const char *ref_so_path, const char *img_path);
void difftest_step();
void difftest_finish();
bool difftest_is_running();
int  difftest_trap_code();
void difftest_set_program(const uint8_t *img_data, uint64_t img_size);
void difftest_dump_state();

#endif
