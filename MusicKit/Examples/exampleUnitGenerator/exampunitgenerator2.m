/* Simple example of using a UnitGenerator with timed DSP updates 
   with a Conductor. 

   By David A. Jaffe and J. O. Smith */

#import <musickit/musickit.h>
#import <musickit/unitgenerators/unitgenerators.h>
#import "OscwUGx.h"

#define DEBUGGING 1

main(ac,av) 
    int ac;
    char *av[]; 
{
#   define NOTES 3
#   define DUR 1.0 /* duration in seconds */
    double freq,radiansPerSample,decay,amp,time;
    int u,v,c,s;   /* UnitGenerator argument values */
    int i; 
    id theOrch = [Orchestra new];
    id osc,pp,output,aCond;

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
    [osc setOutputAout:pp];
    [output setInput:pp];
    time = 0;
    aCond = [Conductor defaultConductor];
    [Conductor setClocked:NO];

    amp = 0.1;		        /* amplitude */
    decay = 0.9995;		/* decay factor per sample */
    
    /* Set state variables which give amplitude and initial phase (=0) */
    u = DSPDoubleToFix24(amp);
    v = 0;
    /* Preferable simpler interface to implement in OscwUG.m: 
       [osc setAmp:amp]; */

    for (i=0; i<NOTES; i++) {
	/* Set rotation coefficients which give frequency and decay rate */
	freq = 440.0 * (i+1);	/* frequency */
	radiansPerSample = M_PI * 2 * freq/[theOrch samplingRate];
	c = DSPDoubleToFix24(cos(radiansPerSample) * decay);
        s = DSPDoubleToFix24(sin(radiansPerSample) * decay);
	/* Preferable interface to implement in OscwUG.m: 
	   [osc setFreq:freq decay:decay]; */

	time = i * DUR;

	/* Enqueue some messages with the Conductor to make osc tones happen
	   at the appropriate times. A more sophisticated program would group 
	   the UnitGenerators into a SynthPatch and use Notes and a 
	   SynthInstrument to dispatch the Notes. */

#define SEND_AT_TIME(_receiver,_msg,_time,_arg) \
    [aCond sel:@selector(_msg) to:_receiver atTime:_time argCount:1,_arg]

	SEND_AT_TIME(osc,setC:,time,c);
	SEND_AT_TIME(osc,setS:,time,s);
	SEND_AT_TIME(osc,setU:,time,u);
	SEND_AT_TIME(osc,setV:,time,v);
    }
    time = NOTES * DUR;
    SEND_AT_TIME(osc,setU:,time,u); /* This is essential so that Conductor
				       doesn't finish until the end of the
				       third note. */

    [osc run];
    [output run];   
    MKSetDeltaT(.5); /* Begin feeding DSP a bit ahead of time. */
    [theOrch run];   /* Start DSP and the performance */
    [Conductor startPerformance]; /* Returns after all messages are sent */

    /* Osc plays here Conductor's startPerformance method
       does not return until the performance is over.  Note, however, that
       if the Conductor is in a different mode, startPerformance returns 
       immediately (if it is in clocked mode or if you have specified that the 
       performance is to occur in a separate thread).  See the Conductor 
       documentation for details. 
       */

    [theOrch close]; /* This waits for enqueued sound to finish. */
    [theOrch free]; 
    exit(0);
}

