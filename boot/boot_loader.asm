bits 32

color_black equ 0
color_white equ 15
color_white_on_black equ (color_black << 4) | color_white
video_mem equ 0x000B8000
columns equ 80
lines equ 25

section .bss

; disk stuff
drive_num: resb 1 ; Inherited from stage1
disk_access: resb 16
boot_partition: resb 4
; printing stuff
number_string: resb 32
print_x: resb 1
print_y: resb 1

section .text

_start:
    jmp start

start:
    cli
    mov ebp, esp

    ; Setup video vars
    mov byte [print_x], 0
    mov byte [print_y], 0

    call clear_screen
    ; print message saying we're in stage 2
    push color_white_on_black
    push ident_string
    call print_str
    add esp, 8

    ; dead loop
    hlt
    jmp $-1
    ; Do a reset if we ever get here
    jmp 0xFFFF:0x0000

find_boot_partition:
    ret 

clear_screen:
    mov eax, video_mem
    mov ecx, eax
    add ecx, 2 * columns * lines
.loop:
    mov dword [eax], 0x00000000
    add eax, 4
    cmp eax, ecx
    jne .loop
    ret

print_str: ; print_str(char *str, uint8_t color)
    push ebp
    mov ebp, esp
    push esi
    push edi
    push ebx

    mov esi, dword [ebp + 8] ; String to print

    xor ecx, ecx
    mov cl, byte [print_y] ; row counter
    xor ebx, ebx
    mov bl, byte [print_x] ; column counter
    jmp .loop

; Shift the entire video memory up one line
.shift_mem:
    sub ecx, 1
    push ecx
    push ebx
    mov ecx, 0
.shift_loop:
    mov ebx, 0
.shift_loop_inner:
    mov eax, 2 * columns
    mul ecx
    lea edi, [(ebx * 2) + eax + video_mem]
    lea edx, [edi + (2 * columns)]
    mov ax, word [edx]
    mov word [edi], ax
    add ebx, 1
    cmp ebx, columns - 1
    jl .shift_loop_inner
    add ecx, 1
    cmp ecx, lines
    jl .shift_loop
    pop ebx
    pop ecx
    jmp .write_char

.loop:
.check_column:
    cmp ecx, columns
    jnge .check_row
    mov ebx, 0
    add ecx, 0
.check_row:
    cmp ecx, lines
    jge .shift_mem
.write_char:
    mov al, byte [esi]
    cmp bl, al
    je .exit
    cmp al, `\n`
    jne .no_newline
    add ecx, 1
    mov ebx, 0
    add esi, 1
    jmp .loop
.no_newline:
    cmp al, `\r`
    jne .no_cr
    mov ebx, 0
    add esi, 1
    jmp .loop
.no_cr:
    mov eax, 2 * columns
    mul ecx
    lea edi, [(ebx * 2) + eax + video_mem]
    mov al, byte [esi]
    mov byte [edi], al
    mov al, byte [ebp + 12]
    mov byte [edi + 1], al
    add ebx, 1
    add esi, 1
    jmp .loop
.exit:
    mov byte [print_y], cl
    mov byte [print_x], dl
    pop ebx
    pop edi
    pop esi
    pop ebp
    ret

itoa:
    push ebp
    mov ebp, esp

section .data

ident_string: db `Stage2 Bootloader\n`, 0
test_string: db `blah\n`, 0

section .bios_data nobits

bios_data_com1: resb 1
bios_data_com2: resb 1
bios_data_com3: resb 1
bios_data_com4: resb 1
bios_data_ebda: resb 2
bios_data_hw_flags: resb 2
bios_data_data_before_ebda: resb 2
bios_data_kb_state: resb 2
bios_data_kb_buffer: resb 32
bios_data_display_mode: resb 1
bios_data_text_columns: resb 2
bios_data_video_io_port: resb 2
bios_data_boot_timer: resb 2
bios_data_disk_count: resb 1
bios_data_kb_buffer_start: resb 2
bios_data_kb_buffer_end: resb 2
bios_data_kb_last_state: resb 1
