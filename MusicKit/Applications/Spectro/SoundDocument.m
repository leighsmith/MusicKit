/*	$Id$
 *	Originally from SoundEditor3.0.
 *	Modified for Spectro3.0 by Gary Scavone.
 *
 * Modifications Copyright (c) 2003 The MusicKit Project, All Rights Reserved.
 *
 * Legal Statement Covering Additions by The MusicKit Project:
 *
 *   Permission is granted to use and modify this code for commercial and
 *   non-commercial purposes so long as the author attribution and copyright
 *   messages remain intact and accompany all relevant code.
 *
 */

#import <AppKit/AppKit.h>
#import "SoundDocument.h"
#import "SpectroController.h"

#define ZOOM_FACTOR 2.0
#define WAVE_MODE 0
#define OUTLINE_MODE 1
#define PUTVAL(cell,f)	[cell setStringValue: [NSString stringWithFormat: @"%3.3f", f]]

@implementation SoundDocument

- init
{
    self = [super init];
    if(self != nil) {
	NSRect theFrame;

	theSound = nil;
	theFrame = [soundWindow frame];
	[self newSoundLocation: &theFrame.origin];
	soundInfo = [[SoundInfo alloc] init];
	fresh = YES;
    }
    return self;
}

- (void) dealloc
{
    [theSound release];
    theSound = nil;
    [super dealloc];
}

// Override returning the nib file name of the document
// If you need to use a subclass of NSWindowController or if your document supports
// multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
- (NSString *) windowNibName
{
    return @"soundDocument";
}

- newSoundLocation: (NSPoint *) p
{
    int count = [[NSApp delegate] documentCount];
    int cnt = (count > 3)? count - 4 : count;
    
    p->x += (20.0 * count);
    p->y -= (25.0 * cnt);
    count = (count > 6)? 0 : count + 1;
    [[NSApp delegate] setCounter: count];
    return self;
}

- (void) setFileName: (NSString *) aName
{
    [fileName release];
    fileName = [aName copy];
}

- (NSString *) fileName
{
    return fileName;
}

- setWindowTitle
{
    NSString *title;
    
    [soundInfo setSoundHeader: [self sound]];
    if ([soundInfo getChannelCount] == 2)
        title = [fileName stringByAppendingFormat: @" (%i Hz %@, Stereo)", [soundInfo getSrate],
            [soundInfo getSoundFormat]];
    else
        title = [fileName stringByAppendingFormat: @" (%i Hz %@, Mono)", [soundInfo getSrate],
            [soundInfo getSoundFormat]];
    [soundWindow setTitleWithRepresentedFilename: title];
    return self;
}

- (Snd *) sound
{
    return [[theSound retain] autorelease];
}

- (double) samplingRate
{
    Snd *sound = [self sound];
    
    if ((sound == nil) || [sound isEmpty])
	return 0.0;
    else 
	return [sound samplingRate];
}

- printTimeWindow
{
    [soundWindow print:self];
    return self;
}

- printSpectrumWindow
{
    if (mySpectrumDocument)
	[mySpectrumDocument printSpectrum];
    return self;
}

- printWaterfallWindow
{
    if (mySpectrumDocument)
	[mySpectrumDocument printWaterfall];
    return self;
}

- (float) sampToSec: (int) samples rate: (float) srate
{
    if (srate == 0.0) return 0.0;
    return samples / srate;
}

// You can also choose to override -loadFileWrapperRepresentation:ofType:  instead.
- (BOOL) readFromURL: (NSURL *) soundURL ofType: (NSString *) typeName error: (NSError **) outError
{
    theSound = [[Snd alloc] initFromSoundURL: soundURL]; // will retain.
    
    if (theSound) {
	[self setFileName: [soundURL path]]; // kludged for now, can eventually be removed when fileName is no longer used.
	fresh = NO;
	return YES;
    }
    else
	return NO;
}

- (void) windowControllerDidLoadNib: (NSWindowController *) windowController
{
    [soundWindow setDelegate: self];
    // [soundWindow setFrameOrigin: theFrame.origin];
    [soundWindow disableFlushWindow];
    [soundWindow enableFlushWindow];
    [soundWindow flushWindow];
    
    [scrollSound setDelegate: self];
    [scrollSound setSound: theSound];

    [mySpectrumDocument soundChanged]; /*sb */
    [self zoomAll: self];
    [self setButtons];

    mySoundView = [scrollSound soundView];
    if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"DisplayType"] floatValue] < 1.0)
	[mySoundView setDisplayMode: SND_SOUNDVIEW_WAVE];
    else
	[mySoundView setDisplayMode: SND_SOUNDVIEW_MINMAX];
    [mySoundView setDelegate: self];
    [mySoundView setContinuousSelectionUpdates: YES];
    [mySoundView setForegroundColor: [NSColor blueColor]];
}

- saveError:(NSString *)msg arg: (NSString *)arg
{
    NSBundle *mainB = [NSBundle mainBundle];
    
    NSRunAlertPanel([mainB localizedStringForKey:@"Save" value:@"Save" table:nil],
                    [mainB localizedStringForKey:msg value:msg table:nil],
                    [mainB localizedStringForKey:@"OK" value:@"OK" table:nil], nil, nil, arg);
    return nil;
}

// Need to determine the format from the extension.
- (BOOL) writeToURL: (NSURL *) absoluteURL ofType: (NSString *) typeName error: (NSError **) outError
{
    NSLog(@"writeToURL %@ of type: %@\n", absoluteURL, typeName);
    
#if 0
    if (templateSound && theSound) {
	err = [theSound convertToSampleFormat: [templateSound dataFormat]
				 samplingRate: [templateSound samplingRate]
				 channelCount: [templateSound channelCount]];
	if (err) {
	    /* The DSP is required for compression or decompression */
	    // TODO assign outError
	    [self saveError: @"Cannot do format conversion %@ (DSP busy?)" arg: @""];
	    return NO;
	}
    }
#endif
    
    return ![theSound writeSoundfile: [absoluteURL path]];
}

#if 0
- (IBAction) revertToSaved: (id) sender
{
    NSBundle *mainB = [NSBundle mainBundle];
    if([soundWindow isDocumentEdited] && fileName
       && ![[fileName lastPathComponent] isEqualToString:@"/UNTITLED"]) {
        if (NSRunAlertPanel(
			    [mainB localizedStringForKey:@"Revert" value:@"Revert" table:nil],
			    [mainB localizedStringForKey:@"Revert to saved version of %@?"
						   value:@"Revert to saved version of %@?" table:nil],
			    [mainB localizedStringForKey:@"Revert" value:@"Revert" table:nil],
			    [mainB localizedStringForKey:@"Cancel" value:@"Cancel" table:nil],
			    nil, fileName) == NSAlertDefaultReturn)
            // [self load:nil];
	    ;
    }
}
#endif

- (IBAction) play: sender
{
    if (![theSound isPlayable]) {
	NSBeep();
	return;
    }
    [playButton setEnabled: NO];
    [recordButton setEnabled: NO];
    [stopButton setEnabled: YES];
    [pauseButton setState: 0];
    [theSound play: sender];
}

- (IBAction) stop: (id) sender
{
    [theSound stop: sender];
    [playButton setState: 0];
    [playButton setEnabled: YES];
    [recordButton setState: 0];
    [recordButton setEnabled: ([self isRecordable]? YES : NO)];
    [pauseButton setState: 0];
}

- (IBAction) pause: sender
{
    if (![playButton state] && ![recordButton state]) {
	[pauseButton setState: 0];
	return;
    } 
    else if ([pauseButton state])
	[theSound pause: sender];
    else
	[theSound resume: sender];
}

- (IBAction) record: sender
{
    [recordButton setEnabled: NO];
    [playButton setEnabled: NO];
    [stopButton setEnabled: YES];
    [theSound record: sender];
    [soundWindow setDocumentEdited: YES];
}

- (IBAction) displayMode: sender
{
    if ([[sender selectedCell] tag] == OUTLINE_MODE)
	[mySoundView setDisplayMode: SND_SOUNDVIEW_MINMAX];
    else 
	[mySoundView setDisplayMode: SND_SOUNDVIEW_WAVE];	
}

- showDisplayTimes
{
    int start, size;
    float srate;
    
    /* Get the times from the ScrollingSound and show
	* them in the appropriate Forms
	*/
    srate = [self samplingRate];
    [scrollSound getWindowSamples: &start Size: &size];
    [wStartSamp setIntValue:start];
    PUTVAL(wStartSec, [self sampToSec: start rate: srate]);
    [wDurSamp setIntValue: size];
    PUTVAL(wDurSec, [self sampToSec: size rate: srate]);
    return self;
}

- showSelectionTimes
{
    unsigned int start;
    unsigned int size;
    float srate;
    
    /* Get the selection samples and stuff 'em into the selection display */
    
    srate = [self samplingRate];
    [mySoundView getSelection: &start size: &size];
    [sStartSamp setIntValue: start];
    PUTVAL(sStartSec, [self sampToSec: start rate: srate]);
    if (size > ([theSound lengthInSampleFrames] - start))
	return self;
    [sDurSamp setIntValue: size];
    PUTVAL(sDurSec, [self sampToSec: size rate: srate]);
    return self;
}

- windowMatrixChanged: sender
{
    id cell;
    int start, size, dur;
    float rate;
    BOOL startChanged, sizeChanged;
    
    cell = [sender selectedCell];
    start = [wStartSamp intValue];
    size = [wDurSamp intValue];
    dur = [theSound lengthInSampleFrames];
    rate = [self samplingRate];
    startChanged = sizeChanged = NO;
    switch ([cell tag]) {
	case 0:	start = [cell intValue];
	    startChanged = YES;
	    break;
	case 1:	start = (int) ([cell floatValue] * rate);
	    startChanged = YES;
	    break;
	case 2:	size = [cell intValue];
	    sizeChanged = YES;
	    break;
	case 3:	size = (int) ([cell floatValue] * rate);
	    sizeChanged = YES;
	    break;
	default: ;
    }
    
    if (size <= 0 || start < 0) {		/* erase and ignore bad values */
	[self showDisplayTimes];
	return self;
    }
    if (startChanged) {
	if (start > dur - size)
	    size = dur - start;
	[scrollSound setWindowSize: size];
	[scrollSound setWindowStart: start];
    }
    if (sizeChanged) {
	if (size > dur) size = dur;
	if (start > dur - size)
	    start = dur - size;
	[scrollSound setWindowSize: size];
	[scrollSound setWindowStart: start];
    }
    [self showDisplayTimes];
    return self;
}

- selectionMatrixChanged: sender
{
    id cell;
    int start, size, end, dur;		/* Start/size/end of selection */
    int	vstart, vsize, vend;	/* Start/size/end of view */
    float rate;
    
    cell = [sender selectedCell];
    start = [sStartSamp intValue];
    size = [sDurSamp intValue];
    dur = [theSound lengthInSampleFrames];
    rate = [self samplingRate];
    switch ([cell tag]) {
	case 0:	start = [cell intValue];
	    break;
	case 1: start = (int)([cell floatValue] * rate);
	    break;
	case 2: size = [cell intValue];
	    break;
	case 3: size = (int)([cell floatValue] * rate);
	    break;
	default: ;
    }
    end = start + size;
    vstart = [wStartSamp intValue];
    vsize = [wDurSamp intValue];
    vend = vstart + vsize;
    
    if (start < 0 || size < 0) {				/* Ignore negative values */
	[self showSelectionTimes];
	return self;
    }
    if (end > dur) end = dur;		/* Can't select past EOF */
    if (start > end) start = end;
    size = end-start;
    [mySoundView setSelection: start size:size];

    /* If the new start time is outside the current view, scroll the view
    * so that the new start is in the center.  If the whole selection
    * will fit in the view, center the selection instead.
    */
    if (start < vstart  ||  start > vend) {
	if (size <= vsize)
	    vstart = start + size/2 - vsize/2;
	else
	    vstart = start - vsize/2;
	if (vstart < 0)
	    vstart = 0;
	[scrollSound setWindowStart: vstart];
    }

    /* If the new end time is outside the current view, scroll the view
    * so that the new end is in the center.
    */
    if (end < vstart  ||  end > vend) {
	if (size <= vsize)
	    vstart = start + size/2 - vsize/2;
	else
	    vstart = end - vsize/2;
	if (vstart < 0)
	    vstart = 0;
	[scrollSound setWindowStart: vstart];
    }
    return self;
}

- touch
{
    [self updateChangeCount: NSChangeDone];        // Indicate the sound document has been changed.
    return self;
}

- setButtons
{
    [recordButton setEnabled: ([self isRecordable] ? YES : NO)];
    [playButton setEnabled: YES];
    return self;
}

- (IBAction) sndInfo: (id) sender
{
    NSString *title;
    
    if ([theSound isEmpty])
	return;
    title = [[self fileName] lastPathComponent];
    [soundInfo displaySound: theSound title: title];
}

- (IBAction) spectrum: (id) sender
{	
    if ([theSound isEmpty]) 
	return;
    if (mySpectrumDocument == nil) {
	mySpectrumDocument = [[SpectrumDocument alloc] init];
	[mySpectrumDocument setDelegate: self];
	[mySpectrumDocument setSoundView: mySoundView];
	[mySpectrumDocument setWindowTitle: [self fileName]];
    }
    [mySpectrumDocument spectroButtonDepressed];
    [spectrumButton setState: 0];
}

- setColors
{
    [mySpectrumDocument setViewColors];
    return self;
}

- zoom: (float) scale center: (int) sample
{
    if ([theSound isEmpty])
	return self;
    [scrollSound setReductionFactor: scale];
    [scrollSound centerAt: sample];
    return self;	
}

- (IBAction) zoomIn: sender
{
    [self zoom: ([scrollSound reductionFactor] / ZOOM_FACTOR)
	center: [scrollSound centerSample]];
}

- (IBAction) zoomOut:sender
{
    NSRect aRect;
    float maxRFactor;
    float scale = ([scrollSound reductionFactor] * ZOOM_FACTOR);
    
    if (NSIsEmptyRect(aRect = [scrollSound documentVisibleRect])) 
	return;
    maxRFactor = [theSound lengthInSampleFrames] / aRect.size.width;
    if (scale > maxRFactor)
	[self zoomAll: sender];
    else
	[self zoom: scale center: [scrollSound centerSample]];
}

- (IBAction) zoomSelect:sender
{
    [scrollSound sizeToSelection:sender];
}

- (IBAction) zoomAll: sender
{
    NSSize size;
    int count;
    float width;
    
    size = [scrollSound contentSize];
    width = size.width;
    count = [theSound lengthInSampleFrames];
    [self zoom: (((float) count) / width) center: (count / 2)];
}

- (BOOL) isRecordable
{
    SndSampleFormat format;
    
    if (!theSound) 
	return YES;
    format = [theSound dataFormat];
    if (format == SND_FORMAT_MULAW_8 &&
	[theSound samplingRate] == (int) SND_RATE_CODEC &&
	[theSound channelCount] == 1 )
	return YES;
    else
	return NO;
}

@end

@implementation SoundDocument(ScrollingSoundDelegate)

- displayChanged:sender
{
    [self showDisplayTimes];
    return self;
}

@end

@implementation SoundDocument(SoundViewDelegate)

- didPlay: sender;
{
    [playButton setState: 0];
    [playButton setEnabled: YES];
    [recordButton setState: 0];
    [recordButton setEnabled: ([self isRecordable] ? YES : NO)];
    [pauseButton setState: 0];
    return self;
}

- didPlay: sender duringPerformance: (SndPerformance *) performance;
{
    return [self didPlay: sender];
}

- didRecord:sender
{
    [playButton setState: 0];
    [playButton setEnabled: YES];
    [recordButton setState: 0];
    [recordButton setEnabled: YES];
    [pauseButton setState: 0];
    return self;
}

- hadError: sender
{
    int err = [[sender soundBeingProcessed] processingError];
    NSBundle *mainB = [NSBundle mainBundle];
    if ([playButton state]) 
        NSRunAlertPanel(
			[mainB localizedStringForKey: @"Play error" value: @"Play error" table: nil],
			[mainB localizedStringForKey: SndSoundError(err) value: SndSoundError(err) table: nil],
			[mainB localizedStringForKey: @"OK" value: @"OK" table: nil],
			nil, nil);
    else if ([recordButton state])
        NSRunAlertPanel(
			[mainB localizedStringForKey: @"Record error" value: @"Record error" table: nil],
			[mainB localizedStringForKey: SndSoundError(err) value: SndSoundError(err) table: nil],
			[mainB localizedStringForKey: @"OK" value: @"OK" table: nil],
			nil, nil);
    [self stop: self];
    return self;
}

- selectionChanged: sender
{	
    if (fresh) { /* covers copy-new-paste situation */
	fresh = NO; /* must do first to avoid infinite recursion */
	[self zoomAll: self];
    }
    [self showSelectionTimes];
    [mySpectrumDocument disableWFSlider];
    [mySpectrumDocument setTotalFrames];
    return self;
}

- soundDidChange:sender
{
    [self touch];
    [[self sound] compactSamples];
    [mySpectrumDocument soundChanged];
    return self;
}

@end

@implementation SoundDocument(WindowDelegate)

- (void)windowDidBecomeMain: (NSNotification *) notification
{
    [(SpectroController *)[NSApp delegate] setDocument: self];
    [soundWindow makeFirstResponder: mySoundView];
    [mySoundView showCursor];
}

- (void) windowDidResignMain: (NSNotification *) notification
{
    SpectroController *theController = [NSApp delegate];
    if ([theController document] == self)
        [theController setDocument: nil];
    [mySoundView hideCursor];
}

- (void) windowDidMiniaturize: (NSNotification *) notification
{
    NSWindow *theWindow = [notification object];
    
    [mySoundView stop: theWindow];
    [mySoundView hideCursor];
    [soundWindow setMiniwindowImage: [NSImage imageNamed: @"Spectro.tiff"]];
}

- (void) windowDidResize: (NSNotification *) notification
{
    double width;
    NSRect tempRect;
    
    tempRect = [mySoundView bounds];
    width = tempRect.size.width;
    tempRect = [scrollSound documentVisibleRect];
    if (width < tempRect.size.width)
	[self zoomAll: self];
}

- (BOOL) windowShouldClose: (id) sender
{
    int choice;
    NSBundle *mainB = [NSBundle mainBundle];
    
    if ([soundWindow isDocumentEdited]) {
	choice = NSRunAlertPanel(
				 [mainB localizedStringForKey:@"Close" value:@"Close" table:nil],
				 [mainB localizedStringForKey:@"Sound is modified.\nSave it?"
							value:@"Sound is modified.\nSave it?" table:nil],
				 [mainB localizedStringForKey:@"Yes" value:@"Yes" table:nil],
				 [mainB localizedStringForKey:@"No" value:@"No" table:nil],
				 [mainB localizedStringForKey:@"Cancel" value:@"Cancel" table:nil]); 
	switch (choice) {
	    case NSAlertAlternateReturn:
		break;
	    case NSAlertDefaultReturn:
		[[NSApp delegate] save:nil];
		break;
	    case NSAlertOtherReturn:
		return NO;
	}
    }
    [soundWindow setDelegate: nil];
    [mySpectrumDocument closeWindows];
    [mySpectrumDocument release];
    [self release];
    return YES;
}

@end
