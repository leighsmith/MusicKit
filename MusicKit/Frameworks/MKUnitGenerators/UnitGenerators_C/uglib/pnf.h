/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu), T. Stilson (stilti@ccrma.stanford.edu), and S.A. Van Duyne (savd@ccrma.stanford.edu).  All rights reserved. */

typedef struct _pnfVars {
    pp input;
    pp output;
    word a0;
    word a1;
    word last_u;
} pnfVars;

extern void pnf(pnfVars *);




