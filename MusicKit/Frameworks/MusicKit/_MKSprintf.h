#ifndef __MK__MKSprintf_H___
#define __MK__MKSprintf_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#include        <stdarg.h>
#include	<math.h>

/* These replace sprintf and vsprintf with thread-safe versions.
 *
 * Note that both of these return void here.
 */

extern void _MKSprintf(char *str, const char *fmt, ...);
extern void _MKVsprintf(char *str, const char *fmt, va_list ap);



#endif
