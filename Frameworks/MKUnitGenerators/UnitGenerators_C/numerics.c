/* numerics.c */

/* 6/1/95  - jos, created */

#include "musickit_c.h"

void mk_double_to_word_array(word *wval, double *dval, int n) 
{
    int i;
    for (i=0; i<n; i++)
	wval[i] = mk_double_to_word(dval[i]);
}

void mk_word_to_short_array(short *sval, double *wval, int n) 
{
    int i;
    for (i=0; i<n; i++)
	sval[i] = mk_word_to_short(wval[i]);
}


