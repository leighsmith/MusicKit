/*
 *  Animator.m
 *  Object for general timing, animation, and dynamics.
 *  Author: R. E. Crandall, Educational Technology Center
 *  10-APR-88
 */
 
 /* revised 9/29/88 bmb for 0.8 */
 /* 04/26/90/mtm	 Fixed compiler warnings. */
 /* 06/19/90/mdm	 Fixed more compiler warnings. */
 /* 10/10/90/david jaffe Updated for 2.0 */

/*
 *  An 'Animator' controls the timing for your action method of choice.
 *  The object may function as a general timer object; i.e.
 *  graphics are neither expected nor required by the class.
 *  When you init an Animator, you specify
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

/* This could be rewritten to use the Music Kit Conductor. 
 */
   

#include <appkit/appkit.h>
#include <sys/time.h>
#include <objc/objc-runtime.h>
#import "Animator.h"
@implementation Animator

void TimerFunc(teNum,now,self)
int	teNum;
double	now;
Animator* self;
{
    gettimeofday(&self->entrytime,&self->tzone);
    if(self->howOften > 0.) [self adapt];
    [self->target perform:self->action with:self];
}
 
- initChronon: (double) dt	/* The time increment desired. */
	adaptation:(double)howoft  /* Adaptive time constant (0.deactivates).*/
	target: (id) targ	/* Target to whom proc belongs. */
	action: (SEL) act	/* The action. */
	autoStart: (int) start	/* Automatic start of timed entry? */
	eventMask: (int) eMask  /* Mask for optional check in "shouldBreak". */
{
    [super init];
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
    gettimeofday(&realtime,&tzone);
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
    NXEvent *e, eBuffer;
    e = [NXApp peekNextEvent:mask
        into:&eBuffer
        waitFor:0.0
        threshold:NX_BASETHRESHOLD];
    if (e == NULL)
   	return 0;
    else
   	return 1;
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
    return self;
}

- setAction:(SEL) aSelector
{
    action = aSelector;
    return self;
}

- startEntry
{ 
    [self stopEntry];
    teNum =(int)DPSAddTimedEntry(interval, (DPSTimedEntryProc)TimerFunc,
				 self, NX_MODALRESPTHRESHOLD+5);
    ticking = YES;
    return self;
}

- stopEntry
{
    if (ticking) 
	DPSRemoveTimedEntry((DPSTimedEntry)teNum);
    ticking = NO;
    return self;
}

- free
{
    if (ticking)
	DPSRemoveTimedEntry((DPSTimedEntry)teNum);
    return [super free];
}
@end	

