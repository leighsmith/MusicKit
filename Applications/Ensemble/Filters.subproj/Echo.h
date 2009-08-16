#ifndef __MK_Echo_H___
#define __MK_Echo_H___
#import "EnsembleNoteFilter.h"

#define MAXDELAYS 8
#define MAXECHOS 12

@interface Echo : EnsembleNoteFilter
    /* A NoteFilter subclass which schedules echos of notes */
{
    int curDelay;
    BOOL thru;
    int tagMapIndex;
    id hashTable;
    id defaultConductor;
    BOOL delayUntaggedUpdates;
    
    double delayTimes[MAXDELAYS];
    int numEchos[MAXDELAYS];
    int attenuation[MAXDELAYS];
    double ranVariation[MAXDELAYS];
    int controlVals[MAXDELAYS][2];
    int controllers[MAXDELAYS][2];
    int tagMap[512][MAXDELAYS][MAXECHOS];

    id curDelayField;
    id delayTimeInterface;
	id paramInterface;
	id controllerInterface;
	id controlValInterface;
	id bearingSwitch;
	id delaySwitch;
	id thruButton;
    MKPerformerStatus status;
}

- takeDelayTimeFrom:sender;
- takeParamFrom:sender;
- takeControllerFrom:sender;
- takeControlValFrom:sender;
- takeCurDelayFrom:sender;
- toggleThru:sender;
- takeDelayUntaggedFrom:sender;

@end
  
  

#endif
