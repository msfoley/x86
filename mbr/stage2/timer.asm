%define TIMER_ASM_INC_NO_EXTERN
%include "stage2/timer.asm.inc"
%include "stage2/interrupt.asm.inc"

bits 32

PIT_CHANNEL_0_PORT equ 0x40
PIT_CHANNEL_1_PORT equ 0x41
PIT_CHANNEL_2_PORT equ 0x42
PIT_COMMAND_PORT equ 0x43

PIT_COMMAND_CHANNEL_0 equ 0x00
PIT_COMMAND_CHANNEL_1 equ 0x40
PIT_COMMAND_CHANNEL_2 equ 0x80
PIT_COMMAND_ACCESS_LATCH_COUNT equ 0x00
PIT_COMMAND_ACCESS_LOW_ONLY equ 0x10
PIT_COMMAND_ACCESS_HIGH_ONLY equ 0x20
PIT_COMMAND_ACCESS_LOW_HIGH equ 0x30
PIT_COMMAND_OP_MODE_0 equ 0x00
PIT_COMMAND_OP_MODE_1 equ 0x02
PIT_COMMAND_OP_MODE_2 equ 0x04
PIT_COMMAND_OP_MODE_3 equ 0x06
PIT_COMMAND_OP_MODE_4 equ 0x08
PIT_COMMAND_OP_MODE_5 equ 0x0A
PIT_COMMAND_OP_MODE_2_ALT equ 0x0C
PIT_COMMAND_OP_MODE_3_ALT equ 0x0E
PIT_COMMAND_COUNT_MODE_BIN equ 0x00
PIT_COMMAND_COUNT_MODE_BCD equ 0x01

PIT_RELOAD_ONE_MSEC equ 1193

section .text

timer_isr:
    pushad

    add dword [timer_cnt], 1

    mov dx, PIC1_COMMAND
    mov al, PIC_COMMAND_EOI
    out dx, al

    popad
    iretd

global timer_init
timer_init: ; void timer_init()
    push ebp
    mov ebp, esp

    mov dword [timer_cnt], 0

    push 0x00
    call pic_unmask
    add esp, 4

    push IDT_INTERRUPT_GATE
    push timer_isr
    push INTERRUPT_PIC_1
    call interrupt_register
    add esp, 12

    mov dx, PIT_COMMAND_PORT
    mov al, (PIT_COMMAND_CHANNEL_0 | PIT_COMMAND_OP_MODE_2 | PIT_COMMAND_ACCESS_LOW_HIGH | PIT_COMMAND_COUNT_MODE_BIN)
    out dx, al

    mov dx, PIT_CHANNEL_0_PORT
    mov ax, PIT_RELOAD_ONE_MSEC
    out dx, al
    mov al, ah
    out dx, al

    pop ebp
    ret

global timer_delay
timer_delay: ; void timer_delay(uint32_t msec)
    push ebp
    mov ebp, esp

    mov eax, dword [timer_cnt]
.loop:
    ;hlt
    mov ecx, dword [timer_cnt]
    sub ecx, eax
    cmp ecx, dword [ebp + 8]
    jl .loop

    pop ebp
    ret
