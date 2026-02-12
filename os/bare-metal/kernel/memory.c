/* ============================================================================
 * CursorOS - Simple Heap Memory Manager
 * ============================================================================
 * A basic first-fit memory allocator. The heap starts after the kernel's
 * BSS section and grows upward.
 * ============================================================================ */

#include "../include/memory.h"
#include "../include/string.h"

/* Heap configuration */
#define HEAP_START  0x200000   /* 2MB - start of heap (after kernel) */
#define HEAP_SIZE   0x400000   /* 4MB heap */
#define BLOCK_MAGIC 0xDEADBEEF

/* Memory block header */
typedef struct block_header {
    uint32_t magic;              /* Magic number for validation */
    size_t size;                 /* Size of the data area (excluding header) */
    bool is_free;                /* Is this block free? */
    struct block_header *next;   /* Next block in the list */
} block_header_t;

static block_header_t *heap_start = NULL;
static uint32_t total_memory = HEAP_SIZE;
static uint32_t used_memory = 0;

void memory_init(void) {
    heap_start = (block_header_t *)HEAP_START;
    heap_start->magic = BLOCK_MAGIC;
    heap_start->size = HEAP_SIZE - sizeof(block_header_t);
    heap_start->is_free = true;
    heap_start->next = NULL;
    used_memory = 0;
}

void *kmalloc(size_t size) {
    if (size == 0) return NULL;

    /* Align to 4 bytes */
    size = (size + 3) & ~3;

    block_header_t *current = heap_start;

    /* First-fit search */
    while (current) {
        if (current->magic != BLOCK_MAGIC) {
            /* Heap corruption detected */
            return NULL;
        }

        if (current->is_free && current->size >= size) {
            /* Split the block if there's enough space left */
            if (current->size > size + sizeof(block_header_t) + 4) {
                block_header_t *new_block = (block_header_t *)((uint8_t *)(current + 1) + size);
                new_block->magic = BLOCK_MAGIC;
                new_block->size = current->size - size - sizeof(block_header_t);
                new_block->is_free = true;
                new_block->next = current->next;
                current->next = new_block;
                current->size = size;
            }

            current->is_free = false;
            used_memory += current->size;
            return (void *)(current + 1);
        }

        current = current->next;
    }

    return NULL; /* Out of memory */
}

void kfree(void *ptr) {
    if (!ptr) return;

    block_header_t *header = (block_header_t *)ptr - 1;

    if (header->magic != BLOCK_MAGIC) {
        return; /* Invalid pointer */
    }

    header->is_free = true;
    used_memory -= header->size;

    /* Coalesce with next block if it's free */
    if (header->next && header->next->is_free) {
        header->size += sizeof(block_header_t) + header->next->size;
        header->next = header->next->next;
    }

    /* Coalesce with previous block */
    block_header_t *prev = heap_start;
    while (prev && prev->next != header) {
        prev = prev->next;
    }
    if (prev && prev->is_free) {
        prev->size += sizeof(block_header_t) + header->size;
        prev->next = header->next;
    }
}

uint32_t memory_get_total(void) {
    return total_memory;
}

uint32_t memory_get_used(void) {
    return used_memory;
}
