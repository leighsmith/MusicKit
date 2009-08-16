/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */
typedef struct _oscgVars {
    MKWavetable table;
    word *data;
    word mtab; /* mask for wrapping pointer in wavetable memory */
    pp output;
    word amp;
    dbl inc;
    dbl freq; /* not used but nice to see for convenience */
    word phase;
} oscgVars;

extern void init_oscg(oscgVars *a);

extern void oscg(oscgVars *a);




