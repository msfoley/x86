bits 32

section .text

_start:
    jmp start

start:
    jmp $
    ; Do a reset if we ever get here
    jmp 0xFFFF:0x0000

section .bss

drive_num: resb 1
heads_per_cylinder: resb 2
sectors_per_track: resb 2
