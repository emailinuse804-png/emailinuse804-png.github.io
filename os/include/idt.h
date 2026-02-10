/* ============================================================================
 * CursorOS - Interrupt Descriptor Table Header
 * ============================================================================ */

#ifndef IDT_H
#define IDT_H

#include "types.h"

/* IDT Entry structure */
struct idt_entry {
    uint16_t base_low;      /* Lower 16 bits of handler address */
    uint16_t sel;           /* Kernel segment selector */
    uint8_t  always0;       /* Always zero */
    uint8_t  flags;         /* Flags (type, privilege, present) */
    uint16_t base_high;     /* Upper 16 bits of handler address */
} __attribute__((packed));

/* IDT Pointer/Descriptor */
struct idt_ptr {
    uint16_t limit;
    uint32_t base;
} __attribute__((packed));

/* Register state pushed by interrupt handlers */
typedef struct {
    uint32_t ds;                                     /* Data segment */
    uint32_t edi, esi, ebp, esp, ebx, edx, ecx, eax; /* Pushed by pusha */
    uint32_t int_no, err_code;                        /* Interrupt number and error code */
    uint32_t eip, cs, eflags, useresp, ss;            /* Pushed by CPU */
} registers_t;

/* Callback type for interrupt handlers */
typedef void (*isr_t)(registers_t *);

/* Initialize the IDT */
void idt_init(void);

/* Register an interrupt handler */
void register_interrupt_handler(uint8_t n, isr_t handler);

/* Assembly function to load IDT */
extern void idt_flush(uint32_t);

/* ISR declarations (defined in interrupt.asm) */
extern void isr0(void);  extern void isr1(void);
extern void isr2(void);  extern void isr3(void);
extern void isr4(void);  extern void isr5(void);
extern void isr6(void);  extern void isr7(void);
extern void isr8(void);  extern void isr9(void);
extern void isr10(void); extern void isr11(void);
extern void isr12(void); extern void isr13(void);
extern void isr14(void); extern void isr15(void);
extern void isr16(void); extern void isr17(void);
extern void isr18(void); extern void isr19(void);
extern void isr20(void); extern void isr21(void);
extern void isr22(void); extern void isr23(void);
extern void isr24(void); extern void isr25(void);
extern void isr26(void); extern void isr27(void);
extern void isr28(void); extern void isr29(void);
extern void isr30(void); extern void isr31(void);

/* IRQ declarations */
extern void irq0(void);  extern void irq1(void);
extern void irq2(void);  extern void irq3(void);
extern void irq4(void);  extern void irq5(void);
extern void irq6(void);  extern void irq7(void);
extern void irq8(void);  extern void irq9(void);
extern void irq10(void); extern void irq11(void);
extern void irq12(void); extern void irq13(void);
extern void irq14(void); extern void irq15(void);

#endif /* IDT_H */
