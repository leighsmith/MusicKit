/* Stopwatch.m -- Implementation for Stopwatch class.
 *
 * See Stopwatch.h for details.
 * 
 * jwp@silvertone.Princeton.edu, 11/89
 * Version 1.2, 1/90
 * 	-- changed name of panel updating function
 * Version 1.21, 2/90
 *	-- Fixed bug that kept Stopwatch from starting plays
 */

#import "Stopwatch.h"
#import "Animator.h"
#import "UpPanel.h"

#import <appkit/appkit.h>
#import <appkit/TextField.h>
#import <appkit/Button.h>

#define ST_START 1	/* startButton state 1 = "start" */
#define ST_STOP  0	/* startButton state 0 = "stop" */

@implementation Stopwatch

/* +new -- Create an instance.
 * 	In addition to the normal stuff, this loads the .nib file
 *	and initializes the Animator.
 */

+ new
{	
  self = [super new];
  [NXApp loadNibSection:"Stopwatch.nib" owner:self];
  myAnimator = [Animator  newChronon: 0.1
			  adaptation: 3.0				
			  target: self
			  action: @selector(animate:)
			  autoStart: NO
			  eventMask: NX_ALLEVENTS];
  [panel setUpdateAction:@selector(panelUpdate:) by:NXApp];
  [panel setDelegate:self];
  return self;
}

/* startPressed: -- Respond to start/stop button press
 *	Action taken depends on state of button.  This message should
 *	not be sent by an external object, only by the start/stop button.
 *	To simulate Start/Stop button behavior, use performStart:/Stop:
 *	methods.
 */
#define DELSTART @selector(stopwatchWillStart:)	/* Shorthand for delegate   */
#define DELSTOP  @selector(stopwatchDidStop:)	/* 	selectors ...	    */

- startPressed:sender 
{
	if ([sender state] == ST_START)	{
		[[lapTimeField setStringValue: ""] display];
		if (delegate && [delegate respondsTo:DELSTART])
			[delegate perform:DELSTART with:self];
		if (target != nil)
			[target perform:startAction with:self];
		[[myAnimator startEntry] resetRealTime];
	}
	else {
		[myAnimator stopEntry];
		if (target != nil)
			[target perform:stopAction with:self];
		if (delegate && [delegate respondsTo:DELSTOP])
			[delegate perform:DELSTOP with:self];
	}
	return self;
}

/* performStart -- simulate start button press
 * performStop  -- simulate stop button press
 *	These messages can be sent by any object.  They cause the
 *	start/stop button to "press itself".  These methods thus
 *	allow external control of the watch.
 */
- performStart:sender
{
	if ([startButton state] == ST_STOP) {
		[panel orderFront:self];	/* Be sure we can see panel */
		[startButton performClick:self];
	}
	return self;
}

- performStop:sender
{
	if ([startButton state] == ST_START)
		[startButton performClick:self];
	return self;
}


/* lapPressed: -- respond to lap button press
 *	Displays current time in lap time field.  This message can
 *	be sent by any object.
 */
- lapPressed:sender 
{
	char str[64];		/* For sprintf'd time */

	sprintf(str,"%8.3f",(float)[myAnimator getDoubleEntryTime]);
	[[lapTimeField setStringValue: str] display];
	return self;
}

/* setTarget:toStart:andStop -- Link watch with another object
 * start and stop actions must be implemented on target object and
 * should return immediately.  They must take 'sender' as their only
 * argument.
 */
- setTarget:anObject toStart:(SEL)beginAction andStop:(SEL)endAction
{
	target = anObject;
	startAction = beginAction;
	stopAction = endAction;
	return self;
}


/* (BOOL) isRunning -- query the status of the watch
 */
- (BOOL) isRunning
{
	return [myAnimator isTicking];
}

/* panel -- returns pointer to Stopwatch panel
 */
- panel
{
	return panel;
}

/* delegate -- returns pointer to delegate
 */
- delegate
{
	return delegate;
}


/* -animate: -- response to Animator timed entry.
 *	Prints the elapsed time in the proper text field.
 */
- animate: sender 
{
	char str[64];		/* sprintf'd time value goes here */

	sprintf(str,"%8.3f",(float)[myAnimator getDoubleEntryTime]);
	[[timeField setStringValue: str] display];
	return self;
}	


/* windowWillClose: -- delegate method for panel
 *	Stops the watch before panel disappears
 */
- windowWillClose:sender
{
	[self performStop:self];
	return self;
}


/* Stuff for Interface Builder
 */
- setPanel:anObject
{
	panel = anObject;
	return self;
}
- setTimeField:anObject
{
	timeField = anObject;
	return self;
}
- setLapTimeField:anObject
{
	lapTimeField = anObject;
	return self;
}
- setStartButton:anObject
{
	startButton = anObject;
	return self;
}
- setLapButton:anObject
{
	lapButton = anObject;
	return self;
}

- setDelegate:anObject
{
/* Test validity of this object as a delegate NOW, so we can save
 * a little time later.
 */
	if ([anObject respondsTo:@selector(stopwatchWillStart:)] ||
	    [anObject respondsTo:@selector(stopwatchDidStop:)])
		delegate = anObject;
	return self;
}

@end	

