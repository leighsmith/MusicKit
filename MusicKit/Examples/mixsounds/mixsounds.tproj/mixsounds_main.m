/*
  $Id$

  Description:
    mixsounds is an example of a Music Kit performance that actually makes
    no sound. Rather, it's "output" is a sound file that is the result of
    a mix of the soundfiles specified in its input scorefile.
    See the README file on this directory for details.

    Since no real-time interaction is involved, and since we want the program
    to run as fast as possible, the Conductor is set to unclocked mode.
    In unclocked mode the Conductor's +startPerformance method initiates a
    tight loop that sends Notes as fast as possible until all Notes have been
    sent, then returns. In this program, each "Note" is actually a
    soundfile mix specification. 
*/

#import <Foundation/Foundation.h>
#import <MusicKit/MusicKit.h>

#define SCOREFILE_PERFORMER 0 // 1 to use MKScorefilePerformer, 0 to use MKScorePerformer

int main (int argc, const char *argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    int i,partCount;
#if SCOREFILE_PERFORMER
    MKScorefilePerformer *aSFPerformer;
    NSData *inStream;
#else
    MKScorePerformer *aScorePerformer;
    MKScore *mixScore;
#endif
    MKMixerInstrument *mixIns;
    double samplingRate = 44100;
    int channelCount = 2;
    MKNote *scoreInfo;
    NSArray *noteSenders;
    NSMutableData *outStream;

    if (argc != 3) {
        fprintf(stderr, "Usage: mixsounds <input score file> <output snd file>.\n");
        exit(1);
    }
    outStream = [NSMutableData data];
#if SCOREFILE_PERFORMER
    inStream = [NSData dataWithContentsOfFile: [NSString stringWithCString: argv[1]]];
    if (inStream == nil) {
        NSLog(@"Can't open score file %s\n.", argv[1]);
        exit(1);
    } 
    else
        NSLog(@"Input score file: %s\n", argv[1]);
    aSFPerformer = [[MKScorefilePerformer alloc] init];
    [aSFPerformer setStream: inStream];
    [aSFPerformer activate];
    scoreInfo = [aSFPerformer infoNote];
#else
    mixScore = [MKScore score];
    aScorePerformer = [[MKScorePerformer alloc] init];
    [mixScore readScorefile: [NSString stringWithCString: argv[1]]];
    [aScorePerformer setScore: mixScore];
    [aScorePerformer activate];
    scoreInfo = [mixScore infoNote];
    [[MKConductor defaultConductor] setTempo: [scoreInfo parAsDouble: MK_tempo]];
#endif
    if (scoreInfo) { /* Configure performance as specified in info. */
        if ([scoreInfo isParPresent: MK_samplingRate])
            samplingRate = [scoreInfo parAsDouble: MK_samplingRate];
        if ([scoreInfo isParPresent:[MKNote parName: @"channelCount"]])
            channelCount = [scoreInfo parAsInt:[MKNote parName: @"channelCount"]];
    }
    mixIns = [[MKMixerInstrument alloc] init];
    [mixIns setSamplingRate: samplingRate channelCount: channelCount writingToStream: outStream];
#if SCOREFILE_PERFORMER
    noteSenders = [aSFPerformer noteSenders];
#else
    noteSenders = [aScorePerformer noteSenders];
#endif
    partCount = [noteSenders count];
    for (i = 0; i < partCount; i++)
        [[noteSenders objectAtIndex: i] connect: [mixIns noteReceiver]];
    [MKConductor setClocked: NO];     /* User process runs as fast as it can. */
    NSLog(@"mixing...\n");

    [MKConductor startPerformance];  /* Start sending Notes, loops till done.*/

    /* Conductor's startPerformance method
    does not return until the performance is over.  Note, however, that
    if the Conductor is in a different mode, startPerformance returns
    immediately (if it is in clocked mode or if you have specified that the
    performance is to occur in a separate thread).  See the Conductor
    documentation for details.
    */

    NSLog(@"...done\n");
    if (![outStream writeToFile: [NSString stringWithCString: argv[2]] atomically: NO]) {
        NSLog(@"Can't create %s\n.", argv[2]);
        exit(1);
    }
    else
        NSLog(@"Output sound file: %s\n", argv[2]);
    [mixIns release];
    [pool release];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}
