#include "../musickit_c.h"
/* 6/1/95/jos - created */

void dswitch(dswitchVars *a)
{
    int i;
    for (i=0; i<NTICK; i++) {
	a->output[i] = (--(a->delaySamples) < 0) ? a->input2[i] : 
	    a->input1[i] * a->scale1;
    }
    if (a->delaySamples < 0) /* Don't let it reach -Infinity */
      a->delaySamples = 0;
}

