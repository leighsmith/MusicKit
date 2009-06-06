/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */

typedef struct _dcblockVars {
    pp input;
    pp output;
    word b0;
    word b1;
    word a1;
    word si1;
    word so1;
} dcblockVars;

extern void dcblock(dcblockVars *a);




