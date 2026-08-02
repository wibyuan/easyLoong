// Cache hierarchy unit test main: run the SV testbench to $finish.
#include "verilated.h"
#include "Vtest_tb.h"

#include <memory>

int main(int argc, char** argv, char**) {
    Verilated::debug(0);
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
    contextp->commandArgs(argc, argv);

    const std::unique_ptr<Vtest_tb> topp{new Vtest_tb{contextp.get(), ""}};

    while (!contextp->gotFinish()) {
        topp->eval();
        if (!topp->eventsPending()) break;
        contextp->time(topp->nextTimeSlot());
    }

    if (!contextp->gotFinish())
        VL_DEBUG_IF(VL_PRINTF("+ Exiting without $finish; no events left\n"););

    topp->final();
    return 0;
}
