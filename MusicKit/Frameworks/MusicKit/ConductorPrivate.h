/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
*/
/*
  $Log$
  Revision 1.6  2000/01/27 19:06:28  leigh
  Now using NSPort replacing C Mach port API

  Revision 1.5  2000/01/20 17:15:36  leigh
  Replaced sleepMs with OpenStep NSThread delay

  Revision 1.4  2000/01/13 06:54:04  leigh
  Added a missing (pre-OpenStep conversion!) _error: method

  Revision 1.3  1999/09/04 22:02:16  leigh
  Removed mididriver source and header files as they now reside in the MKPerformMIDI framework

  Revision 1.2  1999/07/29 01:25:42  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__Conductor_H___
#define __MK__Conductor_H___
#import "MKConductor.h"

#import	<mach/message.h>
#import <AppKit/dpsclient.h>
#import <AppKit/NSDPSContext.h>
#import <AppKit/dpsOpenStep.h>
#import <AppKit/NSDPSContext.h>

#define _MK_ONLY_ONE_MTC_SUPPORTED 1 /* Do we ever need more than one? */
#define _MK_DEFAULT_MTC_POLL_PERIOD (1/30.0)

typedef enum _backgroundThreadAction {
    exitThread,
    pauseThread
} backgroundThreadAction;

extern void _MKLock(void) ;
    /* Waits for Music Kit to become available for messaging. */
extern void _MKUnlock(void) ;
    /* Gives up lock so that Music Kit can run again. */

extern void _MKAddPort(NSPort *aPort, 
		       id handlerObj,
		       unsigned max_msg_size, 
		       void *anArg,
		       NSString *priority);
extern void _MKRemovePort(NSPort *aPort);

extern void _MKSendVMMsgToApplicationThread(id self,
					    short *data,
					    int dataCount,
					    int vmCount);

@interface MKConductor(Private)

+(MKMsgStruct *)_afterPerformanceSel:(SEL)aSelector 
 to:(id)toObject 
 argCount:(int)argCount, ...;
+(MKMsgStruct *)_newMsgRequestAtTime:(double)timeOfMsg
  sel:(SEL)whichSelector to:(id)destinationObject
  argCount:(int)argCount, ...;
+(void)_scheduleMsgRequest:(MKMsgStruct *)aMsgStructPtr;
+(MKMsgStruct *)_cancelMsgRequest:(MKMsgStruct *)aMsgStructPtr;
+(double)_adjustTimeNoTE:(double)desiredTime ;
+(double)_getLastTime;
+_adjustDeltaTThresholds;
-(void)_scheduleMsgRequest:(MKMsgStruct *)aMsgStructPtr;
-(MKMsgStruct *)_rescheduleMsgRequest:(MKMsgStruct *)aMsgStructPtr
  atTime:(double)timeOfNewMsg sel:(SEL)whichSelector
  to:(id)destinationObject argCount:(int)argCount, ...;
+ (void) masterConductorBody:(NSTimer *) unusedTimer;
- _error: (NSString *) errorMsg;

@end

@interface MKConductor(MTCPrivate)

-_adjustPauseOffset:(double)v;
-_MTCException:(int)exception;
-_addActivePerformer:perf;
-_removeActivePerformer:perf;
-_runMTC:(double)requestedTime :(double)actualTime;
-(double) _setMTCTime:(double)desiredTime;
-(double)_MTCPerformerActivateOffset:sender;
-_setMTCSynch:aMidiObj;

@end


#endif
