#include "../musickit_c.h"
/* 6/1/95/jos - created */

void snoise(snoiseVars *a)
{
    int i;
    unsigned int x;       
    word y;
    x = 2; /* Any positive even number */
    x += 56097 * a->seed; /* pick a number = 1 mod 4 */
    y = mk_int_to_word(x) - 1.0;
    for (i=0; i<NTICK; i++) 
      a->output[i] = y;
    a->seed = x;
}

