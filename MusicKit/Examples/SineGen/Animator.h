#ifndef __MK_Animator_H___
#define __MK_Animator_H___

#import <objc/Object.h>
#include <sys/time.h>

@interface Animator : Object
{
    int mask;
    int teNum;
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
- initChronon:(double )dt adaptation:(double )howoft target:(id )targ 
  action:(SEL )act autoStart:(int )start eventMask:(int )eMask; 
- resetRealTime; 
-(double ) getSyncTime; 
-(double ) getDoubleEntryTime; 
-(double ) getDoubleRealTime; 
-(double ) getDouble; 
- adapt; 
- setBreakMask:(int )eventMask; 
-(int ) getBreakMask; 
-(int ) isTicking; 
-(int ) shouldBreak; 
- setIncrement:(double )dt; 
-(double ) getIncrement; 
- setAdaptation:(double )oft; 
- setTarget:(id )targ; 
- setAction:(SEL )aSelector; 
- startEntry; 
- stopEntry; 
- free; 

@end

#endif
