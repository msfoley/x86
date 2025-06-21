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

struc _ahci_mem
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

AHCI_GHC_AE equ (1 << 31)
AHCI_GHC_IE equ (1 << 1)
AHCI_GHC_HR equ (1 << 0)

AHCI_CAP2_BOHC equ (1 << 0)

AHCI_BOHC_OOS equ (1 << 1)
AHCI_BOHC_BB equ (1 << 4)

struc _ahci_port
    .clb: resb 4
    .clbu: resb 4
    .fb: resb 4
    .fbu: resb 4
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

AHCI_PxCMD_ICC equ 0xF0000000
AHCI_PxCMD_ICC_ACTIVE equ 0x10000000
AHCI_PxCMD_CR equ 0x8000
AHCI_PxCMD_FR equ 0x4000
AHCI_PxCMD_FRE equ 0x0010
AHCI_PxCMD_POD equ 0x0004
AHCI_PxCMD_SUD equ 0x0002
AHCI_PxCMD_ST equ 0x0001

AHCI_PxTFD_ERR equ 0x01
AHCI_PxTFD_DRQ equ 0x08
AHCI_PxTFD_BSY equ 0x80

AHCI_PxIS_TFES equ 0x40000000

AHCI_PxSCTL_DET equ 0x000F

AHCI_PxIE_HBDF equ 0x20000000
AHCI_PxIE_HBDE equ 0x10000000
AHCI_PxIE_IFE  equ 0x08000000
AHCI_PxIE_INFE equ 0x04000000
AHCI_PxIE_DPS  equ 0x00000020
AHCI_PxIE_DHRE equ 0x00000001
AHCI_PxIE_DEFAULTS equ 0x3C000021

AHCI_PxSSTS_DET equ 0x0000000F
AHCI_PxSSTS_DET_PRESENT_AND_PHY equ 0x00000003
AHCI_PxSSTS_DET_PRESENT equ 0x00000001
AHCI_PxSSTS_DET_NOT_PRESENT equ 0x00000000

struc _ahci_fis
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

AHCI_FIS_TYPE_REG_H2D equ 0x27
AHCI_FIS_TYPE_REG_D2H equ 0x34
AHCI_FIS_TYPE_DMA_ACT equ 0x39
AHCI_FIS_TYPE_DMA_SETUP equ 0x41
AHCI_FIS_TYPE_DATA equ 0x46
AHCI_FIS_TYPE_BIST equ 0x58
AHCI_FIS_TYPE_PIO_SETUP equ 0x5F
AHCI_FIS_TYPE_DEV_BITS equ 0xA1
struc _ahci_fis_reg_h2d
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
struc _ahci_fis_reg_d2h
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
struc _ahci_fis_data
    ; DWORD 0
    .fis_type: resb 1
    .pmport: resb 1
    .reserved1: resb 2
    ; 1 - N DWORDs of data
endstruc
struc _ahci_fis_pio_setup
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
AHCI_FIS_PMPORT equ 0x0F
AHCI_FIS_H2D_C equ 0x80

struc _ahci_command_list
    .flags: resb 2
    .prdtl: resb 2
    .prdbc: resb 4
    .ctba: resb 4
    .ctbau: resb 4
    .reserved: resb 16
endstruc
AHCI_COMMAND_LIST_FLAG_CFL equ 0x001F
AHCI_COMMAND_LIST_FLAG_A equ 0x0020
AHCI_COMMAND_LIST_FLAG_W equ 0x0040
AHCI_COMMAND_LIST_FLAG_P equ 0x0080
AHCI_COMMAND_LIST_FLAG_R equ 0x0100
AHCI_COMMAND_LIST_FLAG_B equ 0x0200
AHCI_COMMAND_LIST_FLAG_C equ 0x0400
AHCI_COMMAND_LIST_FLAG_RES equ 0x0800
AHCI_COMMAND_LIST_FLAG_PMP equ 0xF000

struc _ahci_command_table
    .cfis: resb 64
    .acmd: resb 16
    .reserved: resb 48
    ; prdt entries after
endstruc

struc _ahci_prdt_entry
    .dba: resb 4
    .dbau: resb 4
    .reserved1: resb 4
    .dbc_i: resb 4
endstruc
AHCI_PRDT_ENTRY_DBC equ 0x003FFFFF
AHCI_PRDT_ENTRY_I equ 0x80000000

ATA_CMD_READ_DMA_EX equ 0x25

struc _boot_partition
    .attrs: resb 1
    .chs_start: resb 3
    .type: resb 1
    .chs_last: resb 3
    .lba_start: resb 4
    .sector_count: resb 4
endstruc

%ifndef DISK_ASM_INC_NO_EXTERN
extern boot_partition
extern ahci_init
%endif

%endif
