#import "SubSoundView.h"
#import "SpectrumDocument.h"
#import "ScrollingSound.h"
#import <Foundation/NSObject.h>
#import <SndKit/SndView.h>

char *doFloat(float f, int a, int r);

@interface SoundDocument:NSObject
{
    id soundWindow;
    ScrollingSound *scrollSound;
    id playButton;
    id recordButton;
    id stopButton;
    id pauseButton;
    id spectrumButton;
    id wStartSamp;
    id wStartSec;
    id wDurSamp;
    id wDurSec;
    id sStartSamp;
    id sStartSec;
    id sDurSamp;
    id sDurSec;
    id soundInfo;
    id stringTable;
    id spectrumDocument;
    NSString *fileName;
    SubSoundView *mySoundView;
    SpectrumDocument *mySpectrumDocument;
    BOOL fresh;
}

- init;
- newSoundLocation:(NSPoint *)p;
- setFileName:(NSString *)aName;
- (NSString *)fileName;
- setWindowTitle;
- sound;
- (double)samplingRate;
- printTimeWindow;
- printSpectrumWindow;
- printWaterfallWindow;
- (float)sampToSec:(int)samples rate: (float)srate;
- saveError:(const char *)msg arg: (const char *)arg;
- saveToFormat:templateSound fileName:(NSString *)fileName;
- save:sender;
- revertToSaved:sender;
- load:sender;
- play:sender;
- (void)stop:(id)sender;
- pause:sender;
- record:sender;
- displayMode:sender;
- showDisplayTimes;
- showSelectionTimes;
- windowMatrixChanged:sender;
- selectionMatrixChanged:sender;
- touch;
- (BOOL)touched;
- setButtons;
- sndInfo:sender;
- spectrum:sender;
- setColors;
- zoom:(float)scale center:(int)sample;
- zoomIn:sender;
- zoomOut:sender;
- zoomSelect:sender;
- zoomAll:sender;
- (BOOL)isRecordable;

@end

@interface SoundDocument(ScrollingSoundDelegate)

- displayChanged:sender;

@end

@interface SoundDocument(SoundViewDelegate)

- didPlay:sender duringPerformance: (SndPerformance *) performance;
- didRecord:sender;
- hadError:sender;
- selectionChanged:sender;
- soundDidChange:sender;

@end

@interface SoundDocument(WindowDelegate)

- (void)windowDidBecomeMain:(NSNotification *)notification;
- (void)windowDidResignMain:(NSNotification *)notification;
- (void)windowDidMiniaturize:(NSNotification *)notification;
- (void)windowDidResize:(NSNotification *)notification;
- (BOOL)windowShouldClose:(id)sender;

@end