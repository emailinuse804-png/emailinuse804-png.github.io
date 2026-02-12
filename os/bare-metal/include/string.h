/* ============================================================================
 * CursorOS - String Utility Functions Header
 * ============================================================================ */

#ifndef STRING_H
#define STRING_H

#include "types.h"

/* Memory operations */
void *memset(void *dest, int val, size_t count);
void *memcpy(void *dest, const void *src, size_t count);
void *memmove(void *dest, const void *src, size_t count);
int   memcmp(const void *s1, const void *s2, size_t count);

/* String operations */
size_t strlen(const char *str);
int    strcmp(const char *s1, const char *s2);
int    strncmp(const char *s1, const char *s2, size_t n);
char  *strcpy(char *dest, const char *src);
char  *strncpy(char *dest, const char *src, size_t n);
char  *strcat(char *dest, const char *src);
char  *strchr(const char *str, int c);
char  *strstr(const char *haystack, const char *needle);
char  *strtok(char *str, const char *delim);
int    atoi(const char *str);
void   itoa(int value, char *str, int base);

/* String trim (remove leading/trailing whitespace) */
char *strtrim(char *str);

#endif /* STRING_H */
