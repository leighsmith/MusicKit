/* Stopwatch.h -- Interface for Stopwatch class
 *
 * This is an object for general purpose timing display.  It consists
 * of a panel with two fields to display elapsed time and lap time,
 * along with two buttons:  Start/Stop (toggle) and Lap.
 * This object makes use of the Animator class to handle the timing
 * functions.  The Start/Stop button starts the timer from 0.0 and
 * stops it.  The Lap button displays the current elapsed time in
 * the lap time field.  The effects of the buttons can be simulated
 * by messages, as well.  Since the Start/Stop button is a toggle,
 * special messages 'performStop' and 'performStart' are necessary
 * (the 'lapPressed' message can be sent by any object).
 * This object has an optional delegate that can receive a
 * 'stopwatchWillStart:' and/or a 'stopwatchDidStop:' message. 
 * A target object and an action that that target can perform
 * can be specified, thus allowing another object to use
 * the stopwatch to time its actions.
* The panel used is an UpPanel, so that the watch can be stopped by
 * a change in the application's status.
 *
 * jwp@silvertone.Princeton.edu, 11/89
 * Version 1.2, 1/90
 */

#import <objc/Object.h>

@interface Stopwatch : Object
{
    id  panel;			/* The panel this displays in */
    id	timeField;		/* Time display fields */
    id  lapTimeField;
    id  startButton;		/* The buttons */
    id  lapButton;
    id  delegate;		/* Receives willStart: and didStop: */
    id  myAnimator;		/* This handles the timing.  */
    id  target;			/* Object that we're timing */
    SEL  startAction;		/* Start up an process */
    SEL  stopAction;		/* Stop the process */
}

/* CLASS METHODS
 *
 * +new -- create and initialize a new instance
 */
+ new;

/* INSTANCE METHODS
 *
 * Methods to respond to button presses or simulate button presses:
 *	- startPressed:		-- Start or stop watch (response to button)
 *	- performStart		-- Start watch (response to other object)
 *	- performStop		-- Stop watch  (response to other object)
 *	- lapPressed:		-- Display lap time
 */
- startPressed:sender;
- performStart:sender;
- performStop:sender;
- lapPressed:sender;

/* Methods to modify and query the object
 *	- setTarget:toStart:andStop:  -- Set the object/action we're timing
 *	- (BOOL)isRunning	-- Is the watch running?
 *	- panel			-- Access to stopwatch panel
 *	- delegate		-- Access to stopwatch delegate
 */
- setTarget:anObject toStart:(SEL)beginAction andStop:(SEL)endAction;
- (BOOL) isRunning; 
- panel;
- delegate;

/* Delegate methods
 *	For Animator:
 *		- animate:	   -- updates elapsed time display
 *	For Panel:
 *		- windowWillClose  -- Shuts off clock
 */
- animate:sender;
- windowWillClose:sender;

/* Methods to initialize object (needed by IB)
 */
- setPanel:anObject;
- setTimeField:anObject;
- setLapTimeField:anObject;
- setStartButton:anObject;
- setLapButton:anObject;
- setDelegate:anObject;

@end
