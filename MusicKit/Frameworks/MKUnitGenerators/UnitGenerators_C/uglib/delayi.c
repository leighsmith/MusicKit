#include "../musickit_c.h"
/* 6/1/95/jos - created */
/* 
 * Delayi by David A. Jaffe.
 * Original DSP56001 code, Nov. 1993
 * Translated to fixed-point C, Nov. 1993.
 * Translated to floating-point C, July 1995.
 */


void init_delayi(delayiVars *a)
{
    if (a->delayMemory.data == 0) {
	fprintf(stderr,"*** delayi.c: Delay Memory must be set\n");
	exit(1);
    }
    if (a->length > a->delayMemory.size) {
	fprintf(stderr,"*** delayi.c: length = %d > size = %d!\n",
		a->length, a->delayMemory.size);
	a->length = a->delayMemory.size;
    }
    if (a->length <= 0) {	/* not set => default to full mem size */
	a->length = a->delayMemory.size;
    }
    a->lengthM1 = a->length - 1;  /* Length minus 1 (an optimization) */
    a->writeIndex = 0; 
}

/* 
 * For compatibility with the DSP version, delayInput is a fraction between 
 * 0 and 1.  It's then scaled by the delay length and added into the 
 * writeIndex to obtain the floating-point read offset.
 * This is rather inefficient in the floating point version because it
 * means there's an extra multiply.  We could easily switch to having 
 * the delayInput be the actual offset (i.e. pre-scaled by the delay length). 
 * - DAJ
 */

void delayi(delayiVars *a)
{
    int readInd1,readInd2;			/* Read indecies */
    word val1,val2,interpFraction;		/* Interpolation values */
    word floatTabPtr;				/* Fractional table pointer */
    int i;

    for (i=0; i<NTICK; i++) {

	/* Compute interpolated read pointers (see comment above) */
	floatTabPtr = a->writeIndex - a->delayInput[i] * a->length; 
	if (floatTabPtr < 0)
	  floatTabPtr += a->length; 
	readInd1 = (int)floatTabPtr;		/* Get integer part */
	interpFraction = floatTabPtr - readInd1;/* Get fractional part */

	/* 
	 * Wrap interpolated lookups.
	 * 
	 * Instead of doing this:
	 * 
	 *   readInd1 %= a->length;
	 *   readInd2 = (readInd1 + 1) % a->length;
	 * 
	 * We optimize a bit...
	 */

	if (readInd1 >= a->lengthM1) {		
	   if (readInd1 == a->lengthM1)
	      readInd2 = 0;
  	   else {
	      readInd1 = 0;
   	      readInd2 = 1;
	   }
        } else readInd2 = readInd1 + 1;

	/* Do lookups */
	val1 = a->delayMemory.data[readInd1];	
	val2 = a->delayMemory.data[readInd2]; 

	/* Update delay memory */
        a->delayMemory.data[a->writeIndex] = a->input[i];	

	/* Do interpolation */
	a->output[i] = val1 + (val2 - val1) * interpFraction;

	/* Update writeIndex */
        if (++a->writeIndex == a->length)
	  a->writeIndex = 0;
    }
}

