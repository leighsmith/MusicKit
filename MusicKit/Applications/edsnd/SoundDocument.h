/* SoundDocument.h -- Interface for SoundDocument object.
 * 
 * This is a custom object that does the following:
 *	1) Through several Forms, reports on and allows control of
 *	   sound display.
 *	2) Manages sound playback
 *	3) Manages soundfile I/O
 *	4) Acts as delegate for the window, ScrollingSound, and EdSoundView
 *
 * Original code by Lee Boynton
 * Revision by James Pritchett, 10/89
 * Version 1.01, 11/89
 *	-- removed added edit commands now in EdSoundView;
 *	-- prompts user to save when closing edited file
 *	-- Changed messaging to NXApp re: document status (removed currentDoc)
 * Version 1.2, 1/90
 * Version 1.3, 2/90
 *	-- Added nchansField, formatField, srateField
 */
 
#import <objc/Object.h>

@interface SoundDocument:Object
{
    id	window;			/* Window this SoundDocument is in */
    id  scroller;		/* The ScrollingSound object */
    id	view;			/* The EdSoundView of that ScrollingSound */

    id	startForm;		/* Start time display Form */
    id	endForm;		/* End time display Form */
    id	selStartForm;		/* Selection start time display Form */
    id	selEndForm;		/* Selection end time display Form */
    id	sizeForm;		/* Size display Form */
    id  durationForm;		/* Total Duration display Form */
    id playButton;		/* Playback control buttons */
    id stopButton;
    id pauseButton;
    id meter;			/* SoundMeter */
    id nchansField;		/* Field for channel count */
    id formatField;		/* Field for sampling format */
    id srateField;		/* Field for sampling rate */

    char *fileName;		/* Name of the soundfile */
    BOOL isempty;		/* Flag to note empty Sound */
}


/* CLASS METHODS
 *
 * new			-- Create a new instance
 */
+ new;


/* INSTANCE METHODS
 *
 * Methods to handle soundfiles: 
 * 	setFileName:		-- Change the soundfile name
 *	saveAs:			-- Save a sound under a new filename
 *	save:			-- Save the Sound into a soundfile
 *	load:			-- Load the soundfile into the EdSoundView
 */
- setFileName:(char *)aName;
- saveAs:sender;
- save:sender;
- load:sender;

/* Methods to handle playing the sound:
 *	play:			-- Play the sound
 *	stop:			-- Stop the play
 *	pause:			-- Pause or resume the play
 */
- play:sender;
- stop:sender;
- pause:sender;

/* Methods to handle the time displays:
 * 	showDisplayTimes	-- Display the start/end/size times
 *	showSelectionTimes	-- Display the selection times
 *	displayChanged:		-- Handle a change in ScrollingSound:
 *				   this message sent by the ScrollingSound
 */
- showDisplayTimes;
- showSelectionTimes;
- showFormat:sound;
- displayChanged:sender;

/* Methods to change the display or selection:
 *	newStart:		-- Set the display start time
 *	newSize:		-- Set the display duration
 *	setSelStart:		-- Set the selection start time
 * 	setSelEnd:		-- Set the selection end time
 *
 */
- newStart:sender;
- newSize:sender;
- setSelStart:sender;
- setSelEnd:sender;

/* Delegate methods for Window:
 *	windowWillClose:
 *	windowDidBecomeMain:
 * 	windowDidResignMain:
 *	windowDidMiniaturize:
 *	windowDidDeminiaturize:
 *
 * Delegate methods for EdSoundView:
 *	willPlay:
 *	didPlay:
 *	hadError:
 *	soundChanged:
 */
- windowWillClose:sender;
- windowDidBecomeMain:sender;
- windowDidResignMain:sender;
- windowDidMiniaturize:sender;
- windowDidDeminiaturize:sender;
- willPlay:sender;
- didPlay:sender;
- hadError:sender;
- soundChanged:sender;


/* Stuff for Interface Builder:
 */
- setWindow:anObject;
- setScroller:anObject;
- scroller;			/* Returns ptr to scroller */
- setStartForm:anObject;
- setEndForm:anObject;
- setSelStartForm:anObject;
- setSelEndForm:anObject;
- setSizeForm:anObject;
- setDurationForm:anObject;
- setPlayButton:anObject;
- setStopButton:anObject;
- setPauseButton:anObject;
- setMeter:anObject;
- setNchansField:anObject;
- setFormatField:anObject;
- setSrateField:anObject;

@end
