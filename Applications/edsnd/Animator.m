//  Animator.m
//  Object for general timing, animation, and dynamics.
//  Author: R. E. Crandall, Educational Technology Center
//  10-Apr-88
//  Revised by Bluce Blumberg for 0.8, 29-Sep-88
//  Revised for 1.0 by Ali Ozer, 13-Jun-89

 
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

#import "Animator.h"

@implementation Animator

void TimerFunc(teNum,now,self)
DPSTimedEntry teNum;
double now;
id self;
{
  gettimeofday(&self->entrytime,NULL);
  if (self->howOften > 0.) [self adapt];
  [self->target perform:self->action with:self];
}
 
+ newChronon: (double) dt	/* The time increment desired. */
	adaptation:(double)howoft  /* Adaptive time constant (0.deactivates).*/
	target: (id) targ	/* Target to whom proc belongs. */
	action: (SEL) act	/* The action. */
	autoStart: (int) start	/* Automatic start of timed entry? */
	eventMask: (int) eMask  /* Mask for optional check in "shouldBreak". */
{
  self = [super new];
  ticking = NO;
  desireddt = dt;
  [self setIncrement: dt];
  [self setAdaptation: howoft];
  [self setTarget: targ];
  [self setAction: act];
  if(start) [self startEntry];
  mask = eMask;
  [self resetRealTime];
  return self;
}

- resetRealTime { 
/* After this call, getDoubleRealTime is the real time that ensues. */
	struct timeval realtime;

	gettimeofday(&realtime,NULL);
	synctime = realtime.tv_sec + realtime.tv_usec/1000000.0;
	passcounter = 0;
	t0 = 0.0;
	return self;
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
	struct timeval realtime;
	struct timezone tzone;

	gettimeofday(&realtime,&tzone);
	return(- synctime + realtime.tv_sec + realtime.tv_usec/1000000.0);
}

- (double) getDouble {
	return([self getDoubleRealTime]);
}

- adapt {
/* Adaptive time-step algorithm. */
  double t;
  if(!ticking) return self;
  ++passcounter;
  t = [self getDoubleEntryTime];
  if(t - t0 >= howOften) {  	
  	adapteddt *= desireddt*passcounter/(t - t0);
	[self setIncrement: adapteddt];
	[self startEntry];
	passcounter = 0;
	t0 = t;
  }
  return self;
}
  
- setBreakMask : (int) eventMask {
  mask = eventMask;
  return self;
}

- (int) getBreakMask {
  return(mask);
}

- (int) isTicking {
  return(ticking);
}
   
- (int) shouldBreak  {
/* Call this to see if you want to exit a loop in your action method. */
   int   found;
   NXEvent *e, event;
   e = [NXApp peekNextEvent:mask into:&event 
	      waitFor:0.0 threshold:NX_BASETHRESHOLD];
   return(e ? 1: 0);
}

- setIncrement: (double) dt {
  adapteddt = dt;
  interval = dt;
  return self;
}

- (double) getIncrement {
  return(adapteddt);
}

- setAdaptation: (double) oft {
  howOften = oft;
  return self;
}

- setTarget: (id) targ {
  target = targ;
}

- setAction:(SEL) aSelector
{
    action = 
    aSelector && !ISSELECTOR(aSelector) ? (*_cvtToSel) (aSelector) : aSelector;
    return self;
}

- startEntry
{ 
  [self stopEntry];
  teNum = DPSAddTimedEntry(interval,&TimerFunc,self,NX_BASETHRESHOLD);
  ticking = YES;
  return self;
}

- stopEntry
{
  if (ticking) DPSRemoveTimedEntry(teNum);
  ticking = NO;
  return self;
}

- free
{
  if (ticking) DPSRemoveTimedEntry(teNum);
  return [super free];
}

@end	
