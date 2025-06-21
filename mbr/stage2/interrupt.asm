%define INTERRUPT_ASM_INC_NO_EXTERN
%include "stage2/interrupt.asm.inc"
%include "stage2/util.asm.inc"
%include "stage2/print.asm.inc"
%include "stage2/bootloader.asm.inc"

bits 32

PIC_INIT_SEQ equ 0x11
PIC_8086_MODE equ 0x01

PIC1_INTERRUPT_OFFSET equ 0x20
PIC2_INTERRUPT_OFFSET equ 0x28

section .data

mandatory_isr:
    dd divide_err_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd debug_exception_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd nmi_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd breakpoint_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd overflow_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd bound_range_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd invalid_opcode_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd device_not_available_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd double_fault_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd coprocessor_segment_overrun_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd tss_invalid_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd segment_not_present_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd stack_segment_fault_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd general_protection_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd page_fault_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd reserved_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd x87_fpu_error_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd alignment_check_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd machine_check_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd simd_fp_exception_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd virtualization_exception_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0
    dd control_protection_exception_isr
    db IDT_INTERRUPT_GATE, 0, 0, 0

global idtr
idtr:
    dw (256 * _idt_entry_size) - 1
    dd idt

global tss
tss: times _tss_size db 0x00

section .bss

alignb 4
tss_stack: resb 256

global idt
idt: resb (256 * _idt_entry_size)

section .text

io_wait:
    push ecx
    mov ecx, 0xFF
.delay:
    sub ecx, 1
    jnz .delay
    pop ecx
    ret

global pic_mask
pic_mask: ; void pic_mask(uint8_t int)
    push ebp
    mov ebp, esp

    mov cl, byte [ebp + 8]
    mov dx, PIC1_DATA

    cmp cl, 15
    jg .done
    cmp cl, 8
    jl .pic1
    mov dx, PIC2_DATA
    sub cl, 8
.pic1:
    mov al, 1
    shl al, cl
    push eax

    in al, dx
    or al, byte [esp]
    out dx, al

    add esp, 4
.done:
    pop ebp
    ret

global pic_unmask
pic_unmask: ; void pic_mask(uint8_t int)
    push ebp
    mov ebp, esp

    mov cl, byte [ebp + 8]
    mov dx, PIC1_DATA

    cmp cl, 15
    jg .done
    cmp cl, 8
    jl .pic1
    mov dx, PIC2_DATA
    sub cl, 8
.pic1:
    mov al, 1
    shl al, cl
    not al
    push eax

    in al, dx
    and al, byte [esp]
    out dx, al

    add esp, 4
.done:
    pop ebp
    ret

pic_remap: ; void pic_remap(uint8_t offset1, uint8_t offset2)
    push ebp
    mov ebp, esp

    ; Set PICs to init mode
    mov al, PIC_INIT_SEQ
    out PIC1_COMMAND, al
    call io_wait
    out PIC2_COMMAND, al
    call io_wait
    ; Set PIC interrupt offests
    mov al, [ebp + 8]
    out PIC1_DATA, al
    call io_wait
    mov al, [ebp + 12]
    out PIC2_DATA, al
    call io_wait
    ; Set PIC1 to master
    mov al, 0x04
    out PIC1_DATA, al
    call io_wait
    ; Set PIC2 to slave
    mov al, 0x02
    out PIC2_DATA, al
    call io_wait
    ; Set PICs to 8086 mode
    mov al, PIC_8086_MODE
    out PIC1_DATA, al
    call io_wait
    out PIC2_DATA, al
    call io_wait

    ; Mask all interrupts on the PICs
    mov al, 0xFF
    out PIC2_DATA, al
    and al, ~(1 << 2)
    out PIC1_DATA, al

    pop ebp
    ret

global interrupt_register
interrupt_register: ; void interrupt_register(uint8_t interrupt, uint32_t address, uint8_t flags)
    push ebp
    mov ebp, esp
    push edi

    mov eax, dword [ebp + 8]
    cmp eax, 0xFF
    jg .done
    and eax, 0xFF

    lea edi, dword [idt + eax * _idt_entry_size] ; IDT entry

    mov eax, dword [ebp + 16]
    mov byte [edi + _idt_entry.flags], al

    mov eax, dword [ebp + 12]
    mov word [edi + _idt_entry.offset_low], ax
    shr eax, 16
    mov word [edi + _idt_entry.offset_high], ax

    mov word [edi + _idt_entry.segment_selector], 0x0008

.done:
    pop edi
    pop ebp
    ret

idt_init: ; void idt_init(void)
    push ebp
    mov ebp, esp
    push esi

    xor ecx, ecx
.mandatory_isrs:
    lea esi, dword [mandatory_isr + _idt_entry_size * 8]
    mov eax, dword [esi + 4] ; Flags
    push eax
    mov eax, dword [esi] ; ISR address
    push eax
    push ecx
    call interrupt_register
    add esp, 12

    add ecx, 1
    cmp ecx, 0x16
    jl .mandatory_isrs

.reserved_isrs:
    push IDT_INTERRUPT_GATE
    push reserved_isr
    push ecx
    call interrupt_register
    add esp, 12

    add ecx, 1
    cmp ecx, 0x20
    jl .reserved_isrs

    pop esi
    pop ebp
    ret

global interrupt_init
interrupt_init: ; int interrupt_init(void)
    push ebp
    mov ebp, esp

    call idt_init
    lidt [ds:idtr]

    mov word [tss + _tss.iopb], _tss_size
    mov word [tss + _tss.ss0], _gdt.data
    mov dword [tss + _tss.esp0], tss_stack
    mov ax, _gdt.tss
    ltr ax

    push PIC2_INTERRUPT_OFFSET
    push PIC1_INTERRUPT_OFFSET
    call pic_remap
    add esp, 8

    xor eax, eax
    pop ebp
    ret

%macro default_isr 1
%1:
    ;pushad
    jmp $
    ;popad
    ;iret
%endmacro

%macro default_isr 2
%1:
    jmp $
    ;pushad
    ;push color_norm
    ;push .isr_code
    ;call print_str
    ;add esp, 8
    ;popad
    ;iret
.isr_code: db `\nException: `, %2, `\n`, 0
%endmacro
    
default_isr divide_err_isr, "#DE"
default_isr debug_exception_isr, "#DB"
default_isr nmi_isr, "NMI"
default_isr breakpoint_isr, "#BP"
default_isr overflow_isr, "#OF"
default_isr bound_range_isr, "#BR"
default_isr invalid_opcode_isr, "#UD"
default_isr device_not_available_isr, "#NM"
default_isr double_fault_isr
default_isr coprocessor_segment_overrun_isr, "CoProSegOver"
default_isr tss_invalid_isr, "#TS"
default_isr segment_not_present_isr, "#NP"
default_isr stack_segment_fault_isr, "#SS"
default_isr general_protection_isr, "#GP"
default_isr page_fault_isr, "#PF"
default_isr x87_fpu_error_isr, "#MF"
default_isr alignment_check_isr, "#AC"
default_isr machine_check_isr, "#MC"
default_isr simd_fp_exception_isr, "#XM"
default_isr virtualization_exception_isr, "#VE"
default_isr control_protection_exception_isr, "#CP"

default_isr reserved_isr, "Reserved"
