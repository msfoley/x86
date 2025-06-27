bits 32

%define DISK_ASM_INC_NO_EXTERN
%include "stage2/disk.inc.asm"
%include "stage2/bootloader.inc.asm"
%include "stage2/pci.inc.asm"
%include "stage2/print.inc.asm"
%include "stage2/util.inc.asm"
%include "stage2/interrupt.inc.asm"
%include "stage2/timer.inc.asm"

AHCI_CLASS equ 0x01
AHCI_SUBCLASS equ 0x06
AHCI_PROG_IF equ 0x01

AHCI_CLASS_ATAPI equ 0xEB140101
AHCI_CLASS_SEMB equ 0xC33C0101
AHCI_CLASS_PM equ 0x96690101
AHCI_CLASS_SATA equ 0x00000101

AHCI_PORT_IPM_ACTIVE equ 1
AHCI_PORT_DET_PRESENT equ 3

AHCI_PORT_COUNT equ 32

struc _command_table_entry
    .command_table: resb _ahci_command_table_size
    .prdt: resb _ahci_prdt_entry_size * 8 ; What is a good number here?
endstruc

struc _command_table
    .entries: resb _command_table_entry_size * 32
endstruc

struc _ahci_state
    .mem: resb 4
    .port: resb 4
    .command_list: resb 4
    .command_table: resb 4
    .received_fis: resb 4
endstruc

; %1 = destination register for ahci_state[%3]
; %2 = r/m index
; eax and edx are modified by this macro.
%macro get_ahci_state 2
    mov eax, _ahci_state_size
    mul %2
    lea %1, dword [ahci_state + eax]
%endmacro

section .bss

ahci_pci_device: resb 4
ahci_base: resb 4

global ahci_boot_device_port
ahci_boot_device_port: resb 4

alignb 4
ahci_state: resb _ahci_state_size * AHCI_PORT_COUNT

alignb 4
disk_read_sector: resb 512

alignb 256
received_fis: resb _ahci_fis_size * AHCI_PORT_COUNT

alignb 128
command_table: resb _command_table_size * AHCI_PORT_COUNT

alignb 1024
command_list: resb _ahci_command_list_size * 32 * AHCI_PORT_COUNT

section .text

global ahci_init
ahci_init: ; int ahci_init()
    push ebp
    mov ebp, esp
    push edi

    mov ecx, -1
    xor ecx, ecx
    mov edx, dword [pci_device_list + _pci_device_list.length]
    lea edi, dword [pci_device_list + _pci_device_list.device_list]
    jmp .loop_start

.loop:
    add ecx, 1
    add edi, _pci_device_size
.loop_start:
    cmp ecx, edx
    jge .fail

    mov eax, dword [edi + _pci_device.revision_id]
    shr eax, 8
    cmp al, AHCI_PROG_IF
    jne .loop
    shr eax, 8
    cmp al, AHCI_SUBCLASS
    jne .loop
    shr eax, 8
    cmp al, AHCI_CLASS
    jne .loop
.found:
    push edi
    call ahci_pci_init
    add esp, 4
    call ahci_controller_init

    call ahci_port_find_boot_device
    cmp eax, 0
    je .success
    mov eax, 1
    jmp .exit

.success:
    mov eax, 0
    jmp .exit
.fail:
    push color_norm
    push .no_ahci
    call print_str
    add esp, 8
    mov eax, 1
.exit:
    pop edi
    pop ebp
    ret
.no_ahci: db `No AHCI devices found.\n`, 0

ahci_detect_port: ; int ahci_detect_port(int index)
    push ebp
    mov ebp, esp
    push esi
    push edi

    get_ahci_state esi, dword [ebp + 8]
    mov edi, dword [esi + _ahci_state.port]

    mov eax, dword [edi + _ahci_port.ssts]
    and eax, AHCI_PxSSTS_DET
    cmp eax, AHCI_PxSSTS_DET_PRESENT_AND_PHY
    jne .not_present

    mov eax, dword [edi + _ahci_port.sig]
    cmp eax, AHCI_CLASS_SATA
    je .supported
    ;cmp eax, AHCI_CLASS_ATAPI
    ;je .supported
    ;cmp eax, AHCI_CLASS_SEMB
    ;je .supported
    ;cmp eax, AHCI_CLASS_PM
    ;je .supported
    jmp .not_present
.supported:
    xor eax, eax
    jmp .exit
.not_present:
    mov eax, 1
.exit:
    pop edi
    pop esi
    pop ebp
    ret  

ahci_port_find_boot_device:
    push ebp
    mov ebp, esp
    push edi
    push esi

    push 0
.port_loop:
    get_ahci_state esi, dword [esp]
    lea edi, [esi + _ahci_state.port]

    call ahci_detect_port
    cmp eax, 0
    jnz .port_not_present

    mov ecx, dword [esp]
    ; Get the device's boot sector
    push 0
    push 0
    push disk_read_sector
    push ecx
    call ahci_port_read_sector
    add esp, 16
    cmp eax, 0
    jnz .port_not_present

    ; Compare the device's boot sector with our saved copy
    push 512
    push disk_read_sector
    push mbr_backup
    call memcmp
    add esp, 12
    cmp eax, 0
    jnz .port_not_present

    ; Port found!
    pop ecx
    mov dword [ahci_boot_device_port], ecx
    push color_norm
    push .found_str
    call print_str
    add esp, 8
    xor eax, eax
    jmp .exit

.port_not_present:
    add ecx, 1
    cmp ecx, 32
    jl .port_loop
    add esp, 4
    mov eax, 1

.exit:
    pop esi
    pop edi
    pop ebp
    ret
.port_str1: db "AHCI Port ", 0
.port_str2: db ": ", 0
.port_str3: db " int=", 0
.found_str: db `Boot device found.\n`, 0

ahci_port_init: ; int ahci_port_init(uint32_t port_num)
    push ebp
    mov ebp, esp
    push esi
    push edi

    get_ahci_state esi, dword [ebp + 8]

    push dword [esi + _ahci_state.port]
    call ahci_command_stop
    add esp, 4

    ; clb = command list
    mov edi, dword [esi + _ahci_state.port]
    mov eax, dword [esi + _ahci_state.command_list]
    mov dword [edi + _ahci_port.clb], eax
    mov dword [edi + _ahci_port.clbu], 0

    ; fb = received FIS entry
    mov edi, dword [esi + _ahci_state.port]
    mov eax, dword [esi + _ahci_state.received_fis]
    mov dword [edi + _ahci_port.fb], eax
    mov dword [edi + _ahci_port.fbu], 0

    mov ecx, 0
.init_cmds:
    mov edi, dword [esi + _ahci_state.command_list]
    mov eax, _ahci_command_list_size
    mul ecx
    lea edi, dword [edi + eax]

    mov eax, _command_table_entry_size
    mul ecx
    mov edx, dword [esi + _ahci_state.command_table]
    lea eax, dword [edx + eax]
    
    ; Set command header info
    mov dword [edi + _ahci_command_list.ctba], eax
    add ecx, 1
    cmp ecx, 32
    jl .init_cmds

    mov edi, dword [esi + _ahci_state.port]
    and dword [edi + _ahci_port.serr], 0xFFFFFFFF
    and dword [edi + _ahci_port.is], 0xFFFFFFFF
    mov dword [edi + _ahci_port.ie], AHCI_PxIE_DEFAULTS

    mov eax, dword [edi + _ahci_port.cmd]
    and eax, ~AHCI_PxCMD_ICC
    or eax, AHCI_PxCMD_ICC_ACTIVE | AHCI_PxCMD_POD
    mov dword [edi + _ahci_port.cmd], eax

    ; SUD support
    test dword [edi + _ahci_port.cmd], AHCI_PxCMD_SUD
    jnz .sud_done

    ; Try and spin er up
    and dword [edi + _ahci_port.sctl], ~AHCI_PxSCTL_DET
    or dword [edi + _ahci_port.cmd], AHCI_PxCMD_SUD

    ; Delay a little bit to let the port get ready
    push 50
    call timer_delay
    add esp, 4

.sud_done:
    push edi
    call ahci_command_start
    add esp, 4

    ; Wait for initial FIS to complete?
.wait_busy:
    test dword [edi + _ahci_port.tfd], AHCI_PxTFD_BSY
    jnz .wait_busy

    xor eax, eax ; function always succeeds
    pop edi
    pop esi
    pop ebp
    ret

ahci_command_start: ; void ahci_command_start(struct ahci_port *port)
    push ebp
    mov ebp, esp
    push esi

    mov esi, dword [ebp + 8] ; port ptr
    lea esi, [esi + _ahci_port.cmd]

.cr_clear:
    mov eax, dword [esi]
    test eax, AHCI_PxCMD_CR
    jnz .cr_clear

    or eax, AHCI_PxCMD_FRE
    or eax, AHCI_PxCMD_ST
    mov dword [esi], eax

    pop esi
    pop ebp
    ret

ahci_command_stop: ; void ahci_command_stop(struct _ahci_port *port)
    push ebp
    mov ebp, esp
    push esi

    mov esi, dword [ebp + 8]
    lea esi, dword [esi + _ahci_port.cmd]

    mov eax, dword [esi]
    and eax, ~AHCI_PxCMD_ST
    and eax, ~AHCI_PxCMD_FRE
    mov dword [esi], eax

.fr_cr_clear:
    mov eax, dword [esi]
    test eax, AHCI_PxCMD_FR
    jnz .fr_cr_clear
    test eax, AHCI_PxCMD_CR
    jnz .fr_cr_clear

    pop esi
    pop ebp
    ret

global ahci_port_read_sector
ahci_port_read_sector: ; int ahci_port_init(uint32_t port_num, uint8_t *buf, uint32_t lba_low, uint32_t lba_high)
    push ebp
    mov ebp, esp
    push edi
    push esi

    get_ahci_state esi, dword [ebp + 8]

    mov edi, dword [esi + _ahci_state.port]
.start_busy_loop:
    test dword [edi + _ahci_port.ci], 0x01
    jnz .start_busy_loop

    ; Zero out command table
    push _command_table_entry_size + _ahci_prdt_entry_size * 1
    push 0
    push dword [esi + _ahci_state.command_table]
    call memset
    add esp, 12

    ; Setup PRDT
    mov edi, dword [esi + _ahci_state.command_table]
    mov eax, dword [ebp + 12]
    mov dword [edi + _command_table_entry.prdt + _ahci_prdt_entry.dba], eax
    mov eax, 511
    or eax, AHCI_PRDT_ENTRY_I
    mov dword [edi + _command_table_entry.prdt + _ahci_prdt_entry.dbc_i], eax

    ; Setup command list
    mov edi, dword [esi + _ahci_state.command_list]
    mov ax, _ahci_fis_reg_h2d_size / 4
    and ax, AHCI_COMMAND_LIST_FLAG_CFL
    ;or ax, AHCI_COMMAND_LIST_FLAG_C
    mov word [edi + _ahci_command_list.flags], ax
    mov word [edi + _ahci_command_list.prdtl], 1
    mov dword [edi + _ahci_command_list.prdbc], 0

    ; Setup command
    mov edi, dword [esi + _ahci_state.command_table]
    add edi, _ahci_command_table.cfis
    ; fs->fis_type = REG_H2D
    mov byte [edi + _ahci_fis_reg_h2d.fis_type], AHCI_FIS_TYPE_REG_H2D
    ; fis->c = 1;
    mov al, AHCI_FIS_H2D_C
    mov byte [edi + _ahci_fis_reg_h2d.pmport_c], al
    ; fis->command = ATA_CMD_READ_DMA_EX
    mov byte [edi + _ahci_fis_reg_h2d.command], ATA_CMD_READ_DMA_EX
    ; fs->lba_low = lba & 0x00FFFFFF
    ; fs->device = LBA ??
    ; Overwrites fis->device with the MSB of lba, but we're about to set it anyhow
    mov eax, dword [ebp + 16]
    and eax, 0x00FFFFFF
    or eax, 64 << 24
    mov dword [edi + _ahci_fis_reg_h2d.lba_low], eax
    ; fs->lba_high = (lba & 0xFF000000) >> 24
    mov eax, dword [ebp + 16]
    shr eax, 24
    mov byte [edi + _ahci_fis_reg_h2d.lba_high], al
    mov eax, dword [ebp + 20]
    mov word [edi + _ahci_fis_reg_h2d.lba_high + 1], ax
    ; fs->count = 1
    mov word [edi + _ahci_fis_reg_h2d.count], 1

    mov edi, dword [esi + _ahci_state.port]
.ready_loop:
    mov eax, dword [edi + _ahci_port.tfd]
    test eax, AHCI_PxTFD_DRQ
    jnz .ready_loop
    test eax, AHCI_PxTFD_BSY
    jnz .ready_loop

    mov eax, dword [edi + _ahci_port.ci]
    or eax, 0x01
    mov dword [edi + _ahci_port.ci], eax
.done_loop:
    mov eax, dword [edi + _ahci_port.is]
    mov eax, dword [edi + _ahci_port.ci]
    test eax, 0x01
    jnz .done_loop

    mov eax, dword [esi + _ahci_port.is]
    test eax, AHCI_PxIS_TFES
    jnz .fail

    xor eax, eax
.done:
    pop esi
    pop edi
    pop ebp
    ret
.fail:
    mov eax, 1
    jmp .done

ahci_setup_interrupt: ; void ahci_setup_interrupt(uint8_t interrupt_line)
    push ebp
    mov ebp, esp

    push IDT_INTERRUPT_GATE
    push ahci_isr
    mov eax, dword [ebp + 8]
    add eax, INTERRUPT_PIC_1
    push eax
    call interrupt_register
    add esp, 12

    mov eax, dword [ebp + 8]
    push eax
    call pic_unmask
    add esp, 4

    pop ebp
    ret

ahci_pci_init: ; int ahci_pci_init(struct pci_device *pci_device)
    push ebp
    mov ebp, esp
    push edi

    mov edi, dword [ebp + 8]
    mov dword [ahci_pci_device], edi

    ; Setup stack for repeated PCI calls
    push 0 ; value (writes only)
    push 0 ; offset
    push dword [edi + _pci_device.func]
    push dword [edi + _pci_device.slot]
    push dword [edi + _pci_device.bus]

    ; Get AHCI base memory pointer
    mov dword [esp + 12], _pci_header_type_0.bar5
    call pci_read_dword
    mov dword [ahci_base], eax

    ; Set necessary PCI flags
    mov dword [esp + 12], _pci_header_type_0.command
    call pci_read_dword
    and eax, ~(1 << 10) ; Enable PCI interrupts
    or eax, (1 << 2) ; Enable DMA
    or eax, (1 << 1) ; Enable memory map
    mov dword [esp + 16], eax
    call pci_write_dword

    ; Get PIC IRQ and then enable that line
    mov dword [esp + 12], _pci_header_type_0.interrupt_line
    call pci_read_byte
    push eax
    call ahci_setup_interrupt
    add esp, 4

.done:
    xor eax, eax
    jmp .exit
.fail:
    mov eax, 1
.exit:
    add esp, 20
    pop edi
    pop ebp
    ret

ahci_controller_init: ; int ahci_controller_init()
    push ebp
    mov ebp, esp
    push esi
    push edi

    mov edi, dword [ahci_base]

    ; BIOS handoff
    test dword [edi + _ahci_mem.cap2], AHCI_CAP2_BOHC ; Check if BIOS handoff is supported
    jz .reset_controller
    test dword [edi + _ahci_mem.bohc], AHCI_BOHC_OOS
    jnz .reset_controller
    or dword [edi + _ahci_mem.bohc], AHCI_BOHC_OOS
.bios_handoff_spin_init:
    push 0
.bios_handoff_spin:
    push 50
    call timer_delay
    add esp, 4
    test dword [edi + _ahci_mem.bohc], AHCI_BOHC_BB
    jnz .bios_handoff_spin_init

    ; Reset AHCI controller
.reset_controller:
    or dword [edi + _ahci_mem.ghc], AHCI_GHC_HR
.reset_loop:
    test dword [edi + _ahci_mem.ghc], AHCI_GHC_HR
    jnz .reset_loop

    ; Enable AHCI mode
    or dword [edi + _ahci_mem.ghc], AHCI_GHC_AE

    ; Enable interrupts
    or dword [edi + _ahci_mem.ghc], AHCI_GHC_IE

    ; Init each port    
    push 0
.port_init_loop:
    ; Setup ahci_state[ctr]
    mov ecx, dword [esp]
    get_ahci_state esi, ecx

    mov dword [esi + _ahci_state.mem], edi

    mov eax, _ahci_port_size
    mul ecx
    lea eax, dword [edi + _ahci_mem.ports + eax]
    mov dword [esi + _ahci_state.port], eax

    mov eax, _ahci_command_list_size * 32
    mul ecx
    lea eax, dword [command_list + eax]
    mov dword [esi + _ahci_state.command_list], eax

    mov eax, _ahci_command_table_size
    mul ecx
    lea eax, dword [command_table + eax]
    mov dword [esi + _ahci_state.command_table], eax

    mov eax, _ahci_fis_size
    mul ecx
    lea eax, dword [received_fis + eax]
    mov dword [esi + _ahci_state.received_fis], eax

    ; Test if port is actually implemented
    mov ecx, dword [esp]
    mov eax, 1
    shl eax, cl
    test [edi + _ahci_mem.pi], eax
    jz .port_skip
    ; Initialize the port for reading
    call ahci_port_init
.port_skip:
    add dword [esp], 1
    cmp dword [esp], 32
    jl .port_init_loop
.port_init_done:
    add esp, 4

    pop edi
    pop esi
    pop ebp
    ret

ahci_isr:
    pushad

    mov esi, dword [ahci_base]

    push 0
.port_loop:
    mov cl, byte [esp]
    mov eax, 1
    shl eax, cl
    test dword [esi + _ahci_mem.is], eax
    jz .next_port

    ; Interrupt is for this port. Let's find out what it is.
    mov edx, dword [esp]
    mov eax, _ahci_port_size
    mul edx
    lea edi, dword [esi + _ahci_mem.ports + eax]

    mov eax, dword [edi + _ahci_port.is]
.unknown:
    test eax, ~AHCI_PxIE_DEFAULTS
    jnz .unimpl
.d2h_done:
    test eax, AHCI_PxIE_DHRE
    jz .dps
    or dword [edi + _ahci_port.is], AHCI_PxIE_DHRE ; Clear and keep going?
.dps:
    test eax, AHCI_PxIE_DPS
    jz .non_fatal_error
    or dword [edi + _ahci_port.is], AHCI_PxIE_DPS ; Clear and keep going?
.non_fatal_error:
    test eax, AHCI_PxIE_INFE
    jz .fatal_error
    jmp .unimpl
.fatal_error:
    test eax, AHCI_PxIE_IFE
    jz .bus_data_error
    jmp .unimpl
.bus_data_error:
    test eax, AHCI_PxIE_HBDE
    jz .bus_fatal_error
    jmp .unimpl
.bus_fatal_error:
    test eax, AHCI_PxIE_HBDF
    jz .next_port
    jmp .unimpl
.unimpl:
    push color_err
    push .unhandled
    call print_str
    add esp, 8
    jmp $
.next_port:
    add dword [esp], 1
    cmp dword [esp], 32
    jl .port_loop
    add esp, 4

    popad
    iret
.unhandled: db `Unhandled AHCI error.\n`, 0

section .stage1_copy nobits
global boot_partition
boot_partition: resb 16
