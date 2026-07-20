RM	:= rm -f
ifeq ($(OS),Windows_NT)
# Windows Host
GCCPREFIX	?= 
else
GCCPREFIX	?= loongarch32r-linux-gnusf-
endif
LD	:= $(GCCPREFIX)ld
CC	:= $(GCCPREFIX)gcc
OBJCOPY	:= $(GCCPREFIX)objcopy
OBJDUMP	:= $(GCCPREFIX)objdump
PYTHON	?= python3
OBJDIR	:= obj
INCLUDE	:= include
SRCDIR	:= kern
LDSCRIPT	:= kern/kernel.ld
SDKDIR	:= ../../../..
MIF_CONVERTER	:= ../utility/bin_to_mem.py
SRC	:= $(foreach sdir, $(SRCDIR), $(wildcard $(sdir)/*.S))
OBJ	:= $(patsubst $(SRCDIR)/%.S, $(OBJDIR)/%.o, $(SRC))
DEP	:= $(OBJ:.o=.d)
TARGET	:= kernel.elf
ASFLAG	:= -nostdinc -nostdlib -fno-builtin -mabi=ilp32s -g -fdebug-prefix-map=$(CURDIR)=.
CACHE_MODE ?= auto

override ON_FPGA ?= y
ifeq ($(ON_FPGA), y)
	MACH_DEF = -DMACH_FPGA
else
   	MACH_DEF = -DMACH_QEMU
endif
ASFLAG += $(MACH_DEF)
ifeq ($(CACHE_MODE), uncache)
	ASFLAG += -DSUPERVISOR_FORCE_UNCACHE
endif
CONFIG_FILE := .config_$(ON_FPGA)_$(CACHE_MODE)

.PHONY: all uncache install install-uncache clean checkdirs show-utest

all: $(TARGET) kernel.bin kernel.s axi_ram.mif show-utest

uncache:
	$(MAKE) CACHE_MODE=uncache all

install: all
	cp axi_ram.mif $(SDKDIR)/axi_ram.mif

install-uncache:
	$(MAKE) CACHE_MODE=uncache install

$(CONFIG_FILE):
	@rm -f .config_*
	touch $@

$(TARGET): $(OBJ) $(LDSCRIPT) | $(OBJDIR)
	$(LD) $(OBJ) -T$(LDSCRIPT) -o $@

$(OBJ): $(OBJDIR)/%.o : $(SRCDIR)/%.S $(CONFIG_FILE) | $(OBJDIR)
	$(CC) -o $@ $< -c -I$(INCLUDE) $(ASFLAG) -MMD -MP -MF $(@:.o=.d)

checkdirs: $(OBJDIR)

$(OBJDIR):
	test -d $@ || mkdir $@

kernel.bin: $(TARGET)
	@$(OBJCOPY) -j .text -j .rodata -j .got -O binary $< $@

kernel.s: $(TARGET)
	$(OBJDUMP) -d -S -l $< > $@

axi_ram.mif: kernel.bin $(MIF_CONVERTER)
	$(PYTHON) $(MIF_CONVERTER) $< $@

show-utest: $(TARGET)
	@$(OBJDUMP) -D $< | grep "^[0-9a-f]\{8\} <UTEST_" | grep -n --color=auto 'UTEST_'

clean:
	-$(RM) -r $(OBJDIR)
	-$(RM) $(TARGET) kernel.bin kernel.s axi_ram.coe axi_ram.mif rom.vlog .config_*

-include $(DEP)
