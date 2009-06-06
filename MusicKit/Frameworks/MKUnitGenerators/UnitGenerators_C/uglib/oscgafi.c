#include "../musickit_c.h"
/* 6/1/95/jos - created */

void init_oscgafi(oscgafiVars *a)
{
    a->data = a->table.data;
    a->mtab = a->table.size - 1;
}

void oscgafi(oscgafiVars *a)
{
    word val1,val2,interpFraction;
    int i,ind1,ind2;
    for (i=0;i<NTICK;i++) {
	while (a->phase >= a->mtab)
	    a->phase -= a->table.size;
	while (a->phase < 0)
	    a->phase += a->table.size;
	ind1 = floor(a->phase);
	val1 = a->data[ind1];
	ind2 = ind1 + 1;
	if (ind2 >= a->mtab)
	    ind2 = 0;
	val2 = a->data[ind2];
	interpFraction = a->phase - ind1;
	a->output[i] = ((val2-val1)*interpFraction + val1) * a->ampInput[i];

           /* 
	    a->phase += a->incScaler * a->incInput[i];

            11/21/95 gps, added multiply by the table size, because
            the phaseInc is normalized, and needs to be scaled up 
            to be in units of samples (like oscg). 
           */ 

	a->phase += a->incScaler * a->incInput[i]* a->table.size;
    }
}

