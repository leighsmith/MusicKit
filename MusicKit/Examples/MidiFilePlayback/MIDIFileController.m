/* $Id$
 * This is a demonstration of MIDI playback from a Standard MIDI file together with sample file playback.
 * A mapping of MIDI channel and keynumber to specific sound files (a keymap plist file) is used to nominate
 * samples to play.
 * created by leigh on Tue 04-May-1999
 */

#import <AppKit/AppKit.h>
#import "MIDIFileController.h"

@implementation MIDIFileController

#ifdef WIN32
#define SAMPLE_LOC @"/Windows/Library/Lobe/Samples/"
#else
#define SAMPLE_LOC @"/Local/Users/leigh/Library/Lobe/Samples/"
#endif
#define KEYMAPFORMAT @"chan:%d key:%d"
#define SOUNDFILEEXT @"wav"

// Needs to be done before the nib displays.
- (void) applicationDidFinishLaunching:(NSNotification *) aNotification 
{
    [driverPopup removeAllItems];
    [driverPopup addItemsWithTitles: [MKMidi getDriverNames]];
    [driverPopup selectItemWithTitle: [midiInstrument driverName]];
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

    // rather than just loading and playing a file, we read in a plist of a keymap allowing us to overide
    // MIDI channels and keys with sample files.
    keymap = [NSDictionary dictionaryWithContentsOfFile: [SAMPLE_LOC stringByAppendingString: @"keymap.plist"]];
    if(keymap == nil) {
        NSLog(@"Couldn't load keymap file\n");
        return nil;
    }
    [keymap retain];
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
//   NSLog(@"Testing  %@\n", chanAndKeyNum);
  // NSLog([aNote description]);
   if(filename != nil) {
       soundPathName = [[SAMPLE_LOC stringByAppendingPathComponent: filename] stringByAppendingPathExtension: SOUNDFILEEXT];
       NSLog(@"Assigning %@ to %@\n", soundPathName, chanAndKeyNum);
       [aNote setPar:MK_filename toString: soundPathName];
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
    NSMutableArray *allNoteSenders;
    MKNote *partInfo = nil;
    MKNoteSender *aNoteSender;
    MKPart *aPart;

    allNoteSenders = [theScorePerformer noteSenders];
    partCount = [allNoteSenders count];
    for (i = 0; i < partCount; i++) {
        /* Connect each part to MKMidi based on its midiChan parameter */
        aNoteSender = [allNoteSenders objectAtIndex: i];
        aPart = [[aNoteSender owner] part];
        partInfo = [aPart infoNote];
        /* Look in the partInfo for a midi channel. Default to 1. */
        if (!partInfo)
            chan = 1;
        if (![partInfo isParPresent:MK_midiChan])
            chan = 1;
        else
            chan = [partInfo parAsInt:MK_midiChan];
        // don't connect the sampler parts to MIDI, they need to be connected to the MKSamplerInstrument
        if([self convertPartToSamples: aPart]) {
//	    NSLog([aPart description]);
            [aNoteSender connect:[sampleInstrument noteReceiver]];
        }
        else
            [aNoteSender connect:[theMidiInstrument channelNoteReceiver: chan]];
    }
}

// Generate another long sound to play over the top while the beats sound.
// This has its own part (as it will be performed by a different instrument).
- (MKPart *) generateDroneOfDuration: (double) duration
{
   MKPart *dronePart = [[MKPart alloc] init];
   MKNote *aNote;

   aNote = [[MKNote alloc] initWithTimeTag:1.333]; // 8.333 seconds corresponds to tick 4000 in the file.
   [aNote setNoteType:MK_noteDur];
   [aNote setNoteTag: MKNoteTag()];
   [aNote setDur: duration];  // at least as long as the drums sound and then 3 seconds more
   [aNote setPar:MK_velocity toInt: 127];
   [aNote setPar:MK_keyNum toInt: 40]; // drone keyNum
   [aNote setPar:MK_filename toString: @"/Local/Users/leigh/Library/Lobe/Samples/Amanda/Amanda16.snd"];
   NSLog([aNote description]);
   [dronePart addNote:aNote];
   [aNote release];

   return [dronePart autorelease];
}

- (void) startPlaying
{
    MKMsgStruct *endRequest;
    MKScore *outputScore = [[MKScore alloc] init];
    MKPart *dronePart = [self generateDroneOfDuration: 3.0];
    NSArray *instruments = [[NSArray arrayWithObject: [NSNumber numberWithUnsignedInt: 0x01]] retain];

    [dronePart retain];
    [samplePartPerformer setPart: dronePart];

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
//    [samplePartPerformer activate]; // don't play the samplePart just now.

    [MKConductor setDeltaT: 0.5];            // Run (MKConductor) at least half a second ahead of DSP
    [MKConductor setClocked: YES];           // The conductor needs to be clocked when using MIDI.
    [(MKConductor *)[MKConductor defaultConductor] setTempo: currentTempo];    // we could also retrieve this from the file.

    NSLog(@"playing %@...\n", midiPathName);

//    MKSetTrace(MK_TRACECONDUCTOR);
    endRequest = [MKConductor afterPerformanceSel:@selector(haveFinishedPlaying) to: self argCount: 0];
    [MKConductor useSeparateThread: YES];
    [midiInstrument openOutputOnly];         /* No need for MKMidi input. */
    [midiInstrument downloadDLS: instruments];
    [midiInstrument run];                    /* This starts the device driver clock. */
    [MKConductor startPerformance];  /* Start sending Notes, loops until done. */

    /* MKConductor's startPerformance method
    does not return until the performance is over.  Note, however, that
    if the Conductor is in a different mode, startPerformance returns
    immediately (if it is in clocked mode or if you have specified that the
    performance is to occur in a separate thread).  See the Conductor
    documentation for details. In this case we will return immediately.
    */
}

- (void) stopPlaying
{
   NSLog(@"...stopping\n");
   NSLog(@"...locking\n");
   [MKConductor lockPerformance];
   NSLog(@"allNotesOff\n");
   [midiInstrument allNotesOff];
   NSLog(@"stop\n");
   [midiInstrument stop];  // abort will actually close the device, whereas stop just stops it
   NSLog(@"finishPerformance\n");
   [MKConductor unlockPerformance]; // should unlock the performance before trying to finish it.
   NSLog(@"unlockPerformance\n");
   [MKConductor finishPerformance];
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

- (void) haveFinishedPlaying
{
    NSLog(@"...finished\n");
    [playButton setState: NSOffState];
}

- (void) applicationWillTerminate: (NSNotification *) aNotification 
{
    [midiInstrument close];
    //[sampleInstrument close];
}

- (void) setMIDIFilename: (id) sender
{
    int result;
    NSArray *fileTypes = [NSArray arrayWithObject:@"midi"];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];

    [oPanel setAllowsMultipleSelection:NO];
    result = [oPanel runModalForDirectory:midiPathName file:nil types:fileTypes];
    if (result == NSOKButton) {
        NSArray *filesToOpen = [oPanel filenames];
        int i, count = [filesToOpen count];
        for (i=0; i<count; i++) {
            midiPathName = [filesToOpen objectAtIndex:i];
            [midiPathNameTextBox setStringValue: midiPathName];
        }
    }   
}

- (void) setSoundfileName: (id) sender
{
}

//@implementation MIDIFileController(ConductorDelegate)
- conductorWillSeek:sender
{
//    [MKConductor sendMsgToApplicationThreadSel:@selector(showConductorWillSeek) to:self argCount:0];
    return self;
}

- conductorDidSeek:sender
{
//    [MKConductor sendMsgToApplicationThreadSel:@selector(showConductorDidSeek) to:self argCount:0];
    return self;
}

- conductorDidReverse:sender
{
//    [MKConductor sendMsgToApplicationThreadSel:@selector(showConductorDidReverse) to:self argCount:0];
    return self;
}

- conductorDidPause:sender
{
//    [MKConductor sendMsgToApplicationThreadSel:@selector(showConductorDidPause) to:self argCount:0];
    [midiInstrument allNotesOff];
    return self;
}

- conductorDidResume:sender
{
//    [MKConductor sendMsgToApplicationThreadSel:@selector(showConductorDidResume) to:self argCount:0];
    return self;
}

@end
