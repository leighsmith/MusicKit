#include "../musickit_c.h"
/* 6/1/95/jos - created */

void cubicnlg(cubicnlgVars *a)
{
    int i;
    for (i=0; i<NTICK; i++) {
	word in = a->input[i];
	word ins = in*in;
	word inc = ins*in;
	word out = a->a1 * in + a->a2 * ins + a->a3 * inc;
	out *= a->gain * 256.0;
	if (out > 1.0) 
	    out = 1.0;
	else if (out < -1.0) 
	    out = -1.0;
	a->output[i] = out;
    }
}

