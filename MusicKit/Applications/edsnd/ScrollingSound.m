/* ScrollingSound.m -- Implementation of ScrollingSound class
 *
 * Original code by Lee Boynton
 * Revision by James Pritchett, 10/89
 * Version 1.01, 11/89 
 *	-- tidied code, added support for EdSoundView
 * Version 1.1,  12/89
 *	-- Added sizeToSelection:
 * Version 1.2, 1/90
 *	-- Fixed bug that caused selection to get screwed up when changing
 *	   reduction factor
 */
 
#import "ScrollingSound.h"
#import "EdSoundView.h"
#import <appkit/Application.h>
#import <appkit/Cursor.h>


@implementation ScrollingSound

/* newFrame: -- create a new ScrollingSound.  This method overrides
 * 	the standard newFrame: for a ScrollView.  It creates a new
 *	ScrollView, creates a new EdSoundView, and sets the EdSoundView
 *	as the ScrollView's docView.  Also sets various ScrollView
 *	parameters.
 */
+ newFrame:(NXRect const *)theFrame	/* theFrame = coordinates of
					 * ScrollView frame
					 */
{
    NXRect tempRect = *theFrame;	/* Size of content area goes here */
    id sndview;				/* The SoundView for this object */
    int borderType = NX_LINE;		/* Border type of ScrollView */


/* Figure the content size of the ScrollView and create a SoundView
 * with this size.
 */
    [ScrollView getContentSize:&tempRect.size forFrameSize:&theFrame->size
    		horizScroller:YES vertScroller:NO borderType:borderType];
    sndview = [EdSoundView newFrame:&tempRect];

/* Create the ScrollView using the newFrame:  method and set all the
 * parameters.
 */
    self = [super newFrame:theFrame];	  /* Use the ScrollView newFrame: */
    [self setBorderType:borderType];
    [self setHorizScrollerRequired:YES];
    [self setDynamicScrolling:YES];	  /* What does this do? */
    [self setView:sndview];
    [self setBackgroundGray:NX_WHITE];
    [self setAutoresizeSubviews:YES];
    [self setAutosizing:NX_WIDTHSIZABLE|NX_HEIGHTSIZABLE];
    [self setSound:[Sound new]];
    [sndview setReductionFactor:50.0];
    rfact = 50.0;
    [[sndview superview] setAutoresizeSubviews:YES];
    [sndview setAutosizing:NX_HEIGHTSIZABLE];
    return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setDelegate -- Set a delegate for this ScrollingSound.
 * 	The delegate can receive the displayChanged: message to handle
 *	any scrolling events.
 */
- setDelegate:anObject		/* anObject = delegate */
{
	delegate = anObject;
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setView: -- Change the attached EdSoundView
 * 	Argument is a pointer to an EdSoundView object.
 */
- setView:aSoundView
{
	if (view)
		[view free];
	view = aSoundView;
	[self setDocView:view];
	return self;
}
	
/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setSound: -- Attach a Sound object to the EdSoundView
 *	Argument is pointer to Sound object.  Never change the sound
 *	any other way, since this is how the ScrollingSound keeps
 *	track of the sampling rate.
 */
- setSound:aSound
{
	if ([view sound])
		[[view sound] free];
	[view setSound:aSound];
	srate = [aSound samplingRate];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setRfact: -- Change the reduction factor in the EdSoundView.
 *	Argument is a float.  Never change the reduction factor any other
 *	way, since the ScrollingSound has to keep track of it for
 *	various other methods.  This method also keeps the selection
 *	intact when changing scales (that it wouldn't otherwise is
 *	probably a bug in SoundView?)
 */
- setRfact:(float)rf
{
	int start,size;

	[view getSelection:&start size:&size];
	rfact = rf;
	[view setReductionFactor:rf];
	[view setSelection:start size:size];

	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* delegate -- Returns the delegate of this object
 */
- delegate
{
	return delegate;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* view -- Returns the EdSoundView of this object
 */
- view
{
	return view;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* duration -- Get the duration of the Sound object
 *	Returns a float.
 */
- (float)duration
{
	if (srate == 0)
		return 0;
	else
		return [[view sound] sampleCount] / srate;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* getStart:Size: -- Get the start time and size of the display
 * 	Arguments are pointers to floats.
 */
- getStart:(float *)stptr Size:(float *)sizptr
{
	NXRect aRect;			/* dimensions of visible view */

/* If this is a new Sound object with no data (and hence no sampling
 * rate), just return zeroes
 */
	if (srate == 0) {
		*stptr = *sizptr = 0;
		return self;
	}

/* Get the graphic dimensions of the currently visible portion of the
 * EdSoundView and convert those graphic coordinates to times.
 */
	[self getDocVisibleRect:&aRect];
	*stptr  = aRect.origin.x   * rfact / srate;
	*sizptr = aRect.size.width * rfact / srate;
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* getSelStart:Size: -- Get the start time and size of the current selection.
 * 	Arguments are pointers to floats.
 */
- getSelStart:(float *)stptr Size:(float *)sizptr
{
	int startsamp;			/* First sample of selection */
	int nsamps;			/* Samples in selection */

	if (srate == 0) {
		*stptr = *sizptr = 0;
		return self;
	}

/* The EdSoundView returns the selection start and size in samples,
 * which are then converted to timings.
 */
	[view getSelection:&startsamp size:&nsamps];
	*stptr =  startsamp / srate;
	*sizptr = nsamps    / srate;
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setStart: -- Change the start time of the display
 *	Argument is a float.
 */
- setStart:(float)start
{
	NXRect aRect;			/* Visible part of SoundView */
	float oldstart,size,dur;

	if (srate == 0)
		return self;

/* Get the coordinates of the visible part of the EdSoundView,
 * change its origin, and force a scroll.
 */
	[self getDocVisibleRect:&aRect];
	[self getStart:&oldstart Size:&size];
	dur = [self duration];		/* dur = duration of file */
	if (start > dur-size)		/* Don't scroll past end of sound */
		start = dur-size;

	aRect.origin.x = start * srate / rfact;
 	[view scrollRectToVisible:&aRect];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setSize:  -- Change the duration of the display.
 * 	Argument is a float.  The change in duration is accomplished by
 *	changing the reduction factor while keeping the graphic
 *	size of the EdSoundView constant.
 */
- setSize:(float)size
{
	NXRect aRect;			/* Visible part of SoundView */

	if (srate == 0)
		return self;

/* Get the width of the display and calculate the new reduction factor
 * needed to fit the requested duration within that size.
 */
	[self getDocVisibleRect:&aRect];
	rfact = size * srate / aRect.size.width;
	if (rfact < 1)		/* rfact can't be < 1 */
		rfact = 1;
	[self setRfact:rfact];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* setSelStart:Size: -- Set the start time and duration of selection
 *	Arguments are floats.
 */
- setSelStart:(float)start Size:(float)size
{
	int startsamp;		/* Starting sample of selection */
	int nsamps;		/* Size of selection in samples */

	if (srate == 0)
		return self;

/* Convert timings to samples and set the selection
 */
	startsamp = start * srate;
	nsamps = size * srate;
	[view setSelection:startsamp size:nsamps];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* sizeToSelection: -- Set the display start/size to the start/size of
 *			current selection.
 * This is, in effect, a "zoom" action, and can be connected to an
 * action cell.
 */
- sizeToSelection:sender
{
	float selstart, selsize;

	[self getSelStart:&selstart Size:&selsize];
	if (!selsize)
		return self;
	[NXWait set];
	NXPing();
	[self setSize:selsize];
	[self setStart:selstart];
	[NXArrow set];
	NXPing();

/* Be sure to notify the delegate that our display changed
 */
	if (delegate && [delegate respondsTo:@selector(displayChanged:)])
		[delegate perform:@selector(displayChanged:) with:self];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* reflectScroll: -- handle a change in the relationship between
 *	the contentView and the docView.  This method overrides
 *	the standard ScrollView method so as to send a displayChanged:
 *	message to the delegate.
 */
- reflectScroll:sender
{	
	[super reflectScroll:sender];		/* Do the default actions */
	if (srate == 0)
		srate = [[view sound] samplingRate];
	if (delegate && [delegate respondsTo:@selector(displayChanged:)])
		[delegate perform:@selector(displayChanged:) with:self];
	return self;
}

@end
