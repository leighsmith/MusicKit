/*
  $Id$
  Defined In: The MusicKit

  Description:
    This is the header for the MusicKit scheduler. See documentation for details.

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.11  2001/07/05 22:57:58  leighsmith
  Added useful status methods and removed _wakeUpMKThread

  Revision 1.10  2001/04/24 23:37:26  leighsmith
  Added _MKWakeThread prototype for separate threading

  Revision 1.9  2000/04/20 21:39:00  leigh
  Removed flakey longjmp for unclocked MKConductors, improved description

  Revision 1.8  2000/04/16 04:28:17  leigh
  Class typing and added description method

  Revision 1.7  2000/03/31 00:14:43  leigh
  typed defaultConductor

  Revision 1.6  2000/01/20 17:15:36  leigh
  Replaced sleepMs with OpenStep NSThread delay

  Revision 1.5  2000/01/13 06:53:17  leigh
  doco cleanup

  Revision 1.4  1999/09/04 22:02:17  leigh
  Removed mididriver source and header files as they now reside in the MKPerformMIDI framework

  Revision 1.3  1999/08/06 16:31:12  leigh
  Removed extraInstances and implementation ivar cruft

  Revision 1.2  1999/07/29 01:25:44  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_Conductor_H___
#define __MK_Conductor_H___

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSThread.h>

// Enforce C name mangling to allow linking MusicKit functions to C++ code
#ifdef __cplusplus
extern "C" {
#endif

 /* The Conductor message structure.  All fields are private and
  * shouldn't be altered directly from an application.
  * LMS: should become an object named MKConductorMsg
  */
@class MKConductor;

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
    MKConductor *_conductor;
} MKMsgStruct;

#define MK_ENDOFTIME (6000000000.0) /* A long time, but not as long as MK_FOREVER */

/* Time functions */
extern double MKGetTime(void);           /* Returns the time in seconds. */
extern double MKGetDeltaT(void);         /* Returns deltaT, in seconds. */
extern void MKSetDeltaT(double val);     /* Sets deltaT, in seconds. */
extern double MKGetDeltaTTime(void);     /* Returns deltaT + time, in seconds. */

/* The following modes determine how deltaT is interpreted. */
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
                         * Note that pausing all MKConductors through the pause factory
                         * method doesn't set this to YES. */
    id delegate;
    NSMutableArray *activePerformers;
    id MTCSynch;

    /* Internal use only */
    MKMsgStruct *_msgQueue;
    MKConductor *_condNext;
    MKConductor *_condLast;
    double _pauseOffset;
    double inverseBeatSize;
    double oldAdjustedClockTime;
    MKMsgStruct *pauseFor;
    unsigned char archivingFlags;
    unsigned char delegateFlags;
}
 
+ allocWithZone:(NSZone *)zone;
+ alloc;
- init;
+ adjustTime; 
+ startPerformance;
+ (MKConductor *) defaultConductor; 
+(BOOL) inPerformance; 
+ finishPerformance; 
+ pausePerformance; 
+(BOOL) isPaused; 
+ resumePerformance; 
+ currentConductor; 
+ clockConductor;
+ setClocked:(BOOL) yesOrNo; 
+(BOOL) isClocked; 
+ setFinishWhenEmpty:(BOOL) yesOrNo; 
+(BOOL) isEmpty;
+(BOOL) finishWhenEmpty;
+(void) setDeltaT: (double) newDeltaT;
+(double) deltaT;
- copy;
- copyWithZone:(NSZone *)zone;
-(BOOL) isPaused; 
- pause; 
- pauseFor:(double) seconds;
- resume; 
-(double) setBeatSize:(double) newBeatSize; 
-(double) beatSize; 
-(double) setTempo:(double) newTempo; 
-(double) tempo; 
-(double) setTimeOffset:(double) newTimeOffset; 
-(double) timeOffset; 
- sel:(SEL) aSelector to: toObject withDelay:(double) beats argCount:(int) argCount, ...;
- sel:(SEL) aSelector to: toObject atTime:(double) time argCount:(int) argCount, ...;
+(double) time; 
-(double) time; 
- emptyQueue; 
-(BOOL) isCurrentConductor;
+(MKMsgStruct *) afterPerformanceSel:(SEL) aSelector to: toObject argCount:(int) argCount, ...; 
+(MKMsgStruct *) beforePerformanceSel:(SEL) aSelector to: toObject argCount:(int) argCount, ...; 
-(void) setDelegate:(id) object;
- delegate;
+(void) setDelegate: object;
+ delegate;
- activePerformers;
-(void) encodeWithCoder:(NSCoder *) aCoder;
-(id) initWithCoder:(NSCoder *) aDecoder;
- awakeAfterUsingCoder:(NSCoder *) aDecoder;
- setMTCSynch:aMidiObj;
- MTCSynch;
-(double) clockTime;
/* Obsolete methods */
+ new; 
-(double) predictTime:(double)beatTime; 

@end

@interface MKConductor(SeparateThread)

+ useSeparateThread:(BOOL) yesOrNo;

/*!
    @method separateThreaded
    @description Returns YES if the MKConductor is separate threaded, NO if it runs in the application thread.
*/
+ (BOOL) separateThreaded;

/*!
    @method separateThreadedAndInMusicKitThread
    @description Returns YES if the MKConductor is separate threaded and the calling code is running
        in the separate thread, NO if the code is running in the application thread.
*/
+ (BOOL) separateThreadedAndInMusicKitThread;
+ lockPerformance;
+ unlockPerformance;
+ (BOOL) lockPerformanceNoBlock;
+ setThreadPriority:(float) priorityFactor;
+ (NSThread *) performanceThread;
+ sendMsgToApplicationThreadSel:(SEL) aSelector to:(id) toObject argCount:(int)argCount, ...;
+ setInterThreadThreshold:(NSString *) newThreshold;

@end

#import "MKConductorDelegate.h"

#ifdef __cplusplus
}
#endif

#endif
