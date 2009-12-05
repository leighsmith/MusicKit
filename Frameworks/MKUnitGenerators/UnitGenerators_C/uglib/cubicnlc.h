/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */

typedef struct _cubicnlcVars {
    pp input;
    pp output;
    word a1;
    word a2;
    word a3;
    word thr;			/* clipping threshold */
} cubicnlcVars;

extern void cubicnlc(cubicnlcVars *a);




