/* The following files must be imported. */
#import <MusicKit/MusicKit.h>    
#import <MKUnitGenerators/UnitGenerators.h>
#import <math.h>
#import <stdio.h>

#import "SourceFilterIns.h"

# define SRATE 22050.0
# define TWO_PI 6.283185308

/* A DSP chip source/filter model. */
@implementation SourceFilterIns;

/* Statically declare the synthElement indices. */
static int		ampAsymp,   	/* amplitude envelope UG */
			freqAsymp,  	/* frequency envelope UG */
			vampAsymp,   	/* vibrato amplitude envelope UG */
			vfreqAsymp,  	/* vibrato frequency envelope UG */
			osc,      	/* oscillator UG */
			noise,		/* glottal noise generator  */
			rndOsc,		// random vibrato generator
			rndFilt,	// random vibrato filter
			vosc,		// periodic vibrato generator
			sourceSummer,
			modSummer,
			vfreqSummer,
			filt1,
			filt2,
			filt3,
			stereoOut,  /* output UG */
			ampPp, 		/* amplitude patchpoint */
			freqPp,		/* frequency patchpoint */ 
			vampPp, 	/* vibrato amplitude patchpoint */
			vfreqPp,	/* vibrato frequency patchpoint */ 
			voscOutPp,
			oscOutPp,
			oscInFreqPp,
			noiseOutPp,
			sourceOutPp,	
			filt1OutPp,
			filt2OutPp,
			outPp,
			rvibPp,
			rFiltPp,
			modOutPp;			

+patchTemplateFor:aNote
{
    int i;
    
    /* Step 1: Create (or return) the PatchTemplate. */
    static id theTemplate = nil;
    if (theTemplate)
      return theTemplate;
    theTemplate = [PatchTemplate new];

    /* Step 2:  Add the SynthElement specifications. */	
    ampAsymp = [theTemplate addUnitGenerator:[AsympUGy class]];
    freqAsymp = [theTemplate addUnitGenerator:[AsympUGx class]];
    vampAsymp = [theTemplate addUnitGenerator:[AsympUGx class]];
    vfreqAsymp = [theTemplate addUnitGenerator:[AsympUGx class]];
    osc = [theTemplate addUnitGenerator:[OscgafiUGyyyy class]];
    noise = [theTemplate addUnitGenerator:[UnoiseUGy class]];
    vosc = [theTemplate addUnitGenerator:[OscgafUGxxxy class]];
    rndOsc = [theTemplate addUnitGenerator:[SnoiseUGx class]];
    rndFilt = [theTemplate addUnitGenerator:[OnepoleUGxx class]];
    sourceSummer = [theTemplate addUnitGenerator:[Scl2add2UGyyy class]];
    modSummer = [theTemplate addUnitGenerator:[Add2UGxxx class]];
    vfreqSummer = [theTemplate addUnitGenerator:[Add2UGyxx class]];
    filt1 = [theTemplate addUnitGenerator:[BiquadUGy class]];
    filt2 = [theTemplate addUnitGenerator:[BiquadUGy class]];
    filt3 = [theTemplate addUnitGenerator:[BiquadUGy class]];
    stereoOut = [theTemplate addUnitGenerator:[Out2sumUGy class]];

    ampPp = [theTemplate addPatchpoint:MK_yPatch];
    freqPp = [theTemplate addPatchpoint:MK_xPatch];
    oscInFreqPp = [theTemplate addPatchpoint:MK_yPatch];
    vampPp = [theTemplate addPatchpoint:MK_xPatch];
    vfreqPp = [theTemplate addPatchpoint:MK_xPatch];
    oscOutPp = [theTemplate addPatchpoint:MK_yPatch];
    voscOutPp = [theTemplate addPatchpoint:MK_xPatch];
    noiseOutPp = [theTemplate addPatchpoint:MK_yPatch];
    sourceOutPp = [theTemplate addPatchpoint:MK_yPatch];
    filt1OutPp = [theTemplate addPatchpoint:MK_yPatch];
    filt2OutPp = [theTemplate addPatchpoint:MK_yPatch];
    rvibPp = [theTemplate addPatchpoint:MK_xPatch];
    rFiltPp = [theTemplate addPatchpoint:MK_xPatch];
    modOutPp = [theTemplate addPatchpoint:MK_yPatch];
    outPp = [theTemplate addPatchpoint:MK_yPatch];


    /* Step 3:  Specify the connections. */
    [theTemplate to:freqAsymp sel:@selector(setOutput:) arg:freqPp];

    [theTemplate to:vampAsymp sel:@selector(setOutput:) arg:vampPp];

    [theTemplate to:vfreqAsymp sel:@selector(setOutput:) arg:vfreqPp];

    [theTemplate to:vosc sel:@selector(setAmpInput:) arg:vampPp];
    [theTemplate to:vosc sel:@selector(setIncInput:) arg:vfreqPp];
    [theTemplate to:vosc sel:@selector(setOutput:) arg:voscOutPp];

    [theTemplate to: rndOsc sel:@selector(setOutput:) arg:rFiltPp];

    [theTemplate to: rndFilt sel:@selector(setInput:) arg:rFiltPp];
    [theTemplate to: rndFilt sel:@selector(setOutput:) arg:rvibPp];

    [theTemplate to:modSummer sel:@selector(setInput1:) arg:rvibPp];
    [theTemplate to:modSummer sel:@selector(setInput2:) arg:voscOutPp];
    [theTemplate to:modSummer sel:@selector(setOutput:) arg:modOutPp];

    [theTemplate to:vfreqSummer sel:@selector(setInput1:) arg:modOutPp];
    [theTemplate to:vfreqSummer sel:@selector(setInput2:) arg:freqPp];
    [theTemplate to:vfreqSummer sel:@selector(setOutput:) arg:oscInFreqPp];

    [theTemplate to:ampAsymp sel:@selector(setOutput:) arg:ampPp];

    [theTemplate to:osc sel:@selector(setAmpInput:) arg:ampPp];
    [theTemplate to:osc sel:@selector(setIncInput:) arg:oscInFreqPp];
    [theTemplate to:osc sel:@selector(setOutput:) arg:oscOutPp];

    [theTemplate to: noise sel:@selector(setOutput:) arg:noiseOutPp];

    [theTemplate to:sourceSummer sel:@selector(setInput1:) arg:oscOutPp];
    [theTemplate to:sourceSummer sel:@selector(setInput2:) arg:noiseOutPp];
    [theTemplate to:sourceSummer sel:@selector(setOutput:) arg:sourceOutPp];

    [theTemplate to:filt1 sel:@selector(setInput:) arg:sourceOutPp];
    [theTemplate to:filt1 sel:@selector(setOutput:) arg:filt1OutPp];

    [theTemplate to:filt2 sel:@selector(setInput:) arg:filt1OutPp];
    [theTemplate to:filt2 sel:@selector(setOutput:) arg:filt2OutPp];

    [theTemplate to:filt3 sel:@selector(setInput:) arg:filt2OutPp];
    [theTemplate to:filt3 sel:@selector(setOutput:) arg:outPp];

    /* Return the PatchTemplate. */	
    return theTemplate;
}

- initialize
{
    /* Sent once when the patch is created. */
    [[self synthElementAt:osc] setTable:nil defaultToSineROM:YES];
    [[self synthElementAt:vosc] setTable:nil defaultToSineROM:YES];
    return self;
}

- setDefaults
{
    int i;
    
    ampEnv  = nil;	
    amp0    = 0.0;
    amp1    = MK_DEFAULTAMP;  /* 0.1 */
    ampAtt  = MK_NODVAL;      /* parameter not present */
    ampRel  = MK_NODVAL;      /* parameter not present */

    freqEnv = nil;	
    freq0   = 0.0;
    freq1   = MK_DEFAULTFREQ; /* 440.0 */
    freqAtt = MK_NODVAL;		/* parameter not present */      	     
    freqRel = MK_NODVAL;      /* parameter not present */

    svibAmpEnv  = nil;	
    svibAmp0    = 0.0;
    svibAmp1    = 0.01;  		/* 0.01 */
    svibAmpAtt  = MK_NODVAL;      /* parameter not present */
    svibAmpRel  = MK_NODVAL;      /* parameter not present */

    svibFreqEnv = nil;	
    svibFreq0   = 0.0;
    svibFreq1   = 6.0; 		/* All vibratos are 6 Hz. */
    svibFreqAtt = MK_NODVAL;	/* parameter not present */      	     
    svibFreqRel = MK_NODVAL;      /* parameter not present */

    sourceFader = 0.5;
    
    oscLevel = 1.0;
    noiseLevel = 0.01;
    
    waveTable = nil;
    waveTableLength = 1024;
    
    filt1pr = 0.0;
    filt1pf = 0.0;
    filt2pr = 0.0;
    filt2pf = 0.0;
    filt3pr = 0.0;
    filt3pf = 0.0;
    filt1zr = 0.0;
    filt1zf = 0.0;
    filt2zr = 0.0;
    filt2zf = 0.0;
    filt3zr = 0.0;
    filt3zf = 0.0;
    filt1Gain = 1.0;
    filt2Gain = 1.0;
    filt3Gain = 1.0;
    
    rvibAmp = 0.01;
    numHarmonics = 30;
    
    portamento = MK_DEFAULTPORTAMENTO; 	/* 0.1 */
    bearing = MK_DEFAULTBEARING;	/* 0.0 (centered) */

    return self;
}

- preemptFor:aNote
{
    [[self synthElementAt:ampAsymp] preemptEnvelope]; 
    [self setDefaults];
    return self;
}

- applyParameters:aNote
  /* This is a private method to the Singer class. It is used internally only.
     */
{
    int i;
    
     /* Retrieve and store the parameters. */
    id		myAmpEnv = [aNote parAsEnvelope:MK_ampEnv];
    double	myAmp0   = [aNote parAsDouble:MK_amp0];
    double	myAmp1   = [aNote parAsDouble:MK_amp1];
    double	myAmpAtt = [aNote parAsDouble:MK_ampAtt];
    double	myAmpRel = [aNote parAsDouble:MK_ampAtt];

    id		myFreqEnv = [aNote parAsEnvelope:MK_freqEnv];
    double	myFreq0   = [aNote parAsDouble:MK_freq0];
    double	myFreq1   = [aNote freq];
    double	myFreqAtt = [aNote parAsDouble:MK_freqAtt];
    double	myFreqRel = [aNote parAsDouble:MK_freqRel];

    int		MK_svibAmpAtt = [[aNote class] parName:"MK_svibAmpAtt"],
    		MK_svibAmpRel = [[aNote class] parName:"MK_svibAmpRe"],
    		MK_svibFreqAtt = [[aNote class] parName:"MK_svibFreqAtt"],
    		MK_svibFreqRel = [[aNote class] parName:"MK_svibFreqRel"];

    id		myVAmpEnv = [aNote parAsEnvelope:MK_svibAmpEnv];
    double	myVAmp0   = [aNote parAsDouble:MK_svibAmp0];
    double	myVAmp1   = [aNote parAsDouble:MK_svibAmp1];
    double	myVAmpAtt = [aNote parAsDouble:MK_svibAmpAtt];
    double	myVAmpRel = [aNote parAsDouble:MK_svibAmpRel];

    id		myVFreqEnv = [aNote parAsEnvelope:MK_svibFreqEnv];
    double	myVFreq0   = [aNote parAsDouble:MK_svibFreq0];
    double	myVFreq1   = [aNote parAsDouble:MK_svibFreq1];
    double	myVFreqAtt = [aNote parAsDouble:MK_svibFreqAtt];
    double	myVFreqRel = [aNote parAsDouble:MK_svibFreqRel];

    int		RESO_sourceFader = [[MKNote class] parName: "RESO_sourceFader"];
    double	mySourceFader = [aNote parAsDouble: RESO_sourceFader];
    
    int		RESO_oscLevel = [[MKNote class] parName: "RESO_oscLevel"];
    double	myOscLevel = [aNote parAsDouble: RESO_oscLevel];
    
    int		RESO_noiseLevel = [[MKNote class] parName: "RESO_noiseLevel"];
    double	myNoiseLevel = [aNote parAsDouble: RESO_noiseLevel];
    
    id		myWaveTable  = [aNote parAsWaveTable:MK_waveform];
    double	myWaveTableLength  = [aNote parAsDouble:MK_waveLen];
    
    double	myPortamento = [aNote parAsDouble:MK_portamento];
    double	myBearing    = [aNote parAsDouble:MK_bearing];
    
    double 	myrvibAmp = [aNote parAsDouble:MK_rvibAmp];
    
    int		RESO_filt1pr = [[aNote class] parName:"RESO_filt1pr"],
    		RESO_filt1pf = [[aNote class] parName:"RESO_filt1pf"],
    		RESO_filt2pr = [[aNote class] parName:"RESO_filt2pr"],
    		RESO_filt2pf = [[aNote class] parName:"RESO_filt2pf"],
    		RESO_filt3pr = [[aNote class] parName:"RESO_filt3pr"],
    		RESO_filt3pf = [[aNote class] parName:"RESO_filt3pf"],
    		RESO_filt1zr = [[aNote class] parName:"RESO_filt1zr"],
    		RESO_filt1zf = [[aNote class] parName:"RESO_filt1zf"],
    		RESO_filt2zr = [[aNote class] parName:"RESO_filt2zr"],
    		RESO_filt2zf = [[aNote class] parName:"RESO_filt2zf"],
    		RESO_filt3zr = [[aNote class] parName:"RESO_filt3zr"],
    		RESO_filt3zf = [[aNote class] parName:"RESO_filt3zf"],
     		RESO_filt1Gain = [[aNote class] parName:"RESO_filt1Gain"],
    		RESO_filt2Gain = [[aNote class] parName:"RESO_filt2Gain"],
    		RESO_filt3Gain = [[aNote class] parName:"RESO_filt3Gain"];
		
    int 	RESO_numHarmonics = [[aNote class] parName:"RESO_numHarmonics"];
    int         myNumHarmonics = [aNote parAsInt:RESO_numHarmonics];
    		
    double   	myFilt1pr = [aNote parAsDouble:RESO_filt1pr],
    		myFilt1pf = [aNote parAsDouble:RESO_filt1pf],
		myFilt2pr = [aNote parAsDouble:RESO_filt2pr],
		myFilt2pf = [aNote parAsDouble:RESO_filt2pf],
		myFilt3pr = [aNote parAsDouble:RESO_filt3pr],
		myFilt3pf = [aNote parAsDouble:RESO_filt3pf],
   		myFilt1zr = [aNote parAsDouble:RESO_filt1zr],
    		myFilt1zf = [aNote parAsDouble:RESO_filt1zf],
		myFilt2zr = [aNote parAsDouble:RESO_filt2zr],
		myFilt2zf = [aNote parAsDouble:RESO_filt2zf],
		myFilt3zr = [aNote parAsDouble:RESO_filt3zr],
		myFilt3zf = [aNote parAsDouble:RESO_filt3zf],
		myFilt1Gain = [aNote parAsDouble:RESO_filt1Gain],
		myFilt2Gain = [aNote parAsDouble:RESO_filt2Gain],
		myFilt3Gain = [aNote parAsDouble:RESO_filt3Gain];

    
    double freqs[200],amps[200],phases[200];
    
    /* Store the phrase status. */	
    MKPhraseStatus phraseStatus = [self phraseStatus];

    /* Is aNote a noteOn? */
    BOOL isNoteOn = [aNote noteType] == MK_noteOn;

    /* Is aNote the beginning of a new phrase? */
    BOOL isNewPhrase = (phraseStatus == MK_phraseOn) || 
                       (phraseStatus == MK_phraseOnPreempt);

    /* Used in the parameter checks. */
    BOOL shouldApplyAmp = NO;
    BOOL shouldApplyFreq = NO;
    BOOL shouldApplyVAmp = NO;
    BOOL shouldApplyVFreq = NO;
    BOOL shouldApplyBearing = NO;

    BOOL shouldUpdateFilter = NO;
    BOOL changeLevels = NO;

    /*  check and apply wave table and length  */

    if (mySourceFader!=MK_NODVAL) {
        sourceFader = mySourceFader;
	changeLevels = YES;
    }
    if (myOscLevel!=MK_NODVAL) {
    	oscLevel = myOscLevel;
	changeLevels = YES;
    }
    if (myNoiseLevel!=MK_NODVAL) {
	noiseLevel = myNoiseLevel;
	changeLevels = YES;
    }
    if (changeLevels)	{
	[[self synthElementAt:sourceSummer] setScale1: oscLevel * (sourceFader)];
	[[self synthElementAt:sourceSummer] setScale2: noiseLevel * (1.0 - sourceFader)];
    }	

/* Update filter coefficients   */

	if (!MKIsNoDVal(myFilt1Gain))	{
	    shouldUpdateFilter = YES;
	    filt1Gain = myFilt1Gain;
	}
	if (!MKIsNoDVal(myFilt2Gain))	{
	    shouldUpdateFilter = YES;
	    filt2Gain = myFilt2Gain;
	}
	if (!MKIsNoDVal(myFilt2Gain))	{
	    shouldUpdateFilter = YES;
	    filt3Gain = myFilt3Gain;
	}

	if (!MKIsNoDVal(myFilt1pr))	{
	    shouldUpdateFilter = YES;
	    filt1pr = myFilt1pr;
	}
	if (!MKIsNoDVal(myFilt2pr))	{
	    shouldUpdateFilter = YES;
	    filt2pr = myFilt2pr;
	}
	if (!MKIsNoDVal(myFilt3pr))	{
	    shouldUpdateFilter = YES;
	    filt3pr = myFilt3pr;
	}
	if (!MKIsNoDVal(myFilt1pf))	{
	    shouldUpdateFilter = YES;
	    filt1pf = myFilt1pf;
	}
	if (!MKIsNoDVal(myFilt2pf))	{
	    shouldUpdateFilter = YES;
	    filt2pf = myFilt2pf;
	}
	if (!MKIsNoDVal(myFilt3pf))	{
	    shouldUpdateFilter = YES;
	    filt3pf = myFilt3pf;
	}

	if (!MKIsNoDVal(myFilt1zr))	{
	    shouldUpdateFilter = YES;
	    filt1zr = myFilt1zr;
	}
	if (!MKIsNoDVal(myFilt2zr))	{
	    shouldUpdateFilter = YES;
	    filt2zr = myFilt2zr;
	}
	if (!MKIsNoDVal(myFilt3zr))	{
	    shouldUpdateFilter = YES;
	    filt3zr = myFilt3zr;
	}
	if (!MKIsNoDVal(myFilt1zf))	{
	    shouldUpdateFilter = YES;
	    filt1zf = myFilt1zf;
	}
	if (!MKIsNoDVal(myFilt2zf))	{
	    shouldUpdateFilter = YES;
	    filt2zf = myFilt2zf;
	}
	if (!MKIsNoDVal(myFilt3zf))	{
	    shouldUpdateFilter = YES;
	    filt3zf = myFilt3zf;
	}
	if (shouldUpdateFilter)	{
	    [[self synthElementAt:filt1] setA1: - 2.0 * filt1pr * cos(TWO_PI * filt1pf / SRATE)];
	    [[self synthElementAt:filt1] setA2: filt1pr * filt1pr];
	    [[self synthElementAt:filt1] setB1: - 2.0 * filt1zr * cos(TWO_PI * filt1zf / SRATE)];
	    [[self synthElementAt:filt1] setB2: filt1zr * filt1zr];
	    [[self synthElementAt:filt1] setGain: filt1Gain];
	    [[self synthElementAt:filt2] setA1: - 2.0 * filt2pr * cos(TWO_PI * filt2pf / SRATE)];
	    [[self synthElementAt:filt2] setA2: filt2pr * filt2pr];
	    [[self synthElementAt:filt2] setB1: - 2.0 * filt2zr * cos(TWO_PI * filt2zf / SRATE)];
	    [[self synthElementAt:filt2] setB2: filt2zr * filt2zr];
	    [[self synthElementAt:filt2] setGain: filt2Gain];
	    [[self synthElementAt:filt3] setA1: - 2.0 * filt3pr * cos(TWO_PI * filt3pf / SRATE)];
	    [[self synthElementAt:filt3] setA2: filt3pr * filt3pr];
	    [[self synthElementAt:filt3] setB1: - 2.0 * filt3zr * cos(TWO_PI * filt3zf / SRATE)];
	    [[self synthElementAt:filt3] setB2: filt3zr * filt3zr];
	    [[self synthElementAt:filt3] setGain: filt3Gain];
    }
    
    if (myNumHarmonics!=MAXINT) {
        numHarmonics = myNumHarmonics;	
        waveTable = [Partials new];
        if (numHarmonics>199) numHarmonics = 199;
        if (numHarmonics<1) numHarmonics = 1;
        for (i=0;i<numHarmonics;i++)	{
	    freqs[i] = i+1;
	    amps[i] = 1.0/numHarmonics;
	    phases[i] = 0.0;
        }
        [waveTable setPartialCount: (int) numHarmonics freqRatios: &freqs[0]  
			ampRatios: &amps[0]
			phases: &phases[0] 
			orDefaultPhase: 0.0];    
	if (!MKIsNoDVal(myWaveTableLength)) waveTableLength = myWaveTableLength;
	[[self synthElementAt:osc] setTable:waveTable length: waveTableLength];
    }
    
    if (myWaveTable != nil) {
        waveTable = myWaveTable;
	if (!MKIsNoDVal(myWaveTableLength)) waveTableLength = myWaveTableLength;
	[[self synthElementAt:osc] setTable:waveTable length: waveTableLength];
    }	

    /* The same portamento is used in both frequency and amplitude. */
    if (!MKIsNoDVal(myPortamento)) {
        portamento = myPortamento;
        shouldApplyAmp = YES;
        shouldApplyFreq = YES;
	shouldApplyVAmp = YES;
        shouldApplyVFreq = YES; }	

    /* Check the amplitude parameters and set the instance variables. */
    if (myAmpEnv != nil) {
        ampEnv = myAmpEnv;
        shouldApplyAmp = YES; }
    if (!MKIsNoDVal(myAmp0)) {
        amp0 = myAmp0;
        shouldApplyAmp = YES; }
    if (!MKIsNoDVal(myAmp1)) {
        amp1 = myAmp1;
        shouldApplyAmp = YES; }
    if (!MKIsNoDVal(myAmpAtt)) {
        ampAtt = myAmpAtt;
        shouldApplyAmp = YES; }
    if (!MKIsNoDVal(myAmpRel)) {
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
    if (!MKIsNoDVal(myFreq0)) {
        freq0 = myFreq0;
        shouldApplyFreq = YES; }
    if (!MKIsNoDVal(myFreq1)) {
        freq1 = myFreq1;
        shouldApplyFreq = YES; }
    if (!MKIsNoDVal(myFreqAtt)) {
        freqAtt = myFreqAtt;
        shouldApplyFreq = YES; }
    if (!MKIsNoDVal(myFreqRel)) {
        freqRel = myFreqRel;
        shouldApplyFreq = YES; }
    /* Apply the frequency parameters. */
    if (shouldApplyFreq || isNoteOn)	{
      MKUpdateAsymp([self synthElementAt:freqAsymp], freqEnv, 
                    [[self synthElementAt:osc] incAtFreq:freq0], 
                    [[self synthElementAt:osc] incAtFreq:freq1], 
                    freqAtt, freqRel, portamento, phraseStatus);
    }
    

    /* Check the vibrato amplitude parameters and set the instance variables. */
    if (myVAmpEnv != nil) {
        svibAmpEnv = myVAmpEnv;
        shouldApplyVAmp = YES; }
    if (!MKIsNoDVal(myVAmp0)) {
        svibAmp0 = myVAmp0;
        shouldApplyVAmp = YES; }
    if (!MKIsNoDVal(myVAmp1)) {
        svibAmp1 = myVAmp1;
        shouldApplyVAmp = YES; }
    if (!MKIsNoDVal(myVAmpAtt)) {
        svibAmpAtt = myVAmpAtt;
        shouldApplyVAmp = YES; }
    if (!MKIsNoDVal(myVAmpRel )) {
        svibAmpRel = myVAmpRel;
        shouldApplyVAmp = YES; }
    /* Apply the amplitude parameters. */
    if (shouldApplyVAmp || isNoteOn)
      MKUpdateAsymp([self synthElementAt:vampAsymp], 
                    svibAmpEnv, 0.00015 * svibAmp0 * freq1,
		    0.00015 * svibAmp1 * freq1, svibAmpAtt, svibAmpRel, 
                    portamento, phraseStatus);
    /* Check the vibrato freqeuncy parameters and set the instance variables. */
    if (myVFreqEnv != nil) {
        svibFreqEnv = myVFreqEnv;
        shouldApplyVFreq = YES; }
    if (!MKIsNoDVal(myVFreq0)) {
        svibFreq0 = myVFreq0;
        shouldApplyVFreq = YES; }
    if (!MKIsNoDVal(myVFreq1)) {
        svibFreq1 = myVFreq1;
        shouldApplyVFreq = YES; }
    if (!MKIsNoDVal(myVFreqAtt)) {
        svibFreqAtt = myVFreqAtt;
        shouldApplyVFreq = YES; }
    if (!MKIsNoDVal(myVFreqRel)) {
        svibFreqRel = myVFreqRel;
        shouldApplyVFreq = YES; }
    /* Apply the frequency parameters. */
    if (shouldApplyVFreq || isNoteOn)	{
      MKUpdateAsymp([self synthElementAt:vfreqAsymp], svibFreqEnv, 
                    [[self synthElementAt:vosc] incAtFreq:svibFreq0], 
                    [[self synthElementAt:vosc] incAtFreq:svibFreq1], 
                    svibFreqAtt, svibFreqRel, portamento, phraseStatus);
    }

    /*  random vibrato filter settings */
    if (!MKIsNoDVal(myrvibAmp))	{
	rvibAmp = myrvibAmp;
	[[self synthElementAt:rndFilt] setB0: rvibAmp * 3.0e-7 * freq1];
	[[self synthElementAt:rndFilt] setA1: -0.9999];
    }
    

   /* Check and set the bearing. */
   if (!MKIsNoDVal(myBearing)) {
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

    /* Signal the release portion of the frequency Envelope. */
    [[self synthElementAt:vfreqAsymp] finish];
 
    /* Same for amplitude, but also return the release duration. */
    return [[self synthElementAt:vampAsymp] finish];

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

