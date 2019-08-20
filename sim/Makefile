ROM =../roms/no_branch_bist.hrom
HROM = $(basename $(ROM)).hrom
ASM = $(basename $(ROM)).asm
DESIGN = mcs4
TOP_MODULE = mcs4_tb

# Run sim, depends on verilated module & HROM
run: ./V$(TOP_MODULE) $(HROM)
	cd obj_dir; \
	ln -sf ../$(HROM) rom_00.hrom; \
	./V$(TOP_MODULE) --trace

# Verilated module depends on 'verilated' rule
./V$(TOP_MODULE):
	make verilate

# Actual rule to verilate module
verilate:
	verilator -Wall -f $(DESIGN).f -cc --top-module $(TOP_MODULE) --exe ./$(DESIGN)_tb.cpp --trace-fst; \
	cd obj_dir; \
	make -j -C ./ -f V$(TOP_MODULE).mk V$(TOP_MODULE); \

# Assemble HROM as needed from ASM
$(HROM): $(ASM)
	../sw/assembler.py $(ASM)

clean:
	rm -rf $(DESIGN).o $(DESIGN).lxt; \
	rm -rf obj_dir

roms: ../roms/*.asm
	for file in $^ ; do \
		../sw/assembler.py $${file} ; \
	done


