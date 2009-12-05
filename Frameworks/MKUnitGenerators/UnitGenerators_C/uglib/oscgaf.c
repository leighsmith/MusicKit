#include "../musickit_c.h"
/* 6/1/95/jos - created */

void init_oscgaf(oscgafVars *a)
{
    a->data = a->table.data;
    a->mtab = a->table.size - 1;
}

void oscgaf(oscgafVars *a)
{
    int i;
    for (i=0; i<NTICK; i++) {
          /* 
	   a->phase += a->incInput[i] * a->incScaler;

            11/21/95 gps, added multiply by the table size, because
            the phaseInc is normalized, and needs to be scaled up 
            to be in units of samples (like oscg). 
           */ 

	a->phase += a->incInput[i] * a->incScaler * a->table.size ;
	while (a->phase >= a->mtab)
	    a->phase -= a->table.size;
	while (a->phase < 0)
	    a->phase += a->table.size;
	a->output[i] = a->data[(int)a->phase] * a->ampInput[i];
    }
}   

