#include "../musickit_c.h"
/* 6/1/95/jos - created */

void onepole(onepoleVars *a)
{
    int i;
    for (i=0; i<NTICK; i++) {
	a->s = a->input[i] * a->b0  -  a->s * a->a1;
	a->output[i] = a->s;
    }
}

