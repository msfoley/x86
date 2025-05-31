MBR_IMAGE := mbr.bin

AFLAGS += -g -felf64 -F dwarf
LDFLAGS += --print-memory-usage

STAGE1_NAME := stage1
STAGE1_DIR := $(STAGE1_NAME)
STAGE1_SRCS := $(shell find $(STAGE1_DIR) -name "*.asm")
STAGE1_OBJS := $(patsubst %.asm,%.o,$(STAGE1_SRCS))
STAGE1_LINKER := $(STAGE1_DIR)/linker.ld
STAGE1_ELF := $(STAGE1_NAME).elf
STAGE1_BIN := $(STAGE1_NAME).bin

STAGE2_NAME := stage2
STAGE2_DIR := $(STAGE2_NAME)
STAGE2_SRCS := $(shell find $(STAGE2_DIR) -name "*.asm")
STAGE2_OBJS := $(patsubst %.asm,%.o,$(STAGE2_SRCS))
STAGE2_LINKER := $(STAGE2_DIR)/linker.ld
STAGE2_ELF := $(STAGE2_NAME).elf
STAGE2_BIN := $(STAGE2_NAME).bin
STAGE2_SECTOR_OFFSET=1

LISTINGS := $(patsubst %.asm,%.lst,$(STAGE1_SRCS) $(STAGE2_SRCS))

DEPS := $(patsubst %.asm,%.d,$(STAGE1_SRCS) $(STAGE2_SRCS))

.PHONY: all clean

all: $(MBR_IMAGE)

clean:
	$(RM) $(STAGE1_ELF) $(STAGE2_ELF)
	$(RM) $(STAGE1_BIN) $(STAGE2_BIN)
	$(RM) $(STAGE1_OBJS) $(STAGE2_OBJS)
	$(RM) $(DEPS)
	$(RM) $(MBR_IMAGE)
	$(RM) $(LISTINGS)

$(MBR_IMAGE): $(STAGE1_BIN) $(STAGE2_BIN)
	cat $^ > $@
	./set_stage1_info.sh $(STAGE1_ELF) $(STAGE2_BIN) $@ $(STAGE2_SECTOR_OFFSET)

$(STAGE1_ELF): $(STAGE1_LINKER) $(STAGE1_OBJS)
$(STAGE1_BIN): $(STAGE1_ELF)

$(STAGE2_ELF): $(STAGE2_LINKER) $(STAGE2_OBJS)
$(STAGE2_BIN): $(STAGE2_ELF)

%.o: %.asm
	nasm $(AFLAGS) -MD $*.d $< -l $*.lst -o $@

%.elf:
	$(LD) -T $(filter %.ld,$^) $(LDFLAGS) $(filter %.o,$^) -o $@ -Map=$*.map

%.bin: %.elf
	objcopy -O binary $< $@

print-%:
	@echo "$* = $($*)"

-include $(DEPS)
