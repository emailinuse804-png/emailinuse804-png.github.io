/* ============================================================================
 * CursorOS - PS/2 Keyboard Driver
 * ============================================================================
 * Handles keyboard input via IRQ1. Translates scan codes to ASCII characters
 * and stores them in a circular buffer for the shell to consume.
 * ============================================================================ */

#include "../include/keyboard.h"
#include "../include/io.h"
#include "../include/vga.h"
#include "../include/idt.h"
#include "../include/types.h"

/* Keyboard I/O ports */
#define KBD_DATA_PORT    0x60
#define KBD_STATUS_PORT  0x64

/* Key state tracking */
static bool shift_pressed = false;
static bool caps_lock = false;
static bool ctrl_pressed = false;

/* Circular key buffer */
static char key_buffer[KEY_BUFFER_SIZE];
static volatile int buf_head = 0;
static volatile int buf_tail = 0;

/* US keyboard layout - scan code to ASCII (lowercase) */
static const char scancode_ascii[] = {
    0,    KEY_ESCAPE, '1', '2', '3', '4', '5', '6',    /* 0x00 - 0x07 */
    '7',  '8', '9', '0', '-', '=', KEY_BACKSPACE, KEY_TAB,  /* 0x08 - 0x0F */
    'q',  'w', 'e', 'r', 't', 'y', 'u', 'i',           /* 0x10 - 0x17 */
    'o',  'p', '[', ']', KEY_ENTER, KEY_LCTRL, 'a', 's', /* 0x18 - 0x1F */
    'd',  'f', 'g', 'h', 'j', 'k', 'l', ';',           /* 0x20 - 0x27 */
    '\'', '`', KEY_LSHIFT, '\\', 'z', 'x', 'c', 'v',   /* 0x28 - 0x2F */
    'b',  'n', 'm', ',', '.', '/', KEY_RSHIFT, '*',     /* 0x30 - 0x37 */
    KEY_LALT, ' ', KEY_CAPSLOCK, KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5,  /* 0x38 - 0x3F */
    KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10, 0, 0, 0,   /* 0x40 - 0x47 */
    KEY_UP, 0, 0, KEY_LEFT, 0, KEY_RIGHT, 0, 0,         /* 0x48 - 0x4F */
    KEY_DOWN, 0, 0, KEY_DELETE, 0, 0, 0, KEY_F11,        /* 0x50 - 0x57 */
    KEY_F12                                               /* 0x58 */
};

/* Shifted characters */
static const char scancode_ascii_shift[] = {
    0,    KEY_ESCAPE, '!', '@', '#', '$', '%', '^',
    '&',  '*', '(', ')', '_', '+', KEY_BACKSPACE, KEY_TAB,
    'Q',  'W', 'E', 'R', 'T', 'Y', 'U', 'I',
    'O',  'P', '{', '}', KEY_ENTER, KEY_LCTRL, 'A', 'S',
    'D',  'F', 'G', 'H', 'J', 'K', 'L', ':',
    '"',  '~', KEY_LSHIFT, '|', 'Z', 'X', 'C', 'V',
    'B',  'N', 'M', '<', '>', '?', KEY_RSHIFT, '*',
    KEY_LALT, ' ', KEY_CAPSLOCK, KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5,
    KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10, 0, 0, 0,
    KEY_UP, 0, 0, KEY_LEFT, 0, KEY_RIGHT, 0, 0,
    KEY_DOWN, 0, 0, KEY_DELETE, 0, 0, 0, KEY_F11,
    KEY_F12
};

/* Add a character to the key buffer */
static void buffer_put(char c) {
    int next = (buf_head + 1) % KEY_BUFFER_SIZE;
    if (next != buf_tail) {
        key_buffer[buf_head] = c;
        buf_head = next;
    }
}

/* Keyboard IRQ handler */
static void keyboard_irq_handler(registers_t *regs) {
    (void)regs;
    uint8_t scancode = inb(KBD_DATA_PORT);

    /* Key release (bit 7 set) */
    if (scancode & 0x80) {
        uint8_t released = scancode & 0x7F;
        if (released == 0x2A || released == 0x36) {
            shift_pressed = false;
        }
        if (released == 0x1D) {
            ctrl_pressed = false;
        }
        return;
    }

    /* Handle modifier keys */
    if (scancode == 0x2A || scancode == 0x36) {
        shift_pressed = true;
        return;
    }
    if (scancode == 0x1D) {
        ctrl_pressed = true;
        return;
    }
    if (scancode == 0x3A) {
        caps_lock = !caps_lock;
        return;
    }

    /* Translate scan code to ASCII */
    if (scancode < sizeof(scancode_ascii)) {
        char c;
        if (shift_pressed) {
            c = scancode_ascii_shift[scancode];
        } else {
            c = scancode_ascii[scancode];
        }

        /* Apply caps lock to letters */
        if (caps_lock && !shift_pressed) {
            if (c >= 'a' && c <= 'z') {
                c -= 32;
            }
        } else if (caps_lock && shift_pressed) {
            if (c >= 'A' && c <= 'Z') {
                c += 32;
            }
        }

        /* Ctrl+C - put a special character */
        if (ctrl_pressed && (c == 'c' || c == 'C')) {
            buffer_put(0x03); /* ETX */
            return;
        }

        /* Ctrl+L - clear screen */
        if (ctrl_pressed && (c == 'l' || c == 'L')) {
            buffer_put(0x0C); /* FF - form feed */
            return;
        }

        if (c != 0) {
            buffer_put(c);
        }
    }
}

void keyboard_init(void) {
    buf_head = 0;
    buf_tail = 0;
    register_interrupt_handler(33, keyboard_irq_handler); /* IRQ1 = interrupt 33 */
}

char keyboard_getchar(void) {
    while (buf_head == buf_tail) {
        __asm__ volatile("hlt"); /* Wait for interrupt */
    }
    char c = key_buffer[buf_tail];
    buf_tail = (buf_tail + 1) % KEY_BUFFER_SIZE;
    return c;
}

bool keyboard_has_key(void) {
    return buf_head != buf_tail;
}

int keyboard_readline(char *buffer, int max_len) {
    int pos = 0;
    while (pos < max_len - 1) {
        char c = keyboard_getchar();

        if (c == KEY_ENTER) {
            buffer[pos] = '\0';
            vga_putchar('\n');
            return pos;
        } else if (c == KEY_BACKSPACE) {
            if (pos > 0) {
                pos--;
                vga_putchar('\b');
            }
        } else if (c == 0x03) {
            /* Ctrl+C - cancel input */
            buffer[0] = '\0';
            vga_println("^C");
            return 0;
        } else if (c == 0x0C) {
            /* Ctrl+L - clear screen */
            vga_clear();
            return -1; /* Signal to redraw prompt */
        } else if (c >= 0x20 && c < 0x7F) {
            /* Printable character */
            buffer[pos++] = c;
            vga_putchar(c);
        }
    }
    buffer[pos] = '\0';
    return pos;
}
