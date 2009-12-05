#ifndef __MK_Animator_H___
#define __MK_Animator_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */

#import <Foundation/NSObject.h>
#include <sys/time.h>

@interface Animator : NSObject
{
	int mask;
	NSTimer * teNum;
	int ticking;
	double interval;
	struct timezone tzone;
	struct timeval realtime;
	struct timeval entrytime;
	double synctime;
	double adapteddt;
	double desireddt;
	double t0;
	double howOften;
	id target;
	SEL action;
	int passcounter;
}
+ newChronon:(double )dt adaptation:(double )howoft target:(id )targ action:(SEL )act autoStart:(int )start eventMask:(int )eMask; 
- (void)resetRealTime; 
-(double ) getSyncTime; 
-(double ) getDoubleEntryTime; 
-(double ) getDoubleRealTime; 
-(double ) getDouble; 
- (void)adapt; 
- (void)setBreakMask:(int )eventMask; 
-(int ) getBreakMask; 
-(int ) isTicking; 
-(int ) shouldBreak; 
- (void)setIncrement:(double )dt; 
-(double ) getIncrement; 
- (void)setAdaptation:(double )oft; 
- (void)setTarget:(id )targ; 
- (void)setAction:(SEL )aSelector; 
- (void)startEntry; 
- (void)stopEntry; 
- (void)dealloc; 

@end

#endif
