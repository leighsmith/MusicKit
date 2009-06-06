/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */
/* Biquad filter - "direct-form II" */


typedef struct _biquadVars {
    pp output;
    pp input;
    word s2;
    word s1;
    word gain;
    word a2;
    word a1;
    word b2;
    word b1;
} biquadVars;

extern void biquad(biquadVars *a);




