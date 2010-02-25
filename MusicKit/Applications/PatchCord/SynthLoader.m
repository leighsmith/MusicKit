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
