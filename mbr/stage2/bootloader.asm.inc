%ifndef BOOTLOADER_ASM_INC
%define BOOTLOADER_ASM_INC

common drive_num 1

struc mbr_part
    .attr: resb 1
    .chs_start: resb 3
    .type: resb 1
    .chs_last: resb 3
    .lba_start: resb 4
    .sector_count: resb 4
endstruc

common boot_partition 16

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

%endif
