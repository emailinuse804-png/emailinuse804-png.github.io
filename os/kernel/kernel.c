/* ============================================================================
 * CursorOS - Kernel Main
 * ============================================================================
 * This is the main entry point of the kernel, called from boot.asm after
 * the Multiboot bootloader hands off control.
 *
 * Initialization order:
 *   1. GDT (Global Descriptor Table) - memory segmentation
 *   2. IDT (Interrupt Descriptor Table) - interrupt handling
 *   3. VGA (Video Graphics Array) - text output
 *   4. Timer (PIT) - system clock
 *   5. Keyboard - user input
 *   6. Memory Manager - heap allocation
 *   7. Shell - interactive command line
 * ============================================================================ */

#include "../include/types.h"
#include "../include/vga.h"
#include "../include/gdt.h"
#include "../include/idt.h"
#include "../include/timer.h"
#include "../include/keyboard.h"
#include "../include/memory.h"
#include "../include/shell.h"

/* Kernel entry point - called from boot.asm */
void kernel_main(uint32_t magic, uint32_t mboot_info) {
    (void)magic;
    (void)mboot_info;

    /* ================================================================
     * Phase 1: Core CPU Setup
     * ================================================================ */

    /* Initialize the Global Descriptor Table */
    gdt_init();

    /* Initialize the Interrupt Descriptor Table + PIC */
    idt_init();

    /* ================================================================
     * Phase 2: Hardware Drivers
     * ================================================================ */

    /* Initialize VGA text mode display */
    vga_init();

    /* Show boot splash */
    vga_set_color(VGA_LIGHT_CYAN, VGA_BLACK);
    vga_println("  ______                           ____  _____");
    vga_println(" / ____/_  _______________  _____/ __ \\/ ___/");
    vga_println("/ /   / / / / ___/ ___/ _ \\/ ___/ / / /\\__ \\ ");
    vga_println("/ /___/ /_/ / /  (__  ) __/ /  / /_/ /___/ / ");
    vga_println("\\____/\\__,_/_/  /____/\\___/_/   \\____//____/  ");
    vga_println("");
    vga_set_color(VGA_LIGHT_GREY, VGA_BLACK);

    vga_print("[");
    vga_print_colored("BOOT", VGA_LIGHT_GREEN, VGA_BLACK);
    vga_println("] CursorOS v1.0.0 starting...");

    /* Initialize PIT timer at 100 Hz */
    vga_print("[");
    vga_print_colored(" OK ", VGA_LIGHT_GREEN, VGA_BLACK);
    vga_println("] Programmable Interval Timer (100 Hz)");
    timer_init(100);

    /* Initialize keyboard driver */
    vga_print("[");
    vga_print_colored(" OK ", VGA_LIGHT_GREEN, VGA_BLACK);
    vga_println("] PS/2 Keyboard Driver");
    keyboard_init();

    /* ================================================================
     * Phase 3: Memory Management
     * ================================================================ */
    vga_print("[");
    vga_print_colored(" OK ", VGA_LIGHT_GREEN, VGA_BLACK);
    vga_print("] Memory Manager (");
    memory_init();
    vga_print_dec(memory_get_total() / 1024);
    vga_println(" KB heap)");

    /* ================================================================
     * Phase 4: Enable Interrupts
     * ================================================================ */
    vga_print("[");
    vga_print_colored(" OK ", VGA_LIGHT_GREEN, VGA_BLACK);
    vga_println("] Interrupts enabled");
    __asm__ volatile("sti");

    /* ================================================================
     * Phase 5: Launch Shell
     * ================================================================ */
    vga_print("[");
    vga_print_colored(" OK ", VGA_LIGHT_GREEN, VGA_BLACK);
    vga_println("] All systems go!");

    /* Hand off to the interactive shell */
    shell_run();

    /* Should never reach here */
    vga_println("FATAL: Shell exited unexpectedly.");
    for (;;) {
        __asm__ volatile("hlt");
    }
}
