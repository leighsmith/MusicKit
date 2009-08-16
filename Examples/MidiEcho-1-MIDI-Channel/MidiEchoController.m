/*
 $Id$
 
 Description:
   MidiEcho-1-Channel is an example of a MusicKit performance where the interactive
   response time needs to be as fast as possible, even if at the expense of 
   a bit of timing indeterminacy. Therefore, the MKConductor is clocked and 
   MKMidi is untimed (i.e. no delays are introduced in the MKMidi object). 
   The MKConductor is also set to not 'finishWhenEmpty'. This ensures the 
   performance will continue, whether or not the MKConductor has 
   any objective-c messages to send, until the user decides to terminate the 
   performance. The MKMidi object is set to not 'useInputTimeStamps' because
   we are not interested in the exact time the MIDI entered the computer, as
   we would be if we were recording the MIDI (See MidiRecord). 

 Portions Copyright (c) 1999-2005, The MusicKit Project.  All rights reserved.
 
   Permission is granted to use and modify this code for commercial and 
   non-commercial purposes so long as the author attribution and copyright 
   messages remain intact and accompany all relevant code.
 
 */

#import "MidiEchoController.h"

@implementation MidiEchoController

static NSString *dev = @"midi0"; /* Serial port B -- the default. */
static float delay = .1;

static void handleMKError(NSString *msg)
{
    if (!NSRunAlertPanel(@"MidiEcho", msg, @"OK", @"Quit", NULL, NULL))
	[NSApp terminate: NSApp];
}

- (IBAction) showInfoPanel: (id) sender
{
    [NSBundle loadNibNamed: @"Info.nib" owner: self];
    [infoPanel orderFront: sender];
}

- (IBAction) go: (id) sender
{
    if ([MKConductor inPerformance])  
    	return;

    MKSetErrorProc(handleMKError); /* Intercept Music Kit errors. */
       
    /* Get MKMidi object for the specified serial port. */
    midi = [MKMidi midiOnDevice: dev];

    /* Open it for input and output */
    [midi open];

    /* We use a MKNoteFilter subclass to make the echoes. */
    myFilter = [[EchoFilter alloc] init];
    [myFilter setDelay: delay];

    /* Connect up the MKMidi NoteSender for channel 1 to the MKNoteReceiver
       of the MKNoteFilter.  Connect up the MKNoteFilter noteSender to the  
       MKNoteReceiver of MKMidi for channel 1. */
    [[midi channelNoteSender: 1] connect:[myFilter noteReceiver]];
    [[myFilter noteSender] connect: [midi channelNoteReceiver: 1]];

    /* No delay in sending out midi out events */      
    [midi setOutputTimed: NO];     

    /* The driver's time stamps are not useful in this application */
    [midi setUseInputTimeStamps: NO]; 

    /* Boost priority of performance. */ 
    [MKConductor setThreadPriority: 1.0];

    /* Tell MKConductor not to quit when there are no more scheduled messages.
       We are often in the 'empty' state, waiting for the next MIDI message.
       */
    [MKConductor setFinishWhenEmpty: NO];   

    /* Start up MKMidi */
    [midi run];

    /* Start the MKConductor */
    [MKConductor startPerformance];
}

- (IBAction) setMidiDev: (id) sender
{
    if ([[sender selectedCell] tag])
	dev = @"midi0";
    else
	dev = @"midi1";
    if ([MKConductor inPerformance]) { /* Already started? */
	[MKConductor finishPerformance];
	[midi close];
	[midi release];    
	[myFilter release];
	myFilter = nil;
	[self go: self]; /* Start us up again. */
    }
}

- (IBAction) setDelayFrom: (id) sender
  /* This is invoked from the text field. Sets the delay used by the NoteFilter
   */
{
    delay = [sender floatValue];
    [myFilter setDelay: delay];
}

@end
