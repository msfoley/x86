%ifndef DISK_ASM_INC
%define DISK_ASM_INC

struc mbr_part
    .attr: resb 1
    .chs_start: resb 3
    .type: resb 1
    .chs_last: resb 3
    .lba_start: resb 4
    .sector_count: resb 4
endstruc

struc ahci_mem
    .cap: resb 4
    .ghc: resb 4
    .is: resb 4
    .pi: resb 4
    .vs: resb 4
    .ccc_ctl: resb 4
    .ccc_pts: resb 4
    .em_loc: resb 4
    .em_ctl: resb 4
    .cap2: resb 4
    .bohc: resb 4
    .reserved: resb 0xA0 - .reserved
    .vendor: resb 0x100 - .vendor
    .ports: resb 0x100
endstruc

struc ahci_port
    .clb: resb 4
    .clbu: resb 4
    .fb: resb 4
    .dbu: resb 4
    .is: resb 4
    .ie: resb 4
    .cmd: resb 4
    .reserved0: resb 4
    .tfd: resb 4
    .sig: resb 4
    .ssts: resb 4
    .sctl: resb 4
    .serr: resb 4
    .sact: resb 4
    .ci: resb 4
    .sntf: resb 4
    .fbs: resb 4
    .reserved1: resb 44
    .vendor: resb 16
endstruc

struc ahci_fis
    .dma_setup: resb 28
    .pad0: resb 4
    .pio_setup: resb 20
    .pad1: resb 12
    .reg_d2h: resb 20
    .pad2: resb 4
    .set_device_bit: resb 2
    .unknown: resb 64
    .reserved: resb 0x100 - 0xA0
endstruc

struc ahci_fis_reg_h2d
    ; DWORD 0
    .fis_type: resb 1
    .pmport_c: resb 1
    .command: resb 1
    .featurel: resb 1
    ; DWORD 1
    .lba_low: resb 3
    .device: resb 1
    ; DWORD 2
    .lba_high: resb 3
    .featureh: resb 1
    ; DWORD 3
    .count: resb 2
    .icc: resb 1
    .control: resb 1
    ; DWORD 4
    .reserved: resb 4
endstruc
struc ahci_fis_reg_d2h
    ; DWORD 0
    .fis_type: resb 1
    .pmport_i: resb 1
    .status: resb 1
    .error: resb 1
    ; DWORD 1
    .lba_low: resb 3
    .device: resb 1
    ; DWORD 2
    .lba_high: resb 3
    .reserved1: resb 1
    ; DWORD 3
    .count: resb 2
    .reserved2: resb 2
    ; DWORD 4
    .reserved3: resb 4
endstruc
struc ahci_fis_data
    ; DWORD 0
    .fis_type: resb 1
    .pmport: resb 1
    .reserved1: resb 2
    ; 1 - N DWORDs of data
endstruc
struc ahci_fis_pio_setup
    ; DWORD 0
    .fis_type: resb 1
    .pmport_d_i: resb 1
    .status: resb 1
    .error: resb 1
    ; DWORD 1
    .lba_low: resb 3
    .device: resb 1
    ; DWORD 2
    .lba_high: resb 3
    .reserved1: resb 1
    ; DWORD 3
    .count: resb 2
    .reserved2: resb 1
    .e_status: resb 1
    ; DWORD 4
    .tc: resb 2
    .reserved3: resb 2
endstruc
ahci_fis_pmport equ 0x0F
ahci_fis_c equ 0x10
ahci_fis_i equ 0x20
ahci_fis_d equ 0x40

struc ahci_command_header
    .flags: resb 2
    .prdtl: resb 2
    .prdbc: resb 4
    .ctba: resb 4
    .ctbau: resb 4
    .reserved: resb 16
endstruc
ahci_command_header_flag_cfl equ 0x001F
ahci_command_header_flag_a equ 0x0020
ahci_command_header_flag_w equ 0x0040
ahci_command_header_flag_p equ 0x0080
ahci_command_header_flag_r equ 0x0100
ahci_command_header_flag_b equ 0x0200
ahci_command_header_flag_c equ 0x0400
ahci_command_header_flag_res equ 0x0800
ahci_command_header_flag_pmp equ 0xF000

struc ahci_command_table
    .cfis: resb 64
    .acmd: resb 16
    .reserved: resb 48
    ; prdt entries after
endstruc

struc ahci_prdt_entry
    .dba: resb 4
    .dbau: resb 4
    .reserved1: resb 4
    .dbc_i: resb 4
endstruc
ahci_prdt_entry_dbc equ 0x003FFFFF
ahci_prdt_entry_i equ 0x80000000

common boot_partition 16

%endif
