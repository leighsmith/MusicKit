/* Copyright CCRMA, 1992.  All rights reserved. */
/* This example SynthPatch envelopes a mono 16-bit sound file through the DSP
   using the Music Kit. Since the SynthPatch is instantiable, many soundfiles
   can be mixed at the same time. See README for details. */
  
#import <musickit/musickit.h>    
#import <musickit/unitgenerators/unitgenerators.h> 
#import "EnvelopeSound.h"
#import "ReadsoundUGxx.h"
#import <appkit/nextstd.h>

@implementation EnvelopeSound

/* Indecies into List of UnitGenerators and Patchpoints. This List is the 
   instance variable 'synthElements'. */
static int soundReader,xPP,yPP,envelope,stereoOut,multiply;

+ patchTemplateFor:aNote
  /* Create the PatchTemplate if it doesn't exist. This is the specification
     of how to make a new SynthPatch of this kind */
{
    static id theTemplate = nil;
    if (theTemplate)
      return theTemplate;
    theTemplate = [PatchTemplate new];

    /* Add patchpoint allocation specifications */
    xPP = [theTemplate addPatchpoint:MK_xPatch];
    yPP = [theTemplate addPatchpoint:MK_yPatch];

    /* Add UnitGenerator allocation specifications */
    soundReader = [theTemplate addUnitGenerator:[ReadsoundUGxx class]];
    envelope = [theTemplate addUnitGenerator:[AsympUGy class]];
    multiply = [theTemplate addUnitGenerator:[Mul2UGxyx class]];
    stereoOut = [theTemplate addUnitGenerator:[Out2sumUGx class]]; 

    return theTemplate;
}

#define SE NX_ADDRESS(synthElements) /* Make synth element access easy */

static int soundfilePar;             /* For application-defined parameters  */

#define DEBUG 1

+ initialize
  /* Sent once when class is initialized. */
{
#if DEBUG
    [UnitGenerator enableErrorChecking:YES]; /* A good idea, when debugging */
#endif    
    soundfilePar = [Note parName:"soundfile"]; /* Get parameter number */
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
    if (soundfile)
      NX_FREE(soundfile);
    soundfile = NULL;
    [SE[soundReader] setSound:nil]; /* Cancel old sound, if any. */
    [SE[stereoOut] idle]; 
    return self;
}

- init
{
    /* Add patching instructions */
    [SE[soundReader] setOutput:SE[xPP]];
    [SE[envelope] setOutput:SE[yPP]];
    [SE[multiply] setInput2:SE[xPP]];
    [SE[multiply] setInput1:SE[yPP]];
    [SE[multiply] setOutput:SE[xPP]];
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

    /* First update instance vars. */
    if (noteHasBearing) bearing = [aNote parAsDouble:MK_bearing];
    if (noteHasAmp)     amp     = [aNote parAsDouble:MK_amp];
    if (noteHasAmpEnv)  ampEnv  = [aNote parAsEnvelope:MK_ampEnv];
    if (noteHasAmpAtt)  ampAtt  = [aNote parAsDouble:MK_ampAtt];
    if (noteHasAmpRel)  ampRel  = [aNote parAsDouble:MK_ampRel];
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
    if (noteHasBearing || isNewPhrase) /* Need to set bearing? */
      [SE[stereoOut] setBearing:bearing];
    if (isNewNote || noteHasAmp || noteHasAmpEnv || noteHasAmpAtt || 
	noteHasAmpRel) 
      MKUpdateAsymp(SE[envelope],ampEnv,0,amp,ampAtt,ampRel,MK_NODVAL,ps);
    return self;
}

- noteOnSelf:aNote
{
    if (![self _applyParameters:aNote])
      return nil;
    [SE[stereoOut] setInput:SE[xPP]];
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
    return self;
}

- preemptFor:aNote
  /* This resets the patch when a preemption occurs. */
{
    [SE[envelope] preemptEnvelope];
    [self _setDefaults];
    return self;
}

@end
