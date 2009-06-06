#include "../musickit_c.h"
/* 6/1/95/jos - created */

void init_tablooki(tablookiVars *a)
{
    a->atablook = a->table.data;
    a->halflen = a->table.size/2;
}

void tablooki(tablookiVars *a)
{
    int i,ind1,ind2;
    word val1,val2,interpFraction;
    pp ainv = a->ainv;
    dbl A;
    for (i=0;i<NTICK;i++) {
	A = a->halflen * *ainv++ + a->halflen;
	ind1 = floor(A);
	interpFraction = A - (dbl)ind1;
	ind2 = ind1 + 1;
	val1 = a->atablook[ind1];
	val2 = a->atablook[ind2];
	/* out[i] = ((val2-val1)*interp + val1) */
	a->output[i] = ((val2 - val1) * interpFraction) + val1;
    }
//printf("(%lf,%lf)",a->ainv[0],a->output[0]);
}

