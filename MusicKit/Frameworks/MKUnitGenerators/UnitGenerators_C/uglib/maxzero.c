#include "../musickit_c.h"
/* written by gps, 12/17/95 */

void maxzero(maxzeroVars *a)
{
  int i;
  for (i=0; i<NTICK; i++) { 
    if (a->input[i] > 0.0) {        
      a->output[i] = a->input[i]; 
    } else { 
      a->output[i] = 0.0; 
    } 
  } 
} 

