/* 
  playscorefile2.

  David A. Jaffe.
  
  See README for a description of this program.
*/

/* playscorefile2 is an example of a Music Kit performance that "spools" a 
   scorefile to the DSP. Since no real-time interaction is involved, all 
   timing is done on the DSP; thus, the Orchestra is set to timed mode and the
   Conductor is set to unclocked mode. In unclocked mode the Conductor's
   +startPerformance method initiates a tight loop that sends Notes as
   fast as possible until all Notes have been sent, then returns.  */

#import <musickit/musickit.h>
#import <musickit/synthpatches/synthpatches.h>

main(ac, av)
  int ac;
  char * av[];
{
    int i;
    id aSFPerformer,anOrch;

    [UnitGenerator enableErrorChecking:YES]; /* Added for debugging purposes */

    for (i=1; i<ac; i++) {  
	/* Read command line arguments. Usage: [-t <num>  <  <file>] */
	if (av[i][1] == 't') 
	    MKSetTrace(atoi(av[++i]));
    }	
    
    if (isatty(0)) {
	fprintf(stderr,"usage: playscorefile2 [-t] < inputfile\n");
	exit(1);
    }

    anOrch = [Orchestra new];
    {	/* Create a Score object and read a scorefile into it. Then create a 
	   ScorePerformer to perform the Score and configure the performance 
	   from the 'info' field of the scorefile . */

	id scoreInfo;                                    /* Used for 'info' */
	NXStream *stdinStream = NXOpenFile(stdin->_file,NX_READONLY);
	aSFPerformer = [[ScorefilePerformer alloc] init];

	[aSFPerformer setStream:stdinStream];
	[aSFPerformer activate]; 

	scoreInfo = [aSFPerformer info];
	if (scoreInfo) { /* Configure performance as specified in info. */ 
	    double samplingRate;
	    /* "headroom" determines how close to the limit of the DSP we want
	       to run. If headroom is 0 or negative, there is a higher risk
	       of falling out of real time (interruptions will be heard).
	       If headroom is positive (e.g. .25), it is unlikely you will
	       fall out of real time. */
	    if ([scoreInfo isParPresent:MK_headroom])
		[Orchestra setHeadroom:[scoreInfo parAsDouble:MK_headroom]];
	    /* Set sampling rate. The Sound hardware only functions at 
	       44100 or 22050. */
	    samplingRate = [anOrch defaultSamplingRate];
	    if ([anOrch prefersAlternativeSamplingRate] && 
		[scoreInfo isParPresent:MK_alternativeSamplingRate])
	      samplingRate = [scoreInfo parAsDouble:MK_alternativeSamplingRate];
	    else if ([scoreInfo isParPresent:MK_samplingRate]) {
		samplingRate = [scoreInfo parAsDouble:MK_samplingRate];
	    }
	    if ([anOrch supportsSamplingRate:samplingRate])
	      [Orchestra setSamplingRate:samplingRate];
	    else fprintf(stderr,"Unsupported sampling rate. %f\n",samplingRate);

	    /* Get tempo and set the tempo of the default Conductor. */
	    if ([scoreInfo isParPresent:MK_tempo]) {
		double tempo = [scoreInfo parAsDouble:MK_tempo];
		[[Conductor defaultConductor] setTempo:tempo];
	    }
	}
    }

    /* Open the Orchestra. */
    if (![anOrch open]) {
	fprintf(stderr,"Can't open DSP.\n");
	exit(1);
    }

    { /* Create a SynthInstrument for each part in the scorefile and set them
	 up as specified in the corresponding 'info'. Each part in the 
	 scorefile has a corresponding NoteSender in the ScorefilePerformer */

	int partCount,synthPatchCount,voices;
	char *className;
	id noteSenders,synthPatchClass,partInfo,anIns,aNoteSender;

	noteSenders = [aSFPerformer noteSenders];
	partCount = [noteSenders count];
	for (i = 0; i < partCount; i++) {
	    aNoteSender = [noteSenders objectAt:i];
	    partInfo = [aSFPerformer infoForNoteSender:aNoteSender];
	    if (!partInfo) {              /* Omit Parts with no info. */ 
		fprintf(stderr,"%s info missing.\n",
			MKGetObjectName(aNoteSender));
		continue;
	    }		

	    /* Look in the partInfo for a SynthPatch name. If none, omit
	       this part. */
	    if (![partInfo isParPresent:MK_synthPatch]) {
		fprintf(stderr,"%s info missing synthPatch.\n",
			MKGetObjectName(aNoteSender));
		continue;
	    }

	    /* Now set the SynthPatch of this Part as specified in the info */
	    className = [partInfo parAsStringNoCopy:MK_synthPatch];
	    synthPatchClass = (strlen(className) ? 
			       [SynthPatch findSynthPatchClass:className] : nil);
	    /* See comment in Makefile about dynamic loading requirements */
	    if (!synthPatchClass) {         /* Class not loaded in program? */ 
		fprintf(stderr,"Can't find SynthPatch class %s.\n",
			className);
		continue;
	    }

	    /* Create a new SynthInstrument to manage the notes from this part
	       and connect the noteSender to the SynthInsturment's 
	       noteReceiver. */
	    anIns = [[SynthInstrument alloc] init];
	    [aNoteSender connect:[anIns noteReceiver]];

	    /* Set the new SynthInstrument to use the specified SynthPatch */
	    [anIns setSynthPatchClass:synthPatchClass];

	    /* Look for the synthPatchCount for this part. */
	    if (![partInfo isParPresent:MK_synthPatchCount])
	      continue;         /* Do allocation of voices from a common pool
				   on the fly during performance. */

	    /* Otherwise, use a number of voices specified by the part info.*/
	    voices = [partInfo parAsInt:MK_synthPatchCount];
	    synthPatchCount = 
	      [anIns setSynthPatchCount:voices patchTemplate:
	       [synthPatchClass patchTemplateFor:partInfo]];
	    /* A given SynthPatch can have several versions or 
	       "PatchTemplates". For example, there may be one version
	       that supports vibrato and another that does not.
	       The SynthPatch class provides a method to
	       determine the correct version for a given Note. In this case,
	       we pass the SynthPatch class the Part info and allow it
	       to customize based on the information contained therein. */

	    if (synthPatchCount < voices) 
		fprintf(stderr,
			"Could only allocate %d instead of %d %ss for %s\n",
			synthPatchCount,voices,[synthPatchClass name],
			MKGetObjectName(aNoteSender));
	}
    }

    /* Prepare Conductor */
    MKSetDeltaT(1.0);              /* Run at least one second ahead of DSP.
				      For very dense scores, this number may
				      have to be increased. */
    [Conductor setClocked:NO];     /* Conductor feeds DSP as fast as it can. */
    [Conductor setThreadPriority:1.0];  /* Boost priority of performance. */ 
    [anOrch run];                  /* Start the DSP. */
    fprintf(stderr,"playing...\n");
    [Conductor startPerformance];  /* Start sending Notes, loops till done.*/

     /* Here's where the music plays. Conductor's startPerformance method
       does not return until the performance is over.  Note, however, that
       if the Conductor is in a different mode, startPerformance returns 
       immediately (if it is in clocked mode or if you have specified that the 
       performance is to occur in a separate thread).  See the Conductor 
       documentation for details. 
       */

    /* Now clean up. */
    [anOrch close];                /* Releases DSP. */
    fprintf(stderr,"...done\n");
    exit(0);
}







