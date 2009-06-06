/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */
typedef struct _oscgafVars {
    MKWavetable table;
    word *data;
    word incScaler;
    pp ampInput;
    pp output;
    pp incInput;
    word mtab;
    dbl phase;
} oscgafVars;

extern void init_oscgaf(oscgafVars *a);

extern void oscgaf(oscgafVars *a);




