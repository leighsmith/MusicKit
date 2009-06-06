#include "../musickit_c.h"
/* 6/1/95/jos - created */

void asymp(asympVars *a)
{
    int i;
    for (i=0; i<NTICK; i++) {
	a->curVal = a->curVal * (1.0 - a->rate) + a->targetVal * a->rate;
	a->output[i] = a->curVal;
    }
}

