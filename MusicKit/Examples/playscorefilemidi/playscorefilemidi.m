/* 
  $Id$
  
  Description:

    This example illustrates playing a Music Kit scorefile on an external
    MIDI synthesizer. It reads the scorefile from stdin and plays it 'on
    the fly', i.e. as it is read.  This is analagous to the programming
    example 'playscorefile2', which plays a scorefile on the DSP as it is
    being read. An alternative is to first read the scorefile into a Score
    object and then play it.

    In the example program, the midi channel information for each part is gleaned
    from the part 'info' statement in the scorefile. If none is found, all
    notes go out on MIDI channel 1.

  Original Author: David A. Jaffe.

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/

/* playscorefilemidi is an example of a Music Kit performance that "spools" a 
   Score to MIDI. Since no real-time interaction is involved, all timing is
   done by the Midi object (actually, by the MIDI device driver); 
   thus, the Midi object is set to timed mode and the Conductor is set to 
   unclocked mode. In unclocked mode the Conductor's
   +startPerformance method initiates a tight loop that sends Notes as
   fast as possible until all Notes have been sent, then returns.  */

#import <MusicKit/MusicKit.h>

int main(int ac, char * av[])
{
    int i;
    MKScorefilePerformer *aSFPerformer;
    MKMidi *midi;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if (isatty(0)) {
	fprintf(stderr,"usage: %s < scorefile\n", av[0]);
	exit(1);
    }
    else {	
	id scoreInfo;                                    
	/* Read file from stdin. */
        NSFileHandle *stdinFileHandle = [NSFileHandle fileHandleWithStandardInput];
        NSData *stdinStream = [stdinFileHandle availableData];

	/* Create and activate the Performer. */
	aSFPerformer = [[MKScorefilePerformer alloc] init];
	[aSFPerformer setStream: stdinStream];

//        [stdinFileHandle closeFile];

	if([aSFPerformer activate] != nil) {
            /* Configure performance as specified in info statement in file. */
            scoreInfo = [aSFPerformer infoNote];
            if (scoreInfo) {
                /* Get tempo and set the tempo of the default Conductor. */
                if ([scoreInfo isParPresent:MK_tempo]) {
                    double tempo = [scoreInfo parAsDouble:MK_tempo];
                    [[MKConductor defaultConductor] setTempo:tempo];
                }
            }
	}
	else {
	    exit(1);
        }
    }

    /* Get the Midi object for the default MIDI serial port. */
    midi = [MKMidi midi];
    { 
	int partCount,chan;
	NSMutableArray *noteSenders;
        MKNote *partInfo;
        MKNoteSender *aNoteSender;

	noteSenders = [aSFPerformer noteSenders];
	partCount = [noteSenders count];
	for (i = 0; i < partCount; i++) {
	    /* Connect each part to Midi based on its midiChan parameter */
	    aNoteSender = [noteSenders objectAtIndex:i];
	    partInfo = [aSFPerformer infoNoteForNoteSender:aNoteSender];
	    /* Look in the partInfo for a midi channel. Default to 1. */
	    if (!partInfo)               
	      chan = 1;
	    if (![partInfo isParPresent:MK_midiChan]) 
	      chan = 1;
	    else chan = [partInfo parAsInt:MK_midiChan];
	    [aNoteSender connect:[midi channelNoteReceiver:chan]];
	}
    }

    /* Prepare Conductor */
    [MKConductor setDeltaT: 2.0];    /* Run at least two seconds ahead of MIDI.
				      For very dense scores, this number may
				      have to be increased. */
    [MKConductor setClocked:NO];     /* MKConductor feeds MIDI driver as fast as possible. */    
    [MKConductor setThreadPriority:1.0]; /* Boost priority of performance */
    [midi openOutputOnly];           /* No need for Midi input. */
    fprintf(stderr,"playing...\n");
    [midi run];                      /* This starts the device driver clock. */
    [MKConductor startPerformance];  /* Start sending Notes, loops until done.*/

     /* Here's where the music plays. MKConductor's startPerformance method
       does not return until the performance is over.  Note, however, that
       if the MKConductor is in a different mode, startPerformance returns 
       immediately (if it is in clocked mode or if you have specified that the 
       performance is to occur in a separate thread).  See the MKConductor 
       documentation for details. 
       */

    /* Now clean up. */
    [midi close]; 
    fprintf(stderr,"...done\n");
    [pool release];
    exit(0);        // insure the process exit status is 0
    return 0;       // ...and make main fit the ANSI spec.
}
