#ifndef __MK_Chord_H___
#define __MK_Chord_H___
#import <MusicKit/MusicKit.h>
#import "EnsembleNoteFilter.h"

#define MAXCHORDSIZE 5
#define NUMMAPS 16

@interface Chord : EnsembleNoteFilter
    /* A NoteFilter subclass which maps chords to single notes */
{
    int note, octave, relativeNote;
    int currentSet, displayedSet;
    int maxSetNum;
    int tagMapIndex;
    int chordMap[NUMMAPS][12][MAXCHORDSIZE];
    int tagMap[512][MAXCHORDSIZE+1];
    int controller;
    int noteController;
    double controlVals[NUMMAPS][MAXCHORDSIZE];
    BOOL midiNoteSelection;
    BOOL damping;
    id hashTable;
	BOOL incrementing;

    id mapNumField;
    id enableInputButton;
    id controlValFields;
	id noteButtons;
	id mapChangeButtons;
    id controllerInterface;
    id noteInterface;
	id dampSwitch;
}

- enableNoteSelection:sender;
- takeRelativeNoteFrom:sender;
- addNote:(int)n;
- clear:sender;
- takeControllerFrom:sender;
- takeControlValFrom:sender;
- takeKeyNumFrom:sender;
- takeSetNumFrom:sender;
- takeDampingFrom:sender;
- takeIncrementingFrom:sender;

@end


#endif
