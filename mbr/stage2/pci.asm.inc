%ifndef PCI_ASM_INC
%define PCI_ASM_INC

PCI_MAX_BUS equ 0xFF
PCI_MAX_SLOT equ 0x1F
PCI_MAX_FUNC equ 0x07
PCI_MAX_DEVICES equ (PCI_MAX_BUS + 1) * (PCI_MAX_SLOT + 1) * (PCI_MAX_FUNC + 1)

PCI_AHCI_CODE equ 0x01060100

struc _pci_device
    ; DWORD 0
    .func: resb 1
    .slot: resb 1
    .bus: resb 1
    .reserved: resb 1
    ; DWORD 1
    .revision_id: resb 1
    .prog_if: resb 1
    .subclass: resb 1
    .class: resb 1
endstruc

struc _pci_device_list
    .length: resb 4
    .device_list: resb 4
endstruc

struc _pci_header_type_0
    .vendor: resb 2
    .device: resb 2
    .command: resb 2
    .status: resb 2
    .revision_id: resb 1
    .prog_if: resb 1
    .sublcass: resb 1
    .class: resb 1
    .cache_line_size: resb 1
    .latency_timer: resb 1
    .header_type: resb 1
    .bist: resb 1
    .bar0: resb 4
    .bar1: resb 4
    .bar2: resb 4
    .bar3: resb 4
    .bar4: resb 4
    .bar5: resb 4
    .cardbus_cis_ptr: resb 4
    .subsystem_vendor_id: resb 2
    .subsystem_id: resb 2
    .expansion_rom_bar:  resb 4
    .cap_ptr: resb 1
    .reserved1: resb 3
    .reserved2: resb 4
    .interrupt_line: resb 1
    .interrupt_pin: resb 1
    .min_grant: resb 1
    .max_latency: resb 1
endstruc

struc _pci_header_type_bridge
    .ignored: resb 0x18
    .primary_bus: resb 1
    .secondary_bus: resb 1
endstruc

%ifndef PCI_ASM_INC_NO_EXTERN
extern pci_init ; void pci_init()
extern pci_read_dword ; uint32_t pci_read_dword(uint8_t bus, uint8_t slot, uint8_t func, uint8_t offset)
extern pci_read_word ; uint16_t pci_read_word(uint8_t bus, uint8_t slot, uint8_t func, uint8_t offset)
extern pci_read_byte ; uint8_t pci_read_byte(uint8_t bus, uint8_t slot, uint8_t func, uint8_t offset)
extern pci_print_device_list ; void pci_print_device_list()
%endif

%endif
