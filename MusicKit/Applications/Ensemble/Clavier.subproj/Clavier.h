#ifndef __MK_Clavier_H___
#define __MK_Clavier_H___
#import <Foundation/Foundation.h>

@interface Clavier:NSObject
    /* A Performer-like object that has three graphic piano octaves
     * with keys that can be clicked on.
     */
{
    id	pianoOctave1;		/* Three PianoOctave controls */
    id	pianoOctave3;
    id	pianoOctave2;
    id	pitchBendSlider;	/* Our special centering slider  */
    id  modWheelSlider;		/* A regular slider */
    id  octaveDisplayer;	/* Displays octave of lowest PianoOctave */
    id  noteSender;		/* For sending notes like a performer  */
    id  window;			/* The Clavier window */
    int lastModVal, lastPitchVal;
    int octave;			/* The base octave */
    int noteTags[128];		/* array of unique note tags */
    int soundGroup;
    id soundGroupMatrix;
    id soundGroupDisplayer;
    int variation;
    id variationMatrix;
    id variationDisplayer;
    int controllers[3];
    id controlValSliders;
    id controllerFields;
    id controllerInterface;
	id programChangeField;
}

- window;
- noteSender;
- takeSostenutoFrom:sender;
- takeKeyValueFrom:sender;
- takeModWheelFrom:sender;
- takePitchBendFrom:sender;
- takeOctaveFrom:sender;
- takeSoundGroupFrom:sender;
- takeVariationFrom:sender;
- takeControlValFrom:sender;
- takeControllerFrom:sender;
- setSound;
- sendController:(int)controller value:(int) value;

@end


#endif
