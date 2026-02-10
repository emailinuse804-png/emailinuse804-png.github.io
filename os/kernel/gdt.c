/* ============================================================================
 * CursorOS - Global Descriptor Table Implementation
 * ============================================================================
 * Sets up the GDT with a flat memory model:
 *   - Null segment
 *   - Kernel code segment (ring 0)
 *   - Kernel data segment (ring 0)
 * ============================================================================ */

#include "../include/gdt.h"

/* 3 GDT entries: null, kernel code, kernel data */
#define GDT_ENTRIES 3

static struct gdt_entry gdt[GDT_ENTRIES];
static struct gdt_ptr gdt_descriptor;

/* Set a GDT entry */
static void gdt_set_gate(int num, uint32_t base, uint32_t limit,
                          uint8_t access, uint8_t gran) {
    gdt[num].base_low    = (base & 0xFFFF);
    gdt[num].base_middle = (base >> 16) & 0xFF;
    gdt[num].base_high   = (base >> 24) & 0xFF;
    gdt[num].limit_low   = (limit & 0xFFFF);
    gdt[num].granularity  = ((limit >> 16) & 0x0F) | (gran & 0xF0);
    gdt[num].access      = access;
}

void gdt_init(void) {
    gdt_descriptor.limit = (sizeof(struct gdt_entry) * GDT_ENTRIES) - 1;
    gdt_descriptor.base  = (uint32_t)&gdt;

    /* Null segment */
    gdt_set_gate(0, 0, 0, 0, 0);

    /* Kernel code segment: base=0, limit=4GB, executable, readable, ring 0 */
    gdt_set_gate(1, 0, 0xFFFFFFFF, 0x9A, 0xCF);

    /* Kernel data segment: base=0, limit=4GB, writable, ring 0 */
    gdt_set_gate(2, 0, 0xFFFFFFFF, 0x92, 0xCF);

    /* Load the new GDT */
    gdt_flush((uint32_t)&gdt_descriptor);
}
