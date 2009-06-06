#include "../musickit_c.h"
/* 6/1/95/jos - created */

void cubicnlc(cubicnlcVars *a)
{
    int i;
    for (i=0; i<NTICK; i++) {
	word in = a->input[i];
	word ins = in*in;
	word inc = ins*in;
	word out = a->a1 * in + a->a2 * ins + a->a3 * inc;
	if (fabs(out) < a->thr)
	    a->output[i] = out;
	else
	    a->output[i] = (out < 0 ? - a->thr : a->thr);
    }
}

