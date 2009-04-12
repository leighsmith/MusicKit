/*
 *  Animator8.m
 *  Object for general timing, animation, and dynamics.
 *  Copyright 1988 NeXT, Inc.  All Rights Reserved.
 *  Author: R. E. Crandall, Educational Technology Center
 *  10-APR-88
 */
 
 /* revised 9/29/88 bmb for 0.8 */
 /* 04/26/90/mtm	Fixed compiler warnings. */
 /* 06/19/90/mdm	Fixed more compiler warnings. */
 /* 10/08/90/daj	Flushed cvtToSel */

/*
 *  An 'Animator' controls the timing for your action method of choice.
 *  The object may function as a general timer object; i.e.
 *  graphics are neither expected nor required by the class.
 *  When you create an Animator with +newChronon, you specify
 *  the time interval between calls, the adaptation time constant (see below),
 *  the target to which the method belongs, the action name, whether to 
 *  automatically start up the timing upon creation, and an event mask (if you 	
 *  plan to break conditionally out of loops within the action method.
 *
 *  The Animator has adaptive means for adjusting to harsh operating
 *  environments.  An adaptation constant d > 0. will invoke dynamical 
 *  correction of entry times, on-the-fly, so that the desired chronon
 *  will be realized in a real-time sense.
 *
 *  Functionality and applications are discussed in Report ETC-0008.
 */

#include <AppKit/AppKit.h>
#include <sys/time.h>
#import "Animator.h"

@implementation Animator

- (void) timerFunc:(NSTimer *)teNum
{
  gettimeofday(&entrytime,&tzone);
  if(howOften > 0.) [self adapt];
  [target performSelector:action withObject:self];
}
 
+ newChronon: (double) dt	/* The time increment desired. */
	adaptation:(double)howoft  /* Adaptive time constant (0.deactivates).*/
	target: (id) targ	/* Target to whom proc belongs. */
	action: (SEL) act	/* The action. */
	autoStart: (int) start	/* Automatic start of timed entry? */
	eventMask: (int) eMask  /* Mask for optional check in "shouldBreak". */
{
  Animator *newObj = [super new];
  newObj->ticking = NO;
  newObj->desireddt = dt;
  [newObj setIncrement:dt];
  [newObj setAdaptation:howoft];
  [newObj setTarget:targ];
  [newObj setAction:act];
  if(start) [newObj startEntry];
  newObj->mask = eMask;
  [newObj resetRealTime];
  return newObj;
}

- (void)resetRealTime { 
/* After this call, getDoubleRealTime is the real time that ensues. */
	gettimeofday(&realtime,&tzone);
	synctime = realtime.tv_sec + realtime.tv_usec/1000000.0;
	passcounter = 0;
	t0 = 0.0; 
}

- (double) getSyncTime {
	return(synctime);
}

- (double) getDoubleEntryTime {
/* Returns real time since "resetrealTime". */
	return(- synctime + entrytime.tv_sec + entrytime.tv_usec/1000000.0);
}

- (double) getDoubleRealTime {
/* Returns real time since "resetrealTime". */
	gettimeofday(&realtime,&tzone);
	return(- synctime + realtime.tv_sec + realtime.tv_usec/1000000.0);
}

- (double) getDouble {
	return([self getDoubleRealTime]);
}

- (void)adapt {
/* Adaptive time-step algorithm. */
  double t;
  if(!ticking) return;
  ++passcounter;
  t = [self getDoubleEntryTime];
  if(t - t0 >= howOften) {  	
  	adapteddt *= desireddt*passcounter/(t - t0);
	[self setIncrement:adapteddt];
	[self startEntry];
	passcounter = 0;
	t0 = t;
  } 
}
  
- (void)setBreakMask:(int)eventMask {
  mask = eventMask; 
}

- (int) getBreakMask {
  return(mask);
}

- (int) isTicking {
  return(ticking);
}
   
- (int) shouldBreak  {
/* Call this to see if you want to exit a loop in your action method. */
   NSEvent *e, *eBuffer;
   
    e = (eBuffer = [NSApp nextEventMatchingMask:mask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.0] inMode:NSEventTrackingRunLoopMode dequeue:NO]);
   if (e == NULL)
   	return 0;
   else
   	return 1;
}

- (void)setIncrement:(double)dt {
  adapteddt = dt;
  interval = dt; 
}

- (double) getIncrement {
  return(adapteddt);
}

- (void)setAdaptation:(double)oft {
  howOften = oft; 
}

- (void)setTarget:(id)targ {
  target = targ;
}

- (void)setAction:(SEL)aSelector
{
    action = aSelector;
}

- (void)startEntry
{ 
  [self stopEntry];
//#error DPSConversion: DPSAddTimedEntry is obsolete.  Use the NSTimer class instead:
// [[NSTimer timerWithTimeInterval:interval target:<target> selector:TimerFunc userInfo:self repeats:YES] retain].  <target> should be an objects that implements method ([aTarget TimerFunc:timer])
    [teNum release];
    teNum = [[NSTimer timerWithTimeInterval:interval
                                     target:self
                                   selector:@selector(timerFunc)
                                   userInfo:self
                                    repeats:YES] retain];
//  teNum =(int)DPSAddTimedEntry(interval, (DPSTimedEntryProc)TimerFunc, self, NSModalResponseThreshold+5);
  ticking = YES; 
}

- (void)stopEntry
{
  if (ticking) {
    [teNum invalidate];
    [teNum release];
    teNum=nil;
  }
  ticking = NO; 
}

- (void)dealloc
{
  if(ticking) {
    [teNum invalidate];
    [teNum release];
  }  
  [super dealloc];
}
@end	

