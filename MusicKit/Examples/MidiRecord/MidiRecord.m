/*
  $Id$
  Example Application within the MusicKit

  Description:
    This example program captures MIDI input in a scorefile.

    Each time you push the button a new MIDI recording session begins. The
    input is written to the file with the name specified in the graphic interface
    field.

    MidiRecord is an example of an interactive Music Kit performance.
    Therefore, the Conductor is clocked. The Conductor is also set to not
    'finishWhenEmpty'. This ensures the performance will continue, whether or
    not the Conductor has any objective-c messages to send,
    until the user decides to terminate the performance. Finally, we set
    the midi object to 'useInputTimeStamps' so that the times written to the
    output file are as precise as possible.

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
#import "MidiRecord.h"

@implementation MidiRecord

#import <AppKit/AppKit.h>
//#import <synthpatches/synthpatches.h>


static void handleMKError(char *msg) {
    if (!NSRunAlertPanel(@"MidiRecord", [NSString stringWithCString:msg], @"OK", @"Quit", nil, NULL))
	[NSApp terminate:NSApp];
}

- _start
    /* This method sets things up and begins the performance. */
{
    NSArray *partRecorders;
    MKPart *aPart;
    MKNote *info;
    int i;

    needsUpdate = YES;
    // MKSetErrorProc(handleMKError);  // FIXME
    [saveAsMenuItem setEnabled:YES];  /* Something to save now. */
    [score release];                  /* Free old score, parts and notes. */
    score = [[MKScore alloc] init];   /* Make a new Score to store Notes */
    for (i = 0; i<17; i++) {          /* 16 channels and one for system msgs */
	aPart =[[MKPart alloc] init]; /* Make a new Part for each channel */

	/* Each Part has an 'info' MKNote which contains some special info
	   for that Part. In this case we put the midiChan there. */
	info = [[MKNote alloc] init];
	if (i != 0)  {               /* The 0th 'channel' is our 'sys' Part */
	    [info setPar: MK_midiChan toInt: i]; 
	    [info setPar: MK_synthPatch toString: @"midi"]; 
	}
	[aPart setInfoNote: info];
	[score addPart: aPart];     /* Add the Part to the Score. */
    }
    scoreRecorder = [[MKScoreRecorder alloc] init];

    /* ScoreRecorder is an Instrument that collects Notes and writes
       them to a Score. */
    [scoreRecorder setScore:score];

    /* ScoreRecorder automatically creates a PartRecorder for each Part in 
       the Score. The -partRecorders method returns a NSArray object. */
    partRecorders = [scoreRecorder partRecorders]; 
    midiIn = [[MKMidi midi] retain];           /* Get the Midi object for the default MIDI port */

    /* Connect the outputs of the Midi object to the inputs of each of 
       the PartRecorders. */
    for (i = 0; i<17; i++)         
	[[midiIn channelNoteSender: i] connect:
	 [[partRecorders objectAtIndex: i] noteReceiver]];
      
    [partRecorders release];               /* List is copied above so free here */
    [midiIn setUseInputTimeStamps:YES]; /* We want MIDI driver's time stamps */
    [midiIn openInputOnly];             /* We don't need MIDI output so we
					   specify 'input only' */

    [MKConductor setFinishWhenEmpty:NO];  /* Tell MKConductor not to quit when it 
					   has no more scheduled events.
					   Instead, tell it to wait until 
					   finishPerformance is received */
    [MKConductor useSeparateThread: YES];
    [midiIn run];                  /* Start midi clock */
    [MKConductor startPerformance];  /* Start the performance */
    return self;
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification 
{
    savePanel = [[NSSavePanel savePanel] retain];
}

-_finish
  /* This method is used to write the file and finish the performance. */
{
    [MKConductor finishPerformance];/* End the performance */
    [midiIn close];               /* Close the midi device */
    [scoreRecorder release];         /* Also frees contained PartRecorders */
    return self;
}

- (void)go:sender
  /* This method is invoked when the button is pushed. */ 
{
    if ([MKConductor inPerformance]) { /* We're already performing */
	[theButton setTitle:@"Start recording"];   /* Change the button name */
	[self _finish];              /* Write file and end performance. */
    } else  {                        /* New performance */
	[theButton setTitle:@"Stop recording"];    /* Change the button name */
	[self _start];               /* Start things up */
    } 
}

- (void)saveAs:sender
{
    if (sender != self) {
        if (!savePanel) {
            [savePanel setTitle:@"MidiRecord Save"];
        }
        [savePanel setRequiredFileType:@"score"];
        if ([savePanel runModalForDirectory:@"" file:@""])  {
            scoreFilePath = [savePanel filename];
            [saveMenuItem setEnabled:YES];   /* We have a default now. */
        }
        else
            return;
    }
    if ([MKConductor inPerformance])
	[self go:self];                       /* End performance. */
    [myWindow setTitle: scoreFilePath];
    [myWindow display];
    [score writeScorefile:scoreFilePath];     /* Write the file. */
    needsUpdate = NO; 
}

- (void)save:sender
{
    return [self saveAs: ([scoreFilePath length] > 0) ? self : nil];
}

- (void)showInfoPanel:sender
{
    [NSBundle loadNibNamed:@"Info.nib" owner:self];
//    [infoPanel orderFront:sender]; 
}

/* Sent via 'quit' option in menu. Before the app terminates. */
- (void) applicationWillTerminate: (NSNotification *) aNotification
{
    if ([MKConductor inPerformance]) 
	[self _finish];
    if (needsUpdate)
        if (NSRunAlertPanel(@"MidiRecord", @"Save file before quitting?", @"Yes", @"No", nil))
	    [self save:self];
}

@end
