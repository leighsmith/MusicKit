/* FFTView.h -- Interface for FFTView class
 *
 * This is a subclass of View that displays spectral data for a sound
 * via an FFT.  The FFTView handles all the computation and graphics;
 * it does not handle Sound object creation or soundfile operations.
 * External objects control the number of points in the FFT, the 
 * sound to be viewed, and the starting point within that sound.
 * The latter is expressed as a time point.  The FFTView also
 * manages a hairline cursor (manipulated by the mouse) and can
 * report the frequency and amplitude at the current cursor
 * location.
 *
 * In a typical usage, an Application (or other object) would
 * feed sounds, start times, and FFT window sizes to the FFTView,
 * and then cause computation and plotting via a 'display' message.
 *
 * jwp@silverton.Princeton.edu, 12/89
 * 02/21/90:  Added support for DPSDoUserPath()
 */

#import <appkit/View.h>

@interface FFTView : View
{
        id sound;               /* The sound we're looking at */
        int npoints;            /* Number of points (power of 2) */
        float inskip;           /* Start time of frame */
	id delegate;		/* Delegate for this view (if any) */
	BOOL dBflag;		/* dB display? */

        float *sframe;          /* Current frame of samples */
        float *coefs;           /* Output data */
	float *scoefs;		/* Scaled output data */
	float srate;		/* Sampling rate of sound */
	int startsamp;		/* First sample of frame */
        float cursorpixel;      /* Cursor location (as pixel column) */
	float cursorpoint;	/* Cursor location (as FFT point) */

	float *PSdata;		/* User path data (allocated in setNpoints) */
	char *PSops;		/* User path operators */

        BOOL needsFFT;          /* Do we need to do an FFT? */
	BOOL needsScaling;	/* Do we need to do a scaling? */
        BOOL validData;         /* Do we have good data in sframe? */
}

/* Public methods
 *
 * To create an instance:
 *      + newFrame:             -- Create and initialize a new instance
 *				   (see View.h for more info)
 */
+ newFrame:(const NXRect *)frameRect;

/* To set up the FFT:
 *      - setSound:		-- Attach a sound to this FFTView
 *      - setNpoints:     	-- Set number of points in FFT window
 *      - setInskip:		-- Set start time of frame
 *	- advanceFrame:		-- Advance by one frame of data
 *	- dBdisplay:		-- Turn on/off dB display
 */
- setSound:aSound;
- setNpoints: (int)n;
- setInskip: (float)t;
- advanceFrame:sender;		/* Note: this is target/action method */
- dBdisplay:(BOOL)flag;

/* To retrieve info about the FFT:
 *	- sound			-- Returns pointer to attached sound
 *	- (int)npoints		-- Returns size of FFT window
 *	- (float)inskip		-- Returns start time
 *	- (BOOL)dBdisplay	-- Returns dBflag
 */
- sound;
- (int)npoints;
- (float)inskip;
- (BOOL)dBdisplay;

/* Cursor information methods:
 *	- getCursorFreq:Amp:	-- Retrieve the frequency and amplitude
 *				   at the current cursor location (arguments
 *				   are pointers to floats)
 *	- setCursorFreq:	-- Set the cursor to point to a particular
 *				   frequency
 */
- getCursorFreq:(float *)freq Amp:(float *)amp;
- setCursorFreq:(float)freq;

/* Miscellaneous lower-level methods:
 *	- setDelegate:		-- Set the delegate for cursor update messages
 *	- delegate		-- Returns pointer to the delegate
 *	- needsFFT:		-- Set/reset needsFFT flag (this method
 *				   used to force or suppress calculation of
 *				   FFT.  Not normally necessary).
 *	- (BOOL)needsFFT	-- Returns current value of needsFFT flag
 */
- setDelegate:anObject;
- delegate;
- needsFFT:(BOOL)flag;
- (BOOL)needsFFT;


/* Private methods
 *
 * Drawing methods:
 *
 *      - drawSelf::            -- Do FFT (if necessary) and draw it
 */
- drawSelf:(NXRect *)rects :(int)rectCount;

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
@interface DummyFFTViewDelegate : Object
- cursorMoved:sender;
@end
