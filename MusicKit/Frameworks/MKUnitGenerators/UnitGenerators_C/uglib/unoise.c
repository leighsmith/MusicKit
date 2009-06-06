#include "../musickit_c.h"
/* 6/1/95/jos - created */

void unoise(unoiseVars *a)
{
    int i;
    for (i=0; i<NTICK; i++) {
	/* random() returns a long between 0 and (2**31)-1 = MAXINT */
	a->output[i] = ((word)random())*(1.0/(0.5*(word)MAXINT))-1.0; /* -1 to 1.0 */
    }
}
