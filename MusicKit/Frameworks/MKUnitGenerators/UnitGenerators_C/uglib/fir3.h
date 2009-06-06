/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */

typedef struct _fir3Vars {
    pp outputAout;
    pp inputAinp;
    word b0;
    word b1;
    word b2;
    word s1;
    word s2;
} fir3Vars;

extern void fir3(fir3Vars *a);




