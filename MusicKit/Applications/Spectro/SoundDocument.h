/*
  $Id$

  Part of Spectro.app
  Modifications Copyright (c) 2003 The MusicKit Project, All Rights Reserved.

  Legal Statement Covering Additions by The MusicKit Project:

    Permission is granted to use and modify this code for commercial and
    non-commercial purposes so long as the author attribution and copyright
    messages remain intact and accompany all relevant code.

*/
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <AppKit/NSDocument.h> // For some reason GnuStep doesn't include this
#import <SndKit/SndView.h>
#import "SpectrumDocument.h"
#import "ScrollingSound.h"

char *doFloat(float f, int a, int r);

@interface SoundDocument: NSDocument
{
    IBOutlet id soundWindow;
    ScrollingSound *scrollSound;
    IBOutlet NSButton *playButton;
    IBOutlet NSButton *recordButton;
    IBOutlet NSButton *stopButton;
    IBOutlet NSButton *pauseButton;
    IBOutlet NSButton *spectrumButton;
    IBOutlet id wStartSamp;
    IBOutlet id wStartSec;
    IBOutlet id wDurSamp;
    IBOutlet id wDurSec;
    IBOutlet id sStartSamp;
    IBOutlet id sStartSec;
    IBOutlet id sDurSamp;
    IBOutlet id sDurSec;
    IBOutlet id soundInfo;
    // TODO determine difference between these.
    IBOutlet id spectrumDocument;
    SpectrumDocument *mySpectrumDocument;
    NSString *fileName;
    SndView *mySoundView;
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

- setFileName: (NSString *) aName;
- (NSString *) fileName;
- setWindowTitle;

/*!
  @method sound
  @abstract Returns the Snd instance currently being displayed.
 */
- (Snd *) sound;

- (double) samplingRate;
- printTimeWindow;
- printSpectrumWindow;
- printWaterfallWindow;
- (float)sampToSec:(int)samples rate: (float)srate;
- saveError:(NSString *)msg arg: (NSString *)arg;
- saveToFormat:templateSound fileName:(NSString *)fileName;
- (void) save: (id) sender;
- (IBAction) revertToSaved:sender;
- load:sender;
- (IBAction) play:sender;
- (void) stop: (id) sender;
- (IBAction) pause:sender;
- (IBAction) record:sender;
- (IBAction) displayMode:sender;
- showDisplayTimes;
- showSelectionTimes;
- windowMatrixChanged:sender;
- selectionMatrixChanged:sender;
- touch;
- (BOOL) touched;
- setButtons;
- (IBAction) sndInfo:sender;
- (IBAction) spectrum: (id) sender;
- setColors;
- zoom: (float) scale center: (int) sample;
- (IBAction) zoomIn:sender;
- (IBAction) zoomOut:sender;
- (IBAction) zoomSelect:sender;
- (IBAction) zoomAll:sender;
- (BOOL) isRecordable;

@end

@interface SoundDocument(ScrollingSoundDelegate)

- displayChanged: sender;

@end

@interface SoundDocument(SoundViewDelegate)

- didPlay: sender duringPerformance: (SndPerformance *) performance;
- didRecord: sender;
- hadError: sender;
- selectionChanged: sender;
- soundDidChange: sender;

@end

@interface SoundDocument(WindowDelegate)

- (void) windowDidBecomeMain: (NSNotification *) notification;
- (void) windowDidResignMain: (NSNotification *) notification;
- (void) windowDidMiniaturize: (NSNotification *) notification;
- (void) windowDidResize: (NSNotification *) notification;
- (BOOL) windowShouldClose: (id) sender;

@end
