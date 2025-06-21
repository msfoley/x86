%ifndef INTERRUPT_ASM_INC
%define INTERRUPT_ASM_INC

struc _idt_entry
    .offset_low: resb 2
    .segment_selector: resb 2
    .reserved: resb 1
    .flags: resb 1
    .offset_high: resb 2
endstruc

INTERRUPT_PIC_1 equ 0x20
INTERRUPT_PIC_2 equ 0x21
INTERRUPT_PIC_3 equ 0x22
INTERRUPT_PIC_4 equ 0x23
INTERRUPT_PIC_5 equ 0x24
INTERRUPT_PIC_6 equ 0x25
INTERRUPT_PIC_7 equ 0x26
INTERRUPT_PIC_8 equ 0x27
INTERRUPT_PIC_9 equ 0x28
INTERRUPT_PIC_10 equ 0x2A
INTERRUPT_PIC_11 equ 0x2B
INTERRUPT_PIC_12 equ 0x2C
INTERRUPT_PIC_13 equ 0x2D
INTERRUPT_PIC_14 equ 0x2E
INTERRUPT_PIC_15 equ 0x2F

IDT_INTERRUPT_GATE equ 0x8E
IDT_TRAP_GATE equ 0x8F
IDT_TASK_GATE equ 0x85

PIC1_COMMAND equ 0x0020
PIC1_DATA equ 0x0021
PIC2_COMMAND equ 0x00A0
PIC2_DATA equ 0x00A1

PIC_COMMAND_EOI equ 0x20

%ifndef INTERRUPT_ASM_INC_NO_EXTERN
extern idt
extern idtr

extern pic_mask ; void pic_mask(uint8_t int)
extern pic_unmask ; void pic_mask(uint8_t int)

extern interrupt_register ; void interrupt_register(uint8_t interrupt, uint32_t address, uint8_t flags)
extern interrupt_init ; int interrupt_init(void)

extern tss
%endif
%endif
