/* Copyright 1993, CCRMA, Stanford University. */
/* This is a very minimal MKSynthPatch for supporting mixing Quint Processor satellite
 * DSPs in with the main DSP.
 *
 * Author: David A. Jaffe
 */

#import <MusicKit/MusicKit.h>
#import <unitgenerators/Out1aUGx.h>
#import <unitgenerators/Out1bUGy.h>
#import <unitgenerators/In1qpUGx.h>
#import <unitgenerators/In1qpUGy.h>

#import "ArielQPMix.h"

@implementation ArielQPMix:MKSynthPatch
{
}

static int ins[8],outs[8],ppx,ppy;

+patchTemplateFor:aNote {
    int i,j,in,out,ctr;
    MKPatchTemplate *aTemplate = nil;
    if (aTemplate)
      return aTemplate;
    aTemplate = [[MKPatchTemplate alloc] init];
    ctr = 0;
    ppx = [aTemplate addPatchpoint:MK_xPatch];
    ppy = [aTemplate addPatchpoint:MK_yPatch];
    for (i=1; i<=4; i++) {
	for (j=0; j<2; j++) { /* FIXME assumes stereo (need out1n)!!! */
	    if (j % 2 == 0) {
		in = [aTemplate addUnitGenerator:[In1qpUGx class]];
		out = [aTemplate addUnitGenerator:[Out1aUGx class]];
		[aTemplate to:in sel:@selector(setOutput:) arg:ppx];
		[aTemplate to:out sel:@selector(setInput:) arg:ppx];
	    }
	    else {
		in = [aTemplate addUnitGenerator:[In1qpUGy class]];
		out = [aTemplate addUnitGenerator:[Out1bUGy class]];
		[aTemplate to:in sel:@selector(setOutput:) arg:ppy];
		[aTemplate to:out sel:@selector(setInput:) arg:ppy];
	    }
	    ins[ctr] = in;
	    outs[ctr++] = out;
	}
    }
    return aTemplate;
}

-init
  /* Sent by this class on object creation and reset. */
{
    int i,j;
    id ug;
    int ctr = 0;
    for (i=1; i<=4; i++) 
      for (j=0; j<2; j++) {  /* FIXME assumes stereo */
	  ug = [self synthElementAt:ins[ctr++]];
	  [ug setSatellite:i+'A'-1];
	  [ug setChannel:j % 2];
	  /* Out and in scales defaults to 1.0 */
      }
    [synthElements makeObjectsPerform:@selector(run)];
    return self;
}

@end


