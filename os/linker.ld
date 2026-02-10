/* ============================================================================
 * CursorOS - Linker Script
 * ============================================================================
 * Defines the memory layout of the kernel binary.
 * The kernel is loaded at 1MB (0x100000) by GRUB.
 * ============================================================================ */

ENTRY(_start)

SECTIONS
{
    /* Start at 1MB - standard location for kernels loaded by GRUB */
    . = 1M;

    /* Multiboot header must be very early in the binary */
    .multiboot ALIGN(4K) :
    {
        *(.multiboot)
    }

    /* Code section */
    .text ALIGN(4K) :
    {
        *(.text)
    }

    /* Read-only data */
    .rodata ALIGN(4K) :
    {
        *(.rodata)
        *(.rodata.*)
    }

    /* Initialized data */
    .data ALIGN(4K) :
    {
        *(.data)
    }

    /* Uninitialized data (BSS) */
    .bss ALIGN(4K) :
    {
        *(COMMON)
        *(.bss)
    }

    /* Discard unnecessary sections */
    /DISCARD/ :
    {
        *(.eh_frame)
        *(.comment)
        *(.note.*)
    }
}
