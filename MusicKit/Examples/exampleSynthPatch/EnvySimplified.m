/* This is similar to Envy.m but it makes a number of assumptions about the
   Application that allow it to be much simpler:

   It assumes that all parameters will be present in every note and that 
   only noteDurs without noteTags are used (as in software packages such as 
   CSound, C-Music, or MUSIC 5). It also assumes that it will never be 
   necessary to preempt running SynthPatches because the Application will 
   never attempt to play too many simultaneous notes.  

   Keep in mind that a convenient way to insure
   that parameters are present in every note is to include all parameters
   in an initial noteUpdate without a noteTag (this noteUpdate is merged
   into incoming noteDurs by the Music Kit.) 
   
   The parameters are:

        amp, ampEnv, ampAtt, ampRel, 
        freq0, freq1, freqEnv, freqAtt, freqRel, bearing

   See README for details.
*/

#import <MKUnitGenerators/UnitGenerators.h> 
#import "EnvySimplified.h"

@implementation EnvySimplified

static int ampAsymp, freqAsymp, osc, stereoOut, ampPp, freqPp, outPp; 

+patchTemplateFor:aNote
{   /* Returns a template describing the UnitGenerators and Patchpoints that
       comprise the patch. */
    static PatchTemplate *theTemplate = nil;
    if (theTemplate)           
	return theTemplate;
    theTemplate = [[PatchTemplate alloc] init];
    ampAsymp    = [theTemplate addUnitGenerator:[AsympUGx class]];
    freqAsymp   = [theTemplate addUnitGenerator:[AsympUGy class]];
    osc         = [theTemplate addUnitGenerator:[OscgafiUGxxyy class]];
    stereoOut   = [theTemplate addUnitGenerator:[Out2sumUGx class]];
    ampPp       = [theTemplate addPatchpoint:MK_xPatch];
    freqPp      = [theTemplate addPatchpoint:MK_yPatch];
    outPp       = ampPp;  /* Reuse this patchpoint. */
    return theTemplate;
}

/* Let's define a macro SE ("synth element") to make access more terse: */
#define SE(x) [self synthElementAt:x] 

- init
{   /* Sent once when the patch is created. */
    [SE(ampAsymp) setOutput:SE(ampPp)];
    [SE(freqAsymp) setOutput:SE(freqPp)];
    [SE(osc) setAmpInput:SE(ampPp)];
    [SE(osc) setIncInput:SE(freqPp)];
    [SE(osc) setOutput:SE(outPp)];
    [SE(osc) setTable:nil defaultToSineROM:YES];
    return self;
}

- noteOnSelf:aNote
{   /* Sent when a noteOn is received */
    Envelope *ampEnv = [aNote parAsEnvelope:MK_ampEnv];
    double amp    = [aNote parAsDouble:MK_amp];
    double ampAtt = [aNote parAsDouble:MK_ampAtt];
    double ampRel = [aNote parAsDouble:MK_ampRel];
    Envelope *freqEnv = [aNote parAsEnvelope:MK_freqEnv];
    double freq0   = [aNote parAsDouble:MK_freq0];
    double freq1   = [aNote freq];
    double freqAtt = [aNote parAsDouble:MK_freqAtt];
    double freqRel = [aNote parAsDouble:MK_freqRel];
    double bearing = [aNote parAsDouble:MK_bearing];
    MKUpdateAsymp(SE(ampAsymp), ampEnv, 0.0, amp, ampAtt, ampRel, 
		  MK_NODVAL, MK_phraseOn);  /* Amplitude envelope */
    MKUpdateAsymp(SE(freqAsymp), freqEnv, 
		  [SE(osc) incAtFreq:freq0], [SE(osc) incAtFreq:freq1], 
		  freqAtt, freqRel, MK_NODVAL, MK_phraseOn); /* Freq env */
    [SE(stereoOut) setBearing:bearing];      
    [SE(stereoOut) setInput:SE(outPp)]; /* Make connection to output */
    [synthElements makeObjectsPerform:@selector(run)]; /* Broadcast "run" */
    return self;
}    

- (double)noteOffSelf:aNote
{   /* Sent when a noteOff is received */
    [SE(freqAsymp) finish]; /* Signal release portion of freq envelope */
    return [SE(ampAsymp) finish]; /* Return amplitude env's time to finish */
}

- noteEndSelf
{   /* Sent when the patch is to go idle (at the end of the ampEnv release). */
    [SE(stereoOut) idle];           /* Remove output from sample stream. */
    [SE(freqAsymp) abortEnvelope];  /* Abort the freq envelope */
    return self;
}

@end

