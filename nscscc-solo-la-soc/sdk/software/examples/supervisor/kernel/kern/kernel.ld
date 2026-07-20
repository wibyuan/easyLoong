ENTRY(INITLOCATE)
OUTPUT("kernel.elf")
OUTPUT_ARCH(loongarch)

PROVIDE(SerialData = 0xbf000000);
PROVIDE(SerialStat = 0xbf000005);

/* Qemu serial constants */


PROVIDE(KERNEL_STACK_INIT = 0x1c800000);
PROVIDE(USER_STACK_INIT = 0x1c7F0000);
SECTIONS
{
    . = 0x1c000000;
    .text : {
        *(.text.init)
        . = ALIGN(0x1000);
        *(.text)
        . = ALIGN(0x1000); /* "fixed" utest address */
        *(.text.utest)
    }
    .rodata : {
        *(.rodata*)
    }
    .got : {
        *(.got)
        *(.got.*)
    }

    . = 0x1c7F0000;
    .bss : {
        _sbss = .;         /* define a global symbol at bss start */
        *(.bss.uregs)
        *(.bss)
        *(.bss.ptes)
        . = ALIGN(4);
        _ebss = .;         /* define a global symbol at bss end */
    }
    PROVIDE(uregs_sp = uregs + 2 * 4);
    PROVIDE(uregs_fp = uregs + 21 * 4);
}
