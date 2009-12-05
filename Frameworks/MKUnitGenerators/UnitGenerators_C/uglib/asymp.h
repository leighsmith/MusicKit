/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */

typedef struct _asympVars {
    pp output;
    word targetVal;
    word rate;
    dbl curVal;
} asympVars;

extern void asymp(asympVars *a);




