#include <stdlib.h>
#include "Vmcs4_tb.h"
#include "testbench.h"
#include "verilated.h"

int main(int argc, char **argv, char** env) {
    // Initialize Verilators variables
    Verilated::commandArgs(argc, argv);
    int timeout = 1000;
    int time = 0;

    // Create an instance of our module under test
    TESTBENCH<Vmcs4_tb>* tb = new TESTBENCH<Vmcs4_tb>();

    tb->openTrace("simx.fst");

    printf("Starting at time: #%d\n", time);
    tb->reset();
    // Tick the clock until we are done
    while(time < timeout && !tb->done()){
        tb->tick();
        time++;
        printf("\rTick #%d", time);
    }
    printf("\nDone at time #%d\n", time);

    delete tb;
    exit(0);
}