/* 
  playscorefile-qp.

  Author: David A. Jaffe.
  
  This is a version of the standard playscorefile programming example, but
  modified to synthesize the sound on the Ariel QuintProcessor 5-DSP board.

  See README for a description of this program.
*/

#import <musickit/musickit.h>
#import <musickit/synthpatches/synthpatches.h>

main(ac, av)
  int ac;
  char * av[];
{
    int i,orchNum;
    id aScorePerformer,orchestras[6];
    BOOL alsoUseNextDSP = NO;

    for (i=1; i<ac; i++) {  
	/* Read command line arguments. Usage: [-t <num>  <  <file>] */
	if (av[i][1] == 't') 
	    MKSetTrace(atoi(av[++i]));
	if (av[i][1] == 'n') 
	  alsoUseNextDSP = YES;
    }	
    if (isatty(0)) {
	fprintf(stderr,"usage: playscorefile [-t -n] < scorefile\n");
	exit(1);
    }
    else fprintf(stderr,"playscorefile reading scorefile...\n");
    
    {	/* Create a Score object and read a scorefile into it. Then create a 
	   ScorePerformer to perform the Score and configure the performance 
	   from the 'info' field of the scorefile . */

	id scoreInfo;                                    /* Used for 'info' */
	id aScore = [[Score alloc] init];
	NXStream *stdinStream = NXOpenFile(stdin->_file,NX_READONLY);

	/* Read scorefile from stdin. */
	if (![aScore readScorefileStream:stdinStream]) { /* Error in file? */
	    fprintf(stderr,"Fix scorefile errors and try again.\n");
	    exit(1);
	}

	/* Create a ScorePerformer to perform the Score and activate it. */
	aScorePerformer = [[ScorePerformer alloc] init];
	[aScorePerformer setScore:aScore];
	[aScorePerformer activate]; 

	scoreInfo = [aScore info];
	if (scoreInfo) { /* Configure performance as specified in info. */ 

	    /* "headroom" determines how close to the limit of the DSP we want
	       to run. If headroom is 0 or negative, there is a higher risk
	       of falling out of real time (interruptions will be heard).
	       If headroom is positive (e.g. .25), it is unlikely you will
	       fall out of real time. */
	    if ([scoreInfo isParPresent:MK_headroom])
		[Orchestra setHeadroom:[scoreInfo parAsDouble:MK_headroom]];
	    /* Set sampling rate. The Sound hardware only functions at 
	       44100 or 22050. */
	    if ([scoreInfo isParPresent:MK_samplingRate]) {
		double samplingRate = [scoreInfo parAsDouble:MK_samplingRate];
		if ((samplingRate == 44100.0) || (samplingRate == 22050.0)) 
		  [Orchestra setSamplingRate:samplingRate];
		else fprintf(stderr,
			     "Sampling rate must be 44100 or 22050.\n");
	    }
	    /* Get tempo and set the tempo of the default Conductor. */
	    if ([scoreInfo isParPresent:MK_tempo]) {
		double tempo = [scoreInfo parAsDouble:MK_tempo];
		[[Conductor defaultConductor] setTempo:tempo];
	    }
	}
    }
    fprintf(stderr,"...done\n");

    /* Open the Orchestra. */
    orchestras[5] = [ArielQP new];
    if (!orchestras[5]) {
	fprintf(stderr,"No Ariel QuintProcessor found in slot 2.\n");
	exit(1);
    }
    [orchestras[5] setSerialPortDevice:[[ArielProPort alloc] init]];
    for (i=1; i<=4; i++)
      orchestras[i] = [orchestras[5] satellite:i+'A'-1]; 
    if (![Orchestra open]) {
	fprintf(stderr,"Can't open QuintProcessor.\n");
	exit(1);
    }
    [orchestras[5] allocSynthPatch:[ArielQPMix class]];

    { /* Create a SynthInstrument for each Part in the Score and set them
	 up as specified in the corresponding 'info'. */

	int partCount,synthPatchCount,voices;
	char *className;
	id partPerformers,synthPatchClass,partPerformer,partInfo,anIns,aPart;

	partPerformers = [aScorePerformer partPerformers];
	partCount = [partPerformers count];
	for (i = 0; i < partCount; i++) {
	    partPerformer = [partPerformers objectAt:i];
	    aPart = [partPerformer part]; 
	    partInfo = [aPart info];      /* Get info from Part. */
	    if (!partInfo) {              /* Omit Parts with no info. */ 
		fprintf(stderr,"%s info missing.\n",MKGetObjectName(aPart));
		continue;
	    }		

	    /* Look in the partInfo for a SynthPatch name. If none, omit
	       this Part. */
	    if (![partInfo isParPresent:MK_synthPatch]) {
		fprintf(stderr,"%s info missing synthPatch.\n",
			MKGetObjectName(aPart));
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

	    /* Create a new SynthInstrument to manage the notes from
	       aPart and connect the partPerformer to the SynthInsturment. */
	    anIns = [[SynthInstrument alloc] init];
	    [[partPerformer noteSender] connect:[anIns noteReceiver]];

	    if ([partInfo isParPresent:MK_orchestraIndex]) {
		orchNum = [partInfo parAsInt:MK_orchestraIndex];
		if (![Orchestra nthOrchestra:orchNum]) {
		    fprintf(stderr,"Part info calls for an Orchestra (%d) that does not exist.",orchNum);
		    orchNum = -1;
		}
	    }
	    else orchNum = -1;

	    /* Set the new SynthInstrument to use the specified SynthPatch */
	    if (orchNum != -1)
	      [anIns setSynthPatchClass:synthPatchClass orchestra:orchestras[orchNum]];
	    else [anIns setSynthPatchClass:synthPatchClass];

	    /* Look for the synthPatchCount for this part. */
	    if (![partInfo isParPresent:MK_synthPatchCount])
		continue;       /* Do allocation of voices from a common pool
				   on the fly during performance. */

	    /* Otherwise, use a number of voices specified by the part info */
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
			synthPatchCount,voices, 
			[synthPatchClass name],MKGetObjectName(aPart));
	}
    }

    /* Prepare Conductor */
    MKSetDeltaT(1.0);              /* Run at least one second ahead of DSP */
    [Conductor setClocked:NO];     /* Conductor feeds DSP as fast as it can. */
    [Conductor setThreadPriority:1.0];  /* Boost priority of performance. */ 

    fprintf(stderr,"playing...\n");
    [Orchestra run];                /* Start the DSPs. */
    [Conductor startPerformance];   /* Start sending Notes, loops till done.*/

    /* Here's where the music plays. Conductor's startPerformance method
       does not return until the performance is over.  Note, however, that
       if the Conductor is in a different mode, startPerformance returns 
       immediately (if it is in clocked mode or if you have specified that the 
       performance is to occur in a separate thread).  See the Conductor 
       documentation for details. 
       */
   
    /* Now clean up. */
    [Orchestra close];                /* Releases DSPs. */
    fprintf(stderr,"...done\n");
    exit(0);
}







