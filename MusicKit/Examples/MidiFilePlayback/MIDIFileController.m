/* $Id$
 * This is a demonstration of MIDI playback from a Standard MIDI file together with sample file playback.
 * A mapping of MIDI channel and keynumber to specific sound files (a keymap plist file) is used to nominate
 * samples to play.
 * created by leigh on Tue 04-May-1999
 */

#import <AppKit/AppKit.h>
#import "MIDIFileController.h"

@implementation MIDIFileController

#define KEYMAPFORMAT @"chan:%d key:%d"
#define SOUNDFILEEXT @"wav"

// Needs to be done before the nib displays.
- (void) applicationDidFinishLaunching:(NSNotification *) aNotification 
{
    [driverPopup removeAllItems];
    [driverPopup addItemsWithTitles: [MKMidi getDriverNames]];
    [driverPopup selectItemWithTitle: [midiInstrument driverName]];
}

// User double clicked a MIDI filename to launch the app
- (BOOL) application:(NSApplication *) theApplication openFile:(NSString *) filename 
{
    [midiPathName release];   // since it was retained in -init
    midiPathName = [filename retain];
    [midiPathNameTextBox setStringValue: midiPathName];
    [playButton setEnabled: YES];
    return YES;
}

- init
{
    currentTempo = [tempoSlider doubleValue];
    sampleInstrument = [[MKSamplerInstrument alloc] init];
    [sampleInstrument retain];

    /* Get the Midi object for the default MIDI serial port. */
    midiInstrument = [MKMidi midi];
    [midiInstrument retain];
    NSLog(@"Initialised with %@ driver\n", [midiInstrument driverName]);

    aScorePerformer = [[MKScorePerformer alloc] init];
    [aScorePerformer retain];

    /* Create a PartPerformer to perform the Part. */
    samplePartPerformer = [[MKPartPerformer alloc] init];
    [samplePartPerformer retain];
    [[samplePartPerformer noteSender] connect: [sampleInstrument noteReceiver]];

    midiPathName = NSHomeDirectory();
    [midiPathName retain];

    // rather than just loading and playing a sound file, we read in a plist of a keymap allowing us to overide
    // specific MIDI channels and keys with sound files.
    keymap = nil;     // by default we don't do this until the user selects a keymap file.

    return self;
}

- (void) setTempo: (id) sender
{
    currentTempo = [sender doubleValue];
    [(MKConductor *)[MKConductor defaultConductor] setTempo: currentTempo];
}

- (void) setDriverName: (id) sender
{
    [midiInstrument close];
    [midiInstrument release];
    midiInstrument = [MKMidi midiOnDevice: [driverPopup titleOfSelectedItem]];
    [midiInstrument retain];
    NSLog([midiInstrument driverName]);
}

// Determine the sample filename to be assigned to this note using the keymap
- assignSampleFromKeymapOf: (MKNote *) aNote
{
    NSString *chanAndKeyNum = [NSString stringWithFormat: KEYMAPFORMAT, [aNote parAsInt: MK_midiChan], [aNote parAsInt: MK_keyNum]];
    NSString *filename = [keymap objectForKey: chanAndKeyNum];

    NSLog(@"Testing  %@\n", chanAndKeyNum);
    NSLog([aNote description]);
    if(filename == nil) { // if we can't find the filename using the keymap, we may be able to find it using the noteTag
        filename = [samplesIndexedByTag objectForKey: [NSNumber numberWithInt: [aNote noteTag]]];
    }
    if(filename != nil) {
        NSString *sampleFilePath = [keymapPathName stringByDeletingLastPathComponent];
        soundPathName = [sampleFilePath stringByAppendingPathComponent: filename];
        if([[soundPathName pathExtension] length] == 0)
            soundPathName = [soundPathName stringByAppendingPathExtension: SOUNDFILEEXT];
        NSLog(@"Assigning %@ to %@\n", soundPathName, chanAndKeyNum);
        [aNote setPar:MK_filename toString: soundPathName];
        [samplesIndexedByTag setObject: filename forKey: [NSNumber numberWithInt: [aNote noteTag]]];
        [sampleInstrument prepareSoundWithNote: aNote]; // optimisation to preload the samples.
        return self;
    }
    return nil;
}

// Enables a part to be played with the MKSampleInstrument.
// All we do is add a MK_filename parameter with the appropriate sample file.
- (BOOL) convertPartToSamples: (MKPart *) aPart
{
   NSMutableArray *noteList = [aPart notes];
   int i;
   MKNote *aNote;
   BOOL modify = NO;

   for(i = 0; i < [noteList count]; i++) {
       aNote = [noteList objectAtIndex: i];
       if([self assignSampleFromKeymapOf: aNote] != nil) {
	   modify = YES;
       } 
   }
   return modify;
}

- (void) connectPartsToChannels: (MKScorePerformer *) theScorePerformer forInstrument: (MKMidi *) theMidiInstrument
{
    int partCount, chan, i;
    NSArray *allNoteSenders;
    MKNote *partInfo = nil;
    MKNoteSender *aNoteSender;
    MKPart *aPart;

    allNoteSenders = [theScorePerformer noteSenders];
    partCount = [allNoteSenders count];
    for (i = 0; i < partCount; i++) {
        // Connect each part to MKMidi based on its midiChan parameter
        aNoteSender = [allNoteSenders objectAtIndex: i];
        aPart = [[aNoteSender owner] part];
        partInfo = [aPart infoNote];
        // Look in the partInfo for a midi channel. Default to 1.
        if (!partInfo)
            chan = 1;
        if (![partInfo isParPresent:MK_midiChan])
            chan = 1;
        else
            chan = [partInfo parAsInt:MK_midiChan];
        // don't connect the sampler parts to MIDI, they need to be connected to the MKSamplerInstrument
        if(keymap != nil && [self convertPartToSamples: aPart]) {
            // NSLog([aPart description]);
            [aNoteSender connect:[sampleInstrument noteReceiver]];
        }
        else
            [aNoteSender connect:[theMidiInstrument channelNoteReceiver: chan]];
    }
}

- (void) startPlaying
{
    MKMsgStruct *endRequest;
    MKScore *outputScore = [MKScore score];
    NSArray *instruments = [[NSArray arrayWithObject: [NSNumber numberWithUnsignedInt: 0x01]] retain];

    [MKScore setMidifilesEvaluateTempo: NO]; // this ensures timing values are not modified during reading.
    if([outputScore readMidifile: midiPathName] == nil) {
        NSLog(@"Couldn\'t read MIDI file %@\n", midiPathName);
	return;
    }
    currentTempo = [[outputScore infoNote] parAsDouble: MK_tempo];
    NSLog(@"Current tempo %lf\n", currentTempo);
    [tempoSlider setDoubleValue: currentTempo];

    [aScorePerformer setScore: outputScore];
    [self connectPartsToChannels: aScorePerformer forInstrument: midiInstrument];

    [aScorePerformer activate];
    // [samplePartPerformer activate]; // don't play the samplePart just now.

    [MKConductor setDeltaT: 0.5];            // Run (MKConductor) at least half a second ahead of DSP
    [MKConductor setClocked: YES];           // The conductor needs to be clocked when using MIDI.
    [[MKConductor defaultConductor] setTempo: currentTempo];    // we could also retrieve this from the file.

    NSLog(@"playing %@...\n", midiPathName);

    endRequest = [MKConductor afterPerformanceSel:@selector(haveFinishedPlaying) to: self argCount: 0];
    [MKConductor useSeparateThread: YES];
    [midiInstrument openOutputOnly];         /* No need for MKMidi input. */
    [midiInstrument downloadDLS: instruments];
    [midiInstrument run];                    /* This starts the device driver clock. */
    [MKConductor startPerformance];  /* Start sending Notes, loops until done. */

NSLog(@"Completed startPerformance\n");
    /* 
    MKConductor's startPerformance method does not return until the performance is over.
    Note, however, that if the Conductor is in a different mode, startPerformance returns
    immediately (if it is in clocked mode or if you have specified that the performance is
    to occur in a separate thread).  See the MKConductor documentation for details.
    In this case we will return immediately.
    */
    [pauseButton setState: NSOffState];
    [pauseButton setEnabled: YES];
}

- (void) stopPlaying
{
    [MKConductor lockPerformance];
    [midiInstrument allNotesOff];
    [midiInstrument stop];  // abort will actually close the device, whereas stop just stops it
    [sampleInstrument stop];         // this doesn't seem right to have to stop each instrument separately,
                                    // this should be the job of the Conductor.
    [MKConductor unlockPerformance]; // should unlock the performance before trying to finish it.
    [MKConductor finishPerformance];

    [pauseButton setState: NSOffState];
    [pauseButton setEnabled: NO];    // we disable the pause button here.
    NSLog(@"finished\n");
}

// read a midifile and and play it.
- (void) transport: (id) sender
{
    playButton = sender;  // save the button that was pushed so we can reset when playing has finished.
    [playButton retain];

    if([sender state] == NSOnState) {
        [self startPlaying];
    }
    else {
        [self stopPlaying];
    }
}

// pause or resume a currently playing sequence.
- (void) pause: (id) sender
{
    if([MKConductor isPaused]) { // resume
        NSLog(@"...resuming play\n");
        [MKConductor lockPerformance];
        [MKConductor resumePerformance];
        [MKConductor unlockPerformance];
    }
    else {  // pause
        NSLog(@"...pausing play\n");
        [MKConductor lockPerformance];
        [midiInstrument allNotesOff];
        [MKConductor pausePerformance];
        [MKConductor unlockPerformance];
    }
}

- (void) haveFinishedPlaying
{
    NSLog(@"...finished\n");
    [playButton setState: NSOffState];
    [pauseButton setEnabled: NO];    // we disable the pause button until we begin playing again.
}

- (void) applicationWillTerminate: (NSNotification *) aNotification 
{
    [midiInstrument close];
    //[sampleInstrument close];
}

- (void) setMIDIFilename: (id) sender
{
    int result;
    NSArray *fileTypes = [NSArray arrayWithObjects:@"midi", @"", nil];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];

    [oPanel setAllowsMultipleSelection:NO];
    result = [oPanel runModalForDirectory:midiPathName file:nil types:fileTypes];
    if (result == NSOKButton) {
        NSArray *filesToOpen = [oPanel filenames];
        int i, count = [filesToOpen count];
        for (i=0; i<count; i++) {
            midiPathName = [filesToOpen objectAtIndex:i];
            [midiPathNameTextBox setStringValue: midiPathName];
            [playButton setEnabled: YES];
        }
    }   
}

// Rather than just loading and playing a file, we read in a plist of a keymap allowing us to overide
// MIDI channels and keys with sample files.
- (void) setKeymapFilename: (id) sender
{
    int result;
    NSArray *fileTypes = [NSArray arrayWithObject:@"plist"];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];

    [oPanel setAllowsMultipleSelection:NO];
    result = [oPanel runModalForDirectory:keymapPathName file:nil types:fileTypes];
    if (result == NSOKButton) {
        NSArray *filesToOpen = [oPanel filenames];
        int i, count = [filesToOpen count];
        for (i=0; i<count; i++) {
            keymapPathName = [filesToOpen objectAtIndex:i];
            keymap = [NSDictionary dictionaryWithContentsOfFile: keymapPathName];
            if(keymap == nil) {
                NSLog(@"Couldn't load keymap file %@.\n", keymapPathName);
                return;
            }
            [keymapPathNameTextBox setStringValue: keymapPathName];
            [keymap retain];
            samplesIndexedByTag = [[NSMutableDictionary dictionary] retain];
        }
    }   
}

//@implementation MIDIFileController(ConductorDelegate)
- conductorWillSeek:sender
{
    return self;
}

- conductorDidSeek:sender
{
    return self;
}

- conductorDidReverse:sender
{
    return self;
}

- conductorDidPause:sender
{
    [midiInstrument allNotesOff];
    return self;
}

- conductorDidResume:sender
{
    return self;
}

@end
