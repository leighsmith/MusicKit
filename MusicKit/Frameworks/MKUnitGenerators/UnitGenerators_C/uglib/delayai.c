#include "../musickit_c.h"

void init_delayai(delayaiVars *a)
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
    a->writeIndex = 0; 
}




void delayai(delayaiVars *a)
{
	double ramp[16] = {0.0, 0.00960735979838479, 0.03806023374435663, 

		0.0842651938487274, 0.1464466094067262, 

		0.2222148834901989, 0.3086582838174551, 

		0.4024548389919359, 0.5, 0.5975451610080641, 

		0.6913417161825448, 0.777785116509801, 

		0.853553390593274, 0.915734806151273, 

		0.961939766255643, 0.990392640201615};
	double delay,delay_frac;
	int delay_int;
	int readIndex;			//integer current read index
	double apCoef;
//	double xnM1 = a->xnM1;
//	double ynM1 = a->ynM1;
	double xnM1 = 0;
	double ynM1 = 0;
	double readValue1,readValue2; 

	double allpassedValue1[16],allpassedValue2[16];
	double x,xsquared,xcubed;
	int wasSameAsPrevDelay,discreteChange = 1;
	int i;
	double *tmp;
	//once per tick: break new delay into int and frac parts
	delay = a->delayInput[0]*(double)a->length;
	wasSameAsPrevDelay = (delay == a->prev_delay);
	if (wasSameAsPrevDelay) {
	    delay_int = (int)delay;
	    delay_frac = delay - (double)delay_int;
	    if(delay_frac < GOLDEN_MEAN){
		delay_frac += 1.0;
		delay_int -= 1;
	    }
	    //get new integer read pointer
	    readIndex = a->writeIndex - delay_int;
	    if (readIndex < 0) readIndex += a->length;
	    //compute allpass coeficient with polynomial
	    x = (delay_frac - 1.0);
	    xsquared = x*x;
	    xcubed = x*xsquared;
	    apCoef = -0.5*x + 0.25*xsquared - 0.125*xcubed;
	    // or, recursively, apCoef = -.5*x*(1 - .5*x*(1 - .5*x))...
	    a->prev_delay = delay;
	    tmp = allpassedValue1;
	} else {
	    tmp = a->output;
	}
	
	for (i=0; i<NTICK; i++) {
		//do the write
		a->delayMemory.data[a->writeIndex] = a->input[i];
		if(++a->writeIndex == a->length) a->writeIndex = 0;
        }
	if (!discreteChange)
	  for (i=0; i<NTICK; i++) {
	        //do the reads
		readValue1 = a->delayMemory.data[a->readIndex];
		if(++a->readIndex == a->length) a->readIndex = 0;
		//do the allpass (direct form 1...)
		tmp[i] = (readValue1 - a->ynM1)*a->apCoef + a->xnM1;
		a->xnM1 = readValue1;
		a->ynM1 = allpassedValue1;
	}
	if (!wasSameAsPrevDelay) {
	    for (i=0; i<NTICK; i++) {
		readValue2 = a->delayMemory.data[readIndex];
		if(++readIndex == a->length) readIndex = 0;
		//do the allpass (direct form 1...)
		a->output[i] = (readValue2 - ynM1)*apCoef + xnM1;
		xnM1 = readValue2;
		ynM1 = a->output[i];
	    }
	    a->readIndex = readIndex;
	    a->apCoef = apCoef;
	    a->xnM1 = xnM1;
	    a->ynM1 = ynM1;
        }
	if (!wasSameAsPrevDelay && !discreteChange)
	  for (i=0; i<NTICK; i++) {
		//do the crossfade;
		a->output[i] = allpassedValue1[i] +
			(a->output[i] - allpassedValue1[i]) * ramp[i];
	}
	discreteChange = 0;
}

