/* The following files must be imported. */
#ifndef UNITGENERATORS_H
#define UNITGENERATORS_H

#import <MusicKit/MusicKit.h>
#import	<MKUnitGenerators/Add2UGxxx.h> 
#import <MKUnitGenerators/Add2UGyyy.h> 
#import <MKUnitGenerators/AsympUGy.h> 
#import <MKUnitGenerators/DelayUGyxx.h> 
#import <MKUnitGenerators/Mul2UGyyy.h> 
#import <MKUnitGenerators/OscgUGyy.h> 
#import <MKUnitGenerators/OscgafiUGxyyy.h> 
#import <MKUnitGenerators/Out1aUGx.h> 
#import <MKUnitGenerators/Out1bUGy.h> 

#define MK_OSCFREQSCALE 256.0 /* Used by Oscg and Oscgaf */
#endif UNITGENERATORS_H

#import "Bark.h"

@implementation Bark:SynthPatch
{
	id LoochWave;
}

static int i = 0;

/* A static integer is created for each synthElement. */
static int	osc[2],        	/* wave UG */
		ampEnvUG,	/* amplitude envelope UG */
		ampPatchpoint,	/* amplitude patch point */
		freqOscUG[2],	/* frequency vibrato UG */
		vibDeviateUG[2],	/* base deviation of note */
		vibMulUG[2],	/* vibrato increment calculator */
		vibMulIn1[2],	/* vib oscil input patch point */
		vibMulIn2[2],	/* vib base input patch point */
		vibBaseUG[2],	/* base frequency of note */
		freqEnvUG[2],	/* frequency of note adder */
		freqEnvIn1[2],	/* freq adder input 1 */
		freqEnvIn2[2],	/* freq adder input 2 */
		freqPatchpoint[2],	/* frequency patch point */
		oscOutPatchpoint[2],	/* output of the two oscil chains */
		oscSum,		/* add the two oscil chains */
		delayUG,	/* digital delay unit generator */
		delayIn,	/* delay line input patch point */
		delayOut,	/* delay line output patch point */
		stereoOutA,	/* sound output UG for channel 0 */
		stereoOutB,	/* sound output UG for channel 1 */
		outPatchpointA,	/* SynthData */
		outPatchpointB, /* SynthData -- whatever */
		DelayLine;	/* SynthData memory for delay */

+ patchTemplateFor:aNote
/* The argument is ignored in this implementation. */
{
    int DelayLength,j;

    /* Step 1: Create an instance of the PatchTemplate class. */
    static id theTemplate = nil;
// I took this out to give me four different templates for 4 delay lines
//    if (theTemplate)
//      return theTemplate;
    theTemplate = [PatchTemplate new];

    /* Step 2: Add synthElement specifications to the PatchTemplate.  */
    ampEnvUG = [theTemplate addUnitGenerator:[AsympUGy class]];
  for (j = 0; j < 2; j++) {
    vibBaseUG[j] = [theTemplate addUnitGenerator:[AsympUGy class]];
    vibDeviateUG[j] = [theTemplate addUnitGenerator:[AsympUGy class]];
    freqOscUG[j] = [theTemplate addUnitGenerator:[OscgUGyy class]];
    vibMulUG[j] = [theTemplate addUnitGenerator:[Mul2UGyyy class]];
    freqEnvUG[j] = [theTemplate addUnitGenerator:[Add2UGyyy class]];
    osc[j] = [theTemplate addUnitGenerator:[OscgafiUGxyyy class]];
  }

    oscSum = [theTemplate addUnitGenerator:[Add2UGxxx class]];
    delayUG = [theTemplate addUnitGenerator:[DelayUGyxx class]];
    stereoOutA = [theTemplate addUnitGenerator:[Out1aUGx class]];
    stereoOutB = [theTemplate addUnitGenerator:[Out1bUGy class]];
    
    switch(i) {
	case 0:
		DelayLength = 500;
		break;
	case 1:
		DelayLength = 85;
		break;
	case 2:
		DelayLength = 40;
		break;
	case 3:
		DelayLength = 5;
		break;
	default:
		fprintf(stderr,"DelayLength problems!\n");
		DelayLength = 1;
	}

    DelayLine = [theTemplate addSynthData:MK_xData length:DelayLength];
    
    ampPatchpoint = [theTemplate addPatchpoint:MK_yPatch];
  for (j = 0; j < 2; j++) {
    vibMulIn1[j] = [theTemplate addPatchpoint:MK_yPatch];
    vibMulIn2[j] = [theTemplate addPatchpoint:MK_yPatch];
    freqEnvIn1[j] = [theTemplate addPatchpoint:MK_yPatch];
    freqEnvIn2[j] = [theTemplate addPatchpoint:MK_yPatch];
    freqPatchpoint[j] = [theTemplate addPatchpoint:MK_yPatch];
    oscOutPatchpoint[j] = [theTemplate addPatchpoint:MK_xPatch];
  }
    delayIn = [theTemplate addPatchpoint:MK_xPatch];
    delayOut = [theTemplate addPatchpoint:MK_yPatch];
    outPatchpointA = [theTemplate addPatchpoint:MK_xPatch];
    outPatchpointB = [theTemplate addPatchpoint:MK_yPatch];

    /* Step 3:  Specify the connections between synthElements. */
    [theTemplate to:ampEnvUG sel:@selector(setOutput:) arg:ampPatchpoint];
  for (j = 0; j < 2; j++) {
    [theTemplate to:freqOscUG[j] sel:@selector(setOutput:) arg:vibMulIn1[j]];
    [theTemplate to:vibDeviateUG[j] sel:@selector(setOutput:)
    						arg:vibMulIn2[j]];
    [theTemplate to:vibMulUG[j] sel:@selector(setInput1:) arg:vibMulIn1[j]];
    [theTemplate to:vibMulUG[j] sel:@selector(setInput2:) arg:vibMulIn2[j]];
    [theTemplate to:vibMulUG[j] sel:@selector(setOutput:) arg:freqEnvIn1[j]];
    [theTemplate to:vibBaseUG[j] sel:@selector(setOutput:) arg:freqEnvIn2[j]];
    [theTemplate to:freqEnvUG[j] sel:@selector(setInput1:) arg:freqEnvIn1[j]];
    [theTemplate to:freqEnvUG[j] sel:@selector(setInput2:) arg:freqEnvIn2[j]];
    [theTemplate to:freqEnvUG[j] sel:@selector(setOutput:)
    						arg:freqPatchpoint[j]];
    [theTemplate to:osc[j] sel:@selector(setAmpInput:) arg:ampPatchpoint];
    [theTemplate to:osc[j] sel:@selector(setIncInput:) arg:freqPatchpoint[j]];
    [theTemplate to:osc[j] sel:@selector(setOutput:) arg:oscOutPatchpoint[j]];
  }
    [theTemplate to:oscSum sel:@selector(setInput1:) arg:oscOutPatchpoint[0]];
    [theTemplate to:oscSum sel:@selector(setInput2:) arg:oscOutPatchpoint[1]];
    [theTemplate to:oscSum sel:@selector(setOutput:) arg:outPatchpointA];
    [theTemplate to:stereoOutA sel:@selector(setInput:) arg:outPatchpointA];
    [theTemplate to:delayUG sel:@selector(setInput:) arg:outPatchpointA];
    [theTemplate to:delayUG sel:@selector(setOutput:) arg:outPatchpointB];
    [theTemplate to:stereoOutB sel:@selector(setInput:) arg:outPatchpointB];
    [theTemplate to:delayUG sel:@selector(setDelayMemory:) arg:DelayLine];

    /* Always return the PatchTemplate. */
    return theTemplate;
}

- applyParameters:aNote
  /* This is a private method to the Envy class. It is used internally only.
     */
{
	/* Retrieve and store the parameters. */	
	double	myFreq0 = [aNote parAsDouble:MK_freq0];
	double  myFreq1 = [aNote parAsDouble:MK_freq1];
        double	FreqInc;
	double	myAmp = [aNote parAsDouble:MK_amp];
//	double	myBearing = [aNote parAsDouble:MK_bearing];
	double	myVibFreq0 = [aNote parAsDouble:MK_svibFreq];
	double	myVibAmp0 = [aNote parAsDouble:MK_svibAmp];
	double	myVibFreq1 = [aNote parAsDouble:MK_rvibFreq];
	double	myVibAmp1 = [aNote parAsDouble:MK_rvibAmp];
	double	FreqIncHi;
	LoochWave = [aNote parAsWaveTable:MK_waveform];
	
	/* set wavetable if present */
	if (LoochWave != nil) {
		[[self synthElementAt:osc[0]] setTable:LoochWave length:64 
						defaultToSineROM:YES];
		[[self synthElementAt:osc[1]] setTable:LoochWave length:64
						defaultToSineROM:YES];
		}

	/* Apply frequency if present. */
	if (myFreq0 != MAXDOUBLE) {
		FreqInc = [[self synthElementAt:osc[0]] incAtFreq:myFreq0];
		[[self synthElementAt:vibBaseUG[0]] setConstant:FreqInc];
		}
	if (myFreq1 != MAXDOUBLE) {
		FreqInc = [[self synthElementAt:osc[1]] incAtFreq:myFreq1];
		[[self synthElementAt:vibBaseUG[1]] setConstant:FreqInc];
		}
	
	/* Apply vibrato freq if present */
	if (myVibFreq0 != MAXDOUBLE) {
		[[self synthElementAt:freqOscUG[0]] setFreq:myVibFreq0];
		}
	if (myVibFreq1 != MAXDOUBLE) {
		[[self synthElementAt:freqOscUG[1]] setFreq:myVibFreq1];
		}
	
	/* Apply vibrato amplitude if present (amp in Hz) */
	if (myVibAmp0 != MAXDOUBLE) {
		FreqInc = [[self synthElementAt:osc[0]] incAtFreq:myFreq0];
		FreqIncHi = [[self synthElementAt:osc[0]]
					incAtFreq:(myFreq0+myVibAmp0)];
		[[self synthElementAt:vibDeviateUG[0]]
					setConstant:(FreqIncHi-FreqInc)];
		}
	if (myVibAmp1 != MAXDOUBLE) {
		FreqInc = [[self synthElementAt:osc[1]] incAtFreq:myFreq1];
		FreqIncHi = [[self synthElementAt:osc[1]]
					incAtFreq:(myFreq1+myVibAmp1)];
		[[self synthElementAt:vibDeviateUG[1]]
					setConstant:(FreqIncHi-FreqInc)];
		}

	/* Apply amplitude if present. */
	if (myAmp != MAXDOUBLE)
		[[self synthElementAt:ampEnvUG] setTargetVal:myAmp];

//	/* Apply bearing if present. */
//	if (myBearing != MAXDOUBLE)
//		[[self synthElementAt:stereoOut] setBearing:myBearing];
      
}

- noteOnSelf:aNote
{
   /* Step 1: Read the parameters in the Note and apply them to the patch. */
	[self applyParameters:aNote];

	[[self synthElementAt:ampEnvUG] setCurVal:0.0];
	[[self synthElementAt:ampEnvUG] setT60:[aNote parAsDouble:MK_ampAtt]];

    /* Step 2: Turn on the patch by connecting the Out2sumUGx object to the
	patchpoint and sending the run message to all the synthElements. */
	[[self synthElementAt:stereoOutA] 
                 setInput:[self synthElementAt:outPatchpointA]];
	[[self synthElementAt:stereoOutB] 
                 setInput:[self synthElementAt:outPatchpointB]];
	[synthElements makeObjectsPerform:@selector(run)]; 

	return self;
}

- noteUpdateSelf:aNote
{
	[self applyParameters:aNote];

	[[self synthElementAt:ampEnvUG] setTargetVal:0.0];
	[[self synthElementAt:ampEnvUG] setT60:[aNote parAsDouble:MK_ampRel]];

	return self;	
}

- (double)noteOffSelf:aNote
{
	[self applyParameters:aNote];

	return 0.0;
}

- noteEndSelf
{
    /* Deactivate the SynthPatch by idling the output. */
    [[self synthElementAt:stereoOutA] idle];
    [[self synthElementAt:stereoOutB] idle];
 
    return self;
}


- initialize
{
    /* Initialize is automatically sent once when an instance is created, after
       it's patch has been loaded. */    
    [[self synthElementAt:osc[0]] setTable:nil defaultToSineROM:YES];
    /* full output for vibrato */
    [[self synthElementAt:freqOscUG[0]] setAmp:1.0];
    
    [[self synthElementAt:osc[1]] setTable:nil defaultToSineROM:YES];
    /* full output for vibrato */
    [[self synthElementAt:freqOscUG[1]] setAmp:1.0];

    return self;
}  
@end