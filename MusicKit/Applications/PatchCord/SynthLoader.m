/*
 * SynthLoader.m created by leigh on Tue 28-Jul-1998
 * Responsible for initialising all the synthesiser objects from their bundles and starting up and closing down the
 * System Exclusive messaging.
 */
#import "SysExMessage.h"	// to be able to open the SysEx interface.
#import "SynthLoader.h"
#import "UnhandledSynth.h"           // to be able to load Unhandled
#import "PreferencesManager.h"       // to get untitled open preference

#import "Juno106.subproj/Juno106.h"             // kludge until bundle loading is working.
#import "Quadraverb.subproj/QuadraverbGT.h"             // kludge until bundle loading is working.
#import "AxonNGC77.subproj/AxonNGC77.h"             // kludge until bundle loading is working.
#import "ProphetVS.subproj/ProphetVS.h"             // kludge until bundle loading is working.


@implementation SynthLoader

// We load all the MIDISysExSynth objects from the bundles that we can find here to enable MIDI sysex reception. Priority increases
// on each register so we load unhandled first.
// MIDI reception of patches should only be enabled when a BankController has been
// allocated. That means we should load the Nibs here and enable reception everytime we start up a
// BankController.
- (void) loadTheBundles
{
   MIDISysExSynth *respondantSynth1;

   // We should always load unhandled.
   // We load it first to ensure it has lowest priority registering as the default handler.
   respondantSynth1 = [[UnhandledSynth alloc] init];
      // Should extract out the name, the icon to create ourselves an array of tiles

   // Load our bundles for those synths found
   // for now we kludge, eventually we should search and find them in Library/PatchCord

   // For now just load the ones we need
   [[Juno106 alloc] init];
   [[QuadraverbGT alloc] init];
   [[ProphetVS alloc] init];
   [[AxonNGC77 alloc] init];
}

// Determine what Synth bundles we find and load up.
- (void) awakeFromNib
{
    [NSApp setServicesProvider: self];
    [SysExMessage open];     // Start MIDI things up
    [self loadTheBundles];
}

@end

@implementation SynthLoader(ApplicationDelegate)

- (void) applicationDidFinishLaunching: (NSNotification *) notification
{
    // NSApplication *theApplication = [notification object];
}

- (void) applicationDidBecomeActive: (NSNotification *) notification
{
}

// Check the default openInitialUntitledFile to open the untitled window automatically
- (BOOL) applicationOpenUntitledFile: (NSApplication *) theApplication
{
    NSUserDefaults *patchcordDefaults = [NSUserDefaults standardUserDefaults];

    if([patchcordDefaults objectForKey: OPENUNTITLED] == nil)
        [patchcordDefaults setBool: YES forKey: OPENUNTITLED];
    return ![patchcordDefaults boolForKey: OPENUNTITLED];
}

// Write file and end performance.
- (BOOL) applicationShouldTerminate: (id) sender
{
    [SysExMessage close];	// close the System Exclusive stuff down
    return YES;
}

@end

@implementation SynthLoader(ServiceManager)

// Currently handle ascii strings as SysEx messages only.
- (void) patchMessage: (NSPasteboard *) pasteboard
             userData: (NSString *) sortArgs
                error: (NSString **) errorMessage
{
    NSArray *ptypes  = [pasteboard types];
    NSString  *pboardString;
    SysExMessage *newsysex;
    NSDocumentController *dc;

    // Look for NSString first...
    if (![ptypes containsObject: NSStringPboardType]) {
        *errorMessage = NSLocalizedString(@"Error: couldn't use text for SysEx message.",
              @"pboard couldn't give string.");
        return;
    }

    pboardString = [pasteboard stringForType: NSStringPboardType];  // can we return a NSString?
    if (pboardString == nil) {
        *errorMessage = NSLocalizedString(@"Error: couldn't use text for SysEx message.",
                  @"pboard couldn't give string.");
        return;
    }

    // create a new bank if there is not already one opened by the DocumentController
    dc = [NSDocumentController sharedDocumentController];
    if([[dc documents] count] == 0) {
       [dc openUntitledDocumentOfType: @"MIDI" display: YES];
    }

    // now create a sysex message and send it to the receiver to have it interpreted.
    newsysex = [[SysExMessage alloc] init];
    [newsysex initWithString: pboardString];
    [newsysex receive];
}

@end
