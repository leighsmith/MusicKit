/* 
  playpart.

  Author: David A. Jaffe.
  
  See README for a description of this program.
*/

/* playpart is an example of a Music Kit performance that "spools" a 
   Score to the DSP. Since no real-time interaction is involved, all 
   timing is done on the DSP; thus, the Orchestra is set to timed mode and the
   Conductor is set to unclocked mode. In unclocked mode the Conductor's
   +startPerformance method initiates a tight loop that sends Notes as
   fast as possible until all Notes have been sent, then returns.  */

#import <MusicKit/MusicKit.h>
// LMS #import <MKSynthPatches/synthpatches.h>
#import <MusicKit/pitches.h>

static double ranNum(void)
    /* Returns a random number between 0 and 1. */
{
    static double oldRanValue = 0;
    double newVal;
#   define   RANDOMMAX (double)((long)MAXINT)
    newVal =  ((double)random()) / RANDOMMAX;
    /* Low pass filter the noise for more coherency */
    newVal = (newVal * .75 + oldRanValue * .25);  
    oldRanValue = newVal;
    return newVal;
}

static char *ranTimbre(double freq)
    /* Returns a randomly selected timbre from a set determined by the
       frequency range. */
{
    int i;
#   define RANTIMBRE(_x) (_x[i = SIZEOF(_x) * ranNum()])
#   define SIZEOF(_x) ((sizeof(_x) - 1) / sizeof(char *))
    static char *highTimbres[] = 
	{"SA","SE","SI","SO","SU","TR","SS","CL","OB"};
    static char *mediumTimbres[] = 
	{"TR","CL","OB","TA","TE","TI","TO","TU","BN","AS","BC","EH"};	
    static char *lowTimbres[] = {"BA","BE","BO","BU"};
    if (freq > f4) 
	return RANTIMBRE(highTimbres);
    else if (freq > c3) 
	return RANTIMBRE(mediumTimbres);
    else 
	return RANTIMBRE(lowTimbres);
}

int computeNotes(void)
{
    double freqBase,curTime;
    id ampEnvelope, freqEnvelope;
    int i,j;
    MKPartPerformer *aPartPerformer;
    MKPart *aPart;
    MKNote *aNote;
    MKSynthInstrument *aSynthInstrument;
    MKOrchestra *anOrch;
    

    /* Make envelopes */
    double xAmpArray[] = {0,.1,.2,.3}; 
    double yAmpArray[] = {0,1,.1,0};
    double xFreqArray[] = {0,.05,.1,.2};
    double yFreqArray[] = {.99,1.1,1.0,.99};
    ampEnvelope = [[MKEnvelope alloc] init];
    [ampEnvelope setPointCount:4 xArray:xAmpArray yArray:yAmpArray];
    [ampEnvelope setStickPoint:2];
    freqEnvelope = [[MKEnvelope alloc] init];
    [freqEnvelope setPointCount:4 xArray:xFreqArray yArray:yFreqArray];
    [freqEnvelope setStickPoint:1];

    /* We put all Note in one Part. */
    aPart = [[MKPart alloc] init];

    /* Make a no-tag noteUpdate used for parameters shared by all notes. */
    aNote = [[MKNote alloc] initWithTimeTag:0];
    [aNote setNoteType:MK_noteUpdate];
    [aNote setPar:MK_ampEnv toEnvelope:ampEnvelope];
    [aNote setPar:MK_freqEnv toEnvelope:freqEnvelope]; 
    [aPart addNote:aNote];

    fprintf(stderr,"computing notes...\n");

#   define NOTES_PER_ITERATION 8
#   define DUR .3

    for (i = 0; i < 100; i++) {
	freqBase = pow(2.0,ranNum() * 4) * c2; /* Range is c2 to c6 */
	for (j = 0; j < NOTES_PER_ITERATION; j++) {
	    curTime += DUR;
	    aNote = [[MKNote alloc] initWithTimeTag:curTime];
	    [aNote setDur:NOTES_PER_ITERATION * DUR]; 
	    [aNote setPar:MK_velocity toInt:j * 5 + 50];
	    /* Ascending whole tone scales */
	    [aNote setPar:MK_freq toDouble:freqBase * pow(2.0,j/6.0)];
	    /* A bunch of other parameters */
	    [aNote setPar:MK_waveform toString: [NSString stringWithCString: ranTimbre(freqBase)]];
	    [aNote setPar:MK_ampAtt toDouble:ranNum() * .3 + .1];
	    [aNote setPar:MK_freqAtt toDouble:ranNum() * .3 + .1];
	    [aNote setPar:MK_svibAmp toDouble:.015 * ranNum() + .005];
	    [aNote setPar:MK_svibFreq toDouble:4.5 * ranNum() + 1];
	    [aNote setPar:MK_rvibAmp toDouble:.01 * ranNum() + .005];
	    [aPart addNote:aNote];
	}
    }

    /* Open the Orchestra. */
    anOrch = [MKOrchestra new];
    if ([anOrch prefersAlternativeSamplingRate]) 
        [anOrch setSamplingRate: 11025]; /* For slow memory DSP cards */ 

    if (![anOrch open]) {
	fprintf(stderr,"Can't open DSP.\n");
	exit(1);
    }

    /* Create a MKPartPerformer to perform the Part. */
    aPartPerformer = [[MKPartPerformer alloc] init];
    [aPartPerformer setPart: aPart];
    [aPartPerformer activate]; 

    /* Create a SynthInstrument to manage voice (SynthPatch) allocation,
       assign it 10 SynthPatches of the DBWave1vi class, and connect it
       to the MKPartPerformer. */
    aSynthInstrument = [[MKSynthInstrument alloc] init];
// LMS    [aSynthInstrument setSynthPatchClass:[DBWave1vi class]];
    [aSynthInstrument setSynthPatchCount:10];
    /* Connect the MKPartPerformer to the MKSynthInstrument */
    [[aPartPerformer noteSender] connect: [aSynthInstrument noteReceiver]];

    /* Prepare Conductor */
    MKSetDeltaT(1.0);              /* Run at least one second ahead of DSP */
    [MKConductor setClocked:NO];     /* User process runs as fast as it can and
				      loops until done. */

    fprintf(stderr,"playing...\n");
    [anOrch run];                  /* Start the DSP. */
    [MKConductor startPerformance];  /* Start sending MKNotes, loops until done. */

     /* MKConductor's startPerformance method
       does not return until the performance is over.  Note, however, that
       if the Conductor is in a different mode, startPerformance returns 
       immediately (if it is in clocked mode or if you have specified that the 
       performance is to occur in a separate thread).  See the Conductor 
       documentation for details. 
       */

    /* Now clean up. */
    [anOrch close];                /* Releases DSP. */
    fprintf(stderr,"...done\n");
    return(0);
}







