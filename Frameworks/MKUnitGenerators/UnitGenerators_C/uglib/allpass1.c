#include "../musickit_c.h"
/* 6/1/95/jos - created */

void allpass1(allpass1Vars *a)
{
    int i;
    word tmp;
    for (i=0; i<NTICK; i++) {
	tmp =  -(a->b0) * a->s + a->input[i];
	a->output[i] = a->b0 * tmp + a->s;
	a->s = tmp;
    }
}

