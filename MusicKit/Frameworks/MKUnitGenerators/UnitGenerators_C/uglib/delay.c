#include "../musickit_c.h"
/* 6/1/95/jos - created */

void init_delay(delayVars *a)
{
    if (a->length > a->delayMemory.size) {
	fprintf(stderr,"*** delay.c: length = %d > size = %d!\n",
		a->length, a->delayMemory.size);
	a->length = a->delayMemory.size;
    }

    if (a->length <= 0) {       /* not set => default to full mem size */  
        a->length = a->delayMemory.size;
    }

    a->baseAddress = a->pointer = a->delayMemory.data;
    a->endPointer = a->delayMemory.data + a->length - 1;
}

void delay(delayVars *a)
{
    int i;

    for (i=0; i<NTICK; i++)  {

        word in = a->input[i];

	if (a->pointer > a->endPointer) 
	    a->pointer = a->baseAddress;
	a->output[i] = *a->pointer;
	*a->pointer++ = in;
    }
}

