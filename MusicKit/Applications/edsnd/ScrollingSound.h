/* ScrollingSound.h -- interface for the ScrollingSound class
 * 
 * This is a custom ScrollView that contains an EdSoundView.  Does following:
 *	1) Performs all ScrollView functions
 *	2) Acts as translator to form graphics commands from user timing
 *	   inputs.
 *
 * Original code by Lee Boynton
 * Revision by James Pritchett, 10/89
 * Version 1.01, 11/89
 *	-- added support for EdSoundView
 * Version 1.1,  12/89
 *	-- added sizeToSelection: method
 * Version 1.2, 1/90
 *	-- Changed setReductionFactor: to setRfact:
 */
 
#import <appkit/ScrollView.h>

@interface ScrollingSound : ScrollView
{
	id delegate;		/* Delegate for displayChanged: messages */
	id view;		/* EdSoundView for this object */
	float rfact;		/* Reduction factor of EdSoundView */
	float srate;		/* Sampling rate of Sound */
}


/* CLASS METHODS
 *
 * newFrame: -- creates a new ScrollingSound
 */
+ newFrame:(NXRect const *)theFrame;


/* INSTANCE METHODS
 *
 * Methods to set up the object:
 * 	setDelegate:		-- Set the delegate for this object
 *	setView:		-- Set the EdSoundView for this object
 *	setSound:		-- Attach a Sound object to the EdSoundView
 *	setRfact:		-- Set the reduction factor of the EdSoundView
 */
- setDelegate:anObject;
- setView:anObject;
- setSound:aSound;
- setRfact:(float)rf;

/* Methods to retrieve information about the object:
 * 	delegate		-- Get the delegate for this object
 *	view			-- Get the EdSoundView for this object
 */
- delegate;
- view;

/* Methods to get time information about the sound, display, and selection
 * 	duration		-- Get the duration of the Sound object
 * 	getStart:Size:		-- Get the start time and size of display
 * 	getSelStart:Size:	-- Get the start time and size of selection
 */
- (float)duration;
- getStart:(float *)stptr Size:(float *)sizptr;
- getSelStart:(float *)stptr Size:(float *)sizptr;

/* Methods to set display and selection by timings
 *	setStart:		-- Set the start time of display
 *	setSize:		-- Set the duration of display
 * 	setSelStart:Size:	-- Set the start time and size of selection
 *	sizeToSelection:	-- Set start/size of display to current
 *				   selection start/size (i.e., zoom)
 */

- setStart:(float)start;
- setSize:(float)size;
- setSelStart:(float)start Size:(float)size;
- sizeToSelection:sender;

/* Methods to replace normal ScrollView methods:
 * 	reflectScroll:		-- Handle a user scroll event
 */
- reflectScroll:sender;

@end
