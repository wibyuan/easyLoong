// Unit test: ex_mem_stall_dup — C++ harness with difftest
#include "Vtest_ex_mem_stall_dup.h"
#include "verilated.h"
#include "difftest_dut.h"
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <vector>

static constexpr int MAX_CYCLES = 10000;
static constexpr const char *NEMU_SO =
    "la32r-nemu/NEMU/build/la32r-nemu-interpreter-so";

int main(int argc, char **argv) {
    VerilatedContext context;
    Vtest_ex_mem_stall_dup tb(&context);

    const char *img_path = (argc > 1) ? argv[1] : "test_prog.bin";
    std::ifstream img_file(img_path, std::ios::binary | std::ios::ate);
    if (!img_file) {
        printf("FAIL: cannot open image file: %s\n", img_path);
        return 2;
    }
    size_t img_size = img_file.tellg();
    img_file.seekg(0, std::ios::beg);
    std::vector<uint8_t> img_data(img_size);
    img_file.read(reinterpret_cast<char*>(img_data.data()), img_size);
    difftest_set_program(img_data.data(), img_size);

    if (!difftest_init(NEMU_SO, nullptr)) {
        printf("FAIL: difftest init failed for %s\n", NEMU_SO);
        return 2;
    }
    printf("[DIFFTEST] initialized with %s, image %s (%zu bytes)\n",
           NEMU_SO, img_path, img_size);

    tb.reset = 1;
    tb.clk = 0;
    for (int c = 0; c < 5; ++c) {
        tb.clk = !tb.clk;
        tb.eval();
    }

    tb.reset = 0;
    for (int cycle = 0; cycle < MAX_CYCLES; ++cycle) {
        tb.clk = !tb.clk;
        tb.eval();
        if (tb.clk)
            difftest_step();
    }

    printf("TIMEOUT: no mismatch detected in %d cycles\n", MAX_CYCLES);
    difftest_finish();
    return 2;
}
