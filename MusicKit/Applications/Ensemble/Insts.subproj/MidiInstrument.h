#ifndef __MK_MidiInstrument_H___
#define __MK_MidiInstrument_H___
/* Obsolete.  See MidiOutInstrument.m */

#import <musickit/Instrument.h>
#import <musickit/Note.h>
#import <objc/HashTable.h>

@interface MidiInstrument:Instrument
{
    id  document;		/* The document for this instrument */
    id  window;			/* The original instrument window from IB */
    id  view;			/* The window's content view */
    id  info;			/* Like SynthInstrument update note */
    id  parametersWindow;	/* Panel displaying additional parameters */
    id  midi;
    int testKey;		/* key number for test notes */
    int velocityIncrement;	/* value added to velocity */
    unsigned int outChan;		/* output MIDI channel */
    int pan;			/* MIDI pan value */
    int minVel; 		/* minimum velocity for passing notes */
    int controller, controlVal;	/* MIDI controller value */
    int velocityAdjustMin;
    int velocityAdjustMax;
    int controlMin;
    int controlMax;
    double controlTmp;
    int velocityController;
    int channelController;
    int controlController;
    BOOL damperOn;
    id  panDisplayer;		/* interface objects */
    id  afterTouchDisplayer;    /* Obsolete */
    id  velocityDisplayer;
    id  minVelDisplayer;
    id  channelDisplayer;
    id  controllerDisplayer;
    id  controlValDisplayer;
    id  controlControllerDisplayer;
    id  velocityControllerDisplayer;
    id  channelControllerDisplayer;
    id  controlMinDisplayer;
    id  controlMaxDisplayer;
    id  velocityMinDisplayer;
    id  velocityMaxDisplayer;
    id  midiNoteReceiver;
    id  velocityAdjustSlider;
    id  controlSlider;
    id  controlNote;
    int noteTags[16];
    int tagIndex;
}

- takeVelocityFrom:sender;
- takeMinVelFrom:sender;
- takeControlValFrom:sender;
- takeControllerFrom:sender;
- takeChannelFrom:sender;
- takePanFrom:sender;
- takeControlControllerFrom:sender;
- takeVelocityControllerFrom:sender;
- takeChannelControllerFrom:sender;
- takeControlMinFrom:sender;
- takeControlMaxFrom:sender;
- takeVelocityAdjustMinFrom:sender;
- takeVelocityAdjustMaxFrom:sender;
- showParameters:sender;

@end


#endif
