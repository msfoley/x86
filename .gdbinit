target remote localhost:1234
b *0x7C00
b *0x10000
add-symbol-file boot/boot_sector.elf 0x7C00
add-symbol-file boot/boot_loader.elf 0x10000
