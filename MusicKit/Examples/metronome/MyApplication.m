#import <appkit/appkit.h>
#import <musickit/musickit.h>
#import <musickit/synthpatches/Pluck.h>
#import "MyApplication.h"

@implementation MyApplication

- setTempoFromSlider:sender {
    [Conductor lockPerformance];
    [cond setTempo:[sender doubleValue]];
    [Conductor unlockPerformance];
    return self;
}

- appDidInit:sender  { /* Invoked when first message is sent to app */
    aNote = [[Note alloc] init];          /* A note we'll use over and over */
    [Orchestra setTimed:YES];             /* Use the DSP 'clock' */
    [Orchestra new];                      /* Create Orchestra for all DSPs */
    MKSetDeltaT(1.0);                     /* Scheduler advance   */
    [Conductor setFinishWhenEmpty:NO];    /* Keep going forever  */
    cond = [Conductor defaultConductor];
    return self;
}	

- play {
    [pluck noteOn:aNote];                  /* Do it */
    [cond sel:@selector(play) to:self withDelay:1.0 argCount:0];
    return self;
}

- startStop:sender {
    if ([Conductor inPerformance]) {
	[Conductor lockPerformance];
	[Conductor finishPerformance];
	[Conductor unlockPerformance];
	[pluck dealloc];  /* Must dealloc by hand, 'cause we alloced by hand */
	[Orchestra close];
    } else {
	[Orchestra open];
	pluck = [Orchestra allocSynthPatch:[Pluck class]];		
	[cond sel:@selector(play) to:self withDelay:0 argCount:0];
	[Orchestra run]; 
	[Conductor startPerformance];	    
    }
    return self;
}

@end
