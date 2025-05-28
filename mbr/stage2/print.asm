bits 32

%define STRING_ASM_INC_NO_EXTERN
%include "stage2/print.asm.inc"
%include "stage2/strings.asm.inc"

video_mem equ 0x000B8000
columns equ 80
lines equ 25

section .bss

global print_col
print_col: resb 1
global print_line
print_line: resb 1

section .text

global print_str
print_str: ; print_str(char *str, uint8_t color)
    push ebp
    mov ebp, esp
    push esi
    push edi
    push ebx

    mov esi, dword [ebp + 8] ; String to print

    xor ecx, ecx
    mov cl, byte [print_line] ; row counter
    xor ebx, ebx
    mov bl, byte [print_col] ; column counter
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
    cmp al, 0x00
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
    mov byte [print_line], cl
    mov byte [print_col], bl
    pop ebx
    pop edi
    pop esi
    pop ebp
    ret

global itoa
itoa:
    push ebp
    push edi
    mov ebp, esp

    mov edi, dword [ebp + 12]
    mov eax, dword [ebp + 16]

.push_loop:
    mov edx, eax
    and edx, 0x0F
    mov dl, byte [edx + conv_hex]
    push edx
    shr eax, 4 
    cmp eax, 0
    jne .push_loop
    push 'x'
    push '0'
.pop_loop:
    pop eax
    mov byte [edi], al
    add edi, 1
    cmp esp, ebp
    jne .pop_loop
.exit:
    mov byte [edi], 0
    mov eax, edi
    sub eax, dword [ebp + 8]
    sub eax, 1

    pop edi
    pop ebp
    ret

global clear_screen
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

section .data

conv_hex: db "0123456789ABCDEF", 0
