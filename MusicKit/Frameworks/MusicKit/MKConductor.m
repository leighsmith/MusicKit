/*
  $Id$
  Defined In: The MusicKit

  Description:
    This is the MusicKit scheduler. See documentation for details. 
    Note that, in clocked mode, all timing is done with a single NSTimer "timed entry." 

    In this version, you must use the FoundationKit NSRunLoop if you are in clocked mode. You may,
    however, use the unClocked mode, although its purpose is now deprecated.

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/* 
Modification history:

  $Log$
  Revision 1.24  2002/01/29 16:50:42  sbrandon
  checked over MKCancelMsgRequest and other MsgStruct-related functions and methods, and fixed some leaks by retaining and releasing objects where appropriate.

  Revision 1.23  2001/09/06 21:27:47  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.22  2001/08/27 23:51:47  skotmcdonald
  deltaT fetched from conductor, took out accidently left behind debug messages (MKSampler). Conductor: renamed time methods to timeInBeat, timeInSamples to be more explicit

  Revision 1.21  2001/08/07 16:16:11  leighsmith
  Corrected class name during decode to match latest MK prefixed name

  Revision 1.20  2001/07/05 22:52:42  leighsmith
  Comment cleanups, removed redundant getNextMsgTime()

  Revision 1.19  2000/05/27 19:16:08  leigh
  Code cleanup

  Revision 1.18  2000/05/06 00:57:16  leigh
  Parenthetised to remove warnings

  Revision 1.17  2000/05/06 00:29:58  leigh
  removed redundant setjmp include

  Revision 1.16  2000/04/25 02:14:05  leigh
  Moved separate thread locking into masterConductorBody since
  it was being locked before being called, which under NSRunLoop dispatching was not possible.

  Revision 1.15  2000/04/22 20:17:02  leigh
  Extra info in description, proper class ivar initialisations

  Revision 1.14  2000/04/20 21:39:00  leigh
  Removed flakey longjmp for unclocked MKConductors, improved description

  Revision 1.13  2000/04/16 04:28:17  leigh
  Class typing and added description method

  Revision 1.12  2000/04/08 01:01:33  leigh
  Fixed bug when inPerformance set during final pending masterConductorBody

  Revision 1.11  2000/04/02 17:22:13  leigh
  Cleaned doco

  Revision 1.10  2000/04/01 01:19:27  leigh
  Removed redundant getTime function

  Revision 1.9  2000/03/31 00:13:57  leigh
  theTimeToWait now a shared function, using _MKAppProxy

  Revision 1.8  2000/03/24 16:27:25  leigh
  Removed redundant AppKit headers

  Revision 1.7  2000/01/24 22:32:02  leigh
  Comment improvements

  Revision 1.6  2000/01/20 17:15:36  leigh
  Fixed accidental commenting out of header files, reorganised #imports

  Revision 1.5  2000/01/13 06:44:07  leigh
  Added a missing (pre-OpenStep conversion!) _error: method, improved forward declaration of newMsgRequest

  Revision 1.4  1999/09/04 22:02:17  leigh
  Added setDeltaT, deltaT class methods. Merged to single masterConductorBody method.

  Revision 1.3  1999/08/06 16:31:12  leigh
  Removed extraInstances and implementation ivar cruft

  Revision 1.2  1999/07/29 01:16:36  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  09/15/89/daj - Added caching of inverse of beatSize. 
  09/19/89/daj - Unraveled inefficient MIN(MAX construct.
  09/25/89/daj - Added check for common case in addConductor.
  01/03/90/daj - Added check for performanceIsPaused in adjustTime and
                 _adjustTimeNoTE:. Made jmp_buf be static.
		 Optimized insertMsgQueue() a bit.
  01/07/90/daj - Changed to use faster time stamps.		 
		 Changed comments. addConductor() name changed to 
		 repositionCond()
  01/31/90/daj - Moved _jmpSet = YES; in unclocked loop to fix bug:
                 Memory exception when empty unclocked conducted performance 
		 following an unclocked performance that wasn't empty. 
		 (bug 4451). Added extraInstanceVars mechanism so that
		 we can forever remain backward compatable.
  02/01/90/daj - Added comments. Added check for inPerformance in
                 MKCancelMsgRequest() to fix bug whereby if finishPerformance
		 is triggered by the repositionCond(), condQueue was nil and
		 you got a memory fault.
  03/13/90/daj - Fixed bugs involving pause/resume and timeOffset 
                 (much thanks to lbj). 
                 Fixed bug in MKRescheduleMsgRequest() whereby 
		 the end of performance was erroneously being triggered.
		 Also added MKRepositionMsgRequest().
  	         Moved private methods to a catagory.
  03/19/90/daj - Added pauseFor:.
  03/23/90 lbj - Fixed pauseFor: -- 
  		Put in a return-if-negative-arg predicate and changed the 
		recipient of the resume msgReq to clockConductor (it was self).
  03/23/90/daj - Added check for isPaused in insertMsgQueue() and -emptyQueue
  03/27/90/daj - Added delegate, against my better judgement, at the request
                 of lbj.
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  04/27/90/daj - Commented out MKSetTime(0) (see changes in time.m) 
  06/10/90/daj - Added _MKAdjustTimeIfNotBehind() for Orchestra's synchTime.
  07/27/90/daj - Added seperate thread mechanism.  See lock.m.
  07/27/90/daj - Moved all checks of the form if (!allConductors) condInit()
                 that were in factory methods into +initialize.
  08/20/90/daj - Added delegate methods for crossing high/low deltaT thresholds.
  08/30/90/daj - Fixed bug that caused empty performance to crash if tempo
                 isn't 60! (Changes to _runSetup). Also changed float compares
		 of MK_ENDOFTIME and ENDOFLIST to be safer.
  09/02/90/daj - Changed MAXDOUBLE references to noDVal.h way of doing things
  09/29/90/daj - Changed to coincide with new way of doing separate thread 
                 loop. Also fixed bug in forking of thread!
  12/12/90/daj - Fixed big memory leak in conductor body.
  04/22/91/daj - Changed separate-threaded finishPerformance to do longjmp
  02/06/92/daj - Added bulletproofing against messages scheduled for negative
                 times.  (See masterConductorBody).
  02/25/92/daj - Changed adjustBeat to allow for floating point round off error in 
                 timeOffset calc.
  11/02/92/daj - Changes for MTC
  11/09/92/daj - Changed beatToClock and adjustBeat.  Changes to pause/resume, etc.
  11/16/92/daj - Bumped archiving version to 3 and added archiving of delegate.
                 We don't archive activePerformers because MKPerformer doesn't archive
		 it's status--unarchived performers always come up inactive.
		 We don't archive MTCSynch because MKMidi (still!) doesn't support 
		 archiving. (Sigh.)
*/
#import <AppKit/NSApplication.h>
#import "_musickit.h"
#import "_time.h"
#import "MidiPrivate.h"
#import "_MTCHelper.h"   // sb: moved this to here from _MTCHelper.m, since it interferred there.
#import "_MKAppProxy.h"

#define MK_INLINE 1

// This used to be NX_FOREVER which is obsolete with OpenStep. There's no reason not to include it manually though.
#define MK_FOREVER	(6307200000.0)	/* 200 years of seconds */

#define ENDOFLIST (MK_FOREVER)
#define PAUSETIME (MK_ENDOFTIME - 2.0) /* See ISENDOFTIME below */

/* Macros for safe float compares */
#define ISENDOFLIST(_x) (_x > (ENDOFLIST - 1.0))
#define ISENDOFTIME(_x) (_x > (MK_ENDOFTIME - 1.0))

#define TARGETFREES NO
#define CONDUCTORFREES YES

#define NOTIMEDENTRY nil

static BOOL separateThread = NO;
static NSTimer *timedEntry = NOTIMEDENTRY; /* Only used for DPS client mode */
					   /* sb: now NSTimer instead of void*. Not DPS. */
static BOOL inPerformance = NO;   /* YES if we're currently in performance. */
static BOOL dontHang = YES;       /* NO if we are expecting asynchronous input, e.g. MIDI or mouse */
static BOOL isClocked = YES;      /* YES if we should stay synced up to the clock.
				     NO if we can run as fast as possible. */
static NSDate * startTime = nil;  /* Start of performance time. */
static NSDate * pauseTime = nil;  /* Time last paused. */
static double clockTime = 0.0;    /* Clock time. */
static double oldClockTime = 0;

static MKMsgStruct *afterPerformanceQueue = NULL; /* end-of-time messages. */
static MKMsgStruct *_afterPerformanceQueue = NULL; /* same but private */
static MKMsgStruct *beforePerformanceQueue = NULL;/* start-of-time messages.*/
static MKMsgStruct *afterPerformanceQueueEnd = NULL; /* end-of-time messages.*/
static MKMsgStruct *_afterPerformanceQueueEnd = NULL; /* same but private */
static MKMsgStruct *beforePerformanceQueueEnd = NULL;/* start-of-time msgs.*/
static BOOL performanceIsPaused = NO; /* YES if the entire performance is
					 paused. */
static id classDelegate = nil;  /* Delegate for the whole class. */

#import "ConductorPrivate.h"
@implementation MKConductor:NSObject 

/* METHOD TYPES
 * Creating and freeing Conductors
 * Querying the object
 * Modifying the object
 * Controlling a performance
 * Tempo and timeOffset
 * Requesting messages
 */

static MKConductor *curRunningCond = nil; /* Or nil if no running conductor. */
static MKConductor *condQueue = nil;   /* Head of conductor queue. */
static MKConductor *defaultCond = nil; /* default Conductor. */
static MKConductor *clockCond = nil;   /* clock time Conductor. */

#define NORMALCOND (unsigned char)0
#define CLOCKCOND (unsigned char)1
#define DEFAULTCOND (unsigned char)2

#define DELEGATE_RESPONDS_TO(_self,_msgBit) ((_self)->delegateFlags & _msgBit)
#define BEAT_TO_CLOCK 1
#define CLOCK_TO_BEAT 2

#define VERSION2 2
#define VERSION3 3

static NSMutableArray *allConductors = nil; /* An array of all conductors. */
static void condInit();    /* Forward decl */

+ (void)initialize
{
    if (self != [MKConductor class])
      return;
    [MKConductor setVersion:VERSION3];//sb: suggested by Stone conversion guide (replaced self)
    if (!allConductors)
        condInit();
    return;
}

#import "separateThread.m"

static MKMsgStruct *evalSpecialQueue();

/*
 LMS these are SB's notes, perhaps redundant.
 startTime is absolute date (NSDate *)
 nextmsgtime: maybe relative time to start of performance YES
 clockTime: relative to start of performance
 pauseTime is absolute
*/

/* The following implements the delta T high water/low water notification */
static double deltaTThresholdLowPC = .25; /* User sets this */
static double deltaTThresholdHighPC = .75;/* User sets this */

static double deltaTThresholdLow = 0;     
static double deltaTThresholdHigh = 0;    
static BOOL delegateRespondsToThresholdMsgs = NO; 
static BOOL delegateRespondsToLowThresholdMsg = NO;
static BOOL delegateRespondsToHighThresholdMsg = NO;
static BOOL lowThresholdCrossed = NO;

void MKSetLowDeltaTThreshold(double percentage)
{
    deltaTThresholdLowPC = percentage;
    [MKConductor _adjustDeltaTThresholds];
}

void MKSetHighDeltaTThreshold(double percentage)
{
    deltaTThresholdHighPC = percentage;
    [MKConductor _adjustDeltaTThresholds];
}

double _MKTheTimeToWait(double nextMsgTime)
{
    double t;
//    t = getTime();  /* Current time */
//    t -= startTime; /* current time relative to the start of performance. */
    t = [[NSDate date] timeIntervalSinceDate:startTime]; //sb: replaced previous 2 lines.
    t = nextMsgTime - t; /* relative time */
    t = MIN(t, MK_ENDOFTIME); /* clip */
    if (delegateRespondsToThresholdMsgs) {
        if (t < deltaTThresholdLow && !lowThresholdCrossed) {
            if (delegateRespondsToLowThresholdMsg)
                [classDelegate conductorCrossedLowDeltaTThreshold];
            lowThresholdCrossed = YES;
        }
        else if (t > deltaTThresholdHigh && lowThresholdCrossed) {
            if (delegateRespondsToHighThresholdMsg)
                [classDelegate conductorCrossedHighDeltaTThreshold];
            lowThresholdCrossed = NO;
        }
    }
    t = MAX(t,0);
    return t; /*sb: returns relative time... */
}

static void adjustTimedEntry(double nextMsgTime)
    /* The idea here is that we always calibrate by clock time. Therefore
       we can't accumulate errors. We subtract the difference between 
       where we are and where we should be. It is assumed that time is
       already updated. */
{
    // NSLog(@"Adjusting timed entry %lf %d, %d, %d, %d\n", nextMsgTime, !inPerformance, performanceIsPaused, musicKitHasLock(), !isClocked);
    if ((!inPerformance) || (performanceIsPaused) || (musicKitHasLock()) || (!isClocked)) 
        return;  /* No timed entry, s.v.p. */
    if (separateThread)
        sendMessageToWakeUpMKThread();
    else {
        if (timedEntry != NOTIMEDENTRY) {
            [timedEntry invalidate];
            [timedEntry release];
        }
        timedEntry = [[NSTimer timerWithTimeInterval: _MKTheTimeToWait(nextMsgTime) 
			       target: [MKConductor class]
			       selector: @selector(masterConductorBody:)
			       userInfo: nil
			       repeats: NO] retain];
        [[NSRunLoop currentRunLoop] addTimer: timedEntry forMode: _MK_DPSPRIORITY];
    }
}

/* mtc forward decls */
static void resetMTCTime(void);
static void setupMTC(void);
static BOOL mtcEndOfTime(void);
static BOOL weGotMTC(void);

static BOOL checkForEndOfTime()
{
    if ((dontHang || (!isClocked)) && ISENDOFTIME(condQueue->nextMsgTime) && mtcEndOfTime()) {
        [MKConductor finishPerformance];
        return YES;
    } 
    return NO;
}

static void repositionCond(MKConductor *cond,double nextMsgTime)
    /* Enqueue a MKConductor (this happens every time a new message is 
       scheduled.)

       cond is the conductor to be enqueued.  nextMsgTime is the next
       post-mapped time that the conductor wants to run.  If we're not in
       performance, just sets cond->nextMsgTime.  Otherwise, enqueues cond at
       the appropriate place, ordered by time. If, after adding the conductor, the head of the
       queue is MK_ENDOFTIME and if we're not hanging, sends
       +finishPerformance. If the newly enqueued conductor is added at the
       head of the list, calls adjustTimedEntry().
       Question is: where do we retain cond? I presume it is assumed cond is already retained.
     */
{
    MKConductor *tmp;
    register double t;
    t = MIN(nextMsgTime,MK_ENDOFTIME);
    t = MAX(t,clockTime);
    cond->nextMsgTime = t;
    if (!inPerformance)
      return;
    /* remove conductor from doubly-linked list. */
    if (cond == condQueue) { /* It's first */
      if ((!cond->_condNext) || (t < ((MKConductor *)cond->_condNext)->nextMsgTime)) { 
	    /* It's us again. */
	    /* We use < to avoid doing an adjustTimedEntry if possible. */
	    /* No need to reposition. */
	    if (!curRunningCond)  /* See comment below */
	      adjustTimedEntry(t);
	    if (!cond->_condNext)
   	       checkForEndOfTime();
	    /* We only need to check for ENDOFTIME if !cond->_condNext.
	     * If cond->_condNext != nil, then we used the second part of
 	     * the conditional above--i.e. we know that nextMsgTime < 
	     * ENDOFTIME.
	     */
	    return;
	}
	/* Remove us from queue. No need to set pointers in cond because
	   they're going to be set below. */
	condQueue = cond->_condNext;
	condQueue->_condLast = nil;
    }
    else { 
	/* Remove cond from queue. No need to set pointers in cond because
	   they're going to be set below. */
	if (cond->_condLast) /* The first time, this can be nil */
	  ((MKConductor *)cond->_condLast)->_condNext = cond->_condNext;
	if (cond->_condNext)
	  ((MKConductor *)cond->_condNext)->_condLast = cond->_condLast;
    }
    /* Now add it. */
    if ( // (!condQueue) || 
	(t < condQueue->nextMsgTime)) { /* Add at the start of queue? */
	/* We use < to avoid doing an adjustTimedEntry if possible. */
	/* This can only happen if curRunningCond == self or if
	   nobody's running. In the first case, the timed entry is 
	   added by masterConductorBody. In the second, we add it
	   below. */
	tmp = condQueue;
	condQueue = cond;
	cond->_condNext = tmp;
	cond->_condLast = nil;
//	if (tmp)
	  tmp->_condLast = cond;
	if (!curRunningCond)
	  adjustTimedEntry(t); /* Nobody's running and we're not in setup. */
	return;                /* No need to check for ENDOFTIME because
				  otherwise, t wouldn't be < nextMsgTime */
    }
    else {
	for (tmp = condQueue; 
	     (tmp->_condNext && 
	      (((MKConductor *)tmp->_condNext)->nextMsgTime <= t)); 
	     tmp = tmp->_condNext)
	  ;
	/* tmp is now first one before us and tmp->_condNext is the first one
	   after us, if any. */
	cond->_condLast = tmp;
	if (tmp->_condNext)
	  ((MKConductor *)tmp->_condNext)->_condLast = cond;
	cond->_condNext = tmp->_condNext;
	tmp->_condNext = cond;
    }	
    checkForEndOfTime();
}

#if i386         /* There's a Pentium optimization bug that is tickled here */
#pragma CC_OPT_OFF
#endif

static double beatToClock(MKConductor *self,double newBeat)
    /* Conversion from beat time to clock time.
       This function assumes that self has been adjusted with adjustBeat. */
{
    double x;
    if (ISENDOFLIST(newBeat))
      return MK_ENDOFTIME;
    /* The formula is MAX(mapFun(newBeat) + pauseOffset, clockTime) */
    if (self == clockCond)
      return MAX(newBeat,clockTime);
    if (DELEGATE_RESPONDS_TO(self,BEAT_TO_CLOCK)) {
	x = [self->delegate beatToClock:newBeat from:self] + self->_pauseOffset;
    } else { /* Use built-in version */
	double beatDiff;
	double adjustedBaseTime;
	/* The point of this subtracting and then adding in again is to
	 * make sure that if pauseOffset > clockTime, the music waits
	 * appropriately.
	 */
	adjustedBaseTime = clockTime - self->_pauseOffset;
	if (adjustedBaseTime < 0) 
	  adjustedBaseTime = 0;
	beatDiff = (newBeat - self->time);
	x = (MAX(beatDiff,0.0) * self->beatSize + adjustedBaseTime + 
	     self->_pauseOffset);
    }
    return MAX(x,clockTime);
}

#if i386
#pragma CC_OPT_ON
#endif

static void adjustBeat(MKConductor *self)
    /* Given clock time, adjust internal state to reflect current time. */
{
    double adjustedClockTime,x;
    if (self == clockCond) 
      self->time += clockTime - oldClockTime;
    else if (self->isPaused) 
      self->_pauseOffset += (clockTime - oldClockTime);
    else {
	adjustedClockTime = clockTime - self->_pauseOffset;
	if (DELEGATE_RESPONDS_TO(self,CLOCK_TO_BEAT)) 
	  x = [self->delegate clockToBeat:adjustedClockTime from:self];
	else { /* Use built-in version */
          x = self->time + (adjustedClockTime - self->oldAdjustedClockTime) * self->inverseBeatSize;
          self->oldAdjustedClockTime = MAX(adjustedClockTime,0);
	}
	if (x > self->time)
	  self->time = x;
    }
}

static void setTime(t)
    double t;
    /* Adjusts beats of all conductors and resets time. */
{
    register MKConductor *cond;
    oldClockTime = clockTime;
    clockTime = t;
    // NSLog(@"Setting clockTime to %lf\n", clockTime);
    if (curRunningCond) {
  	for (cond = curRunningCond->_condNext; cond; cond = cond->_condNext)
	  adjustBeat(cond);
 	for (cond = curRunningCond->_condLast; cond; cond = cond->_condLast)
	  adjustBeat(cond);
	/* Need to set oldAdjustedClockTime for the running conductor */
	if (curRunningCond != clockCond && 
	    !DELEGATE_RESPONDS_TO(curRunningCond,CLOCK_TO_BEAT)) {
	    double x;
	    x = clockTime - curRunningCond->_pauseOffset;
            curRunningCond->oldAdjustedClockTime = MAX(x,0);
	}
    }
    else for (cond = condQueue; cond; cond = cond->_condNext)
      adjustBeat(cond);
}

static void adjustTime()
/* Normally, the variable time jumps in discrete amounts. However,
   sometimes, as, for example, when an asynchronous event such as
   MIDI or a mouse-click is received, it is desirable to adjust time 
   to reflect the current time. 
   This function adjustTime() attempts to serve this need. It will set
   the conductors clockTime to either the current system time or the current clockTime.
   The current value of clockTime is set. */
{
    double time;
//    time = getTime() - startTime;
    time = [[NSDate date] timeIntervalSinceDate:startTime]; //sb: replaced previous line.
    /* Don't allow it to exceed next scheduled msg. This insures that 
       multiple adjustTimes (e.g. for flurry of MIDI events) don't push 
       scheduled events into the past. (The event loop may favor port action
       over timed entries. Even though it's not obvious, experiments have 
       shown that it's better to do this clip. Otherwise notes are completely
       omitted, whether or not preemption is used (because envelopes are
       "stepped on" out of existance). */
    // NSLog(@"adjusting Time %lf condQueue->nextMsgTime = %lf\n", time, condQueue->nextMsgTime);
    time = MIN(time,condQueue->nextMsgTime);
    // NSLog(@"after to minimum Time %lf\n", time);
    time = MAX(time,clockTime); /* Must be more than the previous time, otherwise we're moving time backwards */
    // NSLog(@"after gating maximum Time %lf clockTime = %lf, oldClockTime = %lf\n", time, clockTime, oldClockTime);
    setTime(time);
}

BOOL _MKAdjustTimeIfNotBehind(void)
/* Normally, the variable time jumps in discrete amounts. However,
   sometimes, as, for example, when an asynchronous event such as
   MIDI or a mouse-click is received, it is desirable to adjust time 
   to reflect the current time.  AdjustTime serves this function.
   Returns the current value of clockTime. */
{
    double time;
//    time = getTime() - startTime;
    time = [[NSDate date] timeIntervalSinceDate:startTime]; //sb: replaced previous line.
    /* Don't allow it to exceed next scheduled msg. This insures that 
       multiple adjustTimes (e.g. for flurry of MIDI events) don't push 
       scheduled events into the past. (The event loop may favor port action
       over timed entries. Even though it's not obvious, experiments have 
       shown that it's better to do this clip. Otherwise notes are completely
       omitted, whether or not preemption is used (because envelopes are
       "stepped on" out of existance). */
    if (time > condQueue->nextMsgTime)
      return NO;
    time = MAX(time,clockTime); /* Must be more than previous time. */
    setTime(time);
    return YES;
}

+(double)timeInSeconds
    /* Returns the time in seconds as viewed by the clock conductor.
       Same as [[Conductor clockConductor] time]. 
       Returns MK_NODVAL if not in
       performance. Use MKIsNoDVal() to check for this return value.  */
{
    if (inPerformance)
      return clockTime;
    return MK_NODVAL;
}

/* Convience class methods to set the delta time using the MKConductor class */
+(void) setDeltaT: (double) newDeltaT
{
    MKSetDeltaT(newDeltaT);
}

/* Convience class methods to return the delta time using the MKConductor class */
+(double) deltaT
{
    return MKGetDeltaT();
}

#if 0 // LMS unnecess
/* The following is a hack that may go away. It was inserted as an 
   emergency measure to get ScorePlayer working for 1.0. It's now
   in the shlib interface so it's here for the duration of the war.
 */
static void (*pollProc)() = NULL;

void _MKSetPollProc(void (*proc)()) {
    pollProc = proc;
}
#endif

static void
unclockedLoop()
    /* FIXME Might want to check for events here. */
    /* Run until done. */
{
#if 0   // disabled by LMS as the longjmp was doing funny things to memory.
    _jmpSet = YES;
    setjmp(conductorJmp);
    if (inPerformance)
      for (; ;) {
        [MKConductor masterConductorBody: nil];
      }
#else
    while(inPerformance) {
        [MKConductor masterConductorBody: nil];
    }
#endif
}

/* In addition to the regular message queues, there are several special 
   message queues. E.g. there's one for before-performance messages, one
   for after-performance messages, and so on. These are handled somewhat
   differently. E.g. we don't use back links
   and we cancel just by setting object field to nil. */
static MKMsgStruct *
insertSpecialQueue(sp,queue,queueEnd)
    register MKMsgStruct *sp;
    MKMsgStruct *queue;
    register MKMsgStruct **queueEnd;
    /* insert at end of special msgQueues used for start and end messages */
{
    if (!sp)
        return queue;
    sp->_onQueue = YES;
    if (*queueEnd) {
	(*queueEnd)->_next = sp;
	(*queueEnd) = sp;
	sp->_next = NULL;
    }
    else {
	sp->_next = NULL;
	*queueEnd = sp;
	queue = sp;
    }
    sp->_conductor = nil; /* nil signals special queue */
    return queue;
}

#define PEEKTIME(pq) (pq)->_timeOfMsg

#define COUNT_MSG_QUEUE_LENGTH 0

static id
insertMsgQueue(sp,self)
    register MKMsgStruct * sp;
    MKConductor *self;
    /* inserts in msgQueue and changes timed entry if necessary. */
{
    register double t;
    register MKMsgStruct * tmp;
    if (!sp)
        return nil;
    t = MIN(sp->_timeOfMsg,MK_ENDOFTIME);
    t = MAX(t,self->time);
    sp->_onQueue = YES;
    if ((t < PEEKTIME(self->_msgQueue)) || (!self->_msgQueue->_next)) { 
	sp->_next = self->_msgQueue;
	sp->_prev = NULL;
	sp->_next->_prev = sp;
	self->_msgQueue = sp;
	if (!self->isPaused)
	  repositionCond(self,beatToClock(self,t)); 
	/* Only need to add yourself if this message is the next one. */
    }
    else {
#if 0
	/* Commented out because version below is faster */
	for (tmp = self->_msgQueue; (t >= tmp->_next->_timeOfMsg); 
	     tmp = tmp->_next)
	  ;
	/* insert after tmp */
	sp->_next = tmp->_next;
	sp->_next->_prev = sp;
	tmp->_next = sp;	
	sp->_prev = tmp;
#endif
	for (tmp = self->_msgQueue->_next; (t >= tmp->_timeOfMsg); 
	     tmp = tmp->_next)
	  ;
	/* insert before tmp */
	sp->_next = tmp;
	sp->_prev = tmp->_prev;
	tmp->_prev = sp;	
	sp->_prev->_next = sp;
    }	
    sp->_conductor = self;
#   if COUNT_MSG_QUEUE_LENGTH
    {
	static int maxQueueLen = 0;
	int i;
	for (i = 0, tmp = self->_msgQueue; tmp; tmp = tmp->_next, i++)
	  if (i > maxQueueLen) {
	      NSLog(@"MaxQLen == %d\n",i);
	      maxQueueLen = i;
	  }
    }
#   endif
    return self;
}

/* Why do I call MKMsgStructs "sp" you ask? I don't know!
   Perhaps it means "struct pointer"? */

#define SPCACHESIZE 64  
static MKMsgStruct *spCache[SPCACHESIZE];
static unsigned spCachePtr = 0;

#define USECACHE 1

#if USECACHE
static MKMsgStruct *allocSp()
    /* alloc a new sp. */
{
    MKMsgStruct *sp;
    if (spCachePtr) 
      sp = spCache[--spCachePtr]; 
    else _MK_MALLOC(sp,MKMsgStruct,1);
    return sp;
}

static void freeSp(sp)
    MKMsgStruct * sp;
    /* If cache isn't full, cache sp, else free it. 
       Be careful not to freeSp the same sp twice! */
{
    if (spCachePtr < SPCACHESIZE) 
      spCache[spCachePtr++] = sp;
    else free(sp);
}

#else

static MKMsgStruct *allocSp()
    /* alloc a new sp. */
{
    MKMsgStruct *sp;
    _MK_MALLOC(sp,MKMsgStruct,1);
    return sp;
}

static void freeSp(sp)
    MKMsgStruct * sp;
{
    free(sp);
}

#endif

static MKMsgStruct * 
popMsgQueue(msgQueue)
    register MKMsgStruct * *msgQueue;		
    /* Pop and return first element in process queue. 
       msgQueue is a pointer to the process queue head. */
{
    register MKMsgStruct * sp;
    sp = *msgQueue;		/* Pop msgQueue. */
    if ((*msgQueue = (*msgQueue)->_next))
      (*msgQueue)->_prev = NULL;
    return(sp);
}

// forward declaration
static MKMsgStruct *newMsgRequest(BOOL,double,SEL,id,int,id,id);

static void condInit()
/*sb: changed from void to (id)callingObj because I need to tell initializeBackgroundThread which object the main conductor is, so that the conductor can be sent objC messages from the background thread.
 */
{

    allConductors = [NSMutableArray new];
    defaultCond   = [MKConductor new];
    clockCond     = [MKConductor new];
    /* This actually works ok for +new. The first time +new is called,
       it creates defaultCond, clockCond and the new Cond. */
    initializeBackgroundThread();
}

- (void)dealloc
  /* Freeing a conductor is not permitted. This message overrides the free 
     capability. */
{
    [self doesNotRecognizeSelector:_cmd];
    //return nil;
}

-_initialize
    /* Private method that initializes the Conductor when it is created
       and after it finishes performing. Sent by self only. Returns self.
       BeatSize is not reset. It retains its previous value. */
{	
    pauseFor = MKCancelMsgRequest(pauseFor);
    /* timeOffset is inititialized to 0 because it's an instance var. Nowdays so are the rest, but so what? */
    oldAdjustedClockTime = 0;
    time = 0;	
    nextMsgTime = 0;
    _pauseOffset = 0;
    isPaused = NO;
    /* If the end-of-list marker is ever sent, it will print an error. (It's a bug if this ever happens.) */
    if (!_msgQueue)
        _msgQueue = newMsgRequest(CONDUCTORFREES,ENDOFLIST, @selector(_error:), self,
                                1, @"MKConductor's end-of-list was erroneously evaluated (this shouldn't happen).\n", nil);
    // Remove links. We don't want to leave links around because they screw up repositionCond.
    // The links are added at the last minute in _runSetup.
    _condLast = _condNext = nil; 
    return self;
}

+ allocWithZone:(NSZone *)zone {
    if (inPerformance)
      return nil;
    self = [super allocWithZone:zone];
    return self;
}

+ alloc {
    if (inPerformance)
      return nil;
    self = [super alloc];
    return self;
}

+ new {
    self = [self allocWithZone:NSDefaultMallocZone()];
    [self init];
    return self;
}

- init
  /* TYPE: Creating; Creates a new Conductor.
   * Creates and returns a new Conductor object with a tempo of
   * 60 beats a minute.
   * If inPerformance is YES, does nothing
   * and returns nil.
   */
{
    /* Initialize instance variables here that are only intiailized upon
       creation. Initialize instance variables that are reinitialized for
       each performance in the _initialize method. */
    id oldLast = [allConductors lastObject];
    if (oldLast == self) /* Attempt to init twice */
      return nil;
    if (![allConductors containsObject:self]) [allConductors addObject:self];
//#error ListToMutableArray: lastObject raises when List equivalent returned nil //sb: not true?
    if ([allConductors lastObject] != self)
      return nil; /* Attempt to init twice */
    [super init];
    activePerformers = [[NSMutableArray allocWithZone:[self zone]] init];
    beatSize = 1;
    pauseFor = NULL; 
    delegateFlags = 0;
    inverseBeatSize = 1;
    _msgQueue = NULL;
    [self _initialize];
    return self;
}

- copy
  /* Same as [[self copyFromZone:[self zone]]. */
{
    return [self copyWithZone:[self zone]];
}

- copyWithZone:(NSZone *)zone
  /* Same as [[self class] allocFromZone:zone] followed by [self init]. */
{
    id obj;
    obj = [[self class] allocWithZone:zone]; 
    [obj init];
    return obj;
}

+adjustTime
  /* TYPE: Modifying; Updates the current time.
   * Updates the factory's notion of the current time.
   * This method should be invoked whenever 
   * an asychronous event (such as a mouse, keyboard, or MIDI
   * event) takes place. The MidiIn object sends adjustTime for you.
   */
{
    if (inPerformance)
      adjustTime();
    return self;
}

static void _runSetup()
  /* Very private function. Makes the conductor list with much hackery. */
{
    /* These hacks are to keep repositionCond() from triggering
       finishPerformance or adding timed entries while sorting list. */
    BOOL clk = isClocked;
    BOOL noHng = dontHang;
    dontHang=NO;
    isClocked=YES;
    curRunningCond = clockCond;
    condQueue = clockCond; 
    /* Set head of queue to an arbitrary conductor. Sorting is done by _runSetup. */
    [allConductors makeObjectsPerformSelector:@selector(_runSetup)];
    dontHang = noHng;
    isClocked = clk;
    curRunningCond = nil;
}

+ startPerformance
  /* TYPE: Managing; Starts a performance.
   * Starts a Music Kit performance.  All Conductor objects
   * begin at the same time.
   * In clocked mode, the Conductor assumes the use of the Application 
   * object's event loop.
   * If you have not yet sent the -run message to your application, or if 
   * NSApp has not been created, startPerformance does nothing and return nil.
   */
{
    if (inPerformance)
        return self;
    _MKSetConductedPerformance(YES, self);
    inPerformance = YES;   /* Set this before doing _runSetup so that repositionCond() works right. */
    [self _adjustDeltaTThresholds]; /* For automatic notification */
    setTime(clockTime = 0.0); // this forces oldClockTime to 0.0 also.
    _runSetup(); // Was before setTime()
    setupMTC();
    if (MKIsTraced(MK_TRACECONDUCTOR))
        NSLog(@"Evaluating the beforePerformance queue,%s separate threaded.\n", separateThread ? "" : " not");
    beforePerformanceQueue = evalSpecialQueue(beforePerformanceQueue, &beforePerformanceQueueEnd);
    if (checkForEndOfTime()) {
	[self finishPerformance];
	return self;
    }
    if (!separateThread) 
        setPriority();
    if (!isClocked && !separateThread) {
	timedEntry = NOTIMEDENTRY;
	unclockedLoop();
	return self;
    }
    if (!separateThread) {
        /*sb: I am assuming that self, in a class method, equals the class method. */
        timedEntry = [[NSTimer timerWithTimeInterval: condQueue->nextMsgTime
			       target: [self class]
			       selector: @selector(masterConductorBody:)
			       userInfo: nil
			       repeats: YES] retain];
        [[NSRunLoop currentRunLoop] addTimer: timedEntry forMode: _MK_DPSPRIORITY];
    }
    [startTime autorelease];
    startTime = [[NSDate date] retain];
    if (MKGetDeltaTMode() == MK_DELTAT_SCHEDULER_ADVANCE) {
        [startTime autorelease];
        startTime = [[startTime addTimeInterval:(0 - MKGetDeltaT())] retain];
    }
    if (separateThread) {
	launchThread();
    }
    return self;
}

+ (MKConductor *) defaultConductor
  /* TYPE: Querying; Returns the defaultConductor. 
   * Returns the defaultConductor.
   */
{ 	
    return defaultCond;
}

+(BOOL)inPerformance
  /* TYPE: Querying; Returns YES if a performance is in session.
   * Returns YES if a performance is currently taking
   * place.
   */
{
    return inPerformance;
}

static void evalAfterQueues()
    /* Calls evalSpecialQueue for both the private and public after-performance
       queues. */
{
    if (MKIsTraced(MK_TRACECONDUCTOR))
        NSLog(@"Evaluating afterPerformance queue.\n");
   _afterPerformanceQueue = evalSpecialQueue(_afterPerformanceQueue, &_afterPerformanceQueueEnd);
   afterPerformanceQueue = evalSpecialQueue(afterPerformanceQueue, &afterPerformanceQueueEnd);
}

+finishPerformance
  /* TYPE: Modifying; Ends the performance.
   * Stops the performance.  All enqueued messages are  
   * flushed and the afterPerformance message is sent
   * to the factory.  Returns nil if it was in performance, nil
   * otherwise.
   *
   * If the performance doesn't hang,
   * the factory automatically sends the finishPerformance
   * message to itself when the message queue is exhausted.
   * It can also be sent by the application to terminate the
   * performance prematurely.
   */
{	
    double lastTime;
    if (MKIsTraced(MK_TRACECONDUCTOR))
        NSLog(@"finishPerformance,%s separate threaded,%s in performance.\n", separateThread ? "" : " not", inPerformance ? "" : " not");
    if (!inPerformance) {
	evalAfterQueues(); /* This is needed for MKFinishPerformance() */
	return nil;
    }
    performanceIsPaused = NO;
    _MKSetConductedPerformance(NO,self);
    inPerformance = NO; /* Must be set before -emptyQueue is sent */
    [allConductors makeObjectsPerformSelector:@selector(emptyQueue)];
    if (separateThread)
        removeTimedEntry(exitThread);
    else if (timedEntry != NOTIMEDENTRY) {
        [timedEntry invalidate];
        [timedEntry release];
    }
    if (!separateThread)
        resetPriority();
    timedEntry = NOTIMEDENTRY;
    // condQueue is being set to nil, before the MusicKit thread has finished up.
    // however this is not that tragic as the inPerformance = NO will stop
    // masterConductorBody doing anything harmful.
    condQueue = nil;
    lastTime = clockTime;
    setTime(clockTime = 0.0);  // this forces oldClockTime to 0.0 also.
    resetMTCTime();
    //   MKSetTime(0.0); /* Handled by _MKSetConductedPerformance now */
    oldClockTime = lastTime;
    [allConductors makeObjectsPerformSelector:@selector(_initialize)];
    evalAfterQueues();
#if 0 // disabled as longjmp makes memory flakey.
    if (_jmpSet) {
	_jmpSet = NO;     
	if (separateThreadedAndInMusicKitThread() || 
	    (!isClocked && !separateThread)) {
	    longjmp(conductorJmp, 0);   /* Jump out of loop now. */
	} 
    }
    else
        _jmpSet = NO;
#endif

    return self;
}

+pausePerformance
  /* TYPE: Controlling; Pauses a performance.
   * Pauses all Conductors.  The performance is resumed when
   * the factory receives the resume message.
   * The factory object's notion of the current time is suspended
   * until the performance is resumed.
   * It's illegal to pause an unclocked performance. Returns nil in this
   * case, otherwise returns the receiver.
   * Note that pausing a performance does not pause MidiIn, nor does it
   * pause any Instruments that have their own clocks. (e.g. MidiOut, and
   * the MKOrchestra).
   */
{	
   if ((!inPerformance)  || performanceIsPaused)
     return self;
   if (!isClocked || weGotMTC())
     return nil;
   [pauseTime autorelease];
   pauseTime = [[NSDate date] retain];
   if (separateThread)
     removeTimedEntry(pauseThread);
   else if (timedEntry != NOTIMEDENTRY) {
       [timedEntry invalidate];
       [timedEntry release];
   }
   timedEntry = NOTIMEDENTRY;
   performanceIsPaused = YES;
   return self;
}

+(BOOL)isPaused
  /* TYPE: Querying; YES if performance is paused.
   * Returns YES if the performance is paused.
   */
{
    return performanceIsPaused;
}

+resumePerformance
  /* TYPE: Controlling; Unpauses a paused performance.
   * Resumes a paused performance.
   * When the performance resumes, the notion of the
   * current time will be the same as when the factory
   * received the pause message --
   * time stops while the performance
   * is paused. It's illegal to resume a performance that's not clocked.
   * Returns nil in this case, otherwise returns the receiver.
   */
{	
    if ((!inPerformance)  || (!performanceIsPaused))
      return self;
    if (!isClocked)
      return nil;
    performanceIsPaused = NO;
    [startTime autorelease];
//    startTime += (getTime() - pauseTime);
    startTime = [[startTime addTimeInterval:[[NSDate date] timeIntervalSinceDate:pauseTime]] retain];
    /* We use cur-start to get the time since the start of the performance
       with all pauses removed. Thus by increasing startTime by the
       paused time, we remove the effect of the pause. */
    adjustTimedEntry(condQueue->nextMsgTime); 
    return self;
}

+ currentConductor
  /* TYPE: Querying; Returns the Conductor that's sending a message, if any.
   * Returns the Conductor that's in the process
   * of sending a message, or nil if no message
   * is currently being sent.
   */
{
    return curRunningCond;
}

+ setFinishWhenEmpty:(BOOL)yesOrNo
  /* TYPE: Modifying; Sets BOOL for continuing with empty queues.
   * If yesOrNo is NO (the default), the performance
   * is terminated when all the Conductors' message queues are empty.
   * If YES, the performance continues until the finishPerformance
   * message is sent.
   */
{
    dontHang = yesOrNo;
    return self;
}


+ setClocked:(BOOL)yesOrNo 
  /* TYPE: Modifying; Establishes clocked or unclocked performance.  
   * If yesOrNo is YES, messages are dispatched
   * at specific times.  If NO, they are sent 
   * as quickly as possible.
   * It's illegal to invoke this method while the performance is in progress.
   * Returns nil in this case, else self.
   * Initialized to YES.  
   */
{	
    if (inPerformance && ((yesOrNo && (!isClocked)) || ((!yesOrNo) && isClocked)))
        return nil;
    isClocked = yesOrNo;
    return self;
}

+(BOOL)isEmpty
  /* TYPE: Querying; YES if in performance and all queues are empty.
   * YES if the performance is active and all message queues are empty. 
   * (This can only happen if setFinishWhenEmpty:NO was sent.)
   */
{
    return ((!dontHang) && (inPerformance) && 
	    (!condQueue || ((ISENDOFTIME(condQueue->nextMsgTime) &&
			     mtcEndOfTime()))));
}

+(BOOL)finishWhenEmpty
  /* TYPE: Querying; YES if performance continues despite empty queues.
   * Returns NO if the performance is terminated when the
   * queues are empty, NO if the performance continues.
   */
{
    return dontHang;
}

+(BOOL) isClocked
  /* TYPE: Querying; YES if performance is clocked, NO if not.
   * Returns YES if messages are sent at specific times,
   * NO if they are sent as quickly as possible.
   */
{	
    return isClocked;
}

-activePerformers
{
    return activePerformers;
}

-(BOOL)isPaused 
  /* Returns YES if the receiver is paused. */
{
    return isPaused;
}

-_pause
  /* Used by MTC mechanism */
{
    if (isPaused)
      return self;
    isPaused = YES;
    repositionCond(self,PAUSETIME);
    if ([delegate respondsToSelector:@selector(conductorDidPause:)])
      [delegate conductorDidPause:self];
    return self;
}

-pause
  /* TYPE: Controlling; Pauses the receiver.
   * Pauses the performance of the receiver.
   * The effect on the receiver is restricted to
   * the present performance;
   * paused Conductors are automatically resumed at the end of each
   * performance.
   * Returns the receiver.
   */
{
    if (self == clockCond || MTCSynch)
      return nil;
    if (isPaused)
      return self;
    isPaused = YES;
    repositionCond(self,PAUSETIME);
    if ([delegate respondsToSelector:@selector(conductorDidPause:)])
      [delegate conductorDidPause:self];
    return self;
}

-_resume
  /* This is factored out of resume to avoid circularity in MTC
   * implementation.
   */
{
    if (!isPaused)
      return self;
    isPaused = NO;
    oldAdjustedClockTime = clockTime - _pauseOffset;
    repositionCond(self,beatToClock(self,PEEKTIME(_msgQueue)));
    pauseFor = MKCancelMsgRequest(pauseFor);
    return self;
}

-resume
  /* TYPE: Controlling; Resumes a paused receiver.
   * Resumes the receiver.  If the receiver isn't currently paused
   * (if it wasn't previously sent the pause message),
   * this has no effect.
   */
{
    if (MTCSynch)
      return nil;
    if (!isPaused)
      return self;
    [self _resume];
    if ([delegate respondsToSelector:@selector(conductorDidResume:)])
      [delegate conductorDidResume:self];
    return self;
}

-pauseFor:(double)seconds
{
    /* Pause it if it's not already paused. */
    if (seconds <= 0.0 || ![self pause]) 
      return nil;
    if (pauseFor)	/* Already doing a "pauseFor"? */
      MKRepositionMsgRequest(pauseFor,clockTime + seconds);
    else {             /* New "pauseFor". */
	pauseFor = MKNewMsgRequest(clockTime + seconds, @selector(resume),self,0);
	MKScheduleMsgRequest(pauseFor, clockCond); 
    }
    return self;
}

+ clockConductor
  /* TYPE: Querying; Returns the clockConductor. 
   * Returns the clockConductor.
   */
{ 	
    return clockCond;
}

-(double)setBeatSize:(double)newBeatSize
  /* TYPE: Tempo; Sets the tempo by resizing the beat.
   * Sets the tempo by changing the size of a beat to newBeatSize,
   * measuredin seconds.  The default beat size is 1.0 (one beat per
   * second).
   * Attempts to set the beat size of the clockConductor are ignored. 
   * Returns the previous beat size.
   */
{
    register double oldBeatSize;
    oldBeatSize = beatSize;
    if (self == clockCond)
      return oldBeatSize;
    beatSize  = newBeatSize;
    inverseBeatSize = 1.0/beatSize;
    if (curRunningCond != self && !isPaused) 
      repositionCond(self,beatToClock(self,PEEKTIME(self->_msgQueue)));
    return oldBeatSize;
}

-(double)setTempo:(double)newTempo
  /* TYPE: Tempo; Sets the tempo in beats per minute.
   * Sets the tempo to newTempo, measured in beats per minute.
   * Implemented as [self\ setBeatSize:(60.0/newTempo)].
   * Attempts to set the tempo of the clockConductor are ignored. 
   * Returns the previous tempo.
   */
{
    return 60.0 / [self setBeatSize: (60.0 / newTempo)];
}

-(double)setTimeOffset:(double)newTimeOffset
  /* TYPE: Tempo; Sets the receiver's timeOffset value in seconds.
   * Sets the number of seconds into the performance
   * that the receives waits before it begins processing
   * its message queue.  Notice that newtimeOffset is measured
   * in seconds -- it's not affected by the receiver's
   * tempo.
   * Attempts to set the timeOffset of the clockConductor are ignored. 
   * Returns the previous timeOffset.
   */
{
    double oldTimeOffset = timeOffset;
    if (self == clockCond)
      return timeOffset;
    else if (MTCSynch) {
	[self->MTCSynch _setMTCOffset:newTimeOffset];
	timeOffset = newTimeOffset;
	return oldTimeOffset;
    }
    if (inPerformance) 
      _pauseOffset = newTimeOffset - oldTimeOffset;
    timeOffset = newTimeOffset;
    if (curRunningCond != self && !isPaused) 
      repositionCond(self,beatToClock(self,PEEKTIME(self->_msgQueue)));
    return oldTimeOffset;
}

-(double)beatSize
  /* TYPE: Tempo; Returns the receiver's beat size in seconds.
   * Returns the size of the receiver's beat, in seconds.
   */
{
    return beatSize;
}

-(double)tempo
  /* TYPE: Tempo; Returns the receiver's tempo in beats per minute.
   * Returns the receiver's tempo in beats per minute.
   */
{
    return 60.0 * inverseBeatSize;
}

-(double)timeOffset
  /* TYPE: Tempo; Returns the receiver's timeOffset.
   * Returns the receiver's timeOffset value.
   */
{
    return timeOffset;
}

-sel:(SEL)aSelector to:(id)toObject withDelay:(double)deltaT 
 argCount:(int)argCount, ...;
/* TYPE: Requesting; Requests aSelector to be sent to toObject.
 * Schedules a request for the receiver
 * to send the message aSelector to the
 * object toObject at time deltaT beats from now.
 * argCount specifies the number of arguments to 
 * aSelector followed by the arguments themselves,
 * separated by commas (up to two arguments are allowed).
 * Returns the receiver unless argCount is too high, in which case returns nil.
 */
{
    id arg1,arg2;
    va_list ap;
    va_start(ap,argCount); 
    arg1 = va_arg(ap,id);
    arg2 = va_arg(ap,id);
    va_end(ap);	
    return insertMsgQueue(newMsgRequest(CONDUCTORFREES, self->time + deltaT,
					aSelector, toObject, argCount, arg1, arg2), self);
}

-sel:(SEL)aSelector to:(id)toObject atTime:(double)t
 argCount:(int)argCount, ...;
/* TYPE: Requesting; Requests aSelector to be sent to toObject.
 * Schedules a request for the receiver to send 
 * the message aSelector to the object toObject at
 * time t beats into the performance (offset by the
 * receiver's timeOffset).
 * argCount specifies the number of arguments to 
 * aSelector followed by the arguments themselves,
 * seperated by commas (up to two arguments are allowed).
 * Returns the receiver unless argCount is too high, in which case returns 
 * nil. 
 */
{
    id arg1,arg2;
    va_list ap;
    va_start(ap,argCount); 
    arg1 = va_arg(ap,id);
    arg2 = va_arg(ap,id);
    va_end(ap);	
    return insertMsgQueue(newMsgRequest(CONDUCTORFREES, t, aSelector, toObject, argCount, arg1, arg2), self);
}

- _runSetup
  /* Private method that inits a Conductor to run. */
{
    _pauseOffset = timeOffset;
    if (MTCSynch)
        return [self _pause];
    if (ISENDOFLIST(PEEKTIME(_msgQueue))) {
        nextMsgTime = MK_ENDOFTIME;
    }
    else {
//	nextMsgTime = PEEKTIME(_msgQueue) * beatSize + timeOffset;
//	nextMsgTime = MIN(nextMsgTime,MK_ENDOFTIME);    
        nextMsgTime = beatToClock(self,PEEKTIME(_msgQueue));
    }
    repositionCond(self,nextMsgTime);
    return self;
}

-(double)predictTime:(double)beatTime
  /* TYPE: Querying; Returns predicted time corresponding to beat.
   * Returns the time, in tempo-mapped time units,
   * corresponding to a specified beat time.  In our Conductor, this method
   * just assumes the tempo is a constant between now and beatTime.  That
   * is, it keeps no record of how tempo has changed, nor does it know the
   * future; it just computes based on the current time and tempo.  
   * More sophisticated tempo mappings an be added by subclassing
   * conductor. See "Ensemble Aspects of Computer Music", by David Jaffe,
   * CMJ (etc.) for details of tempo mappings. 
   */
{
    return beatToClock(self,beatTime);
}    

-(double)timeInBeats
  /* TYPE: Querying; Returns the receiver's notion of the current time.
   * Returns the receiver's notion of the current time
   * in beats.
   */
{	
    return self->time;
}

-emptyQueue
  /* TYPE: Requesting; Flushes the receiver's message queue.
   * Flushes the receiver's message queue and returns self.
   */
{
    register MKMsgStruct *curProc;
    while (!ISENDOFLIST(PEEKTIME(_msgQueue))) {
	curProc = popMsgQueue(&(_msgQueue));
        if (curProc) { /* This test shouldn't be needed */
            if (curProc->_conductorFrees)
                freeSp(curProc);
            else
                curProc->_onQueue = NO;
        }
    }
    if (!isPaused)
      repositionCond(self,MK_ENDOFTIME);
    return self;
}

-(BOOL)isCurrentConductor
  /* TYPE: Querying; YES if the receiver is sending a message.
   * Returns YES if the receiver
   * is currently sending a message.
   */
{
    return (curRunningCond == self);
}    

/* The following functions and equivalent methods
   give the application more control over 
   scheduling. In particular, they allow scheduling requests to be
   unqueued. They work as follows:

   MKNewMsgRequest() creates a new MKMsgStruct.
   MKScheduleMsgRequest() schedules up the request.
   MKCancelMsgRequest() cancels the request.

   Unless a MKCancelMsgRequest() is done, it is the application's 
   responsibility to NX_FREE the structure. On the other hand,
   if a  MKCancelMsgRequest() is done, the application must relinquish
   ownership of the MKMsgStruct and should not NX_FREE it.
   */

static void freeSp();

MKMsgStruct *
MKCancelMsgRequest(MKMsgStruct *aMsgStructPtr)
    /* Cancels MKScheduleMsgRequest() request and frees the structure. 
       Returns NULL.
       */
{
    if (!aMsgStructPtr)
      return NULL;
    if (!aMsgStructPtr->_conductor) { /* Special queue */
	/* Special queue messages are cancelled differently. Here we just
	   set the _toObject field to nil and leave the struct in the list. */
	if (!aMsgStructPtr->_toObject) /* Already canceled? */
	  return NULL;
        [aMsgStructPtr->_toObject release];
        [aMsgStructPtr->_arg1 release];
        [aMsgStructPtr->_arg2 release];
	aMsgStructPtr->_toObject = nil;
	aMsgStructPtr->_arg1 = nil;
	aMsgStructPtr->_arg2 = nil;
	if (aMsgStructPtr->_onQueue) 
	  aMsgStructPtr->_conductorFrees = YES;
	else freeSp(aMsgStructPtr);
	return NULL;
    }
    if (aMsgStructPtr->_onQueue) { /* Remove from ordinary queue */
	aMsgStructPtr->_next->_prev = aMsgStructPtr->_prev;
	if (aMsgStructPtr->_prev)
	  aMsgStructPtr->_prev->_next = aMsgStructPtr->_next;
	else {
	    MKConductor *conductor = aMsgStructPtr->_conductor;
	    conductor->_msgQueue = aMsgStructPtr->_next;
	    if ((curRunningCond != conductor) && !conductor->isPaused) {
		/* If our conductor is the running conductor, then 
		   repositionCond will be called by him so there's no need 
		   to do it here. */
		BOOL wasHeadOfQueue;
		double nextTime = beatToClock(conductor,
					      PEEKTIME(conductor->_msgQueue));
		wasHeadOfQueue = (conductor == condQueue);
		/* If we're the head of the queue, then the message we've
		   just deleted is enqueued to us with a timed entry. We've
		   got to do an adjustTimedEntry. */
		repositionCond(conductor,nextTime); 
		/* Need to check for inPerformance below because
		   repositionCond() can call finishPerformance. */
		/* If curRunningCond is non-nil, adjustTimedEntry will be 
		   done for us by masterConductorBody. */
		if (inPerformance && !curRunningCond && wasHeadOfQueue)
		  adjustTimedEntry(condQueue->nextMsgTime);
	    }
	}
    }
    [aMsgStructPtr->_toObject release];
    [aMsgStructPtr->_arg1 release];
    [aMsgStructPtr->_arg2 release];
    freeSp(aMsgStructPtr);
    return NULL;
}

MKMsgStruct *
MKNewMsgRequest(double timeOfMsg,SEL whichSelector,id destinationObject,
		int argCount,...)
    /* Creates a new msgStruct to be used with MKScheduleMsgRequest. 
       args may be ids or ints. The struct returned by MKNewMsgRequest
       should not be altered in any way. Its only use is to pass to
       MKCancelMsgRequest() and MKScheduleMsgRequest(). */
{
    id arg1,arg2;
    va_list ap;
    va_start(ap,argCount);
    arg1 = va_arg(ap,id);
    arg2 = va_arg(ap,id);
    va_end(ap);
    return newMsgRequest(TARGETFREES, timeOfMsg, whichSelector, destinationObject, argCount, arg1, arg2);
}	


void MKScheduleMsgRequest(MKMsgStruct *aMsgStructPtr, id conductor)
    /* Reschedule the specified msg. */
{
    if (aMsgStructPtr && conductor && (!aMsgStructPtr->_onQueue))
      insertMsgQueue(aMsgStructPtr,conductor);
}

MKMsgStruct *MKRescheduleMsgRequest(MKMsgStruct *aMsgStructPtr,id conductor,
				    double timeOfNewMsg,SEL whichSelector,
				    id destinationObject,int argCount,...)
    /* Reschedules the MKMsgStruct pointed to by aMsgStructPtr as indicated.
       If aMsgStructPtr is non-NULL and points to a message request currently
       in the queue, first cancels that request. Returns a pointer to the
       new MKMsgStruct. This function is equivalent to the following
       three function calls:
       MKNewMsgRequest() // New one
       MKScheduleMsgRequest() // New one 
       MKCancelMsgRequest() // Old one

       Note that aMsgStructPtr may be rescheduled with a different conductor,
       destinationObject and arguments, 
       than those used when it was previously scheduled.
       */
{
    MKMsgStruct *newMsgStructPtr;
    id arg1,arg2;
    va_list ap;
    va_start(ap,argCount);
    arg1 = va_arg(ap,id);
    arg2 = va_arg(ap,id);
    va_end(ap);
    newMsgStructPtr = newMsgRequest(TARGETFREES, timeOfNewMsg, whichSelector, destinationObject, argCount, arg1, arg2);
    MKScheduleMsgRequest(newMsgStructPtr,conductor);
    MKCancelMsgRequest(aMsgStructPtr); /* A noop if already canceled. */
    return aMsgStructPtr = newMsgStructPtr;
}

MKMsgStruct *MKRepositionMsgRequest(MKMsgStruct *aMsgStructPtr,
				    double timeOfNewMsg)
{
    MKMsgStruct *newMsgStructPtr = newMsgRequest(TARGETFREES,timeOfNewMsg,
						    aMsgStructPtr->_aSelector,
						    aMsgStructPtr->_toObject,
						    aMsgStructPtr->_argCount,
						    aMsgStructPtr->_arg1,
						    aMsgStructPtr->_arg2);
    MKScheduleMsgRequest(newMsgStructPtr,aMsgStructPtr->_conductor);
    MKCancelMsgRequest(aMsgStructPtr);
    return aMsgStructPtr = newMsgStructPtr;
}

static MKMsgStruct *newMsgRequest(
    BOOL doesConductorFree,
    double timeOfMsg,
    SEL whichSelector,
    id destinationObject,
    int argCount,
    id arg1,
    id arg2)
    /* Create a new msg struct */
{
    MKMsgStruct * sp;
    sp = allocSp();
    if ((sp->_conductorFrees = doesConductorFree) == TARGETFREES)
      sp->_methodImp = [destinationObject methodForSelector:whichSelector];
    sp->_timeOfMsg = timeOfMsg;
    sp->_aSelector = whichSelector;
    sp->_toObject = [destinationObject retain];
    sp->_argCount = argCount;
    sp->_next = NULL;
    sp->_prev = NULL;
    sp->_conductor = nil;
    sp->_onQueue = NO;
    switch (argCount) {
    default: 
	freeSp(sp);
	return NULL;
    case 2:
        sp->_arg2 = [arg2 retain];
    case 1:
        sp->_arg1 = [arg1 retain];
    case 0:
        break;
    }
    return(sp);
  return NULL;
}	

+(MKMsgStruct *)afterPerformanceSel:(SEL)aSelector 
 to:(id)toObject 
 argCount:(int)argCount, ...;
/* TYPE: Requesting; Sends aSelector to toObject after performance.
 * Schedules a request for the factory object
 * to send the message aSelector to the object
 * toObject immediately after the performance ends, regardless
 * of how it ends.
 * argCount specifies the number of arguments to 
 * aSelector followed by the arguments themselves,
 * seperated by commas.  Up to two arguments are allowed.
 * AfterPerfomance messages are sent in the order they were enqueued.
 * Returns a pointer to an MKMsgStruct that can be
 * passed to cancelMsgRequest:.
 */
{
    MKMsgStruct *sp;
    id arg1,arg2;
    va_list ap;

    va_start(ap,argCount); 
    arg1 = va_arg(ap,id);
    arg2 = va_arg(ap,id);
    afterPerformanceQueue = 
      insertSpecialQueue(sp = newMsgRequest(CONDUCTORFREES, MK_ENDOFTIME,
					    aSelector, toObject, argCount, arg1, arg2),
			 afterPerformanceQueue,&afterPerformanceQueueEnd);
    va_end(ap);

    return(sp);
}

+(MKMsgStruct *)beforePerformanceSel:(SEL)aSelector 
 to:(id)toObject 
 argCount:(int)argCount, ...;
/* TYPE: Requesting; Sends aSelector to toObject before performance.
 * Schedules a request for the factory object
 * to send the message aSelector to the object
 * toObject immediately before performance begins.
 * argCount specifies the number of arguments to 
 * aSelector followed by the arguments themselves,
 * seperated by commas.  Up to two arguments are allowed.
 * Messages requested through this method will be sent
 * before any other messages. beforePerformance messages are sent in the
 * order they were enqueued.
 * Returns a pointer to an MKMsgStruct that can be
 * passed to cancelMsgRequest:.
 */
{
    MKMsgStruct *sp;
    id arg1,arg2;
    va_list ap;

    va_start(ap,argCount); 
    arg1 = va_arg(ap,id);
    arg2 = va_arg(ap,id);
    beforePerformanceQueue = 
      insertSpecialQueue(sp = newMsgRequest(CONDUCTORFREES,0.0,
					    aSelector,toObject,argCount,
					    arg1,arg2),
			 beforePerformanceQueue,&beforePerformanceQueueEnd);
    va_end(ap);
    return(sp);
}

static MKMsgStruct *evalSpecialQueue(MKMsgStruct *queue, MKMsgStruct **queueEnd)
    /* Sends all messages in the special queue, e.g. afterPerformanceQueue.
     */
{
    register MKMsgStruct *curProc;

    while (queue) {
        curProc = popMsgQueue(&(queue));
        if (curProc == *queueEnd)
            *queueEnd = NULL;
        if(curProc->_toObject) {  // ensure we have a valid object to perform a selector
            switch (curProc->_argCount) {
            case 0:
                [curProc->_toObject performSelector:curProc->_aSelector];
                break;
            case 1:
                [curProc->_toObject performSelector:curProc->_aSelector withObject:curProc->_arg1];
                break;
            case 2:
                [curProc->_toObject performSelector:curProc->_aSelector withObject:curProc->_arg1 withObject:curProc->_arg2];
                break;
            default:
                break;
            }
        }
//	else {
//            NSLog(@"Warning, nil object on special queue\n");
//      }
        if (curProc->_conductorFrees)
            freeSp(curProc);
    }    
    return NULL;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
  /* TYPE: Archiving; Writes object.
     You never send this message directly.  
     Archives beatSize and timeOffset. Also archives whether this
     was the clockConductor or defaultConductor.
     */
{
//    [super encodeWithCoder:aCoder];//sb: unnec?
    [aCoder encodeValuesOfObjCTypes: "ddc", &beatSize, &timeOffset, &(archivingFlags)];
    [aCoder encodeConditionalObject: delegate];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* TYPE: Archiving; Reads object.
     You never send this message directly.  
     Should be invoked with NXReadObject(). 
     See write: and finishUnarchiving.
     */
{
    delegateFlags = 0;
    if ([aDecoder versionForClassName:@"MKConductor"] >= VERSION2) {
        [aDecoder decodeValuesOfObjCTypes: "ddc", &beatSize, &timeOffset, &(archivingFlags)];
        activePerformers = nil;
    }
    if ([aDecoder versionForClassName:@"MKConductor"] >= VERSION3) {
          activePerformers = [[aDecoder decodeObject] retain];
    }
    return self;
}

- awakeAfterUsingCoder:(NSCoder *)aDecoder
  /* If the unarchived object was the clockConductor, frees the new object
     and returns the clockConductor. Otherwise, if there is a performance
     going on, frees the new object and returns the defaultConductor. 
     Otherwise, if the unarchived object was the defaultConductor, sets the 
     defaultConductor's beatSize and timeOffset from the unarchived object,
     frees the new object and returns the defaultConductor.
     Otherwise, the new unarchived Conductor is added to the Conductor
     list and nil is returned. */
{
    if (archivingFlags == CLOCKCOND) {
        if (delegate)
            [clockCond setDelegate:delegate];
        [super release];
        return clockCond;
    } else if (inPerformance) {
        [super release];
        return defaultCond;
    } else if (archivingFlags == DEFAULTCOND) {
        [defaultCond setDelegate:delegate];
        [defaultCond setBeatSize:beatSize];
        [defaultCond setTimeOffset:timeOffset];
        [super release];
        return defaultCond;
    } 
    [allConductors addObject:self];
    inverseBeatSize = 1.0/beatSize;
    [self _initialize];

    return self;
}

+ (void)setDelegate:object
{
    delegateRespondsToLowThresholdMsg = 
      [object respondsToSelector:@selector(conductorCrossedLowDeltaTThreshold)];
    delegateRespondsToHighThresholdMsg = 
      [object respondsToSelector:@selector(conductorCrossedHighDeltaTThreshold)];
    delegateRespondsToThresholdMsgs = (delegateRespondsToLowThresholdMsg ||
				       delegateRespondsToHighThresholdMsg);
    classDelegate = object;
    return;
}

+ delegate 
{
    return classDelegate;
}

- (void)setDelegate:(id)object
{
    unsigned char flags;
    delegate = object;
    if (!delegate) {
        delegateFlags = 0;
        return;
    }
    flags = 0;
    if ([self->delegate respondsToSelector:@selector(beatToClock:from:)]) 
      flags = BEAT_TO_CLOCK;
    if ([self->delegate respondsToSelector:@selector(clockToBeat:from:)]) 
      flags |= CLOCK_TO_BEAT;
    delegateFlags = flags;
}

-delegate
{
    return delegate;
}

#if 0
/* Needed to get around a compiler bug FIXME */
static double getNextMsgTime(MKConductor *aCond)
{
    return aCond->nextMsgTime;
}
#endif

// for debugging
- (NSString *) description
{
//    MKMsgStruct *p;
    NSString *queue = [NSString stringWithFormat:
        @"MKConductor 0x%x\n  Next conductor 0x%x, Last conductor 0x%x\n", self, _condNext, _condLast];
    NSString *timeStr = [NSString stringWithFormat: @"  time %lf beats, nextMsgTime %lf, timeOffset %lf\n",
       time, nextMsgTime, timeOffset];
    NSString *beatTime = [NSString stringWithFormat:
        @"  beatSize %lf Secs, inverseBeatSize %lf, oldAdjustedClockTime %lf\n",
        beatSize, inverseBeatSize, oldAdjustedClockTime];
    NSString *misc = [NSString stringWithFormat:
        @"  archivingFlags %x, delegateFlags %x, delegate %@, activePerformers %@, MTCSynch %@\n",
        archivingFlags, delegateFlags, delegate, activePerformers, MTCSynch];
    NSString *pausing = [NSString stringWithFormat:
        @"  %s, pauseOffset = %lf, pauseFor = 0x%x\n",
        isPaused ? "Paused" : "Not paused", _pauseOffset, pauseFor];
    NSString *msgs = [NSString stringWithFormat: @"  msgQueue = 0x%x: ", _msgQueue];

//    for(p = _msgQueue; p != NULL; p = p->_next) {
//        [msgs stringByAppendingFormat: @"t %lf [%@ arg1:%@ arg2:%@] conductor %s \n",
//            p->_timeOfMsg, p->_toObject, p->_arg1, p->_arg2, p->_conductorFrees ? "frees" : "doesn't free"];
//        [msgs stringByAppendingFormat: @"t %lf\n",
//           p->_timeOfMsg];
//    }

    return [queue stringByAppendingFormat: @"%@%@%@\n%@%@", timeStr, beatTime, msgs, pausing, misc];
}

#import "mtcConductor.m"

@end

#import "mtcConductorPrivate.m"

@implementation MKConductor(Private)

+ (void) masterConductorBody:(NSTimer *) unusedTimer
/*sb: created for the change from DPS timers to OS-style timers. The timer performs a method, not
 * a function. It's a class method because we want only one object to look after these messages.
 * When called from a separate thread, it will not actually be called from a NSTimer, but after a timed condition lock.
 * Therefore we should never do anything with unusedTimer.
 */
{
    MKMsgStruct  *curProc;

    _MKLock();  // ensure we can do our thang uninterrupted.
    // Since masterConductorBody can be called from a NSTimer in a separate thread NSRunLoop without being
    // able to check the performance status, it's possible for the performance to end while waiting, 
    // such that by the time we arrive here, we don't want to perform anything, so we split this crazy scene...
    if(!inPerformance) {
        if (MKIsTraced(MK_TRACECONDUCTOR))
            NSLog(@"Early escape from masterConductorBody as not in performance\n"); 
        _MKUnlock(); // drop the lock before this early out.
        return;
    }

    /* Preamble */
    curRunningCond = condQueue;
    // NSLog(@"Setting time via masterConductorBody\n");
    setTime(condQueue->nextMsgTime);

    /* Here is the meat of the conductor's performance. */
    do {
        // NSLog(@"curRunningCond %x\n", curRunningCond);
        curProc = popMsgQueue(&(curRunningCond->_msgQueue));
        if (curProc->_timeOfMsg > curRunningCond->time) // IMPORTANT--Performers can give us negative vals
            curRunningCond->time = curProc->_timeOfMsg;
        if (MKIsTraced(MK_TRACECONDUCTOR))
            NSLog(@"t %f\n", clockTime);
        if (!curProc->_conductorFrees) {
            // NSLog(@"I'm not supposed to free %d, %@\n", curProc->_argCount, curProc->_toObject);
            // NSLog(@"separateThreaded %d and in MusicKit thread %d\n", separateThread, separateThreadedAndInMusicKitThread());
            curProc->_onQueue = NO;  // LMS this is neccessary but why?
            switch (curProc->_argCount) {
            case 0:
                (*curProc->_methodImp)(curProc->_toObject, curProc->_aSelector);
                break;
            case 1:
                (*curProc->_methodImp)(curProc->_toObject, curProc->_aSelector, curProc->_arg1);
                break;
            case 2:
                (*curProc->_methodImp)(curProc->_toObject, curProc->_aSelector, curProc->_arg1, curProc->_arg2);
                break;
            }
            // NSLog(@"Returned from method call (conductor doesnt free) %@ sepThreadMK %d\n", 
	    // curProc->_toObject, separateThreadedAndInMusicKitThread());
        }
        else {
            // NSLog(@"I'm supposed to free %@\n", curProc->_toObject);
            switch (curProc->_argCount) {
            case 0:
                [curProc->_toObject performSelector:curProc->_aSelector];
                break;
            case 1:
                [curProc->_toObject performSelector:curProc->_aSelector withObject:curProc->_arg1];
                break;
            case 2:
                [curProc->_toObject performSelector:curProc->_aSelector withObject:curProc->_arg1 withObject:curProc->_arg2];
                break;
            default:
                break;
            }
            // NSLog(@"Returned from method call (conductor frees)\n");
            freeSp(curProc);
        }
        // NSLog(@"curRunningCond at end of loop %x\n", curRunningCond);
    } while (PEEKTIME(curRunningCond->_msgQueue)  <= curRunningCond->time);


    if (!curRunningCond->isPaused) {
        double theNextTime = PEEKTIME(curRunningCond->_msgQueue);
        repositionCond(curRunningCond,beatToClock(curRunningCond,theNextTime));
    }
    // If at the end, repositionCond triggers [MKConductor finishPerformance].
    // If this occurs, adjustTimedEntry is a noop (see masterConductorBody:).
    [_MKClassOrchestra() flushTimedMessages];

    /* Postamble */
    // NSLog(@"Setting curRunningCond nil\n");
    curRunningCond = nil;
    if (inPerformance) {        /* Performance can be ended by repositionCond(). */
        adjustTimedEntry(condQueue->nextMsgTime);
    }
    _MKUnlock();
}

+(MKMsgStruct *)_afterPerformanceSel:(SEL)aSelector 
 to:(id)toObject 
 argCount:(int)argCount, ...;
/* 
  Same as afterPerformanceSel:to:argCount: but ensures that message will
  be sent before any of the messages enqueued with that method. Private
  to the musickit.
*/
{
    MKMsgStruct *sp;
    id arg1,arg2;
    va_list ap;
    va_start(ap,argCount); 
    arg1 = va_arg(ap,id);
    arg2 = va_arg(ap,id);
    _afterPerformanceQueue = 
      insertSpecialQueue(sp = newMsgRequest(CONDUCTORFREES,MK_ENDOFTIME,
					    aSelector,toObject,argCount,
					    arg1,arg2),
			 _afterPerformanceQueue,&_afterPerformanceQueueEnd);
    va_end(ap);
    return(sp);
}

+(MKMsgStruct *)_newMsgRequestAtTime:(double)timeOfMsg
  sel:(SEL)whichSelector to:(id)destinationObject
  argCount:(int)argCount, ...;
/* TYPE: Requesting; Creates and returns a new message request.
 * Creates and returns message request but doesn't schedule it.
 * The return value can be passed as an argument to the
 * _scheduleMsgRequest: and _cancelMsgRequest: methods.
 *
 * You should only invoke this method if you need greater control
 * over scheduling (for instance if you need to cancel a message request)
 * than that afforded by the sel:to:atTime:argCount: and
 * sel:to:withDelay:argCount: methods.
 */
{
    id arg1,arg2;
    va_list ap;
    va_start(ap,argCount); 
    arg1 = va_arg(ap,id);
    arg2 = va_arg(ap,id);
    va_end(ap);
    return newMsgRequest(TARGETFREES, timeOfMsg, whichSelector, destinationObject, argCount, arg1, arg2);
}

-(void)_scheduleMsgRequest:(MKMsgStruct *)aMsgStructPtr
  /* TYPE: Requesting; Schedules a message request with the receiver.
   * Sorts the message request aMsgStructPtr
   * into the receiver's message queue.  aMsgStructPtr is 
   * a pointer to an MKMsgStruct, such as returned by
   * _newMsgRequestAtTime:sel:to:argCount:.
   */
{
    if (aMsgStructPtr && (!aMsgStructPtr->_onQueue))
        insertMsgQueue(aMsgStructPtr,self);
}

+(void)_scheduleMsgRequest:(MKMsgStruct *)aMsgStructPtr
  /* Same as _scheduleMsgRequest: but uses clock conductor. 
   */
{
    if (aMsgStructPtr && (!aMsgStructPtr->_onQueue))
        insertMsgQueue(aMsgStructPtr,clockCond);
}

-(MKMsgStruct *)_rescheduleMsgRequest:(MKMsgStruct *)aMsgStructPtr
  atTime:(double)timeOfNewMsg sel:(SEL)whichSelector
  to:(id)destinationObject argCount:(int)argCount, ...;
  /* TYPE: Requesting; Reschedules a message request with the receiver.
   * Redefines the message request aMsgStructPtr according
   * to the following arguments and resorts
   * it into the receiver's message queue.
   * aMsgStructPtr is 
   * a pointer to an MKMsgStruct, such as returned by
   * _newMsgRequestAtTime:sel:to:argCount:.
   */

/* Same as MKReschedule */
{
    id arg1,arg2;
    va_list ap;
    va_start(ap,argCount); 
    arg1 = va_arg(ap,id);
    arg2 = va_arg(ap,id);
    return MKRescheduleMsgRequest(aMsgStructPtr,self,timeOfNewMsg,
    		whichSelector,destinationObject,argCount,arg1,
				  arg2);
    va_end(ap);
}


+(MKMsgStruct *)_cancelMsgRequest:(MKMsgStruct *)aMsgStructPtr
  /* TYPE: Requesting; Cancels the message request aMsgStructPtr.
   * Removes the message request pointed to by
   * aMsgStructPtr. 
   * Notice that this is a factory method -- you don't have to
   * know which queue the message request is on to cancel it.
   * aMsgStructPtr is 
   * a pointer to an MKMsgStruct, such as returned by
   * _newMsgRequestAtTime:sel:to:argCount:.
   */
{
    return MKCancelMsgRequest(aMsgStructPtr);
}

+(double)_adjustTimeNoTE:(double)desiredTime     
  /* TYPE: Modifying; Sets the current time to desiredTime.
   * Sets the factory's notion of the current time to
   * desiredTime.  desiredTime is clipped
   * to a value not less than the time that the previous message
   * was sent and not greater than that of the
   * next scheduled message.
   * Returns the adjusted time.
   */
{
    double t;
    if (!inPerformance || performanceIsPaused)
      return clockTime;
    /* FIXME Should maybe do a gettime() and compare with the time
      we've been handed. If they're different, we need to 
      adjust startTime (subtract difference) and then adjust timed entry.
      */
    t = MIN(desiredTime, condQueue->nextMsgTime);
    t = MAX(t, clockTime);
    setTime(t);
    return clockTime;
}

+(double)_getLastTime
  /* See time.m: _MKLastTime(). */ 
{
    return (clockTime != 0.0) ? clockTime : oldClockTime;
}

+_adjustDeltaTThresholds
{
    double dt = -MKGetDeltaT();
    deltaTThresholdLow = dt * (1 - deltaTThresholdLowPC);
    deltaTThresholdHigh = dt * (1 - deltaTThresholdHighPC);
    if (deltaTThresholdLow > deltaTThresholdHigh)
      deltaTThresholdLow = deltaTThresholdHigh;
    return self;
}

// private error message method signalling an internal error from sending the end-of-list marker
// an NSString is immutable and therefore thread-safe.
- _error: (NSString *) errorMsg
{
   MKError(errorMsg);
   return self;
}

@end

