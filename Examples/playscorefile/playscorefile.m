/* 
  playscorefile.

  Original Author: David A. Jaffe.
  Converted to Cocoa by: Leigh M. Smith
  
  playscorefile is an example of a MusicKit performance that "spools" a 
  Score to the DSP. Since no real-time interaction is involved, all timing is
  done on the DSP; thus, the MKOrchestra is set to timed mode and the
  MKConductor is set to unclocked mode. In unclocked mode the MKConductor's
  +startPerformance method initiates a tight loop that sends Notes as
  fast as possible until all Notes have been sent, then returns.
  See README for further description of this program.
*/

#import <MusicKit/MusicKit.h>
//#import <MKSynthPatches/MKSynthPatches.h>

int main(int ac, char *av[])
{
    int i;
    MKScorePerformer *aScorePerformer;
    MKOrchestra *anOrch;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    for (i = 1; i < ac; i++) {  
	/* Read command line arguments. Usage: [-t <num>  <  <file>] */
	if (av[i][1] == 't') 
	    MKSetTrace(atoi(av[++i]));
    }	
    if (isatty(0)) {
	fprintf(stderr, "usage: playscorefile [-t] < scorefile\n");
	exit(1);
    }
    else 
	fprintf(stderr, "playscorefile reading scorefile...\n");
    
    anOrch = [MKOrchestra new];
    {	/* Create a MKScore object and read a scorefile into it. Then create a 
	   MKScorePerformer to perform the MKScore and configure the performance 
	   from the 'info' field of the scorefile. */

	MKNote *scoreInfo;                                    /* Used for 'info' */
	MKScore *aScore = [[MKScore alloc] init];
	/* Read file from stdin. */
        NSFileHandle *stdinFileHandle = [NSFileHandle fileHandleWithStandardInput];
        NSData *stdinStream = [stdinFileHandle availableData];
	
	/* Read scorefile from stdin. */
	if (![aScore readScorefileStream: stdinStream]) { /* Error in file? */
	    fprintf(stderr, "Fix scorefile errors and try again.\n");
	    exit(1);
	}

	/* Create a ScorePerformer to perform the Score and activate it. */
	aScorePerformer = [[MKScorePerformer alloc] init];
	[aScorePerformer setScore: aScore];
	[aScorePerformer activate]; 

	scoreInfo = [aScore infoNote];
	if (scoreInfo) { /* Configure performance as specified in info. */ 
	    double samplingRate;
	    
	    /* "headroom" determines how close to the limit of the DSP we want
	       to run. If headroom is 0 or negative, there is a higher risk
	       of falling out of real time (interruptions will be heard).
	       If headroom is positive (e.g. .25), it is unlikely you will
	       fall out of real time. */
	    if ([scoreInfo isParPresent: MK_headroom])
		[MKOrchestra setHeadroom: [scoreInfo parAsDouble: MK_headroom]];
	    /* Set sampling rate. The Sound hardware only functions at 44100 or 22050. */
	    samplingRate = [anOrch defaultSamplingRate];
	    if ([anOrch prefersAlternativeSamplingRate] && 
		[scoreInfo isParPresent: MK_alternativeSamplingRate])
		samplingRate = [scoreInfo parAsDouble: MK_alternativeSamplingRate];
	    else if ([scoreInfo isParPresent: MK_samplingRate]) {
		samplingRate = [scoreInfo parAsDouble: MK_samplingRate];
	    }
	    if ([anOrch supportsSamplingRate: samplingRate])
	      [MKOrchestra setSamplingRate: samplingRate];
	    else fprintf(stderr,"Unsupported sampling rate. %f\n", samplingRate);

	    /* Get tempo and set the tempo of the default MKConductor. */
	    if ([scoreInfo isParPresent: MK_tempo]) {
		double tempo = [scoreInfo parAsDouble: MK_tempo];
		[[MKConductor defaultConductor] setTempo: tempo];
	    }
	}
    }
    fprintf(stderr, "...done\n");

    /* Open the MKOrchestra. */
    if (![anOrch open]) {
	fprintf(stderr, "Can't open DSP.\n");
	exit(1);
    }

    { /* Create a MKSynthInstrument for each MKPart in the MKScore and set them
	 up as specified in the corresponding 'info'. */

	int partCount, synthPatchCount, voices;
	NSString *className;
	NSArray *partPerformers;
	Class synthPatchClass;
	MKPartPerformer *partPerformer;
	MKNote *partInfo;
	MKSynthInstrument *anIns;
	MKPart *aPart;

	partPerformers = [aScorePerformer partPerformers];
	partCount = [partPerformers count];
	for (i = 0; i < partCount; i++) {
	    partPerformer = [partPerformers objectAtIndex: i];
	    aPart = [partPerformer part]; 
	    partInfo = [aPart infoNote];      /* Get info note from MKPart. */
	    if (!partInfo) {              /* Omit Parts with no info. */ 
		fprintf(stderr,"%s info missing.\n", [MKGetObjectName(aPart) UTF8String]);
		continue;
	    }		

	    /* Look in the partInfo for a MKSynthPatch name. If none, omit
	       this Part. */
	    if (![partInfo isParPresent: MK_synthPatch]) {
		fprintf(stderr,"%s info missing synthPatch.\n",	[MKGetObjectName(aPart) UTF8String]);
		continue;
	    }

	    /* Now set the MKSynthPatch of this MKPart as specified in the info */
	    className = [partInfo parAsStringNoCopy: MK_synthPatch];
	    synthPatchClass = ([className length] != 0 ? [MKSynthPatch findPatchClass: className] : nil);
	    /* See comment in Makefile about dynamic loading requirements */
	    if (!synthPatchClass) {         /* Class not loaded in program? */ 
		fprintf(stderr, "Can't find MKSynthPatch class %s.\n", [className UTF8String]);
		continue;
	    }

	    /* Create a new MKSynthInstrument to manage the notes from
	       aPart and connect the partPerformer to the SynthInsturment. */
	    anIns = [[MKSynthInstrument alloc] init];
	    [[partPerformer noteSender] connect: [anIns noteReceiver]];

	    /* Set the new MKSynthInstrument to use the specified MKSynthPatch */
	    [anIns setSynthPatchClass: synthPatchClass];

	    /* Look for the synthPatchCount for this part. */
	    if (![partInfo isParPresent: MK_synthPatchCount])
		continue;       /* Do allocation of voices from a common pool
				   on the fly during performance. */

	    /* Otherwise, use a number of voices specified by the part info */
	    voices = [partInfo parAsInt: MK_synthPatchCount];
	    synthPatchCount = [anIns setSynthPatchCount: voices
					  patchTemplate: [synthPatchClass patchTemplateFor: partInfo]];
	    /* A given MKSynthPatch can have several versions or 
	       "PatchTemplates". For example, there may be one version
	       that supports vibrato and another that does not.
	       The MKSynthPatch class provides a method to
	       determine the correct version for a given MKNote. In this case,
	       we pass the MKSynthPatch class the MKPart info and allow it
	       to customize based on the information contained therein. */

	    if (synthPatchCount < voices) 
		fprintf(stderr, "Could only allocate %d instead of %d %ss for %s\n",
			synthPatchCount, voices, [className UTF8String], [MKGetObjectName(aPart) UTF8String]);
	}
    }

    /* Prepare MKConductor */
    MKSetDeltaT(1.0);              /* Run at least one second ahead of DSP */
    [MKConductor setClocked: NO];     /* MKConductor feeds DSP as fast as it can. */
    [MKConductor setThreadPriority: 1.0];  /* Boost priority of performance. */ 

    fprintf(stderr, "playing...\n");
    [anOrch run];                  /* Start the DSP. */
    [MKConductor startPerformance];  /* Start sending MKNotes, loops till done.*/

    /* Here's where the music plays. MKConductor's startPerformance method
       does not return until the performance is over.  Note, however, that
       if the MKConductor is in a different mode, startPerformance returns 
       immediately (if it is in clocked mode or if you have specified that the 
       performance is to occur in a separate thread).  See the MKConductor 
       documentation for details. 
       */
   
    /* Now clean up. */
    [anOrch close];                /* Releases DSP. */
    fprintf(stderr, "...done\n");
    [pool release];
    exit(0);        // insure the process exit status is 0
    return 0;       // ...and make main fit the ANSI spec.
}






