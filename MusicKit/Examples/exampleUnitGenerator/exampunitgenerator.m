/* Simple example of using a UnitGenerator with timed DSP updates 
   without a Conductor. 

   By D. A. Jaffe and J. O. Smith */

#import <musickit/musickit.h>
#import <musickit/unitgenerators/unitgenerators.h>
#import "OscwUGx.h"

#define DEBUGGING 1

int main(int ac, char *av[])
{
#   define NOTES 3
#   define DUR 1.0 /* duration in seconds */
    id theOrch = [Orchestra new];
    id osc,pp,output;
    double freq,radiansPerSample,decay,amp;
    int i;
#   if DEBUGGING
    [UnitGenerator enableErrorChecking:YES];   /* Does argument type checks */
    [theOrch setOnChipMemoryConfigDebug:YES patchPoints:0]; /* Enable debug */
#   endif
    if (![theOrch open]) { /* Must open before allocation */
	fprintf(stderr,"DSP not available.\n");
	exit(1);
    }
    /* Allocate UnitGenerators and pp */
    osc = [theOrch allocUnitGenerator:[OscwUGx class]];
    pp = [theOrch allocPatchpoint:MK_xPatch];
    output = [theOrch allocUnitGenerator:[Out2sumUGx class]];
    /* Wire them up */
    [osc setOutputAout:pp];
    [output setInput:pp];
    /* UnitGenerators must be sent "run" before being used. */
    [osc run];
    [output run];
    MKSetDeltaT(.5); /* Begin feeding DSP a bit ahead of time. */
    [theOrch run];   /* Start up the DSP */             
    for (i=0; i<NOTES; i++) {
	amp = 0.1;		/* amplitude */
	freq = 440.0 * (i+1);	/* frequency */
	decay = 0.9995;		/* decay factor per sample */
	radiansPerSample = M_PI * 2 * freq / [theOrch samplingRate];

   	MKSetTime(i * DUR);     /* Set begin time of this note. */

	/* Set rotation coefficients which give frequency and decay rate */
	[osc setC:DSPDoubleToFix24(cos(radiansPerSample) * decay)];
	[osc setS:DSPDoubleToFix24(sin(radiansPerSample) * decay)];
	/* Preferable interface to implement in OscwUG.m: 
	   [osc setFreq:freq decay:decay]; */

	/* Set state variables which give amplitude and initial phase (=0) */
	[osc setU:DSPDoubleToFix24(amp)];
	[osc setV:0];
	/* Example simpler interface to implement in OscwUG.m: 
	   [osc setAmp:amp]; */

	[Orchestra flushTimedMessages]; /* Send buffered messages */
    }                
    MKSetTime(NOTES * DUR);  /* Set time to wait before releasing DSP */
    /* Close the orchestra and wait for enqueued sound to finish. */
    [theOrch close]; 
    [theOrch free]; 
    exit(0);
}
	



