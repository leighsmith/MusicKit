
#import <AppKit/AppKit.h>
#import <SndKit/SndKit.h>

@interface Controller: NSObject
{
    id	freqNum1;
    id	freqNum2;
    id	freqSlide1;
    id	freqSlide2;
    IBOutlet SndView *soundView1;
    IBOutlet SndView *soundView2;
    IBOutlet SndView *soundView3;
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
    
    float soundLength;
    int type1,type2;
    BOOL somethingChanged;
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
