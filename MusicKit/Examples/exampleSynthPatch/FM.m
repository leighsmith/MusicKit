/* ------------------------------------------------------------------------ * 
 * FM is a frequency modulation SynthPatch with arbitrary waveforms for     *
 * carrier and modulator and an interpolating oscillator for the carrier.   *
 * It supports a wide variety of parameters, including many MIDI parameters.* 
 *                                                                          *
 * This example is almost identical to the Fm1vi supplied with the 2.0      *
 * Music Kit SynthPatch Library. The only difference is that Fm1vi supports *
 * multiple "flavors" for optimization. For example, Fm1vi allows you to    *
 * specify a patch implementing only periodic or only random vibrato.       *
 *                                                                          *
 * See the FM literature for details of FM synthesis.                       *
 * (Note that the implementation here is "frequency modulation" rather than *
 * "phase modulation" and that the deviation scaling does not follow the    *
 * frequency envelope -- it is exactly as defined in the literature only    *
 * when the frequency envelope is at 1 and the vibrato is neither above nor *
 * below the pitch.)                                                        *
 * ------------------------------------------------------------------------ */

/* Written by Mike McNabb and David Jaffe. */
  
#import <mididriver/midi_spec.h>
#import <musickit/unitgenerators/unitgenerators.h>
#import "FM.h"
  
@implementation FM:SynthPatch

/* The patch is described below. The UnitGenerators are shown in parenthesis:
 *
 * The vibrato is created by adding (Add2) a periodic component with a random
 * component. The periodic component is created by an oscillator (Oscg).
 * The random component is created by white noise (Snoise) that is
 * low-pass filtered (Onepole). 
 *
 * The vibrato signal is multiplied (Mul1add2) by the output of the frequency
 * envelope generator (Asymp) and the frequency envelope generator is 
 * additionally added. Thus, the vibrato depth is perceptually the same, 
 * even as the frequency is continuously changing. Let us call the resulting 
 * signal the "frequency signal".
 *
 * The modulator (Oscgaf) takes its frequency from the frequency signal and 
 * its FM index from the index envelope generator (Asymp). The output of
 * the modulator is added (Scl1add2) to the frequency signal to produce the 
 * frequency input to the carrier. 
 *
 * The carrier (Oscgafi) takes its amplitude envelope from the amplitude
 * envelope generator (Asymp) and sends its output signal to the stereo
 * output sample stream (Out2sum).
 *
 * The communication between UnitGenerators is accomplished by patchpoints.
 * Since the ordering of the UnitGenerators is constrained to be as specified
 * below, two patchpoints suffice for all UnitGenerator communication. 
 * That is, the two patchpoints are reused as temporary storage for each stage
 * in the sample computation.
 */   


/* The following integers are used to hold offsets into the List of     
 * UnitGenerator and patchpoint instances. (The List is stored in the FM
 * instance variable 'synthElements', inherited from SynthPatch.)              
 */

static int ampEnvUG, freqEnvUG, indEnvUG, modulatorUG, carrierUG, outputUG, 
    svibUG, nvibUG, nvibFilterUG, vibAdderUG, fmAdderUG, freqMulUG, xPP, yPP; 

+patchTemplateFor:currentNote
  /* Returns and (if necessary) creates the PatchTemplate that specifies the 
   * UnitGenerators and patchpoints to be used. Note that this method 
   * does not actually allocate the UnitGenerators and patchpoints; it only
   * returns the specification. */
{
    /* This SynthPatch has only one template, but could have variations,
     * returned according to the note parameter values. 
     */
    static PatchTemplate *template = nil;
    if (template)      
	return template;
    template = [[PatchTemplate alloc] init];
    /* These UnitGenerators will be instantiated in the order specified. */
    svibUG = [template addUnitGenerator:[OscgUGyy class]];
    nvibUG = [template addUnitGenerator:[SnoiseUGx class]];
    nvibFilterUG = [template addUnitGenerator:[OnepoleUGxx class]];
    vibAdderUG = [template addUnitGenerator:[Add2UGyxy class]];
    freqEnvUG = [template addUnitGenerator:[AsympUGx class]];
    freqMulUG = [template addUnitGenerator:[Mul1add2UGyxyx class]];
    indEnvUG = [template addUnitGenerator:[AsympUGx class]];
    modulatorUG = [template addUnitGenerator:[OscgafUGxxyy class]];
    fmAdderUG = [template addUnitGenerator:[Scl1add2UGyxy class]];
    ampEnvUG = [template addUnitGenerator:[AsympUGx class]];
    carrierUG = [template addUnitGenerator:[OscgafiUGxxyy class]];
    outputUG = [template addUnitGenerator:[Out2sumUGx class]];
    /* Patchpoint specifications */
    xPP = [template addPatchpoint:MK_xPatch];
    yPP = [template addPatchpoint:MK_yPatch];
    return template;
}

#define UGS NX_ADDRESS(synthElements) // Quick access to UG instances 

/* Definitions for the UnitGenerator and patchpoint instances: */
#define SVIB_UG        UGS[svibUG]
#define NVIB_UG        UGS[nvibUG]
#define NVIB_FILTER_UG UGS[nvibFilterUG]
#define VIB_ADDER_UG   UGS[vibAdderUG]
#define FREQ_ENV_UG    UGS[freqEnvUG]
#define FREQ_MUL_UG    UGS[freqMulUG]
#define IND_ENV_UG     UGS[indEnvUG]
#define MODULATOR_UG   UGS[modulatorUG]
#define FM_ADDER_UG    UGS[fmAdderUG]
#define AMP_ENV_UG     UGS[ampEnvUG]
#define CARRIER_UG     UGS[carrierUG]
#define OUTPUT_UG      UGS[outputUG]
#define X_PP           UGS[xPP]
#define Y_PP           UGS[yPP]

#define OUTPUT_PP      X_PP // We use the x patchpoint for the output signal 
  
-init
  /* Sent by this class on object creation and reset. */
{
    /* This could, alternatively, be specified in the patchTemplateFor:
     * method, as described in the NeXT Technical Documentation. We include
     * it here for clarity. 
     */
    /* Connect UnitGenerators here. */
    [SVIB_UG setOutput:Y_PP];
    [NVIB_UG setOutput:X_PP];
    [NVIB_FILTER_UG setInput:X_PP];
    [NVIB_FILTER_UG setOutput:X_PP];
    [VIB_ADDER_UG setInput1:X_PP];
    [VIB_ADDER_UG setInput2:Y_PP];
    [VIB_ADDER_UG setOutput:Y_PP];
    [FREQ_ENV_UG setOutput:X_PP];
    [FREQ_MUL_UG setInput1:X_PP];
    [FREQ_MUL_UG setInput2:Y_PP];
    [FREQ_MUL_UG setInput3:X_PP];
    [FREQ_MUL_UG setOutput:Y_PP];
    [IND_ENV_UG setOutput:X_PP];
    [MODULATOR_UG setAmpInput:X_PP];
    [MODULATOR_UG setIncInput:Y_PP];
    [MODULATOR_UG setOutput:X_PP];
    [FM_ADDER_UG setInput1:X_PP];
    [FM_ADDER_UG setInput2:Y_PP];
    [FM_ADDER_UG setOutput:Y_PP];
    [AMP_ENV_UG setOutput:X_PP];
    [CARRIER_UG setAmpInput:X_PP];
    [CARRIER_UG setIncInput:Y_PP];
    [CARRIER_UG setOutput:X_PP];
    [self _setDefaults];
    return self;
}

-noteOnSelf:aNote
  /* Sent whenever a noteOn is received. First updates the parameters,
   * then connects the carrier to the output. 
   */
{
    [self _updateParameters:aNote];                 // Interpret parameters
    [OUTPUT_UG setInput:OUTPUT_PP];                 // Connect the ouput last. 
    [synthElements makeObjectsPerform:@selector(run)]; // Make them all run
    return self;
}

-noteUpdateSelf:aNote
  /* Sent whenever a noteUpdate is received by the SynthInstrument. */
{
    [self _updateParameters:aNote];
}

-(double)noteOffSelf:aNote
  /* Sent whenever a noteOff is received by the SynthInstrument. Returns
   * the amplitude envelope completion time, needed to schedule the noteEnd. */
{   
    [self _updateParameters:aNote];
    [FREQ_ENV_UG finish];
    [IND_ENV_UG finish];
    /* The value returned by noteOffSelf: is the time for the release portion
     * to complete. We return the value returned by AMP_ENV_UG's finish method,
     * i.e. the time in seconds it will take the envelope to 
     * complete. We only really care about the amplitude envelope's finishing
     * (because once it is finished, there is no more sound) so we use its 
     * time. This assumes that the amplitude envelope ends at 0.0. */
    return [AMP_ENV_UG finish];
}

-noteEndSelf
  /* Sent when patch goes from finalDecay to idle. */
{
    [OUTPUT_UG idle];
    /* Since we only used the AMP_ENV_UG's finish time above, the other 
     * envelopes may or may not be finished, so we explicitly abort them. */
    [FREQ_ENV_UG abortEnvelope];
    [IND_ENV_UG abortEnvelope];
    [self _setDefaults];
    return self;
}

-preemptFor:aNote
  /* Sent whenever a running note is being preempted by a new note. */
{
    /* Cause envelope to go quickly to last value.  This is to prevent a
     * click between notes when preempting. (This assumes the amplitude 
     * envelope ends at 0). */
    [AMP_ENV_UG preemptEnvelope]; 
    [self _setDefaults]; /* Reset parameters to defaults. */
    return self;
}

#import <objc/HashTable.h>

-controllerValues:controllers
  /* Sent when a new phrase starts. controllers is a HashTable containing
   * key/value pairs as controller-number/controller-value. Our implementation
   * here ignores all but MIDI_MAINVOLUME and MIDI_MODWHEEL. See 
   * <objc/HashTable.h>, <midi/midi_types.h>, and <musickit/SynthPatch.h>. */
{
#   define CONTROLPRESENT(_key) [controllers isKey:(const void *)_key]
#   define GETVALUE(_key) (int)[controllers valueForKey:(const void *)_key]
    if (CONTROLPRESENT(MIDI_MAINVOLUME))
	volume = GETVALUE(MIDI_MAINVOLUME);
    if (CONTROLPRESENT(MIDI_MODWHEEL))
	modWheel = GETVALUE(MIDI_MODWHEEL);
    return self;
}


/* ------------------------------------------------------------------  *
 * The following two methods are private and are used internally only. *
 * They are not intended to be invoked from outside the SynthPatch.    *
 * ------------------------------------------------------------------- */

-_setDefaults
  /* Set the instance variables to reasonable default values. We do this
   * after each phrase and upon initialization. This insures that a freshly 
   * allocated SynthPatch will be in a known state. See <musickit/params.h> 
   */
{
    waveform = m1Waveform = nil;      // WaveTables
    wavelen = 0;                      // Wave table length
    phase = m1Phase = 0.0;            // Waveform initial phases
    ampEnv = freqEnv = m1IndEnv = nil;// Envelopes
    freq0 = 0.0;                      // Frequency values
    freq1 = MK_DEFAULTFREQ;           // 440 Hz.
    amp0 = 0.0;                       // Amplitude values
    amp1 = MK_DEFAULTAMP;             // 0.1
    m1Ind0 = 0.0;                     // FM index values
    m1Ind1 = MK_DEFAULTINDEX;         // 1.0
    ampAtt = freqAtt = m1IndAtt = MK_NODVAL;  // Attack times (not set)
    ampRel = freqRel = m1IndRel = MK_NODVAL;  // Release times (not set)
    bright = 1.0;                     // A multiplier on index
    bearing = MK_DEFAULTBEARING;      // 0.0 degrees
    cRatio = MK_DEFAULTCRATIO;        // Carrier frequency scaler.
    m1Ratio = MK_DEFAULTMRATIO;       // Modulator frequency scaler.
    portamento = MK_NODVAL;           // Rearticulation skew duration (not set)
    svibAmp0 = svibAmp1 = 0.0;        // Periodic vibrato amp
    svibFreq0 = svibFreq1 = 0.0;      // Periodic vibrato freq
    rvibAmp   = 0.0;                  // Random vibrato amplitude
    /* MIDI parameters */
    velocity = MK_DEFAULTVELOCITY;    
    volume = modWheel = afterTouch = MIDI_MAXDATA;
    afterTouchSensitivity = velocitySensitivity = 0.5;
    pitchbend = MIDI_ZEROBEND;
    pitchbendSensitivity = 3.0;
}

static double midiVal(int midiControllerValue)
    /* Convert from int between 0 and 127 to double between 0 and 1 */
{
    return ((double)midiControllerValue)/((double)MIDI_MAXDATA);
}

-_updateParameters:aNote
  /* Updates the SynthPatch according to the information in the note and
   * the note's relationship to a possible ongoing phrase. 
   */
{
    BOOL newPhrase, setWaveform, setM1Waveform, setM1Ratio, setOutput,
         setRandomVib, setCRatio, setAfterTouch, setVibWaveform, setVibFreq,
         setVibAmp, setPhase, setAmpEnv, setFreqEnv, setM1IndEnv;
    void *state; // For parameter iteration below
    int par;     
    MKPhraseStatus phraseStatus = [self phraseStatus];

    /* Initialize booleans based on phrase status -------------------------- */
    switch (phraseStatus) {
      case MK_phraseOn:          /* New phrase. */
      case MK_phraseOnPreempt:   /* New phrase but using preempted patch. */
	newPhrase = setWaveform = setM1Waveform = setM1Ratio = 
	    setOutput = setRandomVib = setCRatio = setAfterTouch = 
		setVibWaveform = setVibFreq = setVibAmp = setPhase = 
		    setAmpEnv = setFreqEnv = setM1IndEnv = YES;  
	// Set everything for new phrase
	break;
      case MK_phraseRearticulate: /* NoteOn rearticulation within phrase. */
	newPhrase = setWaveform = setM1Waveform = setM1Ratio = 
	    setOutput = setRandomVib = setCRatio = setAfterTouch = 
		setVibWaveform = setVibFreq = setVibAmp = setPhase = NO;
	setAmpEnv = setFreqEnv = setM1IndEnv = YES; // Just restart envelopes 
	break;
      case MK_phraseUpdate:       /* NoteUpdate to running phrase. */
      case MK_phraseOff:          /* NoteOff to running phrase. */
      case MK_phraseOffUpdate:    /* NoteUpdate to finishing phrase. */
      default: 
	newPhrase = setWaveform = setM1Waveform = setM1Ratio = 
	    setOutput = setRandomVib = setCRatio = setAfterTouch = 
		setVibWaveform = setVibFreq = setVibAmp = setPhase = 
		    setAmpEnv = setFreqEnv = setM1IndEnv = NO;  
	// Only set what's in Note
	break;
    }

    /* Since this SynthPatch supports so many parameters, it would be 
     * inefficient to check each one with Note's isParPresent: method, as
     * we did in Simplicity and Envy. Instead, we iterate over the parameters 
     * in aNote. */

    state = MKInitParameterIteration(aNote);
    while (par = MKNextParameter(aNote, state))  
      switch (par) {       /* Parameters in (roughly) alphabetical order. */
	case MK_afterTouch:
	    afterTouch = MKGetNoteParAsInt(aNote,MK_afterTouch);
	    setAfterTouch = YES;
	    break;
	case MK_afterTouchSensitivity:
	  afterTouchSensitivity = 
            MKGetNoteParAsDouble(aNote,MK_afterTouchSensitivity);
	  setAfterTouch = YES;
          break;
	case MK_ampEnv:
	  ampEnv = MKGetNoteParAsEnvelope(aNote,MK_ampEnv);
	  setAmpEnv = YES;
	  break;
	case MK_ampAtt:
	  ampAtt = MKGetNoteParAsDouble(aNote,MK_ampAtt);
	  setAmpEnv = YES;
	  break;
	case MK_ampRel:
	  ampRel = MKGetNoteParAsDouble(aNote,MK_ampRel);
	  setAmpEnv = YES;
	  break;
	case MK_amp0:
	  amp0 = MKGetNoteParAsDouble(aNote,MK_amp0);
	  setAmpEnv = YES;
	  break;
	case MK_amp1: // MK_amp is synonym
	  amp1 = MKGetNoteParAsDouble(aNote,MK_amp1);
	  setAmpEnv = YES;
	  break;
	case MK_bearing:
	  bearing = MKGetNoteParAsDouble(aNote,MK_bearing);
	  setOutput = YES;
	  break;
	case MK_bright:
	  bright = MKGetNoteParAsDouble(aNote,MK_bright);
	  setM1IndEnv = YES;
	  break;
	case MK_controlChange: {
	    int controller = MKGetNoteParAsInt(aNote,MK_controlChange);
	    if (controller == MIDI_MAINVOLUME) {
		volume = MKGetNoteParAsInt(aNote,MK_controlVal);
		setOutput = YES; 
	    } 
	    else if (controller == MIDI_MODWHEEL) {
		modWheel = MKGetNoteParAsInt(aNote,MK_controlVal);
		setVibFreq = setVibAmp = YES;
	    }
	    break;
	}
	case MK_cRatio:
	  cRatio = MKGetNoteParAsDouble(aNote,MK_cRatio);
	  setCRatio = YES;
	  break;
	case MK_freqEnv:
	  freqEnv = MKGetNoteParAsEnvelope(aNote,MK_freqEnv);
	  setFreqEnv = YES;
	  break;
	case MK_freqAtt:
	  freqAtt = MKGetNoteParAsDouble(aNote,MK_freqAtt);
	  setFreqEnv = YES;
	  break;
	case MK_freqRel:
	  freqRel = MKGetNoteParAsDouble(aNote,MK_freqRel);
	  setFreqEnv = YES;
	  break;
	case MK_freq:
	case MK_keyNum:
	  freq1 = [aNote freq]; // A special method (see <musickit/Note.h>)
	  setFreqEnv = YES;
	  break;
	case MK_freq0:
	  freq0 = MKGetNoteParAsDouble(aNote,MK_freq0);
	  setFreqEnv = YES;
	  break;
	case MK_m1IndEnv:
	  m1IndEnv = MKGetNoteParAsEnvelope(aNote,MK_m1IndEnv);
	  setM1IndEnv = YES;
	  break;
	case MK_m1IndAtt:
	  m1IndAtt = MKGetNoteParAsDouble(aNote,MK_m1IndAtt);
	  setM1IndEnv = YES;
	  break;
	case MK_m1IndRel:
	  m1IndRel = MKGetNoteParAsDouble(aNote,MK_m1IndRel);
	  setM1IndEnv = YES;
	  break;
	case MK_m1Ind0:
	  m1Ind0 = MKGetNoteParAsDouble(aNote,MK_m1Ind0);
	  setM1IndEnv = YES;
	  break;
	case MK_m1Ind1:
	  m1Ind1 = MKGetNoteParAsDouble(aNote,MK_m1Ind1);
	  setM1IndEnv = YES;
	  break;
	case MK_m1Phase:
	  m1Phase = MKGetNoteParAsDouble(aNote,MK_m1Phase);
	  /* To avoid clicks, we don't allow phase to be set except at the 
	     start of a phrase. Therefore, we don't set setPhase. */
	  break;
	case MK_m1Ratio:
	  m1Ratio = MKGetNoteParAsDouble(aNote,MK_m1Ratio);
	  setM1Ratio = YES;
	  break;
	case MK_m1Waveform:
	  m1Waveform = MKGetNoteParAsWaveTable(aNote,MK_m1Waveform);
	  setM1Waveform = YES;
	  break;
	case MK_phase:
	  phase = MKGetNoteParAsDouble(aNote,MK_phase);
	  /* To avoid clicks, we don't allow phase to be set except at the 
	     start of a phrase. Therefore, we don't set setPhase. */
	  break;
	case MK_pitchBend:
	  pitchbend = MKGetNoteParAsInt(aNote,MK_pitchBend);
	  setFreqEnv = YES;
	  break;
	case MK_pitchBendSensitivity:
	  pitchbendSensitivity = 
	    MKGetNoteParAsDouble(aNote,MK_pitchBendSensitivity);
	  setFreqEnv = YES;
	  break;
	case MK_portamento:
	  portamento = MKGetNoteParAsDouble(aNote,MK_portamento);
	  setM1IndEnv = setAmpEnv = YES;
	  break;
	case MK_rvibAmp:
	  rvibAmp = MKGetNoteParAsDouble(aNote,MK_rvibAmp);
	  setRandomVib = YES;
	  break;
	case MK_svibFreq0:
	  svibFreq0 = MKGetNoteParAsDouble(aNote,MK_svibFreq0);
	  setVibFreq = YES;
	  break;
	case MK_svibFreq1:
	  svibFreq1 = MKGetNoteParAsDouble(aNote,MK_svibFreq1);
	  setVibFreq = YES;
	  break;
	case MK_svibAmp0:
	  svibAmp0 = MKGetNoteParAsDouble(aNote,MK_svibAmp0);
	  setVibAmp = YES;
	  break;
	case MK_svibAmp1:
	  svibAmp1 = MKGetNoteParAsDouble(aNote,MK_svibAmp1);
	  setVibAmp = YES;
	  break;
	case MK_vibWaveform:
	  vibWaveform = MKGetNoteParAsWaveTable(aNote,MK_vibWaveform);
	  setVibWaveform = YES;
	  break;
	case MK_velocity:
	  velocity = MKGetNoteParAsDouble(aNote,MK_velocity);
	  setAmpEnv = YES;
	  break;
	case MK_velocitySensitivity:
	  velocitySensitivity = 
	    MKGetNoteParAsDouble(aNote,MK_velocitySensitivity);
	  setAmpEnv = YES;
	  break;
	case MK_waveform:
	  waveform = MKGetNoteParAsWaveTable(aNote,MK_waveform);
	  setWaveform = YES;
	  break;
	case MK_waveLen:
	  wavelen = MKGetNoteParAsInt(aNote,MK_waveLen);
	  setWaveform = setM1Waveform = setM1Ratio = YES; 
	  break;
	default: /* Skip unrecognized parameters */
	  break;
      } /* End of parameter loop. */

    /* -------------------------------- Waveforms --------------------- */
    if (setWaveform)
      [CARRIER_UG setTable:waveform length:wavelen defaultToSineROM:newPhrase];
    if (setM1Waveform)
      [MODULATOR_UG setTable:m1Waveform length:wavelen 
       defaultToSineROM:newPhrase];

    /* ------------------------------- Frequency scaling --------------- */
    if (setCRatio)
	[CARRIER_UG setIncRatio:cRatio];
    if (setM1Ratio)
      /* Since table lengths may be set automatically (if wavelen is 0),
	 we must account here for possible difference in table lengths 
	 between carrier and modulator. */
	[MODULATOR_UG setIncRatio:m1Ratio * [MODULATOR_UG tableLength] / 
	 [CARRIER_UG tableLength]];

    /* ------------------------------- Phases -------------------------- */
    if (setPhase) {
	[CARRIER_UG setPhase:phase];
	[MODULATOR_UG setPhase:m1Phase];
    }

    /* ------------------------------ Envelopes ------------------------ */
    if (setAmpEnv) 
	MKUpdateAsymp(AMP_ENV_UG,ampEnv,amp0,
		      amp1 * 
		      MKMidiToAmpWithSensitivity(velocity,velocitySensitivity),
		      ampAtt,ampRel,portamento,phraseStatus);
    if (setFreqEnv) {
	double fr0, fr1;
	fr0 = MKAdjustFreqWithPitchBend(freq0,pitchbend,pitchbendSensitivity);
	fr1 = MKAdjustFreqWithPitchBend(freq1,pitchbend,pitchbendSensitivity);
	MKUpdateAsymp(FREQ_ENV_UG,freqEnv,
		      [CARRIER_UG incAtFreq:fr0], // Convert to osc increment
		      [CARRIER_UG incAtFreq:fr1], 
		      freqAtt,freqRel,portamento,phraseStatus);
    }
    if (setM1IndEnv) {
	double FMDeviation = [CARRIER_UG incAtFreq:(m1Ratio * freq1)] * bright;
	/* See literature on FM synthesis for details about the scaling by
	   FMDeviation */
	MKUpdateAsymp(IND_ENV_UG, m1IndEnv, 
		      m1Ind0 * FMDeviation, m1Ind1 * FMDeviation,
		      m1IndAtt,m1IndRel,portamento,phraseStatus);
    }

    /* ----------------------------- Vibrato ---------------------------- */
    if (setVibWaveform) 
	[SVIB_UG setTable:vibWaveform length:128 defaultToSineROM:YES];
    if (setVibFreq) 
	[SVIB_UG setFreq:svibFreq0 + (svibFreq1-svibFreq0) * 
	 midiVal(modWheel)];
    if (setVibAmp)
	[SVIB_UG setAmp:svibAmp0 + (svibAmp1-svibAmp0) * midiVal(modWheel)];
    if (setRandomVib) {
	[NVIB_FILTER_UG setB0:0.004 * rvibAmp]; /* Filter gain (rvibAmp) */
	[NVIB_FILTER_UG clear];                 /* Clear filter state */
	if (newPhrase) {
	    [NVIB_FILTER_UG setA1:-0.9999]; /* Filter feedback coefficient */
	    [NVIB_UG anySeed]; /* Make each instance have different vib */
	}
    }

    /* ------------------- Bearing, volume and after touch -------------- */
    if (setOutput)
	[OUTPUT_UG setBearing:bearing scale:MKMidiToAmpAttenuation(volume)];
    if (setAfterTouch)
	[FM_ADDER_UG setScale:(1-afterTouchSensitivity) + 
	 afterTouchSensitivity * midiVal(afterTouch)];

    return self;
}    

@end

