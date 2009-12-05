// $Id$

#import <AppKit/AppKit.h>
#import <SndKit/SndKit.h>

@interface Controller: NSObject
{
    IBOutlet NSTextField *freqNum1;
    IBOutlet NSTextField *freqNum2;
    IBOutlet NSSlider *freqSlide1;
    IBOutlet NSSlider *freqSlide2;
    IBOutlet SndView *soundView1;
    IBOutlet SndView *soundView2;
    IBOutlet SndView *soundView3;
    IBOutlet NSTextField *volNum1;
    IBOutlet NSTextField *volNum2;
    IBOutlet NSSlider *volSlide1;
    IBOutlet NSSlider *volSlide2;
    IBOutlet NSMatrix *waveType1;
    IBOutlet NSMatrix *waveType2;
    IBOutlet NSTextView *mesgBox;
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
