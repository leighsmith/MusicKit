/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */
typedef struct _exponentialVars {
    pp output;
    word targetVal;
    word rate;
    dbl curVal;
} exponentialVars;

extern void exponential(exponentialVars *a);




