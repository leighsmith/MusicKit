/*	SoundController.m
 *	Originally from SoundEditor3.0.
 *	Modified for Spectro3 by Gary Scavone.
 *	Last modified: 4/94
 */

#import "SoundController.h"
#import "SaveToController.h"
#import "SoundDocument.h"

#import <AppKit/AppKit.h>
#import <string.h>
#import <Foundation/Foundation.h>

static NSString *pathname;

static NSString * getOpenPath(NSString *buf)
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    NSArray *fileTypes = [Snd soundFileExtensions];
    int opr;
    
    if (!buf)
        buf = @"";
    
    opr = [openPanel runModalForDirectory: buf file: @"" types: fileTypes];

    if (opr == NSOKButton)
        return [buf stringByAppendingPathComponent: [openPanel filename]];
    else
        return nil;
}


static NSString *getSavePath(NSString *defaultPath, NSView *accessory)
{
    id	savePanel;
    BOOL		ok=NO;

    savePanel = [NSSavePanel savePanel];
    [savePanel setRequiredFileType:@"snd"];
    [savePanel setAccessoryView:accessory];
    if (defaultPath) if ([defaultPath length]) {
        ok = [savePanel runModalForDirectory:[defaultPath stringByDeletingLastPathComponent]
                                        file:[defaultPath lastPathComponent]];
    } else
        ok = [savePanel runModal];
    if (ok) {
        return [savePanel filename];
    }
    else
        return NO;
}

NSString *colorToString(NSColor *color)
{
    float r, g, b;
    NSString *ret;
    [[color colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:NULL];
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
    [super init];
	counter = 0;
    return self;
}

+ (void)initialize
{
    NSMutableDictionary *SpectroDefaults = [[NSDictionary dictionaryWithObjectsAndKeys:
    @"1024",	@"WindowSize",
    @"2.0",	@"ZPFactor",
    @"0.5",	@"HopRatio",
    @"Hanning",	@"WindowType",
    @"10000",	@"SpectrumMaxFreq",
    @"-100",	@"dBLimit",
    @"5000",	@"WFMaxFreq",
    @"3.0",	@"WFPlotHeight",
    @"0",	@"DisplayType",
    @"0:0:0",	@"SpectrumColor",
    @"1:0:0",	@"CursorColor",
    @"0.3333:0.3333:0.3333", @"WaterfallColor",
    @"0.6666:0.6666:0.6666", @"GridColor",
    NULL,NULL] retain];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:SpectroDefaults];
	
    return;
}

- newSoundDoc:sender
{
    SoundDocument * newDocument;
    NSString *filenamebuf;
    if (!currentDir) currentDir = @"";
    filenamebuf = [currentDir stringByAppendingPathComponent: @"/UNTITLED"];
    newDocument = [self openDoc];
    [newDocument setFileName:filenamebuf];
    return self;
}

- open:sender
{
    [pathname release];
    pathname = nil;
    if (pathname = getOpenPath(pathname))
        [self openFile:[pathname retain]];
    return self;
}

- openFile:(NSString *)fileName
{
    SoundDocument * newDocument;
    newDocument = [self openDoc];
    [newDocument setFileName:fileName];
    [newDocument load:nil];
        [newDocument setButtons];
    return self;
}

- openDoc
{
	id newDoc;
	newDoc = [[SoundDocument alloc] init];
	[self setDocument:newDoc];
	[documentList addObject:newDoc];
	return newDoc;
}

- setDocument:aDocument
{
    currentDocument = aDocument;
    return self;
}

- document
{
    return currentDocument;
}

- closeDoc:aDoc
{
	[documentList removeObject:aDoc];
	return self;
}

- save:sender
{
    if (currentDocument) {
        id thename = [currentDocument fileName];
        if (thename) if ([thename isEqualToString:@"/UNTITLED"]) {
            [self saveAs:sender];
            return self;
        }
            else [currentDocument save:sender];
    }
    return self;
}

- saveAs:sender
{
    return [self saveAs:sender withAccessory:nil];
}

- saveAs:sender withAccessory:accessory
{
    NSString * mypathname;
    SoundDocument * doc = currentDocument;
    if (accessory)
        [saveToController setSound:[doc sound]];
    if (doc && (mypathname = getSavePath([doc fileName],accessory))) {
        [pathname release];
        pathname = [mypathname retain];
        if (accessory)
            [doc saveToFormat:[saveToController soundTemplate]
                     fileName: pathname];
        else {
            [doc setFileName:pathname];
            [doc save:sender];
        }
    }
    return self;
}

- saveTo:(id)sender
{
    return [self saveAs:sender withAccessory:saveToAccessoryView];
}

- printSound:sender
{
	[currentDocument printTimeWindow];
	return self;
}

- printSpectrum:sender
{
	[currentDocument printSpectrumWindow];
	return self;
}

- printWaterfall:sender
{
	[currentDocument printWaterfallWindow];
	return self;
}

- sndInfo:sender
{
	[currentDocument sndInfo:sender];
	return self;
}

- revertToSaved:sender
{
    if (currentDocument)
		[currentDocument revertToSaved:sender];
    return self;
}

- stringTable
{
    return stringTable;	
}

- showInfoPanel:sender
{
    [infoPanel makeKeyAndOrderFront:nil];
    return self;	
}

- showPreferences:sender
{
	if (!prefController) {
		[NSBundle loadNibNamed:@"preferences.nib" owner:self];
	}
	[[prefController window] makeKeyAndOrderFront:sender];
	return self;
}

- (int)documentCount
{
	return counter;
}

- setCounter:(int)count
{
	counter = count;
	return self;
}

@end

@implementation SoundController(ApplicationDelegate)


- (int)application:sender openFile:(NSString *)filename
{
	if (![[filename pathExtension] isEqualToString:@"snd"]) {
	   fprintf(stderr,"SoundEditor: Attempt to open file type %s\n",[[filename pathExtension] cString]);
	   return NO;
	}
    [pathname release];
    pathname = [filename copy];
    return ([self openFile:pathname] != nil);
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    documentList = [NSMutableArray new];
    currentDocument = nil;
    [self showInfoPanel:self];
}

- (void)applicationDidHide:(NSNotification *)notification
{
    if (currentDocument)
        [currentDocument stop:nil];
}

- (BOOL)applicationShouldTerminate:(id)sender
{
	int i, count, touched;
	id doc;
	
	count = [documentList count];
	touched = NO;
	for (i = 0; i < count; i++) {
		doc = [documentList objectAtIndex:i];
		if ([doc touched]) touched = YES;
	}
	if (touched) {
		i = NSRunAlertPanel(@"Quit",
                      NSLocalizedStringFromTableInBundle(@"Sound Document(s) not saved", @"Spectro", [NSBundle mainBundle], "not saved button name"),
                      NSLocalizedStringFromTableInBundle(@"Yes", @"Spectro", [NSBundle mainBundle], "Yes button name"),
                      NSLocalizedStringFromTableInBundle(@"No", @"Spectro", [NSBundle mainBundle], "No button name"), nil); 
		if (i == NSAlertAlternateReturn)
                    return NO;
	}
	[documentList release];
	return YES;
}

@end