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
*/
/*
Modification history:

  $Log$
  Revision 1.5  2000/04/07 18:44:51  leigh
  Upgraded logging to NSLog

  Revision 1.4  2000/04/01 00:31:26  leigh
  Replaced getTime with NSDate use

  Revision 1.3  2000/01/19 19:56:42  leigh
  Replaced mach port based millisecond timing with NSThread approach

  Revision 1.2  1999/07/29 01:26:09  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
/* #import "_MTCHelper.h" */ /*sb: removed from here and put in MKConductor.h, since it is interfering
			      * with stuff */

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

static void resetMTCTime(void)
{
    if (theMTCCond) 
      MTCTime = 0;
    mtcStatus = MTC_UNDEFINED; 
}

static void setupMTC(void)
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

static BOOL weGotMTC(void)
{
    return theMTCCond != nil;
}

static BOOL endOfTimeOverride = NO;

static BOOL mtcEndOfTime(void)  
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
	 * oldAdjustedBaseTime = clockTime - _pauseOffset
	 * We want _pauseOffset += oldAdjustedBaseTime - newBaseTime
	 * But this is the same as _pauseOffset = clockTime - newBaseTime
	 */
	self->_pauseOffset = clockTime - MTCTime;
	/* For oldAdjustedClockTime (which is used only when delegate doesn't
	 * provide a time map), we just set it to the same as the current
	 * adjusted clockTime. 
	 */
	self->oldAdjustedClockTime = clockTime - self->_pauseOffset;
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

-setMTCSynch:aMidiObj
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
    if (inPerformance || self == clockCond)
      return nil;
    [MKConductor setClocked:YES];
    return [self _setMTCSynch:aMidiObj];
}

-MTCSynch
{
    return MTCSynch;
}

-(double)clockTime
  /* If receiver is in MTC mode, returns current MTC "clockTime" used by the
   * object.  Otherwise returns [[MKConductor clockConductor] time];
   */
{
    if (MTCSynch)
      return MTCTime;
    else return clockTime;
}

-setMTCPollPeriod:(double)v
{
    mtcPollPeriod = v;
    [mtcHelper setPeriod:mtcPollPeriod];
    return self;
}
