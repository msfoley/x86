bits 32

%define BOOTLOADER_ASM_INC_NO_EXTERN
%include "stage2/bootloader.asm.inc"
%include "stage2/print.asm.inc"
%include "stage2/disk.asm.inc"
%include "stage2/pci.asm.inc"

extern _bss_start
extern _bss_length
extern _stack_top

section .entry

global start_32
start_32:
    xor eax, eax
    mov edi, _bss_start
    mov ecx, _bss_length
    shr ecx, 2
    repe stosd

.far_jump:
    jmp 0x08:stage2

section .text

stage2:
    cli

    mov esp, _stack_top
    mov ebp, esp    

    ; Setup video vars
    mov byte [print_col], 0
    mov byte [print_line], 0

    call clear_screen
    ; print message saying we're in stage 2
    push color_norm
    push .ident
    call print_str
    add esp, 8

    call print_active_partition

    push memory_map
    call print_memory_map
    add esp, 4

    call pci_init
    call pci_print_device_list

    call ahci_init
    cmp eax, 0
    jne reset

    call reset
.ident: db `Stage2 Bootloader\n`, 0

reset:
    hlt
    jmp $
    ; Do a reset if we ever get here
    jmp 0xFFFF:0x0000

print_active_partition:
    push ebp
    mov ebp, esp

    test byte [boot_partition + _boot_partition.attrs], 0x80
    jnz .valid_part

.invalid_part:
    push color_err
    push .active_partition_error
    call print_str
    add esp, 8
    call reset
.valid_part:
    push dword [boot_partition + _boot_partition.lba_start]
    push number_string
    call itoa
    add esp, 8

    push color_norm
    push .active_partition
    call print_str
    add esp, 4
    push number_string
    call print_str
    add esp, 8
    call print_newline

    pop ebp
    ret
.active_partition: db `Active partition start sector: `, 0
.active_partition_error: db `No active partition found\n`, 0

print_memory_map: ; void print_memory_map(struct _memory_map *map)
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
    push dword [edi + _memory_map_entry.base_addr + 4]
    push dword [edi + _memory_map_entry.base_addr]
    push number_string
    call itoa64
    add esp, 12
    push color_norm
    push number_string
    call print_str
    add esp, 8
    call print_space

    ; print 64-bit length
    push dword [edi + _memory_map_entry.length + 4]
    push dword [edi + _memory_map_entry.length]
    push number_string
    call itoa64
    add esp, 12
    push color_norm
    push number_string
    call print_str
    add esp, 8
    call print_space

    ; print type
    push dword [edi + _memory_map_entry.type]
    push number_string
    call itoa
    add esp, 8
    push color_norm
    push number_string
    call print_str
    add esp, 8
    call print_space
    
    ; print ACPI Flags
    push dword [edi + _memory_map_entry.acpi_flags]
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

section .mbr nobits

global mbr_backup
mbr_backup: resb 512

section .stage1_copy nobits

global memory_map
memory_map: resb _memory_map_size

section .bios_data nobits

global bios_data
bios_data: resb _bios_data.kb_last_state + 1 
