/* ============================================================================
 * CursorOS - Programmable Interval Timer (PIT) Header
 * ============================================================================ */

#ifndef TIMER_H
#define TIMER_H

#include "types.h"

/* Initialize the PIT timer at the given frequency (Hz) */
void timer_init(uint32_t frequency);

/* Get the number of ticks since boot */
uint32_t timer_get_ticks(void);

/* Sleep for a given number of milliseconds (approximate) */
void timer_sleep(uint32_t ms);

#endif /* TIMER_H */
