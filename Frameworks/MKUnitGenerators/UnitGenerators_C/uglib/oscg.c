#include "../musickit_c.h"
/* 6/1/95/jos - created */

void init_oscg(oscgVars *a)
{
    a->data = a->table.data;
    a->mtab = a->table.size - 1;
    a->phase = 0;
}

void oscg(oscgVars *a)
{
    int i;
    for (i=0; i<NTICK; i++) {
	while (a->phase >= a->mtab)
	    a->phase -= a->table.size;
	while (a->phase < 0)
	    a->phase += a->table.size;
	a->output[i] = a->data[(int)a->phase] * a->amp;
	a->phase = a->phase + a->inc;
    }
}   

