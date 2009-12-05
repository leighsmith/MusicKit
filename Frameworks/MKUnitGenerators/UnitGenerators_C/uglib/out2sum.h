/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */

typedef struct _out2sumVars {
    word leftScale;
    word rightScale;
    pp input;
} out2sumVars;

extern void out2sum(out2sumVars *a, MKSysVars *s);




