%ifndef BOOTLOADER_ASM_INC
%define BOOTLOADER_ASM_INC

struc _tss
    .link: resb 4
    .esp0: resb 4
    .ss0: resb 4
    .esp1: resb 4
    .ss1: resb 4
    .esp2: resb 4
    .ss2: resb 4
    .cr3: resb 4
    .eip: resb 4
    .eflags: resb 4
    .eax: resb 4
    .ecx: resb 4
    .edx: resb 4
    .ebx: resb 4
    .esp: resb 4
    .ebp: resb 4
    .esi: resb 4
    .edi: resb 4
    .es: resb 4
    .cs: resb 4
    .ss: resb 4
    .ds: resb 4
    .fs: resb 4
    .gs: resb 4
    .ldtr: resb 4
    .res: resb 2
    .iopb: resb 2
    .ssp: resb 4
endstruc

struc _gdt
    .null: resb 8
    .code: resb 8
    .data: resb 8
    .tss: resb 8
endstruc

struc _bios_data
    .com1: resb 1
    .com2: resb 1
    .com3: resb 1
    .com4: resb 1
    .ebda: resb 2
    .hw_flags: resb 2
    .data_before_ebda: resb 2
    .kb_state: resb 2
    .kb_buffer: resb 32
    .display_mode: resb 1
    .text_columns: resb 2
    .video_io_port: resb 2
    .boot_timer: resb 2
    .disk_count: resb 1
    .kb_buffer_start: resb 2
    .kb_buffer_end: resb 2
    .kb_last_state: resb 1
endstruc

struc _memory_map_entry
    .base_addr: resb 8
    .length: resb 8
    .type: resb 4
    .acpi_flags: resb 4
endstruc
_memory_map_entry_type_normal equ 1
_memory_map_entry_type_reserved equ 2 
_memory_map_entry_type_acpi_reclaimable equ 3
_memory_map_entry_type_acpi_nvs equ 4
_memory_map_entry_type_bad_memory equ 5

_memory_map_entry_acpi_flags_valid equ 1
_memory_map_entry_acpi_flags_nonvol equ 2

struc _memory_map
    .length: resb 4
    .reserved: resb 12
    .map: resb _memory_map_entry_size * 20
endstruc

%ifndef BOOTLOADER_ASM_INC_NO_EXTERN
extern start32
extern memory_map
extern bios_data
extern mbr_backup
%endif

%endif
