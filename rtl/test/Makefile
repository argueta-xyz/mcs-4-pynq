DESIGN = mcs4
all:
	iverilog -o $(DESIGN).o -c $(DESIGN).f -g2012
	vvp $(DESIGN).o -lxt2

clean:
	rm $(DESIGN).o $(DESIGN).lxt
