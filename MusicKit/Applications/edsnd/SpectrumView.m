/* SpectrumView.m -- Implementation for SpectrumView class
 *
 * See 'SpectrumView.h' for details
 *
 * smb@datran2.uunet.uu.net
 * jwp@silvertone.Princeton.edu
 * 2/90
 * 03/90:  Spectral data plot now done via PSrectfill() to save time
 */

#import <stdlib.h>
#include <limits.h>
#include <sound/sound.h>
#include <dsp/arrayproc.h>
#import <math.h>
#import <dpsclient/wraps.h>
#import <appkit/Window.h>
#import <appkit/Panel.h>
#import <appkit/Application.h>
#import <soundkit/Sound.h>
#import "SpectrumView.h"
#import "fft.h"
#import "PWSpectrum.h"

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */
/* Shorthand for the PostScript call to draw the cursor
 */
#define DOVCURSOR() PScompositerect(cursorXpixel,0,1,bounds.size.height,NX_HIGHLIGHT);
#define DOHCURSOR() PScompositerect(0,cursorYpixel,bounds.size.width,1,NX_HIGHLIGHT);

/* Handy shorthands for various conversions:
 *	WIDTH	= width of view in pixels
 *	freqBW	= bandwidth of FFT (in Hz)
 *	pixelXBW = bandwidth of slice in pixels
 *	pixelYBW = bandwidth of FFT point in pixels
 * 	SLICESECS = duration of slice in seconds
 */
#define WIDTH    (bounds.size.width - 30)
#define freqBW   (srate / (npoints - 1))
#define pixelXBW  (WIDTH / nslices)
#define pixelYBW  (4 *(bounds.size.height - 20) / (npoints - 1))
#define SLICESECS ((slidepoints - 1) / srate)

/* Shorthand for alert panel calls
 */
#define erralert(title, msg) NXRunAlertPanel(title, msg, "OK", NULL, NULL)

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */
/* Functions in fft_net.c:
 */
extern void fft(int t, int n, int w, float *sb, int sf, int sc, 
                float *rb, int rf, int rs);
extern int power_of_two(int n);

/* Functions in fft.m:
 */
extern float *getframe(id sound,int startsamp, int nsamps);
extern float scaledata(float *inptr, float *outptr, int nsamps, int scalemask, int *mean);

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

static int *slicemeanindex = NULL;	/* slicemeanindex[] stores the
					 * mean frequency info for the
					 * slices.  It is allocated
					 * by doSpectrum at display time
					 */

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

@implementation SpectrumView 

/* dBdisplay: -- Turn on/off dB display
 */
- dBdisplay:(BOOL)flag
{
	dBflag = flag;
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* dBdisplay -- returns dBflag
 */
- (BOOL) dBdisplay
{
	return dBflag;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* getCursorTime:Freq:Mean: -- Retrieves frequency/amplitude data at current
 *			 cursor location
 * Arguments are pointers to floats where data is to go.
 */
- getCursorTime:(float *)time Freq:(float *)freq Mean:(float *)mean
{
	if (!sound) {
		*freq = *time = *mean = 0.0;
		return self;
	}
	*time = cursorXpoint * SLICESECS;
	*freq = cursorYpoint * freqBW;
	*mean = slicemeanindex[(int)cursorXpoint] * freqBW;
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setCursorTime: -- Set the position of the cursor
 * Argument is a time to set cursor to.  This method does
 * all translation necessary.
 */
- setCursorTime:(float)time
{
	if (!sound) 
		return self;

	/* Interpret time as a point, then
	 * convert that to a pixel column and draw it.
	 */
	cursorXpoint = time / (SLICESECS);
	DOVCURSOR();
	DOHCURSOR();
	cursorXpixel = (cursorXpoint * pixelXBW) + 30;
	cursorYpixel = (cursorYpoint * SLICESECS) + 20;
	DOHCURSOR();
	DOVCURSOR();
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setDelegate: -- set the delegate for this object
 */
- setDelegate:anObject
{
	delegate = anObject;
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* delegate -- returns pointer to current delegate
 */
- delegate
{
	return delegate;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */


/* setMeanDisplay: -- Set/reset meanDisplay flag
 */
- setMeanDisplay:(BOOL)flag
{
	meanDisplay = flag;
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setSpectrumDisplay: -- Set/reset spectrumDisplay flag
 */
- setSpectrumDisplay:(BOOL)flag
{
	spectrumDisplay = flag;
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* drawSelf:: -- This just clears the view (called by 'display' when
 *	first bringing up the view, etc.)  To draw the spectrum, use
 *	'doSpectrum'
 *
 * This method called via 'display' method.
 */

- drawSelf:(NXRect *)rects :(int)rectCount
{
NXEraseRect(&bounds);
cursorXpixel = cursorYpixel = 0.0;
return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* doSpectrum -- Actually draw the spectrum over the specified duration
 * This method does all the real work in the SpectrumView
 */
- doSpectrum:aSound Start:(float)start Dur:(float)dur Npoints:(int)n Slidepoints:(int)s;
{
	static float *sframe = NULL;	/* Current frame of samples */
	static float *coefs = NULL;	/* Output data */
	static float *scoefs = NULL;	/* Scaled output data */
	static float maxamp;		/* Peak amp in coefs[] */
	float *inp, *outp;		/* Pointers into coefs/scoefs */

	int startsamp;			/* First sample frame to get */
	int nsamps;			/* Number of sample frames to get */

	int slice = 0;			/* Slice counter */

	float xincr,yincr;		/* Graphics scaling parameters */
	int N;      			/* = npoints/2 */
	int maxfreq;			/* Top freq in display (in KHz) */
	float KHzincr;			/* Pixel rows per KHz */
	float maxtime;			/* Top timing in display (in sec.) */
	float timeincr;			/* Pixel columns per time quantum */
	float x;			/* Current pixel column */
	int i;
	NXEvent foo;
	float yval;
	int lasti;


/* Initializations:
 *	-- Initialize PostScript
 *	-- Set our instance variables (sound,npoints,slidepoints)
 *	-- Convert start and dur to samples and slices
 *	-- Set up scaling factors xincr and yincr
 */

	PWSpectinit();

	sound = aSound;

	if (n != npoints) {
		if (!power_of_two(n)) {
			erralert("SpectrumView","Size must be a power of two");
			return self;
		}
		npoints = n;

	/* Allocate new coefs and scoefs arrays, since the FFT size changed.
	 */
		if (coefs)
			free(coefs);
		coefs = (float *)malloc(npoints * sizeof(float));
		if (scoefs)
			free(scoefs);
		scoefs = (float *)malloc(npoints * sizeof(float));
	}
	N = npoints/2;

	slidepoints = s;

	if (!sound || dur == 0.0)
		return self;

	srate = [sound samplingRate];
	startsamp = start * srate;
	nsamps = dur * srate;
 	nslices = nsamps / slidepoints;
	
	/* Allocate a new array of slicemeans
	 */
	if (slicemeanindex)
		free(slicemeanindex);
	slicemeanindex = (int *)malloc(nslices * sizeof(int));

	/* Set scaling factors: 
	 * xincr = pixel columns per slice
	 * yincr = pixel rows per FFT point
	 * maxfreq and KHzincr are for the KHz ruler.
	 * timeincr is for the sec. ruler.
	 */


	xincr = WIDTH / nslices;
	if (xincr <= 0.5) {
		erralert("Spectrum","View too small for display");
		return self;
	}
	timeincr = xincr * ((srate / (slidepoints - 1)) / 4);

	yincr = (bounds.size.height - 20) / ((N  / 2) - 1);
	if (yincr <= 0.5) {
		erralert("Spectrum","View too small for display");
		return self;
	}
        maxfreq = srate / 4000;
        KHzincr = (bounds.size.height - 20) / maxfreq;

/* Erase what's there now and draw the rulers
 */
	[self lockFocus];
	NXEraseRect(&bounds);
	PSgsave();
	PStranslate(30,0);
	PWSpectdrawHruler(0.0,dur,0.25,timeincr);
	PSgrestore();

	PSgsave();
	PStranslate(0,20);
	PWSpectdrawVruler(0,maxfreq,1,KHzincr);
	PSgrestore();
	[self unlockFocus];
	[[self window] flushWindow];
	cursorXpixel = cursorYpixel = 0.0;

/* Draw the spectrum.  'x' is our current horizontal position.
 * We start drawing at (xincr + 1)/2 (i.e., in the middle of the
 * first slice), and increment by xincr for subsequent slices.
 * The slices are drawn as vertical lines with widths of 'xincr',
 * so that they will be centered on 'x'.
 */
	[self lockFocus];
	for (x = 0.0, slice = 0;
	     slice < nslices;
	     x += xincr, slice++, startsamp += slidepoints) {

	/* Get a frame of data and apply the FFT
	 */
		if (!(sframe = getframe(sound,startsamp,npoints)))
			break;
		fft(FORWARD, npoints, RECTANGULAR,
		    sframe, REAL, LINEAR,
	 	    coefs, MAG, LINEAR);

	/* Rescale the FFT results
	 */
 		if (!dBflag)
			maxamp = scaledata(coefs,scoefs,npoints,
					GRAYSCALEMASK,slicemeanindex+slice);
		else
			maxamp = scaledata(coefs,scoefs,npoints,
				GRAYSCALEMASK|dBMASK,slicemeanindex+slice);

	/* And draw this slice
	 */
		PSgsave();
		PStranslate(30+x,20);	/* Translate to 'x' */

		if (spectrumDisplay) {
		
	/* Go through the grayscaled data and find the largest rectangle
	 * of uniform color and then draw it.  This minimizes the
	 * Display PostScript overhead.
	 * yval = current grayscale value
	 */
			for (i = 0, yval = *scoefs, lasti = 0; i < N/2; i++) {
				if (scoefs[i] != yval) {
					if (yval < 1.0) {
						PSsetgray(yval);
						PSrectfill(0,
							   lasti*yincr,
							   xincr+1,
							   (i-lasti)*yincr);
					}
					yval = scoefs[i];
					lasti = i-1;
				}
			}
			if (yval < 1.0) {
				PSsetgray(yval);
				PSrectfill(0,
					   lasti*yincr,
					   xincr+1,
					   (i-lasti)*yincr);
			}
		}
		if (meanDisplay)
		     PWSmeanplotdata(slicemeanindex[slice],xincr+1,yincr);
		PSgrestore();
		[[self window] flushWindow];
//               NXPing();

	/* Any mouse-down event aborts the plot
	 */
                if ([NXApp peekNextEvent:NX_MOUSEDOWNMASK into:&foo]) {
                        [NXApp getNextEvent:NX_MOUSEDOWNMASK];
                        break;
                }
	}
	[self unlockFocus];

	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* mouseDown: -- Handle a mousedown event
 * This method does cursor management.  It locates and draws the cursor
 * at the point of the mouse down, then follows the mouse along during
 * any subsequent dragging.  This method returns as soon as a mouseup
 * event is received.
 * A "cursorMoved" message is sent to the delegate (if any) as
 * mousedown/mousedragged events are received.
 */

#define DRAG_MASK (NX_MOUSEUPMASK|NX_MOUSEDRAGGEDMASK)

- mouseDown:(NXEvent *)event
{
	NXPoint p;		/* Where the mouse is */
	int oldMask;		/* Old event mask */
	float pXbw = pixelXBW;	/* Local copy of pixelXBW */
	float pYbw = pixelYBW;	/* Local copy of pixelYBW */
	BOOL shift;
	int i;
	
	if (!sound)
		return self;
	shift = (event->flags & NX_SHIFTMASK) ? YES : NO;
	
	/* Ask for mousedragged and mouseup events only for the duration
	 * of this method.
	 */
	oldMask = [[self window] addToEventMask:DRAG_MASK];

	/* For the initial mousedown event and all subsequent mousedragged events,
	 * update the cursor as necessary and send a cursorMoved: message to
	 * the delegate.
	 */
	if (shift) {
		p = event->location;
		[self convertPoint:&p fromView:nil];
		[self lockFocus];
		DOVCURSOR();		/* This unhighlights the old */
		DOHCURSOR();		/* This unhighlights the old */
		cursorXpixel = p.x;
		cursorYpixel = p.y;
		DOHCURSOR();		/* This highlights the new */
		DOVCURSOR();		/* This highlights the new */
		if ((cursorXpoint = (cursorXpixel - 30) / pXbw) < 0)
			cursorXpoint = 0;
		if ((cursorYpoint = (cursorYpixel - 20) / pYbw) < 0)
			cursorYpoint = 0;
		if (delegate && [delegate respondsTo:@selector(cursorMoved:)])
			[delegate cursorMoved:self];
		for (i = 2*cursorXpixel; i < WIDTH; i += cursorXpixel)
			PScompositerect(i,0,1,bounds.size.height,NX_HIGHLIGHT);
		[self unlockFocus];
		[[self window] flushWindow];
		NXPing();
		do{
			event = [NXApp getNextEvent:DRAG_MASK];
		} while (event->type != NX_MOUSEUP);
		return self;
	}
	do {
		p = event->location;
		[self convertPoint:&p fromView:nil];
		if (p.x >= 0 && p.x <= bounds.size.width
			&& p.y >= 0 && p.y <= bounds.size.height
			&& (cursorXpixel != p.x || cursorYpixel != p.y)) { /* Draw the cursor: */
			[self lockFocus];
			DOVCURSOR();		/* This unhighlights the old */
			DOHCURSOR();		/* This unhighlights the old */
			cursorXpixel = p.x;
			cursorYpixel = p.y;
			DOHCURSOR();		/* This highlights the new */
			DOVCURSOR();		/* This highlights the new */
			[self unlockFocus];
			[[self window] flushWindow];
			NXPing();
			cursorXpoint = (cursorXpixel - 30) / pXbw;
			cursorYpoint = (cursorYpixel - 20) / pYbw;
			if ((cursorXpoint = (cursorXpixel - 30) / pXbw) < 0)
				cursorXpoint = 0;
			if ((cursorYpoint = (cursorYpixel - 20) / pYbw) < 0)
				cursorYpoint = 0;
			if (delegate && [delegate respondsTo:@selector(cursorMoved:)])
				[delegate cursorMoved:self];
		}
		event = [NXApp getNextEvent:DRAG_MASK];
	} while (event->type != NX_MOUSEUP);
	[[self window] setEventMask:oldMask];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* acceptsFirstResponder -- notify Window Server that we want mouse events
 */

- (BOOL) acceptsFirstResponder
{
        return YES;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

@end
