/* SynthLoader.h created by leigh on Tue 28-Jul-1998 */

#import <AppKit/AppKit.h>

@interface SynthLoader : NSObject {
}

/*!
  @brief We load all the MIDISysExSynth objects from the bundles that we can find here to
  enable MIDI sysex reception.

  Priority increases on each register so we load unhandled first.
  MIDI reception of patches should only be enabled when a BankController has been allocated.
  That means we should load the Nibs here and enable reception everytime we start up a BankController.
 */
- (void) loadTheBundles;

/*!
  @brief Determine what Synth bundles we find and load up.
 */
- (void) awakeFromNib;

@end

@interface SynthLoader(ApplicationDelegate)
- (void) applicationDidFinishLaunching: (NSNotification *) notification;
- (void) applicationDidBecomeActive: (NSNotification *) notification;
- (BOOL) applicationOpenUntitledFile: (NSApplication *) theApplication;
- (BOOL) applicationShouldTerminate: (id) sender;
@end

@interface SynthLoader(ServiceManager)
- (void) patchMessage: (NSPasteboard *) pasteboard
             userData: (NSString *) sortArgs 
                error: (NSString **) errorMessage;
@end
