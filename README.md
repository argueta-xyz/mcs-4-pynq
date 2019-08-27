# MCS-"4" Pynq
#### An attempt to bring the venerable 4004 to the Pynq-Z2

## Project Layout

### RTL (rtl/)
A 4-bit processor (4004) with its respective ROM's (4001) and RAM's (4002) is implemented in SystemVerilog with some debug infrastructure wired in to allow remote manipulation and monitoring of the system as it's running.

### Simulation (sim/)
A simulation testbench is provided in Verilator with support for waveform dumping, makefiles handle generation & updating of specified ROMs.

### ROMs (roms/)
Example Assembly files are provided to exercise the system, along with a rudimentary assembler (located in sw/) to convert the ROMs into ASCII Hex ROMs that can be parsed and loaded by the testbench or eventually by the Zynq main processor.

### Software (sw/)
An assembler for the ASM files and a gold model for the Fibonacci "Random" program.

### Vivado (vivado/)
All TCL scripts necessary to inflate a BlockDesign and Vivado Project to synthesize a bitfile for the Pynq-Z2 platform. MCS-4 system is packaged into an IP with parameterizable ROM & RAM configurations.

## Getting Started
### Simulation
```bash
cd sim/
make ROM=../roms/fibonacci_rand.asm
gtkwave obj_dir/simx.fst &
```
| ROM | Function |
|-----|----------|
|fibonacci_rand | Generates Fibonacci mod 128                    |
|no_branch_bist | All non-branching instruction quick test       |
|ram_test   | Writes and reads a bunch of different RAMs         |
|stack_test | Plays around with branching and stack instructions |

### Synthesis
```bash
cd vivado/
vivado -mode batch -source ./mcs4pynq_proj.tcl
start_gui
```

### Tools Required
1. Vivado 2019.1 WebPack (license for Zynq-Z7020)
2. Verilator
3. Python
4. Pynq-Z2
