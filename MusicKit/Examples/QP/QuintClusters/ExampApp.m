/* Copyright CCRMA, Stanford University, 1993.  Written by David A. Jaffe */

#import <appkit/appkit.h>
#import <musickit/musickit.h>
#import <musickit/unitgenerators/unitgenerators.h>
#import <musickit/synthpatches/Pluck.h>
#import <musickit/synthpatches/ArielQPMix.h>
#import <musickit/pitches.h>
#import "ExampApp.h"
#import "DramEchos.h"

/* For 44 khz ProPort */
#define SAT_PATCHES 7
#define NEXT_PATCHES 6  // NeXT DSP runs at a slightly slower clock
#define HUB_PATCHES 4   // 5 is ok too

#define DSPs 6  /* 5 on QuintProcessor and 1 on NeXT */

#define DEFAULTFREQ 115.0

/* We choose to manage our own array of SynthPatches here, rather than
 * having a SynthInstrument do it for us.  
 */
static id dspPatch[DSPs][SAT_PATCHES] = {nil};

static void handleMKError(char *msg) { /* Surpress warnings */ }
  
@implementation ExampApp

#define VOICES ((useNeXTDSP) ? (SAT_PATCHES*5+HUB_PATCHES) : (SAT_PATCHES*4+HUB_PATCHES))

#define RANDOMMAX (double)((long)MAXINT)
#define RANNUM  (((double)random()) / RANDOMMAX)

/* We don't want to endlessly create Notes because it will be a memory leak.  
 * On the other hand, we don't want to have to worry about freeing them.  
 * So we use a cache big enough so that we don't have to worry about either 
 * of these things.
 */
static id noteCache[1024];
static int noteCacheCounter = 0;

static void initNoteCache(void)
{
    int i;
    for (i=0;i<1024;i++)  {
	noteCache[i] = [[Note alloc] init];
	/* we don't send any note-offs */
	[noteCache[i] setNoteType:MK_noteOn]; 	
	[noteCache[i] setNoteTag:MKNoteTag()];      
    }
}

- appDidInit:sender
{
    int i,j;
    /* Show the "be patient" message */
    [bootingPanel orderFront:sender];
    [bootingPanel display];
    NXPing();
    
    /* Set some defaults */
    rate = .01;
    useNeXTDSP = NO;
    interval = .0625/12.0;
    bright = 1.0;
    sustain = .5;
    scheduled = NO;
    varyPitch = NO;
    varyBright = NO;
    varySus = NO;
    varyRate = NO;
    varyInterval = NO;
    echoAmp = .4;
    strummingUp = YES;
    freq = DEFAULTFREQ;
    continuous = NO;

    MKSetErrorProc(handleMKError);    /* Intercept music kit errors. */
    initNoteCache();                  /* See above */
    [Conductor setFinishWhenEmpty:NO];/* Let it play forever until user quits */
    MKSetDeltaT(0.01);                /* 10 millisecond secheduler advance */

    qp = [ArielQP new];               /* Create Quint Processor object */
    [Orchestra newOnDSP:0];           /* Create NeXT DSP Orchestra */
    [Orchestra setSamplingRate:44100]; /* Try lower values for more voices. */
    [Orchestra setFastResponse:YES];   /* This affects only NeXT DSP */
    [qp setSerialPortDevice:[[ArielProPort alloc] init]];
    if (![[Orchestra nthOrchestra:0] open])
      NXRunAlertPanel("QuintClusters",
		      "Could not open NeXT DSP. "
		      "Someone else is probably using it. " 
		      "Continuing with QuintProcessor DSPs",
		      "OK",NULL,NULL);
    [qp makeQPPerform:@selector(open)];
    if ([qp deviceStatus] != MK_devOpen) {
	NXRunAlertPanel("QuintClusters","Could not open Quint Processor. ",
			"Quit",NULL,NULL);
	[self terminate:self];
    }
    allocateDramEchos(qp,echoAmp);
    for (j=0; j<NEXT_PATCHES; j++) 
      dspPatch[0][j] = [[Orchestra nthOrchestra:0] allocSynthPatch:[Pluck class]];
    for (i=4; i>=1; i--)
      for (j=0; j<SAT_PATCHES; j++)  
	dspPatch[i][j] = [[qp satellite:'A'+i-1] allocSynthPatch:[Pluck class]];
    for (j=0; j<HUB_PATCHES; j++) 
      dspPatch[5][j] = [qp allocSynthPatch:[Pluck class]];
    [Orchestra run];
    [Conductor startPerformance];        
    [bootingPanel orderOut:sender];
    return self;
}

static id makeNote(double freq,double bright, double sustain, double bearing)
{
    id theNote;
    if (++noteCacheCounter==1024)
      noteCacheCounter = 0;
    theNote = noteCache[noteCacheCounter];
    /* Pluck is rather quiet, so we use the maximum amplitude */
    [theNote setPar:MK_amp toDouble:1.0];   
    [theNote setPar:MK_freq toDouble:freq];  
    [theNote setPar:MK_amp toDouble:.1];
    [theNote setPar:MK_bright toDouble:bright];
    [theNote setPar:MK_sustain toDouble:sustain];
    [theNote setPar:MK_bearing toDouble:bearing];
    return theNote;
}

- _strum
  /* This does the dirty work */
{
    int i,j;
    double f,b,freqFact,bearingFact,us;

    if (varySus) {
	sustain = RANNUM;
	[susSlider setDoubleValue:sustain];
    }
    if (varyBright) {
	bright =  RANNUM;
	[brightSlider setDoubleValue:bright];
    }
    if (varyRate) {
	rate =  RANNUM/10.0 + .01;
	[rateSlider setDoubleValue:1.0 - 10*rate];
    }
    if (varyInterval)
      interval = RANNUM/12.0;
    if (varyPitch) {
	double v;
	freq =  DEFAULTFREQ * pow(2,v = -1+2*RANNUM);
	[pitchSlider setDoubleValue:12*v];
    }
    f = freq;
    freqFact = pow(2.0,interval);
    b = -45;
    bearingFact = 90.0/VOICES;
    us = rate * 1000000;
    if (!continuous) 
      strummingUp = YES;
    if (!strummingUp) {
	f *= pow(freqFact,(double)VOICES);
	freqFact = 1/freqFact;
	bearingFact = -bearingFact;
	b = 45;
    }
    [Conductor lockPerformance];	     /* Prepare to send MK message */
    for (j=0; j<=SAT_PATCHES; j++)
      for (i=1; i<=4; i++) {
	  f *= freqFact;
	  b += bearingFact;
	  [[Conductor defaultConductor] sel:@selector(noteOn:) to:dspPatch[i][j] 
	   withDelay:(rate)*(i+j*4) argCount:1, makeNote(f,bright,sustain,b)];
      }
    for (j=0; j<HUB_PATCHES; j++) {
	f = f * freqFact;
	b += bearingFact;
	[[Conductor defaultConductor] sel:@selector(noteOn:) to:dspPatch[5][j] 
         withDelay:(rate)*(SAT_PATCHES*4+j) argCount:1, 
	 makeNote(f,bright,sustain,b)];
      }
    if (useNeXTDSP)
      for (j=0; j<=SAT_PATCHES; j++){
	  f = f * freqFact;
	  b += bearingFact;
	  [[Conductor defaultConductor] sel:@selector(noteOn:) to:dspPatch[0][j] 
	   withDelay:(rate)*(SAT_PATCHES*4+HUB_PATCHES+j) argCount:1, 
	   makeNote(f,bright,sustain,b)];
      }
    if (continuous) {
	[[Conductor defaultConductor] sel:@selector(_strum) to:self 
         withDelay:VOICES * rate argCount:0];
	scheduled = YES;
	strummingUp = !strummingUp;
    } else scheduled = NO;
    [Conductor unlockPerformance];	     /* End of MK message block */
    return self;
}

- playStrum:sender
{
    if (!continuous)
      return [self _strum];
    else if (scheduled) {
	NXRunAlertPanel("Quint Processor Demo",
			"Click on 'continuous' to stop continuous play",
			"Alright",NULL,NULL,NULL);
	return self;
    }
    [[Conductor defaultConductor] sel:@selector(_strum) to:self 
     withDelay:VOICES * rate argCount:0];
    scheduled = YES;
    return self;
}

/* Target methods. */
- setPitch:sender
{    
    double transposition = [sender floatValue];	  /* -12 to +12 semitones */
    freq =  DEFAULTFREQ * pow(2,transposition/12.0);         /* in Hz */
    return self;
}

- showInfoPanel:sender
{
    [self loadNibSection:"Info.nib" owner:self];
    [infoPanel orderFront:sender];
    return self;
}

-setRate:sender
{
    rate = (1.0 - [sender doubleValue])/10;
    return self;
}

-useNeXTDSP:sender
{
    useNeXTDSP = [sender intValue];
    return self;
}

-setContinuous:sender
{
    continuous = !continuous;
    return self;
}

-setSustain:sender
{
    sustain = [sender doubleValue];
    return self;
}

-setBright:sender
{
    bright = [sender doubleValue];
    return self;
}

-varyPitch:sender
{
    varyPitch = !varyPitch;
    return self;
}

-varyBright:sender
{
    varyBright = !varyBright;
    return self;
}

-varySus:sender
{
    varySus = !varySus;
    return self;
}

-varyRate:sender
{
    varyRate = !varyRate;
    return self;
}

-setInterval:sender
{
    int tag = [[sender selectedCell] tag];
    interval = (tag == 0) ? .0625 : (tag == 1) ? .125 : (tag == 2) ? .25 : (tag == 3) ? .5 : 1;
    varyInterval = (tag == 5); 
    interval = interval/12.0;
    return self;
}

- setEchoAmp:sender
{
    echoAmp = [sender doubleValue];
    [Conductor lockPerformance];
    setDramEchoScale(echoAmp);
    [Conductor unlockPerformance];
    return self;
}

- setEchoDur:sender
{
    int delayLength = [sender intValue];
    [Conductor lockPerformance];
    setDramEchoDelay(delayLength);
    [Conductor unlockPerformance];
    return self;
}

- terminate:sender
{
    int i,j;
    [Conductor lockPerformance];
    for (j=0; j<=6; j++)
      for (i=1; i<=4; i++) 
	[dspPatch[i][j] dealloc];
    for (j=0; j<HUB_PATCHES; j++) 
      [dspPatch[5][j] dealloc];
    if (useNeXTDSP)
      for (j=0; j<=6; j++)
	[dspPatch[0][j] dealloc];
    [Conductor finishPerformance];       
    [Conductor unlockPerformance];
    [Orchestra close];     /* Free Orchestra resources and release the DSP. */ 
    return [super terminate:self];
}

@end


