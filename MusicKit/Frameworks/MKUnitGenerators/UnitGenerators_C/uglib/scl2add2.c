#include "../musickit_c.h"
/* 6/1/95/jos - created */

void scl2add2(scl2add2Vars *a)
{
    int i;
    for (i=0; i<NTICK; i++)  
      a->output[i] = a->input2[i] * a->scale2 + a->input1[i] * a->scale1;
}

