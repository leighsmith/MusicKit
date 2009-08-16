#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>
//#import <MKSynthPatches/Pluck.h>

@interface Metronome: NSObject 
{
    id	tempoSlider;
    MKNote *aNote;
    Pluck *pluck;
    MKConductor *cond;
}

- setTempoFromSlider: sender;
- startStop: sender;

@end
