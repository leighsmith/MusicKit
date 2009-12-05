#ifndef __MK_MidiOutInstrument_H___
#define __MK_MidiOutInstrument_H___
#import "EnsembleIns.h"
#import <musickit/Note.h>
#import <objc/HashTable.h>

@interface MidiOutInstrument:EnsembleIns
    /* An Instrument which handles MIDI output */
{
    id  info;					/* Like SynthInstrument update note */
    id  midi;
    id  channelField;
    id  velocityField;
    id  velocitySlider;
    id  minVelField;
    id  minVelSlider;
    id  controlValField;
    id  controlValSlider;
    id  controlInterface;
    id  controlRangeFields;
    id  controlRangeSliders;
    id  velocityRangeFields;
    id  velocityRangeSliders;
    id  midiNoteReceiver;
    id  controlNote;
    int noteTags[16];
    int tagIndex;
@public
    int velocityIncrement;		/* value added to velocity */
    unsigned int outChan;		/* output MIDI channel */
    int minVel; 				/* minimum velocity for passing notes */
    int controller, controlVal;	/* MIDI controller value */
    int velocityAdjustMin;
    int velocityAdjustMax;
    int controlMin;
    int controlMax;
    double controlTmp;
    int controlController;
    int channelController;
    int velocityController;
}

- takeVelocityFrom:sender;
- takeMinVelFrom:sender;
- takeControlValFrom:sender;
- takeControllerFrom:sender;
- (int)testKey;
- takeChannelFrom:sender;
- takeControlRangeFrom:sender;
- takeVelocityRangeFrom:sender;
- abort;
- getUpdates:(Note **)aNoteUpdate controllerValues:(HashTable **)controllers;
- setMidi:newMidi;
- (unsigned int)outChan;

@end


#endif
