/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */
typedef struct _readonceVars {
    pp output;
    word *pointer;
    word *endPointer;
    word *baseAddress;
    MKWavetable table;
} readonceVars;

extern void init_readonce(readonceVars *a);
extern void readonce(readonceVars *a);



