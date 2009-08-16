#include "../musickit_c.h"
/* 6/1/95/jos - created */

void interp(interpVars *a)
{
    int i;
    for (i=0; i<NTICK; i++)  {
	/* (sig2-sig1)*control + sig1 */
	a->output[i] = (a->input2[i] - a->input1[i]) * a->input3[i] + a->input1[i];
    }
}

