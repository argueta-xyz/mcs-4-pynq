#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <stdlib.h>
#include "Vmcs4_tb.h"
#include "testbench.h"
#include "verilated.h"
using namespace std;

#define CTL_BASE_ADDR 0x0000
#define ROM_BASE_ADDR 0x1000
#define RAM_BASE_ADDR 0x2000

vector<int> parseRom(string filename) {
    // Parse ROM file
    vector<int> rom_bytes;
    vector<string> rom_byte_strings;
    ifstream stream;
    stream.open(filename, ios_base::in);
    if (stream.is_open()) {
        string rom_string;
        string line;
        while (getline(stream, line)) {
            rom_string += line + " ";
        }
        stream.close();

        istringstream iss(rom_string);
        copy(istream_iterator<string>(iss),
             istream_iterator<string>(),
             back_inserter(rom_byte_strings));
        cout << "ROM to load:";
        int i = 0;
        for (vector<string>::iterator it = rom_byte_strings.begin();
             it != rom_byte_strings.end(); ++it) {
            unsigned int b = stoul(*it, nullptr, 16);
            rom_bytes.push_back(b);
            if (i % 8 == 0) {
                cout << "\n\t0x" << setfill('0') << setw(2) << hex << i << ": ";
            }
            cout << setfill('0') << setw(2) << hex << b << " ";
            i++;
        }
        cout << endl;
    } else {
        cerr << "ERROR: Unable to open ROM file \'" << filename <<
                "\', using linked default.\n" << endl;
    }
    return rom_bytes;
}

void debugWrite(TESTBENCH<Vmcs4_tb>* tb, int addr, int wdata) {
    tb->m_core->dbg_wen = 1;
    tb->m_core->dbg_addr  = addr;
    tb->m_core->dbg_wdata = wdata;
    tb->tick();
    tb->m_core->dbg_wen = 0;
}

int debugRead(TESTBENCH<Vmcs4_tb>* tb, int addr) {
    tb->m_core->dbg_wen = 0;
    tb->m_core->dbg_addr  = addr;
    tb->m_core->dbg_wdata = 0;
    tb->tick();
    return tb->m_core->dbg_rdata;
}

void initMemory(TESTBENCH<Vmcs4_tb>* tb, vector<int> rom_bytes) {
    // Write ROMs while in reset
    tb->reset();
    for (int addr = 0; addr < rom_bytes.size(); addr++) {
        debugWrite(tb, ROM_BASE_ADDR | addr, rom_bytes[addr]);
    }
    tb->tick();
    cout << "Done initializing " << dec << rom_bytes.size() << " bytes" << endl;
}

void setResets(TESTBENCH<Vmcs4_tb>* tb, int cpu, int rom, int ram) {
    debugWrite(tb, CTL_BASE_ADDR | 0x0, ram << 2 | rom << 1 | cpu);
}

int main(int argc, char **argv, char** env) {
    // Initialize Verilators variables
    Verilated::commandArgs(argc, argv);
    int timeout = 30000;
    int time = 0;
    int extra_cycles = 32;

    // Create an instance of our module under test
    TESTBENCH<Vmcs4_tb>* tb = new TESTBENCH<Vmcs4_tb>();
    Vmcs4_tb* ports = tb->m_core;

    tb->openTrace("simx.fst");

    vector<int> rom_bytes;
    rom_bytes = parseRom("rom_00.hrom");
    tb->reset();

    initMemory(tb, rom_bytes);
    setResets(tb, 0, 0, 0);

    cout << "Tick #" << time << " [START]" << endl;
    ports->io_in = 0x09;
    // Tick the clock until we are done
    while(time < timeout && !tb->done()) {
        tb->tick();
        time++;
        cout << "\rTick #" << time << flush;
        if (ports->io_ram_out == 0x6) {
            if (extra_cycles == 32) {
                cout << " [SENTINEL RECEIVED]" << endl;
            }
            extra_cycles--;
            if (extra_cycles == 0) {
                break;
            }
        }
    }
    if (time >= timeout) {
        cout << " [TIMEOUT]" << endl;
    } else {
        cout << " [DONE]" << endl;
    }
    delete tb;
    exit(0);
}