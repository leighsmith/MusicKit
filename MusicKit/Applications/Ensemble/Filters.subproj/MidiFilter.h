#ifndef __MK_MidiFilter_H___
#define __MK_MidiFilter_H___
#import "EnsembleNoteFilter.h"

@interface MidiFilter : EnsembleNoteFilter
    /* A NoteFilter subclass that thins the pitchbend, aftertouch, and
       controller updates. */
{    
    int thruControl;
    BOOL thruState;
    BOOL initialThruState;
    BOOL thruEnabled;
    BOOL thru;
    
    int minVals[131];
    int lastVals[131];
    double minControlTimes[131];
    double lastControlTimes[131];
    int controlAction[131];
    int controller;
    BOOL filteringEnabled;

    int noteNum;
    double velocityScaler[128];
    int octaveShift[128];
    BOOL noteAdjustingEnabled;

    double doubleAttackTime;
    int harmonicThreshold;
    BOOL attackFilteringEnabled;
    int lastKeyNum;
    MKMsgStruct *noteOffMsg;
    int lastNoteTag;
    int noteOffTag;

    id thruControlInterface;
	id thruOnButtons;
	id thruStateButtons;
	id dataThruSwitch;

    id controllerInterface;
    id minValField;
    id minTimeField;
    id minValButtons;
    id minTimeButtons;
    id actionButtons;
	id controlFilterSwitch;

    id noteInterface;
    id velocityScalerField;
    id octaveShiftField;
	id velocityAdjustSwitch;
	
    id attackTimeField;
    id thresholdField;
	id attackFilterSwitch;
}

- takeControllerFrom:sender;
- takeMinValFrom:sender;
- takeMinTimeFrom:sender;
- takeActionFrom:sender;
- enableControlFilter:sender;

- takeNoteNumberFrom:sender;
- takeOctaveShiftFrom:sender;
- takeVelocityScalerFrom:sender;
- takeThresholdFrom:sender;
- takeAttackTimeFrom:sender;
- enableNoteFilter:sender;
- enableAttackFilter:sender;

- enableThruSwitch:sender;
- takeInitialThruFrom:sender;
- takeThruStateFrom:sender;
- takeThruControllerFrom:sender;

@end


#endif
