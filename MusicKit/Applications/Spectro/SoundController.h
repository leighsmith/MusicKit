/*
  $Id$
  
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

@class SaveToController;

@interface SoundController:NSObject
{
    id currentDocument;
    NSMutableArray *documentList;
    id infoPanel;
    id saveToAccessoryView;
    SaveToController *saveToController;
    PrefController *prefController;
    int counter;
    id currentDir;
}

- init;
+ (void)initialize;
- newSoundDoc:sender;
- open:sender;
- openFile:(NSString *)fileName;
- openDoc;
- setDocument:aDocument;
- document;
- closeDoc:aDoc;
- (void) save: (id) sender;
- saveAs:sender;
- saveAs:sender withAccessory:accessory;
- saveTo:(id)sender;
- printSound:sender;
- printSpectrum:sender;
- printWaterfall:sender;
- sndInfo:sender;
- revertToSaved:sender;
- showInfoPanel:sender;
- showPreferences:sender;
- (int)documentCount;
- setCounter:(int)count;

@end

@interface SoundController(ApplicationDelegate)

- (int)application:sender openFile:(NSString *)filename;
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (void)applicationDidHide:(NSNotification *)notification;
- (BOOL)applicationShouldTerminate:(id)sender;

@end
