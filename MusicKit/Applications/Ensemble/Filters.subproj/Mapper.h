#ifndef __MK_Mapper_H___
#define __MK_Mapper_H___
#import <musickit/musickit.h>
#import "EnsembleNoteFilter.h"

#define NUMMAPS 6

@interface Mapper : EnsembleNoteFilter
    /* A NoteFilter subclass which maps MIDI data to other MIDI data */
{
    id newNote;
	
	id enabledButtons;
	id clickButtons;
    id inputInterface;
	id outputInterface;
	id thruButtons;
    id doubleClickTimeField;
	id sequentialSwitch;
	id functionButtons;
	id inspectButtons;
	id envelopeView;

    int map[NUMMAPS][2];
    id envelopes[NUMMAPS];
    BOOL enabled[NUMMAPS];
    BOOL functionEnabled[NUMMAPS];
    BOOL mapThru[NUMMAPS];
    BOOL sequentialMapping;
    double doubleClickTime;
    double lastNoteTime[NUMMAPS];
    int doubleClicks[NUMMAPS];
    int clickCount[NUMMAPS];
	BOOL inSequence[NUMMAPS];
	int nextMap[NUMMAPS];
	BOOL sendThru;
}

- takeInputFrom:sender;
- takeOutputFrom:sender;
- enableFunction:sender;
- editEnvelope:sender;
- enableMap:sender;
- enableThru:sender;
- enableSequentialMapping:sender;
- takeDoubleClickFrom:sender;
- takeDoubleClickTimeFrom:sender;

@end


#endif
