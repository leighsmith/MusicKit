/*
  $Id$
  Defined In: The MusicKit
  
  Description:
    This file contains private methods, functions and defines.
  
  Original Author: David Jaffe
  
  Copyright 1988-1992, NeXT Inc. All rights reserved.
  Portions Copyright (c) 1999-2003 The MusicKit Project.
 */
#ifndef __MK__Conductor_H___
#define __MK__Conductor_H___

#import "MKConductor.h"
#import <Foundation/Foundation.h>

#define _MK_ONLY_ONE_MTC_SUPPORTED 1 /* Do we ever need more than one? */
#define _MK_DEFAULT_MTC_POLL_PERIOD (1/30.0)

#define DELEGATE_RESPONDS_TO(_self,_msgBit) ((_self)->delegateFlags & _msgBit)
#define BEAT_TO_CLOCK 1
#define CLOCK_TO_BEAT 2

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

#define PEEKTIME(pq) (pq)->_timeOfMsg

typedef enum _backgroundThreadAction {
    exitThread,
    pauseThread
} backgroundThreadAction;

extern void _MKLock(void) ;
    /* Waits for MusicKit to become available for messaging. */
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


extern double _MKTheTimeToWait(double nextMsgTime);

@interface MKConductor(Private)

+(MKMsgStruct *)_afterPerformanceSel:(SEL)aSelector 
 to:(id)toObject 
 argCount:(int)argCount, ...;
+(MKMsgStruct *)_afterPerformanceSel:(SEL)aSelector 
 to:(id)toObject 
 argCount:(int)argCount
 arg1:(id)arg1 retain:(BOOL)retainArg1
 arg2:(id)arg2 retain:(BOOL)retainArg2;
+(MKMsgStruct *)_newMsgRequestAtTime:(double)timeOfMsg
  sel:(SEL)whichSelector to:(id)destinationObject
  argCount:(int)argCount, ...;
+(MKMsgStruct *)_newMsgRequestAtTime:(double)timeOfMsg
  sel:(SEL)whichSelector to:(id)destinationObject
  argCount:(int)argCount arg1:(id)arg1 retain:(BOOL)retainArg1
  arg2:(id)arg2 retain:(BOOL)retainArg2;
+(void)_scheduleMsgRequest:(MKMsgStruct *)aMsgStructPtr;
+(MKMsgStruct *)_cancelMsgRequest:(MKMsgStruct *)aMsgStructPtr;
+(double)_adjustTimeNoTE:(double)desiredTime ;
+(double)_getLastTime;
+_adjustDeltaTThresholds;
-(void)_scheduleMsgRequest:(MKMsgStruct *)aMsgStructPtr;
-(MKMsgStruct *)_rescheduleMsgRequest:(MKMsgStruct *)aMsgStructPtr
  atTime:(double)timeOfNewMsg sel:(SEL)whichSelector
  to:(id)destinationObject argCount:(int)argCount, ...;
-(MKMsgStruct *)_rescheduleMsgRequestWithObjectArgs:(MKMsgStruct *)aMsgStructPtr
  atTime:(double)timeOfNewMsg sel:(SEL)whichSelector
  to:(id)destinationObject argCount:(int)argCount
  arg1:(id)arg1 retain:(BOOL)retainArg1
  arg2:(id)arg2 retain:(BOOL)retainArg2;
+ (void) masterConductorBody:(NSTimer *) unusedTimer;
- _error: (NSString *) errorMsg;
-_pause;
-_resume;

@end

@interface MKConductor(MTCPrivate)

-_adjustPauseOffset:(double)v;
-_MTCException:(int)exception;
-_addActivePerformer:perf;
-_removeActivePerformer:perf;
-_runMTC:(double)requestedTime :(double)actualTime;
-(double) _setMTCTime:(double)desiredTime;
-(double)_MTCPerformerActivateOffset: (id) sender;
- _setMTCSynch: (MKMidi *) aMidiObj;

void setupMTC(void);
void resetMTCTime(void);
BOOL weGotMTC(void);
BOOL mtcEndOfTime(void);
void adjustTime();
BOOL checkForEndOfTime();
void repositionCond(MKConductor *cond, double nextMsgTime);
double beatToClock(MKConductor *self, double newBeat);

@end

#endif
