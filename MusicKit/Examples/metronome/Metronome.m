#import "Metronome.h"

@implementation Metronome

- setTempoFromSlider: sender
{
    [MKConductor lockPerformance];
    [cond setTempo: [sender doubleValue]];
    [MKConductor unlockPerformance];
    return self;
}

 /* Invoked when first message is sent to app */
- appDidInit: sender
{
    aNote = [[MKNote alloc] init];          /* A note we'll use over and over */
    [MKOrchestra setTimed: YES];             /* Use the DSP 'clock' */
    [MKOrchestra new];                      /* Create Orchestra for all DSPs */
    MKSetDeltaT(1.0);                     /* Scheduler advance   */
    [MKConductor setFinishWhenEmpty: NO];    /* Keep going forever  */
    cond = [MKConductor defaultConductor];
    return self;
}	

- play 
{
    [pluck noteOn: aNote];                  /* Do it */
    [cond sel: @selector(play) to: self withDelay: 1.0 argCount: 0];
    return self;
}

- startStop: sender 
{
    if ([MKConductor inPerformance]) {
	[MKConductor lockPerformance];
	[MKConductor finishPerformance];
	[MKConductor unlockPerformance];
	[pluck dealloc];  /* Must dealloc by hand, 'cause we alloced by hand */
	[MKOrchestra close];
    } 
    else {
	[MKOrchestra open];
	pluck = [MKOrchestra allocSynthPatch: [MKPluck class]];		
	[cond sel: @selector(play) to: self withDelay: 0 argCount: 0];
	[MKOrchestra run]; 
	[MKConductor startPerformance];	    
    }
    return self;
}

@end
