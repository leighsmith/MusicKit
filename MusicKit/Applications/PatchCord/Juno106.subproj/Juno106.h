/*
 * Roland Juno 106 Synthesiser object declaration header
 */
#import <AppKit/AppKit.h>
#import "../MIDISysExSynth.h"

#define MAX_SLIDERS     16

@interface Juno106: MIDISysExSynth
{
    SysExMessage *update;
    id patchName;	// outlet to the Juno's patch nomenclature A11 etc
    id midiChan;	// outlet to the MIDI channel MiscValueField
    id range;		// User interface outlets
    id chorus;
    id saw;
    id pulse;
    id vca;		// outlet to the Amplifier Gate/Envelope switch
    id envDirection;
    id pwm;
    id hpf;		// outlet to the High Pass Filter sliding switch
    id sliderGroup;		// outlet to the group (Box) enclosing our sliders
    id sliders[MAX_SLIDERS];	// Holds a simple array of our slider objects
				// so we can index them using their parameter
				// numbers efficiently.
}

- (id) init;
- (id) initWithEmptyPatch;
- (BOOL) isParameterUpdate: (SysExMessage *) msg;
- (BOOL) isNewPatch: (SysExMessage *) msg;
- (void) acceptNewPatch: (SysExMessage *) msg;
- (void) parameterUpdate: (SysExMessage *) msg;
- (void) sendUpdate;
- (void) displayPatch;
- (void) updateSliders:sender;
- (void) updateHPF:sender;
- (void) updateSwitches:sender;
- (void) updateRangeAndChorus:sender;
- (void) updateMidiChannel:sender;
- (void) setSliderGroup:aSliderGroup;
- (void) setMidiPatchNumber: (int) midiPatchNumber;
@end

