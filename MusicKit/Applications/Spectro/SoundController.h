
#import <Foundation/NSObject.h>
#import <AppKit/NSColor.h>
#import <Foundation/NSArray.h>

NSString *colorToString(NSColor  *color);
NSColor  *StringToColor(NSString *buf);

@interface SoundController:NSObject
{
	id currentDocument;
	NSMutableArray *documentList;
	id infoPanel;
	id stringTable;
	id saveToAccessoryView;
	id saveToController;
	id prefController;
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
- save:sender;
- saveAs:sender;
- saveAs:sender withAccessory:accessory;
- saveTo:(id)sender;
- printSound:sender;
- printSpectrum:sender;
- printWaterfall:sender;
- sndInfo:sender;
- revertToSaved:sender;
- stringTable;
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