#ifndef __MK_PianoOctave_H___
#define __MK_PianoOctave_H___
#import <AppKit/Control.h>

@interface PianoOctave : Control
    /* One octave of a piano keyboard view */
{
    NSRect keyRects[19];	/* The rects for the keys */
    int keyStates[12];		/* The state of the keys */
    int value;			/* The key being clicked on */
    id target;			/* Who gets tapped when a key goes down */
    SEL action;			/* The message that gets sent */
}

- setKey:(int) keyNum toState:(int) state;
- (int)state:(int)keyNum;

@end


#endif
