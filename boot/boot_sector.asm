bits 16

sector_size equ 512
stage2 equ 0x10000
extern _stack_top

section .text

_start:
    jmp 0:start

; pad to word boundary
db 0x5A
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
    ; Get disk geometry info
    call get_disk_info
    ; Copy the boot loader
    call copy_boot_loader
    ; Enter 32-bit protected
    call enter_32
    ; Loop here for debugging purposes
.dead_loop:
    jmp $
    ; Do a reset if we ever get here
    jmp 0xFFFF:0x0000

enter_32:
    ; Make sure we zero out segments that we used.
    xor ax, ax
    mov ds, ax

    lgdt [gdtr]
    mov eax, cr0
    or al, 0x01
    mov cr0, eax
    jmp 0x08:tramp_32

bits 32
tramp_32:
    jmp 0x08:stage2
bits 16

; Get disk layout information from BIOS
get_disk_info:
    xor ax, ax
    mov ds, ax

    xor dx, dx
    mov dl, byte [ds:drive_num] ; Drive number in dl
    test dl, 0x80
    jz .defaults

    ; For compatiblity 0 out es:di
    mov es, ax
    xor di, di

    mov ah, 0x08
    int 0x13
    jc $ ; Loop here for debug
.hard_drive:
    ; Extract info for a hard drive
    and cx, 0x3F
    mov word [ds:sectors_per_track], cx
    shr dx, 8
    add dx, 1
    mov word [ds:heads_per_cylinder], dx
    jmp .exit
.defaults:
    mov word [ds:sectors_per_track], 63
    mov word [ds:heads_per_cylinder], 16
.exit:
    ret

; Copy the stage2 bootloader from disk to RAM
copy_boot_loader:
    xor ax, ax
    mov ds, ax
    mov es, ax
    push si

    ; Load start sector in si
    mov di, stage2_sector
    mov si, word [ds:di]
    mov dx, si

    ; Load end sector in cx
    mov di, stage2_length
    mov cx, word [ds:di]
    add cx, si

.loop:
    cmp si, cx
    je .exit

    ; Get destination of sector
    mov ax, si
    sub ax, dx
    mov bx, sector_size
    mul bx
    mov di, ax

    ; Handle any overflow in dx
    xor ax, ax
    mov bx, 0x00016
    div bx
    cmp ax, 0x6000
    jg .exit ; We need to stop if we're going to overflow stage2
    ; ds = _stage2 segment + ax
    add ax, stage2 / 16
    mov ds, ax

    call .lba
    add si, 1
    jmp .loop
.exit:
    pop si
    ret
; Convert the LBA to CHS and read the sector to ds:di
.lba:
    push cx
    push dx
    xor ax, ax
    mov es, ax

    ; C = LBA / (HPC * SPT)
    ; bx = HPC * SPT
    mov ax, [es:heads_per_cylinder]
    mov bx, [es:sectors_per_track]
    mul bx
    mov bx, ax
    ; LBA / bx
    mov ax, si
    div bx
    ; ch = C
    mov ch, al

    ; S = (LBA mod SPT) + 1
    ; dx = LBA mod SPT
    xor dx, dx
    mov ax, si
    mov bx, [es:sectors_per_track]
    div bx
    ; S = dx + 1
    add dx, 1
    ; cl = S
    mov cl, dl

    ; H = (LBA / SPT) mod HPC
    xor dx, dx
    mov ax, si
    mov bx, [es:sectors_per_track]
    div bx
    mov bx, [es:heads_per_cylinder]
    div bx
    mov bx, dx
    ; dh = H
    shl dx, 8

    mov dl, [es:drive_num] ; drive number
    
    mov ax, ds
    mov es, ax ; buffer segment
    mov bx, di ; buffer index

    mov ah, 0x02 ; arg=read for int 0x13
    mov al, 0x01 ; Read one sector

    int 0x13
    jc $ ; Loop here for debug
.lba_exit:
    pop dx
    pop cx
    ret

; Warning: destructive
check_a20:
    xor ax, ax
    ; 0000:0500 -> 0x00000500
    mov ds, ax
    mov si, 0x0500
    ; FFFF:0510 -> 0x00100500
    not ax
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
heads_per_cylinder: resb 2
sectors_per_track: resb 2
buf: resb 512
