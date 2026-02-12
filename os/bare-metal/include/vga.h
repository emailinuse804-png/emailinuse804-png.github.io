/* ============================================================================
 * CursorOS - VGA Text Mode Driver Header
 * ============================================================================ */

#ifndef VGA_H
#define VGA_H

#include "types.h"

/* VGA text mode dimensions */
#define VGA_WIDTH  80
#define VGA_HEIGHT 25

/* VGA color palette */
enum vga_color {
    VGA_BLACK         = 0,
    VGA_BLUE          = 1,
    VGA_GREEN         = 2,
    VGA_CYAN          = 3,
    VGA_RED           = 4,
    VGA_MAGENTA       = 5,
    VGA_BROWN         = 6,
    VGA_LIGHT_GREY    = 7,
    VGA_DARK_GREY     = 8,
    VGA_LIGHT_BLUE    = 9,
    VGA_LIGHT_GREEN   = 10,
    VGA_LIGHT_CYAN    = 11,
    VGA_LIGHT_RED     = 12,
    VGA_LIGHT_MAGENTA = 13,
    VGA_YELLOW        = 14,
    VGA_WHITE         = 15,
};

/* Initialize the VGA driver */
void vga_init(void);

/* Clear the screen */
void vga_clear(void);

/* Set the text color */
void vga_set_color(enum vga_color fg, enum vga_color bg);

/* Print a single character */
void vga_putchar(char c);

/* Print a string */
void vga_print(const char *str);

/* Print a string with a newline */
void vga_println(const char *str);

/* Print a string in a specific color */
void vga_print_colored(const char *str, enum vga_color fg, enum vga_color bg);

/* Print a hexadecimal number */
void vga_print_hex(uint32_t value);

/* Print a decimal number */
void vga_print_dec(int32_t value);

/* Scroll the screen up by one line */
void vga_scroll(void);

/* Move the hardware cursor */
void vga_move_cursor(int x, int y);

/* Enable/disable the cursor */
void vga_enable_cursor(uint8_t cursor_start, uint8_t cursor_end);
void vga_disable_cursor(void);

/* Get current cursor position */
int vga_get_cursor_x(void);
int vga_get_cursor_y(void);

#endif /* VGA_H */
