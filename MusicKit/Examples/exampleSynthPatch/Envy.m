#import <musickit/unitgenerators/unitgenerators.h> 

#import "Envy.h"

/* We call our simple SynthPatch with Envelopes 'Envy'. */
@implementation Envy;

/* Statically declare the synthElement indices. */
static int ampAsymp,   /* amplitude envelope UG */
    freqAsymp,         /* frequency envelope UG */
    osc,               /* oscillator UG */
    stereoOut,         /* output UG */
    ampPp,             /* amplitude patchpoint */
    freqPp,            /* frequency patchpoint */ 
    outPp;             /* output patchpoint */

+patchTemplateFor:aNote
{
    /* Step 1: Create (or return) the PatchTemplate. */
    static PatchTemplate *theTemplate = nil;
    if (theTemplate)
	return theTemplate;
    theTemplate = [[PatchTemplate alloc] init];

    /* Step 2:  Add the SynthElement specifications. */	
    ampAsymp = [theTemplate addUnitGenerator:[AsympUGx class]];
    freqAsymp = [theTemplate addUnitGenerator:[AsympUGy class]];
    osc = [theTemplate addUnitGenerator:[OscgafiUGxxyy class]];
    stereoOut = [theTemplate addUnitGenerator:[Out2sumUGx class]];

    ampPp = [theTemplate addPatchpoint:MK_xPatch];
    freqPp = [theTemplate addPatchpoint:MK_yPatch];
    outPp = ampPp;

    /* Step 3:  Specify the connections. */
    [theTemplate to:ampAsymp sel:@selector(setOutput:) arg:ampPp];
    [theTemplate to:freqAsymp sel:@selector(setOutput:) arg:freqPp];
    [theTemplate to:osc sel:@selector(setAmpInput:) arg:ampPp];
    [theTemplate to:osc sel:@selector(setIncInput:) arg:freqPp];
    [theTemplate to:osc sel:@selector(setOutput:) arg:outPp];

    /* Return the PatchTemplate. */	
    return theTemplate;
}

- init
{
    /* Sent once when the patch is created. */
    [[self synthElementAt:osc] setTable:nil defaultToSineROM:YES];
    return self;
}

- setDefaults
{
    ampEnv  = nil;	
    amp0    = 0.0;
    amp1    = MK_DEFAULTAMP;  /* 0.1 */
    ampAtt  = MK_NODVAL;      /* parameter not present */
    ampRel  = MK_NODVAL;      /* parameter not present */

    freqEnv = nil;	
    freq0   = 0.0;
    freq1   = MK_DEFAULTFREQ; /* 440.0 */
    freqAtt = MK_NODVAL;      /* parameter not present */      	     
    freqRel = MK_NODVAL;      /* parameter not present */

    portamento = MK_DEFAULTPORTAMENTO; 	/* 0.1 */
    bearing = MK_DEFAULTBEARING;	/* 0.0 (centered between speakers) */

    return self;
}

- preemptFor:aNote
{
    [[self synthElementAt:ampAsymp] preemptEnvelope]; 
    [self setDefaults];
    return self;
}

#define valid(_x) (!MKIsNoDVal(_x))

- applyParameters:aNote
    /* This is a private method to the Envy class. It is used internally only.
     */
{
    /* Retrieve and store the parameters. */
    Envelope *  myAmpEnv = [aNote parAsEnvelope:MK_ampEnv];
    double	myAmp0   = [aNote parAsDouble:MK_amp0];
    double	myAmp1   = [aNote parAsDouble:MK_amp1];
    double	myAmpAtt = [aNote parAsDouble:MK_ampAtt];
    double	myAmpRel = [aNote parAsDouble:MK_ampAtt];

    Envelope *	myFreqEnv = [aNote parAsEnvelope:MK_freqEnv];
    double	myFreq0   = [aNote parAsDouble:MK_freq0];
    double	myFreq1   = [aNote freq];
    double	myFreqAtt = [aNote parAsDouble:MK_freqAtt];
    double	myFreqRel = [aNote parAsDouble:MK_freqRel];

    double	myPortamento = [aNote parAsDouble:MK_portamento];
    double	myBearing    = [aNote parAsDouble:MK_bearing];

    /* Store the phrase status. */	
    MKPhraseStatus phraseStatus = [self phraseStatus];

    /* Is aNote a noteOn? */
    MKNoteType noteType = [aNote noteType];
    BOOL isNoteOn = (noteType == MK_noteOn || noteType == MK_noteDur);

    /* Is aNote the beginning of a new phrase? */
    BOOL isNewPhrase = (phraseStatus == MK_phraseOn) || 
                       (phraseStatus == MK_phraseOnPreempt);

    /* Used in the parameter checks. */
    BOOL shouldApplyAmp = NO;
    BOOL shouldApplyFreq = NO;
    BOOL shouldApplyBearing = NO;	

    /* The same portamento is used in both frequency and amplitude. */
    if (valid(myPortamento)) {
        portamento = myPortamento;
        shouldApplyAmp = YES;
        shouldApplyFreq = YES; }	

    /* Check the amplitude parameters and set the instance variables. */
    if (myAmpEnv != nil) {
        ampEnv = myAmpEnv;
        shouldApplyAmp = YES; }

    if (valid(myAmp0)) {
        amp0 = myAmp0;
        shouldApplyAmp = YES; }

    if (valid(myAmp1)) {
        amp1 = myAmp1;
        shouldApplyAmp = YES; }

    if (valid(myAmpAtt)) {
        ampAtt = myAmpAtt;
        shouldApplyAmp = YES; }

    if (valid(myAmpRel)) {
        ampRel = myAmpRel;
        shouldApplyAmp = YES; }

    /* Apply the amplitude parameters. */
    if (shouldApplyAmp || isNoteOn)
	MKUpdateAsymp([self synthElementAt:ampAsymp], 
		      ampEnv, amp0, amp1, ampAtt, ampRel, 
		      portamento, phraseStatus);

    /* Check the freqeuncy parameters and set the instance variables. */
    if (myFreqEnv != nil) {
        freqEnv = myFreqEnv;
        shouldApplyFreq = YES; }

    if (valid(myFreq0)) {
        freq0 = myFreq0;
        shouldApplyFreq = YES; }

    if (valid(myFreq1)) {
        freq1 = myFreq1;
        shouldApplyFreq = YES; }

    if (valid(myFreqAtt)) {
        freqAtt = myFreqAtt;
        shouldApplyFreq = YES; }

    if (valid(myFreqRel)) {
        freqRel = myFreqRel;
        shouldApplyFreq = YES; }

    /* Apply the frequency parameters. */
    if (shouldApplyFreq || isNoteOn)
	MKUpdateAsymp([self synthElementAt:freqAsymp], freqEnv, 
		      [[self synthElementAt:osc] incAtFreq:freq0], 
		      [[self synthElementAt:osc] incAtFreq:freq1], 
		      freqAtt, freqRel, portamento, phraseStatus);
    
   /* Check and set the bearing. */
   if (valid(myBearing)) {
        bearing = myBearing;
        shouldApplyBearing = YES; }

   if (shouldApplyBearing || isNewPhrase)
       [[self synthElementAt:stereoOut] setBearing:bearing];

  return self;
}    

- noteOnSelf:aNote
{
    /* Apply the parameters to the patch. */	
    [self applyParameters:aNote];

    /* Make the final connection to the output sample stream. */	
    [[self synthElementAt:stereoOut] setInput:[self synthElementAt:outPp]];

    /* Tell the UnitGenerators to begin running. */	
    [synthElements makeObjectsPerform:@selector(run)];

    return self;
}

- noteUpdateSelf:aNote
{
    /* Apply the parameters to the patch. */	
    [self applyParameters:aNote];
	
    return self;	
}

- (double)noteOffSelf:aNote
{   
    /* Apply the parameters. */
    [self applyParameters: aNote];

    /* Signal the release portion of the frequency Envelope. */
    [[self synthElementAt:freqAsymp] finish];
 
    /* Same for amplitude, but also return the release duration. */
    return [[self synthElementAt:ampAsymp] finish];
}

- noteEndSelf
{
    /* Remove the patch's Out2sum from the output sample stream. */
    [[self synthElementAt:stereoOut] idle]; 

    /* Abort the frequency Envelope. */
    [[self synthElementAt:freqAsymp] abortEnvelope];

    /* Set the instance variables to their default values. */ 
    [self setDefaults];

    return self;
}

@end

