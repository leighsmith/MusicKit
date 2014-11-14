/*
PatchBank - a managed collection of dissimilar synth subclass instances, containing synth data.

 * This should allow collecting and archiving various Synth instances in a single file, searching through by using the patch as a key into the PatchBankDocument archive.
 Banks - archiving objects
 Investigate bank files and the indexing kit, rather than a full
 database. This could be the case if we are storing in Ascii, which has
 advantages in being not architecture dependent

 Should the Juno object initiate the Database search (supplying the
 key?) rather than the sysex manager? Definately not the sysex manager.
 This implies the Juno object would need to update it's encapsulated
 patch (from a new patch or a parameter modification), download the
 current patch to the Juno (unless it just got the patch/parameter from
 there), signal the database search (which would ultimately update the
 patch name display if something was found) and perhaps update the
 front panel mimics (sliders etc).

 The trick is to determine what objects should do the display updates.
 The database search would only really ever retrieve data other than
 the patch (by definition, the patch is the database search key).
 However, when browsing patches, selected on some search criteria
 (search both name, category fields), selecting each patch should
 download the patch to the synth and update the display. However we may
 want the display to be updated without updating the synth or vice
 versa - However that is not a situation which would be wanted, as that
 introduces some asynch between possible display and sound - perhaps we
 shouldn't after all. The clearest behaviour should be to not tie the
 Juno object update to a display update and database update and MIDI
 update (unless that is considered good programming practice).

 You can create a sorted version of the array (sortedArrayUsingSelector: and sortedArrayUsingFunction:context:)
*/
 /*
 The following two informational methods consider the same problem, banks, delegates?
 Probably should start thinking about the bank interface in order to fully define the
 synth multiple patch handling methods. Think of it in terms of a general object storage device.
 PatchBankDocument - a managed collection of dissimilar synth subclass instances, containing synth data.
 */
// - (BOOL) canSendMultiplePatches

/*
It is feasible to have a synth which only works by downloading an entire bank, even though we are working on a single patch. In that case before anything can be changed a complete bank has to be assembled.
Controller may need to inform the user that a complete bank must be downloaded, where should the patch be placed.
*/
// - (BOOL) mustDownloadBank

#import <MusicKit/MusicKit.h>   // for the MIDI file I/O
#import "PatchBank.h"

@implementation PatchBank

// Initialise the bank instance. I guess we should be allocating NSMutableArray here (that it won't be allocated in alloc?
- init
{
    [super init];
    theBank = [[NSMutableArray alloc] init];
    return self;
}

// We should export the patch names and numbers for a particular device as a patch list to Sequence.app/patchlists and then run Sequence.app/patchlists/midi-convert to turn it into a patch list useful by Sequence. Will need to check the permissions for writing. The Name should be determined from the Class name of the Synth object.
// - generatePatchListsForSequence called from PatchBankDocument->Save To 
- generatePatchListsForSequence
{
     return self;
}

// 
- (void) encodeWithCoder: (NSCoder *) aCoder
{
//    encode the theBank
//    save the sort order, then each of the patches to a Standard MIDI file.
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
    return nil;
}

// Return the instance encoded as a Level 1 Standard MIDI file - platform independent and standard
// Each SysExSynth patch has a MIDI channel patch number associated with it, a MIDI channel and a patch description. 
// We use format 1 MIDI files:
//   text meta-event to list sort order of field identifiers
//   text meta-event to give the version of PatchCord (copyright?)
//   In the following order for each MIDI track:
//   FF 04 Instrument Name - patchDescription
//   FF 20 01 MIDI channel prefix
//   Patch change - patchChangeNumber
//   SysEx message #1 for this patch
//   1 second event delay
//   SysEx message #2 for this patch
//   text meta-event for any other non-standard data saving requirements.
- (NSData *) dataEncodingSMF
{
    NSMutableData *smf = [[NSMutableData alloc] init];
    NSEnumerator *enumerator = [theBank objectEnumerator];
    MIDISysExSynth *patch;
    MKScore *sysexScore = [[MKScore alloc] init];
    double absoluteTime = 0.0;     // what MIDI event time to write each patch out at so external MIDI players don't swamp synths.

    NSString *sortOrderString;
    NSString *versionString;
    MKPart *infoPart = [[MKPart alloc] init];
    MKNote *infoNote = [[MKNote alloc] initWithTimeTag: 0.0]; // An Info note for the Copyright/Version, sort order stuff
    MKNote *sortOrderNote = [[MKNote alloc] initWithTimeTag: 1.0]; // An Info note for the sort order

    // We use format 1 MIDI files by default.

    // Create an info part 
    // text meta-event to give the version of PatchCord (copyright?)
    // MK_copyright
// [infoPanelController versionDescription] probably should be application, not the infoPanelController
    NSLog(@"Copyright/Version\n");
    versionString = [NSString stringWithFormat: @"PatchCordVersion: %@", @"V0.1"];
    [infoNote setPar: MK_text toString: versionString];
    [infoPart addNote: infoNote];

// MK_title toString: @"PatchCord patch dump %@" [NSDate
//    NSDateFormatter *dateFormat = [[NSDateFormatter alloc]
//        initWithDateFormat:@"%b %d %Y" allowNaturalLanguage:NO];
// NSCalendarDate

// [titleNote setPar: MK_text toString: versionString];
// only one MK_text parameter per info note?

    // text meta-event to list sort order of field identifiers
    sortOrderString = [NSString stringWithFormat: @"PatchCordSortOrder: %@", sortOrder];
    [sortOrderNote setPar: MK_text toString: sortOrderString];
    [infoPart addNote: sortOrderNote];
    NSLog(@"%@", sortOrderString);

    // [sysexScore setInfo: infoNote];
    [sysexScore addPart: infoPart];

    // write each patch one per MIDI file track.
    while ((patch = [enumerator nextObject]) != nil) {
	MKPart *messagePart = [[MKPart alloc] init];
        NSString *descriptionString;
	MKNote *descriptionNote = [[MKNote alloc] initWithTimeTag: 0.0];
        MKNote *chanPrefixNote  = [[MKNote alloc] initWithTimeTag: 0.0];
        MKNote *patchChangeNote = [[MKNote alloc] init];
        MKNote *messageNote;

        // NSLog(@"New MIDI track\n");
        
        // FF 04 Instrument Name - patchDescription
        descriptionString = [NSString stringWithFormat: @"%@", [patch patchDescription]];
        [descriptionNote setPar: MK_instrumentName toString: descriptionString];
        [messagePart addNote: descriptionNote];
        // NSLog(descriptionString);

        // FF 20 01 MIDI channel prefix
        [chanPrefixNote setPar: MK_midiChan toInt: [patch midiChannel]];
	[messagePart addNote: chanPrefixNote];
        // NSLog(@"MIDI channel %d\n", [patch midiChannel]);

        // Patch change
        [patchChangeNote setPar: MK_programChange toInt: [patch midiPatchNumber]];
        [patchChangeNote setTimeTag: absoluteTime];
        [messagePart addNote: patchChangeNote];
        // NSLog(@"at %ld, change to patch %d\n", absoluteTime, [patch midiPatchNumber]);

        // TODO this willl become a preference
	absoluteTime += 500.0; // patch change 0.5 a second before sending the sysex message.

	// should just be able to ask SysExMessage to give us a note
        // SysEx message #1 for this patch
#if 1
        messageNote = [[patch sysEx] note];
        [messageNote setTimeTag: absoluteTime];
#else
        messageNote = [[MKNote alloc] initWithTimeTag: absoluteTime];
        [messageNote setPar: MK_sysExclusive toString: [[patch sysEx] exportToAscii: musicKitSysExSyntax]];
#endif
        [messagePart addNote: messageNote];
        // NSLog(@"at %ld,%@\n", absoluteTime, [patch sysEx]);

        [sysexScore addPart: messagePart];

        // 1 second event delay
        // TODO this will become a preference
	absoluteTime += 1000.0;
        // Any further SysEx messages for this patch
        // text meta-event for any other non-standard data saving requirements.

	// TODO release all that we've created for next time.
    }
    // [sysexScore writeMidiFileToData - preferable for Object persisitance
    // just use the stream named methods for now until we can rename them properly.
    [sysexScore writeMidifileStream: smf];

//    return [smf autorelease];
    return [smf copy];
}

// initialise the instance from a Level 1 Standard MIDI file, encoded as described above by dataEncodingSMF.
// We read the midifile stream into an MKScore then extract what we can from that.
- (id) initWithSMFData: (NSData *) smf
{
    MKScore *sysexScore = [[MKScore alloc] init];
    MKPart *nextPart;
    NSMutableArray *allParts;
    NSArray *notesPerPart;
    MKNote *messageNote;
    SysExMessage *newMessage;
    int partIndex;
    int noteIndex;
    // NSMutableArray *newSortOrder;

    [sysexScore readMidifileStream: [NSMutableData dataWithData: smf]];

    // loop through the parts (we make no assumption of the order of the "info part").
    allParts = [sysexScore parts];
    for(partIndex = 0; partIndex < [allParts count]; partIndex++) {
        NSLog(@"Reading part %d\n", partIndex);
        nextPart = [allParts objectAtIndex: partIndex]; // get each part
        notesPerPart = [nextPart notes];         // and each of its notes   
        for(noteIndex = 0; noteIndex < [notesPerPart count]; noteIndex++) {
	    messageNote = [notesPerPart objectAtIndex: noteIndex];
            // check the parameter for each note.
		// do a switch on parameters?
            // if a sysex then import it into a SysExMessage and add the new message to the patch bank
            if([messageNote isParPresent: MK_sysExclusive]) {
                newMessage = [[SysExMessage alloc] initWithNote: messageNote];
		[self newPatch: newMessage];
	    }
	}

    }
   // [self sortSynths: (NSMutableArray *) newSortOrder];

    return self; // probably should return a new instance??
}

- (int) count
{
    return [theBank count];
}

- (id) patchAtIndex: (int) index
{
    return [theBank objectAtIndex: index];
}

- (void) deletePatchAtIndex: (int) index
{
    [theBank removeObjectAtIndex: index];
}

// If the patch already has been inserted into the bank we don't reinclude.
- (void) newPatch: (id) patch
{
    NSUInteger previousLocation;

    [patch retain];
    previousLocation = [theBank indexOfObjectIdenticalTo: patch];
    if(previousLocation == NSNotFound)
        [theBank addObject: patch];
    else
        [theBank replaceObjectAtIndex: previousLocation withObject: patch];
}

// sort the elements according to the order of the keys supplied by newSortOrder
- (void) sortSynths: (NSMutableArray *) newSortOrder
{
// [NSArray arrayWithArray: theBank]

    NSMutableArray *sorted = [theBank sortedArrayUsingKeyOrderArray: newSortOrder];
    [sortOrder release];
    sortOrder = [newSortOrder retain];  // keep a copy of the sort order to write out to the MIDI file.
    [theBank release];     // release the old one
    // TODO should this be a copy operation?
    theBank = [sorted retain];  // keep the new one
}

// return an enumeration of the MIDISysExSynth objects
- (NSEnumerator *) objectEnumerator
{
    return [theBank objectEnumerator];
}

@end
