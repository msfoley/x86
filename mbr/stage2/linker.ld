MEMORY {
    BIOS_DATA (r): ORIGIN = 0x00000400, LENGTH = 0x00000100
    STAGE2 (rx): ORIGIN = 0x00000500, LENGTH = 0x00010000
    STAGE2_DATA (r): ORIGIN = 0x00010500, LENGTH = 0x0006F500
    MBR (rw): ORIGIN = 0x0007FA00, LENGTH = 0x00000200
    STAGE1_COPY (rw): ORIGIN = 0x0007FC00, LENGTH = 0x00000400
    KERNEL (rwx): ORIGIN = 0x00100000, LENGTH = 0x00E00000
}

ENTRY(_start)

SECTIONS {
    .text :
    {
        _text_start = .;
        *(.entry*)
        *(.text*)
        _text_end = .;
    } > STAGE2
    _text_length = _text_end - _text_start;

    .data :
    {
        _data_start = .;
        *(.data*)
        . = ALIGN(512);
        _data_end = .;
    } > STAGE2
    _data_length = _data_end - _data_start;
    _reloc_length = _data_end - _text_start;

    .mbr (NOLOAD):
    {
    } > MBR
    .stage1_copy (NOLOAD):
    {
        _stage1_copy_start = .;
        *(.stage1_copy*)
    } > STAGE1_COPY

    .bss :
    {
        . = ALIGN(4);
        _bss_start = .;
        *(.bss*)
        . = ALIGN(4);
        _bss_end = .;
    } > STAGE2_DATA
    _bss_length = _bss_end - _bss_start;
    _stack_top = ORIGIN(STAGE2_DATA) + LENGTH(STAGE2_DATA);

    .bios_data (NOLOAD) :
    {
        *(.bios_data*)
    } > BIOS_DATA
}
