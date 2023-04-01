# Project setup
PROJ      = hovalaag

# Files
FILES = ledscan.v big_7seg.v tt03-hovalaag/src/hovalaag_tiny_tapeout.v tt03-hovalaag/src/hovalaag_wrapper.v ring_oscillator.v tt03-hovalaag/src/decoder.v tt_top.v tt03-hovalaag/src/HovalaagCPU/Hovalaag.v

.PHONY: iceFUN clean burn

iceFUN:
	# Synthesize using Yosys
	yosys -p "synth_ice40 -top tt_top -json $(PROJ).json" -DSIM $(FILES) > yosys.log
	@grep Warn yosys.log || true
	@grep Error yosys.log || true
	@echo

	# Place and route using nextpnr
	nextpnr-ice40 -r --hx8k --json $(PROJ).json --package cb132 --pre-pack timing.py --asc $(PROJ).asc --opt-timing --pcf iceFUN.pcf > nextpnr.log 2>& 1
	@grep Warn nextpnr.log || true
	@grep Error nextpnr.log || true
	@echo

	# Convert to bitstream using IcePack
	icepack $(PROJ).asc $(PROJ).bin

burn:
	iceFUNprog $(PROJ).bin

clean:
	rm *.asc *.bin *blif
