#ifndef __MK_FractalMelody_H___
#define __MK_FractalMelody_H___
#import "EnsembleNoteFilter.h"

#define NUMSETS 16

@interface FractalMelody : EnsembleNoteFilter
    /* A NoteFilter subclass which controls a performer which generates
     * fractal melodies.
     */
{
    BOOL thru;
    BOOL listening;
    BOOL dynamicMode;
	BOOL triggering;
    int displayedSet;
    int keyRange;
    int controllers[16];

    id thruButton;
	id modeButtons;
	id delayField;

    id setNumField;
    id setDurationInterface;
	id durationSwitch;
    id noteSetButtons;
    id gravityFields;

    id numNotesField;
	id noteSetSwitches;
	id velocityButtons;
    id listeningButton;

    id dynamicGravityInterface;
    id keyInterface;
    id velocityInterface;
    id phrasingInterface;
	id phrasingSwitches;
	id silenceButtons;
    id silenceField;
    id silenceSlider;
    id controlNumInterface;
    id controlValInterface;

    id controllersInterface;
    id controllerPanel;
	
	id noteTagInterface;
	id tagTypeButtons;
	
	int intervalIndex;
	int durationIndex;
}

- toggleThru:sender;
- toggleListening:sender;
- selectMode:sender;
- takeNoteSetFrom:sender;
- takeStaticGravitiesFrom:sender;
- incrementStaticGravity:sender;
- takeKeyNumsFrom:sender;
- takeVelocitiesFrom:sender;
- selectRepeatMode:sender;
- takeNoteIntervalFrom:sender;
- selectRestMode:sender;
- takeSilenceFrom:sender;
- takeControlValsFrom:sender;
- takeControllerFrom:sender;
- takeSetNumFrom:sender;
- takeSetDurationFrom:sender;
- takeControllersFrom:sender;
- takeDelayFrom:sender;
- enableDurations:sender;
- takeNumNotesFrom:sender;
- enableOctaves:sender;
- enableUniqueNotes:sender;
- enablePitchSorting:sender;
- takeVelocityTrackingFrom:sender;
- takeGravityScalingFrom:sender;
- reset:sender;
- inspectFractal:sender;
- takeTagTypeFrom:sender;
- takeNumTagsFrom:sender;
@end


#endif
