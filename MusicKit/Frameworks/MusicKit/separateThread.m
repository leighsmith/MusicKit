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

#import <mach/mach.h>
#import <mach/mach_init.h>
#import <mach/mach_error.h>
#import	<mach/message.h>
#import "_error.h"

#define COND_ERROR NSLocalizedStringFromTableInBundle(@"MKConductor encountered problem.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs if the Music Kit's MKConductor class encounters a Mach error (this should never happen, so this error should never appear--in particular, it should never be seen by the user).")

static NSRecursiveLock *musicKitLock = nil;  
static NSThread *musicKitThread = nil;
static NSThread *appKitThread = nil;
static NSThread *lockingThread = nil;
static NSLock *musicKitAbortCondition = nil;  

// Locking definitions.
#define nonrecursive 0
#define recursive 1
#define lockIt() { lockingThread = [NSThread currentThread]; [musicKitLock lock]; }
// LMS: at the moment, we always recursively unlock (ignoring _x) until we determine exactly when we shouldn't
#define unlockIt(_x) [musicKitLock unlock]

typedef enum _backgroundThreadAction {
    exitThread,
    pauseThread
} backgroundThreadAction;

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

static port_name_t appToMKPort;
static port_name_t MKToAppPort;
static NSPort* appToMKPortObj = nil; /*sb: added these 2 to provide NSPort objects */
static NSPort* MKToAppPortObj = nil; /*    that contain the actual ports.          */

/* Forward declarations */ 
static void adjustTimedEntry(double nextMsgTime);
static void emptyAppToMKPort(void);

// Should declare this as part of the MKConductor category, not include it.

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
#if PRIORITY_THREADING // LMS: disabled for safty for now 
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

/* May want to look at this some time: */
#if 0
static BOOL getProcessorSetInfo(port_t privPortSet,int *info)
{
    kern_return_t ec;
    unsigned int count = PROCESSOR_SET_INFO_MAX;
    ec = processor_set_info(privPortSet, PROCESSOR_SET_SCHED_INFO, host_self(),
			    (processor_set_info_t)info,
			    &count);
    if (ec != KERN_SUCCESS) {
	_MKErrorf(MK_machErr, @"Can't get processor set scheduling info",
		  mach_error_string(ec), @"processor_set_info");
	return NO;
    }
    return YES;
}
#endif

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

static BOOL thingsHaveChanged = NO; /* See below */

static void sendMessageIfNeeded()
{
	/* The way this is currently implemented, an extra context switch
	   gets done. The alternative is to not send the message until 
	   the _MKUnlock(). But this is more complicated (since multiple
	   messages may cancel each other out) and should be left
	   as an optimization, if needed. */

    kern_return_t ec;
    msg_header_t msg =    {0,                   /* msg_unused */
                           TRUE,                /* msg_simple */
			   sizeof(msg_header_t),/* msg_size */
			   MSG_TYPE_NORMAL,     /* msg_type */
			   0};                  /* Fills in remaining fields */
    if (!separateThread)
      return;

    /*  We send the message only when someone other than the Music Kit has
	the lock. If we're not in performance, the value of musicKitThread
	and lockingThread will both be nil. The assumption here
	is that the caller has the lock if we are in performance. */
    if (musicKitThread == nil ||       /* Not in performance? */
        lockingThread == musicKitThread) {  /* MK doesn't have the lock */
	return;
    }

    thingsHaveChanged = YES; /* Added Sep6,90 by daj */
    msg.msg_local_port = PORT_NULL;
    msg.msg_remote_port = appToMKPort;
    /*  If we ever want to pass a simple message identification to the other 
	thread, we can do it in	msg.msg_id */

    ec = msg_send(&msg, SEND_TIMEOUT, 0);
    if (ec == SEND_TIMED_OUT)
      ;	/* message queue is full, don't need to send another */
    else if (ec != KERN_SUCCESS)
      _MKErrorf(MK_machErr, COND_ERROR, mach_error_string(ec), @"sendMessageIfNeeded");
}

static void killMusicKitThread(void)
{
  /* We have to do this complicated thing because the cthread package doesn't
     support a terminate function. */
//  int count;
  if (musicKitThread == nil)
    return;
  if (MKIsTraced(MK_TRACECONDUCTOR))
    NSLog(@"attempting to kill musicKitThread\n");

  // This is only called by a function that has checked it is not in the MusicKit thread.
  // Must check if the current thread (known to not be the musicKitThread) has the lock.
  if (lockingThread == [NSThread currentThread]) { // Must be holding lock to do this
    /* Since we've got the lock, we know that the Music Kit thread is either
       in a msg_receive or waiting for the lock. */
    sendMessageIfNeeded();             /* Get it out of msg_receive */
                                       /* Can't use thread_abort() here
					  because it's possible (unlikely)
					  that thread has not even gotten the
					  initial lock yet! */
// LMS: FIXME Danger Will Robinson! This is totally kludged out and I've yet to stress test things to
// see if we need them. So far, it seems to work...
//    count = musicKitLock->count;       /* Save the count */
//    musicKitLock->count = 0;           /* Fudge the rec_mutex for now */
//    musicKitLock->thread = NO_CTHREAD;
    /* Wait for it to be done */
//    [musicKitAbortCondition lock];
//    musicKitLock->count = count;       /* Fix up the rec_mutex */        
//    musicKitLock->thread = [NSThread currentThread];
  }
  unlockIt(recursive);
}

static BOOL separateThreadedAndNotInMusicKitThread(void)
{
    return (musicKitThread != nil && [NSThread currentThread] != musicKitThread); 
}

static BOOL separateThreadedAndInMusicKitThread(void)
{
    return ([NSThread currentThread] == musicKitThread); 
}

static void removeTimedEntry(int arg)
  /* Destroys the timed entry. Made to be compatable with dpsclient version */
{
    // NSLog(@"removing timed entry\n");
    switch (arg) {
        case pauseThread:
            adjustTimedEntry(MK_ENDOFTIME);
            break;
        case exitThread:
            if (separateThreadedAndNotInMusicKitThread())
                killMusicKitThread ();
	    break;
        default:
	    break;
    }
}

static port_set_name_t conductorPortSet = 0;

/* This is made exactly parallel to dpsclient, in case we ever want to
   export it. */
/*sb: in OpenStep we have moved away from this paradigm (I think) so I feel
 * free to add bits to the structure. In particular, the handler function is
 * no longer used, and is replaced with a handler object that responds to -handleMachMessage.
 * Additionally, I need to be able to store the NSPort object (that holds the Mach port) somewhere,
 * so this is the obvious place.
 */

typedef struct _mkPortInfo {	
    port_name_t thePort;
    NSPort *thePortObj; /* sb: for the NSPort representation of the Mach port */
    unsigned msg_size;
    id theHandlerObj;	/* sb: the object that responds to -handleMachMessage */
    NSString *thePriority;            /* Not supported. */
    BOOL separateThread;        /* YES if not separate threaded */
} mkPortInfo;

static mkPortInfo **portInfos = NULL; /* Array of pointers to mkPortInfos */
static int portInfoCount = 0;

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

void _MKAddPort(port_name_t aPort,
                /*DPSPortProc aHandler,*/ id handlerObj,
		unsigned max_msg_size, 
		void *anArg,NSString *priority)
{
    kern_return_t ec;
    mkPortInfo *p = NULL;
    NSPort * portObj = nil;
    int i;
    if (!allConductors)
        condInit();
    if (portInfoCount > 0) 
	for (i = 0; i < portInfoCount; i++)
	    if (portInfos[i]->thePort == aPort) {
		p = portInfos[i];
		break;
	    }
    if (!p) {
	/* OK to add port here, even if we're in performance -- see above */
	if (portInfoCount == 0)
	    _MK_MALLOC(portInfos,mkPortInfo *,portInfoCount = 1);
	else _MK_REALLOC(portInfos,mkPortInfo *,++portInfoCount);
	_MK_MALLOC(p,mkPortInfo,1);
	portInfos[portInfoCount-1] = p;
	p->thePort = aPort;
        portObj = [[NSPort alloc] initWithMachPort:aPort];
        p->thePortObj = portObj; /* sb */
        p->theHandlerObj = handlerObj; /*sb: not retaining -- expect it to stay around! */
        [p->thePortObj setDelegate:handlerObj]; /* sb */
//	p->theArg = anArg;
	p->msg_size = max_msg_size;
//	p->theFunc = aHandler;
	p->thePriority = [priority copy];      /* Not supported yet (or ever) */
    }
    else {
        portObj = p->thePortObj;
    }
    p->separateThread = separateThread;
//#warning DPSConversion: 'addPort:forMode:' used to be DPSAddPort(aPort, aHandler, max_msg_size, anArg, priority).  aPort should be retained to avoid loss through deallocation, the functionality of aHandler should be implemented by a delegate of the NSPort in response to 'handleMachMessage:' or 'handlePortMessage:',  and priority should be converted to an NSRunLoop mode (NSDefaultRunLoopMode, NSModalPanelRunLoopMode, and NSEventTrackingRunLoopMode are predefined).

    if (!separateThread) 
        [[NSRunLoop currentRunLoop] addPort:portObj forMode:NSDefaultRunLoopMode];
    else {
	ec = port_set_add(task_self(),conductorPortSet,aPort);
	if (ec != KERN_SUCCESS)
	    _MKErrorf(MK_machErr, COND_ERROR, mach_error_string(ec), @"_MKAddPort");
    }
}

void _MKRemovePort(port_name_t aPort)
{
    kern_return_t ec;
    int i;
    if (!allConductors)
      condInit();
    /* OK to remove port, even if in performance -- see above. */
    for (i = 0; i < portInfoCount; i++) {
      if (portInfos[i]->thePort == aPort) {
	  if (!portInfos[i]->separateThread) {
//#warning DPSConversion: 'removePort:forMode:' used to be DPSRemovePort(aPort).  aPort should be retained to avoid loss through deallocation, and <mode> should be the mode for which the port was added.
              [[NSRunLoop currentRunLoop] removePort:portInfos[i]->thePortObj forMode:NSDefaultRunLoopMode];
              [portInfos[i]->thePortObj invalidate];
              [portInfos[i]->thePortObj autorelease];
	  }
          else {
	      ec = port_set_remove(task_self(),aPort);
	      if (ec != KERN_SUCCESS)
		  _MKErrorf(MK_machErr, COND_ERROR, mach_error_string(ec), @"_MKRemovePort");
	  }
	  free(portInfos[i]);
	  portInfos[i] = NULL;
	  portInfoCount--;
	  break;
      }
    }
    if (portInfoCount == 0) {
	free(portInfos);
    }
    else for (; i < portInfoCount; i++)
	portInfos[i] = portInfos[i + 1];
}

#define MSGTYPE_USER 1

typedef struct _mainThreadUserMsg {
    msg_header_t header;
    id toObject;
    SEL aSelector;
    int argCount;
    id arg1;
    id arg2;
} mainThreadUserMsg;

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
    
#if 0
static void MKToAppProc( msg_header_t *msg, void *userData )
    /* Called from DPSClient in appkit thread. */
{
    switch (msg->msg_id) {
      case MSGTYPE_USER: {
	  mainThreadUserMsg *myMsg = (mainThreadUserMsg *)msg; 
	  sendObjcMsg(myMsg->toObject,myMsg->aSelector,myMsg->argCount,myMsg->arg1,
		      myMsg->arg2);
	  break;
      }
      default:
	break;
    }
}
#endif
/*sb: added the following method to handle mach messages. This replaces the function
 * above, because instead of DPSAddPort specifying a function,
 * DPSAddPort() replaced with:
 * [[NSPort portWithMachPort:] retain]
 * [nsport setDelegate:]
 * [nsrunLoop addPort:forMode:]
 *
 * The delegate has to repond to selector -handleMachMessage or -handlePortMessage
 */
+ (void)handleMachMessage:(void *)machMessage
{
    msg_header_t *msg = (msg_header_t *)machMessage;
    
    switch (msg->msg_id) {
      case MSGTYPE_USER: {
          mainThreadUserMsg *myMsg = (mainThreadUserMsg *)msg;
          sendObjcMsg(myMsg->toObject,myMsg->aSelector,myMsg->argCount,myMsg->arg1, myMsg->arg2);
          break;
      }
      default:
          break;
    }
}
- (void)handleMachMessage:(void *)machMessage
/*sb: just in case messages get sent to the wrong place... */
{
    [MKConductor handleMachMessage:(void *)machMessage];
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
/*    if (separateThreadedAndInMusicKitThread()) { */
    if ([NSThread currentThread] != appKitThread) {
        /* i.e. this means that the MKConductor has been called from WITHIN the detached
         * thread, and has to send a message back to the main thread. The message
         * is a Mach message, caught by the NSPort/NSRunLoop handler as an ObjC
         * method, and dispatched from handleMachMessage:.
         */
	/* Sends a Mach message */
        mainThreadUserMsg msg;
        msg.header.msg_unused = 0;
        msg.header.msg_simple=TRUE;
        msg.header.msg_size=sizeof(mainThreadUserMsg);
        msg.header.msg_type=MSG_TYPE_NORMAL;
        msg.header.msg_local_port = PORT_NULL;
        msg.header.msg_remote_port = MKToAppPort;
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
    }
    else { /* Just send it */
	if (!sendObjcMsg(toObject,aSelector,argCount,arg1,arg2))
	    return nil;
    }
    return self;
}

static NSString * interThreadThreshold = nil;

+setInterThreadThreshold:(NSString *)newThreshold
/* sb: this seems fairly unnecessary, but I have left it in. It should work ok. */
{
    if ([NSThread currentThread] == musicKitThread) 
	return nil;
    [MKConductor lockPerformance];
    
//#warning DPSConversion: 'removePort:forMode:' used to be DPSRemovePort(MKToAppPort).  MKToAppPort should be retained to avoid loss through deallocation, and <mode> should be the mode for which the port was added.
    if (interThreadThreshold == nil) interThreadThreshold = NSDefaultRunLoopMode;
    
    [[NSRunLoop currentRunLoop] removePort:MKToAppPortObj forMode:interThreadThreshold];
    /*sb: I am simply using the previous value of interThreadThreshold here, and hoping that it is indeed
        the value that was used to set up the thread. It may not be...?
        */
    
    interThreadThreshold = newThreshold;

//#error DPSConversion: 'addPort:forMode:' used to be DPSAddPort(MKToAppPort, (DPSPortProc)MKToAppProc, sizeof(msg_header_t), NULL, interThreadThreshold).  MKToAppPort should be retained to avoid loss through deallocation, the functionality of (DPSPortProc)MKToAppProc should be implemented by a delegate of the NSPort in response to 'handleMachMessage:' or 'handlePortMessage:',  and interThreadThreshold should be converted to an NSRunLoop mode (NSDefaultRunLoopMode, NSModalPanelRunLoopMode, and NSEventTrackingRunLoopMode are predefined).

    [[NSRunLoop currentRunLoop] addPort:MKToAppPortObj forMode:interThreadThreshold]; 
    return [MKConductor unlockPerformance];
}

static void initializeBackgroundThread()
{
    /* Must be called from App thread. Called once when the MKConductor
       is initialized. */
    kern_return_t ec;
    musicKitLock = [[NSRecursiveLock alloc] init];
    musicKitAbortCondition = [[NSLock alloc] init];
    ec = port_set_allocate(task_self(), &conductorPortSet);
    if (ec != KERN_SUCCESS)
      _MKErrorf(MK_machErr, COND_ERROR, mach_error_string(ec), @"initializeBackgroundThread");
    ec = port_allocate(task_self(), &appToMKPort);
    if (ec != KERN_SUCCESS)
      _MKErrorf(MK_machErr, COND_ERROR, mach_error_string(ec), @"initializeBackgroundThread");
    ec = port_set_add(task_self(),conductorPortSet,appToMKPort);
    if (ec != KERN_SUCCESS)
      _MKErrorf(MK_machErr, COND_ERROR, mach_error_string(ec), @"port_set_add");
    ec = port_allocate(task_self(), &MKToAppPort);
    if (ec != KERN_SUCCESS)
      _MKErrorf(MK_machErr, COND_ERROR, mach_error_string(ec), @"initializeBackgroundThread");
    appToMKPortObj = [[NSPort alloc] initWithMachPort:appToMKPort];
    MKToAppPortObj = [[NSPort alloc] initWithMachPort:MKToAppPort];
    [MKToAppPortObj setDelegate:[MKConductor class]]; //sb:MKConductor handles messages
    
//#error DPSConversion: 'addPort:forMode:' used to be DPSAddPort(MKToAppPort, (DPSPortProc)MKToAppProc, sizeof(msg_header_t), NULL, interThreadThreshold).  MKToAppPort should be retained to avoid loss through deallocation, the functionality of (DPSPortProc)MKToAppProc should be implemented by a delegate of the NSPort in response to 'handleMachMessage:' or 'handlePortMessage:',  and interThreadThreshold should be converted to an NSRunLoop mode (NSDefaultRunLoopMode, NSModalPanelRunLoopMode, and NSEventTrackingRunLoopMode are predefined).
    if (interThreadThreshold == nil) interThreadThreshold = NSDefaultRunLoopMode;

    [[NSRunLoop currentRunLoop] addPort:MKToAppPortObj forMode:interThreadThreshold]; 
    appKitThread = [NSThread currentThread];
}

static void emptyAppToMKPort(void)
    /* This is called twice, once at the end of the performance and
       once at the beginning. The reason is: We want to make sure it's
       empty at the start of the performance. But we want to empty it as
       quickly as possible to avoid timing differences between midi and 
       conductor (or orchestra and conductor). So we empty it at the end
       to increase the likelyhood that emptying will be quick at the 
       beginning.  
       */
{
    /* We only empty the appToMKPort and not the MIDI port. The reason
       is obscure. We think that Midi empties the port and we're concerned
       about possible timing race at the start of a performance. 
       */
    /* sb: I am a bit concerned about what happens to the NSPort wrappers on the
     * port, while the port is removed from then re-added to the port set. I should
     * probably temporarily remove the object from the run loop, release it, then re-create
     * it when the port is added to the port set again. But since this may not be necessary
     * I'll chance it. (Oh hang on, we aren't monitoring this with NSRunLoop are we?)
     */
    struct {
        msg_header_t header;
	char data[MSG_SIZE_MAX];
    } msg;
    msg_return_t ret;
    kern_return_t ec;
    ec = port_set_remove(task_self(),appToMKPort);
    if (ec != KERN_SUCCESS)
      _MKErrorf(MK_machErr, COND_ERROR,
		mach_error_string(ec), @"emptyAppToMKPort port_set_remove");
    do {
	msg.header.msg_size = MSG_SIZE_MAX;
	msg.header.msg_local_port = appToMKPort;
	ret = msg_receive(&msg.header, RCV_TIMEOUT, 0);
    } while (ret == RCV_SUCCESS);
    if (ret != RCV_TIMED_OUT)
      _MKErrorf(MK_machErr, COND_ERROR,
		mach_error_string(ec), @"emptyAppToMKPort msg_receive");
    ec = port_set_add(task_self(),conductorPortSet,appToMKPort);
    if (ec != KERN_SUCCESS)
      _MKErrorf(MK_machErr, COND_ERROR,
		mach_error_string(ec), @"emptyAppToMKPort port_set_add");
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

#define MAXSTRESS 100
static unsigned int threadStress = 0;
static unsigned int maxStress = MAXSTRESS;

void _MKSetConductorThreadMaxStress(unsigned int val)
{
    maxStress = val;
}

//@interface ThreadSafeQueue (SeparateThreadLoop)
//+ (void) separateThreadLoop;
//@end

//@implementation MKConductor (SeparateThreadLoop)

/* This is the main loop for a separate-threaded performance.
   Re: _MKDisableErrorStream/_MKEnableErrorStream,
   It's kind of gross to call these functions ever time through the loop,
   even though they're very cheap.
   The alternative, however, is to drag the MKConductor into every Music Kit
   app by having the error routines poll the MKConductor if it's in
   a performance (using _MKMusicKitHasLock).  I don't know which is worse.
*/
+ (void) separateThreadLoop
{
    struct {
        msg_header_t header;
	char data[MSG_SIZE_MAX];
    } msg;
    msg_return_t ret;
    /*
     * When timeToWait is <= MIN_TIMEOUT (in milliseconds), we
     * avoid a context switch by doing a msg_receive() with a zero
     * timeout.  According to Doug Mitchell this is special-cased in the
     * kernel to just poll your ports.
     */
#   define	MIN_TIMEOUT	3
    int timeout;
    double timeToWait;
    BOOL yield;
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    lockIt();                /* Must be the first thing in this function */
    musicKitThread = [NSThread currentThread];
    _MKDisableErrorStream(); /* See note above */
    emptyAppToMKPort(); /* See comment above */
    setPriority();
    threadStress = 0;
    _jmpSet = YES;
    setjmp(conductorJmp);
    while (inPerformance) { 
	/* finishPerformance can be called from within the musickit thread
	   or from the appkit thread.  In both cases, inPerformance gets
	   set to NO. In the appkit thread case, we also send a message
	   to kick the musickit thread.
	   */
	/**************************** GOODNIGHT ***************************/
	timeToWait = (performanceIsPaused ? MK_ENDOFTIME : 
		      (isClocked ? theTimeToWait(condQueue->nextMsgTime) : 0.0));
	if (timeToWait >= (MAXINT/1000))
	  timeout = MAXINT;  /* Don't wrap around. */
	else timeout = (int)(timeToWait * 1000);
	if (timeout <= MIN_TIMEOUT) {
	    timeout = 0;
	    if (yield = (threadStress++ > maxStress))
	      threadStress = 0;
	} else {
	    yield = NO;
	    threadStress = 0;
	}
	msg.header.msg_size = MSG_SIZE_MAX;
	msg.header.msg_local_port = conductorPortSet;
	_MKEnableErrorStream(); /* See note below */
        if (MKIsTraced(MK_TRACECONDUCTOR))
	  NSLog(@"timeToWait %lf, timeout %d, yield %d, threadStress %d\n", timeToWait, timeout, yield, threadStress);
	if (timeout != 0) 
	  unlockIt(nonrecursive); /* We better have the lock and we know we
				 * want to give it up. By making this 
				 * nonrecursive, we actually make the code 
				 * more forgiving here. */
// LMS maybe yielding is not necessary now that we are NSThreaded - optimistic I know...
//	if (yield) 
//	  cthread_yield();
	ret = msg_receive(&msg.header, RCV_TIMEOUT, timeout);
	if (timeout != 0)  
	  lockIt();
	if (!inPerformance)
	    break;	/* may have been set during unlocked period above */
	/**************************** IT'S MORNING! *************************/
	/* If the desire is to exit the thread, this will be 
	   accomplished by the setting of inPerformance to false.
	   If the desire is to pause the thread, this will be
	   accomplished by the setting of timedEntry to MK_ENDOFTIME.
	   If the desire is to reposition the thread, this will be
	   accomplished by the setting of timedEntry to the new 
	   time. */
	_MKDisableErrorStream(); /* See note below */
	if (ret == RCV_TIMED_OUT) {
	    /* The following 2 lines added Sep6,90 by daj. They are necessary
	       because things could change between the time we return from the
	       msg_receive and the time we get the lock. */
	    if (thingsHaveChanged)  /* It's a "kick-me". Go back to loop */
	      thingsHaveChanged = NO;
	    else 
	      [MKConductor masterConductorBody: nil];
	}
	else if (ret != RCV_SUCCESS)
	  _MKErrorf(MK_machErr, COND_ERROR, mach_error_string(ret), @"separateThreadLoop");
	else if (msg.header.msg_local_port == appToMKPort) 
	  thingsHaveChanged = NO;
	  /* This can happen if there is more than one message in the
	       appToMKPort. This probably should be optimized to make it
	       so that the port accepts only one message. */
	else { 
	    register mkPortInfo *p;
	    register int i;
	    for (i = 0; i<portInfoCount; i++) {
	        if (portInfos[i]->thePort == msg.header.msg_local_port) {
                    p = portInfos[i];
                    //sb: this should echo what the NSRunLoop handler mechanism does
                    [p->theHandlerObj handleMachMessage:&msg.header];
                    break; /* Stop looking */
	        }
	    }
	}
    }
    emptyAppToMKPort();  // empty again, so the next time round it is fast to empty
    resetPriority();
    musicKitThread = nil;
    unlockIt(nonrecursive);  /* Changed to before condition_signal. 11/5/94 */
//    [musicKitAbortCondition unlock];
    
    [pool release];
}

// @end

static void launchThread(void)
{
    lockIt(); /* Make sure thread has had a chance to start up. */
//    cthread_detach(musicKitThread = 
//		   cthread_fork(separateThreadLoop,(any_t) 0));
    // As MKConductor class method, or should it be an instance method?
    [NSThread detachNewThreadSelector:@selector(separateThreadLoop) toTarget: [MKConductor self] withObject:nil];
    unlockIt(nonrecursive);
//    cthread_yield(); /* Give it a chance to run. */
}

