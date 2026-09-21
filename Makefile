XRUN?=xrun
VERILATOR?=verilator-cli
TEST?=i2c_test
SEED?=random
.PHONY: uvm regress lint smoke clean
uvm:
	mkdir -p results
	$(XRUN) -64bit -sv -uvm -f sim/files.f -top tb_top +UVM_TESTNAME=$(TEST) -svseed $(SEED) -access +rwc -coverage all -covoverwrite -covworkdir results/xcelium_cov -l results/xrun_$(TEST).log
regress:
	@for seed in 7 19 47 83 149;do $(MAKE) uvm SEED=$$seed||exit 1;done
lint:
	$(VERILATOR) --lint-only --sv --timing -Wall -Wno-fatal rtl/i2c_master_write.sv
smoke:
	rm -rf build/obj_i2c;mkdir -p build
	$(VERILATOR) --binary --sv --timing --assert -Wall -Wno-fatal -Wno-SYNCASYNCNET --top-module tb_i2c_smoke --Mdir build/obj_i2c rtl/i2c_master_write.sv tb/models/i2c_slave_model.sv tb/assertions/i2c_sva.sv tb/smoke/tb_i2c_smoke.sv
	bash -o pipefail -c './build/obj_i2c/Vtb_i2c_smoke | tee results_smoke.log'
clean:
	rm -rf build xcelium.d INCA_libs waves.shm results *.log *.key
