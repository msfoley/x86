%ifndef ELF_ASM_INC
%define ELF_ASM_INC

; ELF header

struc _elf_header_32
    .ident_magic: resb 4 ; 0x7F 0x45 0x4C 0x46
    .ident_class: resb 1 ; 1 for 32-bit, 2 for 64-bit
    .ident_data: resb 1 ; 1 for LE, 2 for BE
    .ident_version: resb 1 ; ELF version (1?)
    .ident_osabi: resb 1 ; OS ABI version. See below
    .ident_abiversion: resb 1 ; ABI version - depends on OS ABI
    .ident_pad: resb 7 ; Unused padding
    .type: resb 2 ; Object file type
    .machine: resb 2 ; Target ISA
    .version: resb 4 ; ELF version (1?)
    .entry: resb 4 ; Entry point address
    .phoff: resb 4 ; Program header table offset
    .shoff: resb 4 ; Section header table offset
    .flags: resb 4 ; Flags dependent on target ISA
    .ehsize: resb 2 ; Size of a program header table entry
    .phnum: resb 2 ; Number of entries in the program header table
    .shentsize: resb 2 ; Size of a section header table entry
    .shnum: resb 2 ; Number of entries in the section header table
    .shstrndx: resb 2 ; Index of section header table entry containing section names
endstruc

struc _elf_header_64
    .ident_magic: resb 4 ; 0x7F 0x45 0x4C 0x46
    .ident_class: resb 1 ; 1 for 32-bit, 2 for 64-bit
    .ident_data: resb 1 ; 1 for LE, 2 for BE
    .ident_version: resb 1 ; ELF version (1?)
    .ident_osabi: resb 1 ; OS ABI version. See below
    .ident_abiversion: resb 1 ; ABI version - depends on OS ABI
    .ident_pad: resb 7 ; Unused padding
    .type: resb 2 ; Object file type
    .machine: resb 2 ; Target ISA
    .version: resb 4 ; ELF version (1?)
    .entry: resb 8 ; Entry point address
    .phoff: resb 8 ; Program header table offset
    .shoff: resb 8 ; Section header table offset
    .flags: resb 4 ; Flags dependent on target ISA
    .ehsize: resb 2 ; Size of this header
    .phentsize: resb 2 ; Size of a program header table entry
    .phnum: resb 2 ; Number of entries in the program header table
    .shentsize: resb 2 ; Size of a section header table entry
    .shnum: resb 2 ; Number of entries in the section header table
    .shstrndx: resb 2 ; Index of section header table entry containing section names
endstruc

ELF_HEADER_IDENT_CLASS_32BIT equ 1
ELF_HEADER_IDENT_CLASS_64iBIT equ 2
ELF_HEADER_IDENT_DATA_LE equ 0x01
ELF_HEADER_IDENT_DATA_BE equ 0x02
ELF_HEADER_IDENT_VERSION equ 0x01

ELF_HEADER_TYPE_NONE equ 0x0000
ELF_HEADER_TYPE_REL equ 0x0001
ELF_HEADER_TYPE_EXEC equ 0x0002
ELF_HEADER_TYPE_DYN equ 0x0003
ELF_HEADER_TYPE_CORE equ 0x0004

ELF_HEADER_MACHINE_X86 equ 0x0003
ELF_HEADER_MACHINE_AMD_X86_64 equ 0x003E

; Program header 

struc _elf_program_header_32
    .type: resb 4 ; Segment type
    .offset: resb 4 ; Segment offset in file
    .vaddr: resb 4 ; Virtual address of segment
    .paddr: resb 4 ; Physical address of segment (if relevant)
    .filesz: resb 4 ; Size in bytes of the segment in the file
    .memsz: resb 4 ; Size in bytes of the segment in memory
    .flags: resb 4 ; Segment dependent flags
    .align: resb 4 ; Alignment
endstruc

struc _elf_program_header_64
    .type: resb 4 ; Segment type
    .flags: resb 4 ; Segment dependent flags
    .offset: resb 8 ; Segment offset in file
    .vaddr: resb 8 ; Virtual address of segment
    .paddr: resb 8 ; Physical address of segment (if relevant)
    .filesz: resb 8 ; Size in bytes of the segment in the file
    .memsz: resb 8 ; Size in bytes of the segment in memory
    .align: resb 8 ; Alignment
endstruc

ELF_PROGRAM_HEADER_TYPE_NULL equ 0x00000000
ELF_PROGRAM_HEADER_TYPE_LOAD equ 0x00000001
ELF_PROGRAM_HEADER_TYPE_DYNAMIC equ 0x00000002
ELF_PROGRAM_HEADER_TYPE_INTERP equ 0x00000003
ELF_PROGRAM_HEADER_TYPE_NOTE equ 0x00000004
ELF_PROGRAM_HEADER_TYPE_SHLIB equ 0x00000005
ELF_PROGRAM_HEADER_TYPE_PHDR equ 0x00000006
ELF_PROGRAM_HEADER_TYPE_TLS equ 0x00000007

ELF_PROGRAM_HEADER_FLAGS_X equ 0x01
ELF_PROGRAM_HEADER_FLAGS_W equ 0x02
ELF_PROGRAM_HEADER_FLAGS_R equ 0x04

%ifndef ELF_ASM_INC_NO_EXTERN
extern elf_init ; int elf_init()
%endif
%endif
