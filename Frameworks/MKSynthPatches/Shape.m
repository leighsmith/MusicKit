/* Shape.m 
 *
 * Eric J. Graves and David A. Jaffe
 * (c) 1992 Eric J. Graves & Stanford University
 *
 * Modification history:
 *
 * 9/25/93/daj - modified and optimized for incorporation into 
 *               Music Kit release.  Added signification.
 */

#import <MKUnitGenerators/MKUnitGenerators.h> 
#import <MusicKit/midi_spec.h>
#import <math.h>

#import "Shape.h"

/* We call our Shape MKSynthPatch with Envelopes 'Shape'. */
@implementation Shape;

/* Statically declare the synthElement indices. */
static int 
  _freqAsymp,         /* frequency envelope UG */
  _indAsymp,          /* The Index Envelope */
  _osc,               /* oscillator UG */
  _tab,               /* Table lookup */
  _mul,               /* The multiplier to apply the post-tablook 
			amplitude envelope*/
  _ampAsymp,          /* The UG to create the postamp envelope*/
  _ampPp,             /* Patch Point for postamp envelope */
  _stereoOut,         /* output UG */
  _ySig,           /* a frequency patch point */
  _xSig;           /* another frequency patchpoint */ 

+patchTemplateFor: (MKNote *) aNote
{
    /* Step 1: Create (or return) the MKPatchTemplate. */
    static MKPatchTemplate *theTemplate = nil;
  if (theTemplate)
    return theTemplate;
  theTemplate = [[MKPatchTemplate alloc] init];

  /* Step 2:  Add the SynthElement specifications. */	

  _freqAsymp = [theTemplate addUnitGenerator:MKAsympUGyClass()];
  _indAsymp  = [theTemplate addUnitGenerator:MKAsympUGxClass()];
  _osc       = [theTemplate addUnitGenerator:[OscgafiUGxxyy class]];
  _tab       = [theTemplate addUnitGenerator:[TablookiUGyxx class]];
  _ampAsymp  = [theTemplate addUnitGenerator:MKAsympUGxClass()];
  _mul       = [theTemplate addUnitGenerator:[Mul2UGxxy class]];
  _stereoOut = [theTemplate addUnitGenerator:[Out2sumUGx class]];
  
  _ySig  = [theTemplate addPatchpoint:MK_yPatch];
  _xSig  = [theTemplate addPatchpoint:MK_xPatch];
  
  /* Step 3:  Specify the connections. */
  [theTemplate to:_freqAsymp sel:@selector(setOutput:) arg:_ySig];
  [theTemplate to:_indAsymp  sel:@selector(setOutput:) arg:_xSig];
  [theTemplate to:_osc sel:@selector(setAmpInput:)   arg:_xSig];
  [theTemplate to:_osc sel:@selector(setIncInput:)   arg:_ySig];
  [theTemplate to:_osc sel:@selector(setOutput:)     arg:_xSig];
  [theTemplate to:_tab sel:@selector(setInput:)  arg:_xSig];
  [theTemplate to:_tab sel:@selector(setOutput:) arg:_ySig];
  [theTemplate to:_ampAsymp  sel:@selector(setOutput:) arg:_xSig];
  [theTemplate to:_mul sel:@selector(setInput1:)     arg:_xSig];
  [theTemplate to:_mul sel:@selector(setInput2:)     arg:_ySig];
  [theTemplate to:_mul sel:@selector(setOutput:)     arg:_xSig];
  /* Return the MKPatchTemplate. */	
  return theTemplate;
}

-_initUGvars {
  freqAsymp = [self synthElementAt:_freqAsymp]; 
  indAsymp  = [self synthElementAt:_indAsymp]; 
  osc       = [self synthElementAt:_osc]; 
  tab       = [self synthElementAt:_tab]; 
  ampAsymp  = [self synthElementAt:_ampAsymp]; 
  mul       = [self synthElementAt:_mul]; 
  stereoOut = [self synthElementAt:_stereoOut]; 
  xSig = [self synthElementAt:_xSig]; 
  ySig = [self synthElementAt:_ySig]; 
  return self;
}

- init
{
  /* Sent once when the patch is created. */
  [self _initUGvars];
  [osc setTable:nil defaultToSineROM:YES];
  [tab setLookupTable:nil];
  return self;
}

-controllerValues:controllers
  /* Sent when a new phrase starts. controllers is a HashTable containing
   * key/value pairs as controller-number/controller-value. Our implementation
   * here ignores all but MIDI_MAINVOLUME and MIDI_MODWHEEL. See
    * <objc/HashTable.h>, <MusicKit/midi_spec.h>, and <MusicKit/MKSynthPatch.h>. */
{
#   define CONTROLPRESENT(_key) [controllers isKey:(const void *)_key]
#   define GETVALUE(_key) (int)[controllers valueForKey:(const void *)_key]
    if (CONTROLPRESENT(MIDI_MAINVOLUME))
      volume = GETVALUE(MIDI_MAINVOLUME);
    return self;
}

- _setDefaults
{
  waveform = nil;
  wavelen = 0;
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

  indEnv   = nil;
  indAtt   = MK_NODVAL;      /* parameter not present */
  indRel   = MK_NODVAL;      /* parameter not present */
  m1Ind0   = 0.0;              
  m1Ind1   = 1.0;    
  bright   = 1.0;
  
  portamento = MK_DEFAULTPORTAMENTO; 	/* 0.1 */
  bearing = MK_DEFAULTBEARING;	/* 0.0 (centered between speakers) */

  tableInfo = NULL;
  
  /* MIDI parameters */
  velocitySensitivity = 0.5;
  velocity = MK_DEFAULTVELOCITY;    
  volume = MIDI_MAXDATA;
  pitchbend = MIDI_ZEROBEND;
  pitchbendSensitivity = 3.0;
  return self;
}

-_makeTable:(MKWaveTable *)wt
  /* If you pass makeTable nil, you will get a table that is 
   * straight-line... ie, the first fundamental, and that's it! */
{
# define TABLESIZE 129    /* Can be any odd number. Was 513 */
  int i;
  [table dealloc];  /* Deallocate or release claim on previous, but
		     * only if we allocated it
		     */
  if ([wt isKindOfClass: [MKWaveTable class]]) {  
      if (wt) {
	  table = [orchestra sharedSynthDataFor:wt segment:MK_xData
		 type:MK_waveshapingTable];
	  if (table) 
	    return table;
      }
  } else if ([wt isMemberOfClass:[MKSynthData class]]) 
    return wt; /* Don't set table var here! User frees it. */
  if ([wt isMemberOfClass:[MKPartials class]]) {  
      table = [orchestra allocSynthData:MK_xData length:TABLESIZE];
      if (!table) 
	return nil;
      [orchestra installSharedSynthDataWithSegmentAndLength:table for:wt
       type:MK_waveshapingTable];
      [(MKSynthData *)table setData:[(MKPartials *)wt dataDSPAsWaveshapingTableLength:TABLESIZE]];
  } else if ([wt isMemberOfClass:[MKSamples class]]) {
      table = [orchestra allocSynthData:MK_xData length:[wt length]];
      if (!table) 
	return nil;
      [orchestra installSharedSynthDataWithSegment:table for:wt
       type:MK_waveshapingTable];
      [(MKSynthData *)table setData:[wt dataDSP]];
  }
  else {
    /* This portion of code simply creates a straight-line mapping.
       * This is the first harmonic... ie, no change!*/
      DSPDatum vals[TABLESIZE];  

      table = [orchestra allocSynthData:MK_xData length:TABLESIZE];
      /* Don't install it in shared table this time */
      if (!table)
	return nil;
      for (i=0; i<TABLESIZE; i++) 
	vals[i] = DSPDoubleToFix24((2*i/((double)TABLESIZE-1))-1.0);
      [(MKSynthData *)table setData:vals];
  }
  return table;
}

- preemptFor: (MKNote *) aNote
{
    [ampAsymp preemptEnvelope]; 
    [self _setDefaults];
    return self;
}

#define MIDIVAL(midiControllerValue) \
  ((double)midiControllerValue)/((double)MIDI_MAXDATA)

- _applyParameters:aNote
  /* This is a private method to the Shape class. 
   * It is used internally only.
   */
{
    int par;
    void *state; /* For parameter iteration below */
    
    /* Store the phrase status. */	
    MKPhraseStatus phraseStatus = [self phraseStatus];

    /* Used in the parameter checks. */
    BOOL setAmp,setFreq,setInd,setBearing,setWT,setWaveform=NO,setPhase,newPhrase;
    
    switch (phraseStatus) {
      case MK_phraseOn:          /* New phrase. */
      case MK_phraseOnPreempt:   /* New phrase but using preempted patch. */
        newPhrase = setAmp = setFreq = setInd = setWT = 
	  setBearing = setPhase = YES; 
	/* Set everything for new phrase */
	break;
      case MK_phraseRearticulate: /* NoteOn rearticulation within phrase. */
	/* Just restart envelopes */
        setAmp = setFreq = setInd = YES;
	newPhrase = setPhase = setWT = setBearing = NO; 
	break;
      case MK_phraseUpdate:       /* NoteUpdate to running phrase. */
      case MK_phraseOff:          /* NoteOff to running phrase. */
      case MK_phraseOffUpdate:    /* NoteUpdate to finishing phrase. */
      default: 
	newPhrase = setPhase = setAmp = setFreq = setInd = 
	  setWT = setBearing = NO; /* Set only what's in note */
	break;
    }

    state = MKInitParameterIteration(aNote);
    while (par = MKNextParameter(aNote, state))  
      switch (par) {          
	case MK_ampEnv:
	  ampEnv = MKGetNoteParAsEnvelope(aNote,MK_ampEnv);
	  setAmp = YES;
	  break;
	case MK_ampAtt:
	  ampAtt = MKGetNoteParAsDouble(aNote,MK_ampAtt);
	  setAmp = YES;
	  break;
	case MK_ampRel:
	  ampRel = MKGetNoteParAsDouble(aNote,MK_ampRel);
	  setAmp = YES;
	  break;
	case MK_amp0:
	  amp0 = MKGetNoteParAsDouble(aNote,MK_amp0);
	  setAmp = YES;
	  break;
	case MK_amp1: /* MK_amp is synonym */
	  amp1 = MKGetNoteParAsDouble(aNote,MK_amp1);
	  setAmp = YES;
	  break;
	case MK_bearing:
	  bearing = MKGetNoteParAsDouble(aNote,MK_bearing);
	  setBearing = YES;
	  break;
	case MK_bright:
	  bright = MKGetNoteParAsDouble(aNote,MK_bright);
	  setInd = YES;
	  break;
	case MK_controlChange: {
	    int controller = MKGetNoteParAsInt(aNote,MK_controlChange);
	    if (controller == MIDI_MAINVOLUME) {
		volume = MKGetNoteParAsInt(aNote,MK_controlVal);
		setBearing = YES; 
	    } 
	    break;
	}
	case MK_freqEnv:
	  freqEnv = MKGetNoteParAsEnvelope(aNote,MK_freqEnv);
	  setFreq = YES;
	  break;
	case MK_freqAtt:
	  freqAtt = MKGetNoteParAsDouble(aNote,MK_freqAtt);
	  setFreq = YES;
	  break;
	case MK_freqRel:
	  freqRel = MKGetNoteParAsDouble(aNote,MK_freqRel);
	  setFreq = YES;
	  break;
	case MK_freq:
	case MK_keyNum:
	  freq1 = [aNote freq]; /* A special method (see <MusicKit/Note.h>) */
	  setFreq = YES;
	  break;
	case MK_freq0:
	  freq0 = MKGetNoteParAsDouble(aNote,MK_freq0);
	  setFreq = YES;
	  break;
	case MK_m1IndEnv:
	  indEnv = MKGetNoteParAsEnvelope(aNote,MK_m1IndEnv);
	  setInd = YES;
	  break;
	case MK_m1IndAtt:
	  indAtt = MKGetNoteParAsDouble(aNote,MK_m1IndAtt);
	  setInd = YES;
	  break;
	case MK_m1IndRel:
	  indRel = MKGetNoteParAsDouble(aNote,MK_m1IndRel);
	  setInd = YES;
	  break;
	case MK_m1Ind0:
	  m1Ind0 = MKGetNoteParAsDouble(aNote,MK_m1Ind0);
	  setInd = YES;
	  break;
	case MK_m1Ind1:
	  m1Ind1 = MKGetNoteParAsDouble(aNote,MK_m1Ind1);
	  setInd = YES;
	  break;
	case MK_phase:
	  phase = MKGetNoteParAsDouble(aNote,MK_phase);
	  /* To avoid clicks, we don't allow phase to be set except at the 
	     start of a phrase. Therefore, we don't set setPhase. */
	  break;
	case MK_pitchBendSensitivity:
	  pitchbendSensitivity = 
	    MKGetNoteParAsDouble(aNote,MK_pitchBendSensitivity);
	  setFreq = YES;
	  break;
	case MK_pitchBend:
	  pitchbend = MKGetNoteParAsInt(aNote,MK_pitchBend);
	  setFreq = YES;
	  break;
	case MK_portamento:
	  portamento = MKGetNoteParAsDouble(aNote,MK_portamento);
	  setFreq = setInd = setAmp = YES;
	  break;
	case MK_m1Waveform:
	  tableInfo = MKGetNoteParAsWaveTable(aNote,MK_m1Waveform);
	  setWT = YES;
	  break;
	case MK_velocity:
	  velocity = MKGetNoteParAsDouble(aNote,MK_velocity);
	  setAmp = YES;
	  break;
	case MK_velocitySensitivity:
	  velocitySensitivity = 
	    MKGetNoteParAsDouble(aNote,MK_velocitySensitivity);
	  setAmp = YES;
	  break;
	case MK_waveform:
	  waveform = MKGetNoteParAsWaveTable(aNote,MK_waveform);
	  setWaveform = YES;
	  break;
  	case MK_waveLen:
	  wavelen = MKGetNoteParAsInt(aNote,MK_waveLen);
	  setWaveform = YES; 
	  break;
	default:
	  break;
      }
    
    if (setWaveform)
      [osc setTable:waveform length:wavelen defaultToSineROM:newPhrase];

    if (setPhase)
      [osc setPhase:phase];

    /* Apply the amplitude parameters. */
    if (setAmp)
      MKUpdateAsymp(ampAsymp,ampEnv, amp0, 
		    amp1 *
		    MKMidiToAmpWithSensitivity(velocity,velocitySensitivity),
		    ampAtt, ampRel, portamento, phraseStatus);
    
    /* Apply the frequency parameters. */
    if (setFreq) {
	double fr0, fr1;
	fr0 = MKAdjustFreqWithPitchBend(freq0,pitchbend,pitchbendSensitivity);
	fr1 = MKAdjustFreqWithPitchBend(freq1,pitchbend,pitchbendSensitivity);
	MKUpdateAsymp(freqAsymp,freqEnv,
		      [osc incAtFreq:fr0], /* Convert to osc increment */
		      [osc incAtFreq:fr1], 
		      freqAtt,freqRel,portamento,phraseStatus);
    }
    
    if (setInd) 
	MKUpdateAsymp(indAsymp, indEnv,
		      m1Ind0 * bright,m1Ind1 * bright,
		      indAtt, indRel, portamento, phraseStatus);
    
    if (setBearing)
      [stereoOut setBearing:bearing scale:MKMidiToAmpAttenuation(volume)];
    
    if (setWT) {
	id theTable;
	if (!(theTable = [self _makeTable:tableInfo])) {
	    MKErrorCode(MK_spsCantGetMemoryErr,"table",MKGetTime());
	    return nil;
	}
	[tab setLookupTable:theTable];
    }
    return self;
}    

- noteOnSelf: (MKNote *) aNote
{
    /* Apply the parameters to the patch. */	
    [self _applyParameters:aNote];

    /* Make the final connection to the output sample stream. */	
    [stereoOut setInput:xSig];

    /* Tell the UnitGenerators to begin running. */	
    [synthElements makeObjectsPerform:@selector(run)];

    return self;
}

- noteUpdateSelf: (MKNote *) aNote
{
    /* Apply the parameters to the patch. */	
    [self _applyParameters:aNote];
	
    return self;	
}

- (double)noteOffSelf: (MKNote *) aNote
{   
    double x,y;
    /* Apply the parameters. */
    [self _applyParameters: aNote];

    /* Signal release of index Envelope*/
    x = [indAsymp finish];
 
    /* Signal the release portion of the frequency Envelope. */
    [freqAsymp finish];

    /* Same for amplitude */
    y = [ampAsymp finish];

    /* Since both amplitude and index affect the amplitude, take MAX 
     * as the time needed to finish */
    return (y>x) ? y : x;
}

- noteEndSelf
{
    [table dealloc];
    table = nil;

    /* Remove the patch's Out2sum from the output sample stream. */
    [stereoOut idle]; 

    /* Abort the frequency Envelope. */
    [freqAsymp abortEnvelope];

    /* Abort the amp Envelope. */
    [ampAsymp abortEnvelope];

    /* Abort Index envelope */
    [indAsymp abortEnvelope];

    /* Set the instance variables to their default values. */ 
    [self _setDefaults];

    return self;
}

@end


