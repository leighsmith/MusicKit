#import <appkit/appkit.h>
#import <musickit/musickit.h>
#import <musickit/synthpatches/Pluck.h>
#import "SimplePerformer.h"
#import "MyApplication.h"

@implementation MyApplication

- setTempoFromSlider:sender {
    [Conductor lockPerformance];
    [cond setTempo:[sender doubleValue]];
    [Conductor unlockPerformance];
    return self;
}

- appDidInit:sender  { /* Invoked when first message is sent to app */
    [Orchestra setTimed:YES];             /* Use the DSP 'clock' */
    [Orchestra new];                      /* Create Orchestra for all DSPs */
    MKSetDeltaT(1.0);                     /* Scheduler advance   */
    [Conductor setFinishWhenEmpty:NO];    /* Keep going forever  */
    cond = [Conductor defaultConductor];
    perf = [[SimplePerformer alloc] init];
    synthIns = [[SynthInstrument alloc] init];
    [[synthIns noteReceiver] connect:[perf noteSender]];
    [synthIns setSynthPatchClass:[Pluck class]];
    return self;
}	

- startStop:sender {
    if ([Conductor inPerformance]) {
	[Conductor lockPerformance];
	[Conductor finishPerformance];
	[Conductor unlockPerformance];
	[Orchestra close];
    } else {
	[Orchestra open];
	[perf activate];
	[Orchestra run]; 
	[Conductor startPerformance];	    
    }
    return self;
}

- pause:sender {  /* Assumes we're performing and active. */
    [perf pause];
    return self;
}

- resume:sender {  /* Assumes we're performing and paused. */
    [perf resume];
    return self;
}

@end
