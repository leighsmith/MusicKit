
#import <AppKit/AppKit.h>
#import <SndKit/SndKit.h>
#import <SndKit/SndView.h>
#import <SndKit/Snd.h>

@interface Controller:NSObject
{
    id	freqNum1;
    id	freqNum2;
    id	freqSlide1;
    id	freqSlide2;
    id	sound1;
    id	sound2;
    id	sound3;
    id	volNum1;
    id	volNum2;
    id	volSlide1;
    id	volSlide2;
    id	waveType1;
    id	waveType2;
    id  mesgBox;
	id  sLength;
	
	Snd * theSound1;
        Snd * theSound2;
        Snd * theSound3;
        Snd * newSound;
        id playsoundA;
        id playsoundB;
	
	float soundLength;
	int type1,type2;
	BOOL somethingChanged;
#ifdef WIN32
        id tempfile;
        id playsound;
#endif
}

- play:sender;
- playA:sender;
- playB:sender;

- updateNums:sender;
- updateSliders:sender;
- waveChanged:sender;
- recalc;
- calcSound1;
- calcSound2;
- calcSound3;
- changeLength:sender;

@end
