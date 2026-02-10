# ============================================================================
# CursorOS - Build System
# ============================================================================
# Builds a bootable ISO image of CursorOS.
#
# Targets:
#   make          - Build the ISO image
#   make run      - Build and run in QEMU
#   make clean    - Remove build artifacts
#   make debug    - Build and run with QEMU debug output
# ============================================================================

# Tools
ASM      = nasm
CC       = gcc
LD       = ld
GRUB     = grub-mkrescue

# Directories
BOOT_DIR    = boot
KERNEL_DIR  = kernel
DRIVER_DIR  = drivers
LIB_DIR     = lib
INCLUDE_DIR = include
BUILD_DIR   = build
ISO_DIR     = iso

# Flags
ASMFLAGS = -f elf32
CFLAGS   = -m32 -ffreestanding -fno-exceptions -fno-stack-protector \
           -nostdlib -nodefaultlibs -Wall -Wextra -Werror -O2 \
           -I$(INCLUDE_DIR) -c
LDFLAGS  = -m elf_i386 -T linker.ld -nostdlib -z noexecstack

# Source files
ASM_SOURCES = $(BOOT_DIR)/boot.asm \
              $(BOOT_DIR)/gdt.asm \
              $(BOOT_DIR)/interrupt.asm

C_SOURCES = $(KERNEL_DIR)/kernel.c \
            $(KERNEL_DIR)/gdt.c \
            $(KERNEL_DIR)/idt.c \
            $(KERNEL_DIR)/memory.c \
            $(KERNEL_DIR)/shell.c \
            $(DRIVER_DIR)/vga.c \
            $(DRIVER_DIR)/keyboard.c \
            $(DRIVER_DIR)/timer.c \
            $(LIB_DIR)/string.c

# Object files
ASM_OBJECTS = $(patsubst %.asm,$(BUILD_DIR)/%.o,$(ASM_SOURCES))
C_OBJECTS   = $(patsubst %.c,$(BUILD_DIR)/%.o,$(C_SOURCES))
ALL_OBJECTS = $(ASM_OBJECTS) $(C_OBJECTS)

# Output
KERNEL_BIN = $(BUILD_DIR)/kernel.bin
ISO_IMAGE  = CursorOS.iso

# ============================================================================
# Build Targets
# ============================================================================

.PHONY: all clean run debug dirs

all: $(ISO_IMAGE)

# Create the ISO image
$(ISO_IMAGE): $(KERNEL_BIN)
	@echo "[ISO ] Creating bootable ISO image..."
	@cp $(KERNEL_BIN) $(ISO_DIR)/boot/kernel.bin
	@$(GRUB) -o $(ISO_IMAGE) $(ISO_DIR) 2>/dev/null
	@echo ""
	@echo "============================================"
	@echo "  CursorOS ISO built successfully!"
	@echo "  Output: $(ISO_IMAGE)"
	@echo "============================================"
	@echo ""
	@echo "  Run with: qemu-system-i386 -cdrom $(ISO_IMAGE)"
	@echo ""

# Link the kernel binary
$(KERNEL_BIN): dirs $(ALL_OBJECTS)
	@echo "[LINK] Linking kernel..."
	@$(LD) $(LDFLAGS) -o $(KERNEL_BIN) $(ALL_OBJECTS)
	@echo "[LINK] Kernel binary: $(KERNEL_BIN)"

# Compile assembly files
$(BUILD_DIR)/%.o: %.asm
	@mkdir -p $(dir $@)
	@echo "[ASM ] $<"
	@$(ASM) $(ASMFLAGS) $< -o $@

# Compile C files
$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	@echo "[ CC ] $<"
	@$(CC) $(CFLAGS) $< -o $@

# Create build directories
dirs:
	@mkdir -p $(BUILD_DIR)/$(BOOT_DIR)
	@mkdir -p $(BUILD_DIR)/$(KERNEL_DIR)
	@mkdir -p $(BUILD_DIR)/$(DRIVER_DIR)
	@mkdir -p $(BUILD_DIR)/$(LIB_DIR)

# Run in QEMU
run: $(ISO_IMAGE)
	@echo "[QEMU] Starting CursorOS..."
	@qemu-system-i386 -cdrom $(ISO_IMAGE) -m 128M

# Debug in QEMU (serial output)
debug: $(ISO_IMAGE)
	@echo "[QEMU] Starting CursorOS (debug mode)..."
	@qemu-system-i386 -cdrom $(ISO_IMAGE) -m 128M -serial stdio -d int,cpu_reset

# Clean build artifacts
clean:
	@echo "[CLEAN] Removing build artifacts..."
	@rm -rf $(BUILD_DIR)
	@rm -f $(ISO_IMAGE)
	@rm -f $(ISO_DIR)/boot/kernel.bin
	@echo "[CLEAN] Done."
