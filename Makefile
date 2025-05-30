SRC_DIR := src

MBR_DIR := mbr
MBR_IMAGE := $(MBR_DIR)/mbr.bin

DISK_IMAGE := disk.img
DISK_IMAGE_SIZE_MB := 16

QEMU_OPTS ?=
QEMU_ARGS := -drive media=disk,format=raw,file=$(DISK_IMAGE) -gdb tcp::1234 $(QEMU_OPTS)
ifeq ($(strip $(NO_STOP)),)
QEMU_ARGS += -S
endif

.PHONY: all clean mbr

all: $(MBR_IMAGE)

clean:
	$(MAKE) -C $(MBR_DIR) clean
	$(RM) $(DISK_IMAGE)

mbr:
	$(MAKE) -C $(MBR_DIR)

$(MBR_IMAGE): mbr

disk: $(DISK_IMAGE)

$(DISK_IMAGE): $(MBR_IMAGE)
	[ ! -f $(DISK_IMAGE) ] && dd if=/dev/zero of=$(DISK_IMAGE) bs=1M count=$(DISK_IMAGE_SIZE_MB) || true
	dd if=$(MBR_IMAGE) of=$(DISK_IMAGE) conv=notrunc status=none
	parted disk.img -- mkpart p ext4 1MiB -1s set 1 boot on

run: $(DISK_IMAGE)
	qemu-system-x86_64 $(QEMU_ARGS)

print-%:
	@echo "$* = $($*)"

print-mbr-%:
	$(MAKE) -C $(MBR_DIR) print-$*
