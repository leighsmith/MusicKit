#import <musickit/musickit.h>
#import <musickit/unitgenerators/Out2sumUGx.h>
#import <musickit/unitgenerators/OscgUGxy.h>
#import <appkit/Slider.h>
#import <appkit/Panel.h>

#import "MyCustomObject.h"

@implementation MyCustomObject

static SynthData *pp;
static OscgUGxy *osc;
static Out2sumUGx *out; 
	
-init
{	Orchestra *orch = [Orchestra new];
	MKSetDeltaT(.1);
	[Conductor setFinishWhenEmpty:NO];
	[UnitGenerator enableErrorChecking:YES];
	[orch setFastResponse:YES];
	[orch setSamplingRate:44100];
	if (![orch open]) {
	    NXRunAlertPanel("examp5","Can't open DSP.","OK",NULL,NULL);
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
	[Conductor startPerformance];
	return self;
}

-setFreqFrom:sender
{	
	[Conductor lockPerformance];
	[osc setFreq:[sender doubleValue]];
	[Conductor unlockPerformance];
	return self;
}

-setBearingFrom:sender
{	
	[Conductor lockPerformance];
	[out setBearing:[sender doubleValue]];
	[Conductor unlockPerformance];
	return self;
}

-setAmplitudeFrom:sender
{	
	[Conductor lockPerformance];
	[osc setAmp:[sender doubleValue]];
	[Conductor unlockPerformance];
	return self;
}


@end	
