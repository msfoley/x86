bits 16

sector_size equ 512
stage2 equ 0x10000
extern _stack_top

section .text

_start:
    jmp 0:start

stage2_sector: dw 0x0000
stage2_length: dw 0x0000

start:
    cli
    ; Zero out segment registers
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ; Save drive number
    mov byte [ds:drive_num], dl
    ; Setup stack
    mov sp, 0x7B00
    ; Set the A20 address line
    call set_a20
    ; Copy the boot loader
    call copy_boot_loader
    ; Enter 32-bit protected
    call enter_32
reset:
    ; Do a reset if we ever get here
    jmp 0xFFFF:0x0000

enter_32:
    ; Make sure we zero out segments that we used.
    xor ax, ax
    mov es, ax

    lgdt [gdtr]
    mov eax, cr0
    or al, 0x01
    mov cr0, eax
    jmp 0x08:tramp_32

bits 32
tramp_32:
    jmp 0x08:stage2
bits 16

; Copy the stage2 bootloader from disk to RAM
copy_boot_loader:
    ; Load start sector in dx
    mov si, word [ds:stage2_sector]

    ; Load end sector in cx
    mov cx, word [ds:stage2_length]
    add cx, si

    mov byte [ds:disk_access], 0x10
    mov byte [ds:disk_access + 1], 0x00
    mov word [ds:disk_access + 2], 1
    mov word [ds:disk_access + 10], 0
    mov word [ds:disk_access + 12], 0
    mov word [ds:disk_access + 14], 0
.loop:
    cmp si, cx
    je .exit

    ; Get destination of sector
    mov ax, si
    sub ax, [ds:stage2_sector]
    mov bx, sector_size
    mul bx
    mov di, ax

    ; Handle any overflow in dx
    xor ax, ax
    mov bx, 0x00016
    div bx
    cmp ax, 0x6000
    jg .exit ; We need to stop if we're going to overflow stage2
    add ax, stage2 / 16

    mov bx, disk_access
    mov word [ds:disk_access + 4], di
    mov word [ds:disk_access + 6], ax
    mov word [ds:disk_access + 8], si
    mov dl, byte [ds:drive_num]
    push si
    mov si, disk_access
    mov ah, 0x42
    int 0x13
    pop si

    add si, 1
    jmp .loop
.exit:
    ret

; Warning: destructive
check_a20:
    ; 0000:0500 -> 0x00000500
    mov si, 0x0500
    ; FFFF:0510 -> 0x00100500
    mov ax, 0xFFFF
    mov es, ax
    mov di, 0x0510
    ; Get current value of 0x00100500
    mov al, byte [es:di]
    ; Generate a new value and write it to 0x00000500
    not al
    mov byte [ds:si], al
    ; Compare 0x00100500 to the value written to 0x00000500
    cmp byte [es:di], al

    ; If they are not equal, A20 is set
    mov ax, 1
    jne .exit
    ; Otherwise A20 is not set
    mov ax, 0
.exit:
    ret

set_a20_bios:
    ; Check if the A20-Gate is supported in BIOS
    mov ax, 0x2403
    int 0x15
    jc .exit
    cmp ah, 0
    jne .exit
    ; Set A20
    mov ax, 0x2401
    int 0x15
    ; Should technically check this, but meh
    ; jc .exit
    ; cmp ah, 0
    ; jne .exit
.exit:
    ret

set_a20:
    call check_a20
    cmp ax, 1
    je .exit
    ; Try the BIOS method first
    call set_a20_bios
    call check_a20
    cmp ax, 1
    je .exit
    ; TODO: implement the other methods
.exit:
    ret

gdtr:
    dw (8 * 3)
    dd gdt
gdt:
    ; Null descriptor
    dw 0x0000 ; 15:0 Limit
    dw 0x0000 ; 15:0 Base
    db 0x00 ; 23:16 Base
    db 0x00 ; Access Byte
    db 0x00 ; 3:0 Flags ; 19:16 Flags
    db 0x00 ; 31:24 Base
    ; Code descriptor
    dw 0xFFFF ; 15:0 Limit
    dw 0x0000 ; 15:0 Base
    db 0x00 ; 23:16 Base
    db 0x9A ; Access Byte
    db 0xCF ; 3:0 Flags ; 19:16 Limit
    db 0x00 ; 31:24 Base
    ; Data descriptor
    dw 0xFFFF ; 15:0 Limit
    dw 0x0000 ; 15:0 Base
    db 0x00 ; 23:16 Base
    db 0x92 ; Access Byte
    db 0xCF ; 3:0 Flags ; 19:16 Limit
    db 0x00 ; 31:24 Base

times (0x1B8 - ($ - $$)) db 0x00

unique_id: db 0x00, 0x00, 0x00, 0x00
reserved: db 0x00, 0x00
partition1: times 16 db 0x00
partition2: times 16 db 0x00
partition3: times 16 db 0x00
partition4: times 16 db 0x00
signature: db 0x55, 0xAA

section .bss

drive_num: resb 1
disk_access: resb 16
