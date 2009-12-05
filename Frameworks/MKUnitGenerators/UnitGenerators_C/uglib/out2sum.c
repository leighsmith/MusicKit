#include "../musickit_c.h"
/* 6/1/95/jos - created */

extern void out2sum(out2sumVars *a, MKSysVars *s)
{
    int i;
    word *outp = s->dma_wfp;
    for (i=0; i<NTICK; i++) {
	word insamp = a->input[i];
	*outp++ += a->leftScale * insamp;
	*outp++ += a->rightScale * insamp;
    }
}

