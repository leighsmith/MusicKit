#ifndef __MK_Conductor_H___
#define __MK_Conductor_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  Conductor.h
  DEFINED IN: The Music Kit
*/

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
{
    double time;       
    double nextMsgTime;
    double beatSize;    
    double timeOffset; 
    BOOL isPaused;     
    id delegate;       
    id activePerformers;
    id MTCSynch;

    /* Internal use only */
    MKMsgStruct *_msgQueue;
    id _condNext;
    id _condLast;
    double _pauseOffset;
//    void *_reservedConductor5;
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
