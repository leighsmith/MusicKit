// Bank.h - interface for a column based display of the patches

#import <AppKit/AppKit.h>
#import "MIDISysExSynth.h"
#import "PatchBank.h"
#import "SysExReceiver.h"

extern NSString *UNTITLED_BANK;
extern NSString *BANK_FILE_EXTENSION;
extern NSString *APP_NAME;
extern NSString *UNTITLED_PATCH;


@interface Bank : NSDocument {
    PatchBank *patchBank;	     // Holds a collection of MIDISysExSynth objects
    MIDISysExSynth *currentSynth;    // Synth loaded by the nib file
    id synthList;                    // points to the pop-up list on the panel.
    id programNumList;		     // the pop-up list of the patch number to upload from
    id patchTableView;               // Points to our NSTableView showing all the patches
    id patchIconButton;              // where to display the current patch's synth icon
    id sendToSynthButton;            // allows enabling/disabling the button to send to the synth
    id deleteSynthButton;            // allows enabling/disabling the button to delete the selected synth
}

// Overridden methods
- (NSString *) windowNibName;
- (void) windowControllerDidLoadNib: (NSWindowController *) aController;
- (NSData *) dataRepresentationOfType: (NSString *) aType;
- (BOOL) loadDataRepresentation: (NSData *) data ofType: (NSString *) aType;
- (BOOL) validateMenuItem: (NSMenuItem *) aMenuItem;
- (void) close;

- (id) init;
- (void) addPatch: (MIDISysExSynth *) synthToAdd;
- (void) newPatch: (id) sender;
- (void) sendToSynth: (id) sender;
- (void) getFromSynth: (id) sender;
- (void) displayPatch: (id) sender;
- (void) deletePatch: (id) sender;
@end

@interface Bank(SysExReceiverDelegate)
- (void) receiverDidAcceptPatches: (SysExReceiver *) patchReceiver;
@end

@interface Bank(NSTableDataSource)
- (int) numberOfRowsInTableView: (NSTableView *) aTableView;
- (id) tableView: (NSTableView *) aTableView
    objectValueForTableColumn: (NSTableColumn *) aTableColumn
    row: (int) rowIndex;
- (void) tableView: (NSTableView *) aTableView
    setObjectValue: (id) anObject
    forTableColumn: (NSTableColumn *) aTableColumn
    row: (int) rowIndex;
@end

@interface Bank(NSTableViewDelegate)
- (BOOL) tableView: (NSTableView *) aTableView
    shouldEditTableColumn: (NSTableColumn *) aTableColumn
    row: (int) rowIndex;
- (NSMutableArray *) sortOrder;
- (void) tableViewColumnDidMove: (NSNotification *) notification;
- (void) tableViewSelectionDidChange: (NSNotification *) notification;
@end

