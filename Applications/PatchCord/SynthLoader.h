/* SynthLoader.h created by leigh on Tue 28-Jul-1998 */

#import <AppKit/AppKit.h>

@interface SynthLoader : NSObject {
}

- (void) loadTheBundles;
- (void) awakeFromNib;

@end

@interface SynthLoader(ApplicationDelegate)
- (void) applicationDidFinishLaunching: (NSNotification *) notification;
- (void) applicationDidBecomeActive: (NSNotification *) notification;
- (BOOL) applicationOpenUntitledFile: (NSApplication *) theApplication;
- (BOOL) applicationShouldTerminate: (id) sender;
@end

@interface SynthLoader(ServiceManager)
- (void) patchMessage: (NSPasteboard *) pasteboard userData: (NSString *) sortArgs error: (NSString **) errorMessage;
@end
