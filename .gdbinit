target remote localhost:1234
set disassembly-flavor att
add-symbol-file mbr/stage1.elf 0x7C00
add-symbol-file mbr/stage2.elf 0x500
b stage1
b stage2
layout reg
