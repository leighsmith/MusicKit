/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.3  1999/08/06 16:31:12  leigh
  Removed extraInstances and implementation ivar cruft

  Revision 1.2  1999/07/29 01:25:44  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_Conductor_H___
#define __MK_Conductor_H___

#import <Foundation/NSObject.h>
#import <mach/cthreads.h>

 /* The Conductor message structure.  All fields are private and
  * shouldn't be altered directly from an application. 
  */
typedef struct _MKMsgStruct { 
    double _timeOfMsg;     
    SEL _aSelector;       
    id _toObject;	       
    int _argCount;             
    id _arg1;
    id _arg2;
    struct _MKMsgStruct *_next;	
    IMP _methodImp;        
    id *_otherArgs;
    BOOL _conductorFrees;  
    BOOL _onQueue;      
    struct _MKMsgStruct *_prev;
    id _conductor;
} MKMsgStruct;

#define MK_ENDOFTIME (6000000000.0) /* A long time, but not as long as NX_FOREVER */

/* Time functions */
extern double MKGetTime(void) ;
extern double MKGetDeltaT(void);
extern void MKSetDeltaT(double val);
extern double MKGetDeltaTTime(void);

/* The following determines how deltaT is interpreted. */
#define MK_DELTAT_DEVICE_LAG 0
#define MK_DELTAT_SCHEDULER_ADVANCE 1
 
extern void MKSetDeltaTMode(int newMode);
extern int MKGetDeltaTMode(void);
extern double MKSetTime(double newTime); /* Rarely used */

extern MKMsgStruct 
  *MKNewMsgRequest(double timeOfMsg,SEL whichSelector,id destinationObject,
		   int argCount,...);

extern void 
  MKScheduleMsgRequest(MKMsgStruct *aMsgStructPtr, id conductor);

extern MKMsgStruct *
  MKCancelMsgRequest(MKMsgStruct *aMsgStructPtr);

extern MKMsgStruct *
  MKRescheduleMsgRequest(MKMsgStruct *aMsgStructPtr,id conductor,
			 double timeOfNewMsg,SEL whichSelector,
			 id destinationObject,int argCount,...);

extern MKMsgStruct *
  MKRepositionMsgRequest(MKMsgStruct *aMsgStructPtr,double newTimeOfMsg);

extern void MKFinishPerformance(void);

@interface MKConductor : NSObject
/* nextMsgTime = (nextbeat - time) * beatSize */
{
    double time;        // Time in beats, updated (for all instances) after timed entry fires off.
    double nextMsgTime; // Time, in seconds, when next message is scheduled to be sent by this Conductor.
                        // sb: relative to start of performance, I think.
    double beatSize;    // The size of a single beat in seconds.
    double timeOffset;  // Performance timeOffset in seconds.
    BOOL isPaused;      /* YES if this instance is paused. 
                         * Note that pausing all Conductors through the pause factory
                         * method doesn't set this to YES. */
    id delegate;       
    id activePerformers;
    id MTCSynch;

    /* Internal use only */
    MKMsgStruct *_msgQueue;
    id _condNext;
    id _condLast;
    double _pauseOffset;
    double inverseBeatSize;
    double oldAdjustedClockTime;
    MKMsgStruct *pauseFor;
    unsigned char archivingFlags;
    unsigned char delegateFlags;
}
 
+ allocWithZone:(NSZone *)zone;
+alloc;
- init;
+ adjustTime; 
+ startPerformance;
+ defaultConductor; 
+(BOOL) inPerformance; 
+ finishPerformance; 
+ pausePerformance; 
+(BOOL) isPaused; 
+ resumePerformance; 
+ currentConductor; 
+ clockConductor;
+ setClocked:(BOOL)yesOrNo; 
+(BOOL) isClocked; 
+ setFinishWhenEmpty:(BOOL)yesOrNo; 
+(BOOL) isEmpty;
+(BOOL) finishWhenEmpty;
- copy;
- copyWithZone:(NSZone *)zone;
-(BOOL) isPaused; 
- pause; 
-pauseFor:(double)seconds;
- resume; 
-(double) setBeatSize:(double)newBeatSize; 
-(double) beatSize; 
-(double) setTempo:(double)newTempo; 
-(double) tempo; 
-(double) setTimeOffset:(double)newTimeOffset; 
-(double) timeOffset; 
- sel:(SEL)aSelector to:toObject withDelay:(double)beats argCount:(int)argCount,...;
- sel:(SEL)aSelector to:toObject atTime:(double)time argCount:(int)argCount,...;
+(double) time; 
-(double) time; 
- emptyQueue; 
-(BOOL) isCurrentConductor;
+(MKMsgStruct *) afterPerformanceSel:(SEL)aSelector to:toObject argCount:(int)argCount,...; 
+(MKMsgStruct *) beforePerformanceSel:(SEL)aSelector to:toObject argCount:(int)argCount,...; 
- (void)setDelegate:(id)object;
- delegate;
+ (void)setDelegate:object;
+ delegate;
- activePerformers;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;
- awakeAfterUsingCoder:(NSCoder *)aDecoder;
+ useSeparateThread:(BOOL)yesOrNo;
+ lockPerformance;
+ unlockPerformance;
+ (BOOL)lockPerformanceNoBlock;
+ setThreadPriority:(float)priorityFactor;
+ (cthread_t) performanceThread;
+sendMsgToApplicationThreadSel:(SEL)aSelector 
  to:(id)toObject
  argCount:(int)argCount, ...;
+setInterThreadThreshold:(NSString *)newThreshold;
-setMTCSynch:aMidiObj;
-MTCSynch;
-(double)clockTime;
/* Obsolete methods */
+ new; 
-(double) predictTime:(double)beatTime; 

@end

#import "MKConductorDelegate.h"

#endif
