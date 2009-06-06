#include "../musickit_c.h"
/* 6/1/95/jos - created */

void dswitcht(dswitchtVars *a)
{
    int i;
    word scale;
    pp in;
    if (--(a->delayTicks) < 0) {
	scale = a->scale2;
	a->delayTicks = 0;
	in = a->input2;
    }
    else {
	scale = a->scale1;
	in = a->input1;
    }
    for (i=0; i<NTICK; i++) 
      a->output[i] = in[i] * scale;
}

