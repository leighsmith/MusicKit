/* The following files must be imported. */
#import <musickit/musickit.h>    
#import <musickit/unitgenerators/unitgenerators.h> 
#import "BiquadUGy.h"

#import "HoseIns.h"

@implementation HoseIns;

/* Statically declare the synthElement indices. */
static int		ampAsymp,   /* amplitude envelope UG */
			lipDifference,      /* adder to get net lip pressure */
			lipFilter,      /* biquad Filter */
			lipSquarer,      /* multiplier to fake reed table */
			lipProduct,      /* multiplier to calculate pressure */
			delayLine,      /* delay UG */
			gainElement,
			stereoOut,   /* output UG */
    			
			lipDiffPp,
    			lipFiltPp,
    			lipSquarerPp,
    			lipProductPp,
    			delayPp,
			gainPp,
			ampPp, /* amplitude patchpoint */
			outPp; /* output patchpoint */

+ (void)patchTemplateFor:aNote
{
    /* Step 1: Create (or return) the PatchTemplate. */
    static id theTemplate = nil;
    if (theTemplate)
      return theTemplate;
    theTemplate = [PatchTemplate new];

    /* Step 2:  Add the SynthElement specifications. */	
    ampAsymp = [theTemplate addUnitGenerator:[AsympUGx class]];
    lipDifference = [theTemplate addUnitGenerator:[Scl1add2UGyxx class]];
    lipFilter = [theTemplate addUnitGenerator:[BiquadUGy class]];
    lipSquarer = [theTemplate addUnitGenerator:[Mul2UGxyy class]];
    lipProduct = [theTemplate addUnitGenerator:[Mul2UGyxx class]];
    delayLine = [theTemplate addUnitGenerator:[DelayUGxyy class]];
    gainElement = [theTemplate addUnitGenerator:[ScaleUGyy class]];

    stereoOut = [theTemplate addUnitGenerator:[Out2sumUGy class]];

    lipDiffPp = [theTemplate addPatchpoint:MK_yPatch];
    lipFiltPp = [theTemplate addPatchpoint:MK_yPatch];
    lipSquarerPp = [theTemplate addPatchpoint:MK_xPatch];
    lipProductPp = [theTemplate addPatchpoint:MK_yPatch];
    delayPp = [theTemplate addPatchpoint:MK_xPatch];
    gainPp = [theTemplate addPatchpoint:MK_yPatch];
    ampPp = [theTemplate addPatchpoint:MK_xPatch];
    outPp = [theTemplate addPatchpoint:MK_yPatch];

    /* Step 3:  Specify the connections. */
    [theTemplate to:ampAsymp sel:@selector(setOutput:) arg:ampPp];
    
    [theTemplate to:lipDifference sel:@selector(setOutput:) arg:lipDiffPp];
    [theTemplate to:lipDifference sel:@selector(setInput1:) arg:delayPp];
    [theTemplate to:lipDifference sel:@selector(setInput2:) arg:ampPp];

    [theTemplate to:lipFilter sel:@selector(setOutput:) arg:lipFiltPp];
    [theTemplate to:lipFilter sel:@selector(setInput:) arg:lipDiffPp];

    [theTemplate to:lipSquarer sel:@selector(setOutput:) arg:lipSquarerPp];
    [theTemplate to:lipSquarer sel:@selector(setInput1:) arg:lipFiltPp];
    [theTemplate to:lipSquarer sel:@selector(setInput2:) arg:lipFiltPp];

    [theTemplate to:lipProduct sel:@selector(setOutput:) arg:lipProductPp];
    [theTemplate to:lipProduct sel:@selector(setInput1:) arg:lipSquarerPp];
    [theTemplate to:lipProduct sel:@selector(setInput2:) arg:ampPp];

    [theTemplate to:delayLine sel:@selector(setOutput:) arg:delayPp];
    [theTemplate to:delayLine sel:@selector(setInput:) arg:lipProductPp];

    [theTemplate to:gainElement sel:@selector(setOutput:) arg:gainPp];
    [theTemplate to:gainElement sel:@selector(setInput:) arg:lipProductPp];

    /* Return the PatchTemplate. */	
    return theTemplate;
}

- init
{
    /* Sent once when the patch is created. */
    return self;
}

- setDefaults
{
    ampEnv  = nil;	
    amp0    = 0.0;
    amp1    = MK_DEFAULTAMP;  /* 0.1 */
    ampAtt  = MK_NODVAL;      /* parameter not present */
    ampRel  = MK_NODVAL;      /* parameter not present */

    portamento = MK_DEFAULTPORTAMENTO; 	/* 0.1 */
    bearing = MK_DEFAULTBEARING;		/* 0.0 (centered) */
    
    return self;
}

- (void)preemptFor:aNote
{
    [[self synthElementAt:ampAsymp] preemptEnvelope]; 
    [self setDefaults]; 
}

- applyParameters:aNote
  /* This is a private method to the InsTwoWaves class. It is used internally only.
     */
{
    /* Retrieve and store the parameters. */
    id		myAmpEnv = [aNote parAsEnvelope:MK_ampEnv];
    double	myAmp0   = [aNote parAsDouble:MK_amp0];
    double	myAmp1   = [aNote parAsDouble:MK_amp1];
    double	myAmpAtt = [aNote parAsDouble:MK_ampAtt];
    double	myAmpRel = [aNote parAsDouble:MK_ampAtt];


    int		MY_envelopeSlew = [[Note class] parName: "MY_envelopeSlew"];
    double	myEnvelopeSlew   = [aNote parAsDouble:MY_envelopeSlew];

    int		MY_outAmp = [[Note class] parName: "MY_outAmp"];
    int		MY_dLineLength = [[Note class] parName: "MY_dLineLength"];
    int		MY_lipCoeff1 = [[Note class] parName: "MY_lipCoeff1"];
    int		MY_lipCoeff2 = [[Note class] parName: "MY_lipCoeff2"];
    int		MY_lipFiltGain = [[Note class] parName: "MY_lipFiltGain"];
    double	myOutAmp   = [aNote parAsDouble:MY_outAmp];
    double	myDLineLength   = [aNote parAsDouble:MY_dLineLength];
    double	myLipCoeff1 = [aNote parAsDouble:MY_lipCoeff1];
    double	myLipCoeff2 = [aNote parAsDouble:MY_lipCoeff2];
    double	myLipFiltGain = [aNote parAsDouble:MY_lipFiltGain];

    double	myPortamento = [aNote parAsDouble:MK_portamento];
    double	myBearing    = [aNote parAsDouble:MK_bearing];

    /* Store the phrase status. */	
    MKPhraseStatus phraseStatus = [self phraseStatus];

    /* Is aNote a noteOn? */
    BOOL isNoteOn = [aNote noteType] == MK_noteOn;

    /* Is aNote the beginning of a new phrase? */
    BOOL isNewPhrase = (phraseStatus == MK_phraseOn) || 
                       (phraseStatus == MK_phraseOnPreempt);

    /* Used in the parameter checks. */
    BOOL shouldApplyAmp = NO;
    BOOL shouldApplyBearing = NO;	

    [[self synthElementAt:lipDifference] setScale: 0.9];
    
    /* The same portamento is used in both frequency and amplitude. */
    if (!MKIsNoDVal(myPortamento)) {
        portamento = myPortamento;
        shouldApplyAmp = YES;}	

    if (!MKIsNoDVal(myEnvelopeSlew)) {
             [[self synthElementAt:ampAsymp] setT60: myEnvelopeSlew];
	     		// Hack this for slew on breath pressure
    }
    
    /* Check the amplitude parameters and set the instance variables. */
    if (myAmpEnv != nil) {
        ampEnv = myAmpEnv;
        shouldApplyAmp = YES; }
    if (!MKIsNoDVal(myAmp0)) {
        amp0 = myAmp0;
        shouldApplyAmp = YES; }
    if (!MKIsNoDVal(myAmp1)) {
        amp1 = myAmp1;
	[[self synthElementAt:ampAsymp] abortEnvelope];
	[[self synthElementAt:ampAsymp] setT60: 0.01];
	[[self synthElementAt:ampAsymp] setTargetVal:amp1]; }
    if (!MKIsNoDVal(myAmpAtt)) {
        ampAtt = myAmpAtt;
        shouldApplyAmp = YES; }
    if (!MKIsNoDVal(myAmpRel)) {
        ampRel = myAmpRel;
        shouldApplyAmp = YES; }
    /* Apply the amplitude parameters. */
    if (shouldApplyAmp || isNoteOn)	{
      MKUpdateAsymp([self synthElementAt:ampAsymp], 
                    ampEnv, amp0, amp1, ampAtt, ampRel, 
                    portamento, phraseStatus);
    }

   /* Check and set the bearing. */
   if (!MKIsNoDVal(myBearing)) {
        bearing = myBearing;
        shouldApplyBearing = YES; }
   if (shouldApplyBearing || isNewPhrase)
     [[self synthElementAt:stereoOut] setBearing:bearing];

   /* Check and set the fader level. */
   if (!MKIsNoDVal(myOutAmp)) {
        outAmp = myOutAmp;
        [[self synthElementAt:gainElement] setScale:outAmp];
   }

   if (!MKIsNoDVal(myLipCoeff1)) {
        lipCoefficient1 = myLipCoeff1;
        lipCoefficient2 = myLipCoeff2;
        lipFiltGain = myLipFiltGain;
     [[self synthElementAt:lipFilter] setA1:lipCoefficient1];
     [[self synthElementAt:lipFilter] setA2:lipCoefficient2];
     [[self synthElementAt:lipFilter] setB1:0];
     [[self synthElementAt:lipFilter] setB2:0];
     [[self synthElementAt:lipFilter] setGain:lipFiltGain];
   }

   if (!MKIsNoDVal(myDLineLength)) {
        dLineLength = myDLineLength;
     [[self synthElementAt:delayLine] adjustLength:(int) dLineLength];
   }

  return self;
}    

- (void)noteOnSelf:aNote
{
    delayMemory = [Orchestra allocSynthData:MK_yData length:275];
    [[self synthElementAt: delayLine] setDelayMemory: delayMemory];
    [delayMemory setToConstant:0 length:275 offset:0];  
    /* Apply the parameters to the patch. */	
    [self applyParameters:aNote];

    /* Make the final connection to the output sample stream. */	
    [[self synthElementAt:stereoOut] setInput:[self synthElementAt:gainPp]];

    /* Tell the UnitGenerators to begin running. */	
    [synthElements makeObjectsPerform:@selector(run)]; 
}

- (void)noteUpdateSelf:aNote
{
    /* Apply the parameters to the patch. */	
    [self applyParameters: aNote]; 
}

- (double)noteOffSelf:aNote
{   
    /* Apply the parameters. */
    [self applyParameters: aNote];

    /* Same for amplitude, but also return the release duration. */
    return [[self synthElementAt:ampAsymp] finish];
}

- (void)noteEndSelf
{
    /* Remove the patch's Out2sum from the output sample stream. */
    [[self synthElementAt:stereoOut] idle]; 

    /* Abort the frequency Envelope. */
    [[self synthElementAt:ampAsymp] abortEnvelope];

    /* Set the instance variables to their default values. */ 
    [self setDefaults]; 
}

@end
