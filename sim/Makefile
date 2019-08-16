ROM =../roms/no_branch_bist.hrom
DESIGN = mcs4
TOP_MODULE = mcs4_tb
verilate:
	verilator -Wall -f $(DESIGN).f -cc --top-module $(TOP_MODULE) --exe ./$(DESIGN)_tb.cpp --trace-fst; \
	cd obj_dir; \
	ln -sf ../$(ROM) rom_00.hrom; \
	make -j -C ./ -f V$(TOP_MODULE).mk V$(TOP_MODULE); \
	./V$(TOP_MODULE) --trace

run:
	cd obj_dir; \
	./V$(TOP_MODULE) --trace

clean:
	rm -rf $(DESIGN).o $(DESIGN).lxt; \
	rm -rf obj_dir
