/* The following files must be imported. */
#import <musickit/musickit.h>    
#import <musickit/unitgenerators/unitgenerators.h> 

#import "FluteIns.h"

@implementation FluteIns;

/* Statically declare the synthElement indices. */
static int		ampAsymp,   /* amplitude envelope UG */
			inputNoise,
			inputMult,
			inputAdd,      /* adder for envelope and noise */
			inputAdd2,      /* adder to get exitation */
			jetSquarer,      /* multiplier to fake reed table */
			jetCuber,      /* multiplier to fake reed table */
			sigAdder,     /* adder to approximate sigmoid */
			jetAdder,      /* adder to get net jet pressure */
			reflFilter,      /* reflection filter */
			delayLine,      /* delay UG */
			delayLine2,      /* delay UG */
			gainElement,
			stereoOut,   /* output UG */
    			
			inputNoisePp,
			ampPp,			 /* amplitude patchpoint */
			inputMultPp,
			inputAddPp,
			inputAdd2Pp,
    			jetSquarerPp,
    			jetCuberPp,
    			sigAddPp,
			jetAddPp,
    			filterPp,
    			delayPp,
    			delay2Pp,
			gainPp; /* output patchpoint */

+patchTemplateFor:aNote
{
    /* Step 1: Create (or return) the PatchTemplate. */
    static id theTemplate = nil;
    if (theTemplate)
      return theTemplate;
    theTemplate = [PatchTemplate new];

    /* Step 2:  Add the SynthElement specifications. */	
    ampAsymp = [theTemplate addUnitGenerator:[AsympUGx class]];
    inputNoise = [theTemplate addUnitGenerator:[UnoiseUGy class]];
    inputMult = [theTemplate addUnitGenerator:[Mul2UGxyx class]];
    inputAdd = [theTemplate addUnitGenerator:[Scl2add2UGyxx class]];
    inputAdd2 = [theTemplate addUnitGenerator:[Scl2add2UGxyx class]];
    jetSquarer = [theTemplate addUnitGenerator:[Mul2UGxyy class]];
    jetCuber = [theTemplate addUnitGenerator:[Mul2UGxyx class]];
    sigAdder = [theTemplate addUnitGenerator:[Scl2add2UGxyx class]];
    jetAdder = [theTemplate addUnitGenerator:[Scl2add2UGyxx class]];
    reflFilter = [theTemplate addUnitGenerator:[OnepoleUGyy class]];
    delayLine = [theTemplate addUnitGenerator:[DelayUGxyy class]];
    delayLine2 = [theTemplate addUnitGenerator:[DelayUGyxy class]];
    gainElement = [theTemplate addUnitGenerator:[ScaleUGyy class]];

    stereoOut = [theTemplate addUnitGenerator:[Out2sumUGy class]];

    ampPp = [theTemplate addPatchpoint:MK_xPatch];
    inputNoisePp = [theTemplate addPatchpoint:MK_yPatch];
    inputMultPp = [theTemplate addPatchpoint:MK_xPatch];
    inputAddPp = [theTemplate addPatchpoint:MK_yPatch];
    inputAdd2Pp = [theTemplate addPatchpoint:MK_xPatch];
    jetSquarerPp = [theTemplate addPatchpoint:MK_xPatch];
    jetCuberPp = [theTemplate addPatchpoint:MK_xPatch];
    sigAddPp = [theTemplate addPatchpoint:MK_xPatch];
    jetAddPp = [theTemplate addPatchpoint:MK_yPatch];
    filterPp = [theTemplate addPatchpoint:MK_yPatch];
    delayPp = [theTemplate addPatchpoint:MK_xPatch];
    delay2Pp = [theTemplate addPatchpoint:MK_yPatch];
    gainPp = [theTemplate addPatchpoint:MK_yPatch];

    /* Step 3:  Specify the connections. */
    [theTemplate to:ampAsymp sel:@selector(setOutput:) arg:ampPp];

    [theTemplate to:inputNoise sel:@selector(setOutput:) arg:inputNoisePp];
    
    [theTemplate to:inputMult sel:@selector(setOutput:) arg:inputMultPp];
    [theTemplate to:inputMult sel:@selector(setInput1:) arg:inputNoisePp];
    [theTemplate to:inputMult sel:@selector(setInput2:) arg:ampPp];

    [theTemplate to:inputAdd sel:@selector(setOutput:) arg:inputAddPp];
    [theTemplate to:inputAdd sel:@selector(setInput1:) arg:inputMultPp];
    [theTemplate to:inputAdd sel:@selector(setInput2:) arg:ampPp];

    [theTemplate to:inputAdd2 sel:@selector(setOutput:) arg:inputAdd2Pp];
    [theTemplate to:inputAdd2 sel:@selector(setInput1:) arg:inputAddPp];
    [theTemplate to:inputAdd2 sel:@selector(setInput2:) arg:delayPp];

    [theTemplate to:jetSquarer sel:@selector(setOutput:) arg:jetSquarerPp];
    [theTemplate to:jetSquarer sel:@selector(setInput1:) arg:delay2Pp];
    [theTemplate to:jetSquarer sel:@selector(setInput2:) arg:delay2Pp];

    [theTemplate to:jetCuber sel:@selector(setOutput:) arg:jetCuberPp];
    [theTemplate to:jetCuber sel:@selector(setInput1:) arg:delay2Pp];
    [theTemplate to:jetCuber sel:@selector(setInput2:) arg:jetSquarerPp];

    [theTemplate to:sigAdder sel:@selector(setOutput:) arg:sigAddPp];
    [theTemplate to:sigAdder sel:@selector(setInput1:) arg:delay2Pp];
    [theTemplate to:sigAdder sel:@selector(setInput2:) arg:jetCuberPp];

    [theTemplate to:jetAdder sel:@selector(setOutput:) arg:jetAddPp];
    [theTemplate to:jetAdder sel:@selector(setInput1:) arg:sigAddPp];
    [theTemplate to:jetAdder sel:@selector(setInput2:) arg:delayPp];

    [theTemplate to:reflFilter sel:@selector(setOutput:) arg:filterPp];
    [theTemplate to:reflFilter sel:@selector(setInput:) arg:jetAddPp];

    [theTemplate to:delayLine sel:@selector(setOutput:) arg:delayPp];
    [theTemplate to:delayLine sel:@selector(setInput:) arg:filterPp];

    [theTemplate to:delayLine2 sel:@selector(setOutput:) arg:delay2Pp];
    [theTemplate to:delayLine2 sel:@selector(setInput:) arg:inputAdd2Pp];

    [theTemplate to:gainElement sel:@selector(setOutput:) arg:gainPp];
    [theTemplate to:gainElement sel:@selector(setInput:) arg: jetAddPp];

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

- preemptFor:aNote
{
    [[self synthElementAt:ampAsymp] preemptEnvelope]; 
    [self setDefaults];
    return self;
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

    int		MY_noiseVolume = [[Note class] parName: "MY_noiseVolume"];
    double	myNoiseVolume   = [aNote parAsDouble:MY_noiseVolume];

    int		MY_delay2Length = [[Note class] parName: "MY_delay2Length"];
    double	myDelay2Length   = [aNote parAsDouble:MY_delay2Length];

    int		MY_outAmp = [[Note class] parName: "MY_outAmp"];
    int		MY_dLineLength = [[Note class] parName: "MY_dLineLength"];
    double	myOutAmp   = [aNote parAsDouble:MY_outAmp];
    double	myDLineLength   = [aNote parAsDouble:MY_dLineLength];

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

[[self synthElementAt:inputAdd2] setScale1: 1.0];
[[self synthElementAt:inputAdd2] setScale2: -0.35];
[[self synthElementAt:sigAdder] setScale1: -1.0];
[[self synthElementAt:sigAdder] setScale2:  1.0];
[[self synthElementAt:jetAdder] setScale1: 0.4];
[[self synthElementAt:jetAdder] setScale2: 0.90];

[[self synthElementAt:reflFilter] setB0: 0.7];
[[self synthElementAt:reflFilter] setA1: -0.3];

   /* Check and set the embouchure. */
   if (!MKIsNoDVal(myDelay2Length)) {
        delay2Length = myDelay2Length;
             [[self synthElementAt:delayLine2] adjustLength:delay2Length];
   }

   /* Check and set the embouchure. */
   if (!MKIsNoDVal(myNoiseVolume)) {
        noiseVolume = myNoiseVolume;
             [[self synthElementAt:inputAdd] setScale1:myNoiseVolume];
             [[self synthElementAt:inputAdd] setScale2: 1.0];
   }

   /* Check and set the fader level. */
   if (!MKIsNoDVal(myOutAmp)) {
        outAmp = myOutAmp;
        [[self synthElementAt:gainElement] setScale:outAmp];
   }

   if (!MKIsNoDVal(myDLineLength)) {
        dLineLength = myDLineLength;
     [[self synthElementAt:delayLine] adjustLength:(int) dLineLength];
   }

  return self;
}    

- noteOnSelf:aNote
{
    delayMemory = [Orchestra allocSynthData:MK_yData length:100];
    [[self synthElementAt: delayLine] setDelayMemory: delayMemory];
    [delayMemory setToConstant:0 length:100 offset:0];  
    delayMemory2 = [Orchestra allocSynthData:MK_yData length:40];
    [[self synthElementAt: delayLine2] setDelayMemory: delayMemory2];
    [delayMemory2 setToConstant:0 length:40 offset:0];  
    /* Apply the parameters to the patch. */	
    [self applyParameters:aNote];

    /* Make the final connection to the output sample stream. */	
    [[self synthElementAt:stereoOut] setInput:[self synthElementAt:gainPp]];

    /* Tell the UnitGenerators to begin running. */	
    [synthElements makeObjectsPerform:@selector(run)];

    return self;
}

- noteUpdateSelf:aNote
{
    /* Apply the parameters to the patch. */	
    [self applyParameters: aNote];
	
    return self;	
}

- (double)noteOffSelf:aNote
{   
    /* Apply the parameters. */
    [self applyParameters: aNote];

    /* Same for amplitude, but also return the release duration. */
    return [[self synthElementAt:ampAsymp] finish];
}

- noteEndSelf
{
    /* Remove the patch's Out2sum from the output sample stream. */
    [[self synthElementAt:stereoOut] idle]; 

    /* Abort the frequency Envelope. */
    [[self synthElementAt:ampAsymp] abortEnvelope];

    /* Set the instance variables to their default values. */ 
    [self setDefaults];

    return self;
}

@end
