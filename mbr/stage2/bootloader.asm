bits 32

%define BOOTLOADER_ASM_INC_NO_EXTERN
%include "stage2/bootloader.asm.inc"
%include "stage2/print.asm.inc"
%include "stage2/strings.asm.inc"

section .bss

; disk stuff

extern _bss_start
extern _bss_end

section .entry

global _start
_start:
    jmp start

section .text

start:
    cli
    mov ebp, esp

    mov eax, _bss_start
.bss_zero:
    mov dword [eax], 0x00000000
    add eax, 4
    cmp eax, _bss_end
    jl .bss_zero

    ; Boot sector passes drive num in dl
    mov byte [drive_num], dl

    ; Setup video vars
    mov byte [print_col], 0
    mov byte [print_line], 0

    call clear_screen
    ; print message saying we're in stage 2
    push color_norm
    push strings.ident
    call print_str
    add esp, 8

    call find_boot_partition

reset:
    hlt
    jmp $
    ; Do a reset if we ever get here
    jmp 0xFFFF:0x0000

find_boot_partition:
    push ebp
    mov ebp, esp
    push esi

    xor eax, eax
    mov esi, mbr.partition1
.loop:
    mov al, byte [esi]
    test al, 0x80
    jnz .part_found
    add esi, 16
    cmp esi, mbr.partition4
    jle .loop
    push color_err
    push strings.active_partition_error
    call print_str
    add esp, 8
    call reset
.part_found:
    mov eax, dword [esi]
    mov dword [boot_partition], eax
    mov eax, dword [esi + 4]
    mov dword [boot_partition + 4], eax
    mov eax, dword [esi + 8]
    mov dword [boot_partition + 8], eax
    mov eax, dword [esi + 12]
    mov dword [boot_partition + 12], eax

    mov eax, dword [boot_partition + 8]
    push eax
    push number_string
    call itoa
    add esp, 8

    push color_norm
    push strings.active_partition
    call print_str
    add esp, 4
    push number_string
    call print_str
    add esp, 4
    push strings.newline
    call print_str
    add esp, 8

    pop esi
    pop ebp
    ret 

section .stage_one nobits

resb (0x1B8 - ($ - $$))
mbr:
.unique_id: resb 4 
.reserved: resb 2
.partition1: resb 16
.partition2: resb 16
.partition3: resb 16
.partition4: resb 16
.signature: resb 2

section .bios_data nobits

bios_data: resb _bios_data.kb_last_state + 1 
