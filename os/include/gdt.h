/* ============================================================================
 * CursorOS - Global Descriptor Table Header
 * ============================================================================ */

#ifndef GDT_H
#define GDT_H

#include "types.h"

/* GDT Entry structure */
struct gdt_entry {
    uint16_t limit_low;     /* Lower 16 bits of the limit */
    uint16_t base_low;      /* Lower 16 bits of the base */
    uint8_t  base_middle;   /* Next 8 bits of the base */
    uint8_t  access;        /* Access flags */
    uint8_t  granularity;   /* Granularity + upper 4 bits of limit */
    uint8_t  base_high;     /* Last 8 bits of the base */
} __attribute__((packed));

/* GDT Pointer/Descriptor */
struct gdt_ptr {
    uint16_t limit;         /* Size of GDT - 1 */
    uint32_t base;          /* Address of first GDT entry */
} __attribute__((packed));

/* Initialize the GDT */
void gdt_init(void);

/* Assembly function to load GDT */
extern void gdt_flush(uint32_t);

#endif /* GDT_H */
