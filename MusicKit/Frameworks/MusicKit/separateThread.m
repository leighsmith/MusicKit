/*
  $Id$
  Defined In: The MusicKit

  Description:
    This source file should be included by MKConductor.m. It includes
    the MKConductor code relevant to running the MKConductor in a background
    thread.

    Restrictions on use of locking mechanism:
    See ~david/doc/thread-restrictions

  Original Author: David A. Jaffe, Mike Minnick

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/* 
  Modification history:

  $Log$
  Revision 1.15  2000/04/16 04:06:55  leigh
  Removed debugging messages

  Revision 1.14  2000/04/08 00:59:04  leigh
  Fixed bug when inPerformance set during final pending masterConductorBody

  Revision 1.13  2000/04/02 17:21:22  leigh
  set receive port of waking MKThread to nil, fixing crash

  Revision 1.12  2000/04/01 01:17:23  leigh
  made timeToWait checks use method interface in prep for moving separateThread to its own category. Properly defined NSPort workaround

  Revision 1.11  2000/03/31 00:04:40  leigh
  Moved the MK->AppKit communication to _MKAppProxy

  Revision 1.10  2000/03/27 16:53:58  leigh
  Removed mach messaging from separateThreadLoop

  Revision 1.9  2000/01/27 19:17:58  leigh
  Now using NSPort replacing C Mach port API, disabled the ErrorStream disabling (since NSLog is thread-safe)

  Revision 1.8  2000/01/24 22:00:49  leigh
  Manipulating MKToAppPort via the NSPort class

  Revision 1.7  2000/01/13 06:41:13  leigh
  Corrected _MKErrorf to take NSString error message

  Revision 1.6  1999/12/20 17:07:53  leigh
  Removed faulty diagnostic message

  Revision 1.5  1999/11/14 21:30:16  leigh
  Corrected _MKErrorf arguments to be NSStrings

  Revision 1.4  1999/09/10 02:47:45  leigh
  removed warnings

  Revision 1.3  1999/09/04 22:59:18  leigh
  Big overhaul, replaced cthreads with NSThreads, rec_mutexs with NSLocks

  Revision 1.2  1999/07/29 01:26:16  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  07/27/90/daj - Created.
  08/10/90/daj - Added thread_policy setting. 
  08/13/90/daj - Added enabling of FIXEDPRI policy for apps running as root
                 (or for apps running in an environment in which FIXEDPRI
		 policy has been enabled.)
  08/17/90/daj - Added cthread_yield when we're "behind".
  08/18/90/daj - Added lock as first thing in separate thread.
  08/20/90/daj - Added _MKGetConductorThreadStress and 
                 _MKSetConductorMaxThreadStress
  09/04/90/daj - Added check for overflow of msg_receive timeout.
  09/06/90/daj - Added additional bit poll to make sure things haven't changed
                 out from under us. Also added terminating of thread from
		 removeTimedEntry to avoid bad situations when someone does
		 a finishPerformance followed by startPerformance while holding
		 the lock!
  09/26/90/daj - Added adjustTimedEntry() if needed after MIDI is received.
                 (Formerly, timedEntry->timeToWait was not being reset unless
		 something is rescheduled for the head of the queue. Thus,
		 the time between the last scheduled event and the incoming
		 MIDI was not being subtracted.)
  09/29/90/daj - Changed to use condition signal to flush old thread.
  10/01/90/daj - Changed resetPriority to always do it.		 
  12/12/90/daj - Plugged memory leak in _MKRemovePort() 
  03/05/91/daj - Changed to new scheme of doing fixed policy.
  04/22/91/daj - Changed separate-threaded finishPerformance to do longjmp
  07/22/91/daj - Changed unlockIt() to NOT do a recursive lock in certain
                 cases, thus making buggy user code more likely to work.
		 (Especially, this fixes the case where the user does a 
		 lockPerformance followed by a finishPerformance from the 
		 Music Kit thread.) 
  08/27/91/daj - Simplified error messages.
  11/17/92/daj - Added more robust search for fixedpolicy
  07/1/93/daj -  Added an arg to machErr for more descritptive error reporting.
  02/7/94/daj -  Changed to only unlock/lock when timeout != 0
  11/5/94/daj -  Changed thread endgame
*/

//#import <mach/mach.h>
//#import <mach/mach_error.h>
#import <setjmp.h>
#import "ConductorPrivate.h"
#import "_musickit.h"
#import "_error.h"

#define COND_ERROR NSLocalizedStringFromTableInBundle(@"MKConductor encountered problem.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs if the Music Kit's MKConductor class encounters a Mach error (this should never happen, so this error should never appear--in particular, it should never be seen by the user).")

static NSRecursiveLock *musicKitLock = nil;
static NSThread *musicKitThread = nil;
static NSThread *lockingThread = nil;
static NSTimer *threadTimedEntry = nil;
// static NSLock *musicKitAbortCondition = nil;  // for now unused.

// Locking definitions.
#define nonrecursive 0
#define recursive 1
#define lockIt() { lockingThread = [NSThread currentThread]; [musicKitLock lock]; }
// LMS: at the moment, we always recursively unlock (ignoring _x) until we determine exactly when we shouldn't
#define unlockIt(_x) [musicKitLock unlock]


// thread priority
#define PRIORITY_THREADING 0  // LMS: disabled until we find an OpenStep way of changing thread priority...i.e forever.

#if PRIORITY_THREADING
static float threadPriorityFactor = 0.0;
static BOOL useFixedPolicy = NO;
static int oldPriority = MAXINT;

#define INVALID_POLICY -1          /* cf /usr/include/sys/policy.h */
#define QUANTUM 100                /* in ms */

static int oldPolicy = INVALID_POLICY;
#endif

#if defined(__ppc__) && defined(ppc)
#define NSMessagePort NSPort  // fudge around MacOsX-Server old concrete NSPort for MacOsX-Server or OpenStep
#endif

static NSMessagePort *appToMKPortObj = nil; /*sb: added these 2 to provide NSPort objects */
static NSMessagePort *MKToAppPortObj = nil; /*    that contain the actual ports.          */
static NSString *interThreadThreshold = nil;
static BOOL wakeUpCall = NO; /* See below */

/* Forward declarations */ 
static void adjustTimedEntry(double nextMsgTime);

// Should declare this as part of the MKConductor category, not include it.
// Unfortunately that would mean making many variables and functions public when they are currently private (static).
// @implementation MKConductor(SeparateThread)

+ useSeparateThread:(BOOL)yesOrNo
  /* Returns self if successful. It's illegal to change this during a 
     performance. */
{
    if (inPerformance)
      return nil;
    if ([_MKClassMidi() _disableThreadChange])
      return nil;
    separateThread = yesOrNo;
    return self;
}

+ (NSThread *) performanceThread
  /* In a separate-threaded MusicKit performance, returns the NSThread
     used in that performance.  When the thread is finished, returns
     NO_CTHREAD. */
{
    return musicKitThread;
}

/* The idea here is that Mach over-protects us and only allows us to use
   the fixed priority scheme if it's enabled. But it can only be enabled
   if we're running as root.  So we invoke a small setuid command-line program
   to enable the fixed policy.
 */
+ setThreadPriority:(float)priorityFactor
{
#if PRIORITY_THREADING // LMS: disabled for safety for now 
    static BOOL fixedPolicyEnabled = NO;
    NSFileManager *manager = [NSFileManager defaultManager];

    if (priorityFactor < 0.0 || priorityFactor > 1.0)
      return nil;
    threadPriorityFactor = priorityFactor;
    if (priorityFactor > 0.0) { /* See if we can used fixed priority sched */
	NSString** buff1 = NULL;
	if (!fixedPolicyEnabled) { /* Only do it first time. */
	    if (_MKFindAppWrapperFile(@"fixedpolicy",buff1)) {
                system([[*buff1 stringByAppendingString:@" -e -q"] cString]);
	    }
	    else {
        	if ([manager fileExistsAtPath: @"/usr/local/lib/MusicKit/bin/fixedpolicy"]) {
		    system("/usr/local/lib/MusicKit/bin/fixedpolicy -e -q");
		}
		else if ([manager fileExistsAtPath: @"/usr/lib/MusicKit/bin/fixedpolicy"]) {
		    system("/usr/lib/MusicKit/bin/fixedpolicy -e -q");
		}
	    }
	    fixedPolicyEnabled = YES;
	}
	useFixedPolicy = YES;
    }
    else
       useFixedPolicy = NO;
#endif
    return self;
}

void _MKLock(void) 
{ lockIt(); }

void _MKUnlock(void) 
{ unlockIt(recursive); }     

+ lockPerformance
{  
    lockIt();
    if (inPerformance)
      [self adjustTime];
    return self;
}

+ (BOOL) lockPerformanceNoBlock
{
    if ([musicKitLock tryLock]) {
	if (inPerformance)
	  [self adjustTime];
	return YES;
    }
    return NO;
}

+ unlockPerformance
{
    [_MKClassOrchestra() flushTimedMessages]; /* A no-op if no Orchestra */
    unlockIt(recursive);
    return self;
}

static BOOL musicKitHasLock(void)
    /* Returns YES if we are in a multi-threaded performance and the
       Music Kit has the lock.  Note that no mutex is needed around this
       function because the function is assumed to be called from either
       within the Music Kit or from the Appkit with the Music Kit lock. 
       I.e. whoever calls this has the Music Kit lock so its return value
       can't change out from under the caller until the caller himself
       releases the lock.
       */
{
    return (musicKitThread != nil &&       
	    lockingThread == musicKitThread);
}

// Fires a message to the MusicKit thread to wake it out of it's slumber.
// Typically this occurs from a pause scheduling a wait till the end of time (MK_ENDOFTIME).
/* LMS: I think this comment still holds. I don't think it really matters.
   The way this is currently implemented, an extra context switch
   gets done. The alternative is to not send the message until
   the _MKUnlock(). But this is more complicated (since multiple
   messages may cancel each other out) and should be left
   as an optimization, if needed.
*/
static void sendMessageToWakeUpMKThread(void)
{
    // Create a valid but empty message.
    NSPortMessage *msg = [[NSPortMessage alloc] initWithSendPort: appToMKPortObj
						     receivePort: nil   // I think this is the correct way to have no reply.
                                                      components: [NSArray arrayWithObject: [NSData data]]];

    /*  We send the message only when someone other than the Music Kit has
	the lock. If we're not in performance, the value of musicKitThread
	and lockingThread will both be nil. The assumption here
	is that the caller has the lock if we are in performance. */
    if (!separateThread ||
        musicKitThread == nil ||            // Not in performance?
        lockingThread == musicKitThread) {  // Ensure MK doesn't have the lock
	return;
    }
    wakeUpCall = YES;
    [msg sendBeforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.020]];  // 20mSec's *should* be plenty.
    [msg release];
}

/* We have to do this complicated thing because the NSThread class doesn't
   support a terminate method to terminate another thread. 
 */
static void killMusicKitThread(void)
{
    if (musicKitThread == nil)
        return;
    if (MKIsTraced(MK_TRACECONDUCTOR))
        NSLog(@"Attempting to kill the MK Thread\n");

    // This is only called by a function that has checked it is not in the MusicKit thread.
    // Must check if the current thread (known to not be the musicKitThread) has the lock.
    lockIt();
    // Since we've got the lock, we know that the Music Kit thread is either
    // in a NSRunLoop wait or waiting for the lock.
    sendMessageToWakeUpMKThread();             /* Get the MK thread out of its deep sleep (if paused). */
    // Can't use thread_abort() here because it's possible (unlikely) that thread has not
    // even received the initial lock yet!
    unlockIt(recursive);
}

static BOOL separateThreadedAndNotInMusicKitThread(void)
{
    return (musicKitThread != nil && [NSThread currentThread] != musicKitThread); 
}

BOOL separateThreadedAndInMusicKitThread(void)
{
    return ([NSThread currentThread] == musicKitThread); 
}

/* Destroys the timed entry. */
static void removeTimedEntry(int arg)
{
    switch (arg) {
        case pauseThread:
            if (MKIsTraced(MK_TRACECONDUCTOR))
                NSLog(@"Pausing separate thread\n");
            adjustTimedEntry(MK_ENDOFTIME); // just wait for a long, long time.
            break;
        case exitThread:
            if (MKIsTraced(MK_TRACECONDUCTOR))
                NSLog(@"Exiting separate thread\n");
            if (separateThreadedAndNotInMusicKitThread())
                killMusicKitThread();
	    break;
        default:
	    break;
    }
}

/* Will the following scenario work and is it safe?

   Thread A is sitting in a msg_receive on a port set.  
   Thread B removes a port from that port set.

   What is funny about this example is that normally when thread A is in
   the msg_receive, it doesn't have the lock. Therefore, thread B thinks it
   can modify the data. But the one piece of data thread A is still using
   is the port set!

   The alternative is, I guess, the following:

   Thread B sends a message to thread A, thus rousing it from the msg_receive
   and telling thread A to add the port that thread B wanted to add.

   ***THIS IS OK according to Mike DeMoney 18Jun90.  Also according to tech doc on
      msg_receive()***

*/
// If this is in main thread, its NSRunLoop looks after incoming messages.
// If it is not in the main thread, the port is added to the port set. From there, messages are caught
// by separateThreadLoop. From there, they are sent as plain old objC messages.
// After all, we assume that if both the calling function AND the conductor are in the other thread,
// it's ok to send normal objC messages between them.
void _MKAddPort(NSPort *aPort,
                id handlerObj,
		unsigned max_msg_size, // unused
		void *anArg,  // unused
		NSString *priority) // unused, but should be
{
    if (!allConductors)
        condInit();
    [aPort setDelegate:handlerObj];

    // If we are separate threaded, this will associate with the appropriate NSRunLoop of the MK thread.
    // Otherwise it will associate with the NSRunLoop of the AppKit thread.
    [[NSRunLoop currentRunLoop] addPort: aPort forMode: separateThread ? interThreadThreshold : NSDefaultRunLoopMode];
}

void _MKRemovePort(NSPort *aPort)
{
    if (!allConductors)
      condInit();
    /* OK to remove port, even if in performance -- see above. */
    [[NSRunLoop currentRunLoop] removePort: aPort forMode: NSDefaultRunLoopMode];
    [aPort invalidate];
    [aPort autorelease];
}

static id sendObjcMsg(id toObject,SEL aSelector,int argCount,id arg1,id arg2)
{
    switch (argCount) {
      case 0:
          [toObject performSelector:aSelector];
	break;
      case 1:
          [toObject performSelector:aSelector withObject:arg1];
	break;
      case 2:
          [toObject performSelector:aSelector withObject:arg1 withObject:arg2];
	break;
      default: 
	return nil;
    }
    return toObject;
}
    
/* The following method handles Port messages received by the MK thread. 
 * The NSPort delegate has to repond to selector +handlePortMessage
 */
+ (void) handlePortMessage: (NSPortMessage *) portMessage
{
    if (wakeUpCall) { // It's a wakeup rather than a timeout.
        // NSLog(@"Handling MachMessage as a wakeup call, limit date %@\n",
        //    [[NSRunLoop currentRunLoop] limitDateForMode: interThreadThreshold]);
        wakeUpCall = NO;
        [threadTimedEntry invalidate];
        // NSLog(@"new limit date %@\n", [[NSRunLoop currentRunLoop] limitDateForMode: interThreadThreshold]);
    }
    else {
        // NSLog(@"Handling port Message not as a wakeup call");
    }
}

+sendMsgToApplicationThreadSel:(SEL)aSelector 
  to:(id)toObject 
  argCount:(int)argCount, ...;
{
    id arg1,arg2;
    va_list ap;
    va_start(ap,argCount); 
    arg1 = va_arg(ap,id);
    arg2 = va_arg(ap,id);
    va_end(ap);	
    if (separateThreadedAndInMusicKitThread()) {
        /* i.e. this means that the MKConductor has been called from WITHIN the detached
         * MusicKit thread, and has to send a message back to the main AppKit thread. The message
         * is a Mach message, caught by the NSPort/NSRunLoop handler as an ObjC
         * method, and dispatched from handlePortMessage: in AppProxy.
         */
#if 0 // disabled until we decide how to do NSConnections.
	/* Sends a Mach message */
        mainThreadUserMsg msg;
        msg.header.msg_unused = 0;
        msg.header.msg_simple=TRUE;
        msg.header.msg_size=sizeof(mainThreadUserMsg);
        msg.header.msg_type=MSG_TYPE_NORMAL;
        msg.header.msg_local_port = PORT_NULL;
        msg.header.msg_remote_port = [MKToAppPortObj machPort];
        msg.header.msg_id = MSGTYPE_USER;
        /* Now the type-specific fields */
        msg.toObject = toObject;
        msg.aSelector = aSelector;
        msg.argCount = argCount;
        msg.arg1 = arg1;
        msg.arg2 = arg2;

        /* end of sb changes */
//	(void)msg_send(&msg.header, SEND_TIMEOUT, 0);
	(void)msg_send(&msg.header, MSG_OPTION_NONE, 0);  /* Jan, 1996-DAJ */
#endif
    }
    else { /* Just send it */
	if (!sendObjcMsg(toObject,aSelector,argCount,arg1,arg2))
	    return nil;
    }
    return self;
}

+setInterThreadThreshold:(NSString *)newThreshold
/* this seems fairly unnecessary, but its been left in. It should work ok. */
{
    if ([NSThread currentThread] == musicKitThread) 
	return nil;
    [MKConductor lockPerformance];
    
    if (interThreadThreshold == nil)
        interThreadThreshold = NSDefaultRunLoopMode;
    
    [[NSRunLoop currentRunLoop] removePort:MKToAppPortObj forMode:interThreadThreshold];
    /*sb: I am simply using the previous value of interThreadThreshold here, and hoping that it is indeed
        the value that was used to set up the thread. It may not be...?
        */
    
    interThreadThreshold = newThreshold;

    [[NSRunLoop currentRunLoop] addPort:MKToAppPortObj forMode:interThreadThreshold]; 
    return [MKConductor unlockPerformance];
}

/* Must be called from App thread. Called once when the MKConductor is initialized. */
static void initializeBackgroundThread()
{
    _MKAppProxy *appProxy = [[_MKAppProxy alloc] init];
    musicKitLock = [[NSRecursiveLock alloc] init];

    appToMKPortObj = [[NSMessagePort alloc] init];
    if (appToMKPortObj == nil)
        _MKErrorf(MK_musicKitErr, COND_ERROR, 0, @"initializeBackgroundThread"); //TODO
    [appToMKPortObj setDelegate:[MKConductor class]]; // MKConductor handles messages from the AppKit to the MK (just wakeups)

    MKToAppPortObj = [[NSMessagePort alloc] init];
    if (MKToAppPortObj == nil)
        _MKErrorf(MK_musicKitErr, COND_ERROR, 0, @"initializeBackgroundThread"); //TODO
    [MKToAppPortObj setDelegate: appProxy]; // AppProxy handles messages from the MK to the AppKit
    
    if (interThreadThreshold == nil)
        interThreadThreshold = NSDefaultRunLoopMode;

    [[NSRunLoop currentRunLoop] addPort:MKToAppPortObj forMode:interThreadThreshold]; 
}

#if PRIORITY_THREADING // LMS: disabled until we find a OpenStep way of changing thread priority...i.e forever.
static BOOL getThreadInfo(int *info)
{
    kern_return_t ec;
    unsigned int count = THREAD_INFO_MAX;
    ec = thread_info(thread_self(), THREAD_SCHED_INFO, (thread_info_t)info, &count);
    if (ec != KERN_SUCCESS) {
	_MKErrorf(MK_machErr, COND_ERROR, mach_error_string(ec), @"getThreadInfo");
	return NO;
    }
    return YES;
}
#endif

#if PRIORITY_THREADING // LMS: disabled until we find a OpenStep way of changing thread priority...i.e forever.
static BOOL setThreadPriority(int priority)
{
   kern_return_t ec = thread_priority(thread_self(), priority, 0);
    if (ec != KERN_SUCCESS) {
	_MKErrorf(MK_machErr, COND_ERROR,
		  mach_error_string(ec), @"setThreadPriority");
	return NO;
    }
    return YES;
}
#endif

static void setPriority(void)
{
#if PRIORITY_THREADING // LMS: disabled until we find a OpenStep way of changing thread priority...i.e forever.
    int info[THREAD_INFO_MAX];
    thread_sched_info_t sched_info;
    if (threadPriorityFactor == 0.0 || /* No change */
	!getThreadInfo(info))
      return;
    sched_info = (thread_sched_info_t)info;
    /*
     * Increase our thread priority to our current max priority.
     * (Unless base priority is already greater than max, as can happen 
     * with nice -20!)
     */
    if (useFixedPolicy && (sched_info->policy != POLICY_FIXEDPRI)) {
	oldPolicy = sched_info->policy;
	thread_policy(thread_self(), POLICY_FIXEDPRI, QUANTUM);
    } else oldPolicy = INVALID_POLICY;
    if (sched_info->base_priority < sched_info->max_priority) {
	oldPriority = sched_info->base_priority;
	/* Set it to (max - base) * threadPriorityFactor + base */
	setThreadPriority(((sched_info->max_priority - 
			    sched_info->base_priority) * threadPriorityFactor) 
			  + sched_info->base_priority);
    } else oldPriority = MAXINT; /* No priority to be set. */
#endif
}

static void resetPriority(void)
{
#if PRIORITY_THREADING // LMS: disabled until we find a OpenStep way of changing thread priority...i.e forever.
    int info[THREAD_INFO_MAX];
    thread_sched_info_t sched_info;
    if (oldPolicy != INVALID_POLICY) /* Reset it only if it was set. */
      thread_policy(thread_self(), oldPolicy, QUANTUM);
    if (oldPriority == MAXINT ||  /* No change */
	!getThreadInfo(info))
      return;
    sched_info = (thread_sched_info_t)info;
    setThreadPriority(oldPriority);
    oldPriority = MAXINT;
#endif
}

//@end

//@implementation MKConductor(SeparateThreadPrivate)

// This is the main loop for a separate-threaded performance.
+ (void) separateThreadLoop
{
    double timeToWait; // In fractions of seconds
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    NSRunLoop *theLoop = [NSRunLoop currentRunLoop];

    lockIt();                // Must be the first thing in this function
    musicKitThread = [NSThread currentThread];
    setPriority();           // if ever this does something, we may need to retrieve the currentRunLoop afterwards.
    [theLoop addPort: appToMKPortObj forMode: interThreadThreshold];
    [condQueue retain];      // I'm not sure this is neccessary, but we do have an errant autorelease on condQueue somewhere.

    while ([MKConductor inPerformance]) {
        // finishPerformance can be called from within the MusicKit thread
        // or from the AppKit thread.  In both cases, inPerformance gets
        // set to NO. In the AppKit thread case, we also send a message
        // (with sendMessageToWakeUpMKThread) to kick the MusicKit thread outta bed.

        /**************************** GOODNIGHT ***************************/
        timeToWait = ([MKConductor isPaused] ? MK_ENDOFTIME :
                      ([MKConductor isClocked] ? _MKTheTimeToWait(condQueue->nextMsgTime) : 0.0));

        if (MKIsTraced(MK_TRACECONDUCTOR))
            NSLog(@"timeToWait in seconds %lf\n", timeToWait);
        // We better have the lock and we know we  want to give it up. By making this
        // nonrecursive, we actually make the code more forgiving here.
        unlockIt(nonrecursive); 

        // if we need to wait longer than 100uSec, use the timer, this is just a zero check.
	if(timeToWait > 0.00001) { 
            threadTimedEntry = [[NSTimer timerWithTimeInterval: timeToWait
                                target: [MKConductor class]
                                selector: @selector(masterConductorBody:)
                                userInfo: nil
                                repeats: NO] retain];
            [theLoop addTimer: threadTimedEntry forMode: interThreadThreshold];

            // This wakes up when a message arrives, checking the appToMKPortObj and other _MKAddPort added NSPorts
            // until timeout. On waking, the masterConductorBody will be performed.
            // [theLoop acceptInputForMode: interThreadThreshold beforeDate: [theLoop limitDateForMode: interThreadThreshold]];
            [theLoop runUntilDate: [NSDate dateWithTimeIntervalSinceNow: timeToWait]];
	}
	else {
            [MKConductor masterConductorBody: nil];
	}

        /**************************** IT'S MORNING! *************************/
        /* If the desire is to exit the thread, this will be
           accomplished by the setting of inPerformance to false.
           If the desire is to pause the thread, this will be
           accomplished by the setting of timedEntry to MK_ENDOFTIME.
           If the desire is to reposition the thread, this will be
           accomplished by the setting of timedEntry to the new
           time. */
        // NSLog(@"Exited runloop probably with timeout\n");
        lockIt();
    }
    if (MKIsTraced(MK_TRACECONDUCTOR))
        NSLog(@"Exited the inPerformance loop\n");
    resetPriority();
    musicKitThread = nil;
    [condQueue release];      // I'm not sure this is neccessary, but we do have an errant autorelease on condQueue somewhere.
    unlockIt(nonrecursive);

    [pool release];
}

static void launchThread(void)
{
    lockIt(); /* Make sure thread has had a chance to start up. */
    // As MKConductor class method, or should it be an instance method?
    [NSThread detachNewThreadSelector: @selector(separateThreadLoop) toTarget: [MKConductor self] withObject: nil];
    unlockIt(nonrecursive);
}

// @end