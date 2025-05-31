bits 32

%define DISK_ASM_INC_NO_EXTERN
%include "stage2/disk.asm.inc"
%include "stage2/bootloader.asm.inc"
%include "stage2/pci.asm.inc"
%include "stage2/print.asm.inc"

%define AHCI_CLASS 0x01
%define AHCI_SUBCLASS 0x06
%define AHCI_PROG_IF 0x01

section .bss

ahci_base: resb 4

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
    jmp .exit
    mov eax, 0
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

ahci_port_detect: ; int ahci_port_detect(struct ahci_mem *ptr)
    push ebp
    mov ebp, esp
    push esi
    push edi
    push ebx

    mov esi, dword [ebp + 8]
    ; Get bit field of implemented ports
    mov ebx, [esi + ahci_mem.pi]
    xor ecx, ecx
.loop_ports:
    ; Get address of port from memory base
    mov eax, ecx
    mov edx, ahci_port_size
    mul edx
    lea edi, [eax + esi + ahci_mem.ports]
    
    mov eax, 1
    shl eax, cl

    test ebx, eax
    jz .port_not_present

    push edi
    call ahci_detect_port
    add esp, 4
    cmp eax, 0
    jnz .device_found
.port_not_present:
    add ecx, 1
    cmp ecx, 32
    jl .loop_ports
.device_not_found:
    mov eax, 1
    jmp .exit
.device_found:
    xor eax, eax
.exit:
    pop ebx
    pop edi
    pop esi
    pop ebp
    ret

ahci_detect_port: ; int ahci_detect_port(struct ahci_port *ptr)
    push ebp
    mov ebp, esp
    ; Do something

    pop ebp
    ret  
