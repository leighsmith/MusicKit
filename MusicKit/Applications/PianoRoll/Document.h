/* $Id$ */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>
#import "PartView.h"

@interface Document:NSObject
{
    IBOutlet NSWindow *docWindow;
    IBOutlet PartView *partView;
    MKScore *theScore;
    NSString *name;
    BOOL current;
}

- initWithScore: (MKScore *) aScore;
- partView;
- (NSWindow *) docWindow;
- setName: (NSString *) theName;
- (NSString *) whatName;
- whatScore;
- (BOOL) isCurrent;

- (void)windowDidBecomeMain:(NSNotification *)notification;
- (void)windowDidResignMain:(NSNotification *)notification;
- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize;

@end
