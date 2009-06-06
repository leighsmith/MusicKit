#include "../musickit_c.h"
/* 6/1/95/jos - created */

void dcblock(dcblockVars *a)
{
    int i;

    /* Note: can optimize below by using local state vars within loop */
    for (i=0; i<NTICK; i++) {
	word in = a->input[i];
	word out = a->b0 * in + a->b1 * a->si1 - a->a1 * a->so1;
	a->output[i] = out;
	a->si1 = in;
	a->so1 = out;
    }
}

