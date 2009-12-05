/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */

typedef struct _onepolesweptVars {
    pp output;
    pp input;
    word s;
    pp a1;			/* signal-controlled, b0 = 1-abs(a1) */
} onepolesweptVars;

extern void onepoleswept(onepolesweptVars *a);




