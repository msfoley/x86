MEMORY {
    STACK (rw): ORIGIN = 0x00000500, LENGTH = 0x00007700
    STAGE1 (rwx): ORIGIN = 0x00007C00, LENGTH = 0x000001B8
    MBR_FOOTER (r): ORIGIN = 0x00007DB8, LENGTH = 0x00000048
    STAGE1_DATA (rw): ORIGIN = 0x00007E00, LENGTH = 0x00008200
}

SECTIONS {
    .text :
    {
        *(.text*)
    } > STAGE1

    .mbr_footer :
    {
        *(.mbr_footer*)
    } > MBR_FOOTER

    .bss :
    {
        *(.bss*)
    } > STAGE1_DATA

    _stack_top = ORIGIN(STACK) + LENGTH(STACK);
}
