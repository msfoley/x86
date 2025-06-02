%ifndef BOOTLOADER_ASM_INC
%define BOOTLOADER_ASM_INC

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
%endif

%endif
