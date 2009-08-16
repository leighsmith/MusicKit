#include "../musickit_c.h"
/* 6/1/95/jos - created */

void biquad(biquadVars *a)
{
    int i;
    dbl A;
    word s0;
    for (i=0; i<NTICK; i++) {
	A = a->gain * a->input[i];
	A -= a->a1 * a->s1;
	A -= a->a2 * a->s2;
	s0 = A;
	A += a->b1 * a->s1;
	a->output[i] = a->b2 * a->s2 + A;
	a->s2 = a->s1;
	a->s1 = s0;
    }
}

