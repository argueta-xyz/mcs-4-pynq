#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <stdlib.h>
#include "Vmcs4_tb.h"
#include "testbench.h"
#include "verilated.h"
using namespace std;

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

void initMemory(TESTBENCH<Vmcs4_tb>* tb, vector<int> rom_bytes) {
    // Write ROMs while in reset
    tb->m_core->rst = 1;
    tb->m_core->dbg_wen = 1;
    for (int addr = 0; addr < rom_bytes.size(); addr++) {
        tb->m_core->dbg_addr  = addr;
        tb->m_core->dbg_wdata = rom_bytes[addr];
        tb->tick();
    }
    tb->m_core->dbg_wen = 0;
    tb->tick();
    tb->m_core->rst = 0;
    cout << "Done initializing " << dec << rom_bytes.size() << " bytes" << endl;
}

int main(int argc, char **argv, char** env) {
    // Initialize Verilators variables
    Verilated::commandArgs(argc, argv);
    int timeout = 20000;
    int time = 0;
    int extra_cycles = 32;

    // Create an instance of our module under test
    TESTBENCH<Vmcs4_tb>* tb = new TESTBENCH<Vmcs4_tb>();
    Vmcs4_tb* ports = tb->m_core;

    tb->openTrace("simx.fst");

    vector<int> rom_bytes;
    rom_bytes = parseRom("rom_00.hrom");
    initMemory(tb, rom_bytes);

    cout << "Tick #" << time << " [START]" << endl;
    tb->reset();
    ports->io_in = 0xA;
    // Tick the clock until we are done
    while(time < timeout && !tb->done()) {
        tb->tick();
        time++;
        cout << "\rTick #" << time << flush;
        if (ports->io_rom_out == 0x3 && ports->io_ram_out == 0x6) {
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