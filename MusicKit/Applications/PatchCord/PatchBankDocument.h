/*!
  @class PatchBankDocument
  @author Leigh M. Smith
  @description
    Responsible for controlling (managing) each PatchBank object (model) and it's view
    by loading the nib via the NSDocument functionality.
*/

#import <AppKit/AppKit.h>
#import "MIDISysExSynth.h"
#import "PatchBank.h"
#import "SysExReceiver.h"

extern NSString *UNTITLED_BANK;
extern NSString *BANK_FILE_EXTENSION;
extern NSString *APP_NAME;
extern NSString *UNTITLED_PATCH;

@interface PatchBankDocument : NSDocument {
    PatchBank *patchBank;	                  // Holds a collection of MIDISysExSynth objects
    MIDISysExSynth *currentSynth;                 // Synth loaded by the nib file
    IBOutlet NSPopUpButton *synthList;            // points to the pop-up list on the panel.
    IBOutlet NSPopUpButton *programNumList;	  // the pop-up list of the patch number to upload from
    IBOutlet NSTableView *patchTableView;         // Points to our NSTableView showing all the patches
    IBOutlet NSButton *patchIconButton;           // where to display the current patch's synth icon
    IBOutlet NSButton *sendToSynthButton;         // allows enabling/disabling the button to send to the synth
    IBOutlet NSButton *deleteSynthButton;         // allows enabling/disabling the button to delete the selected synth
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

@interface PatchBankDocument(SysExReceiverDelegate)
- (void) receiverDidAcceptPatches: (SysExReceiver *) patchReceiver;
@end

@interface PatchBankDocument(NSTableDataSource)
- (int) numberOfRowsInTableView: (NSTableView *) aTableView;
- (id) tableView: (NSTableView *) aTableView
objectValueForTableColumn: (NSTableColumn *) aTableColumn
             row: (int) rowIndex;
- (void) tableView: (NSTableView *) aTableView
    setObjectValue: (id) anObject
    forTableColumn: (NSTableColumn *) aTableColumn
    row: (int) rowIndex;
@end

@interface PatchBankDocument(NSTableViewDelegate)
- (BOOL) tableView: (NSTableView *) aTableView
shouldEditTableColumn: (NSTableColumn *) aTableColumn
               row: (int) rowIndex;
- (NSMutableArray *) sortOrder;
- (void) tableViewColumnDidMove: (NSNotification *) notification;
- (void) tableViewSelectionDidChange: (NSNotification *) notification;
@end

