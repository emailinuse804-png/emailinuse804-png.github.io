/* ============================================================================
 * CursorOS - I/O Port Operations
 * ============================================================================
 * Inline assembly wrappers for x86 port I/O instructions.
 * ============================================================================ */

#ifndef IO_H
#define IO_H

#include "types.h"

/* Read a byte from an I/O port */
static inline uint8_t inb(uint16_t port) {
    uint8_t result;
    __asm__ volatile("inb %1, %0" : "=a"(result) : "Nd"(port));
    return result;
}

/* Write a byte to an I/O port */
static inline void outb(uint16_t port, uint8_t val) {
    __asm__ volatile("outb %0, %1" : : "a"(val), "Nd"(port));
}

/* Read a word (16-bit) from an I/O port */
static inline uint16_t inw(uint16_t port) {
    uint16_t result;
    __asm__ volatile("inw %1, %0" : "=a"(result) : "Nd"(port));
    return result;
}

/* Write a word (16-bit) to an I/O port */
static inline void outw(uint16_t port, uint16_t val) {
    __asm__ volatile("outw %0, %1" : : "a"(val), "Nd"(port));
}

/* I/O wait (small delay for slow devices) */
static inline void io_wait(void) {
    __asm__ volatile("outb %%al, $0x80" : : "a"(0));
}

#endif /* IO_H */
