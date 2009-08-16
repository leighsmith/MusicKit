#import <MusicKit/MusicKit.h>
#import <musickit/unitgenerators/Out2sumUGx.h>
#import <musickit/unitgenerators/OscgUGxy.h>
#import <AppKit/AppKit.h>

#import "MyCustomObject.h"

@implementation MyCustomObject

static MKSynthData *pp;
static OscgUGxy *osc;
static Out2sumUGx *out; 
	
-init
{	MKOrchestra *orch = [MKOrchestra new];
	MKSetDeltaT(.1);
	[MKConductor setFinishWhenEmpty:NO];
	[MKUnitGenerator enableErrorChecking:YES];
	[orch setFastResponse:YES];
	[orch setSamplingRate:44100];
	if (![orch open]) {
	    NSRunAlertPanel(@"examp5",@"Can't open DSP.",@"OK",NULL,NULL);
	    return nil;
	}
	pp = [orch allocPatchpoint:MK_xPatch];
	osc = [orch allocUnitGenerator:[OscgUGxy class]];
	out = [orch allocUnitGenerator:[Out2sumUGx class]];
	[osc setOutput:pp];
	[out setInput:pp];
	[osc setFreq:440];
	[osc setAmp:0.1];
	[osc run];
	[out run];
	[orch run];
	[MKConductor startPerformance];
	return self;
}

-setFreqFrom:sender
{	
	[MKConductor lockPerformance];
	[osc setFreq:[sender doubleValue]];
	[MKConductor unlockPerformance];
	return self;
}

-setBearingFrom:sender
{	
	[MKConductor lockPerformance];
	[out setBearing:[sender doubleValue]];
	[MKConductor unlockPerformance];
	return self;
}

-setAmplitudeFrom:sender
{	
	[MKConductor lockPerformance];
	[osc setAmp:[sender doubleValue]];
	[MKConductor unlockPerformance];
	return self;
}


@end	
