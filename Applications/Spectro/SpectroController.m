/*	$Id: SoundController.m 3388 2006-10-10 20:27:56Z leighsmith $
*	Originally from SoundEditor3.0.
*	Modified for Spectro3 by Gary Scavone.
*	Last modified: 4/94
*/

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

#import "SpectroController.h"
#import "SoundDocument.h"

NSString *colorToString(NSColor *color)
{
    float r, g, b;

    [[color colorUsingColorSpaceName: NSCalibratedRGBColorSpace] getRed: &r green: &g blue: &b alpha: NULL];
    return [NSString stringWithFormat:@"%f:%f:%f:", r, g, b];
}

NSColor *stringToColor(NSString *buffer)
{
    float r, g, b;
    const char *buf = [buffer UTF8String];
    
    sscanf(buf, "%f:%f:%f", &r, &g, &b);
    return [NSColor colorWithCalibratedRed: r green: g blue: b alpha: 1.0];
}

@implementation SpectroController

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
    [super initialize];    
    
    // register our defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults: [NSDictionary dictionaryWithObjectsAndKeys:
	@"1024", @"WindowSize",
	@"2.0", @"ZPFactor",
	@"0.5", @"HopRatio",
	@"Hanning", @"WindowType",
	@"10000", @"SpectrumMaxFreq",
	@"-100", @"dBLimit",
	@"5000", @"WFMaxFreq",
	@"3.0", @"WFPlotHeight",
	@"0", @"DisplayType",
	colorToString([NSColor blackColor]), @"SpectrumColor",
	colorToString([NSColor greenColor]), @"WaterfallColor",
	colorToString([NSColor redColor]), @"CursorColor",
	colorToString([NSColor lightGrayColor]), @"GridColor",
	colorToString([NSColor blueColor]), @"AmplitudeColor",
	nil, nil]];	
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
    [currentDocument sndInfo: sender];
}

- showInfoPanel: sender
{
    [infoPanel makeKeyAndOrderFront: nil];
    return self;	
}

- showPreferences: sender
{
    if (!prefController) {
	[NSBundle loadNibNamed: @"preferences.nib" owner: self];
    }
    [[prefController window] makeKeyAndOrderFront: sender];
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

@implementation SpectroController(ApplicationDelegate)

- (void) applicationDidFinishLaunching: (NSNotification *) notification
{
    currentDocument = nil;
    [self showInfoPanel: self];
}

- (void) applicationDidHide: (NSNotification *) notification
{
    if (currentDocument)
        [currentDocument stop: nil];
}

@end
