#import <AppKit/AppKit.h>
#import <sys/time.h>

@interface Animator : NSObject
{
	int mask;
	DPSTimedEntry teNum;
	int ticking;
	double interval;
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

+ newChronon:(double)dt 
  adaptation:(double)howoft 
      target:(id)targ 
      action:(SEL)act 
   autoStart:(int)start 
   eventMask:(int)eMask; 
- resetRealTime; 
-(double) getSyncTime; 
-(double) getDoubleEntryTime; 
-(double) getDoubleRealTime; 
-(double) getDouble; 
- adapt; 
- setBreakMask:(int)eventMask; 
-(int) getBreakMask; 
-(int) isTicking; 
-(int) shouldBreak; 
- setIncrement:(double)dt; 
-(double) getIncrement; 
- setAdaptation:(double)oft; 
- setTarget:(id)targ; 
- setAction:(SEL)aSelector; 
- startEntry; 
- stopEntry; 
- free; 

@end
