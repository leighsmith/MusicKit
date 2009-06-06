/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */
typedef struct _delayVars {
    pp output;
    pp input;
    word *pointer;
    word *endPointer;
    word *baseAddress;
    MKWavetable delayMemory;
    int length;
} delayVars;

extern void init_delay(delayVars *a);
extern void delay(delayVars *a);


