/*
  $Id$
  Defined In: The MusicKit

  Description:
    This source file should be included by MKConductor.m. It includes
    the MKConductor code relevant to running the MKConductor in a background
    thread.

  Original Author: David A. Jaffe, Mike Minnick

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/* 
  Modification history prior to commit to CVS:

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

#import "ConductorPrivate.h"
#import "_musickit.h"
#import "_error.h"

#define COND_ERROR NSLocalizedStringFromTableInBundle(@"MKConductor encountered problem.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs if the MusicKit's MKConductor class encounters a Mach error (this should never happen, so this error should never appear--in particular, it should never be seen by the user).")

#ifdef __MINGW32__
#define NSConditionLock SndConditionLock
#endif

#define MKCONDUCTOR_DEBUG 0

static NSRecursiveLock *musicKitLock = nil;
static NSThread *musicKitThread = nil;
static NSThread *lockingThread = nil;
static NSConditionLock *abortPlayLock = nil;  // Used to abort a playing separate thread.

// Locking definitions.
#define nonrecursive 0
#define recursive 1

// TODO better describe what this "lock" actually protects.
#define lockIt() { lockingThread = [NSThread currentThread]; [musicKitLock lock]; }
// LMS: at the moment, we always recursively unlock (ignoring _x) until we determine exactly when we shouldn't
// #define unlockIt(_x) [musicKitLock unlock]
#define unlockIt(_x) { [musicKitLock unlock]; lockingThread = nil; }
#define MK_ABORTED_PLAYING 1
#define MK_PLAYING_UNINTERRUPTED 0

// thread priority
// LMS: disabled until we find an OpenStep way of changing thread priority...i.e probably forever.
//#define PRIORITY_THREADING 1  

#if PRIORITY_THREADING
static float threadPriorityFactor = 0.0;
static BOOL useFixedPolicy = NO;
static int oldPriority = MAXINT;

#define INVALID_POLICY -1          /* cf /usr/include/sys/policy.h */
#define QUANTUM 100                /* in ms */

static int oldPolicy = INVALID_POLICY;
#endif

// Defines ports used in several methods to communicate in one direction and in one thread each.
// Represents sending messages from the application (i.e main) thread to the MK separate conductor thread.
// static NSPort *appToMKPort = nil;  
// Represents receiving messages from MK separate conductor thread to the application (i.e main) thread.
// static NSPort *MKToAppPort = nil;
static NSString *interThreadThreshold = nil;
// static NSConnection *appConnection = nil;

/* Forward declarations */ 
static void adjustTimedEntry(double nextMsgTime);

// Should declare this as part of the MKConductor category, not include it.
// Unfortunately that would mean making many variables and functions public when they are currently private (static).
// @implementation MKConductor(SeparateThread)

+ useSeparateThread: (BOOL) yesOrNo
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

+ (BOOL) separateThreaded
{
    return separateThread;
}

+ (BOOL) separateThreadedAndInMusicKitThread
{
    return (separateThread && 
            musicKitThread != nil &&
            [musicKitThread isEqual: [NSThread currentThread]]);
}

/* The idea here is that Mach over-protects us and only allows us to use
   the fixed priority scheme if it's enabled. But it can only be enabled
   if we're running as root.  So we invoke a small setuid command-line program
   to enable the fixed policy.
 */
+ setThreadPriority: (float) priorityFactor
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
{
    lockIt();
}

void _MKUnlock(void) 
{
    unlockIt(recursive); 
}

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
    [_MKClassOrchestra() flushTimedMessages]; /* A no-op if no MKOrchestra */
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
    BOOL hasLock = musicKitThread != nil && lockingThread == musicKitThread;
    // NSLog(@"MusicKit Has Lock = %d, musicKitThread %@ lockingThread %@\n", hasLock, musicKitThread, lockingThread);
    return hasLock;
}

// Fires a message to the MusicKit thread to wake it out of it's slumber.
// Typically this occurs from a pause scheduling a wait till the end of time (MK_ENDOFTIME).
static void sendMessageToWakeUpMKThread(void)
{
    // We send the message only when someone other than the Music Kit has
    // the lock. If we're not in performance, the value of musicKitThread
    // and lockingThread will both be nil. The assumption here
    // is that the caller has the lock if we are in performance.
    
    // Ensure MK doesn't have the lock
    if (separateThread && !musicKitHasLock()) {
        // NSLog(@"Sending message to wake up MK thread\n");

        // So get the MK thread out of its timed condition lock deep sleep.
        [abortPlayLock unlockWithCondition: MK_ABORTED_PLAYING]; 
    }
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
    // Since we've got the lock, we know that the MusicKit thread is either
    // waiting in a timed condition lock for the abort or waiting for the lock.
    sendMessageToWakeUpMKThread();

    unlockIt(recursive);
}

static BOOL notInMusicKitThread(void)
{
    return musicKitThread != nil && 
           ![musicKitThread isEqual: [NSThread currentThread]]; 
}

/* Destroys the timed entry. */
static void removeTimedEntry(int arg)
{
    switch (arg) {
    case pauseThread:
        if (MKIsTraced(MK_TRACECONDUCTOR))
            NSLog(@"Pausing separate thread\n");
        adjustTimedEntry(MK_ENDOFTIME); // pausing consists of waiting for a long, long time.
        break;
    case exitThread:
        if (MKIsTraced(MK_TRACECONDUCTOR))
            NSLog(@"Exiting separate thread\n");
        if (separateThread && notInMusicKitThread())
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
    [aPort setDelegate: handlerObj];

    // If we are separate threaded, this will associate with the appropriate NSRunLoop of the MK thread.
    // Otherwise it will associate with the NSRunLoop of the AppKit thread.
    [[NSRunLoop currentRunLoop] addPort: aPort 
                                forMode: separateThread ? interThreadThreshold : NSDefaultRunLoopMode];
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

static id sendObjcMsg(id toObject, SEL aSelector, int argCount, id arg1, id arg2)
{
    switch (argCount) {
    case 0:
        [toObject performSelector: aSelector];
	break;
    case 1:
        [toObject performSelector: aSelector withObject: arg1];
	break;
    case 2:
        [toObject performSelector: aSelector withObject: arg1 withObject: arg2];
	break;
    default: 
	return nil;
    }
    return toObject;
}
    
+ sendMsgToApplicationThreadSel: (SEL) aSelector 
			     to: (id) toObject 
		       argCount: (int) argCount, ...;
{
    id arg1, arg2;
    va_list ap;
    
    va_start(ap, argCount); 
    arg1 = va_arg(ap, id);
    arg2 = va_arg(ap, id);
    va_end(ap);	
    if ([self separateThreadedAndInMusicKitThread]) {
        /* i.e. this means that the MKConductor has been called from WITHIN the detached
         * MusicKit thread, and has to send a message back to the main application thread. The message
         * is a Mach message, caught by the NSPort/NSRunLoop handler as an ObjC
         * method, and dispatched from handlePortMessage: in AppProxy.
         */
        [self sendMessageInMainThreadToTarget: toObject 
                                          sel: aSelector 
                                         arg1: arg1 
                                         arg2: arg2 
                                        count: argCount];
    }
    else { /* Just send it */
	if (!sendObjcMsg(toObject, aSelector, argCount, arg1, arg2))
	    return nil;
    }
    return self;
}

+ setInterThreadThreshold: (NSString *) newThreshold
/* this seems fairly unnecessary, but its been left in. It should work ok. */
{
    if ([self separateThreadedAndInMusicKitThread]) 
	return nil;
    [MKConductor lockPerformance];
    
    if (interThreadThreshold == nil)
        interThreadThreshold = NSDefaultRunLoopMode;
    
    // [[NSRunLoop currentRunLoop] removePort: MKToAppPort forMode: interThreadThreshold];
    /*sb: I am simply using the previous value of interThreadThreshold here, and hoping that it is indeed
        the value that was used to set up the thread. It may not be...?
        */
    
    interThreadThreshold = newThreshold;

    // [[NSRunLoop currentRunLoop] addPort:MKToAppPort forMode:interThreadThreshold]; 
    return [MKConductor unlockPerformance];
}

// Must be called from the application thread. Called once when the MKConductor is initialized.
// We use an NSConnection to communicate from the application thread to the separate conductor (MK) thread.
// Since we only need to do this when we are stopping or pausing, restarting etc (wakeup), the latency
// in the connection management will be low enough for this purpose.
// We can get away with NSConnection for the MK to application communication, again, because the messages are
// sparse and since the data being transported is roughly equivalent to the earlier mach port implementation.
static void initializeBackgroundThread()
{
    // _MKAppProxy *appProxy = [[_MKAppProxy alloc] init];
    musicKitLock = [[NSRecursiveLock alloc] init];
    abortPlayLock = [[NSConditionLock alloc] initWithCondition: MK_PLAYING_UNINTERRUPTED];

    // MKConductor doesn't need messages from the application to the MK (just wakeups via abortPlayLock)
    // appToMKPort = [NSPort port];
    // if (appToMKPort == nil)
    //     MKErrorCode(MK_musicKitErr, COND_ERROR, 0, @"initializeBackgroundThread"); //TODO

    // appProxy handles object messages from the MK thread to the application
    // MKToAppPort = [NSPort port];
    // if (MKToAppPort == nil)
    //    MKErrorCode(MK_musicKitErr, COND_ERROR, 0, @"initializeBackgroundThread"); //TODO
    
    // appConnection = [[NSConnection alloc] initWithReceivePort: MKToAppPort sendPort: appToMKPort];
    // [appConnection setRootObject: appProxy];  // for receiving messages from MK thread to the application thread.
    // 1 second *should* be plenty of time for a NSConnection message to be processed correctly.
    // Any longer than this and we assume the message is blocked waiting on the queue to free, in which case
    // the lock should be released.
    // [appConnection setRequestTimeout: 1.0];      

    if (interThreadThreshold == nil)
        interThreadThreshold = NSDefaultRunLoopMode;
    // We should probably do the following, if we start monkeying with the interThreadThreshold
    // aka the run loop mode.
    // [appConnection addRequestMode: interThreadThreshold];
}

#if PRIORITY_THREADING // LMS: disabled until we find a OpenStep way of changing thread priority...i.e probably forever.
static BOOL getThreadInfo(int *info)
{
    kern_return_t ec;
    unsigned int count = THREAD_INFO_MAX;
    ec = thread_info(thread_self(), THREAD_SCHED_INFO, (thread_info_t)info, &count);
    if (ec != KERN_SUCCESS) {
        MKErrorCode(MK_machErr, COND_ERROR, mach_error_string(ec), @"getThreadInfo");
        return NO;
    }
    return YES;
}

static BOOL setThreadPriority(int priority)
{
    kern_return_t ec = thread_priority(thread_self(), priority, 0);
    if (ec != KERN_SUCCESS) {
        MKErrorCode(MK_machErr, COND_ERROR,
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
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    double timeToWait; // In fractions of seconds

    lockIt();                // Must be the first thing in this function
    [abortPlayLock initWithCondition: MK_PLAYING_UNINTERRUPTED];
    musicKitThread = [[NSThread currentThread] retain];
    setPriority();           // if ever this does something, we may need to retrieve the currentRunLoop afterwards.

    while ([MKConductor inPerformance]) {
        BOOL didAbort;

        // finishPerformance can be called from within the MusicKit thread
        // or from the application thread.  In both cases, inPerformance gets
        // set to NO. In the application thread case, we also set the MK_ABORTED_PLAYING
        //  condition on abortPlayLock (in sendMessageToWakeUpMKThread) to kick the MusicKit
        // thread outta bed.

        timeToWait = ([MKConductor isPaused] ? MK_ENDOFTIME :
                      ([MKConductor isClocked] ? _MKTheTimeToWait(condQueue->nextMsgTime) : 0.0));

        if (MKIsTraced(MK_TRACECONDUCTOR))
            NSLog(@"timeToWait in seconds %lf\n", timeToWait);

        // if we need to wait longer than 100 uSec, use the timed condition lock, this is just a zero check.
        if(timeToWait > 0.0001) { 
            // We better have the lock and we know we want to give it up.
            unlockIt(recursive); 

            /**************************** GOODNIGHT ***************************/
            // This wakes up when an abort message arrives or until timeout.
            // On waking, the masterConductorBody will be performed.
            didAbort = [abortPlayLock lockWhenCondition: MK_ABORTED_PLAYING 
                                             beforeDate: [NSDate dateWithTimeIntervalSinceNow: timeToWait]];
            /**************************** IT'S MORNING! *************************/
            // If the desire is to exit the thread, this will be
            // accomplished by the setting of inPerformance to false.
            // If the desire is to pause the thread, this will be
            // accomplished by the setting of timedEntry to MK_ENDOFTIME.
            // If the desire is to reposition the thread, this will be
            // accomplished by the setting of timedEntry to the new
            // time.
            // NSLog(@"Exited timed condition lock either with timeout or abort condition, waiting on lock\n");
            lockIt();
            // check if we aborted, preventing calling masterConductorBody
            if(!didAbort)
                [MKConductor masterConductorBody: nil];
                
        }
        else
            [MKConductor masterConductorBody: nil];
    }
    if (MKIsTraced(MK_TRACECONDUCTOR))
        NSLog(@"Exited the inPerformance loop\n");
    resetPriority();
    musicKitThread = nil;
    unlockIt(nonrecursive);

    [pool release];
    [NSThread exit];
}

static void launchThread(void)
{
    lockIt();                   // Make sure thread has had a chance to start up.
    [NSThread detachNewThreadSelector: @selector(separateThreadLoop) toTarget: [MKConductor self] withObject: nil];
    unlockIt(nonrecursive);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// the following routines stolen out of the (working) implementations for message passing in the
// SndKit. sbrandon, 19/3/2002

static    char            bgdm_sem;
static    NSConditionLock *bgdm_threadLock;
static    NSLock          *delegateMessageArrayLock;
static    NSMutableArray  *delegateMessageArray;
static    NSConnection    *threadConnection;
static    BOOL             bDelegateMessagingEnabled;
//static    BOOL             isStopping;

enum {
    BGDM_ready,
    BGDM_hasFlag,
    BGDM_abortNow,
    BGDM_delegateMessageReady,
    BGDM_threadStopped,
    BGDM_threadInactive
};

////////////////////////////////////////////////////////////////////////////////
// delegateMessageThread:
////////////////////////////////////////////////////////////////////////////////

+ (void) delegateMessageThread:(NSArray*) ports
{
    NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
    id controllerProxy = nil;
    
    [self retain];
    
#if MKCONDUCTOR_DEBUG
    NSLog(@"MKConductor::entering delegate thread\n");
#endif
    
    while (bgdm_sem != BGDM_threadStopped) {
	[bgdm_threadLock lockWhenCondition: BGDM_hasFlag];
	if (bgdm_sem == BGDM_delegateMessageReady)  {
	    NSInvocation *delegateMessage = nil;
	    int count;
	    
      // quickly release the lock so we don't deadlock if the queued messages take
      // a while to go through.
	    [bgdm_threadLock unlockWithCondition: bgdm_sem];
	    while (1) {
		[delegateMessageArrayLock lock];
		count = [delegateMessageArray count];
		if (count) {
		    delegateMessage = [[delegateMessageArray objectAtIndex: 0] retain];
		    [delegateMessageArray removeObjectAtIndex: 0];
		}
		[delegateMessageArrayLock unlock];
		if (!count)
		    break;
		if (!controllerProxy) {
		    NSConnection *theConnection = [NSConnection connectionWithReceivePort: [ports objectAtIndex: 0]
										 sendPort: [ports objectAtIndex: 1]];
          // Note: if there's a problem with the NSRunLoop not running or
          // responding here, the -rootProxy method will block. We could
          // set a timout here and catch the exception thrown as a result,
          // but there may be valid reasons why the NSRunLoop does not respond
          // (perhaps the main loop is busy doing other stuff?). THis could do
          // with some testing cos I think a timeout exception would be the
          // best way forward.
		    
          //[theConnection setReplyTimeout:0.1];
		    controllerProxy = [theConnection rootProxy];
// this causes a problem, and shouldn't, becuase the same code works in the SndKit!
//          [controllerProxy setProtocolForProxy:@protocol(SndDelegateMessagePassing)];
		}
		/* cast to unsigned long to prevent compiler warnings */
		[controllerProxy _sendDelegateInvocation:(unsigned long)delegateMessage];
	    }
	    continue;
	}
	else if (bgdm_sem == BGDM_abortNow) {
#if MKCONDUCTOR_DEBUG
	    NSLog(@"MKConductor::Killing delegate message thread.\n");
#endif
	    bgdm_sem = BGDM_threadStopped;
	    break;
	}
	else {
	    fprintf(stderr,"Semaphore status: %i\n", bgdm_sem);
	    bgdm_sem = BGDM_ready;
	}
	[bgdm_threadLock unlockWithCondition: bgdm_sem];
    }
    [self release];
    [localPool release];
    /* even if there is a new thread is created between the following two
     * statements, that would be ok -- there would temporarily be one
     * extra thread but it won't cause a problem
     */
#if MKCONDUCTOR_DEBUG
    NSLog(@"MKConductor::exiting delegate thread\n");
#endif
    
    [NSThread exit];
}

+ (void) detachDelegateMessageThread
{
    NSPort *managerReceivePort,*managerSendPort;
    
    if (bDelegateMessagingEnabled) {
	return;
    }
    bgdm_threadLock = [[NSConditionLock alloc] initWithCondition: BGDM_ready];
    delegateMessageArrayLock = [[NSLock alloc] init];
    bDelegateMessagingEnabled = FALSE;
    
    if ([[NSRunLoop currentRunLoop] currentMode] || NSApp) {
#if MKCONDUCTOR_DEBUG
	fprintf(stderr,"[MKConductor::detachDelegateMessageThread] Run loop detected - delegate messaging enabled\n");
#endif
	delegateMessageArray = [[NSMutableArray alloc] init];
	managerReceivePort   = (NSPort *)[NSPort port]; /* we don't need to retain, the connection does that */
	managerSendPort      = (NSPort *)[NSPort port];
	
	threadConnection     = [[NSConnection alloc] initWithReceivePort: managerReceivePort
								sendPort: managerSendPort];
	[threadConnection setRootObject:self];
	
	[NSThread detachNewThreadSelector: @selector(delegateMessageThread:)
				 toTarget: self
			       withObject: [NSArray arrayWithObjects: managerSendPort, managerReceivePort, nil]];
	bDelegateMessagingEnabled = TRUE;
    }
    else {
#if MKCONDUCTOR_DEBUG
	fprintf(stderr,"[MKConductor::detachDelegateMessageThread] No runloop or NSApp detected - delegate messaging disabled\n");
#endif
    }
}

////////////////////////////////////////////////////////////////////////////////
// _sendDelegateInvocation:
//
// we cast to unsigned long to prevent MacOSX (and maybe GNUstep) from interpreting
// the argument as an NSInvocation. When it does this, it tries to be too smart, and
// creates a connection to the object in the thread the NSInvocation was created in
// (which is what we're trying to avoid).
//
////////////////////////////////////////////////////////////////////////////////

+ (void) _sendDelegateInvocation:(in unsigned long) mesg
    /* this should only be called while in the main thread. Internal use only. */
{
    [(NSInvocation *)mesg invoke];
}

////////////////////////////////////////////////////////////////////////////////
// sendMessageInMainThreadToTarget:sel:arg1:arg2:
////////////////////////////////////////////////////////////////////////////////

+ (void) sendMessageInMainThreadToTarget:(id)target sel:(SEL)sel arg1:(id)arg1 arg2:(id)arg2 count:(int)count
{
    if (!bDelegateMessagingEnabled) {
	return;
    }
    else {
	NSMethodSignature *aSignature   = [[target class] instanceMethodSignatureForSelector:sel];
	NSInvocation      *anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
	
	[anInvocation setSelector:sel];
	[anInvocation setTarget:target];
	if (count > 0) [anInvocation setArgument:&arg1 atIndex:2];
	if (count > 1) [anInvocation setArgument:&arg2 atIndex:3];
	[anInvocation retainArguments];
	
	[delegateMessageArrayLock lock];
	[delegateMessageArray addObject: anInvocation];
	[delegateMessageArrayLock unlock];
	
	[bgdm_threadLock lock];
	bgdm_sem = BGDM_delegateMessageReady;
	[bgdm_threadLock unlockWithCondition:BGDM_hasFlag];
    }
}

// @end
