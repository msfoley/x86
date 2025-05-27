target remote localhost:1234
b *0x7C00
b *0x10000
add-symbol-file mbr/stage1.elf 0x7C00
add-symbol-file mbr/stage2.elf 0x10000
layout reg
