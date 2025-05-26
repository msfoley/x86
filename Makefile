CFLAGS += -Wall -Werror -ffreestanding -O0 -g

AFLAGS += -g -felf64

SRC_DIR := src
BOOT_DIR := boot

DISK_IMAGE := disk.img
DISK_IMAGE_SIZE_MB := 16

A_SRCS := $(shell find $(SRC_DIR) -name "*.asm")
A_OBJS := $(patsubst %.asm,%.o,$(A_SRCS))
C_SRCS := $(shell find $(SRC_DIR) -name "*.c")
C_OBJS := $(patsubst %.c,%.o,$(C_SRCS))

BOOT_SECTOR := $(BOOT_DIR)/boot_sector
BOOT_SECTOR_ELF := $(BOOT_SECTOR).elf
BOOT_SECTOR_SRC := $(BOOT_SECTOR).asm
BOOT_SECTOR_OBJ := $(BOOT_SECTOR).o
BOOT_SECTOR_LINKER := $(BOOT_SECTOR).ld

BOOT_LOADER := $(BOOT_DIR)/boot_loader
BOOT_LOADER_ELF := $(BOOT_LOADER).elf
BOOT_LOADER_SRC := $(BOOT_LOADER).asm
BOOT_LOADER_OBJ := $(BOOT_LOADER).o
BOOT_LOADER_LINKER := $(BOOT_LOADER).ld
BOOT_LOADER_OFFSET := 1

.PHONY: all clean

all: $(BOOT_SECTOR) $(BOOT_LOADER)

clean:
	$(RM) $(C_OBJS) $(A_OBJS)
	$(RM) $(BOOT_SECTOR) $(BOOT_SECTOR_OBJ) $(BOOT_SECTOR_ELF)
	$(RM) $(BOOT_LOADER) $(BOOT_LOADER_OBJ) $(BOOT_LOADER_ELF)
	$(RM) $(DISK_IMAGE)

disk: $(BOOT_SECTOR) $(BOOT_LOADER)
	dd if=/dev/zero of=$(DISK_IMAGE) bs=1M count=$(DISK_IMAGE_SIZE_MB) status=none
	dd if=$< of=$(DISK_IMAGE) bs=512 count=1 conv=notrunc status=none
	dd if=$(word 2,$^) of=$(DISK_IMAGE) bs=512 seek=$(BOOT_LOADER_OFFSET) conv=notrunc status=none
	perl -e "print pack('S', $(BOOT_LOADER_OFFSET))" | dd of=$(DISK_IMAGE) bs=1 seek=6 conv=notrunc status=none
	perl -e "print pack('S',  $$(s=$$(stat -c %s boot/boot_loader) ; echo $$(((s / 0x200) + ((s % 0x200) > 0)))))" | dd of=$(DISK_IMAGE) bs=1 seek=8 conv=notrunc status=none

run:
	qemu-system-x86_64 -drive media=disk,format=raw,file=$(DISK_IMAGE) -S -gdb tcp::1234

$(BOOT_SECTOR_ELF): $(BOOT_SECTOR_OBJ)
	ld -T $(BOOT_SECTOR_LINKER) $< -o $@

$(BOOT_SECTOR): $(BOOT_SECTOR_ELF)
	objcopy -O binary $< $@

$(BOOT_LOADER_ELF): $(BOOT_LOADER_OBJ)
	ld -T $(BOOT_LOADER_LINKER) $< -o $@

$(BOOT_LOADER): $(BOOT_LOADER_ELF)
	objcopy -O binary $< $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.asm
	nasm $(AFLAGS) $< -o $@
