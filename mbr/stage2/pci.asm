bits 32

%define PCI_ASM_INC_NO_EXTERN
%include "stage2/pci.inc.asm"
%include "stage2/print.inc.asm"

ENABLE_BIT equ 0x80000000

CONFIG_ADDRESS equ 0xCF8
CONFIG_DATA equ 0xCFC

MAX_DEVICE_LIST equ (PCI_MAX_DEVICES * 4) / 16

section .bss

global pci_device_list
; Surely we won't run into a device that needs the whole address space, right?
pci_device_list: resb (4 + MAX_DEVICE_LIST)

section .text

global pci_init
pci_init: ; void pci_init()
    push ebp
    mov ebp, esp
    push esi

    ; Clear length
    mov dword [pci_device_list + _pci_device_list.length], 0

    ; Check if root port exists
    push _pci_header_type_0.vendor ; offset
    push 0 ; func
    push 0 ; slot
    push 0 ; bus
    call pci_read_word
    cmp eax, 0xFFFF
    je .exit

    call bus_scan

    mov dword [ebp - 8], _pci_header_type_0.header_type ; offset
    call pci_read_byte
    test al, 0x80
    jz .exit ; If this isn't a multi function device, we don't have to scan a bunch of other busses

    mov dword [ebp - 8], _pci_header_type_0.vendor ; offset
    xor esi, esi
.alt_bus_loop:
    add esi, 1
    mov dword [ebp - 20], esi ; bus

    call pci_read_word
    cmp eax, 0xFFFF
    je .exit

    call bus_scan

    cmp esi, PCI_MAX_FUNC
    jl .alt_bus_loop

.exit:
    add esp, 16
    pop esi
    pop ebp
    ret

bus_scan: ; void bus_scan(uint8_t bus)
    push ebp
    mov ebp, esp
    push esi

    mov esi, 0
.slot_loop:
    push esi ; slot
    push dword [ebp + 8] ; bus
    call slot_scan
    add esp, 8

    add esi, 1
    cmp esi, PCI_MAX_SLOT
    jle .slot_loop

    pop esi
    pop ebp
    ret

slot_scan: ; void slot_scan(uint8_t bus, uint8_t slot)
    push ebp
    mov ebp, esp

    push _pci_header_type_0.vendor ; offset
    push 0 ; func
    push dword [ebp + 12] ; slot
    push dword [ebp + 8] ; bus
    call pci_read_word

    cmp eax, 0xFFFF
    je .exit ; If have vendor ID of 0xFFFF, no device is here
    call pci_add_device

    mov dword [ebp - 4], _pci_header_type_0.header_type ; offset
    call pci_read_byte
    test eax, 0x80
    jz .exit ; If this bit isn't set, this is a single function device

    mov dword [ebp - 4], _pci_header_type_0.vendor ; offset
.func_loop:
    mov eax, dword [ebp - 8] ; Get func
    add eax, 1 ; Increment func
    mov dword [ebp - 8], eax ; Put it back for the function call
    call pci_read_word

    cmp eax, 0xFFFF
    je .exit ; Vendor ID check again
    call pci_add_device

    cmp dword [ebp - 8], PCI_MAX_FUNC
    jl .func_loop
    
.exit:
    add esp, 16
    pop ebp
    ret

pci_add_device: ; void pci_add_device(uint8_t bus, uint8_t slot, uint8_t func)
    push ebp
    mov ebp, esp
    push edi
    push esi

    ; Store the device if we have room
    lea edi, dword [pci_device_list]
    mov ecx, dword [edi + _pci_device_list.length]
    cmp ecx, MAX_DEVICE_LIST
    jge .exit

    ; Increment the stored length
    mov edx, ecx
    add edx, 1
    mov dword [edi + _pci_device_list.length], edx

    ; Store bus:slot.func
    lea edi, dword [ecx * _pci_device_size + edi + _pci_device_list.device_list]
    mov ecx, dword [ebp + 16]
    mov byte [edi + _pci_device.func], cl
    mov ecx, dword [ebp + 12]
    mov byte [edi + _pci_device.slot], cl
    mov ecx, dword [ebp + 8]
    mov byte [edi + _pci_device.bus], cl

    ; Get class and subclass
    push _pci_header_type_0.revision_id ; offset
    push dword [ebp + 16] ; func
    push dword [ebp + 12] ; slot
    push dword [ebp + 8] ; bus
    call pci_read_dword

    ; Store it
    mov dword [edi + _pci_device.revision_id], eax
    ; Extract class and sub class
    shr eax, 16
    mov edx, eax
    shr edx, 8 ; class
    and eax, 0xFF ; sub class

    ; Check if this is a bridge
    cmp eax, 0x04
    jne .cleanup
    cmp edx, 0x06
    jne .cleanup

    ; Get the new bus number
    mov dword [ebp - 4], _pci_header_type_bridge.secondary_bus ; offset
    call pci_read_byte
    ; Scan it
    mov dword [ebp - 16], eax ; bus
    call bus_scan

.cleanup:
    add esp, 16
.exit:
    pop esi
    pop edi
    pop ebp
    ret

global pci_read_dword
pci_read_dword: ; uint32_t pci_read_dword(uint8_t bus, uint8_t slot, uint8_t func, uint8_t offset)
    push ebp
    mov ebp, esp

    ; Construct address
    mov eax, ENABLE_BIT
    ; Bus number
    mov ecx, [ebp + 8]
    and ecx, PCI_MAX_BUS
    shl ecx, 16
    or eax, ecx
    ; Slot number
    mov ecx, [ebp + 12]
    and ecx, PCI_MAX_SLOT
    shl ecx, 11
    or eax, ecx
    ; Function number
    mov ecx, [ebp + 16]
    and ecx, PCI_MAX_FUNC
    shl ecx, 8
    or eax, ecx
    ; Offset
    mov ecx, [ebp + 20]
    and ecx, 0xFC
    or eax, ecx

    mov edx, CONFIG_ADDRESS
    out dx, eax
    mov edx, CONFIG_DATA
    in eax, dx

    pop ebp
    ret

global pci_read_word
pci_read_word: ; uint32_t pci_read_word(uint8_t bus, uint8_t slot, uint8_t func, uint8_t offset)
    push ebp
    mov ebp, esp

    push dword [ebp + 20] ; offset
    push dword [ebp + 16] ; func
    push dword [ebp + 12] ; slot
    push dword [ebp + 8] ; bus
    call pci_read_dword
    add esp, 16

    mov ecx, [ebp + 20]
    and ecx, 0x02
    shl ecx, 3 ; Either (2 << 3 = 16) or (0 << 3 = 0)
    shr eax, cl ; eax = eax >> ((offset & 0x03) * 8)
    and eax, 0xFFFF

    pop ebp
    ret

global pci_read_byte
pci_read_byte: ; uint32_t pci_read_byte(uint8_t bus, uint8_t slot, uint8_t func, uint8_t offset)
    push ebp
    mov ebp, esp

    push dword [ebp + 20] ; offset
    push dword [ebp + 16] ; func
    push dword [ebp + 12] ; slot
    push dword [ebp + 8] ; bus
    call pci_read_dword
    add esp, 16

    mov ecx, [ebp + 20]
    and ecx, 0x03
    shl ecx, 3
    shr eax, cl ; eax = eax >> ((offset & 0x03) * 8)
    and eax, 0xFF

    pop ebp
    ret

global pci_print_device_list
pci_print_device_list: ; void pci_print_device_list()
    push ebp
    mov ebp, esp
    push ebx
    push esi

    push color_norm
    push .header_str
    call print_str
    add esp, 8

    xor ebx, ebx
.loop:
    lea esi, dword [pci_device_list + _pci_device_list.device_list + ebx * _pci_device_size]
    push esi
    call pci_print_device
    add esp, 4

    add ebx, 1
    cmp ebx, dword [pci_device_list + _pci_device_list.length]
    jl .loop    

    pop esi
    pop ebx
    pop ebp
    ret
.header_str: db `PCI Map:\n`, 0

pci_print_device: ; void pci_print_device(struct _pci_device *device)
    push ebp
    mov ebp, esp
    push edi
    push esi

    mov edi, number_string
    mov esi, [ebp + 8]

    push 0
    push temp_storage
    ; Format bus
    mov al, byte [esi + _pci_device.bus]
    mov byte [ebp - 12], al
    call itoa8
    mov ax, word [temp_storage + 2]
    mov word [edi], ax
    mov byte [edi + 2], ":"
    add edi, 3
    ; Format slot
    mov al, byte [esi + _pci_device.slot]
    mov byte [ebp - 12], al
    call itoa8
    mov ax, word [temp_storage + 2]
    mov word [edi], ax
    mov byte [edi + 2], "."
    add edi, 3
    ; Format func
    mov al, byte [esi + _pci_device.func]
    mov byte [ebp - 12], al
    call itoa8
    mov al, byte [temp_storage + 3]
    mov byte [edi], al
    mov byte [edi + 1], " "
    add edi, 2
    ; cleanup
    mov byte [edi], 0
    add esp, 8
    ; print "<bus>:<slot>.<func> "
    push color_norm
    push number_string
    call print_str
    add esp, 8

    ; Print big ol DWORD 1
    push dword [esi + _pci_device.revision_id]
    push number_string
    call itoa
    mov dword [ebp - 12], color_norm
    call print_str
    add esp, 8
    call print_space

    ; Get vendor/device
    xor eax, eax
    push _pci_header_type_0.vendor
    mov al, [esi + _pci_device.func]
    push eax
    mov al, [esi + _pci_device.slot]
    push eax
    mov al, [esi + _pci_device.bus]
    push eax
    call pci_read_dword
    add esp, 16
    ; Setup stack
    push eax
    push 0
    push temp_storage
    mov edi, number_string
    ; Format vendor
    mov ax, word [ebp - 12]
    mov word [ebp - 16], ax
    call itoa16
    mov eax, dword [temp_storage + 2]
    mov dword [edi], eax
    mov byte [edi + 4], ":"
    add edi, 5
    ; Format device
    mov ax, word [ebp - 10]
    mov word [ebp - 16], ax
    call itoa16
    mov eax, dword [temp_storage + 2]
    mov dword [edi], eax
    mov byte [edi + 4], `\n`
    add edi, 5
    ; print "<vendor>:<device>\n"
    mov byte [edi], 0
    add esp, 12
    push color_norm
    push number_string
    call print_str
    add esp, 8

    pop esi
    pop edi
    pop ebp
    ret

global pci_write_dword
pci_write_dword: ; uint32_t pci_write_dword(uint8_t bus, uint8_t slot, uint8_t func, uint8_t offset, uint32_t data)
    push ebp
    mov ebp, esp

    ; Construct address
    mov eax, ENABLE_BIT
    ; Bus number
    mov ecx, [ebp + 8]
    and ecx, PCI_MAX_BUS
    shl ecx, 16
    or eax, ecx
    ; Slot number
    mov ecx, [ebp + 12]
    and ecx, PCI_MAX_SLOT
    shl ecx, 11
    or eax, ecx
    ; Function number
    mov ecx, [ebp + 16]
    and ecx, PCI_MAX_FUNC
    shl ecx, 8
    or eax, ecx
    ; Offset
    mov ecx, [ebp + 20]
    and ecx, 0xFC
    or eax, ecx

    mov edx, CONFIG_ADDRESS
    out dx, eax
    mov edx, CONFIG_DATA
    mov eax, [ebp + 24]
    out dx, eax

    pop ebp
    ret

section .bss
temp_storage: resb 7
