// $Id$

#import "SubSoundView.h"
#import "SpectrumDocument.h"
#import "ScrollingSound.h"
#import <Foundation/NSObject.h>
#import <SndKit/SndView.h>

char *doFloat(float f, int a, int r);

@interface SoundDocument : NSDocument
{
    IBOutlet id soundWindow;
    ScrollingSound *scrollSound;
    IBOutlet id playButton;
    IBOutlet id recordButton;
    IBOutlet id stopButton;
    IBOutlet id pauseButton;
    IBOutlet id spectrumButton;
    IBOutlet id wStartSamp;
    IBOutlet id wStartSec;
    IBOutlet id wDurSamp;
    IBOutlet id wDurSec;
    IBOutlet id sStartSamp;
    IBOutlet id sStartSec;
    IBOutlet id sDurSamp;
    IBOutlet id sDurSec;
    IBOutlet id soundInfo;
    IBOutlet id spectrumDocument;
    NSString *fileName;
    SubSoundView *mySoundView;
    SpectrumDocument *mySpectrumDocument;
    BOOL fresh;
}

- init;
- newSoundLocation:(NSPoint *)p;

/*!
  @method loadDataRepresentation:ofType:
  @discussion Loads a file of the type given by aType from the NSData instance data.
  @result 
*/
- (BOOL) loadDataRepresentation: (NSData *) data ofType: (NSString *) aType;

/*!
  @method dataRepresentationOfType:
  @discussion Writes a file of the type given by aType.
  @result
*/
- (NSData *) dataRepresentationOfType: (NSString *) aType;

- setFileName:(NSString *)aName;
- (NSString *)fileName;
- setWindowTitle;
- sound;
- (double)samplingRate;
- printTimeWindow;
- printSpectrumWindow;
- printWaterfallWindow;
- (float)sampToSec:(int)samples rate: (float)srate;
- saveError:(NSString *)msg arg: (NSString *)arg;
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