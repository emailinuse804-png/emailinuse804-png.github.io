/* ============================================================================
 * CursorOS - VGA Text Mode Driver
 * ============================================================================
 * Provides text output to the screen using VGA text mode (80x25).
 * The VGA text buffer is memory-mapped at 0xB8000.
 * Each character cell is 2 bytes: [character][attribute]
 * ============================================================================ */

#include "../include/vga.h"
#include "../include/io.h"
#include "../include/string.h"

/* VGA text mode memory-mapped buffer */
static uint16_t *vga_buffer = (uint16_t *)0xB8000;

/* Current cursor position */
static int cursor_x = 0;
static int cursor_y = 0;

/* Current color attribute */
static uint8_t current_color;

/* Create a VGA color attribute byte */
static inline uint8_t vga_make_color(enum vga_color fg, enum vga_color bg) {
    return fg | (bg << 4);
}

/* Create a VGA character entry (character + color) */
static inline uint16_t vga_make_entry(char c, uint8_t color) {
    return (uint16_t)c | ((uint16_t)color << 8);
}

/* Update the hardware cursor position */
static void vga_update_cursor(void) {
    uint16_t pos = cursor_y * VGA_WIDTH + cursor_x;
    outb(0x3D4, 0x0F);
    outb(0x3D5, (uint8_t)(pos & 0xFF));
    outb(0x3D4, 0x0E);
    outb(0x3D5, (uint8_t)((pos >> 8) & 0xFF));
}

/* ============================================================================
 * Public API
 * ============================================================================ */

void vga_init(void) {
    current_color = vga_make_color(VGA_LIGHT_GREY, VGA_BLACK);
    vga_clear();
    vga_enable_cursor(14, 15);
}

void vga_clear(void) {
    uint16_t blank = vga_make_entry(' ', current_color);
    for (int i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) {
        vga_buffer[i] = blank;
    }
    cursor_x = 0;
    cursor_y = 0;
    vga_update_cursor();
}

void vga_set_color(enum vga_color fg, enum vga_color bg) {
    current_color = vga_make_color(fg, bg);
}

void vga_scroll(void) {
    uint16_t blank = vga_make_entry(' ', current_color);

    if (cursor_y >= VGA_HEIGHT) {
        /* Move all lines up by one */
        for (int i = 0; i < (VGA_HEIGHT - 1) * VGA_WIDTH; i++) {
            vga_buffer[i] = vga_buffer[i + VGA_WIDTH];
        }
        /* Clear the last line */
        for (int i = (VGA_HEIGHT - 1) * VGA_WIDTH; i < VGA_HEIGHT * VGA_WIDTH; i++) {
            vga_buffer[i] = blank;
        }
        cursor_y = VGA_HEIGHT - 1;
    }
}

void vga_putchar(char c) {
    if (c == '\n') {
        cursor_x = 0;
        cursor_y++;
    } else if (c == '\r') {
        cursor_x = 0;
    } else if (c == '\t') {
        cursor_x = (cursor_x + 8) & ~7;
    } else if (c == '\b') {
        if (cursor_x > 0) {
            cursor_x--;
            vga_buffer[cursor_y * VGA_WIDTH + cursor_x] = vga_make_entry(' ', current_color);
        }
    } else {
        vga_buffer[cursor_y * VGA_WIDTH + cursor_x] = vga_make_entry(c, current_color);
        cursor_x++;
    }

    /* Wrap to next line */
    if (cursor_x >= VGA_WIDTH) {
        cursor_x = 0;
        cursor_y++;
    }

    /* Scroll if needed */
    vga_scroll();
    vga_update_cursor();
}

void vga_print(const char *str) {
    while (*str) {
        vga_putchar(*str++);
    }
}

void vga_println(const char *str) {
    vga_print(str);
    vga_putchar('\n');
}

void vga_print_colored(const char *str, enum vga_color fg, enum vga_color bg) {
    uint8_t old_color = current_color;
    current_color = vga_make_color(fg, bg);
    vga_print(str);
    current_color = old_color;
}

void vga_print_hex(uint32_t value) {
    char hex_chars[] = "0123456789ABCDEF";
    char buffer[11];
    buffer[0] = '0';
    buffer[1] = 'x';

    for (int i = 7; i >= 0; i--) {
        buffer[2 + (7 - i)] = hex_chars[(value >> (i * 4)) & 0xF];
    }
    buffer[10] = '\0';
    vga_print(buffer);
}

void vga_print_dec(int32_t value) {
    char buffer[12];
    itoa(value, buffer, 10);
    vga_print(buffer);
}

void vga_move_cursor(int x, int y) {
    cursor_x = x;
    cursor_y = y;
    vga_update_cursor();
}

void vga_enable_cursor(uint8_t cursor_start, uint8_t cursor_end) {
    outb(0x3D4, 0x0A);
    outb(0x3D5, (inb(0x3D5) & 0xC0) | cursor_start);
    outb(0x3D4, 0x0B);
    outb(0x3D5, (inb(0x3D5) & 0xE0) | cursor_end);
}

void vga_disable_cursor(void) {
    outb(0x3D4, 0x0A);
    outb(0x3D5, 0x20);
}

int vga_get_cursor_x(void) {
    return cursor_x;
}

int vga_get_cursor_y(void) {
    return cursor_y;
}
