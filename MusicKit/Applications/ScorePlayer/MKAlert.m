/*
 $Id$  
 
 Description:
   This is just like Alert.m (in the AppKit) but it sets the font to Courier
   to make MusicKit errors format correctly.  SIGH!!!

 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Portions Copyright (c) 1999-2004 The MusicKit Project 
*/

#import "MKAlert.h"
#import <AppKit/AppKit.h>
#import <stdarg.h>
#import <Foundation/Foundation.h>

@implementation MKAlert

- init
{
    NSString *path;
    [super init];
    if (((path = [[NSBundle mainBundle] pathForResource: @"MKAlertPanel" ofType: @"nib"]) == nil))
	NSLog(@"Nib file missing for ScorePlayer!\n");
    else 
	[NSBundle loadNibFile:path externalNameTable: [NSDictionary dictionaryWithObjectsAndKeys:self, @"NSOwner", nil] withZone:[self zone]];
    return self;
}

- (void)dealloc
{
    if (![first superview]) [first release];
    if (![second superview]) [second release];
    if (![third superview]) [third release];
    [panel release];
    { [super dealloc]; return; };
}

- setIconButton:anObject
{
    [anObject setImage:[NSImage imageNamed:@"NSApplicationIcon"]];
    return self;
}

- setMsg:anObject
{
    msg = anObject;
    [msg setFont:[NSFont fontWithName:@"Courier" size:[[msg font] pointSize]]];
#if 0
    [[msg cell] _setCentered:YES]; /* Private appkit method */
#endif
    [msg setDrawsBackground:YES];
    return self;
}

- (void)buttonPressed:sender
{
    int exitValue;
    if (sender == first) {
	exitValue = NSAlertDefaultReturn;
    } else if (sender == second) {
	exitValue = NSAlertAlternateReturn;
    } else if (sender == third) {
	exitValue = NSAlertOtherReturn;
    } else {
	exitValue = NSAlertErrorReturn;
    }
    [NSApp stopModalWithCode:exitValue]; 
}

- setMessage:(NSString *)message
{
    [msg setBackgroundColor:[NSColor lightGrayColor]];
    [msg setStringValue:message];
    return self;
}

#define MAXMSGLENGTH 1024

static id buildAlert(MKAlert *alert, NSString *title, NSString *s, NSString *first, NSString *second, NSString *third)
{
    NSString *t;

    if (first) {
        [alert->first setTitle:first];
        if (!title || ![title length]) {
	    [alert->title setStringValue:@""];
	} else {
	    t = [alert->title stringValue];
            if (!t || [t isEqualToString:title]) [alert->title setStringValue:title];
	}
	if (second) {
	    [[alert->panel contentView] addSubview:alert->second];
            [alert->second setTitle:second];
	    if (third) {
		[[alert->panel contentView] addSubview:alert->third];
                [alert->third setTitle:third];
	    } else {
		[alert->third removeFromSuperview];
	    }
	} else {
	    [alert->second removeFromSuperview];
	    [alert->third removeFromSuperview];
	}
    } else {
	[alert->first removeFromSuperview];
	[alert->second removeFromSuperview];
	[alert->third removeFromSuperview];
    }
    [alert setMessage:s];
    return alert->panel;
}

int mkRunAlertPanel(NSString *title, NSString *s, NSString *first, NSString *second, NSString *third)
{
    id panel;
    NSZone *zone;
    MKAlert *newAlert;
    static id cachedAlert = nil;
    NSException *handler = nil;
    volatile int exitValue = NSAlertErrorReturn;
    
    if (cachedAlert) 
	newAlert = cachedAlert;
    else {
	zone = [NSApp zone];
	if (!zone) zone = NSDefaultMallocZone();
	newAlert = [[MKAlert allocWithZone:zone] init];
	if (!newAlert) return NSAlertErrorReturn;
    }
    panel = buildAlert(newAlert, title, s, first, second, third);
    NS_DURING {
	exitValue = [NSApp runModalForWindow:panel];
    } NS_HANDLER {
        handler = [NSException exceptionWithName:[localException name]
                                          reason:[localException reason]
                                        userInfo:[localException userInfo]];
    } NS_ENDHANDLER
    [panel orderOut:panel];
    cachedAlert = [panel delegate];
    return exitValue;
}

@end

