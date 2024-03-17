XSIM_DIR =  $(CURDIR)/sim_out_ongoru_cevreleyici
TESTBENCH_NAME = ongoru_cevreleyici
TEST_FILES += $(CURDIR)/$(TESTBENCH_NAME).v

.PHONY: clean
.SILENT: clean 
clean: xsim 
	echo "Simulation Output saved to ${XSIM_DIR}"
	rm -r xvlog*
	rm -r xelab*
	rm -r xsim*

preclean:
	@if [ -d "$(XSIM_DIR)" ]; then \
		rm -r "$(XSIM_DIR)"; \
		echo "Removed $(XSIM_DIR)"; \
	fi

xvlog: preclean
	@echo "Parsing HDL files"
	@mkdir -p $(XSIM_DIR)
	@xvlog $(TEST_FILES) > $(XSIM_DIR)/vlog.txt

xelab: xvlog
	@echo "Executing Elaboration step"
	@xelab -top $(TESTBENCH_NAME) -snapshot tb_out > $(XSIM_DIR)/elab.txt

xsim: xelab
	@echo "Running Simulation"
	@xsim tb_out -R --wdb $(XSIM_DIR)/tb_out.wdb > $(XSIM_DIR)/sim.txt
	@mv *.vcd $(XSIM_DIR)/

wave: clean
	@echo "Opening waveform file"
	@gtkwave $(XSIM_DIR)/$(TESTBENCH_NAME).vcd

coco:
	SIM ?= icarus
	TOPLEVEL_LANG ?= verilog

	TOP_LEVEL = fetch1
	MODULE = fetch1

	include $(shell cocotb-config --makefiles)/Makefile.sim
