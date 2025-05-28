bits 32

section .data:

global strings
strings:
global .newline
.newline: db `\n`, 0
global .hex_prefix
.hex_prefix: db "0x", 0
global .ident
.ident: db `Stage2 Bootloader\n`, 0
global .active_partition
.active_partition: db `Active partition start sector: `, 0
global .active_partition_error
.active_partition_error: db `No active partition found\n`, 0
