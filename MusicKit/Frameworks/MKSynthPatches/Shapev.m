/* Shapev.m 
 *
 * Here we encapsulate the vibrato additions to Shape.
 */

#import <unitgenerators/unitgenerators.h> 
#import <MusicKit/midi_spec.h>
#import <math.h>

#import "Shapev.h"

@implementation Shapev;

/* Statically declare the synthElement indices. */
static int 
  _svib,              /* Sinusoidal (or other) vib */
  _nvib,              /* Noise vib */
  _onep,              /* One pole filter for noise */
  _add,               /* Vib sum */
  _freqAsymp,         /* frequency envelope UG */
  _freqMul,            /* Combine freq env with vib */
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

+patchTemplateFor:aNote
{
    static MKPatchTemplate *theTemplate = nil;
  if (theTemplate)
    return theTemplate;
  theTemplate = [[MKPatchTemplate alloc] init];

  _svib  = [theTemplate addUnitGenerator:[OscgUGyy class]];
  _nvib  = [theTemplate addUnitGenerator:[SnoiseUGx class]];
  _onep  = [theTemplate addUnitGenerator:[OnepoleUGxx class]];
  _add   = [theTemplate addUnitGenerator:[Add2UGyxy class]];
  _freqAsymp = [theTemplate addUnitGenerator:MKAsympUGxClass()];
  _freqMul   = [theTemplate addUnitGenerator:[Mul1add2UGyxyx class]];
  _indAsymp  = [theTemplate addUnitGenerator:MKAsympUGxClass()];
  _osc       = [theTemplate addUnitGenerator:[OscgafiUGxxyy class]];
  _tab       = [theTemplate addUnitGenerator:[TablookiUGyxx class]];
  _ampAsymp  = [theTemplate addUnitGenerator:MKAsympUGxClass()];
  _mul       = [theTemplate addUnitGenerator:[Mul2UGxxy class]];
  _stereoOut = [theTemplate addUnitGenerator:[Out2sumUGx class]];

  _ySig  = [theTemplate addPatchpoint:MK_yPatch];
  _xSig  = [theTemplate addPatchpoint:MK_xPatch];
  
  [theTemplate to:_svib  sel:@selector(setOutput:)   arg:_ySig];
  [theTemplate to:_nvib  sel:@selector(setOutput:)   arg:_xSig];
  [theTemplate to:_onep  sel:@selector(setInput:)    arg:_xSig];
  [theTemplate to:_onep  sel:@selector(setOutput:)   arg:_xSig];
  [theTemplate to:_add   sel:@selector(setInput1:)   arg:_xSig];
  [theTemplate to:_add   sel:@selector(setInput2:)   arg:_ySig];
  [theTemplate to:_add   sel:@selector(setOutput:)   arg:_ySig];
  [theTemplate to:_freqAsymp sel:@selector(setOutput:) arg:_xSig];
  [theTemplate to:_freqMul   sel:@selector(setInput1:)   arg:_xSig];
  [theTemplate to:_freqMul   sel:@selector(setInput2:)   arg:_ySig];
  [theTemplate to:_freqMul   sel:@selector(setInput3:)   arg:_xSig];
  [theTemplate to:_freqMul   sel:@selector(setOutput:)   arg:_ySig];
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

- _initUGvars {
    /* Invoked by superclass' -init method. */
  svib = [self synthElementAt:_svib]; 
  nvib = [self synthElementAt:_nvib]; 
  onep = [self synthElementAt:_onep]; 
  add = [self synthElementAt:_add]; 
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

-controllerValues:controllers
  /* Sent when a new phrase starts. controllers is a HashTable containing
   * key/value pairs as controller-number/controller-value. Our implementation
   * here ignores all but MIDI_MAINVOLUME and MIDI_MODWHEEL. See
    * <objc/HashTable.h>, <MusicKit/midi_spec.h>, and <MusicKit/MKSynthPatch.h>. */
{
#   define CONTROLPRESENT(_key) [controllers isKey:(const void *)_key]
#   define GETVALUE(_key) (int)[controllers valueForKey:(const void *)_key]
    [super controllerValues:controllers];
    if (CONTROLPRESENT(MIDI_MODWHEEL))
      modWheel = GETVALUE(MIDI_MODWHEEL);
    return self;
}

- _setDefaults
  /* Invoked by superclass */
{
  [super _setDefaults];
  svibAmp0 = svibAmp1 = 0.0;       
  svibFreq0 = svibFreq1 = 0.0;   
  rvibAmp   = 0.0;             
  modWheel = MIDI_MAXDATA;
  vibWaveform = nil;
  return self;
}

#define MIDIVAL(midiControllerValue) \
  ((double)midiControllerValue)/((double)MIDI_MAXDATA)

- _applyParameters:aNote
  /* This is a private method to the Shapev class. 
   * Invoked by the superclass.
   */
{
    BOOL newPhrase = ([self phraseStatus] <= MK_phraseOnPreempt);
    BOOL setVibWaveform,setVibAmp,setVibFreq,setRandomVib;
    [super _applyParameters:aNote];
    setVibFreq = setVibWaveform = setRandomVib = setVibAmp = newPhrase;
    if (MKGetNoteParAsInt(aNote,MK_controlChange) == MIDI_MODWHEEL) {
	modWheel = MKGetNoteParAsInt(aNote,MK_controlVal);
	setVibFreq = setVibAmp = YES;
    }
    if (MKIsNoteParPresent(aNote,MK_rvibAmp)) {
	rvibAmp = MKGetNoteParAsDouble(aNote,MK_rvibAmp);
	setRandomVib = YES;
    }
    if (MKIsNoteParPresent(aNote,MK_svibFreq0)) {
	svibFreq0 = MKGetNoteParAsDouble(aNote,MK_svibFreq0);
	setVibFreq = YES;
    }
    if (MKIsNoteParPresent(aNote,MK_svibFreq1)) {
	svibFreq1 = MKGetNoteParAsDouble(aNote,MK_svibFreq1);
	setVibFreq = YES;
    }
    if (MKIsNoteParPresent(aNote,MK_svibAmp0)) {
	svibAmp0 = MKGetNoteParAsDouble(aNote,MK_svibAmp0);
	setVibAmp = YES;
    }
    if (MKIsNoteParPresent(aNote,MK_svibAmp1)) {
	svibAmp1 = MKGetNoteParAsDouble(aNote,MK_svibAmp1);
	setVibAmp = YES;
    }
    if (MKIsNoteParPresent(aNote,MK_vibWaveform)) {
	vibWaveform = MKGetNoteParAsWaveTable(aNote,MK_vibWaveform);
	setVibWaveform = YES;
    }
    if (setVibWaveform) 
      [svib setTable:vibWaveform length:128 defaultToSineROM:YES];
    if (setVibFreq) 
      [svib setFreq:svibFreq0 + (svibFreq1-svibFreq0) * MIDIVAL(modWheel)];
    if (setVibAmp)
      [svib setAmp:svibAmp0 + (svibAmp1-svibAmp0) * MIDIVAL(modWheel)];
    if (setRandomVib) {
	[onep setB0:0.004 * rvibAmp]; /* Filter gain (rvibAmp) */
	[onep clear];                 /* Clear filter state */
	if (newPhrase) {
	    [onep setA1:-0.9999]; /* Filter feedback coefficient */
	    [nvib anySeed]; /* each instance has different vib */
	}
    }
    return self;
}    

@end


