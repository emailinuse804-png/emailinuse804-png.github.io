# CursorOS

A minimal, bootable operating system built from scratch in x86 assembly and C. CursorOS boots on real hardware or in a VM, provides an interactive shell with built-in commands, and produces a standard ISO image you can burn to a USB drive or CD.

## Features

- **Multiboot-compliant kernel** - boots via GRUB2
- **Protected mode** with GDT (Global Descriptor Table)
- **Interrupt handling** with IDT, PIC remapping, ISR/IRQ handlers
- **VGA text mode driver** (80x25, 16 colors)
- **PS/2 keyboard driver** with US layout, shift, caps lock, Ctrl shortcuts
- **PIT timer** at 100 Hz for timekeeping and sleep
- **Heap memory manager** with `kmalloc`/`kfree` (4MB heap, first-fit allocator)
- **Interactive shell** with 15+ built-in commands
- **Bootable ISO image** (~5 MB)

## Shell Commands

| Command    | Description                         |
|------------|-------------------------------------|
| `help`     | Show all available commands         |
| `clear`    | Clear the screen                    |
| `echo`     | Print text to the screen            |
| `version`  | Show OS version and ASCII logo      |
| `uptime`   | Show system uptime                  |
| `meminfo`  | Show heap memory usage with bar     |
| `color`    | Display all 16 VGA color samples    |
| `history`  | Show command history                |
| `calc`     | Calculator (`calc 5 + 3`)           |
| `sysinfo`  | Show detailed system information    |
| `cowsay`   | ASCII cow says your message         |
| `matrix`   | Matrix-style rain animation         |
| `panic`    | Trigger a fake kernel panic (safe)  |
| `reboot`   | Reboot the system                   |
| `halt`     | Halt the system                     |

**Keyboard shortcuts:** `Ctrl+L` = clear screen, `Ctrl+C` = cancel input

## Building

### Prerequisites

You need a Linux system (or WSL) with these packages:

```bash
# Debian/Ubuntu
sudo apt install nasm gcc grub-pc-bin grub-common xorriso mtools make

# Arch Linux
sudo pacman -S nasm gcc grub xorriso mtools make

# Fedora
sudo dnf install nasm gcc grub2-tools xorriso mtools make
```

### Build the ISO

```bash
cd os
make
```

This produces `CursorOS.iso` in the `os/` directory.

### Clean build artifacts

```bash
make clean
```

## Running

### In QEMU (recommended for testing)

```bash
# Install QEMU if needed
sudo apt install qemu-system-x86

# Run the OS
make run
# or directly:
qemu-system-i386 -cdrom CursorOS.iso -m 128M
```

### In VirtualBox

1. Create a new VM (Type: Other, Version: Other/Unknown)
2. Allocate at least 64 MB RAM
3. Skip the hard disk step
4. Go to Settings > Storage > Add Optical Drive
5. Choose `CursorOS.iso`
6. Start the VM

### On Real Hardware

```bash
# Write to a USB drive (replace /dev/sdX with your USB device!)
sudo dd if=CursorOS.iso of=/dev/sdX bs=4M status=progress
sync
```

Then boot from the USB drive in your BIOS/UEFI boot menu (Legacy/CSM boot mode required).

## Project Structure

```
os/
├── boot/
│   ├── boot.asm          # Multiboot entry point, stack setup
│   ├── gdt.asm           # GDT load routine
│   └── interrupt.asm     # ISR/IRQ assembly stubs
├── kernel/
│   ├── kernel.c          # Kernel main - initialization sequence
│   ├── gdt.c             # GDT configuration (flat memory model)
│   ├── idt.c             # IDT setup, PIC remapping, handler dispatch
│   ├── memory.c          # Heap allocator (kmalloc/kfree)
│   └── shell.c           # Interactive shell with commands
├── drivers/
│   ├── vga.c             # VGA text mode (80x25) driver
│   ├── keyboard.c        # PS/2 keyboard driver
│   └── timer.c           # PIT (Programmable Interval Timer) driver
├── lib/
│   └── string.c          # String/memory utilities (strlen, memcpy, etc.)
├── include/
│   ├── types.h           # uint8_t, uint32_t, bool, NULL, etc.
│   ├── io.h              # Port I/O (inb/outb)
│   ├── vga.h             # VGA driver API
│   ├── keyboard.h        # Keyboard driver API
│   ├── gdt.h             # GDT structures
│   ├── idt.h             # IDT structures + interrupt registers
│   ├── timer.h           # Timer API
│   ├── memory.h          # Memory manager API
│   ├── string.h          # String utilities API
│   └── shell.h           # Shell API
├── iso/
│   └── boot/grub/
│       └── grub.cfg      # GRUB bootloader configuration
├── linker.ld             # Kernel linker script (loads at 1MB)
├── Makefile              # Build system
└── README.md             # This file
```

## Architecture

```
┌─────────────┐
│    Shell     │  User-facing interactive command line
├─────────────┤
│   Keyboard  │  PS/2 keyboard driver (IRQ1)
│    Timer    │  PIT timer driver (IRQ0)
│     VGA     │  Text mode display driver
├─────────────┤
│   Memory    │  Heap allocator (kmalloc/kfree)
│   String    │  Standard library functions
├─────────────┤
│  IDT + PIC  │  Interrupt handling infrastructure
│     GDT     │  Memory segmentation (flat model)
├─────────────┤
│  Bootloader │  Multiboot entry + stack setup
├─────────────┤
│    GRUB2    │  Bootloader (loads kernel from ISO)
└─────────────┘
```

## Technical Details

- **Boot process:** BIOS -> GRUB2 -> Multiboot header -> `boot.asm` -> `kernel_main()`
- **Memory model:** Flat 4GB segments (code + data) via GDT
- **Interrupts:** 8259 PIC remapped to INT 32-47, 32 CPU exception handlers
- **Display:** Direct VGA text buffer writes at `0xB8000`
- **Input:** Scan code translation with shift/caps lock/ctrl support
- **Heap:** Starts at 2MB, 4MB size, first-fit with block coalescing

## License

MIT License - feel free to use, modify, and learn from this code.

## Credits

Built entirely with [Cursor AI](https://cursor.sh).
