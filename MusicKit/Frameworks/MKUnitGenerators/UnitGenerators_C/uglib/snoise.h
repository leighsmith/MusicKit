/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */
typedef struct _snoiseVars {
    pp output;
    unsigned int seed;
} snoiseVars;

extern void snoise(snoiseVars *a);




