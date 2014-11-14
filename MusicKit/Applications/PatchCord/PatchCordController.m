/*
 * PatchCordController
 */
#import "PatchCordController.h"
#import "SysExMessage.h"                // to be able to open the SysEx interface.

#import "UnhandledSynth.h"              // to be able to load Unhandled
#import "Juno106.subproj/Juno106.h"             // kludge until bundle loading is working.
#import "Quadraverb.subproj/QuadraverbGT.h"     // kludge until bundle loading is working.
#import "AxonNGC77.subproj/AxonNGC77.h"         // kludge until bundle loading is working.
#import "ProphetVS.subproj/ProphetVS.h"         // kludge until bundle loading is working.


@implementation PatchCordController

// extract the version number from the NIB, perhaps we should be setting this via SVN and changing the Nib programmatically?
- (NSString *) versionDescription
{
   return @"Version 2.1";
}

- (IBAction) setDriverName: (id) sender
{
    // assign the selected driver to SysExMessage
    [SysExMessage openOnDevice: [sender titleOfSelectedItem] forInput: [sender tag] == 0];
    // NSLog(@"Selected tag %ld: %@", (long) [sender tag], [SysExMessage driverName]);
}

// use SysExMessage drivers to initialise.
- (void) initMIDIDriverPreferences
{
    [midiInputPopup removeAllItems];
    [midiInputPopup addItemsWithTitles: [MKMidi getDriverNamesForInput]];
    [midiInputPopup selectItemWithTitle: [[SysExMessage midiDeviceForInput: YES] driverName]];
    [midiOutputPopup removeAllItems];
    [midiOutputPopup addItemsWithTitles: [MKMidi getDriverNamesForOutput]];
    [midiOutputPopup selectItemWithTitle: [[SysExMessage midiDeviceForInput: NO] driverName]];
}

- (void) loadTheBundles
{
    // TODO check NSUserDefault if we should load unhandled. If not loaded, we should just ignore unhandled SysEx.
    // if ([[NSUserDefaults standardUserDefaults] boolForKey: ShouldRespondToUnhandledSynths])
    {
	MIDISysExSynth *respondantSynth1;
        
	// We load it first to ensure it has lowest priority registering as the default handler.
	respondantSynth1 = [[UnhandledSynth alloc] init];
    }
    
    // Load our bundles for those synths found.
    // search and find bundles for synths inside the main app, ~/Library/PatchCord, /Library/PatchCord etc.
    // NSString *libraryPaths = @"~/Library";
    // NSString *synthBundlesDirectory = [libraryPaths stringByAppendingPathComponent: @"SysExSynths"];
    // NSLog(@"synthBundlesDirectory %@\n", synthBundlesDirectory);
    // NSArray *synthBundlePaths = [NSBundle pathsForResourcesOfType: nil inDirectory: synthBundlesDirectory];
    NSArray *synthBundlePaths = [[NSBundle mainBundle] pathsForResourcesOfType: nil inDirectory: @"SysExSynths"];
    unsigned int pathIndex;
    
    // Should extract out the name, the icon to create ourselves an array of tiles
    for(pathIndex = 0; pathIndex < [synthBundlePaths count]; pathIndex++) {
	NSString *bundlePath = [synthBundlePaths objectAtIndex: pathIndex];
	NSBundle *synthBundle = [NSBundle bundleWithPath: bundlePath];
	
	// allocate and initialise the synth object in each bundle.
	// [synthBundle load];
	Class synthClass = [synthBundle principalClass];
	
	if(synthClass != nil) {
	    id synthInstance = [[synthClass alloc] init];
	    NSLog(@"synthInstance %@\n", synthInstance);
	}
    }
    
    // TODO For now just load the ones we need
    //[[Juno106 alloc] init];
    //[[ProphetVS alloc] init];
    [[QuadraverbGT alloc] init];
    [[AxonNGC77 alloc] init];
}

@end

@implementation PatchCordController(ApplicationDelegate)

- (void) applicationDidFinishLaunching: (NSNotification *) notification
{
    // NSApplication *theApplication = [notification object];
    [NSApp setServicesProvider: self];
    [SysExMessage open];     // Start MIDI things up
    [self initMIDIDriverPreferences]; // use SysExMessage MIDI drivers to initialise.
    [self loadTheBundles];
    [versionText setStringValue: [self versionDescription]];
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
    NSLog(@"initial untitled %d", [patchcordDefaults boolForKey: OPENUNTITLED]);
    return [patchcordDefaults boolForKey: OPENUNTITLED];
}

// Write file and end performance.
- (BOOL) applicationShouldTerminate: (id) sender
{
    [SysExMessage close];	// close the System Exclusive stuff down
    return YES;
}

@end

@implementation PatchCordController(ServiceManager)

// Currently handle ASCII strings as SysEx messages only.
- (void) patchMessage: (NSPasteboard *) pasteboard
             userData: (NSString *) sortArgs
                error: (NSString **) errorMessage
{
    NSArray *ptypes = [pasteboard types];
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
	NSError *outError;
	
	[dc openUntitledDocumentAndDisplay: YES error: &outError];
    }
    
    // now create a sysex message and send it to the receiver to have it interpreted.
    newsysex = [[SysExMessage alloc] init];
    [newsysex initWithString: pboardString];
    [newsysex receive];
}


@end
