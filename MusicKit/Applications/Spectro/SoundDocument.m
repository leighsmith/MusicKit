/*	SoundDocument.m
 *	Originally from SoundEditor3.0.
 *	Modified for Spectro3.0 by Gary Scavone.
 *	Last modified: 1/94
 */


#import "SoundDocument.h"
#import "SoundController.h"
#import "SubSoundView.h"
#import "ScrollingSound.h"
#import "SoundInfo.h"
#import "SpectrumDocument.h"

#import <AppKit/AppKit.h>

#import <stdlib.h>
#import <string.h>

#define ZOOM_FACTOR 2.0
#define WAVE_MODE 0
#define OUTLINE_MODE 1
#define PUTVAL(cell,f)	[cell setStringValue:[NSString stringWithCString:doFloat(f, 3, 3)]]

extern int access();

char *doFloat(float f, int x, int y)	/* Trims float values */
{
	static char s[32];

	sprintf(s,"%*.*f", x, y, f);
	return s;
}

static int calcFormat(SndSoundStruct *s)
{
    if (s->dataFormat == SND_FORMAT_MULAW_8)
		return SND_FORMAT_MULAW_8;
    else if (s->dataFormat == SND_FORMAT_INDIRECT) {
		SndSoundStruct **iBlock = (SndSoundStruct **)s->dataLocation;

	if (*iBlock)
	    return (*iBlock)->dataFormat;
	else
	    return SND_FORMAT_UNSPECIFIED;
    } else
	return s->dataFormat;
}

@implementation SoundDocument

- init
{
    NSRect theFrame;
	
    [super init];
    [NSBundle loadNibNamed:@"soundDocument.nib" owner:self];
    [soundWindow setDelegate:self];
    theFrame = [soundWindow frame];
    [self newSoundLocation:&theFrame.origin];
    [soundWindow setFrameOrigin:NSMakePoint(theFrame.origin.x, theFrame.origin.y)];
//    [soundWindow makeKeyAndOrderFront:nil];
    [scrollSound setDelegate:self];
    mySoundView = [scrollSound soundView];
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"DisplayType"] floatValue] < 1.0)
        [mySoundView setDisplayMode:NX_SOUNDVIEW_WAVE];
    else
        [mySoundView setDisplayMode:NX_SOUNDVIEW_MINMAX];
    [mySoundView setDelegate:self];
    [mySoundView setContinuous:YES];
    soundInfo = [[SoundInfo alloc] init];
    fresh = YES;
    return self;
}

- newSoundLocation:(NSPoint *)p
{
    int count = [[NSApp delegate] documentCount];
	
	int cnt = (count > 3)? count - 4 : count;
    p->x += (20.0 * count);
    p->y -= (25.0 * cnt);
    count = (count > 6)? 0 : count+1;
	[[NSApp delegate] setCounter:count];
	return self;
}

- setFileName:(NSString *)aName
{
    [fileName release];
    fileName = [aName copy];
    return self;
}

- (NSString *)fileName
{
    return fileName;
}

- setWindowTitle
{
    NSString *title;
	
    [soundInfo setSoundHeader:[self sound]];
    if ([soundInfo getChannelCount] == 2)
        title = [fileName stringByAppendingFormat:@" (%i Hz %@, Stereo)",[soundInfo getSrate],
            [soundInfo getSoundFormat]];
    else
        title = [fileName stringByAppendingFormat:@" (%i Hz %@, Mono)",[soundInfo getSrate],
            [soundInfo getSoundFormat]];
    [soundWindow setTitleWithRepresentedFilename:title];
    return self;
}

- sound
{
    return [mySoundView sound];
}

- (double)samplingRate
{
	id sound;
	if (((sound = [self sound]) == nil) || [sound isEmpty])
		return 0.0;
	else return [sound samplingRate];
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

- (float)sampToSec:(int)samples rate: (float)srate
{
	if (srate == 0.0) return 0.0;
	return samples / srate;
}

- saveError:(const char *)msg arg: (const char *)arg
{
    if (!stringTable)
        stringTable = [[NSApp delegate] stringTable];
    NSRunAlertPanel([NSString stringWithCString:[stringTable valueForStringKey:"Save"]],
                    [NSString stringWithCString:[stringTable valueForStringKey:msg]],
                    [NSString stringWithCString:[stringTable valueForStringKey:"OK"]], nil, nil, arg);
    return nil;
}

- saveToFormat:templateSound fileName:(NSString *)fn
{
    if (fn) if ([fn length]) {
	int err;
	id theSound = [[mySoundView sound] copy];
	if (templateSound && theSound) {
	    [theSound copySound:theSound];
	    err = [theSound convertToFormat:[templateSound dataFormat]
			    samplingRate:[templateSound samplingRate]
			    channelCount:[templateSound channelCount]];
	    if (err) {
		/* The DSP is required for compression or decompression */
		return [self saveError: 
			"Cannot do format conversion %s (DSP busy?)" arg:""];
	    }
	}
        if ([[NSFileManager defaultManager] fileExistsAtPath:fn])
            [[NSFileManager defaultManager] movePath:fn toPath:[fn stringByAppendingString:@"~"] handler:nil];

        err = [theSound writeSoundfile:fn];
	if (err) {
	    return [self saveError:"Cannot write %s" arg:[fn cString]];
	}
	else 
	  [soundWindow setDocumentEdited:NO];
	[theSound release];
    }
    return self;
}

- save:sender
{
    return [self saveToFormat:nil fileName:fileName];
}

- revertToSaved:sender
{
    if([soundWindow isDocumentEdited] && fileName
       && ![[fileName lastPathComponent] isEqualToString:@"/UNTITLED"]) {
        if (!stringTable)
            stringTable = [[NSApp delegate] stringTable];
		if (NSRunAlertPanel([NSString stringWithCString:[stringTable valueForStringKey:"Revert"]],
                      [NSString stringWithCString:[stringTable valueForStringKey:"Revert to saved version of %@?"]],
                      [NSString stringWithCString:[stringTable valueForStringKey:"Revert"]],
                      [NSString stringWithCString:[stringTable valueForStringKey:"Cancel"]], nil, fileName)
      == NSAlertDefaultReturn)
			[self load:nil];
    }
    return self;
}

- load:sender
{	
    if (fileName) {
        id newSound = [[Snd alloc] initFromSoundfile:fileName];
        if (newSound) {
            [soundWindow disableFlushWindow];
            [scrollSound setSound:newSound];
#if 0 /*sb: can't determine displayability this way. Find some other way one day... */
            if (![scrollSound setSound:newSound]) { /* not displayable */
                if ([newSound convertToFormat:SND_FORMAT_LINEAR_16]) {
                    if (!stringTable) stringTable = [[NSApp delegate] stringTable];
                    NSRunAlertPanel([NSString stringWithCString:[stringTable valueForStringKey:"Open"]],
                                    [NSString stringWithCString:[stringTable valueForStringKey:
                                        "Cannot convert format for display "
						"(DSP busy?)"]],
                                    [NSString stringWithCString:[stringTable valueForStringKey:"OK"]], nil, nil);
                    return nil;
                } else
                    [scrollSound setSound:newSound];
            }
#endif
            [mySpectrumDocument soundChanged]; /*sb */
            [soundWindow enableFlushWindow];
            [self zoomAll:self];
            [soundWindow flushWindow];
        }
    }
    [soundWindow setDocumentEdited:NO];
    [self setWindowTitle];
    fresh = NO;
    [soundWindow makeKeyAndOrderFront:self];   /*sb: do this now, as new windows
    						* have not yet been displayed	  */
    return self;
}

- play:sender
{
	if (![mySoundView isPlayable]) {
		NSBeep();
		return nil;
	}
	[playButton setEnabled:NO];
	[recordButton setEnabled:NO];
	[stopButton setEnabled:YES];
	[pauseButton setState:0];
    [mySoundView play:sender];
    return self;
}

- (void)stop:(id)sender
{
	[mySoundView stop:sender];
	[playButton setState:0];
	[playButton setEnabled:YES];
	[recordButton setState:0];
	[recordButton setEnabled:([self isRecordable]? YES : NO)];
	[pauseButton setState:0];
}

- pause:sender
{
    if (![playButton state] && ![recordButton state]) {
		[pauseButton setState:0];
		return self;
    } else if ([pauseButton state])
		[mySoundView pause:sender];
    else
		[mySoundView resume:sender];
    return self;
}

- record:sender
{
	[recordButton setEnabled:NO];
	[playButton setEnabled:NO];
	[stopButton setEnabled:YES];
    [mySoundView record:sender];
    [soundWindow setDocumentEdited:YES];
    return self;
}

- displayMode:sender
{
	if ([[sender selectedCell] tag] == OUTLINE_MODE)
		[mySoundView setDisplayMode:NX_SOUNDVIEW_MINMAX];
	else [mySoundView setDisplayMode:NX_SOUNDVIEW_WAVE];	
	return self;
}

- showDisplayTimes
{
	int start, size;
	float srate;
	
/* Get the times from the ScrollingSound and show
 * them in the appropriate Forms
 */
	srate = [self samplingRate];
	[scrollSound getWindowSamples:&start Size:&size];
	[wStartSamp setIntValue:start];
	PUTVAL(wStartSec,[self sampToSec:start rate:srate]);
	[wDurSamp setIntValue:size];
	PUTVAL(wDurSec,[self sampToSec:size rate:srate]);
    return self;
}

- showSelectionTimes
{
	int start, size;
	float srate;

/* Get the selection samples and stuff 'em into the selection display */

	srate = [self samplingRate];
	[mySoundView getSelection:&start size:&size];
	[sStartSamp setIntValue:start];
	PUTVAL(sStartSec,[self sampToSec:start rate:srate]);
	if (size > ([[mySoundView sound] sampleCount] - start))
		return self;
	[sDurSamp setIntValue:size];
	PUTVAL(sDurSec,[self sampToSec:size rate:srate]);
	return self;
}

- windowMatrixChanged:sender
{
	id cell;
	int start, size, dur;
	float rate;
	BOOL startChanged, sizeChanged;

	cell = [sender selectedCell];
	start = [wStartSamp intValue];
	size = [wDurSamp intValue];
	dur = [[mySoundView sound] sampleCount];
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
		[scrollSound setWindowSize:size];
		[scrollSound setWindowStart:start];
	}
	if (sizeChanged) {
		if (size > dur) size = dur;
		if (start > dur - size)
			start = dur - size;
		[scrollSound setWindowSize:size];
		[scrollSound setWindowStart:start];
	}
	[self showDisplayTimes];
	return self;
}

- selectionMatrixChanged:sender
{
	id cell;
	int start, size, end, dur;		/* Start/size/end of selection */
	int	vstart, vsize, vend;	/* Start/size/end of view */
	float rate;
	
	cell = [sender selectedCell];
	start = [sStartSamp intValue];
	size = [sDurSamp intValue];
	dur = [[mySoundView sound] sampleCount];
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
	[mySoundView setSelection:start size:size];

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
		[scrollSound setWindowStart:vstart];
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
		[scrollSound setWindowStart:vstart];
	}
	return self;
}

- touch
{
    [soundWindow setDocumentEdited:YES];
    return self;
}

- (BOOL)touched
{
	return [soundWindow isDocumentEdited];
}

- setButtons
{
	[recordButton setEnabled:([self isRecordable]? YES : NO)];
    [playButton setEnabled:YES];
	return self;
}

- sndInfo:sender
{
	NSString *title;
	
	if ([[mySoundView sound] isEmpty]) return self;
        title = [[self fileName] lastPathComponent];
	[soundInfo displaySound:[self sound] title:title];
	return self;
}

- spectrum:sender
{	
	if ([[mySoundView sound] isEmpty]) return self;
	if (mySpectrumDocument == nil) {
		mySpectrumDocument = [[SpectrumDocument alloc] init];
		[mySpectrumDocument setDelegate:self];
		[mySpectrumDocument setSoundView:mySoundView];
		[mySpectrumDocument setWindowTitle:[self fileName]];
	}
	[mySpectrumDocument spectroButtonDepressed];
	[spectrumButton setState:0];
	return self;
}

- setColors
{
	[mySpectrumDocument setViewColors];
	return self;
}

- zoom:(float)scale center:(int)sample
{
	if ([[mySoundView sound] isEmpty]) return self;
	[scrollSound setReductionFactor:scale];
	[scrollSound centerAt:sample];
	return self;	
}

- zoomIn:sender
{
	[self zoom:([scrollSound reductionFactor] / ZOOM_FACTOR)
	      center:[scrollSound centerSample]];
	return self;
}

- zoomOut:sender
{
	NSRect aRect;
	float maxRFactor;
	float scale = ([scrollSound reductionFactor] * ZOOM_FACTOR);

	if (NSIsEmptyRect(aRect = [scrollSound documentVisibleRect])) return self;
	maxRFactor = [[mySoundView sound] sampleCount] / aRect.size.width;
	if (scale > maxRFactor) [self zoomAll:sender];
	else [self zoom:scale center:[scrollSound centerSample]];
	return self;
}

- zoomSelect:sender
{
	[scrollSound sizeToSelection:sender];
	return self;
}

- zoomAll:sender
{
	NSSize size;
	int count;
	float width;
	
	size = [scrollSound contentSize];
	width = size.width;
	count = [[mySoundView sound] sampleCount];
	[self zoom:(((float) count) / width) center:(count / 2)];
	return self;
}

- (BOOL)isRecordable
{
    int format;
    id theSound = [mySoundView sound];
    SndSoundStruct *soundStruct = [theSound soundStruct];

    if (!soundStruct) return YES;
    format = calcFormat(soundStruct);
    if (format == SND_FORMAT_MULAW_8 &&
    		soundStruct->samplingRate == (int)SND_RATE_CODEC &&
			soundStruct->channelCount == 1 )
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

- didPlay: sender duringPerformance: (SndPerformance *) performance;
{
    [playButton setState:0];
    [playButton setEnabled:YES];
    [recordButton setState:0];
    [recordButton setEnabled:([self isRecordable]? YES : NO)];
    [pauseButton setState:0];
    return self;
}

- didRecord:sender
{
	[playButton setState:0];
	[playButton setEnabled:YES];
	[recordButton setState:0];
	[recordButton setEnabled:YES];
	[pauseButton setState:0];
	return self;
}

- hadError:sender
{
    int err = [[sender soundBeingProcessed] processingError];
	if (!stringTable)
		stringTable = [[NSApp delegate] stringTable];
    if ([playButton state]) 
		NSRunAlertPanel(
                  [NSString stringWithCString:[stringTable valueForStringKey:"Play error"]],
                  [NSString stringWithCString:SndSoundError(err)],
                  [NSString stringWithCString:[stringTable valueForStringKey:"OK"]], nil, nil);
    else if ([recordButton state])
		NSRunAlertPanel(
                  [NSString stringWithCString:[stringTable valueForStringKey:"Record error"]],
                  [NSString stringWithCString:SndSoundError(err)],
                  [NSString stringWithCString:[stringTable valueForStringKey:"OK"]], nil, nil);
    [self stop:self];
    return self;
}

- selectionChanged:sender
{	
	if (fresh) { /* covers copy-new-paste situation */
		fresh = NO; /* must do first to avoid infinite recursion */
		[self zoomAll:self];
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

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    [(SoundController *)[NSApp delegate] setDocument:self];
    [soundWindow makeFirstResponder:mySoundView];
    [mySoundView showCursor];
}

- (void)windowDidResignMain:(NSNotification *)notification
{
    SoundController *theController = [NSApp delegate];
    if ([theController document] == self)
        [theController setDocument:nil];
    [mySoundView hideCursor];
}

- (void)windowDidMiniaturize:(NSNotification *)notification
{
    NSWindow *theWindow = [notification object];
    [mySoundView stop:theWindow];
    [mySoundView hideCursor];
    [soundWindow setMiniwindowImage:[NSImage imageNamed:@"Spectro.tiff"]];
}

- (void)windowDidResize:(NSNotification *)notification
{
    double width;
	NSRect tempRect;
	
	tempRect = [mySoundView bounds];
	width = tempRect.size.width;
	tempRect = [scrollSound documentVisibleRect];
	if (width < tempRect.size.width)
		[self zoomAll:self];
}

- (BOOL)windowShouldClose:(id)sender
{
	int choice;

	if ([soundWindow isDocumentEdited]) {
		if (!stringTable)
			stringTable = [[NSApp delegate] stringTable];
		choice = NSRunAlertPanel([NSString stringWithCString:[stringTable valueForStringKey:"Close"]],
                           [NSString stringWithCString:[stringTable valueForStringKey:"Sound is modified.\nSave it?"]],
                           [NSString stringWithCString:[stringTable valueForStringKey:"Yes"]],
                           [NSString stringWithCString:[stringTable valueForStringKey:"No"]],
                           [NSString stringWithCString:[stringTable valueForStringKey:"Cancel"]]); 
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
	[[NSApp delegate] closeDoc:self];
//#warning This delegate message has changed to a notification.  If you are trying to simulate the sending of the delegate message, you may want to instead post a notification via [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidResignMainNotification object:nil]
    [self windowDidResignMain:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidResignMainNotification object:self];
    [soundWindow setDelegate:nil];
	[mySpectrumDocument closeWindows];
	[mySpectrumDocument release];
    [self release];
    return YES;
}

@end