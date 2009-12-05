/* SoundDocument.m -- Implementation for SoundDocument object.
 *
 * Original code by Lee Boynton
 * Revision by James Pritchett, 10/89
 * Version 1.01, 11/89
 * Version 1.2, 1/90
 * Version 1.3, 2/90
 *	-- Added display of sampling rate, data format, channel count
 */

#import "EdsndApp.h"
#import "SoundDocument.h"
#import "ScrollingSound.h"

#import <soundkit/soundkit.h>
#import <appkit/Application.h>
#import <appkit/Panel.h>
#import <appkit/OpenPanel.h>
#import <appkit/Cursor.h>
#import <appkit/Form.h>
#import <appkit/ClipView.h>
#import <appkit/Button.h>
#import <stdlib.h>
#import <string.h>

/* Macros for getting/putting float values from/to Forms
 */
#define GETVAL(form) 	[form floatValueAt:0]
#define PUTVAL(form,f)	[form setStringValue:dofloat(f) at:0]



static int opendocs = 0;	/* Number of currently open documents */


/* C FUNCTIONS NEEDED BY SoundDocument METHODS:
 *
 * dofloat() -- this function trims all float numbers to 3 decimal places.
 * 	It is used by any routine that does a 'setFloatValue:at:' on
 *	a Form, so as to keep the numbers tidier.
 */

char *dofloat(f)
float f;
{
	static char s[32];

	sprintf(s,"%8.3f",f);
	return s;
}

/* newLocation() -- keeps track of where next window should be opened
 */
static newLocation(NXPoint *p)
{
    static count = 0;
    p->x += (20.0 * count);		/* 20 pixels right */
    p->y -= (25.0 * count);		/* 25 pixels down */
    count = (count > 10)? 0 : count+1;	/* after 10 opens, return to start */
}


/* getSavePath() -- Get a pathname for save command
 */
static BOOL getSavePath(char *buf, char const *defaultPath)
{
    static id	savePanel = nil;
    BOOL	ok;
    char const *fileTypes[2] = {0,0};
    char	dirName[1024], fileName[256];

/* Make the savePanel if we haven't already done it
 */
    if (!savePanel) {
	[NXWait set];		/* Cursor to 'wait' form */
	NXPing();
        savePanel = [SavePanel new];
	[NXArrow set];		/* Back to 'arrow' form */
	NXPing();
    }
    [NXApp setAutoupdate:NO];
    if (defaultPath && *defaultPath) {
	char *p;
	strcpy(dirName,defaultPath);
	if (p = rindex(dirName,'/')) {
	    strcpy(fileName, p+1);
	    *p = '\0';
	} else {
	    strcpy(fileName,defaultPath);
	    fileName[0] = '\0';
	}
	ok = [savePanel runModalForDirectory:dirName file:fileName];
    } else 
	ok = [savePanel runModal];
    [NXApp setAutoupdate:YES];
    if (ok) {
	strcpy(buf,[savePanel filename]);
	return YES;
    } else 
	return NO;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

@implementation SoundDocument

/* new -- factory method
 */
+ new
{
    opendocs++;
    self = [super new];
    isempty = YES;
    [NXApp loadNibSection:"snddoc.nib" owner:self];
    [self displayChanged:self];		/* Force display in forms */
    [NXApp isOpenDocument:YES];
    [NXApp isOpenSound:NO];
    [NXApp isOpenFile:NO];
    return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setFileName: -- set the filename variable to this soundfile's name.
 */
- setFileName:(char *)aName
{
    if (fileName)		/* free old space first */
	free(fileName);
    fileName = (char *)malloc(strlen(aName)+1);
    strcpy(fileName,aName);
    [window setTitle:fileName];	/* set the window title */
    [NXApp isOpenFile:YES];
    return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* saveAs: -- Save Sound under an assumed name
 */
- saveAs:sender
{
    char pathname[1024];
    
    if (getSavePath(pathname,fileName)) {
	[self setFileName:pathname];
	[self save:sender];
	[NXApp isOpenFile:YES];
    }
    return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* save: -- Save the sound into a soundfile.
 */
- save:sender
{
	int err;
	id theSound = [view sound];	/* pointer to the Sound object */

 	if (fileName == NULL)
	    [self saveAs:sender];	/* Get a name if needed */
	else if (theSound) {
	    [NXWait set];
	    NXPing();
	    if ([theSound needsCompacting]) 
    		[theSound compactSamples];	/* Do this if necessary */
	    err = [theSound writeSoundfile:fileName];
	    [NXArrow set];
	    NXPing();

/* If we had any errors, then run an Alert panel; otherwise, mark
 * this file as untouched.
 */
	    if (err)
		NXRunAlertPanel("Save","Cannot write %s","OK",NULL,
							NULL,fileName);
	    else
	    	[window setDocEdited:NO];
	}
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* load: -- Load a soundfile into the EdSoundView
 */
- load:sender
{
	id newSound;

    if (fileName) {
	[NXWait set];
	NXPing();

/* Create a new Sound object from this soundfile and give it to
 * the ScrollingSound.
 */
	newSound = [Sound newFromSoundfile:fileName];
	if (newSound)
	    [scroller setSound:newSound];
	[NXArrow set];
	NXPing();
	[self showDisplayTimes];
	[self showSelectionTimes];
	[self showFormat:newSound];

	if ([scroller duration] != 0)
		[NXApp isOpenSound:YES];
	else
		[NXApp isOpenSound:NO];
    }
    return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* All play/record/stop/pause/resume messages go straight to the
 * SoundView.  The Document only manages the button displays.
 */
- play:sender
{
	[playButton setEnabled:NO];	/* Disable play button */
	[pauseButton setState:0];	/* Pause off */
	[view play:sender];
	return self;
}

- stop:sender
{
    [playButton setState:0];		/* Play button is off and enabled */
    [playButton setEnabled:YES];
    [pauseButton setState:0];		/* Pause off */
    [view stop:sender];
    return self;
}

- pause:sender
{
    if (![playButton state]) {		/* If not playing, this is a nop */
	[pauseButton setState:0];
	return self;
    } else if ([pauseButton state])	/* If pause is now ON, stop */
	[view pause:self];
    else
	[view resume:self];		/* Else, resume */
    return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* showDisplayTimes -- Update the start/end/size time displays
 */
- showDisplayTimes
{
	float start,size;

/* Get the times from the ScrollingSound and show
 * them in the appropriate Forms
 */
	[scroller getStart:&start Size:&size];
	PUTVAL(startForm,start);
	PUTVAL(endForm,start+size);
	PUTVAL(sizeForm,size);
    return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* showSelectionTimes -- Display current selection times
 */
- showSelectionTimes
{
	float start,size;

/* Get the times from ScrollingSound and stuff 'em into the Forms
 */
	[scroller getSelStart:&start Size:&size];
	PUTVAL(selStartForm,start);
	PUTVAL(selEndForm,start+size);
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* showFormat: -- Display sound format info in text fields
 */
- showFormat:sound
{
	float srate = [sound samplingRate];

	switch ([sound channelCount]) {
		case 1:
			[nchansField setStringValue:"Mono"];
			break;
		case 2:
			[nchansField setStringValue:"Stereo"];
			break;
		default:
			[nchansField setStringValue:""];
			break;
	}
	switch([sound dataFormat]) {
		case SND_FORMAT_LINEAR_16:
			[formatField setStringValue:"16-bit"];
			break;
		case SND_FORMAT_FLOAT:
			[formatField setStringValue:"Float"];
			break;
		case SND_FORMAT_MULAW_8:
			[formatField setStringValue:"MuLaw"];
			break;
		default:
			[formatField setStringValue:""];
			break;
	}
	if (srate == 8012.0)
		[srateField setStringValue:"8.012 kHz"];
	else if (srate == SND_RATE_LOW)
		[srateField setStringValue:"22.05 kHz"];
	else if (srate == SND_RATE_HIGH)
		[srateField setStringValue:"44.1 kHz"];
	else
		[srateField setStringValue:""];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* displayChanged: -- Handle a change in the display (scroll or otherwise)
 *	This message is sent by the ScrollingSound
 */
- displayChanged:sender
{
	[self showDisplayTimes];
	[self showSelectionTimes];
	[self showFormat:[[scroller view] sound]];
	PUTVAL(durationForm,[scroller duration]);
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* newStart:  -- Change the display to start at a specified time
 */
- newStart:sender
{
	float start;

/* Get the time from the Form and have the scroller set it
 */
	start = GETVAL(startForm);
	if (start < 0) {		/* ignore negative values */
		[self showDisplayTimes];
		return self;
	}
	[scroller setStart:start];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* newSize: -- Set the duration of the display.  Start time will
 * 	remain constant.
 */
- newSize:sender
{
	float size,start;

	size = GETVAL(sizeForm);
	start = GETVAL(startForm);
	if (size <= 0) {		/* erase and ignore bad values */
		[self showDisplayTimes];
		return self;
	}

	[NXWait set];
	NXPing();
	[scroller setSize:size];
	[scroller setStart:start];
	[NXArrow set];
	NXPing();

	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setSelStart: -- Set the start time of the selection
 */
- setSelStart:sender
{
	float start,end,size;		/* Start/end/size of selection */
	float vstart, vend, vsize ;	/* Start/end/size of view */
	float dur;			/* duration of file */

/* Get the new start and end times for the selection.  If the
 * new start time is > the end time, then make a new endtime == 
 * to the start (i.e., selection size = 0 samples).
 */ 
	start = GETVAL(selStartForm);
	end = GETVAL(selEndForm);
	dur = [scroller duration];
	
	if (start < 0) {		/* Ignore negative values */
		[self showSelectionTimes];
		return self;
	}
	else if (start > dur)		/* Can't select past EOF */
		start = dur;

	if (start > end)
		end = start;

	size = end-start;
	[scroller setSelStart:start Size:size];

/* If the new start time is outside the current view, scroll the view
 * so that the new start is in the center.  If the whole selection
 * will fit in the view, center the selection instead.
 */
	vstart = GETVAL(startForm);
	vend = GETVAL(endForm);
	if (start < vstart  ||  start > vend) {
		vsize = GETVAL(sizeForm);
		if (size <= vsize)
			vstart = start + size/2 - vsize/2;
		else
			vstart = start - vsize/2;
		if (vstart < 0)
			vstart = 0;
		[scroller setStart:vstart];
	}
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setSelEnd:  -- Set the end time of the selection
 */
- setSelEnd:sender
{
	float start,end,size;
	float vstart, vend, vsize ;	/* Start/end/size of view */
	float dur;			/* duration of file */
	
/* Grab the new end time.  If it's < the current start time,
 * then set start time = end time (i.e., selection size = 0).
 */
	end = GETVAL(selEndForm);
	start = GETVAL(selStartForm);
	dur = [scroller duration];
	
	if (end < 0) {		/* Ignore negative values */
		[self showSelectionTimes];
		return self;
	}
	else if (end > dur)		/* Can't select past EOF */
		end = dur;

	if (end < start)
		start = end;
	size = end-start;
	[scroller setSelStart:start Size:size];

/* If the new end time is outside the current view, scroll the view
 * so that the new end is in the center.
 */
	vstart = GETVAL(startForm);
	vend = GETVAL(endForm);
	if (end < vstart  ||  end > vend) {
		vsize = GETVAL(sizeForm);
		if (size <= vsize)
			vstart = start + size/2 - vsize/2;
		else
			vstart = end - vsize/2;
		if (vstart < 0)
			vstart = 0;
		[scroller setStart:vstart];
	}
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* EdSoundView delegate functions start and stop the sound meter and
 * manage buttons
 */
- willPlay:sender
{
    [NXApp isPlaying:YES];		/* Tell the App about this */
    [meter setSound:[sender soundBeingProcessed]];
    [meter run:self];
    return self;
}

- didPlay:sender
{
    [playButton setState:0];		/* Reset the buttons */
    [playButton setEnabled:YES];
    [pauseButton setState:0];
    [meter stop:self];
    [NXApp isPlaying:NO];
    return self;
}

- hadError:sender
{
    int err = [[sender soundBeingProcessed] processingError];
    NXRunAlertPanel("Play error", SNDSoundError(err),"OK", NULL, NULL);
    return [self stop:self];
}

/* selectionChanged: -- Handle a change in the selection. 
 */
- selectionChanged:sender
{
	[self showSelectionTimes];
	return self;
}	

- soundChanged:sender
{
	[window setDocEdited:YES];
	if ([scroller duration] != 0)
		[NXApp isOpenSound:YES];
	else
		[NXApp isOpenSound:NO];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* Window delegate messages -- becoming/resigning main status
 * 	causes changes in the current Document status
 */
- windowDidBecomeMain:sender
{
    [window makeFirstResponder:view];
    [view showCursor];
    if ([scroller duration] != 0)
    	[NXApp isOpenSound:YES];
    else
	[NXApp isOpenSound:NO];
    if (fileName)
    	[NXApp isOpenFile:YES];
    else
    	[NXApp isOpenFile:NO];
    [NXApp setCurrentSound:view];

    return self;
}

- windowDidResignMain:sender
{
	[view stop:sender];
	[view hideCursor];
	[NXApp setCurrentSound:nil];

	return self;
}

- windowDidMiniaturize:sender		/* stop sound if miniaturizing */
{
    [view stop:sender];
    [view hideCursor];
    if (--opendocs == 0)
    	[NXApp isOpenDocument:NO];   
    return self;
}

- windowDidDeminiaturize:sender
{
	opendocs++;
	[NXApp isOpenDocument:YES];
	return self;
}

- windowWillClose:sender	    /* save file if necessary when closing */
{
    char buf[1024];
    int choice;
    if ([window isDocEdited]) {
	choice = NXRunAlertPanel("Close", "Sound is modified.\nSave it?", 
						"Yes", "No", "Cancel");
	switch (choice) {
	    case NX_ALERTALTERNATE:
		break;
	    case NX_ALERTDEFAULT:
		[self save:self];
		break;
	    case NX_ALERTOTHER:
		return nil;
	}
	[window setDocEdited:NO];
    }
    if (--opendocs == 0)
    	[NXApp isOpenDocument:NO];
    [self windowDidResignMain:self];
    return sender;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* Stuff for Interface Builder
 */
- setWindow:anObject
{
    NXRect theFrame;		/* Coordinates of the window */

    window = anObject;
    [window setDelegate:self];	/* Document is delegate for Window */

/* Move this frame to the next location on the screen, as determined
 * by newLocation().  This keeps documents from hiding each other.
 */
    [window getFrame:&theFrame];
    newLocation(&theFrame.origin);
    [window moveTo:theFrame.origin.x :theFrame.origin.y];
    [window makeKeyAndOrderFront:self];
    return self;
}

- setScroller:anObject
{
    scroller = anObject;

/* set our view variable so we can get at the EdSoundView, and set us
 * up as delegate for the EdSoundView and the ScrollingSound.
 */
    view = [scroller view];
    [scroller setDelegate:self];
    [view setDelegate:self];
    [view setContinuous:YES];		/* So we see mouse-drag events */
    return self;
}

- scroller
{
	return scroller;
}

- setStartForm:anObject
{
    startForm = anObject;
    return self;
}

- setEndForm:anObject
{
    endForm = anObject;
    return self;
}

- setSelStartForm:anObject
{
    selStartForm = anObject;
    return self;
}

- setSelEndForm:anObject
{
    selEndForm = anObject;
    return self;
}

- setSizeForm:anObject
{
    sizeForm = anObject;
    return self;
}

- setDurationForm:anObject
{
    durationForm = anObject;
    return self;
}

- setPlayButton:anObject
{
    playButton = anObject;
    return self;
}

- setStopButton:anObject
{
    stopButton = anObject;
    return self;
}

- setPauseButton:anObject
{
    pauseButton = anObject;
    return self;
}

- setMeter:anObject
{
    meter = anObject;
    return self;
}
- setNchansField:anObject
{
    nchansField = anObject;
    return self;
}
- setFormatField:anObject
{
    formatField = anObject;
    return self;
}
- setSrateField:anObject
{
    srateField = anObject;
    return self;
}

@end
