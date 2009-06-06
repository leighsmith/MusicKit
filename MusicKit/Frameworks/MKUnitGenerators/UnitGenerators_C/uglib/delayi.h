/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */

typedef struct _delayiVars {
    pp output;      
    pp input;
    pp delayInput;  /* Must be in the range [0-1.0).  It is
		    * scaled by the delay length and subtracted
		    * from the write pointer. */
    MKWavetable delayMemory;
    int length;    /* Length of delay line (may be < delayMemory size) */
    int lengthM1;  /* length-1 (an optimization) */
    int writeIndex;/* Delay memory write index */
} delayiVars;


extern void init_delayi(delayiVars *a);
extern void delayi(delayiVars *a);


