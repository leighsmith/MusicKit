/* 
 * NotePlayer example #2
 * by David A. Jaffe
 * updated by Leigh M. Smith
 */
#import <MusicKit/MusicKit.h>
#import <MKSynthPatches/Pluck.h>
#import <AppKit/AppKit.h>

- play:sender
{
    [MKConductor lockPerformance];
    [mySynthPatch noteOn:myNote];
    [MKConductor unlockPerformance];
    return self;
}

- setFreqFrom:sender
{
    [MKConductor lockPerformance];
    [myNote setPar:MK_freq toDouble:[sender doubleValue]];
    [mySynthPatch noteUpdate:myNote];
    [MKConductor unlockPerformance];
    return self;
}

+ initialize
{
    [MKConductor setFinishWhenEmpty:NO];
    [MKOrchestra new];
    [MKOrchestra setSamplingRate:44100]; 
    [MKOrchestra setFastResponse:YES];
    [MKOrchestra run];
    [MKConductor startPerformance];
    return self;
}

- init
{
    [super init];
    [MKConductor lockPerformance];
    myNote = [[Note alloc] init];
    mySynthPatch = [MKOrchestra allocSynthPatch:[Pluck class]];
    [MKConductor unlockPerformance];
    return self;
}
