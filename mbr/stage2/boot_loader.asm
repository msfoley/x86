bits 32

color_black equ 0
color_white equ 15
color_gray equ 7
color_red equ 4
color_norm equ (color_black << 4) | color_white
color_err equ (color_red << 4) | color_white

video_mem equ 0x000B8000
columns equ 80
lines equ 25

section .bss

; disk stuff
drive_num: resb 1 ; Inherited from stage1
disk_access: resb 16
boot_partition:
.attr: resb 1
.chs_start: resb 3
.type: resb 1
.chs_last: resb 3
.lba_start: resb 4
.sector_count: resb 4

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
    push color_norm
    push strings.ident
    call print_str
    add esp, 8

    call find_boot_partition

reset:
    hlt
    jmp $
    ; Do a reset if we ever get here
    jmp 0xFFFF:0x0000

find_boot_partition:
    push ebp
    mov ebp, esp
    push esi

    xor eax, eax
    mov esi, mbr.partition1
.loop:
    mov al, [esi]
    test al, 0x80
    jnz .part_found
    add esi, 16
    cmp esi, mbr.partition4
    jle .loop
    push color_err
    push strings.active_partition_error
    call print_str
    add esp, 8
    call reset
.part_found:
    mov eax, dword [esi]
    mov dword [boot_partition], eax
    mov eax, dword [esi + 4]
    mov dword [boot_partition + 4], eax
    mov eax, dword [esi + 8]
    mov dword [boot_partition + 8], eax
    mov eax, dword [esi + 12]
    mov dword [boot_partition + 12], eax

    mov eax, dword [boot_partition + 8]
    push eax
    push number_string
    call itoa
    add esp, 8

    push color_norm
    push strings.active_partition
    call print_str
    add esp, 4
    push number_string
    call print_str
    add esp, 4
    push strings.newline
    call print_str
    add esp, 8

    pop esi
    pop ebp
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
    mov byte [print_y], cl
    mov byte [print_x], bl
    pop ebx
    pop edi
    pop esi
    pop ebp
    ret

itoa:
    push ebp
    push edi
    mov ebp, esp

    mov edi, dword [ebp + 12]
    mov eax, dword [ebp + 16]

.push_loop:
    mov edx, eax
    and edx, 0x0F
    mov dl, byte [edx + strings.hex]
    push edx
    shr eax, 4 
    cmp eax, 0
    jne .push_loop
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

section .data

strings:
.newline: db `\n`, 0
.hex: db "0123456789ABCDEF", 0
.hex_prefix: db "0x", 0
.ident: db `Stage2 Bootloader\n`, 0
.active_partition: db `Active partition start sector: `, 0
.active_partition_error: db `No active partition found\n`, 0

section .stage_one nobits

resb (0x1B8 - ($ - $$))
mbr:
.unique_id: resb 4 
.reserved: resb 2
.partition1: resb 16
.partition2: resb 16
.partition3: resb 16
.partition4: resb 16
.signature: resb 2

section .bios_data nobits

bios_data:
.com1: resb 1
.com2: resb 1
.com3: resb 1
.com4: resb 1
.ebda: resb 2
.hw_flags: resb 2
.data_before_ebda: resb 2
.kb_state: resb 2
.kb_buffer: resb 32
.display_mode: resb 1
.text_columns: resb 2
.video_io_port: resb 2
.boot_timer: resb 2
.disk_count: resb 1
.kb_buffer_start: resb 2
.kb_buffer_end: resb 2
.kb_last_state: resb 1
