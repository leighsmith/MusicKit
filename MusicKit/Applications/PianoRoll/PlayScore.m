/* $Id$
  Plays scorefile in background. -- David Jaffe 
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>
#import "PlayScore.h"

@implementation PlayScore:NSObject

static NSMutableArray *synthInstruments;
static MKScorePerformer *scorePerformer;
static MKOrchestra *theOrch;
static double samplingRate = 22050;
static double headroom = .1;
static double initialTempo;

static BOOL userCancelFileRead = NO;

static void handleMKError(NSString *msg)
{
    if (![MKConductor inPerformance]) {
	if (!NSRunAlertPanel(@"PianoRoll", msg, @"OK", @"Cancel", nil, NULL)) {
	  MKSetScorefileParseErrorAbort(0);
	  userCancelFileRead = YES;         /* A kludge for now. */
      }
    }
    else {
	NSLog(msg);
    }
}

-(BOOL)isPlaying
{
    return (BOOL)(theOrch && [theOrch deviceStatus] == MK_devRunning);
}

- (void)setUpPlay: (MKScore *) scoreObj
{
   /* Could keep these around, in repeat-play cases: */ 
    id scoreInfo;
    if ([self isPlaying])
    	[self stop];
    samplingRate = 22050;
    headroom = .1;
//    MKSetTrace(1023);
    [[MKConductor defaultConductor] setTempo:initialTempo = 60];
    scoreInfo = [scoreObj infoNote];
    if (scoreInfo) { /* Configure performance as specified in info. */ 
	if ([scoreInfo isParPresent:MK_headroom])
            headroom = [scoreInfo parAsDouble:MK_headroom];	  
	if ([scoreInfo isParPresent:MK_samplingRate]) {
	    samplingRate = [scoreInfo parAsDouble:MK_samplingRate];
	    if (!((samplingRate == 44100.0) || (samplingRate == 22050.0))) 
		NSRunAlertPanel(@"ScorePlayer", @"Sampling rate must be 44100 or 22050.\n", @"OK", nil, nil);
	}
	if ([scoreInfo isParPresent:MK_tempo]) {
	    initialTempo = [scoreInfo parAsDouble:MK_tempo];
        [[MKConductor defaultConductor] setTempo:initialTempo];
	} 
    } 
    [scorePerformer release];
    scorePerformer = nil;  // Be Wary of this LMS
    [synthInstruments removeAllObjects];
    [synthInstruments release]; 
    synthInstruments = nil;  // Be wary of this LMS
}

- (BOOL) play:scoreObj
{
    int partCount,synthPatchCount,voices,i;
    NSString *className;
    id partPerformers,synthPatchClass,partPerformer,partInfo,anIns,aPart;

    if ([self isPlaying])
    	[self stop];
    theOrch = [MKOrchestra newOnDSP:0]; /* A noop if it exists */
//    [theOrch setHeadroom:headroom];    /* Must be reset for each play */ 
    [theOrch setSamplingRate:samplingRate];
    if (![theOrch open]) {
	NSRunAlertPanel(@"ScorePlayer", @"Can't open DSP. Perhaps another application has it.", @"OK", nil, nil);
	return NO;
    }
    scorePerformer = [MKScorePerformer new];
    [scorePerformer setScore:scoreObj];
    [scorePerformer activate]; 
    partPerformers = [scorePerformer partPerformers];
    partCount = [partPerformers count];
    synthInstruments = [[NSMutableArray alloc] init];
    for (i = 0; i < partCount; i++) {
	partPerformer = [partPerformers objectAtIndex:i];
	aPart = [partPerformer part]; 
	partInfo = [aPart infoNote];      
	if ((!partInfo) || ![partInfo isParPresent:MK_synthPatch]) {
	    if (!NSRunAlertPanel(@"ScorePlayer", 
                [NSString stringWithFormat: @"%@ info missing.\n", MKGetObjectName(aPart)], @"Continue", @"Cancel", nil)) 
	      return NO;
	    continue;
	}		
	className = [partInfo parAsStringNoCopy:MK_synthPatch];
        synthPatchClass = [MKSynthPatch findSynthPatchClass:className];
        
	if (!synthPatchClass) {         /* Class not loaded in program? */ 
	    if (!NSRunAlertPanel(@"ScorePlayer", 
                [NSString stringWithFormat: @"This scorefile calls for a synthesis instrument (%@) that isn't available in this application.\n", className],
                     @"Continue", @"Cancel", nil))
	      return NO;
	    /* We would prefer to do dynamic loading here. */
	    continue;
	}
	anIns = [MKSynthInstrument new];      
	[synthInstruments addObject:anIns];
	[[partPerformer noteSender] connect:[anIns noteReceiver]];
	[anIns setSynthPatchClass:synthPatchClass];
	if (![partInfo isParPresent:MK_synthPatchCount])
	  continue;         
	voices = [partInfo parAsInt:MK_synthPatchCount];
	synthPatchCount = 
	  [anIns setSynthPatchCount:voices patchTemplate:
	   [synthPatchClass patchTemplateFor:partInfo]];
        [anIns release]; /* since retain is now held in synthInstruments array! */
	if (synthPatchCount < voices) {
	    if (!NSRunAlertPanel(@"ScorePlayer", 
                [NSString stringWithFormat: @"Could only allocate %d instead of %d %@s for %@\n",
		    synthPatchCount, voices, className, MKGetObjectName(aPart)], 
                    @"Continue", @"Cancel", nil))
	      return NO;
	}
    }
//    [partPerformers release];
    MKSetDeltaT(1.0);
    [MKConductor setClocked:YES];     
//    [MKOrchestra setTimed:YES];
    [MKConductor afterPerformanceSel:@selector(close) to:theOrch argCount:0];
//    [MKConductor afterPerformanceSel:@selector(hello) to:self argCount:0];

    [theOrch run];
    [MKConductor startPerformance];
    return YES; 
}

- init
{
    static int inited = 0;
    [super init];
    if (inited++)
        return self;
    [MKConductor setThreadPriority:1.0];
    [MKConductor useSeparateThread:YES];
    MKSetErrorProc(handleMKError);

    return self;
}
- (void)dealloc
{
    [scorePerformer release];
    [synthInstruments removeAllObjects];
    [synthInstruments release];
    [theOrch release];
}

- stop
{
    [MKConductor lockPerformance];
//    [theOrch abort];
    [MKConductor finishPerformance];
    [MKConductor unlockPerformance];
    [theOrch close];
    return self;
}

@end

