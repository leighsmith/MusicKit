/*
  $Id$
  Example Application within the MusicKit

  Description:
    This example program captures MIDI input into a scorefile.

    Each time you push the button a new MIDI recording session begins. The
    input is written to the file with the name specified in the graphic interface
    field.

    MidiRecord is an example of an interactive MusicKit performance.
    Therefore, the MKConductor is clocked. The MKConductor is also set to not
    'finishWhenEmpty'. This ensures the performance will continue, whether or
    not the MKConductor has any Objective-C messages to send,
    until the user decides to terminate the performance. Finally, we set
    the MKMidi object to 'useInputTimeStamps' so that the times written to the
    output file are as precise as possible.

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2004, The MusicKit Project.
*/
#import "MidiRecord.h"

@implementation MidiRecord

#import <AppKit/AppKit.h>
//#import <MKSynthPatches/MKSynthPatches.h>

static void handleMKError(NSString *msg) {
    if (!NSRunAlertPanel(@"MidiRecord", msg, @"OK", @"Quit", nil, NULL))
	[NSApp terminate:NSApp];
}

/* This method sets things up and begins the performance. */
- start
{
    NSArray *partRecorders;
    MKPart *aPart;
    MKNote *info;
    int i;

    needsUpdate = YES;
    [saveAsMenuItem setEnabled: YES]; /* Something to save now. */
    [score release];                  /* Free old score, parts and notes. */
    score = [[MKScore alloc] init];   /* Make a new Score to store Notes */
    for (i = 0; i < 17; i++) {        /* 16 channels and one for system msgs */
	aPart =[[MKPart alloc] init]; /* Make a new Part for each channel */

	/* Each MKPart has an 'info' MKNote which contains some special info
	   for that MKPart. In this case we put the midiChan there. */
	info = [[MKNote alloc] init];
	if (i != 0)  {               /* The 0th 'channel' is our 'sys' MKPart */
	    [info setPar: MK_midiChan toInt: i]; 
	    [info setPar: MK_synthPatch toString: @"midi"]; 
	}
	[aPart setInfoNote: info];
	[score addPart: aPart];     /* Add the MKPart to the MKScore. */
    }
    scoreRecorder = [[MKScoreRecorder alloc] init];

    /* MKScoreRecorder is an MKInstrument that collects MKNotes and writes them to a MKScore. */
    [scoreRecorder setScore: score];

    /* MKScoreRecorder automatically creates a MKPartRecorder for each MKPart in 
       the MKScore. The -partRecorders method returns a NSArray containing those MKPartRecorders. */
    partRecorders = [scoreRecorder partRecorders]; 

    /* Connect the outputs of the MKMidi object to the inputs of each of the MKPartRecorders. */
    for (i = 0; i < [partRecorders count]; i++)         
	[[midiIn channelNoteSender: i] connect:
	 [[partRecorders objectAtIndex: i] noteReceiver]];
      
    [midiIn setUseInputTimeStamps: YES];   /* We want MIDI driver's time stamps */
    [midiIn openInputOnly];                /* We don't need MIDI output so we specify 'input only' */

    [MKConductor setFinishWhenEmpty: NO];  /* Tell MKConductor not to quit when it has no more scheduled events.
					      Instead, tell it to wait until finishPerformance is received */
    [MKConductor useSeparateThread: YES];
    [midiIn run];                          /* Start midi clock */
    [MKConductor startPerformance];        /* Start the performance */
    return self;
}

- init
{
    self = [super init];
    if(self != nil) {
	midiIn = [[MKMidi midi] retain];           /* Get the MKMidi object for the default MIDI port */
    }
    return self;
}

- (void) setDriverName: (id) sender
{
    [midiIn close];
    [midiIn release];
    midiIn = [MKMidi midiOnDevice: [driverPopup titleOfSelectedItem]];
    [midiIn retain];
    NSLog(@"setting the driver to %@\n", [midiIn driverName]);
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification 
{
    [driverPopup removeAllItems];
    [driverPopup addItemsWithTitles: [MKMidi getDriverNames]];
    [driverPopup selectItemWithTitle: [midiIn driverName]];
    savePanel = [[NSSavePanel savePanel] retain];
    MKSetErrorProc(handleMKError);
}

- finish
  /* This method is used to write the file and finish the performance. */
{
    [MKConductor finishPerformance]; /* End the performance */
    [midiIn close];                  /* Close the midi device */
    [scoreRecorder release];         /* Also releases contained MKPartRecorders */
    return self;
}

- (void) go: (id) sender
  /* This method is invoked when the button is pushed. */ 
{
    if ([MKConductor inPerformance]) { /* We're already performing */
	[recordButton setTitle: @"Start recording"];   /* Change the button name */
	[self finish];              /* Write file and end performance. */
    }
    else {                        /* New performance */
	[recordButton setTitle: @"Stop recording"];    /* Change the button name */
	[self start];               /* Start things up */
    } 
}

- (void) saveAs: (id) sender
{
    if (sender != self) {
        if (!savePanel) {
            [savePanel setTitle: @"MidiRecord Save"];
        }
        [savePanel setRequiredFileType: @"score"];
        if ([savePanel runModalForDirectory: @"" file: @""])  {
            if(scoreFilePath != nil)
                [scoreFilePath release];
            scoreFilePath = [[savePanel filename] retain];
            [saveMenuItem setEnabled: YES];   /* We have a default now. */
        }
        else
            return;
    }
    if ([MKConductor inPerformance])
	[self go: self];                       /* End performance. */
    [myWindow setTitle: scoreFilePath];
    [myWindow display];
    [score writeScorefile: scoreFilePath];     /* Write the file. */
    needsUpdate = NO; 
}

- (void) save: sender
{
    [self saveAs: ([scoreFilePath length] > 0) ? self : nil];
}

- (IBAction) showInfoPanel: sender
{
    [NSBundle loadNibNamed: @"Info" owner: self];
    [infoPanel orderFront: sender]; 
}

/* Sent via 'quit' option in menu. Before the app terminates. */
- (void) applicationWillTerminate: (NSNotification *) aNotification
{
    if ([MKConductor inPerformance]) 
	[self finish];
    if (needsUpdate)
        if (NSRunAlertPanel(@"MidiRecord", @"Save file before quitting?", @"Yes", @"No", nil))
	    [self save: self];
}

@end
