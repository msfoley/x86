bits 32

%define DISK_ASM_INC_NO_EXTERN
%include "stage2/disk.asm.inc"
%include "stage2/bootloader.asm.inc"
%include "stage2/pci.asm.inc"
%include "stage2/print.asm.inc"

AHCI_CLASS equ 0x01
AHCI_SUBCLASS equ 0x06
AHCI_PROG_IF equ 0x01

AHCI_CLASS_ATAPI equ 0xEB140101
AHCI_CLASS_SEMB equ 0xC33C0101
AHCI_CLASS_PM equ 0x96690101
AHCI_CLASS_SATA equ 0x00000101

AHCI_PORT_IPM_ACTIVE equ 1
AHCI_PORT_DET_PRESENT equ 3

struc _ahci_port_local
    .port: resb 4
    .port_type: resb 4
endstruc

section .bss

ahci_base: resb 4
ahci_port_local: resb 32 * _ahci_port_local_size
ahci_port_boot_index: resb 1
disk_read_sector: resb 512

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
    push color_norm
    push .found_ahci
    call print_str
    add esp, 8

    push _pci_header_type_0.bar5
    push dword [edi + _pci_device.func]
    push dword [edi + _pci_device.slot]
    push dword [edi + _pci_device.bus]
    call pci_read_dword
    add esp, 16
    mov dword [ahci_base], eax

    call ahci_port_detect
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
.found_ahci: db `Found AHCI device.\n`, 0

ahci_port_detect: ; int ahci_port_detect()
    push ebp
    mov ebp, esp
    push esi
    push edi
    push ebx

    mov esi, dword [ahci_base]
    ; Get bit field of implemented ports
    mov ebx, dword [esi + _ahci_mem.pi]
    xor ecx, ecx
.loop_ports:
    ; Get address of port from memory base
    mov eax, ecx
    mov edx, _ahci_port_size
    mul edx
    lea edi, dword [eax + esi + _ahci_mem.ports]
    
    mov eax, 1
    shl eax, cl

    test ebx, eax
    jz .port_not_present

    push edi
    push ecx
    call ahci_detect_port
    add esp, 8
.port_not_present:
    add ecx, 1
    cmp ecx, 31
    jl .loop_ports
.device_found:
    xor eax, eax
.exit:
    pop ebx
    pop edi
    pop esi
    pop ebp
    ret

ahci_detect_port: ; int ahci_detect_port(int index, struct ahci_port *ptr)
    push ebp
    mov ebp, esp
    push edi
    push esi

    mov edi, dword [ebp + 8]
    lea edi, dword [edi * _ahci_port_local_size + ahci_port_local]

    mov esi, dword [ebp + 12] ; port PTR
    mov eax, dword [esi + _ahci_port.ssts]

    mov ecx, eax
    and ecx, 0x0F
    cmp ecx, AHCI_PORT_DET_PRESENT
    jne .not_present

    mov ecx, eax
    shr ecx, 8
    and ecx, 0x0F
    cmp ecx, AHCI_PORT_IPM_ACTIVE
    jne .not_present

    mov eax, dword [esi + _ahci_port.sig]
    cmp eax, AHCI_CLASS_SATA
    je .supported
    cmp eax, AHCI_CLASS_ATAPI
    je .supported
    cmp eax, AHCI_CLASS_SEMB
    je .supported
    cmp eax, AHCI_CLASS_PM
    je .supported
    jmp .not_present
.supported:
    mov dword [edi + _ahci_port_local.port_type], eax
    mov dword [edi + _ahci_port_local.port], esi
    mov eax, 1
    jmp .exit
.not_present:
    xor eax, eax
.exit:
    pop esi
    pop edi
    pop ebp
    ret  

ahci_port_find_boot_device:
    push ebp
    mov ebp, esp
    push edi
    push esi

    pop esi
    pop edi
    ret

section .stage1_copy nobits
global boot_partition
boot_partition: resb 16
