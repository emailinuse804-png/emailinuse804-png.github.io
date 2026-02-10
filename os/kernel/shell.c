/* ============================================================================
 * CursorOS - Interactive Shell
 * ============================================================================
 * A command-line shell with built-in commands. This is the user-facing
 * interface of the operating system.
 * ============================================================================ */

#include "../include/shell.h"
#include "../include/vga.h"
#include "../include/keyboard.h"
#include "../include/string.h"
#include "../include/timer.h"
#include "../include/memory.h"
#include "../include/io.h"
#include "../include/types.h"

#define MAX_CMD_LEN   256
#define MAX_ARGS      16
#define MAX_HISTORY   10

/* Command history */
static char history[MAX_HISTORY][MAX_CMD_LEN];
static int history_count = 0;

/* OS version */
#define OS_NAME    "CursorOS"
#define OS_VERSION "1.0.0"
#define OS_AUTHOR  "Built with Cursor AI"

/* ============================================================================
 * Built-in Commands
 * ============================================================================ */

static void cmd_help(int argc, char **argv) {
    (void)argc; (void)argv;

    vga_print_colored("=== CursorOS Command Reference ===\n", VGA_LIGHT_CYAN, VGA_BLACK);
    vga_println("");

    vga_print_colored("  help      ", VGA_YELLOW, VGA_BLACK);
    vga_println("- Show this help message");

    vga_print_colored("  clear     ", VGA_YELLOW, VGA_BLACK);
    vga_println("- Clear the screen");

    vga_print_colored("  echo      ", VGA_YELLOW, VGA_BLACK);
    vga_println("- Print text to the screen");

    vga_print_colored("  version   ", VGA_YELLOW, VGA_BLACK);
    vga_println("- Show OS version info");

    vga_print_colored("  uptime    ", VGA_YELLOW, VGA_BLACK);
    vga_println("- Show system uptime");

    vga_print_colored("  meminfo   ", VGA_YELLOW, VGA_BLACK);
    vga_println("- Show memory usage");

    vga_print_colored("  color     ", VGA_YELLOW, VGA_BLACK);
    vga_println("- Test color output");

    vga_print_colored("  history   ", VGA_YELLOW, VGA_BLACK);
    vga_println("- Show command history");

    vga_print_colored("  calc      ", VGA_YELLOW, VGA_BLACK);
    vga_println("- Simple calculator (calc 5 + 3)");

    vga_print_colored("  sysinfo   ", VGA_YELLOW, VGA_BLACK);
    vga_println("- Show system information");

    vga_print_colored("  cowsay    ", VGA_YELLOW, VGA_BLACK);
    vga_println("- ASCII cow says your message");

    vga_print_colored("  matrix    ", VGA_YELLOW, VGA_BLACK);
    vga_println("- Matrix-style rain animation");

    vga_print_colored("  panic     ", VGA_YELLOW, VGA_BLACK);
    vga_println("- Trigger a fake kernel panic");

    vga_print_colored("  reboot    ", VGA_YELLOW, VGA_BLACK);
    vga_println("- Reboot the system");

    vga_print_colored("  halt      ", VGA_YELLOW, VGA_BLACK);
    vga_println("- Halt the system");

    vga_println("");
    vga_print_colored("Shortcuts: ", VGA_LIGHT_GREEN, VGA_BLACK);
    vga_println("Ctrl+L = clear, Ctrl+C = cancel input");
}

static void cmd_clear(int argc, char **argv) {
    (void)argc; (void)argv;
    vga_clear();
}

static void cmd_echo(int argc, char **argv) {
    for (int i = 1; i < argc; i++) {
        vga_print(argv[i]);
        if (i < argc - 1) vga_putchar(' ');
    }
    vga_putchar('\n');
}

static void cmd_version(int argc, char **argv) {
    (void)argc; (void)argv;

    vga_println("");
    vga_print_colored("  ______                           ____  _____\n", VGA_LIGHT_CYAN, VGA_BLACK);
    vga_print_colored(" / ____/_  _______________  _____/ __ \\/ ___/\n", VGA_LIGHT_CYAN, VGA_BLACK);
    vga_print_colored("/ /   / / / / ___/ ___/ _ \\/ ___/ / / /\\__ \\ \n", VGA_LIGHT_CYAN, VGA_BLACK);
    vga_print_colored("/ /___/ /_/ / /  (__  ) __/ /  / /_/ /___/ / \n", VGA_LIGHT_CYAN, VGA_BLACK);
    vga_print_colored("\\____/\\__,_/_/  /____/\\___/_/   \\____//____/  \n", VGA_LIGHT_CYAN, VGA_BLACK);
    vga_println("");

    vga_print_colored("  Version: ", VGA_LIGHT_GREEN, VGA_BLACK);
    vga_println(OS_VERSION);

    vga_print_colored("  Author:  ", VGA_LIGHT_GREEN, VGA_BLACK);
    vga_println(OS_AUTHOR);

    vga_print_colored("  Arch:    ", VGA_LIGHT_GREEN, VGA_BLACK);
    vga_println("x86 (i386)");

    vga_print_colored("  License: ", VGA_LIGHT_GREEN, VGA_BLACK);
    vga_println("MIT");
    vga_println("");
}

static void cmd_uptime(int argc, char **argv) {
    (void)argc; (void)argv;

    uint32_t ticks = timer_get_ticks();
    uint32_t seconds = ticks / 100;  /* Timer running at 100Hz */
    uint32_t minutes = seconds / 60;
    uint32_t hours = minutes / 60;

    vga_print("Uptime: ");
    vga_print_dec(hours);
    vga_print("h ");
    vga_print_dec(minutes % 60);
    vga_print("m ");
    vga_print_dec(seconds % 60);
    vga_print("s (");
    vga_print_dec(ticks);
    vga_println(" ticks)");
}

static void cmd_meminfo(int argc, char **argv) {
    (void)argc; (void)argv;

    uint32_t total = memory_get_total();
    uint32_t used = memory_get_used();
    uint32_t free_mem = total - used;

    vga_print_colored("=== Memory Information ===\n", VGA_LIGHT_CYAN, VGA_BLACK);
    vga_print("  Heap Total:  ");
    vga_print_dec(total / 1024);
    vga_println(" KB");
    vga_print("  Heap Used:   ");
    vga_print_dec(used / 1024);
    vga_println(" KB");
    vga_print("  Heap Free:   ");
    vga_print_dec(free_mem / 1024);
    vga_println(" KB");

    /* Visual bar */
    int bar_width = 40;
    int used_bars = (total > 0) ? ((used * bar_width) / total) : 0;
    vga_print("  [");
    for (int i = 0; i < bar_width; i++) {
        if (i < used_bars) {
            vga_print_colored("#", VGA_LIGHT_RED, VGA_BLACK);
        } else {
            vga_print_colored("-", VGA_LIGHT_GREEN, VGA_BLACK);
        }
    }
    vga_println("]");
}

static void cmd_color(int argc, char **argv) {
    (void)argc; (void)argv;

    vga_println("VGA Color Palette:");
    const char *color_names[] = {
        "BLACK", "BLUE", "GREEN", "CYAN",
        "RED", "MAGENTA", "BROWN", "LIGHT GREY",
        "DARK GREY", "LIGHT BLUE", "LIGHT GREEN", "LIGHT CYAN",
        "LIGHT RED", "LIGHT MAGENTA", "YELLOW", "WHITE"
    };

    for (int i = 0; i < 16; i++) {
        vga_print("  ");
        vga_print_colored("  SAMPLE  ", (enum vga_color)i,
                          (i == 0) ? VGA_LIGHT_GREY : VGA_BLACK);
        vga_print(" - ");
        vga_println(color_names[i]);
    }
}

static void cmd_history(int argc, char **argv) {
    (void)argc; (void)argv;

    if (history_count == 0) {
        vga_println("No command history.");
        return;
    }

    vga_print_colored("=== Command History ===\n", VGA_LIGHT_CYAN, VGA_BLACK);
    for (int i = 0; i < history_count; i++) {
        vga_print("  ");
        vga_print_dec(i + 1);
        vga_print(". ");
        vga_println(history[i]);
    }
}

static void cmd_calc(int argc, char **argv) {
    if (argc != 4) {
        vga_println("Usage: calc <num1> <op> <num2>");
        vga_println("  Operators: + - * /");
        vga_println("  Example: calc 42 + 13");
        return;
    }

    int a = atoi(argv[1]);
    char op = argv[2][0];
    int b = atoi(argv[3]);
    int result = 0;

    switch (op) {
        case '+': result = a + b; break;
        case '-': result = a - b; break;
        case '*': result = a * b; break;
        case '/':
            if (b == 0) {
                vga_print_colored("Error: Division by zero!\n", VGA_LIGHT_RED, VGA_BLACK);
                return;
            }
            result = a / b;
            break;
        default:
            vga_print("Unknown operator: ");
            vga_putchar(op);
            vga_putchar('\n');
            return;
    }

    vga_print_dec(a);
    vga_print(" ");
    vga_putchar(op);
    vga_print(" ");
    vga_print_dec(b);
    vga_print(" = ");
    vga_print_colored("", VGA_LIGHT_GREEN, VGA_BLACK);
    vga_print_dec(result);
    vga_set_color(VGA_LIGHT_GREY, VGA_BLACK);
    vga_putchar('\n');
}

static void cmd_sysinfo(int argc, char **argv) {
    (void)argc; (void)argv;

    vga_print_colored("=== System Information ===\n", VGA_LIGHT_CYAN, VGA_BLACK);

    vga_print_colored("  OS:          ", VGA_YELLOW, VGA_BLACK);
    vga_print(OS_NAME);
    vga_print(" v");
    vga_println(OS_VERSION);

    vga_print_colored("  Arch:        ", VGA_YELLOW, VGA_BLACK);
    vga_println("x86 (32-bit Protected Mode)");

    vga_print_colored("  CPU Mode:    ", VGA_YELLOW, VGA_BLACK);
    vga_println("Protected Mode (Ring 0)");

    vga_print_colored("  Display:     ", VGA_YELLOW, VGA_BLACK);
    vga_println("VGA Text Mode (80x25)");

    vga_print_colored("  Keyboard:    ", VGA_YELLOW, VGA_BLACK);
    vga_println("PS/2 (US Layout)");

    vga_print_colored("  Timer:       ", VGA_YELLOW, VGA_BLACK);
    vga_println("PIT @ 100 Hz");

    vga_print_colored("  Heap:        ", VGA_YELLOW, VGA_BLACK);
    vga_print_dec(memory_get_total() / 1024);
    vga_println(" KB");

    vga_print_colored("  Boot:        ", VGA_YELLOW, VGA_BLACK);
    vga_println("GRUB2 Multiboot");
}

static void cmd_cowsay(int argc, char **argv) {
    /* Build the message */
    char message[200];
    message[0] = '\0';
    if (argc < 2) {
        strcpy(message, "Moo! I'm CursorOS!");
    } else {
        for (int i = 1; i < argc; i++) {
            strcat(message, argv[i]);
            if (i < argc - 1) strcat(message, " ");
        }
    }

    int len = strlen(message);
    if (len > 60) len = 60;

    /* Top border */
    vga_print(" ");
    for (int i = 0; i < len + 2; i++) vga_putchar('_');
    vga_putchar('\n');

    /* Message */
    vga_print("< ");
    for (int i = 0; i < len; i++) vga_putchar(message[i]);
    vga_println(" >");

    /* Bottom border */
    vga_print(" ");
    for (int i = 0; i < len + 2; i++) vga_putchar('-');
    vga_putchar('\n');

    /* Cow */
    vga_println("        \\   ^__^");
    vga_println("         \\  (oo)\\_______");
    vga_println("            (__)\\       )\\/\\");
    vga_println("                ||----w |");
    vga_println("                ||     ||");
}

static void cmd_matrix(int argc, char **argv) {
    (void)argc; (void)argv;

    vga_println("Matrix rain... (runs for 3 seconds)");
    timer_sleep(500);

    /* Simple pseudo-random number state */
    uint32_t rand_state = timer_get_ticks();

    vga_set_color(VGA_LIGHT_GREEN, VGA_BLACK);

    for (int frame = 0; frame < 60; frame++) {
        for (int i = 0; i < 10; i++) {
            rand_state = rand_state * 1103515245 + 12345;
            int col = (rand_state >> 16) % VGA_WIDTH;
            rand_state = rand_state * 1103515245 + 12345;
            char c = '!' + ((rand_state >> 16) % 94);
            vga_move_cursor(col, vga_get_cursor_y());
            vga_putchar(c);
        }
        timer_sleep(50);
    }

    vga_set_color(VGA_LIGHT_GREY, VGA_BLACK);
    vga_putchar('\n');
    vga_println("Matrix rain ended.");
}

static void cmd_panic(int argc, char **argv) {
    (void)argc; (void)argv;

    vga_set_color(VGA_WHITE, VGA_BLUE);
    vga_clear();

    vga_println("");
    vga_println("   *** KERNEL PANIC ***");
    vga_println("");
    vga_println("   A fatal error has occurred in CursorOS.");
    vga_println("");
    vga_println("   Error: FAKE_PANIC_FOR_FUN");
    vga_println("   Code:  0xDEADBEEF");
    vga_println("");
    vga_println("   Don't worry, this is just a demo!");
    vga_println("   The system is perfectly fine.");
    vga_println("");
    vga_println("   Press any key to return to shell...");

    keyboard_getchar();

    vga_set_color(VGA_LIGHT_GREY, VGA_BLACK);
    vga_clear();
}

static void cmd_reboot(int argc, char **argv) {
    (void)argc; (void)argv;
    vga_println("Rebooting...");
    timer_sleep(500);

    /* Reboot via keyboard controller */
    uint8_t good = 0x02;
    while (good & 0x02) {
        good = inb(0x64);
    }
    outb(0x64, 0xFE);

    /* If that didn't work, triple fault */
    __asm__ volatile("lidt (%%eax)" : : "a"(0));
    __asm__ volatile("int $0x03");
}

static void cmd_halt(int argc, char **argv) {
    (void)argc; (void)argv;

    vga_print_colored("\nSystem halted. ", VGA_YELLOW, VGA_BLACK);
    vga_println("It is safe to turn off your computer.");

    __asm__ volatile("cli");
    for (;;) {
        __asm__ volatile("hlt");
    }
}

/* ============================================================================
 * Command Dispatch
 * ============================================================================ */

typedef struct {
    const char *name;
    void (*func)(int argc, char **argv);
} command_t;

static command_t commands[] = {
    { "help",     cmd_help },
    { "clear",    cmd_clear },
    { "echo",     cmd_echo },
    { "version",  cmd_version },
    { "uptime",   cmd_uptime },
    { "meminfo",  cmd_meminfo },
    { "color",    cmd_color },
    { "history",  cmd_history },
    { "calc",     cmd_calc },
    { "sysinfo",  cmd_sysinfo },
    { "cowsay",   cmd_cowsay },
    { "matrix",   cmd_matrix },
    { "panic",    cmd_panic },
    { "reboot",   cmd_reboot },
    { "halt",     cmd_halt },
    { NULL, NULL }
};

static void execute_command(char *input) {
    /* Trim whitespace */
    char *cmd = strtrim(input);
    if (strlen(cmd) == 0) return;

    /* Save to history */
    if (history_count < MAX_HISTORY) {
        strcpy(history[history_count++], cmd);
    } else {
        /* Shift history */
        for (int i = 0; i < MAX_HISTORY - 1; i++) {
            strcpy(history[i], history[i + 1]);
        }
        strcpy(history[MAX_HISTORY - 1], cmd);
    }

    /* Parse arguments */
    char cmd_copy[MAX_CMD_LEN];
    strcpy(cmd_copy, cmd);

    char *argv[MAX_ARGS];
    int argc = 0;

    char *token = strtok(cmd_copy, " ");
    while (token && argc < MAX_ARGS) {
        argv[argc++] = token;
        token = strtok(NULL, " ");
    }

    if (argc == 0) return;

    /* Find and execute command */
    for (int i = 0; commands[i].name != NULL; i++) {
        if (strcmp(argv[0], commands[i].name) == 0) {
            commands[i].func(argc, argv);
            return;
        }
    }

    /* Unknown command */
    vga_print_colored("Unknown command: ", VGA_LIGHT_RED, VGA_BLACK);
    vga_println(argv[0]);
    vga_println("Type 'help' for available commands.");
}

/* ============================================================================
 * Shell Main Loop
 * ============================================================================ */

static void print_prompt(void) {
    vga_print_colored(OS_NAME, VGA_LIGHT_GREEN, VGA_BLACK);
    vga_print_colored("> ", VGA_LIGHT_CYAN, VGA_BLACK);
}

void shell_run(void) {
    char input[MAX_CMD_LEN];

    /* Welcome message */
    vga_println("");
    vga_print_colored("========================================", VGA_LIGHT_CYAN, VGA_BLACK);
    vga_println("");
    vga_print_colored("  Welcome to ", VGA_WHITE, VGA_BLACK);
    vga_print_colored(OS_NAME, VGA_LIGHT_GREEN, VGA_BLACK);
    vga_print_colored(" v", VGA_WHITE, VGA_BLACK);
    vga_print_colored(OS_VERSION, VGA_LIGHT_GREEN, VGA_BLACK);
    vga_println("");
    vga_print_colored("========================================", VGA_LIGHT_CYAN, VGA_BLACK);
    vga_println("");
    vga_println("");
    vga_println("  A minimal operating system built with Cursor AI.");
    vga_println("  Type 'help' for a list of commands.");
    vga_println("");

    while (1) {
        print_prompt();
        int result = keyboard_readline(input, MAX_CMD_LEN);
        if (result >= 0) {
            execute_command(input);
        }
        /* result == -1 means Ctrl+L was pressed, loop re-draws prompt */
    }
}
