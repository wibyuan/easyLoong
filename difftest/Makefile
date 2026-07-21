NEMU_HOME := $(CURDIR)/../la32r-nemu/NEMU

.PHONY: build clean

build:
	$(MAKE) -C $(NEMU_HOME) NEMU_HOME=$(NEMU_HOME) la32-reduced-ref_defconfig
	$(MAKE) -C $(NEMU_HOME) NEMU_HOME=$(NEMU_HOME) -j$$(nproc)

clean:
	$(MAKE) -C $(NEMU_HOME) NEMU_HOME=$(NEMU_HOME) clean

ref_so: build
	@echo "Reference .so: $(NEMU_HOME)/build/la32r-nemu-interpreter-so"
