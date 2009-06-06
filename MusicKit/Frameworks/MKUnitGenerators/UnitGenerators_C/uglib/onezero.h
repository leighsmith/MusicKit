/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */
typedef struct _onezeroVars {
    pp output;
    pp input;
    word s;
    word b0;
    word b1;
} onezeroVars;

extern void onezero(onezeroVars *a);




