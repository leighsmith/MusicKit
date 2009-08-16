/* SpectrumView.h -- Interface for SpectrumView class
 *
 * This is a subclass of View that displays spectral data for a sound
 * via an FFT.  The SpectrumView handles all the computation and graphics;
 * it does not handle Sound object creation or soundfile operations.
 * External objects control the number of points in the FFT, the 
 * sound to be viewed, and the starting point within that sound.
 * The latter is expressed as a time point.  The SpectrumView also
 * manages a hairline cursor (manipulated by the mouse) and can
 * report the frequency and amplitude at the current cursor
 * location.
 *
 * In a typical usage, an Application (or other object) would
 * feed sounds, start times, and FFT window sizes to the SpectrumView,
 * and then cause computation and plotting via a 'display' message.
 *
 * smb@datran2.uunet.uu.net 
 * jwp@silverton.Princeton.edu
 * 2/90
 */

#import <appkit/View.h>

@interface SpectrumView : View
{
	id sound;		/* The sound we're looking at */
	int npoints;		/* Number of points (power of 2) */
	int slidepoints;	/* Number of points to slide the window */
	int nslices;		/* Number of slices in frame */
	id delegate;		/* Delegate for this view (if any) */
	BOOL dBflag;		/* dB display? */	
	float srate;		/* Sampling rate of sound */
	float cursorXpixel;	/* Cursor location (as pixel column) */
	float cursorYpixel;	/* Cursor location (as pixel row) */
	float cursorXpoint;	/* Cursor location (as time slice) */
	float cursorYpoint;	/* Cursor location (as FFT point) */
	
	BOOL meanDisplay;	/* Should we display the Mean Frequency Line */
	BOOL spectrumDisplay;	/* Should we display the Spectrum */
}


/* To set up the FFT:
 *	- dBdisplay:	-- Turn on/off dB display
 */
- dBdisplay:(BOOL)flag;

/* To retrieve info about the FFT:
 *	- (BOOL)dBdisplay	-- Returns dBflag
 */
- (BOOL)dBdisplay;

/* Cursor information methods:
 *	- getCursorTime:Freq:Amp:	-- Retrieve the frequency and amplitude
 *				   at the current cursor location (arguments
 *				   are pointers to floats)
 *	- setCursorTime:	-- Set the cursor to point to a particular
 *				   frequency
 */
- getCursorTime:(float *)time Freq:(float*)freq Mean:(float *)mean;
- setCursorTime:(float)time;

/* Miscellaneous lower-level methods:
 *	- setDelegate:		-- Set the delegate for cursor update messages
 *	- delegate		-- Returns pointer to the delegate
 *	- setMeanDisplay:
 *	- setSpectrumDisplay:
 */
- setDelegate:anObject;
- delegate;
- setMeanDisplay:(BOOL)flag;
- setSpectrumDisplay:(BOOL)flag;


/* Drawing methods:
 *
 *      - drawSelf::            -- (This just clears the View)
 *	- doSpectrum:Start:Dur:Npoints:Slidepoints:
 *				-- Draw the spectrum
 */
- drawSelf:(NXRect *)rects :(int)rectCount;
- doSpectrum:aSound Start:(float)start Dur:(float)dur Npoints:(int)n Slidepoints:(int)s;

/* Cursor/mouse management:
 *      - mouseDown:		-- Handle a mousedown event
 *      - acceptsFirstResponder	-- Returns YES (to get mouse events)
 */
- mouseDown:(NXEvent *)event;
- (BOOL)acceptsFirstResponder;

@end


/* The following dummy interface is used to declare the delegate
 * methods for this object.
 *
 * 	- cursorMoved:		-- Notify delegate that cursor has moved
 */
@interface DummySpectrumViewDelegate : Object
- cursorMoved:sender;
@end
