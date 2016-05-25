# if using Makefile for iverilog:
# - change $stop to $finish is testbenches
# - uncomment "initial $dumpvars(0, tb_name);" to get waveforms
source=pd1_tb.sv memory.sv
iFlags=-g2005-sv

.PHONY: run
run: SimpleAdd BubbleSort

# tb_SimpleAdd
.PHONY: SimpleAdd
SimpleAdd: tb_SimpleAdd.vvp
	vvp $<

.PHONY: SimpleAdd-debug
SimpleAdd-debug: tb_SimpleAdd.lx2
	gtkwave -A $< &

tb_SimpleAdd.vvp: $(source) SimpleAdd.x
	iverilog $(iFlags) -s tb_SimpleAdd -o $@ $(source)

# tb_BubbleSort
.PHONY: BubbleSort
BubbleSort: tb_BubbleSort.vvp
	vvp $<

.PHONY: BubbleSort-debug
BubbleSort-debug: tb_BubbleSort.lx2
	gtkwave -A $< &

tb_BubbleSort.vvp: $(source) BubbleSort.x
	iverilog $(iFlags) -s tb_BubbleSort -o $@ $(source)

%.lx2: %.vvp
	vvp $< -lxt2
	mv dump.lx2 $@

clean:
	rm -f *.vvp *.lx2 *.vcd
