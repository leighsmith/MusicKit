#ifndef __MK__Conductor_H___
#define __MK__Conductor_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#import "MKConductor.h"

#import	<mach/message.h>
#import <AppKit/dpsclient.h>
#import <AppKit/NSDPSContext.h>
#import <AppKit/dpsOpenStep.h>
#import <AppKit/NSDPSContext.h>

#define _MK_ONLY_ONE_MTC_SUPPORTED 1 /* Do we ever need more than one? */
#define _MK_DEFAULT_MTC_POLL_PERIOD (1/30.0)

extern void _MKLock(void) ;
    /* Waits for Music Kit to become available for messaging. */
extern void _MKUnlock(void) ;
    /* Gives up lock so that Music Kit can run again. */

extern void _MKAddPort(port_name_t aPort, 
		       /*DPSPortProc aHandler,*/ id handlerObj,
		       unsigned max_msg_size, 
		       void *anArg,NSString *priority);
extern void _MKRemovePort(port_name_t aPort);

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
