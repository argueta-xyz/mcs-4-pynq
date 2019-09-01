#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <stdlib.h>
#include "svdpi.h"
#include "axi_testbench.h"
#include "verilated.h"
#include "Vmcs4_sys_tb.h"
using namespace std;

#define CTL_BASE_ADDR 0x0000
#define ROM_BASE_ADDR 0x1000
#define RAM_BASE_ADDR 0x2000
#define IO_BASE_ADDR  0x3000

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
    for (int i = 0; i < (rom_bytes.size() % 4); ++i) {
        rom_bytes.push_back(0);
    }
    return rom_bytes;
}

void initMemory(AXI_TESTBENCH<Vmcs4_sys_tb>* tb, vector<int> rom_bytes) {
    // Write ROMs while in reset
    for (int addr = 0; addr < rom_bytes.size(); addr+=4) {
        int wdata = (rom_bytes[addr + 0]  & 0xFF) << 0  |
                    (rom_bytes[addr + 1]  & 0xFF) << 8  |
                    (rom_bytes[addr + 2]  & 0xFF) << 16 |
                    (rom_bytes[addr + 3]  & 0xFF) << 24;
        tb->axiWrite(ROM_BASE_ADDR | addr, wdata);
        int out = tb->axiRead(ROM_BASE_ADDR | addr);
        if (out != wdata) {
            cout << "ERROR: RData[" << hex << addr << "] != WData:\n\tExp: " <<
                    wdata << "\n\tGot: " << out << dec << endl;
        }
    }
    cout << "Done initializing " << dec << rom_bytes.size() << " bytes" << endl;
}

void setResets(AXI_TESTBENCH<Vmcs4_sys_tb>* tb, int cpu, int rom, int ram) {
    tb->axiWrite(CTL_BASE_ADDR | 0x0, ram << 2 | rom << 1 | cpu);
}

void setInputs(AXI_TESTBENCH<Vmcs4_sys_tb>* tb, int hi, int lo) {
    tb->axiWrite(CTL_BASE_ADDR | 0x10, 0x1);
    tb->axiWrite(IO_BASE_ADDR  | 0x0, lo);
    tb->axiWrite(IO_BASE_ADDR  | 0x4, hi);
}

void getCpuInfo(AXI_TESTBENCH<Vmcs4_sys_tb>* tb) {
    int instr_pc = tb->axiRead(CTL_BASE_ADDR | 0x4);
    int idxr_07 = tb->axiRead(CTL_BASE_ADDR | 0x8);
    int idxr_8F = tb->axiRead(CTL_BASE_ADDR | 0xC);
    int rom_out = tb->axiRead(IO_BASE_ADDR | 0x10);
    int ram_out = tb->axiRead(IO_BASE_ADDR | 0x20);
    cout << "PC: " << hex << (instr_pc & 0xFFF)
         << "\tInstr: " << ((instr_pc >> 16) & 0xFF)
         << endl << "\tP3-P0:[" << setfill('0') << setw(8) << idxr_07 << "]"
         << endl << "\tP7-P4:[" << setfill('0') << setw(8) << idxr_8F << "]"
         << endl << "\tROM Out:[" << setfill('0') << setw(8) << rom_out << "]"
         << endl << "\tRAM Out:[" << setfill('0') << setw(8) << ram_out << "]"
         << endl;
}

void dumpRamContents(AXI_TESTBENCH<Vmcs4_sys_tb>* tb, int addr, int size) {
    cout << "Dumping RAM contents from 0x" << hex << addr << " to 0x"
         << addr + size << endl;

    for (int i = addr; i < addr + size; i+=4) {
        int data = tb->axiRead(RAM_BASE_ADDR | i);
        cout << "\t0x" << setfill('0') << setw(2) << hex << i << ": "
             << setfill('0') << setw(8) << hex << data << endl;
    }
}

int main(int argc, char **argv, char** env) {
    // Initialize Verilators variables
    Verilated::commandArgs(argc, argv);
    int timeout = 30000;
    int time = 0;
    int extra_cycles = 32;

    // Create an instance of our module under test
    AXI_TESTBENCH<Vmcs4_sys_tb>* tb = new AXI_TESTBENCH<Vmcs4_sys_tb>();
    Vmcs4_sys_tb* ports = tb->m_core;

    tb->openTrace("simx.fst");

    vector<int> rom_bytes;
    rom_bytes = parseRom("rom_00.hrom");
    tb->reset();

    initMemory(tb, rom_bytes);
    setInputs(tb, 0x0, 0x9);
    setResets(tb, 0, 0, 0);
    cout << "Tick #" << time << " [START]" << endl;
    // Tick the clock until we are done
    while(time < timeout && !tb->done()) {
        tb->tick();
        time++;
        cout << "\rTick #" << dec << time << flush;
        if (time % 500 == 0x6) {
            int ram_out = tb->axiRead(IO_BASE_ADDR | 0x20);
            if(ram_out == 0x6){
                cout << " [SENTINEL RECEIVED]" << endl;
                for (int i = 0; i < extra_cycles; ++i) {
                    tb->tick();
                    time++;
                    cout << "\rTick #" << time << flush;
                }
                break;
            }
        }
    }
    if (time >= timeout) {
        cout << " [TIMEOUT]" << endl;
    } else {
        cout << " [DONE]" << endl;
    }
    getCpuInfo(tb);
    dumpRamContents(tb, 0x0, 0x40);
    delete tb;
    exit(0);
}