/*!
  @class PatchCordController
  @author Leigh M. Smith
  @description
     The Controller for the application itself.
     Responsible for loading and initialising all the synthesiser objects from their bundles 
     and starting up and closing down the System Exclusive messaging. 
     Updates and handles the info and preferences panels.
 */

#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>

#define OPENUNTITLED    @"initialOpenUntitled"
#define ASKDELETEPATCH  @"askWhenDeletingPatch"

@interface PatchCordController : NSObject {
    IBOutlet NSPopUpButton *midiInputPopup;
    IBOutlet NSPopUpButton *midiOutputPopup;
    IBOutlet NSTextField *versionText;
}

- (IBAction) setDriverName: (id) sender;

/*!
  @brief We load all the MIDISysExSynth objects from the bundles that we can find here to
 enable MIDI sysex reception.
 
 Priority increases on each registration so we load unhandled first.
 MIDI reception of patches should only be enabled when a PatchBankDocument has been allocated.
 That means we should load the Nibs here and enable reception everytime we start up a PatchBankDocument.
 */
- (void) loadTheBundles;

@end

@interface PatchCordController(ApplicationDelegate)
/*!
 @brief Determine what Synth bundles we find and load up.
 */
- (void) applicationDidFinishLaunching: (NSNotification *) notification;
- (void) applicationDidBecomeActive: (NSNotification *) notification;
- (BOOL) applicationOpenUntitledFile: (NSApplication *) theApplication;
- (BOOL) applicationShouldTerminate: (id) sender;
@end

@interface PatchCordController(ServiceManager)
- (void) patchMessage: (NSPasteboard *) pasteboard
             userData: (NSString *) sortArgs
                error: (NSString **) errorMessage;
@end
