/* ============================================================================
 * CursorOS - Interrupt Descriptor Table Implementation
 * ============================================================================
 * Sets up the IDT with 256 entries, programs the 8259 PIC, and provides
 * interrupt handler registration and dispatch.
 * ============================================================================ */

#include "../include/idt.h"
#include "../include/io.h"
#include "../include/vga.h"
#include "../include/string.h"

#define IDT_ENTRIES 256

/* PIC ports */
#define PIC1_COMMAND 0x20
#define PIC1_DATA    0x21
#define PIC2_COMMAND 0xA0
#define PIC2_DATA    0xA1

static struct idt_entry idt[IDT_ENTRIES];
static struct idt_ptr idt_descriptor;

/* Array of interrupt handlers */
static isr_t interrupt_handlers[IDT_ENTRIES];

/* Exception names for debugging */
static const char *exception_names[] = {
    "Division By Zero",
    "Debug",
    "Non Maskable Interrupt",
    "Breakpoint",
    "Overflow",
    "Bound Range Exceeded",
    "Invalid Opcode",
    "Device Not Available",
    "Double Fault",
    "Coprocessor Segment Overrun",
    "Invalid TSS",
    "Segment Not Present",
    "Stack-Segment Fault",
    "General Protection Fault",
    "Page Fault",
    "Reserved",
    "x87 FPU Error",
    "Alignment Check",
    "Machine Check",
    "SIMD Floating Point",
    "Virtualization Exception",
};

/* Set an IDT gate */
static void idt_set_gate(uint8_t num, uint32_t base, uint16_t sel, uint8_t flags) {
    idt[num].base_low  = base & 0xFFFF;
    idt[num].base_high = (base >> 16) & 0xFFFF;
    idt[num].sel       = sel;
    idt[num].always0   = 0;
    idt[num].flags     = flags;
}

/* Remap the Programmable Interrupt Controller (8259 PIC) */
static void pic_remap(void) {
    /* Save masks */
    uint8_t mask1 = inb(PIC1_DATA);
    uint8_t mask2 = inb(PIC2_DATA);

    /* Start initialization sequence (ICW1) */
    outb(PIC1_COMMAND, 0x11); io_wait();
    outb(PIC2_COMMAND, 0x11); io_wait();

    /* ICW2: Set interrupt vector offsets */
    outb(PIC1_DATA, 0x20);   io_wait(); /* IRQ 0-7  -> INT 32-39 */
    outb(PIC2_DATA, 0x28);   io_wait(); /* IRQ 8-15 -> INT 40-47 */

    /* ICW3: Tell Master PIC there's a slave at IRQ2 */
    outb(PIC1_DATA, 0x04);   io_wait();
    outb(PIC2_DATA, 0x02);   io_wait();

    /* ICW4: 8086 mode */
    outb(PIC1_DATA, 0x01);   io_wait();
    outb(PIC2_DATA, 0x01);   io_wait();

    /* Restore masks */
    outb(PIC1_DATA, mask1);
    outb(PIC2_DATA, mask2);
}

void idt_init(void) {
    idt_descriptor.limit = (sizeof(struct idt_entry) * IDT_ENTRIES) - 1;
    idt_descriptor.base  = (uint32_t)&idt;

    memset(&idt, 0, sizeof(struct idt_entry) * IDT_ENTRIES);
    memset(&interrupt_handlers, 0, sizeof(isr_t) * IDT_ENTRIES);

    /* Remap the PIC */
    pic_remap();

    /* Set up ISR gates (CPU exceptions) */
    idt_set_gate(0,  (uint32_t)isr0,  0x08, 0x8E);
    idt_set_gate(1,  (uint32_t)isr1,  0x08, 0x8E);
    idt_set_gate(2,  (uint32_t)isr2,  0x08, 0x8E);
    idt_set_gate(3,  (uint32_t)isr3,  0x08, 0x8E);
    idt_set_gate(4,  (uint32_t)isr4,  0x08, 0x8E);
    idt_set_gate(5,  (uint32_t)isr5,  0x08, 0x8E);
    idt_set_gate(6,  (uint32_t)isr6,  0x08, 0x8E);
    idt_set_gate(7,  (uint32_t)isr7,  0x08, 0x8E);
    idt_set_gate(8,  (uint32_t)isr8,  0x08, 0x8E);
    idt_set_gate(9,  (uint32_t)isr9,  0x08, 0x8E);
    idt_set_gate(10, (uint32_t)isr10, 0x08, 0x8E);
    idt_set_gate(11, (uint32_t)isr11, 0x08, 0x8E);
    idt_set_gate(12, (uint32_t)isr12, 0x08, 0x8E);
    idt_set_gate(13, (uint32_t)isr13, 0x08, 0x8E);
    idt_set_gate(14, (uint32_t)isr14, 0x08, 0x8E);
    idt_set_gate(15, (uint32_t)isr15, 0x08, 0x8E);
    idt_set_gate(16, (uint32_t)isr16, 0x08, 0x8E);
    idt_set_gate(17, (uint32_t)isr17, 0x08, 0x8E);
    idt_set_gate(18, (uint32_t)isr18, 0x08, 0x8E);
    idt_set_gate(19, (uint32_t)isr19, 0x08, 0x8E);
    idt_set_gate(20, (uint32_t)isr20, 0x08, 0x8E);
    idt_set_gate(21, (uint32_t)isr21, 0x08, 0x8E);
    idt_set_gate(22, (uint32_t)isr22, 0x08, 0x8E);
    idt_set_gate(23, (uint32_t)isr23, 0x08, 0x8E);
    idt_set_gate(24, (uint32_t)isr24, 0x08, 0x8E);
    idt_set_gate(25, (uint32_t)isr25, 0x08, 0x8E);
    idt_set_gate(26, (uint32_t)isr26, 0x08, 0x8E);
    idt_set_gate(27, (uint32_t)isr27, 0x08, 0x8E);
    idt_set_gate(28, (uint32_t)isr28, 0x08, 0x8E);
    idt_set_gate(29, (uint32_t)isr29, 0x08, 0x8E);
    idt_set_gate(30, (uint32_t)isr30, 0x08, 0x8E);
    idt_set_gate(31, (uint32_t)isr31, 0x08, 0x8E);

    /* Set up IRQ gates (hardware interrupts) */
    idt_set_gate(32, (uint32_t)irq0,  0x08, 0x8E);
    idt_set_gate(33, (uint32_t)irq1,  0x08, 0x8E);
    idt_set_gate(34, (uint32_t)irq2,  0x08, 0x8E);
    idt_set_gate(35, (uint32_t)irq3,  0x08, 0x8E);
    idt_set_gate(36, (uint32_t)irq4,  0x08, 0x8E);
    idt_set_gate(37, (uint32_t)irq5,  0x08, 0x8E);
    idt_set_gate(38, (uint32_t)irq6,  0x08, 0x8E);
    idt_set_gate(39, (uint32_t)irq7,  0x08, 0x8E);
    idt_set_gate(40, (uint32_t)irq8,  0x08, 0x8E);
    idt_set_gate(41, (uint32_t)irq9,  0x08, 0x8E);
    idt_set_gate(42, (uint32_t)irq10, 0x08, 0x8E);
    idt_set_gate(43, (uint32_t)irq11, 0x08, 0x8E);
    idt_set_gate(44, (uint32_t)irq12, 0x08, 0x8E);
    idt_set_gate(45, (uint32_t)irq13, 0x08, 0x8E);
    idt_set_gate(46, (uint32_t)irq14, 0x08, 0x8E);
    idt_set_gate(47, (uint32_t)irq15, 0x08, 0x8E);

    /* Load the IDT */
    idt_flush((uint32_t)&idt_descriptor);
}

void register_interrupt_handler(uint8_t n, isr_t handler) {
    interrupt_handlers[n] = handler;
}

/* Called from assembly ISR stub */
void isr_handler(registers_t regs) {
    if (interrupt_handlers[regs.int_no]) {
        interrupt_handlers[regs.int_no](&regs);
    } else {
        vga_print_colored("\n!!! CPU EXCEPTION: ", VGA_LIGHT_RED, VGA_BLACK);
        if (regs.int_no < 21) {
            vga_print_colored(exception_names[regs.int_no], VGA_YELLOW, VGA_BLACK);
        } else {
            vga_print("Unknown Exception");
        }
        vga_print(" (int ");
        vga_print_dec(regs.int_no);
        vga_print(", err ");
        vga_print_hex(regs.err_code);
        vga_println(")");
        vga_println("System halted.");
        for(;;) __asm__ volatile("hlt");
    }
}

/* Called from assembly IRQ stub */
void irq_handler(registers_t regs) {
    /* Send End of Interrupt (EOI) to PIC */
    if (regs.int_no >= 40) {
        outb(PIC2_COMMAND, 0x20); /* EOI to slave PIC */
    }
    outb(PIC1_COMMAND, 0x20);     /* EOI to master PIC */

    /* Call the registered handler */
    if (interrupt_handlers[regs.int_no]) {
        interrupt_handlers[regs.int_no](&regs);
    }
}
