NSCSCC_DIR     := nscscc-solo-la-soc
SUPERVISOR_DIR := $(NSCSCC_DIR)/sdk/software/examples/supervisor
NEMU_SO        := la32r-nemu/NEMU/build/la32r-nemu-interpreter-so
TOOLCHAIN_BIN  := $(CURDIR)/$(NSCSCC_DIR)/sdk/toolchains/loongson-gnu-toolchain-8.3-x86_64-loongarch32r-linux-gnusf-v2.0/bin
SIM_CASES_DIR  := $(SUPERVISOR_DIR)/sim/cases
FPGA_DIR       := $(NSCSCC_DIR)/fpga

# Vivado Docker build/simulation scaffolding.
# The Vivado 2019.2 Docker image (vivado:2019.2) must exist locally.
DOCKER_VIVADO_RUN = docker run --rm -v "$(CURDIR)/$(NSCSCC_DIR)":/workspace vivado:2019.2 \
                    bash -c "source /opt/Xilinx/Vivado/2019.2/settings64.sh && $(1)"

DIFF ?= 1

DIFF_SO_PATH := ../$(NEMU_SO)
DIFF_IMG_AUTO     := sdk/software/examples/supervisor/build/kernel/auto/kernel.bin
DIFF_IMG_UNCACHE  := sdk/software/examples/supervisor/build/kernel/uncache/kernel.bin

ifeq ($(DIFF),1)
DIFF_FLAGS_simple      := -- +diff_so=$(DIFF_SO_PATH) +diff_img=$(DIFF_IMG_AUTO)
DIFF_FLAGS_fibonacci   := -- +diff_so=$(DIFF_SO_PATH) +diff_img=$(DIFF_IMG_UNCACHE)
DIFF_FLAGS_matrix      := -- +diff_so=$(DIFF_SO_PATH) +diff_img=$(DIFF_IMG_AUTO)
DIFF_FLAGS_stream      := -- +diff_so=$(DIFF_SO_PATH) +diff_img=$(DIFF_IMG_AUTO)
DIFF_FLAGS_cryptonight := -- +diff_so=$(DIFF_SO_PATH) +diff_img=$(DIFF_IMG_AUTO)
DIFF_FLAGS_mixed       := -- +diff_so=$(DIFF_SO_PATH) +diff_img=$(DIFF_IMG_AUTO)
else
DIFF_FLAGS_simple      :=
DIFF_FLAGS_fibonacci   :=
DIFF_FLAGS_matrix      :=
DIFF_FLAGS_stream      :=
DIFF_FLAGS_cryptonight :=
DIFF_FLAGS_mixed       :=
endif

.PHONY: build build-nemu build-supervisor \
        test-simple test-fibonacci test-matrix test-stream test-cryptonight test-mixed test-all \
        clean clean-nemu clean-supervisor \
        build-bitstream \
        vivado-sim-behavioral-simple vivado-sim-behavioral-fibonacci \
        vivado-sim-behavioral-matrix vivado-sim-behavioral-stream \
        vivado-sim-behavioral-cryptonight vivado-sim-behavioral-mixed \
        vivado-sim-behavioral-all \
        vivado-sim-post-impl-simple vivado-sim-post-impl-fibonacci \
        vivado-sim-post-impl-matrix vivado-sim-post-impl-stream \
        vivado-sim-post-impl-cryptonight vivado-sim-post-impl-mixed \
        vivado-sim-post-impl-all \
        clean-vivado

build: build-nemu build-supervisor

build-nemu:
	$(MAKE) -C difftest build

build-supervisor:
	cd $(SUPERVISOR_DIR) && PATH=$(TOOLCHAIN_BIN):$$PATH ./build_all.sh

test-simple: build
	cd $(NSCSCC_DIR) && python3 sim/run.py sdk/software/examples/supervisor/sim/cases/simple.json $(DIFF_FLAGS_simple)

test-fibonacci: build
	cd $(NSCSCC_DIR) && python3 sim/run.py sdk/software/examples/supervisor/sim/cases/fibonacci.json $(DIFF_FLAGS_fibonacci)

test-matrix: build
	cd $(NSCSCC_DIR) && python3 sim/run.py sdk/software/examples/supervisor/sim/cases/matrix.json $(DIFF_FLAGS_matrix)

test-stream: build
	cd $(NSCSCC_DIR) && python3 sim/run.py sdk/software/examples/supervisor/sim/cases/stream.json $(DIFF_FLAGS_stream)

test-cryptonight: build
	cd $(NSCSCC_DIR) && python3 sim/run.py sdk/software/examples/supervisor/sim/cases/cryptonight.json $(DIFF_FLAGS_cryptonight)

test-mixed: build
	cd $(NSCSCC_DIR) && python3 sim/run.py sdk/software/examples/supervisor/sim/cases/mixed.json $(DIFF_FLAGS_mixed)

test-all: build
	-cd $(NSCSCC_DIR) && python3 sim/run.py sdk/software/examples/supervisor/sim/cases/simple.json $(DIFF_FLAGS_simple)
	-cd $(NSCSCC_DIR) && python3 sim/run.py sdk/software/examples/supervisor/sim/cases/stream.json $(DIFF_FLAGS_stream)
	-cd $(NSCSCC_DIR) && python3 sim/run.py sdk/software/examples/supervisor/sim/cases/matrix.json $(DIFF_FLAGS_matrix)
	-cd $(NSCSCC_DIR) && python3 sim/run.py sdk/software/examples/supervisor/sim/cases/mixed.json $(DIFF_FLAGS_mixed)
	-cd $(NSCSCC_DIR) && python3 sim/run.py sdk/software/examples/supervisor/sim/cases/cryptonight.json $(DIFF_FLAGS_cryptonight)
	-cd $(NSCSCC_DIR) && python3 sim/run.py sdk/software/examples/supervisor/sim/cases/fibonacci.json $(DIFF_FLAGS_fibonacci)

# ─── Vivado Bitstream ────────────────────────────────────────────────
# Synthesize, implement, and generate the FPGA bitstream inside the
# Vivado 2019.2 Docker container.  The project is re-created from
# scratch each time.
build-bitstream:
	$(call DOCKER_VIVADO_RUN, \
	 cd /workspace/fpga && \
	 vivado -mode batch -source create_project.tcl && \
	 vivado -mode batch -source build_bitstream.tcl)

# ─── Vivado Behavioral Simulation (XSIM) ─────────────────────────────
# Each target runs one supervisor test case in Vivado XSim at the RTL
# level.  The Vivado project must already exist (created by
# build-bitstream or vivado-sim-behavioral-all).
vivado-sim-behavioral-simple: build-supervisor
	$(call DOCKER_VIVADO_RUN, \
	 cd /workspace && \
	 python3 sim/run.py sdk/software/examples/supervisor/sim/cases/simple.json --backend xsim)

vivado-sim-behavioral-fibonacci: build-supervisor
	$(call DOCKER_VIVADO_RUN, \
	 cd /workspace && \
	 python3 sim/run.py sdk/software/examples/supervisor/sim/cases/fibonacci.json --backend xsim)

vivado-sim-behavioral-matrix: build-supervisor
	$(call DOCKER_VIVADO_RUN, \
	 cd /workspace && \
	 python3 sim/run.py sdk/software/examples/supervisor/sim/cases/matrix.json --backend xsim)

vivado-sim-behavioral-stream: build-supervisor
	$(call DOCKER_VIVADO_RUN, \
	 cd /workspace && \
	 python3 sim/run.py sdk/software/examples/supervisor/sim/cases/stream.json --backend xsim)

vivado-sim-behavioral-cryptonight: build-supervisor
	$(call DOCKER_VIVADO_RUN, \
	 cd /workspace && \
	 python3 sim/run.py sdk/software/examples/supervisor/sim/cases/cryptonight.json --backend xsim)

vivado-sim-behavioral-mixed: build-supervisor
	$(call DOCKER_VIVADO_RUN, \
	 cd /workspace && \
	 python3 sim/run.py sdk/software/examples/supervisor/sim/cases/mixed.json --backend xsim)

vivado-sim-behavioral-all: build-supervisor
	$(call DOCKER_VIVADO_RUN, \
	 cd /workspace && \
	 python3 sim/run.py sdk/software/examples/supervisor/sim/suite.json --backend xsim --recreate-project)

# ─── Vivado Post-Implementation Timing Simulation ─────────────────────
# Each target runs one supervisor test case against the gate-level
# netlist with SDF delay annotation (post-implementation timing
# simulation).  Requires a completed bitstream build.
vivado-sim-post-impl-simple: build-bitstream
	$(call DOCKER_VIVADO_RUN, \
	 cd /workspace && \
	 python3 sim/run_post_impl.py sdk/software/examples/supervisor/sim/cases/simple.json)

vivado-sim-post-impl-fibonacci: build-bitstream
	$(call DOCKER_VIVADO_RUN, \
	 cd /workspace && \
	 python3 sim/run_post_impl.py sdk/software/examples/supervisor/sim/cases/fibonacci.json)

vivado-sim-post-impl-matrix: build-bitstream
	$(call DOCKER_VIVADO_RUN, \
	 cd /workspace && \
	 python3 sim/run_post_impl.py sdk/software/examples/supervisor/sim/cases/matrix.json)

vivado-sim-post-impl-stream: build-bitstream
	$(call DOCKER_VIVADO_RUN, \
	 cd /workspace && \
	 python3 sim/run_post_impl.py sdk/software/examples/supervisor/sim/cases/stream.json)

vivado-sim-post-impl-cryptonight: build-bitstream
	$(call DOCKER_VIVADO_RUN, \
	 cd /workspace && \
	 python3 sim/run_post_impl.py sdk/software/examples/supervisor/sim/cases/cryptonight.json)

vivado-sim-post-impl-mixed: build-bitstream
	$(call DOCKER_VIVADO_RUN, \
	 cd /workspace && \
	 python3 sim/run_post_impl.py sdk/software/examples/supervisor/sim/cases/mixed.json)

vivado-sim-post-impl-all: build-bitstream
	$(call DOCKER_VIVADO_RUN, \
	 set +e; cd /workspace; \
	 python3 sim/run_post_impl.py sdk/software/examples/supervisor/sim/cases/simple.json; \
	 python3 sim/run_post_impl.py sdk/software/examples/supervisor/sim/cases/fibonacci.json; \
	 python3 sim/run_post_impl.py sdk/software/examples/supervisor/sim/cases/matrix.json; \
	 python3 sim/run_post_impl.py sdk/software/examples/supervisor/sim/cases/stream.json; \
	 python3 sim/run_post_impl.py sdk/software/examples/supervisor/sim/cases/cryptonight.json; \
	 python3 sim/run_post_impl.py sdk/software/examples/supervisor/sim/cases/mixed.json)

clean-vivado:
	rm -rf $(FPGA_DIR)/project $(FPGA_DIR)/vivado.log $(FPGA_DIR)/vivado.jou \
	       $(FPGA_DIR)/vivado_*.backup.jou $(FPGA_DIR)/vivado_*.backup.log \
	       $(FPGA_DIR)/.Xil

clean-nemu:
	$(MAKE) -C difftest clean

clean-supervisor:
	cd $(SUPERVISOR_DIR) && ./build_all.sh --clean

clean: clean-nemu clean-supervisor
