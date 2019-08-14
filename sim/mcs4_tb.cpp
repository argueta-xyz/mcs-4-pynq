#include <stdlib.h>
#include "Vmcs4_tb.h"
#include "testbench.h"
#include "verilated.h"

int main(int argc, char **argv, char** env) {
    // Initialize Verilators variables
    Verilated::commandArgs(argc, argv);
    int timeout = 10000;
    int time = 0;
    int extra_cycles = 32;

    // Create an instance of our module under test
    TESTBENCH<Vmcs4_tb>* tb = new TESTBENCH<Vmcs4_tb>();
    Vmcs4_tb* ports = tb->m_core;

    tb->openTrace("simx.fst");

    printf("Starting at time: #%d\n", time);
    tb->reset();
    ports->io_in = 0xA;
    // Tick the clock until we are done
    while(time < timeout && !tb->done()) {
        tb->tick();
        time++;
        printf("\rTick #%d", time);
        if (ports->io_rom_out == 0x3 && ports->io_ram_out == 0x6) {
            extra_cycles--;
            if (extra_cycles == 0) {
                break;
             }
        }
    }
    printf("\nDone at time #%d\n", time);

    delete tb;
    exit(0);
}