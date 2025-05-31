MEMORY {
    BIOS_DATA (r): ORIGIN = 0x00000400, LENGTH = 0x00000100
    STACK (rw): ORIGIN = 0x00000500, LENGTH = 0x00007700
    STAGE1 (rwx): ORIGIN = 0x00007C00, LENGTH = 0x00000200
    STAGE1_DATA (rw): ORIGIN = 0x00007E00, LENGTH = 0x00008200
    STAGE2 (rx): ORIGIN = 0x00010000, LENGTH = 0x00010000
    STAGE2_DATA (rw): ORIGIN = 0x00020000, LENGTH = 0x00060000
    KERNEL (rwx): ORIGIN = 0x00100000, LENGTH = 0x00E00000
}

ENTRY(_start)

SECTIONS {
    .text :
    {
        *(.entry*)
        *(.text*)
    } > STAGE2

    .data :
    {
        *(.data*)
        . = ALIGN(512);
    } > STAGE2

    .stage_one (NOLOAD) :
    {
        *(.stage_one*)
    } > STAGE1

    .bss :
    {
        . = ALIGN(4);
        _bss_start = .;
        *(.bss*)
        . = ALIGN(4);
        _bss_end = .;
    } > STAGE2_DATA

    .bios_data (NOLOAD) :
    {
        *(.bios_data*)
    } > BIOS_DATA

    _stack_top = ORIGIN(STACK) + LENGTH(STACK);
}
