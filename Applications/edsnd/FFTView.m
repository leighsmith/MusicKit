/* FFTView.m -- Implementation for FFTView class
 *
 * See 'FFTView.h' for details
 *
 * jwp@silvertone.Princeton.edu, 12/89
 * 2/5/90: Fixed getFrame to handle stereo by summing channels.
 * 2/21/90: Drawing now done via DPSDoUserPath() to save time.
 */

#import <stdlib.h>
#import <math.h>
#import <dpsclient/wraps.h>
#import <appkit/Window.h>
#import <appkit/Panel.h>
#import <appkit/Application.h>
#import <soundkit/Sound.h>
#import "FFTView.h"
#import "fft.h"
#import "PWfft.h"

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */
/* Shorthand for soundkit format codes:
 */
#define SNDSHORT SND_FORMAT_LINEAR_16
#define SNDFLOAT SND_FORMAT_FLOAT

/* Shorthand for the PostScript call to draw the cursor
 */
#define DOCURSOR() PScompositerect(cursorpixel,0,1,bounds.size.height,NX_HIGHLIGHT);

/* Handy shorthands for various conversions:
 */
#define WIDTH    bounds.size.width	/* Width of view in pixels */
#define freqBW   srate/(npoints-1)	/* Bandwidth of FFT (in Hz) */
#define pixelBW  2*WIDTH / (npoints-1)  /* Bandwidth of FFT (in pixels) */

/* Shorthand for alert panel calls
 */
#define erralert(title, msg) NXRunAlertPanel(title, msg, "OK", NULL, NULL)

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */
/* Functions in fft_net.c:
 */
extern void fft(int t, int n, int w, float *sb, int sf, int sc, 
                float *rb, int rf, int rs);
extern int power_of_two(int n);
extern float *getframe(id sound,int startsamp, int nsamps);
extern float scaledata(float *inptr, float *outptr, int nsamps, int scalemask, int *mean);
/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

@implementation FFTView 

/* newFrame: -- Create an instance and initialize.
 * Default values:  npoints = 512, inskip = 0.0 sec.
 */
+ newFrame:(const NXRect *)frameRect
{
        self = [super newFrame:frameRect];
        [self setSound:nil];		/* This also resets inskip */
        [self setNpoints:512];
	PWinit();			/* Initialize PostScript stuff */
        return self;
}
        
/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setSound: -- Attach a sound to this view
 * This also resets cursor position and inskip to 0.
 */
- setSound:aSound
{
        sound = aSound;
	inskip = cursorpixel = cursorpoint = 0;
	startsamp = 0;
        needsFFT = needsScaling = validData = NO;
	if (sound) {
		srate = [sound samplingRate];
		if (sframe = getframe(sound,startsamp,npoints))
			needsFFT = validData = YES;
	}
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */
 
/* setNpoints: -- Set size of FFT window
 * This is where sframe[], coefs[], and scoefs[] arrays are allocated.
 * This is also where PSdata[] and PSops[] arrays are allocated.
 */
- setNpoints:(int)n
{
	int i,N;

        if (!power_of_two(n)) {          /* Must be power of two */
		erralert("FFTView","Size must be a power of two");
                return self;
	}
	if ((2*WIDTH/(n-1)) < 0.5) {	/* Do we have enough space for this? */
		erralert("FFTView","View isn't large enough");
		return self;
	}

/* Change the cursorpoint location to reflect the change in FFT resolution.
 * (pixel location change will be handled by drawSelf::)
 */
	if (npoints)
 		cursorpoint *= n/npoints;

        npoints = n;

        if (coefs)
                free(coefs);
        coefs = (float *)malloc(npoints * sizeof(float));
	if (scoefs)
		free(scoefs);
	scoefs = (float *)malloc(npoints * sizeof(float));

/* The PSdata[] and PSops[] arrays are for the graphics -- PSdata will
 * hold the pixel coordinates of the data, and PSops[] is just an
 * initial moveto followed by a bunch of linetos.  These arrays are
 * passed to DPSDoUserPath() to draw the series of line segments.
 * See the 'Lines' demo and /usr/include/dpsclients/dpsNeXT.h for more
 * info on DPSDoUserPath().
 */
	if (PSdata)
		free(PSdata);
	PSdata = (float *)malloc(npoints * sizeof(float));
	if (PSops)
		free(PSops);
	PSops = (char *)malloc((N = npoints/2));
	PSops[0] = dps_moveto;
	for (i = 1; i < N; i++)
		PSops[i] = dps_lineto;

	needsFFT = needsScaling = validData = NO;
	if (sframe = getframe(sound,startsamp,npoints))
		needsFFT = validData = YES;

        return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setInskip: -- Set start time of FFT window
 */
- setInskip:(float)t
{
        inskip = t;
	startsamp = inskip * srate;
	needsFFT = needsScaling = validData = NO;
	if (sframe = getframe(sound,startsamp,npoints))
		needsFFT = validData = YES;
        return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* advanceFrame: -- Advance by one frame of data
 * This can be used to do animations.  Also can be invoked by actioncell
 */
- advanceFrame:sender
{
	startsamp += npoints;
        if (startsamp > ([sound sampleCount] - npoints))
                startsamp = [sound sampleCount] - npoints;
	inskip = startsamp / srate;
	needsFFT = needsScaling = validData = NO;
	if (sframe = getframe(sound,startsamp,npoints))
		needsFFT = validData = YES;
	[self display];		/* This method does own display */
	return self;
}
/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* dBdisplay: -- Turn on/off dB display
 */
- dBdisplay:(BOOL)flag
{
	dBflag = flag;
	needsScaling = YES;	/* Force new scaling of display */
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* sound -- Returns pointer to attached sound
 */
- sound
{
	return sound;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* (int)npoints -- Returns size of FFT window
 */
- (int)npoints
{
        return npoints;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* (float)inskip -- Returns start time of FFT window
 */
- (float) inskip
{
        return inskip;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* dBdisplay -- returns dBflag
 */
- (BOOL) dBdisplay
{
	return dBflag;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* getCursorFreq:Amp: -- Retrieves frequency/amplitude data at current
 *			 cursor location
 * Arguments are pointers to floats where data is to go.
 * This method interpolates between data points.
 */
- getCursorFreq:(float *)freq Amp:(float *)amp
{
	int i;
	float fractpoint;

	if (!sound) {
		*freq = *amp = 0;
		return self;
	}

	*freq = cursorpoint * freqBW;

/* Do a simple linear interpolation between data points in coefs[] array
 */
	i = (int)cursorpoint;		/* Integer portion of cursor point */
	fractpoint = cursorpoint - i;	/* Fraction portion */
	*amp = ((scoefs[i+1]-scoefs[i]) * fractpoint) + scoefs[i];

	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setCursorFreq: -- Set the position of the cursor
 * Argument is a frequency to set cursor to.  This method does
 * all translation necessary.
 */
- setCursorFreq:(float)freq
{
	if (!sound)
		return self;

/* Interpret frequency as a point (with possible interpolation), then
 * convert that to a pixel column and draw it.
 */
	cursorpoint = freq / (freqBW);
	DOCURSOR();
	cursorpixel = cursorpoint * pixelBW;
	DOCURSOR();

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

/* needsFFT: -- Set/reset needsFFT flag
 */
- needsFFT:(BOOL)flag
{
        needsFFT = flag;
        return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* needsFFT -- Return value of needsFFT flag
 */
- (BOOL)needsFFT
{
        return needsFFT;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* drawSelf:: -- Do the FFT (if necessary) and draw it
 * This method called via 'display' method.
 */

- drawSelf:(NXRect *)rects :(int)rectCount
{
        static float maxamp;	/* Peak amp in coefs[] */
        float xincr,yscale;	/* Graphics scaling parameters */
        int N = npoints/2;      /* For display purposes */
        int maxfreq;            /* Top freq in display (in KHz) */
        float KHzincr;		/* pixel columns per KHz */
        int i;
	float *inp, *outp;	/* Pointer to coefs/scoefs (for speed) */
	float bbox[4];
	float *fptr;

/* First, erase what we have now.  If there's no data (i.e., if
 * validData == NO), that's all there is to it.
 */
        NXEraseRect(&bounds);
        if (!validData)
                return self;

/* If we need to do a new FFT, then let's do it
 */
        if (needsFFT) {
                fft(FORWARD, npoints, RECTANGULAR,	/* See fft_net.c for info */
                   sframe, REAL, LINEAR,
                   coefs, MAG, LINEAR);
		needsFFT = NO;
		needsScaling = YES;
	}

/* If we need to rescale data, then do that, too
 */
	if (needsScaling) {
		if (!dBflag)
			maxamp = scaledata(coefs,scoefs,npoints,0,NULL);
		else
			maxamp = scaledata(coefs,scoefs,npoints,dBMASK,NULL);
		needsScaling = NO;
        }

/* Set scaling factors: 
 * xincr = pixel columns per data point (= pixelBW).
 * yscale = multiplier to plot maximum amplitude at top of box.
 * maxfreq and KHzincr are for the KHz ruler.
 */
        xincr = WIDTH/(N-1);
        yscale = (maxamp > 0) ? (bounds.size.height-20)/maxamp : 1;
        maxfreq = srate/2000;    	/* max frequency in KHz */
        KHzincr = WIDTH/maxfreq;	/* columns between KHz */

/* Fill the PSdata[] array with the coordinates for the plot,
 * and set the bounding box to the size of our view.  The
 * plot of the data will be done via a DPSDoUserPath() call,
 * which is the zippiest way to do such things.
 */

	for (i = 0,fptr = PSdata; i < N; i++) {
		*fptr++ = xincr * i;		/* X coord */
		*fptr++ = scoefs[i] * yscale;	/* Y coord */
	}
	bbox[0] = 0;
	bbox[1] = 0;
	bbox[2] = bounds.origin.x + bounds.size.width + 1;
	bbox[3] = bounds.origin.y + bounds.size.height + 1;

        PSgsave();
        PStranslate(0,20);              /* To save room for ruler */
	PSsetgray(0.0);
	DPSDoUserPath(PSdata,npoints,dps_float,PSops,N,bbox,dps_ustroke);
        PSgrestore();
        PWdrawruler(0,maxfreq,1,KHzincr);

/* Re-figure the cursor's pixel location here, since this might
 * be a response to a window resizing.
 */
	cursorpixel = cursorpoint * xincr;
        DOCURSOR();

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
	float pbw = pixelBW;	/* Local copy of pixelBW */

	if (!sound)
		return self;

/* Ask for mousedragged and mouseup events only for the duration
 * of this method.
 */
        oldMask = [[self window] addToEventMask:DRAG_MASK];

/* For the initial mousedown event and all subsequent mousedragged events,
 * update the cursor as necessary and send a cursorMoved: message to
 * the delegate.
 */
        do {
                p = event->location;
                [self convertPoint:&p fromView:nil];
		if (p.x < 0.0)
			p.x = 0.0;
		if (p.x > WIDTH)
			p.x = WIDTH;
                if (cursorpixel != p.x) {

		/* Draw the cursor:
		 */
                        [self lockFocus];
                        DOCURSOR();		/* This unhighlights the old */
                        cursorpixel = p.x;
                        DOCURSOR();		/* This highlights the new */
                        [self unlockFocus];
                        [[self window] flushWindow];
                        NXPing();

			cursorpoint = cursorpixel / pbw;
			if (delegate && 
			    [delegate respondsTo:@selector(cursorMoved:)])
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
