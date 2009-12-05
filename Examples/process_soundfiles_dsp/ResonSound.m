/* Copyright CCRMA, 1992.  All rights reserved. */
/* This example non-real-time SynthPatch resonates and applies an envelope
   to a mono 16-bit sound file.  This is done on the DSP
   using the Music Kit. Since the SynthPatch is instantiable, many soundfiles
   can be mixed/resonated at the same time. 

   The algorithm implemented by this SynthPatch is as follows:

   out[i] = (sound[i] * envelope[i] + delay[i-N] * feedbackGain)

   See README for details. - David A. Jaffe */
  
#import <musickit/musickit.h>    
#import <musickit/unitgenerators/unitgenerators.h> 
#import "ResonSound.h"
#import "ReadsoundUGxx.h"
#import <appkit/nextstd.h>

@implementation ResonSound

/* Indecies into List of UnitGenerators and Patchpoints. This List is the 
   instance variable 'synthElements'. */
static int soundReader,xPP,yPP,envelope,stereoOut,envScale,delayPP,delay,
  delayScaler,constPP,outPP;

#define SE NX_ADDRESS(synthElements) /* Make synth element access easy */

+ patchTemplateFor:aNote
  /* Create the PatchTemplate if it doesn't exist. This is the specification
     of how to make a new SynthPatch of this kind */
{
    static id theTemplate = nil;
    if (theTemplate)
      return theTemplate;
    theTemplate = [PatchTemplate new];

    /* Two reusable patchpoints and two dedicated patchpoints. */
    xPP = [theTemplate addPatchpoint:MK_xPatch];
    yPP = [theTemplate addPatchpoint:MK_yPatch];
    constPP = [theTemplate addPatchpoint:MK_xPatch];
    outPP = [theTemplate addPatchpoint:MK_xPatch];
    delayPP = [theTemplate addPatchpoint:MK_xPatch];

    /* Add UnitGenerator allocation specifications */
    soundReader = [theTemplate addUnitGenerator:[ReadsoundUGxx class]];
    envelope = [theTemplate addUnitGenerator:[AsympUGy class]];
    envScale = [theTemplate addUnitGenerator:[Mul1add2UGxxyx class]];
    delay = [theTemplate addUnitGenerator:[DelayUGxxy class]];
    delayScaler = [theTemplate addUnitGenerator:[Mul2UGxxx class]];
    stereoOut = [theTemplate addUnitGenerator:[Out2sumUGx class]]; 
    return theTemplate;
}

static int soundfilePar;             /* For application-defined parameters  */
static int feedbackGainPar;

#define DEBUG 1

+ initialize
  /* Sent once when class is initialized. */
{
#if DEBUG
    [UnitGenerator enableErrorChecking:YES]; /* A good idea, when debugging */
#endif    
    soundfilePar = [Note parName:"soundfile"]; /* Get parameter number */
    feedbackGainPar = [Note parName:"feedbackGain"]; 
    return self;
}

- _setDefaults
  /* A local method that resets instance vars and idles output. */
{
    bearing = 0;
    soundfile = NULL;
    amp = MK_DEFAULTAMP;
    ampEnv = nil;
    ampAtt = MK_NODVAL;
    ampRel = MK_NODVAL;
    feedbackGain = .95;
    if (soundfile)
      NX_FREE(soundfile);
    soundfile = NULL;
    [SE[soundReader] setSound:nil]; /* Cancel old sound, if any. */
    [SE[stereoOut] idle]; 
    [SE[constPP] setToConstant:DSPDoubleToFix24(feedbackGain)];
    return self;
}

-init
{
    [SE[soundReader] setOutput:SE[xPP]];
    [SE[envelope] setOutput:SE[yPP]];
    [SE[envScale] setInput3:SE[xPP]];
    [SE[envScale] setInput2:SE[yPP]];
    [SE[envScale] setInput1:SE[delayPP]];
    [SE[envScale] setOutput:SE[outPP]];
    [SE[delay] setInput:SE[outPP]];
    [SE[delay] setOutput:SE[delayPP]];
    [SE[delayScaler] setInput1:SE[delayPP]];
    [SE[delayScaler] setInput2:SE[constPP]];
    [SE[delayScaler] setOutput:SE[delayPP]];
    [self _setDefaults];
    return self;
}

- _applyParameters:aNote
  /* A local method that applies parameters in the current Note. */ 
{
    MKPhraseStatus ps = [self phraseStatus];
    BOOL isNewPhrase = (ps == MK_phraseOn || ps == MK_phraseOnPreempt);
    BOOL isNewNote = (ps == MK_phraseRearticulate || isNewPhrase);
    BOOL noteHasBearing = [aNote isParPresent:MK_bearing];
    BOOL noteHasSoundfile = [aNote isParPresent:soundfilePar];
    BOOL noteHasAmp = [aNote isParPresent:MK_amp];
    BOOL noteHasAmpEnv = [aNote isParPresent:MK_ampEnv];
    BOOL noteHasAmpAtt = [aNote isParPresent:MK_ampAtt];
    BOOL noteHasAmpRel = [aNote isParPresent:MK_ampRel];
    BOOL noteHasFreq = [aNote isParPresent:MK_freq];
    BOOL noteHasFeedbackGain = [aNote isParPresent:feedbackGainPar];

    /* First update instance vars. */
    if (noteHasFreq) freq = [aNote parAsDouble:MK_freq];
    if (noteHasBearing) bearing = [aNote parAsDouble:MK_bearing];
    if (noteHasAmp)     amp     = [aNote parAsDouble:MK_amp];
    if (noteHasAmpEnv)  ampEnv  = [aNote parAsEnvelope:MK_ampEnv];
    if (noteHasAmpAtt)  ampAtt  = [aNote parAsDouble:MK_ampAtt];
    if (noteHasAmpRel)  ampRel  = [aNote parAsDouble:MK_ampRel];
    if (noteHasFeedbackGain)  feedbackGain = [aNote parAsDouble:feedbackGainPar];
    if (noteHasSoundfile) {            
	if (soundfile)
	  NX_FREE(soundfile);          /* parAsString: copies */
	soundfile = [aNote parAsString:soundfilePar];
    }

    /* Then update UnitGenerators */
    if (noteHasSoundfile || isNewPhrase) { /* Need to set soundfile? */
	if (!soundfile && (strlen(soundfile) == 0)) { /* No name? */
	    MKError("No soundfile specified.");
	    return nil;
	}
	if (![SE[soundReader] setSoundfile:soundfile]) 
	  return nil;
    }
    if (noteHasFreq || isNewPhrase) {
	/* Crude tuning of resonator.  This tuning is quantized to the delay
	   length.  To see how to do fine tuning, see the code to Pluck
	   in the MusicKitSource package or read the paper "Extensions of
	   the Karplus Strong Algorithm" by Jaffe & Smith (Computer Music
	   Journal, 1983)
	   */
        #define PIPE 16 /* One tick of delay is implicit */
	int delayLen = [orchestra samplingRate]/freq - PIPE;
	if (delayLen < 0)
	  delayLen = 1;
	[delayMem free]; 
	delayMem = [[self orchestra] allocSynthData:MK_yData length:delayLen];
	if (!delayMem)
	  fprintf(stderr,"Can't allocate delay memory\n");
	[delayMem clear];
	[SE[delayPP] clear]; /* Clear pipe */
	[SE[delay] setDelayMemory:delayMem];
    }
    if (noteHasBearing || isNewPhrase) /* Need to set bearing? */
      [SE[stereoOut] setBearing:bearing];
    if (isNewPhrase || noteHasFeedbackGain)
      [SE[constPP] setToConstant:DSPDoubleToFix24(feedbackGain)];
    if (isNewNote || noteHasAmp || noteHasAmpEnv || noteHasAmpAtt || 
	noteHasAmpRel) 
      MKUpdateAsymp(SE[envelope],ampEnv,0,amp,ampAtt,ampRel,MK_NODVAL,ps);
    return self;
}

- noteOnSelf:aNote
{
    if (![self _applyParameters:aNote])
      return nil;
    [SE[stereoOut] setInput:SE[outPP]];
    [synthElements makeObjectsPerform:@selector(run)]; 
    return self;
}

- noteUpdateSelf:aNote
  /* We support parameter changing in NoteUpdates. */
{
    return [self _applyParameters:aNote];
}

-(double) noteOffSelf:aNote
{
    if (![self _applyParameters:aNote]) {
	[SE[envelope] abortEnvelope];
	return 0;
    }
    return [SE[envelope] finish];
}

- noteEndSelf
  /* This resets the patch at the end of a phrase */
{
    [self _setDefaults];
    [SE[delay] setDelayMemory:nil];
    [delayMem free];
    delayMem = nil;
    return self;
}

- preemptFor:aNote
  /* This resets the patch when a preemption occurs. */
{
    [SE[envelope] preemptEnvelope];
    [SE[delay] setDelayMemory:nil];
    [self _setDefaults];
    return self;
}

@end
