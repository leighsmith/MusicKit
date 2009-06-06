#include "../musickit_c.h"
/* 6/1/95/jos - created */

void onezero(onezeroVars *a)
{
    int i;
    for (i=0; i<NTICK; i++) {
	a->output[i] = a->input[i] * a->b0 + a->s * a->b1;
	a->s = a->input[i];
    }
}

