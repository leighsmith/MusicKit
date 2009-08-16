#include "../musickit_c.h"
/* 6/1/95/jos - created */

void add3(add3Vars *a)
{
    int i;
    for (i=0; i<NTICK; i++) 
      a->output[i] = a->input1[i] + a->input2[i] + a->input3[i];
}

