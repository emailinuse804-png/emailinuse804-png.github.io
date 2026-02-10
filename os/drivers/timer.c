/* ============================================================================
 * CursorOS - Programmable Interval Timer (PIT) Driver
 * ============================================================================
 * Configures the PIT (Intel 8253/8254) for periodic interrupts.
 * Used for timekeeping and sleeping.
 * ============================================================================ */

#include "../include/timer.h"
#include "../include/io.h"
#include "../include/idt.h"

/* PIT I/O ports */
#define PIT_CHANNEL0 0x40
#define PIT_COMMAND  0x43
#define PIT_FREQUENCY 1193180  /* Base PIT frequency in Hz */

/* Tick counter */
static volatile uint32_t tick_count = 0;
static uint32_t timer_freq = 0;

/* Timer IRQ handler */
static void timer_callback(registers_t *regs) {
    (void)regs;
    tick_count++;
}

void timer_init(uint32_t frequency) {
    timer_freq = frequency;
    tick_count = 0;

    /* Register the timer callback */
    register_interrupt_handler(32, timer_callback); /* IRQ0 = interrupt 32 */

    /* Calculate the PIT divisor */
    uint32_t divisor = PIT_FREQUENCY / frequency;

    /* Send the command byte: channel 0, lobyte/hibyte, rate generator */
    outb(PIT_COMMAND, 0x36);

    /* Send the divisor (low byte first, then high byte) */
    outb(PIT_CHANNEL0, (uint8_t)(divisor & 0xFF));
    outb(PIT_CHANNEL0, (uint8_t)((divisor >> 8) & 0xFF));
}

uint32_t timer_get_ticks(void) {
    return tick_count;
}

void timer_sleep(uint32_t ms) {
    uint32_t target = tick_count + (ms * timer_freq / 1000);
    while (tick_count < target) {
        __asm__ volatile("hlt");
    }
}
