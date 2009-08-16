#include "../musickit_c.h"
/* 6/1/95/jos - created */

void constant(constantVars *a)
{
    int i;
    for (i=0; i<NTICK; i++) 
      a->output[i] = a->constant;
}

