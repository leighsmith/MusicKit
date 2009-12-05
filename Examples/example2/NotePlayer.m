/* 
 * $Id$
 *
 * NotePlayer example #2
 * Originally by David A. Jaffe
 * Rewritten by Leigh M. Smith <leigh@leighsmith.com>
 *
 * Copyright (c) 2005, The MusicKit Project.  All rights reserved.
 *
 * Permission is granted to use and modify this code for commercial and 
 * non-commercial purposes so long as the author attribution and copyright 
 * messages remain intact and accompany all relevant code.
 *
 */
#import <MusicKit/MusicKit.h>
#import <MKSynthPatches/Pluck.h>
#import "NotePlayer.h"

@implementation NotePlayer

- play: sender
{
    [MKConductor lockPerformance];
    [mySynthPatch noteOn: myNote];
    [MKConductor unlockPerformance];
    return self;
}

- setFreqFrom: sender
{
    [MKConductor lockPerformance];
    [myNote setPar:MK_freq toDouble: [sender doubleValue]];
    [mySynthPatch noteUpdate: myNote];
    [MKConductor unlockPerformance];
    return self;
}

+ initialize
{
    [MKConductor setFinishWhenEmpty: NO];
    [MKOrchestra new];
    [MKOrchestra setSamplingRate: 44100]; 
    [MKOrchestra setFastResponse: YES];
    [MKOrchestra run];
    [MKConductor startPerformance];
    return self;
}

- init
{
    self = [super init];
    if(self != nil) {
	[MKConductor lockPerformance];
	myNote = [[Note alloc] init];
	mySynthPatch = [MKOrchestra allocSynthPatch: [Pluck class]];
	[MKConductor unlockPerformance];	
    }
    return self;
}

@end

