#ifndef __MK_MidiFilter_H___
#define __MK_MidiFilter_H___
/* Based on Ensemble MidiFilter */

#import <musickit/NoteFilter.h>

typedef enum _actionType {STOP,THIN,PASS} actionType;

@interface MidiFilter : NoteFilter
    /* A simple note filter that thins the pitchbend, aftertouch, and
       controller updates. */
{    
    unsigned lastVals[131];
    double lastTimes[131];
    unsigned minVals[131];
    double minTimes[131];
    actionType action[131];
    id noteReceiver;
    id noteSender;
}

@end

#endif
