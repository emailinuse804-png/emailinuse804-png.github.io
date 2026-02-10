/* ============================================================================
 * CursorOS - String and Memory Utility Functions
 * ============================================================================ */

#include "../include/string.h"

/* ============================================================================
 * Memory Operations
 * ============================================================================ */

void *memset(void *dest, int val, size_t count) {
    uint8_t *d = (uint8_t *)dest;
    while (count--) {
        *d++ = (uint8_t)val;
    }
    return dest;
}

void *memcpy(void *dest, const void *src, size_t count) {
    uint8_t *d = (uint8_t *)dest;
    const uint8_t *s = (const uint8_t *)src;
    while (count--) {
        *d++ = *s++;
    }
    return dest;
}

void *memmove(void *dest, const void *src, size_t count) {
    uint8_t *d = (uint8_t *)dest;
    const uint8_t *s = (const uint8_t *)src;
    if (d < s) {
        while (count--) {
            *d++ = *s++;
        }
    } else {
        d += count;
        s += count;
        while (count--) {
            *--d = *--s;
        }
    }
    return dest;
}

int memcmp(const void *s1, const void *s2, size_t count) {
    const uint8_t *a = (const uint8_t *)s1;
    const uint8_t *b = (const uint8_t *)s2;
    while (count--) {
        if (*a != *b) return *a - *b;
        a++;
        b++;
    }
    return 0;
}

/* ============================================================================
 * String Operations
 * ============================================================================ */

size_t strlen(const char *str) {
    size_t len = 0;
    while (str[len]) {
        len++;
    }
    return len;
}

int strcmp(const char *s1, const char *s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(unsigned char *)s1 - *(unsigned char *)s2;
}

int strncmp(const char *s1, const char *s2, size_t n) {
    while (n && *s1 && (*s1 == *s2)) {
        s1++;
        s2++;
        n--;
    }
    if (n == 0) return 0;
    return *(unsigned char *)s1 - *(unsigned char *)s2;
}

char *strcpy(char *dest, const char *src) {
    char *d = dest;
    while ((*d++ = *src++));
    return dest;
}

char *strncpy(char *dest, const char *src, size_t n) {
    char *d = dest;
    while (n && (*d++ = *src++)) {
        n--;
    }
    while (n--) {
        *d++ = '\0';
    }
    return dest;
}

char *strcat(char *dest, const char *src) {
    char *d = dest;
    while (*d) d++;
    while ((*d++ = *src++));
    return dest;
}

char *strchr(const char *str, int c) {
    while (*str) {
        if (*str == (char)c) return (char *)str;
        str++;
    }
    return (c == 0) ? (char *)str : NULL;
}

char *strstr(const char *haystack, const char *needle) {
    if (!*needle) return (char *)haystack;
    size_t needle_len = strlen(needle);
    while (*haystack) {
        if (strncmp(haystack, needle, needle_len) == 0) {
            return (char *)haystack;
        }
        haystack++;
    }
    return NULL;
}

/* Static state for strtok */
static char *strtok_next = NULL;

char *strtok(char *str, const char *delim) {
    if (str) strtok_next = str;
    if (!strtok_next) return NULL;

    /* Skip leading delimiters */
    while (*strtok_next) {
        const char *d = delim;
        bool is_delim = false;
        while (*d) {
            if (*strtok_next == *d) { is_delim = true; break; }
            d++;
        }
        if (!is_delim) break;
        strtok_next++;
    }

    if (!*strtok_next) {
        strtok_next = NULL;
        return NULL;
    }

    char *token_start = strtok_next;

    /* Find end of token */
    while (*strtok_next) {
        const char *d = delim;
        while (*d) {
            if (*strtok_next == *d) {
                *strtok_next = '\0';
                strtok_next++;
                return token_start;
            }
            d++;
        }
        strtok_next++;
    }

    strtok_next = NULL;
    return token_start;
}

int atoi(const char *str) {
    int result = 0;
    int sign = 1;

    /* Skip whitespace */
    while (*str == ' ' || *str == '\t') str++;

    /* Handle sign */
    if (*str == '-') { sign = -1; str++; }
    else if (*str == '+') { str++; }

    /* Convert digits */
    while (*str >= '0' && *str <= '9') {
        result = result * 10 + (*str - '0');
        str++;
    }

    return result * sign;
}

void itoa(int value, char *str, int base) {
    char *p = str;
    char *p1, *p2;
    unsigned int uvalue;
    int negative = 0;

    if (base < 2 || base > 36) {
        *str = '\0';
        return;
    }

    if (value < 0 && base == 10) {
        negative = 1;
        uvalue = (unsigned int)(-value);
    } else {
        uvalue = (unsigned int)value;
    }

    /* Convert to string (reversed) */
    do {
        unsigned int remainder = uvalue % base;
        *p++ = (remainder < 10) ? ('0' + remainder) : ('a' + remainder - 10);
        uvalue /= base;
    } while (uvalue);

    if (negative) *p++ = '-';
    *p = '\0';

    /* Reverse the string */
    p1 = str;
    p2 = p - 1;
    while (p1 < p2) {
        char tmp = *p1;
        *p1 = *p2;
        *p2 = tmp;
        p1++;
        p2--;
    }
}

char *strtrim(char *str) {
    /* Trim leading whitespace */
    while (*str == ' ' || *str == '\t') str++;

    if (*str == '\0') return str;

    /* Trim trailing whitespace */
    char *end = str + strlen(str) - 1;
    while (end > str && (*end == ' ' || *end == '\t')) {
        *end = '\0';
        end--;
    }

    return str;
}
