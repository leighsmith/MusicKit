
#import <appkit/appkit.h>

#import <apps/Preferences.h>

@interface MusicKitPrefs:Layout
{
    id	dspDriverPopUpButton;
    id	dspNumField;
    id	midiNumField;
    id	midiUnitNumField;
    id	midiUnitNumSlider;
    id	serialPortDevicePopUpButton;
    id	window;
    id  dspText,midiText;
    id  soundOutMatrix;
    id  dspNumDec,dspNumInc,midiNumDec,midiNumInc;
}

- setDspNum:sender;
- setMidiNum:sender;
- setMidiUnit:sender;
- setSoundOutType:sender;

@end
