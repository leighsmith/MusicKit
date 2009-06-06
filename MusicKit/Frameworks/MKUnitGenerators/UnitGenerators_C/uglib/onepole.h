/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */

typedef struct _onepoleVars {
    pp output;
    pp input;
    word s;
    word b0;
    word a1;
    unsigned int roundingMode;
} onepoleVars;

extern void onepole(onepoleVars *a);




