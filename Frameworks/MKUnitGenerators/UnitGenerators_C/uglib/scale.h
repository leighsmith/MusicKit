/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */
typedef struct _scaleVars {
    pp input;
    pp output;
    word scale;
} scaleVars;

extern void scale(scaleVars *a);




