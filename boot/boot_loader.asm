bits 32

section .text

_start:
    jmp start

start:
    lgdt [gdtr]
    jmp $
    ; Do a reset if we ever get here
    jmp 0xFFFF:0x0000

section .data

gdtr:
    dw (8 * 3)
    dd gdt
gdt:
    ; Null descriptor
    dw 0x0000 ; 15:0 Limit
    dw 0x0000 ; 15:0 Base
    db 0x00 ; 23:16 Base
    db 0x00 ; Access Byte
    db 0x00 ; 3:0 Flags ; 19:16 Flags
    db 0x00 ; 31:24 Base
    ; Code descriptor
    dw 0xFFFF ; 15:0 Limit
    dw 0x0000 ; 15:0 Base
    db 0x00 ; 23:16 Base
    db 0x9A ; Access Byte
    db 0xCF ; 3:0 Flags ; 19:16 Limit
    db 0x00 ; 31:24 Base
    ; Data descriptor
    dw 0xFFFF ; 15:0 Limit
    dw 0x0000 ; 15:0 Base
    db 0x00 ; 23:16 Base
    db 0x92 ; Access Byte
    db 0xCF ; 3:0 Flags ; 19:16 Limit
    db 0x00 ; 31:24 Base

section .bss

drive_num: resb 1
heads_per_cylinder: resb 2
sectors_per_track: resb 2
