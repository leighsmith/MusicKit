#include "../musickit_c.h"
/* 6/1/95/jos - created */

void scl1add2(scl1add2Vars *a)
{
    int i;
    for (i=0; i<NTICK; i++)  
      a->output[i] = a->input1[i] * a->scale + a->input2[i];
}

