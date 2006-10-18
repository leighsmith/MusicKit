/*
  $Id: SoundController.h 3388 2006-10-10 20:27:56Z leighsmith $
  
  Part of Spectro.app
  Modifications Copyright (c) 2003 The MusicKit Project, All Rights Reserved.

  Legal Statement Covering Additions by The MusicKit Project:

    Permission is granted to use and modify this code for commercial and
    non-commercial purposes so long as the author attribution and copyright
    messages remain intact and accompany all relevant code.

*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "PrefController.h"

NSString *colorToString(NSColor  *color);
NSColor  *StringToColor(NSString *buf);

@interface SpectroController: NSObject
{
    id currentDocument;
    IBOutlet id infoPanel;
    IBOutlet id saveToAccessoryView;
    PrefController *prefController;
    int counter;
}

- init;
+ (void) initialize;
- setDocument: aDocument;
- document;
- printSound: sender;
- printSpectrum: sender;
- printWaterfall: sender;
- (IBAction) sndInfo: (id) sender;
- showInfoPanel: sender;
- showPreferences: sender;
- (int) documentCount;
- setCounter: (int) count;

@end

@interface SpectroController(ApplicationDelegate)

- (void) applicationDidFinishLaunching: (NSNotification *) notification;
- (void) applicationDidHide: (NSNotification *) notification;

@end
