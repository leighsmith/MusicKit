#include "../musickit_c.h"
/* 6/1/95/jos - created */

void init_readonce(readonceVars *a)
{
    a->baseAddress = a->pointer = a->table.data;
    a->endPointer = a->table.data + a->table.size - 1;
}

void readonce(readonceVars *a)
{
    int i;
    if (a->pointer > a->endPointer) { /* off end of wavetable */
	for (i=0; i<NTICK; i++) 
	    a->output[i] = 0;
	return;
    } else if (a->pointer + NTICK <= a->endPointer) { /* inside wavetable */
	for (i=0; i<NTICK; i++) 
	    a->output[i] = *a->pointer++;
    } else {			/* near end of wavetable */
	for (i=0; i<NTICK; i++)  {
	    if (a->pointer > a->endPointer) 
		a->output[i] = 0;
	    else
		a->output[i] = *a->pointer++;
	}
    }
}

