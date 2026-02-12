/* ============================================================================
 * CursorOS - Memory Management Header
 * ============================================================================ */

#ifndef MEMORY_H
#define MEMORY_H

#include "types.h"

/* Initialize the memory manager */
void memory_init(void);

/* Allocate a block of memory */
void *kmalloc(size_t size);

/* Free a block of memory */
void kfree(void *ptr);

/* Get total memory available */
uint32_t memory_get_total(void);

/* Get used memory */
uint32_t memory_get_used(void);

#endif /* MEMORY_H */
