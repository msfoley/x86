MEMORY {
    STACK (rw): ORIGIN = 0x00000500, LENGTH = 0x00007700
    STAGE1 (rwx): ORIGIN = 0x00007C00, LENGTH = 0x00000200
    STAGE1_DATA (rw): ORIGIN = 0x00007E00, LENGTH = 0x00008200
    STAGE2 (rwx): ORIGIN = 0x00010000, LENGTH = 0x00070000
}

SECTIONS {
    .text :
    {
        *(.text*)
    } > STAGE1

    .bss :
    {
        *(.bss*)
    } > STAGE1_DATA

    _stack_top = ORIGIN(STACK) + LENGTH(STACK);
}
