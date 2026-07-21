#ifndef DIFFTEST_DUT_H
#define DIFFTEST_DUT_H

#include <cstdint>

bool difftest_init(const char *ref_so_path, const char *img_path);
void difftest_step();
void difftest_finish();
bool difftest_is_running();
int  difftest_trap_code();
void difftest_set_program(const uint8_t *img_data, uint64_t img_size);
void difftest_dump_state();

#endif
