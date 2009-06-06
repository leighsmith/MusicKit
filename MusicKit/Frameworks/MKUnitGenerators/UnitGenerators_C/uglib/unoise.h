/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */

/* On the DSP we generate 24-bit noise using the Linear Congruential method.
   covered in Knuth vol. 2.   Here we use the native random() function.
   (If that doesn't exist, the more standard rand() function can be called.) */

typedef struct _unoiseVars {
    pp output;
    /* long seed; */ /* not supported */
} unoiseVars;

extern void unoise(unoiseVars *a);


