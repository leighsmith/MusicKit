/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */
typedef struct _tablookiVars {
    pp output;
    pp ainv;
    word *atablook;
    word halflen;
    MKWavetable table;
} tablookiVars;

extern void init_tablooki(tablookiVars *a);
extern void tablooki(tablookiVars *a);




