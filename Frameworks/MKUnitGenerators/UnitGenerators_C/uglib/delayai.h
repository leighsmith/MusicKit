/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */

#define GOLDEN_MEAN 1.61

typedef struct _delayaiVars {
    pp output;      
    pp input;
    pp delayInput;  /* Must be in the range [0-1.0).  It is
		    * scaled by the delay length and subtracted
		    * from the write pointer. */
    MKWavetable delayMemory;
    int length;    /* Length of delay line (may be < delayMemory size) */
    int xnM1;      /* length-1 (an optimization) */
    int ynM1;      /* length-1 (an optimization) */
    int writeIndex;/* Delay memory write index */
    int readIndex; /* Delay memory read index */
    word apCoef;   /* allPass coefficient, calculated from fractional delay */
    double prev_delay; /* optimization */  
} delayaiVars;


extern void init_delayai(delayaiVars *a);
extern void delayai(delayaiVars *a);


