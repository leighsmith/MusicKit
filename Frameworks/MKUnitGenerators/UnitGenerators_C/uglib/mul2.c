#include "../musickit_c.h"
/* 6/1/95/jos - created */

void mul2(mul2Vars *a)
{
    /*  out = in1 * in2 */
    int i;
    for (i=0; i<NTICK; i++) 
      a->output[i] = a->input1[i] * a->input2[i];
}

