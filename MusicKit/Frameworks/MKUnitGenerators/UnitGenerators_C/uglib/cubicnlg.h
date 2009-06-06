/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */

typedef struct _cubicnlgVars {
    pp input;
    pp output;
    word a1;
    word a2;
    word a3;
    word gain;
} cubicnlgVars;

extern void cubicnlg(cubicnlgVars *a);




