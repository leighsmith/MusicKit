#include "../musickit_c.h"
/* 6/1/95/jos - created */

void mul1add2(mul1add2Vars *a)
{
    /*  out = in1 + (in2 * in3) */
    int i;
    for (i=0; i<NTICK; i++) 
      a->output[i] = a->input2[i] * a->input3[i] + a->input1[i];
}

