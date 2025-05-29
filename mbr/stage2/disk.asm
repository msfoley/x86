bits 32

%include "stage2/bootloader.asm.inc"
%include "stage2/disk.asm.inc"

global ahci_init
ahci_init: ; int ahci_init(uint32_t base_ptr)
    nop

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
