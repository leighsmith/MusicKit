/*
  $Id$
  Defined In: The MusicKit

  Description:
    This file factored out of MKConductor.m for purposes of separate copyright and
    to isolate MIDI time code functions.
    This file contains public methods and support functions.

  Original Author: David Jaffe

  Copyright (c) Pinnacle Research, 1993
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2003 The MusicKit Project.
*/
#import "_musickit.h"
#import "_MTCHelper.h"
#import <MKPerformSndMIDI/PerformMIDI.h>
#import "ConductorPrivate.h"
#import "MidiPrivate.h"

static MKConductor *theMTCCond = nil;
static double mtcPollPeriod = _MK_DEFAULT_MTC_POLL_PERIOD; /* In seconds */
static double MTCTime /*,sysTime */;
static NSDate *sysTime;

static _MTCHelper* mtcHelper = nil;
static int mtcStatus;

#if !_MK_ONLY_ONE_MTC_SUPPORTED
#warning "Incomplete implementation of multiple MTC conductors."
#endif

/* All occurances of theMTCCond would need to be replaced by a more involved
 * mechanism were we to support multiple MTC conductors. */

#define MTC_UNDEFINED 0
#define MTC_STOPPED 1
#define MTC_FORWARD 2
#define MTC_REVERSE 3

#define SEEK_THRESHOLD 1.0  /* If a time difference this big or bigger occurs, seek */

@implementation MKConductor(MTCPrivate)

void resetMTCTime(void)
{
    if (theMTCCond) 
	MTCTime = 0;
    mtcStatus = MTC_UNDEFINED; 
}

void setupMTC(void)
{
    if (theMTCCond) {
	resetMTCTime();
	[mtcHelper setMTCCond:theMTCCond];
	[mtcHelper setPeriod:mtcPollPeriod];
	[mtcHelper activate];
	[mtcHelper pause];
    }
}

static void stopMTC(MKConductor *self)
{
    adjustTime();
    [theMTCCond _pause];
    [mtcHelper pause];
    mtcStatus = MTC_STOPPED;
    MTCTime = [theMTCCond->MTCSynch _time]; /* Save it to compare to time when resumed */
    [theMTCCond->MTCSynch _alarm:MK_ENDOFTIME]; /* Cancel alarm */
}

static void reverseMTC(MKConductor *self)
{
    adjustTime();
    mtcStatus = MTC_REVERSE;
    if ([self->delegate respondsToSelector:@selector(conductorDidReverse:)])
	[self->delegate conductorDidReverse:self];
}

BOOL weGotMTC(void)
{
    return theMTCCond != nil;
}

static BOOL endOfTimeOverride = NO;

BOOL mtcEndOfTime(void)  
/* Returns YES if all MTC conductors have empty queues */
{
    /* For now, just return the one and only, if any -- */
    if (endOfTimeOverride)
	return NO;
    if (!theMTCCond)
	return YES;
    return ISENDOFTIME(theMTCCond->nextMsgTime);
}

static BOOL startMTC(MKConductor *self,BOOL shouldSeek)
{
    /* This gross hack is to work around a bug in the MIDI
    * driver.  There's NO WAY to know when time is valid.
    * And in the case where there's no full message, the
    * exception can come when time is still bogus.
    * So we wait for 2 frames to go by at the slowest
    * frame rate (since it takes 8 quarter frame messages
		  * to set the time.)  This is about 83 ms.
    * Maybe a better way would be to queue up a message
    * with the conductor.  But then we'd have to worry
    * about MTC stopping in the interim.
    */
    [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:(1000 * 2/24.0)/1000.0]];
    adjustTime();
    sysTime = [[NSDate date] retain];
    MTCTime = [self->MTCSynch _time];
    [mtcHelper setTimeSlip:0];
    if (shouldSeek) {
	//	int i,count;
	id obj;
	id listCopy; /* Need to copy list since deactivate/activate changes it */
	
	/* We subtract MTCTime from pauseOffset because MTCTime will be added back in
	    * by beatToClock().  
	    *
	    * oldAdjustedBaseTime = [MKConductor timeInSeconds] - _pauseOffset
	    * We want _pauseOffset += oldAdjustedBaseTime - newBaseTime
	    * But this is the same as _pauseOffset = [MKConductor timeInSeconds] - newBaseTime
	    */
	self->_pauseOffset = [MKConductor timeInSeconds] - MTCTime;
	/* For oldAdjustedClockTime (which is used only when delegate doesn't
	    * provide a time map), we just set it to the same as the current
* adjusted clockTime. 
*/
	self->oldAdjustedClockTime = [MKConductor timeInSeconds] - self->_pauseOffset;
        if (self->oldAdjustedClockTime < 0)
	    self->oldAdjustedClockTime = 0;
	if (DELEGATE_RESPONDS_TO(self,CLOCK_TO_BEAT)) 
	    self->time = [self->delegate clockToBeat:MTCTime from:self];
	else self->time = MTCTime * self->inverseBeatSize;
	if (MKIsTraced(MK_TRACEMIDI))
	    NSLog(@"MIDI time code MKConductor seeking.\n");
	if ([self->delegate respondsToSelector:@selector(conductorWillSeek:)])
	    [self->delegate conductorWillSeek:self];
	listCopy = [self->activePerformers copy];
	/* We could try and be smart and disable _removeActivePerformer: and
	    * _addActivePerformer: but we might outsmart ourselves--the user's
	    * activateSelf method could add a new performer, for example.
	    */
	endOfTimeOverride = YES;
	/* sb: changed to enumerator */
	//        for (i=0, count=[listCopy count]; i<count; i++)
	//            obj = NX_ADDRESS(listCopy)[i];
        {
            NSEnumerator *enumerator = [listCopy objectEnumerator];
            while ((obj = [enumerator nextObject])) {
                [obj deactivate];
                [obj setFirstTimeTag:self->time];
                [obj activate];
	    }
        }
	endOfTimeOverride = NO;
	[listCopy release];
	if ([self->delegate respondsToSelector:@selector(conductorDidSeek:)])
	    [self->delegate conductorDidSeek:self];
    }
    if (checkForEndOfTime())  /* Needed??? (FIXME) */
	return NO;
    if (mtcStatus != MTC_FORWARD) {
	mtcStatus = MTC_FORWARD;
	if (MKIsTraced(MK_TRACEMIDI))
	    NSLog(@"MIDI time code MKConductor running.\n");
	[theMTCCond _resume];
	[mtcHelper resume];
	[self->MTCSynch _alarm:MTCTime + mtcPollPeriod];   
	if ([self->delegate respondsToSelector:@selector(conductorDidResume:)])
	    [self->delegate conductorDidResume:self];
    }
    return YES;
}

-_MTCException:(int)exception
{
    double newTime;
    if (![MKConductor inPerformance])         /* This can happen if we're not separate-threaded */
	return self;
    if (MKIsTraced(MK_TRACEMIDI))
	NSLog(@"Midi time code exception: %s\n",
	      (exception == MKMD_EXCEPTION_MTC_STARTED_FORWARD) ? "time code started" :
	      (exception == MKMD_EXCEPTION_MTC_STOPPED) ? "time code stopped" :
	      (exception == MKMD_EXCEPTION_MTC_STARTED_REVERSE) ? "reverse time code started" :
	      "unknown exception");
    switch (exception) {
	case MKMD_EXCEPTION_MTC_STARTED_FORWARD:  
	    switch (mtcStatus) {
		case MTC_UNDEFINED: 
		    if (!startMTC(self,YES))
			return nil;
		    break;
		case MTC_STOPPED:  
		    newTime = [MTCSynch _time];
		    /* MTCTime is set in stopMTC() */
		    if (!startMTC(self,(ABS(newTime - MTCTime) > SEEK_THRESHOLD)))
			return nil;
			break;
		case MTC_REVERSE: 
		    if (!startMTC(self,YES))
			return nil;
		default:
		case MTC_FORWARD:
		    break;  /* Should never happen */
	    }
	    break;
	case MKMD_EXCEPTION_MTC_STOPPED:
	    stopMTC(self);
	    break;
	case MKMD_EXCEPTION_MTC_STARTED_REVERSE:
	    reverseMTC(self);
	    break;
	default:
	    break;    
    }
    return self;
}

-_addActivePerformer:perf
{
    [activePerformers addObject:perf];
    return self;
}

-_removeActivePerformer:perf
{
    [activePerformers removeObject:perf];
    return self;
}

- _setMTCSynch: (MKMidi *) aMidiObj
{
    /* Sets up alarm and exception port, etc. 
    * This must be sent to when the performance is not in progress yet.
    * The MIDI object may be in any state (open, closed, etc.)
    *
    * Another restriction implied here is that only one conductor can use a 
    * particular MKMidi object.  Hence if aMidiObj is already in use by a MKConductor 
    * (and that MKConductor is not the receiver), setMTCSynch: steals the synch
    * function from that MKConductor.
    *
    */
    if (MTCSynch == aMidiObj) /* Already synched */
	return self;
    else if (theMTCCond != self)    
	[theMTCCond _setMTCSynch: nil];
    if (aMidiObj)
	theMTCCond = self;
    else 
	theMTCCond = nil;
    [MTCSynch _setSynchConductor: nil];
    [aMidiObj _setSynchConductor: theMTCCond];
    MTCSynch = aMidiObj;
    [self setTimeOffset: timeOffset]; /* Resets it appropriately */
    if (MTCSynch) {
	if (!mtcHelper) 
	    mtcHelper = [[_MTCHelper alloc] init];
    } 
    else {
        [mtcHelper release];
        mtcHelper = nil;
    }
    return self;
}

-(double)_MTCPerformerActivateOffset: (id) sender
{
    if (!MTCSynch)
	return 0;
    return -[sender firstTimeTag];
}

static double slipThreshold = .01;

-setMTCSlipThreshold:(double)thresh
{
    slipThreshold = thresh;
    return self;
}

-_runMTC:(double)requestedTime :(double)actualTime
    /* This is invoked by the MIDI driver.  */
{
#define SEEK_THRESHOLD 1.0
    double MTCTimeJump = requestedTime - actualTime;
    if (![MKConductor inPerformance])         /* This can happen if we're not separate-threaded */
	return self;
    if (ABS(MTCTimeJump) > SEEK_THRESHOLD) {
	startMTC(self,YES);
	return self;
    }
    else {
	NSDate *newSysTime = [NSDate date];
	double newMTCTime = [MTCSynch _time];
	/* Using [MTCSynch _time] works MUCH better than using actualTime!
	    * Apparently, the time it takes to get the mach message from the
	    * driver is significant. (This makes sense, since the Conductor could
				      * be running so "actualTime" could be relatively old.)
	    */
        double sysTimeDiff = [sysTime timeIntervalSinceDate:newSysTime];//newSysTime - sysTime;
	    double MTCTimeDiff = newMTCTime - MTCTime;
	    double clockDiff = sysTimeDiff - MTCTimeDiff;
	    /* If MTC is running slow, its time diff will be less than the sys clock.
		* In this case, we want to add to our pauseOffset.  We don't do it here
	    * because we'd have to do an adjustTime(), which would mess up the
		* Conductor's logical time.
		*/
	    if (ABS(clockDiff) > slipThreshold)
		[mtcHelper setTimeSlip:clockDiff];
	    [MTCSynch _alarm:(double)actualTime + mtcPollPeriod];   
    }
    return self;
}

-_adjustPauseOffset:(double)v
    /* Invoked by _MTCHelper */
{
    if (MKIsTraced(MK_TRACEMIDI))
	NSLog(@"Slipping MIDI time code time by %f\n", v);
    _pauseOffset += v;
    sysTime = [[NSDate date] retain];
    MTCTime = [MTCSynch _time];
    repositionCond(self,beatToClock(self,PEEKTIME(_msgQueue))); 
    return self;
}

-(double) _setMTCTime:(double)desiredTime
    /* This is invoked by the MKMidi object when an incoming MIDI message is received
    * and useInputTimeStamps is YES.
    */
{
    return [MKConductor _adjustTimeNoTE:desiredTime + _pauseOffset];
}

@end

@implementation MKConductor(MTC)

- setMTCSynch: (MKMidi *) aMidiObj
{
    /* Sets up alarm and exception port, etc. 
     * This must be sent to when the performance is not in progress yet.
     * The MIDI object may be in any state (open, closed, etc.)
     *
     * Another restriction implied here is that only one conductor can use a 
     * particular midi object.  Hence if aMidiObj is already in use by a MKConductor 
     * (and that MKConductor is not the receiver), setMTCSynch: steals the synch
     * function from that MKConductor.
     *
     * Also sets clocked to YES.
     */
    if ([MKConductor inPerformance] || self == [MKConductor clockConductor])
	return nil;
    [MKConductor setClocked: YES];
    return [self _setMTCSynch: aMidiObj];
}

- (MKMidi *) MTCSynch
{
    return MTCSynch;
}

- (double) clockTime
  /* If receiver is in MTC mode, returns current MTC "clockTime" used by the
   * object.  Otherwise returns [[MKConductor clockConductor] time];
   */
{
    return (MTCSynch) ? MTCTime : [MKConductor timeInSeconds];
}

-setMTCPollPeriod:(double)v
{
    mtcPollPeriod = v;
    [mtcHelper setPeriod:mtcPollPeriod];
    return self;
}

@end

