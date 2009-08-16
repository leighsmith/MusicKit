/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */
typedef struct _dswitchVars {
    pp input1;
    pp input2;
    pp output;
    word scale1;
    word delaySamples;
} dswitchVars;

extern void dswitch(dswitchVars *a);




