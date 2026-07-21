NSCSCC_DIR     := nscscc-solo-la-soc
SUPERVISOR_DIR := $(NSCSCC_DIR)/sdk/software/examples/supervisor
NEMU_SO        := la32r-nemu/NEMU/build/la32r-nemu-interpreter-so
TOOLCHAIN_BIN  := $(CURDIR)/$(NSCSCC_DIR)/sdk/toolchains/loongson-gnu-toolchain-8.3-x86_64-loongarch32r-linux-gnusf-v2.0/bin

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
        clean clean-nemu clean-supervisor

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

clean-nemu:
	$(MAKE) -C difftest clean

clean-supervisor:
	cd $(SUPERVISOR_DIR) && ./build_all.sh --clean

clean: clean-nemu clean-supervisor
