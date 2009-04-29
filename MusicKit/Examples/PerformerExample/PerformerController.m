#import "PerformerController.h"
#import "RandomPerformer.h"
#import <MusicKit/MusicKit.h>
// #import <MKSynthPatches/DBWave1vi.h>

#define PERFORMERS 9

static RandomPerformer *performers[PERFORMERS];
static MKOrchestra *theOrch;

@implementation PerformerController

- showInfoPanel:sender
{
    [NSApp loadNibSection: @"InfoPanel.nib" owner: self];
    [infoPanel makeKeyAndOrderFront: NSApp];
    return self; 
}

#define STRINGVAL(_x) [stringTable valueForStringKey:_x]

/* Error handling routine */
static void handleMKError(NSString *msg)
{
    if ([MKConductor performanceThread] == NO_CTHREAD) { /* Not performing */
	if (!NSRunAlertPanel(@"ScorePlayer", msg, @"OK", @"Cancel", NULL, NULL))
	    [NSApp terminate: NSApp];
    }
    else {  
	/* When we're performing in a separate thread, we can't bring
	   up a panel because the Application Kit is not thread-safe.
	   In fact, neither is standard IO. Therefore, we use write() to
	   stderr here, causing errors to appear on the console.
	   Note that we assume that the App is not also writing to stderr.

	   An alternative would be to use mach messaging to signal the
	   App thread that there's a panel to be displayed.
	 */
	// int fd = stderr->_file;
	// char *str = "PerformerExample: ";
	// write(fd,str,strlen(str));
	// write(fd,msg,strlen(msg));
	// str = "\n";
	// write(fd,str,strlen(str));
	NSLog(msg);
    }
}

- applicationDidFinishLaunching: sender
{
    int i;
    MKSynthInstrument *anIns;

    if (theOrch) /* We're already playing? */
      return self;

    /* Set function to call when a Music Kit error occurs. */
    MKSetErrorProc(handleMKError);

    /* Create the MKOrchestra which manages all DSP activity. */
    theOrch = [MKOrchestra new];

    if ([theOrch prefersAlternativeSamplingRate]) 
      [theOrch setSamplingRate: 11025]; /* For slow memory DSP cards */ 

    /* Opening the MKOrchestra instance has the effect of claiming the DSP
       and allowing us to allocate MKOrchestra resources. */
    while (![theOrch open]) {               
	if (NSRunAlertPanel(@"PerformerExample",
			    STRINGVAL("DSPUnavailable"),
			    STRINGVAL("Quit"),
			    STRINGVAL("TryAgain"),
			    NULL) == NX_ALERTDEFAULT)
	    [self terminate:sender];
    }

    /* Create instances of our special Performers subclass. (See
       RandomPerformer.m for the definition of our subclass.) Then 
       assign a SynthInstrument and a synthesis voice (SynthPatch) to
        each. */
    for (i = 0; i < PERFORMERS; i++) {

	/* Create a RandomPerformer. */
	performers[i] = [[RandomPerformer alloc] init];

        /* Create a SynthInstrument to manage SynthPatches. */
	anIns = [[MKSynthInstrument alloc] init];

	/* Assign the class of SynthPatch. */
	[anIns setSynthPatchClass: [DBWave1vi class]];   

	/* only one note at a time on this Instrument */
	if ([anIns setSynthPatchCount:1] != 1) {
	    NSRunAlertPanel(@"PerformerExample",
			    STRINGVAL("TooManyVoices"),
			    @"OK", NULL, NULL);
	    [anIns free];
	    [performers[i] free];
	    performers[i] = nil;
	    break;
	}

	/* Connect our performer to the SynthInstrument. */
	[[performers[i] noteSender] connect: [anIns noteReceiver]];
	[performers[i] activate];
	[performers[i] pause];   /* Start with all paused. */
    }
    MKSetDeltaT(.75); /* Run about .75 seconds ahead of the time when the 
  			 DSP plays the sound. This gives the DSP a 
			 'cushion' and helps rhythmic steadiness. */

    /* Since all Performers may be paused, we need to tell the Conductor
       not to finish the performance if that occurs. */
    [MKConductor setFinishWhenEmpty: NO];

    /* Performance will run in a separate Mach thread to allow maximum
       independence between user interface and music. */
    [MKConductor useSeparateThread: YES];
    [MKConductor setThreadPriority: 1.0];  /* Boost priority of performance. */ 
    
    /* Start the DSP running */
    [theOrch run];				

    /* Start the performance. */
    [MKConductor startPerformance];        
    return self;
}

- pauseOrResume: sender
  /* Pause or resume the selected performer */
{    
    RandomPerformer *perf;
    int curPerformerIndex = [sender selectedTag];

    perf = performers[curPerformerIndex];
    [MKConductor lockPerformance];
    if ([perf status] == MK_paused)
	[perf resume];
    else
	[perf pause];
    [MKConductor unlockPerformance];
    return self;
}

- setOctave: sender
  /* Adjust the octave of the performer */
{    
    id selectedCell = [sender selectedCell];
    int curPerformerIndex = [selectedCell tag];

    [MKConductor lockPerformance];
    [performers[curPerformerIndex] setOctaveTo: [selectedCell intValue]];
    [MKConductor unlockPerformance];
    return self;
}

- setSpeed: sender
  /* Adjust the speed of the performer */
{    
    id selectedCell = [sender selectedCell];
    int curPerformerIndex = [selectedCell tag];
    /* Take inverse because slider is actually 1/rhythmicValue. */
    double val = 1.0 / ((double) [selectedCell floatValue]);

    [MKConductor lockPerformance];
    [performers[curPerformerIndex] setRhythmicValueTo: val];
    [MKConductor unlockPerformance];
    return self;
}

- applicationWillTerminate: sender
{
    /* Clean up gracefully (not really needed) */
    [MKConductor lockPerformance];
    [MKConductor finishPerformance];
    [MKConductor unlockPerformance];
    [theOrch close];
    return self;
}

@end

