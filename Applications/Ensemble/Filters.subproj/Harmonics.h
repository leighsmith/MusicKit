#ifndef __MK_Harmonics_H___
#define __MK_Harmonics_H___
#import <musickit/musickit.h>
#import "EnsembleNoteFilter.h"

@interface Harmonics : EnsembleNoteFilter
    /* A NoteFilter subclass which controls a performer which generates
     * dynamically-changing harmonics
     */
{
    BOOL thru;
    int currentTag;
    int controllers[8];
	id noiseTypeButtons;
	id noRepeatsSwitch;
    id controllerPanel;
    id thruButton;
	id paramInterface;
	id controlInterface;
	id noteTagInterface;
	id tagTypeButtons;
}

- takeParamFrom:sender;
- toggleFractal:sender;
- toggleRepeats:sender;
- toggleThru:sender;
- takeControllersFrom:sender;
- inspectFractal:sender;
- takeTagTypeFrom:sender;
- takeNumTagsFrom:sender;

@end


#endif
