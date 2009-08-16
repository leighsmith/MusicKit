/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */
typedef struct _dswitchtVars {
    word scale1;
    word scale2;
    pp input1;
    word delayTicks;
    pp output;
    pp input2;
} dswitchtVars;

extern void dswitcht(dswitchtVars *a);




