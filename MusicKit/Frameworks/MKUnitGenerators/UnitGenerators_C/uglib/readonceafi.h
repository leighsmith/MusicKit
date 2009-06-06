/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */
typedef struct _oscgafiVars {
    MKWavetable table;
    word *data;
    word incScaler;
    pp ampInput;
    pp output;
    pp incInput;
    word mtab;
    word phase;
} oscgafiVars;

extern void init_oscgafi(oscgafiVars *a);

extern void oscgafi(oscgafiVars *a);




