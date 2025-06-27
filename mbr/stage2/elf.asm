%define ELF_ASM_INC_NO_EXTERN
%include "stage2/elf.inc.asm"
%include "stage2/ext4.inc.asm"
%include "stage2/disk.inc.asm"
%include "stage2/bootloader.inc.asm"
%include "stage2/util.inc.asm"
%include "stage2/print.inc.asm"
%include "stage2/interrupt.inc.asm"
%include "stage2/timer.inc.asm"

bits 32

section .data

elf_header_magic: db 0x7F, "ELF"

section .bss

elf_is_64bit: resb 4

ELF_LOAD_SECTIONS_MAX equ 0x20 ; If the kernel has more than 32 sections, I'm going to cry
elf_load_sections_count: resb 4
elf_load_sections: resb _elf_program_header_64_size * ELF_LOAD_SECTIONS_MAX

elf_header: resb _elf_header_64_size

alignb 4
block_buffer: resb EXT4_MAX_BLOCK_SIZE * 2

section .text
global elf_init ; int elf_init()
elf_init:
    push ebp
    mov ebp, esp
    push esi

    push block_buffer
    push 0
    push ext4_kernel_inode
    call ext4_get_inode_block
    add esp, 12

    mov esi, block_buffer
    mov eax, dword [elf_header_magic]
    cmp dword [block_buffer + _elf_header_32.ident_magic], eax
    jne .failure ; Not an ELF file
    cmp byte [block_buffer + _elf_header_32.ident_data], ELF_HEADER_IDENT_DATA_LE
    jne .failure ; Not gonna mess with big endian ELF files
    cmp word [block_buffer + _elf_header_32.machine], ELF_HEADER_MACHINE_X86
    je .32_bit
    cmp word [block_buffer + _elf_header_32.machine], ELF_HEADER_MACHINE_AMD_X86_64
    je .64_bit
    jmp .failure ; Impossible
.32_bit:
    mov dword [elf_is_64bit], 0
    push elf_header
    push block_buffer
    call elf_normalize_header
    add esp, 8
    jmp .valid_isa
.64_bit:
    mov dword [elf_is_64bit], 1
    push _elf_header_64_size
    push block_buffer
    push elf_header
    call memcpy
    add esp, 12
.valid_isa:
    call elf_parse_program_headers
    cmp eax, 0
    jnz .failure
    mov esi, elf_load_sections

    xor eax, eax
    jmp .exit
.failure:
    mov eax, 1
.exit:
    pop esi
    pop ebp
    ret

struc epph_local
    .offset: resb 8
    .count: resb 4
    .size: resb 4
    .index: resb 4
    .block: resb 4
    .block_offset: resb 4
    .construct_offset: resb 4
    .current: resb _elf_program_header_64_size
    .construct: resb _elf_program_header_64_size
endstruc
elf_parse_program_headers: ; int elf_parse_program_headers()
    push ebp
    mov ebp, esp
    push edi
    push esi
    sub esp, epph_local_size

    ; Setup the programs state
    mov eax, dword [elf_header + _elf_header_64.phoff]
    mov edx, dword [elf_header + _elf_header_64.phoff + 4]
    mov dword [esp + epph_local.offset], eax
    mov dword [esp + epph_local.offset + 4], edx

    xor eax, eax
    mov ax, word [elf_header + _elf_header_64.phnum]
    mov dword [esp + epph_local.count], eax
    mov ax, word [elf_header + _elf_header_64.phentsize]
    mov dword [esp + epph_local.size], eax
    mov dword [esp + epph_local.index], 0
    mov dword [esp + epph_local.construct_offset], 0

    mov edx, dword [esp + epph_local.offset + 4]
    mov eax, dword [esp + epph_local.offset]
    push edx
    push eax
    call ext4_byte_to_block
    add esp, 8
    mov dword [esp + epph_local.block], eax

    mov edx, dword [esp + epph_local.offset + 4]
    mov eax, dword [esp + epph_local.offset]
    push edx
    push eax
    call ext4_byte_to_block_offset
    add esp, 8
    mov dword [esp + epph_local.block_offset], eax

.read_block:
    mov eax, dword [esp + epph_local.block]
    push block_buffer
    push eax
    push ext4_kernel_inode
    call ext4_get_inode_block
    add esp, 12
.parse: ; ???
    cmp dword [esp + epph_local.construct_offset], 0
    jz .block_parse
    ; If a program header spans two blocks, finish reading that out here
.continue_parse:
    mov ecx, dword [esp + epph_local.size]
    sub ecx, dword [esp + epph_local.construct_offset]
    mov esi, block_buffer
    add esi, dword [esp + epph_local.block_offset]
    lea edi, dword [esp + epph_local.construct]
    add edi, dword [esp + epph_local.construct_offset]
    add dword [esp + epph_local.block_offset], ecx
    mov dword [esp + epph_local.construct_offset], 0
    push ecx
    push esi
    push edi
    call memcpy
    add esp, 12
    jmp .normalize_header
.block_parse:
    mov eax, dword [esp + epph_local.size]
    add eax, dword [esp + epph_local.block_offset]
    cmp eax, dword [ext4_block_size]
    jg .partial_read ; Program header spans two blocks. Handle specially
    mov ecx, dword [esp + epph_local.size]
    mov esi, block_buffer
    add esi, dword [esp + epph_local.block_offset]
    lea edi, dword [esp + epph_local.construct]
    add dword [esp + epph_local.block_offset], ecx
    push ecx
    push esi
    push edi
    call memcpy
    add esp, 12
    jmp .normalize_header
.partial_read:
    mov ecx, dword [ext4_block_size]
    sub ecx, dword [esp + epph_local.block_offset]
    mov esi, block_buffer
    add esi, dword [esp + epph_local.block_offset]
    lea edi, dword [esp + epph_local.construct]
    mov dword [esp + epph_local.construct_offset], ecx
    add dword [esp + epph_local.block_offset], ecx
    push ecx
    push esi
    push edi
    call memcpy
    add esp, 12
    jmp .block_inc
.normalize_header:
    lea esi, dword [esp + epph_local.construct]
    lea edi, dword [esp + epph_local.current]
    cmp dword [elf_is_64bit], 1
    je .copy_64bit
    push edi
    push esi
    call elf_normalize_program_header
    add esp, 8
    jmp .parse_header
.copy_64bit:
    mov ecx, dword [esp + epph_local.size]
    push ecx
    push esi
    push edi
    call memcpy
    add esp, 12
.parse_header:
    mov eax, dword [esp + epph_local.current + _elf_program_header_64.offset]
    or eax, dword [esp + epph_local.current + _elf_program_header_64.offset + 4]
    cmp eax, 0
    je .block_offset_inc ; Offset of 0 in the file doesn't make sense
    mov eax, dword [esp + epph_local.current + _elf_program_header_64.filesz]
    or eax, dword [esp + epph_local.current + _elf_program_header_64.filesz + 4]
    cmp eax, 0
    je .block_offset_inc ; Don't care about segments that we don't have to load
    ; Only care about loadable segments?
    cmp dword [esp + epph_local.current + _elf_program_header_64.type], ELF_PROGRAM_HEADER_TYPE_LOAD
    jne .block_offset_inc
.save_header:
    lea esi, dword [esp + epph_local.current]
    mov eax, dword [elf_load_sections_count]
    mov edx, _elf_program_header_64_size
    mul edx
    lea edi, dword [elf_load_sections + eax]
    push _elf_program_header_64_size
    push esi
    push edi
    call memcpy
    add esp, 12
    add dword [elf_load_sections_count], 1
    cmp dword [elf_load_sections_count], ELF_LOAD_SECTIONS_MAX
    jge .exit ; Done searching if we've run out of room to load sections
.block_offset_inc:
    add dword [esp + epph_local.index], 1
    mov eax, dword [esp + epph_local.count]
    cmp dword [esp + epph_local.index], eax
    jge .exit ; We've run out of sections to scan.
    mov eax, dword [ext4_block_size]
    cmp dword [esp + epph_local.block_offset], eax
    jl .block_parse
.block_inc:
    add dword [esp + epph_local.block], 1
    mov dword [esp + epph_local.block_offset], 0
    jmp .read_block
.exit:
    xor eax, eax
    add esp, epph_local_size
    pop edi
    pop esi
    pop ebp
    ret

elf_normalize_header: ; int elf_normalize_header(struct elf_header_32 *input, struct elf_header_64 *output)
    push ebp
    mov ebp, esp
    push esi
    push edi

    mov esi, dword [ebp + 8]
    mov edi, dword [ebp + 12]

    ; The structures are the same up until this point
    push _elf_header_64.entry ; copy up until the entry
    push esi
    push edi
    call memcpy
    add esp, 12

    ; Copy the differing fields
    mov eax, dword [esi + _elf_header_32.entry]
    mov dword [edi + _elf_header_64.entry], eax
    mov dword [edi + _elf_header_64.entry + 4], 0
    mov eax, dword [esi + _elf_header_32.phoff]
    mov dword [edi + _elf_header_64.phoff], eax
    mov dword [edi + _elf_header_64.phoff + 4], 0
    mov eax, dword [esi + _elf_header_32.shoff]
    mov dword [edi + _elf_header_64.shoff], eax
    mov dword [edi + _elf_header_64.shoff + 4], 0

    ; Copy the footer over (they're the same)
    add esi, _elf_header_32.flags
    add edi, _elf_header_64.flags

    push _elf_header_64_size - _elf_header_64.flags
    push esi
    push edi
    call memcpy
    add esp, 12

    xor eax, eax
    pop edi
    pop esi
    pop ebp
    ret

elf_normalize_program_header: ; int elf_normalize_program_header(struct elf_program_header_32 *input, struct elf_program_header_64 *output)
    push ebp
    mov ebp, esp
    push esi
    push edi
    
    mov esi, dword [ebp + 8]
    mov edi, dword [ebp + 12]

    mov eax, dword [esi + _elf_program_header_32.type]
    mov dword [edi + _elf_program_header_64.type], eax
    mov eax, dword [esi + _elf_program_header_32.flags]
    mov dword [edi + _elf_program_header_64.flags], eax

    mov eax, dword [esi + _elf_program_header_32.offset]
    mov dword [edi + _elf_program_header_64.offset], eax
    mov dword [edi + _elf_program_header_64.offset + 4], 0
    mov eax, dword [esi + _elf_program_header_32.vaddr]
    mov dword [edi + _elf_program_header_64.vaddr], eax
    mov dword [edi + _elf_program_header_64.vaddr + 4], 0
    mov eax, dword [esi + _elf_program_header_32.paddr]
    mov dword [edi + _elf_program_header_64.paddr], eax
    mov dword [edi + _elf_program_header_64.paddr + 4], 0
    mov eax, dword [esi + _elf_program_header_32.filesz]
    mov dword [edi + _elf_program_header_64.filesz], eax
    mov dword [edi + _elf_program_header_64.filesz + 4], 0
    mov eax, dword [esi + _elf_program_header_32.memsz]
    mov dword [edi + _elf_program_header_64.memsz], eax
    mov dword [edi + _elf_program_header_64.memsz + 4], 0
    mov eax, dword [esi + _elf_program_header_32.align]
    mov dword [edi + _elf_program_header_64.align], eax
    mov dword [edi + _elf_program_header_64.align + 4], 0

    xor eax, eax
    pop edi
    pop esi
    pop ebp
    ret
