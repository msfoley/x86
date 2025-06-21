%include "stage2/bootloader.asm.inc"
%include "stage2/interrupt.asm.inc"
%include "stage2/disk.asm.inc"

extern start_32
extern _text_start
extern _reloc_length

section .entry

bits 16

global _start
_start:
    push di
.copy_active_part:
    xor ax, ax
    mov ds, ax
    mov ax, 0x7000
    mov es, ax
    mov cx, _boot_partition_size / 2
    mov eax, boot_partition
    mov di, ax
    repe movsw
.copy_memory_map:
    pop si
    mov eax, memory_map
    mov di, ax
    mov cx, _memory_map_size / 2
    repe movsw
.copy_mbr:
    mov si, 0x7C00
    mov eax, mbr_backup
    mov di, ax
    mov cx, 512 / 2
    repe movsw
.relocate:
    mov ax, 0x1000
    mov ds, ax
    mov ax, 0x0050
    mov es, ax
    xor di, di
    xor si, si
    mov cx, _reloc_length
    add cx, 1
    shr cx, 1
    repe movsw

    pop si
    xor ax, ax
    mov ds, ax
    mov es, ax
    jmp 0:.reloc_jump
.reloc_jump:
    mov di, gdtr
    lgdt [ds:di]

    mov eax, cr0
    or al, 0x01
    mov cr0, eax
    jmp _gdt.code:.32
bits 32
.32:
    mov ax, _gdt.data
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    jmp _gdt.code:start_32

section .data

initial_gdtr:
    dw _gdt_size
    dd 0x10000 + gdt - 0x500

global gdtr
gdtr:
    dw _gdt_size
    dd gdt

global gdt
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
    db 0x9B ; Access Byte
    db 0xCF ; 3:0 Flags ; 19:16 Limit
    db 0x00 ; 31:24 Base
    ; Data descriptor
    dw 0xFFFF ; 15:0 Limit
    dw 0x0000 ; 15:0 Base
    db 0x00 ; 23:16 Base
    db 0x93 ; Access Byte
    db 0xCF ; 3:0 Flags ; 19:16 Limit
    db 0x00 ; 31:24 Base
    ; TSS descriptor
    dw _tss_size - 1
    dw tss
    db 0x00
    db 0x89
    db 0x40
    db 0x00
