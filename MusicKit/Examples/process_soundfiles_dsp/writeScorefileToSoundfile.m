/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */

/* 
  writeScorefileToSoundfile.

  Author: David A. Jaffe.
  
  This is almost exactly like
  /LocalDeveloper/Examples/MusicKit/playscorefile/playscorefile.m, except that
  it writes a soundfile rather than sending the samples to the sound-output.
*/
#import <musickit/musickit.h>

static char outputSoundfile[128] = "test.snd";

 main(ac, av)
  int ac;
  char * av[];
{
    int i;
    id aScorePerformer,anOrch;
    for (i=1; i<ac; i++) 
      {  /* Read command line arguments. 
	  * Usage: [-t <num>][-o <outputfile>]  <  <file> 
	  */
	  if (av[i][1] == 't') 
	    if (++i < ac)
	      MKSetTrace(atoi(av[i]));
	  if (av[i][1] == 'o')
	    if (++i < ac)
	      strcpy(outputSoundfile,av[i]);
      }	
    fprintf(stderr,"reading scorefile from standard input...\n");
    
    {	/* Create a Score object and read a scorefile into it. Then create a 
	   ScorePerformer to perform the Score and configure the performance 
	   from the 'info' field of the scorefile . */

	id scoreInfo;                                    /* Used for 'info' */
	id aScore = [Score new];                  
	NXStream *stdinStream = NXOpenFile(stdin->_file,NX_READONLY);

	/* Read scorefile from stdin. */
	if (![aScore readScorefileStream:stdinStream]) { /* Error in file? */
	    fprintf(stderr,"Fix scorefile errors and try again.\n");
	    exit(1);
	}

	/* Create a ScorePerformer to perform the Score and activate it. */
	aScorePerformer = [ScorePerformer new];
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
	else {
	  [Orchestra setSamplingRate:22050.0];
	}
    }
    fprintf(stderr,"...done\n");

    /* Open the Orchestra. */
    anOrch = [Orchestra new];        
    [anOrch setOutputSoundfile:outputSoundfile];
    if (![anOrch open]) {
	fprintf(stderr,"Can't open DSP.\n");
	exit(1);
    }

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
	    if (!synthPatchClass) {         /* Class not loaded in program? */ 
		fprintf(stderr,"Class %s not loaded into program.\n",
			className);
		continue;
	    }

	    /* Create a new SynthInstrument to manage the notes from
	       aPart and connect the partPerformer to the SynthInsturment. */
	    anIns = [SynthInstrument new];      
	    [[partPerformer noteSender] connect:[anIns noteReceiver]];

	    /* Set the new SynthInstrument to use the specified SynthPatch */
	    [anIns setSynthPatchClass:synthPatchClass];

	    /* Look for the synthPatchCount for this part. */
	    if (![partInfo isParPresent:MK_synthPatchCount])
	      continue;         /* Do allocation of voices from a common pool
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
    [Conductor setClocked:NO];     /* User process runs as fast as it can. */

    fprintf(stderr,"writing soundfile %s...\n",outputSoundfile);
    [anOrch run];                  /* Start the DSP. */
    [Conductor startPerformance];  /* Start sending Notes, loops till done.*/
    /* Here's where the sound is written. */
    /* Now clean up. */
    [anOrch close];                /* Releases DSP. */
    fprintf(stderr,"...done\n");
    exit(0);
}







