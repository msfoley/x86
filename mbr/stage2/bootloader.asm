bits 32

%define BOOTLOADER_ASM_INC_NO_EXTERN
%include "stage2/bootloader.asm.inc"
%include "stage2/print.asm.inc"
%include "stage2/strings.asm.inc"
%include "stage2/disk.asm.inc"
%include "stage2/pci.asm.inc"

extern _bss_start
extern _bss_end
extern _stack_top

section .entry

global _start
_start:
    jmp stage2

section .text

stage2:
    cli
    mov esp, _stack_top
    
    ; Get the address of the memory map
    and edi, 0xFFFF
    push edi
    ; Boot sector passes drive num in dl
    and edx, 0xFF
    push edx
    ; Get the address of the active partition and save it for later
    and esi, 0xFFFF
    push esi

.start_guard:
    ; Safeguard against return oopsies
    push .start_guard
    ; Save these forever
    mov ebp, esp

    mov eax, _bss_start
.bss_zero:
    mov dword [eax], 0x00000000
    add eax, 4
    cmp eax, _bss_end
    jl .bss_zero

    ; Setup video vars
    mov byte [print_col], 0
    mov byte [print_line], 0

    call clear_screen
    ; print message saying we're in stage 2
    push color_norm
    push strings.ident
    call print_str
    add esp, 8

    mov eax, [ebp + 4]
    push eax
    push boot_partition
    call copy_active_partition
    add esp, 8

    mov eax, [ebp + 12]
    push eax
    push memory_map
    call copy_memory_map
    add esp, 8

    push memory_map
    call print_memory_map
    add esp, 4

    call pci_init
    call pci_print_device_list

reset:
    hlt
    jmp $
    ; Do a reset if we ever get here
    jmp 0xFFFF:0x0000

copy_active_partition:
    push ebp
    mov ebp, esp
    push esi

    mov edi, dword [ebp + 8]
    mov esi, dword [ebp + 12]
    cmp esi, 0
    jnz .valid_part

    push color_err
    push strings.active_partition_error
    call print_str
    add esp, 8
    call reset
.valid_part:
    mov eax, dword [esi]
    mov dword [edi], eax
    mov eax, dword [esi + 4]
    mov dword [edi + 4], eax
    mov eax, dword [esi + 8]
    mov dword [edi + 8], eax
    mov eax, dword [esi + 12]
    mov dword [edi + 12], eax

    mov eax, dword [edi + 8]
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

copy_memory_map: ; void copy_memory_map(struct _memory_map *dst, struct _memory_map *src)
    push ebp
    mov ebp, esp
    push edi
    push esi

    mov edi, dword [ebp + 8]
    mov esi, dword [ebp + 12]
    xor ecx, ecx
.copy:
    cmp ecx, _memory_map_size
    jg .done
    mov eax, dword [esi + ecx]
    mov dword [edi + ecx], eax
    add ecx, 4
    jmp .copy
.done:
    mov eax, dword [edi + _memory_map.length]
    cmp eax, 20
    jl .exit
    mov eax, 20
    mov dword [edi + _memory_map.length], eax
.exit:
    pop esi
    pop edi
    pop ebp
    ret

print_memory_map: ; void copy_memory_map(struct _memory_map *map)
    push ebp
    mov ebp, esp
    push esi
    push edi

    push color_norm
    push .header
    call print_str
    add esp, 8

    mov esi, dword [ebp + 8]
    mov ecx, dword [esi + _memory_map.length]
    add esi, _memory_map.map

.loop:
    mov eax, dword [esi - _memory_map.map]
    sub eax, ecx
    mov edx, _memory_map_entry_size
    mul edx
    lea edi, dword [eax + esi]
    push ecx

    ; print 64-bit base addr
    mov eax, dword [edi + _memory_map_entry.base_addr + 4]
    push eax
    mov eax, dword [edi + _memory_map_entry.base_addr]
    push eax
    push number_string
    call itoa64
    add esp, 12
    push color_norm
    push number_string
    call print_str
    add esp, 8
    call print_space

    ; print 64-bit length
    mov eax, dword [edi + _memory_map_entry.length + 4]
    push eax
    mov eax, dword [edi + _memory_map_entry.length]
    push eax
    push number_string
    call itoa64
    add esp, 12
    push color_norm
    push number_string
    call print_str
    add esp, 8
    call print_space

    ; print type
    mov eax, dword [edi + _memory_map_entry.type]
    push eax
    push number_string
    call itoa
    add esp, 8
    push color_norm
    push number_string
    call print_str
    add esp, 8
    call print_space
    
    ; print ACPI Flags
    mov eax, dword [edi + _memory_map_entry.acpi_flags]
    push eax
    push number_string
    call itoa
    add esp, 8
    push color_norm
    push number_string
    call print_str
    add esp, 8
    call print_newline
.check_done:
    pop ecx
    sub ecx, 1
    cmp ecx, 0
    je .exit
    jmp .loop

.exit:
    pop edi
    pop esi
    pop ebp
    ret
.header: db `Memory map:\n`, 0

section .bios_data nobits

global bios_data
bios_data: resb _bios_data.kb_last_state + 1 
