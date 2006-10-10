/*	$Id$
*	Originally from SoundEditor3.0.
*	Modified for Spectro3 by Gary Scavone.
*	Last modified: 4/94
*/

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

#import "SoundController.h"
#import "SaveToController.h"
#import "SoundDocument.h"

NSString *colorToString(NSColor *color)
{
    float r, g, b;
    NSString *ret;
    [[color colorUsingColorSpaceName: NSCalibratedRGBColorSpace] getRed: &r green: &g blue: &b alpha: NULL];
    ret = [[NSString stringWithFormat:@"%f:%f:%f:",r,g,b] retain];
    return ret;
}

NSColor *StringToColor(NSString *buffer)
{
    float r, g, b;
    const char *buf = [buffer cString];
    sscanf(buf, "%f:%f:%f", &r, &g, &b);
    return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
}

@implementation SoundController

- init
{
    self = [super init];
    if(self != nil) {
	counter = 0;	
    }
    return self;
}

+ (void) initialize
{
    NSMutableDictionary *SpectroDefaults = [[NSDictionary dictionaryWithObjectsAndKeys:
	@"1024",	@"WindowSize",
	@"2.0",		@"ZPFactor",
	@"0.5",		@"HopRatio",
	@"Hanning",	@"WindowType",
	@"10000",	@"SpectrumMaxFreq",
	@"-100",	@"dBLimit",
	@"5000",	@"WFMaxFreq",
	@"3.0",		@"WFPlotHeight",
	@"0",		@"DisplayType",
	@"0:0:0",	@"SpectrumColor",
	@"1:0:0",	@"CursorColor",
	@"0.3333:0.3333:0.3333", @"WaterfallColor",
	@"0.6666:0.6666:0.6666", @"GridColor",
	NULL, NULL] retain];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:SpectroDefaults];
    
}

#if 0

// TODO set the file types for the document from Snd -soundFileExtensions
// <key>CFBundleDocumentTypes</key>
// <key>CFBundleTypeExtensions</key>
// insert the fileTypes
    NSArray *fileTypes = [Snd soundFileExtensions];
    [Snd defaultFileExtension]    
    pathname = nil;  // so if we fail to load, we have notice of this.

#endif

- setDocument: aDocument
{
    currentDocument = aDocument;
    return self;
}

- document
{
    return currentDocument;
}

- printSound: sender
{
    [currentDocument printTimeWindow];
    return self;
}

- printSpectrum: sender
{
    [currentDocument printSpectrumWindow];
    return self;
}

- printWaterfall: sender
{
    [currentDocument printWaterfallWindow];
    return self;
}

- (IBAction) sndInfo: (id) sender
{
    [currentDocument sndInfo:sender];
}

- showInfoPanel: sender
{
    [infoPanel makeKeyAndOrderFront:nil];
    return self;	
}

- showPreferences: sender
{
    if (!prefController) {
	[NSBundle loadNibNamed:@"preferences.nib" owner:self];
    }
    [[prefController window] makeKeyAndOrderFront:sender];
    return self;
}

- (int) documentCount
{
    return counter;
}

- setCounter: (int) count
{
    counter = count;
    return self;
}

@end

@implementation SoundController(ApplicationDelegate)

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    currentDocument = nil;
    [self showInfoPanel:self];
}

- (void) applicationDidHide: (NSNotification *) notification
{
    if (currentDocument)
        [currentDocument stop:nil];
}

@end
