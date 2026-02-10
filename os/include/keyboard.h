/* ============================================================================
 * CursorOS - PS/2 Keyboard Driver Header
 * ============================================================================ */

#ifndef KEYBOARD_H
#define KEYBOARD_H

#include "types.h"

/* Special key codes */
#define KEY_BACKSPACE  0x08
#define KEY_TAB        0x09
#define KEY_ENTER      0x0A
#define KEY_ESCAPE     0x1B
#define KEY_UP         0x80
#define KEY_DOWN       0x81
#define KEY_LEFT       0x82
#define KEY_RIGHT      0x83
#define KEY_LSHIFT     0x84
#define KEY_RSHIFT     0x85
#define KEY_LCTRL      0x86
#define KEY_LALT       0x87
#define KEY_CAPSLOCK   0x88
#define KEY_F1         0x89
#define KEY_F2         0x8A
#define KEY_F3         0x8B
#define KEY_F4         0x8C
#define KEY_F5         0x8D
#define KEY_F6         0x8E
#define KEY_F7         0x8F
#define KEY_F8         0x90
#define KEY_F9         0x91
#define KEY_F10        0x92
#define KEY_F11        0x93
#define KEY_F12        0x94
#define KEY_DELETE     0x95

/* Key buffer size */
#define KEY_BUFFER_SIZE 256

/* Initialize the keyboard driver */
void keyboard_init(void);

/* Keyboard interrupt handler (called from ISR) */
void keyboard_handler(void);

/* Get a character from the keyboard buffer (blocking) */
char keyboard_getchar(void);

/* Check if a key is available in the buffer */
bool keyboard_has_key(void);

/* Read a line of input into a buffer */
int keyboard_readline(char *buffer, int max_len);

#endif /* KEYBOARD_H */
