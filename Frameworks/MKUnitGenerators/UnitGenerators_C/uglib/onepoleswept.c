#include "../musickit_c.h"
/* 6/1/95/jos - created */

void onepoleswept(onepolesweptVars *a)
{
    int i;
    word in;
    for (i=0; i<NTICK; i++) {
	in = a->input[i];
	a->s = in + a->a1[i] * (in  -  a->s);
	a->output[i] = a->s;
    }
}

