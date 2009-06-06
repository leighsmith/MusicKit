#include "../musickit_c.h"
/* 6/1/95/jos - created */

void fir3(fir3Vars *a)
{
    int i;
    word input;
    for (i=0; i<NTICK; i++) {
	input = a->inputAinp[i];
	a->outputAout[i] = a->b0 * input  +  a->b1 * a->s1  +  a->b2 * a->s2;
	a->s2 = a->s1;
	a->s1 = input;
    }
}

