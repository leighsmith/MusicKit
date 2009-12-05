//
//  $Id$
//  PatchCord
//
//  Created by Leigh Smith
//  Copyright 2001 The MusicKit Project. All rights reserved.
//

#import "Bank.h"
//#import <EOControl/EOControl.h>
#import "PreferencesManager.h"          // for preferences constants
#import "SysExReceiver.h"               // in order to be it's delegate

// Constant strings
NSString *BANK_TYPE = @"MIDI";
NSString *UNTITLED_PATCH = @"New Patch %03d";

@implementation Bank

static unsigned int patchCounter;

+ (void) initialize
{
    patchCounter = 0;		// we start from 0 as we return a preincrement.
}

// recturn a monotonically increasing identifier for new patches.
+ (unsigned int) bumpPatchCounter
{
    return ++patchCounter;
}

// Create ourselves our model (PatchBank) instance matching our controller instance (self)
- (id) init
{
    [super init];
    patchBank = [[PatchBank alloc] init];
    return self;
}

// -----------------------------------------------------------------------------
// returning the nib file name of the document
- (NSString *) windowNibName 
{
    return @"Bank";
}

// -----------------------------------------------------------------------------
// (Called after the windowController has loaded the document's window).
// Setup the controls, linking back the action methods from the outlets
- (void) windowControllerDidLoadNib: (NSWindowController *) aController 
{
    NSEnumerator *enumerator;
    Class synthClass;

    [super windowControllerDidLoadNib: aController];
    // the SynthDescription column is uneditable, so if it is double clicked, we bring up the patch.
    [patchTableView setDoubleAction: @selector(displayPatch:)];

    // should go here? or in awakeFromNib or IB? We do it here once we have some patches to display
    // Am I dreaming? is there a setSendToSynthButton called (if it exists when the nib is woken?) check Juno106 + G&M
    //    [patchTableView setDataSource: self];
    [sendToSynthButton setTarget: self];   // Make our button point back to the patch sender
    [sendToSynthButton setAction: @selector(sendToSynth:)];
    [deleteSynthButton setTarget: self];   // Make our button point back to the patch sender
    [deleteSynthButton setAction: @selector(deletePatch:)];

    // Determine the class of the bundle with a modal class selection from selectableSynths.
    // We get the list from SysExMessage using a class method as only those registered should be able
    // to be presented to the user as sources of a newPatch.
    // registeredSynths returns the class objects so we can make new ones.

    enumerator = [[SysExMessage registeredSynths] objectEnumerator];
    while ((synthClass = [enumerator nextObject])) {
        [synthList addItemWithTitle: [synthClass description]];
    }
    [SysExMessage enable];                 // Once we have a bank we can start accepting SysEx messages
    [[SysExMessage receiver] setDelegateBank: self];
    // TODO, when this bank becomes active (the key), it should assign itself the delegateBank for the SysExMessage receiver
}

// -----------------------------------------------------------------------------
// create and return document data (packaged as an NSData object) of a supported type, usually in preparation for writing that data to a file. 
- (NSData *) dataRepresentationOfType: (NSString *) aType {
    NSAssert([aType isEqualToString: BANK_TYPE], @"Unknown type");
    return [patchBank dataEncodingSMF];
}

// -----------------------------------------------------------------------------
// convert an NSData object containing document data of a certain type into the document's internal data structures and display that data in a document window; the NSData object usually results from the document reading a document file.
- (BOOL) loadDataRepresentation: (NSData *) data ofType: (NSString *) aType {
    NSAssert([aType isEqualToString: BANK_TYPE], @"Unknown type");
    patchBank = [[PatchBank alloc] initWithSMFData: data];
    return patchBank != nil;
}

// A window closing delegate method to send a close message to all the patches in the bank.
- (void) close
{
    NSEnumerator *enumerator = [patchBank objectEnumerator];
    id patchToClose;

    // close all patches in the bank.
    while ((patchToClose = [enumerator nextObject]) != nil) {
        [(MIDISysExSynth *) patchToClose close];
    }
    [super close];
}

// enable or disable the new patch menu items.
- (BOOL) validateMenuItem: (NSMenuItem *) aMenuItem
{
    BOOL selectedSynth = [patchTableView selectedRow] != -1;

    // enable creating a new patch once we have a bank.
    if ([[aMenuItem title] isEqualToString:@"New Patch"])
        return YES;
    // enable "get from synth" once we have a bank.
    if ([[aMenuItem title] isEqualToString:@"Get from Synth"]) {
    //        [getFromSynthButton setEnabled: selectedSynth];
        return [NSClassFromString([synthList titleOfSelectedItem]) canUploadPatches];
    }
    // enable "send to synth" when a synth is selected on the patchTableView
    if ([[aMenuItem title] isEqualToString:@"Send to Synth"]) {
//        [sendToSynthButton setEnabled: selectedSynth];
        return selectedSynth;
    }
    // enable "Delete Patch" when a synth is selected on the patchTableView
    if ([[aMenuItem title] isEqualToString:@"Delete Patch"]) {
//        [deleteSynthButton setEnabled: selectedSynth];
        return selectedSynth;
    }
    return [super validateMenuItem: aMenuItem];
}

// insert the synthesizer instance into the Bank TableView and the PatchBank model.
- (void) addPatch: (MIDISysExSynth *) synthToAdd
{
    [patchBank newPatch: synthToAdd];
    [self updateChangeCount: NSChangeDone];        // Indicate the bank has been modified.
    [patchBank sortSynths: [self sortOrder]];      // Put the patch in context
    [patchTableView tile];                    // Force update of record display
    // [patchTableView selectRow: [patchBank findPatchMatching: synthToAdd]];   // Highlight the patch we just created.
}

// A new patch is desired.
// Determine the currently selected synth from the pop up menu, then that objects
// newEmptyPatch method is called and the synth is added to the table and patchBank.
// So the behaviour we want is to present the list to the user to allow as many of the same or different synths to be bought up, that gives the user more control over the MIDI channel semantics, whereas a patch displayed because the user selected it on the synth sets the MIDI channel immediately.
- (void) newPatch: (id) sender
{
    Class synthClassUserSelected;

    synthClassUserSelected = NSClassFromString([synthList titleOfSelectedItem]);
    if(synthClassUserSelected == nil) {
        NSLog(@"Unable to find a class named %@\n", [synthList titleOfSelectedItem]);
        return;
    }

    // However, that would still mean we create two objects - which sometimes we will want (when the respondant instance is already showing and we click new patch). Could have two unhandled synths which we would like to work on (tuning their reception to particular MIDI channels (how? perhaps which ever one is the key window).
    currentSynth = [[synthClassUserSelected alloc] initWithEmptyPatch];
    if(currentSynth == nil) {                  // check we allocated something valid
        NSLog(@"Could not allocate\n");
        return;
    }

    // Ok, if the Synth is catching all messages, do we want to create a newPatch in the bank?
    // Probably not, although in the future, we may well allow archiving selected messages
    // received (shift selection to collect several together).
    if(![currentSynth catchesAllMessages]) {
        [currentSynth setBank: self];         // Let the synth know who its bank is.
        [currentSynth setPatchDescription: [NSString stringWithFormat: UNTITLED_PATCH, [Bank bumpPatchCounter]]];
        [sendToSynthButton setEnabled: YES];      // Now we have a patch we enable the button for sending to a synth
    }
}

// displays the inspector for the patch at the row just double clicked.
- (void) displayPatch: (id) sender
{
    id theSynthPatch;
    int rowIndex = [patchTableView selectedRow];

    // NSLog(@"Should be displaying the patch\n");
    if(rowIndex != -1) {
        // retrieve the patch from the bank using the row number
        theSynthPatch = [patchBank patchAtIndex: rowIndex];
	[theSynthPatch displayPatch];
    }
}

// This will be highlighted if the synth accepts patch uploads, effectively it will force a new patch to be created
// when the upload occurs.
- (void) getFromSynth: (id) sender
{
    Class synthClassUserSelected;

    NSLog(@"Getting from the synth\n");
    synthClassUserSelected = NSClassFromString([synthList titleOfSelectedItem]);
    if(synthClassUserSelected == nil) {
        NSLog(@"Unable to find a class named %@\n", [synthList titleOfSelectedItem]);
        return;
    }

    // Send the dump request to the synth, the uploaded patches will return to this bank via the delegate method
    // receiverDidAcceptPatches:
    // but to which MIDI channel? Howabout MIDI semantics of binding a channel to a synth until the user chooses otherwise. Also see what OMS does.
    [synthClassUserSelected requestPatchUpload];
}

// Should be highlighted when we have selected a valid synth to delete
// have an NSAlertPanel up verifying it unless we have a preference ASKDELETEPATCH to remove the enquiry
- (void) deletePatch: (id) sender
{
    id theSynthPatch;
    int rowIndex = [patchTableView selectedRow];

    NSLog(@"Deleting patch\n");
    if(rowIndex != -1) {
        // delete the patch from the bank using the row number
        theSynthPatch = [patchBank patchAtIndex: rowIndex];
	[(MIDISysExSynth *) theSynthPatch close];      // must close the patch window if it is open first.     
        [patchBank deletePatchAtIndex: rowIndex];
        [self updateChangeCount: NSChangeDone];        // Indicate the bank has been modified.
        [patchBank sortSynths: [self sortOrder]];      // Put the patch in context
        [patchTableView tile];                    // Force update of record display
    }
}

// Should be highlighted when we have selected a valid synth to download
- (void) sendToSynth: (id) sender
{
    id theSynthPatch;
    int rowIndex = [patchTableView selectedRow];

    NSLog(@"Sending to the synth\n");
    if(rowIndex != -1) {
        // retrieve the patch from the bank using the row number
        theSynthPatch = [patchBank patchAtIndex: rowIndex];
        // should we always bring up the inspector just because we download? No
        // [theSynthPatch displayPatch];
        [theSynthPatch sendPatch];
    }
}

@end

@implementation Bank(SysExReceiverDelegate)

// We have made this bank a delegate for SysExReceiver, so we can retrieve the list of
// synths that responded to the accept message
- (void) receiverDidAcceptPatches: (SysExReceiver *) patchReceiver
{
    NSEnumerator *enumerator = [[patchReceiver respondantSynths] objectEnumerator];
    id respondant;

    // add the new respondant patches (typically a single entry) into the bank view and model
    while ((respondant = [enumerator nextObject]) != nil) {
         [self addPatch: respondant];
    }
}

@end

// TODO check if there are no more windows, in which case [SysExMessage disable]
// figure out what to do once all banks are closed, should disable.
// Hmm maybe, we could just do the same as synthLoader and create an untitled Bank.

// Conform to the informal Table Data Source protocol as well as being the TableView's delegate
@implementation Bank(NSTableDataSource)

// Returns the number of patches within the bank.
- (int) numberOfRowsInTableView: (NSTableView *) aTableView
{
    return [patchBank count];
}

// Retrieve the field (description or synth name) indicated by aTableColumn for the numeric record rowIndex
- (id) tableView: (NSTableView *) aTableView
    objectValueForTableColumn: (NSTableColumn *) aTableColumn
    row: (int) rowIndex
{
    id thePatch;

    // retrieve the patch from the bank using the row number
    thePatch = [patchBank patchAtIndex: rowIndex];

    // check we got back something meaningful
    // get the patch description, MIDI channel and patchnumber, and the Synth class as NSStrings
    if([[aTableColumn identifier] isEqualToString: @"patchDescription"])
	return [thePatch patchDescription];
    else if([[aTableColumn identifier] isEqualToString: @"synthName"])
        return [thePatch synthName];
    else if([[aTableColumn identifier] isEqualToString: @"midiChannel"])
        return [NSNumber numberWithInt: [thePatch midiChannel]];
    else if([[aTableColumn identifier] isEqualToString: @"midiPatchNumber"])
        return [NSNumber numberWithInt: [thePatch midiPatchNumber]];
    else
	return nil;
}

- (void) tableView: (NSTableView *) aTableView
    setObjectValue: (id) anObject
    forTableColumn: (NSTableColumn *) aTableColumn
    row: (int) rowIndex
{
    id thePatch;

    // retrieve the patch from the bank using the row number
    thePatch = [patchBank patchAtIndex: rowIndex];

    // check we should modify something meaningful
    // Only the patch description should be set (as an NSString)
    if([[aTableColumn identifier] isEqualToString: @"patchDescription"])
	// this causes the current synth window title to update
        [thePatch setPatchDescription: anObject];
    else if([[aTableColumn identifier] isEqualToString: @"midiChannel"])
	// should check a valid MIDI channel
        [thePatch setMidiChannel: [anObject intValue]];
    else if([[aTableColumn identifier] isEqualToString: @"midiPatchNumber"])
	// should check in the range 0-127 a valid MIDI patch number,
        [thePatch setMidiPatchNumber: [anObject intValue]];

    [patchBank sortSynths: [self sortOrder]];
    [patchTableView tile];                 // force update of record display
}

@end

@implementation Bank(NSTableViewDelegate)

// Deny editing the Synth name
- (BOOL) tableView: (NSTableView *) aTableView
    shouldEditTableColumn: (NSTableColumn *) aTableColumn
    row: (int) rowIndex
{
    if([[aTableColumn identifier] isEqualToString: @"patchDescription"])
        return YES;
    else if([[aTableColumn identifier] isEqualToString: @"synthName"])
        return NO;
    else if([[aTableColumn identifier] isEqualToString: @"midiChannel"])
        return YES;
    else if([[aTableColumn identifier] isEqualToString: @"midiPatchNumber"])
        return YES;
    else
	return NO;
}

// Determine the sort order of the attributes of the patch from the Bank's NSTableView column order.
// The order is returned as an array of 
- (NSMutableArray *) sortOrder
{
    NSArray *columns;
    NSMutableArray *columnOrder;
    NSString *identifier;
    NSEnumerator *columnEnumerator;
    NSTableColumn *eachColumn;

    columns = [patchTableView tableColumns];
    columnOrder = [NSMutableArray array];
    columnEnumerator = [columns objectEnumerator];
    while (eachColumn = [columnEnumerator nextObject]) {
//        EOSortOrdering *tempOrder;

        identifier = [eachColumn identifier];
        NSLog(@"Column %@\n", identifier);

        // Create an NSArray of SortOrdering from the identifer names.
        // check we got back something meaningful
        // get the patch description, MIDI channel and patchnumber, and the Synth name as NSStrings

//        tempOrder = [EOSortOrdering sortOrderingWithKey: identifier selector: EOCompareAscending];
//        [columnOrder addObject: tempOrder];
    }
    return columnOrder;
}

// Use the column indexes to determine the keys ordering so that the table will resort itself.
// Eventually have a preference for auto sorting vs manual (using the corner button) depending 
// on size of database
- (void) tableViewColumnDidMove: (NSNotification *) notification
{
//    NSNumber *oldColumn = [[notification userInfo] objectForKey: @"NSOldColumn"];
//    NSNumber *newColumn = [[notification userInfo] objectForKey: @"NSNewColumn"];

//    NSLog(@"Moved %d to %d\n", [oldColumn intValue], [newColumn intValue]);
    [patchBank sortSynths: [self sortOrder]];
    [patchTableView tile];                 // force update of record display
}

// When a row in the table has been selected, we allow sending that patch to the synth or deleting it.
- (void) tableViewSelectionDidChange: (NSNotification *) notification
{
    [sendToSynthButton setEnabled: YES];  // actually I should check a patch has been selected.
    [deleteSynthButton setEnabled: YES];
}

@end
