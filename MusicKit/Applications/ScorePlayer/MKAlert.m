/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  This is just like Alert.m (in the appkit) but it sets the font to Courier
  to make Music Kit errors format correctly.  SIGH!!!
*/

#import "MKAlert.h"
#import <AppKit/AppKit.h>
//#import <appkit/Application.h>
//#import <appkit/Button.h>
//#import <appkit/Font.h>
//#import <appkit/Panel.h>
//#import <appkit/nextstd.h>
///#import <appkit/errors.h>
#import <stdarg.h>
#import <objc/zone.h>
#import <objc/NXBundle.h>

@implementation MKAlert

+ new
{
    return [[self allocFromZone:NXDefaultMallocZone()] init];
}

- init
{
    char buf[MAXPATHLEN + 1];
    [super init];
    if (![[NXBundle mainBundle] getPath:buf forResource:"MKAlertPanel.nib" 
	ofType:"nib"])
      fprintf(stderr,"Nib file missing for ScorePlayer!\n");
    panel = [NXApp loadNibFile:buf owner:self withNames:NO];
    return self;
}

- free
{
    if (![first superview]) [first free];
    if (![second superview]) [second free];
    if (![third superview]) [third free];
    [panel free];
    return [super free];
}

- setIconButton:anObject
{
    [anObject setIcon:"app"];
    return self;
}

- setMsg:anObject
{
    msg = anObject;
    [msg setFont:[Font newFont:"Courier" size:[[msg font] pointSize]]];
#if 0
    [[msg cell] _setCentered:YES]; /* Private appkit method */
#endif
    [msg setOpaque:YES];
    return self;
}

- buttonPressed:sender
{
    int exitValue;
    if (sender == first) {
	exitValue = NX_ALERTDEFAULT;
    } else if (sender == second) {
	exitValue = NX_ALERTALTERNATE;
    } else if (sender == third) {
	exitValue = NX_ALERTOTHER;
    } else {
	exitValue = NX_ALERTERROR;
    }
    [NXApp stopModal:exitValue];
    return self;
}

- setMessage:(const char *)message
{
    [msg setBackgroundGray:NX_LTGRAY];
    [msg setStringValue:message];
    return self;
}

#define MAXMSGLENGTH 1024

static id buildAlert(MKAlert *alert, const char *title, const char *s, const char *first, const char *second, const char *third)
{
    const char *t;

    if (first) {
	[alert->first setTitle:first];
	if (!title || !*title) {
	    [alert->title setStringValueNoCopy:""];
	} else {
	    t = [alert->title stringValue];
	    if (!t || strcmp(t, title)) [alert->title setStringValue:title];
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

int mkRunAlertPanel(const char *title, const char *s, const char *first, const char *second, const char *third)
{
    id panel;
    NXZone *zone;
    MKAlert *newAlert;
    static id cachedAlert = nil;
    volatile NXHandler handler;
    volatile int exitValue = NX_ALERTERROR;
    if (cachedAlert) 
	newAlert = cachedAlert;
    else {
	zone = [NXApp zone];
	if (!zone) zone = NXDefaultMallocZone();
	zone = NXCreateChildZone(zone, 1024, 1024, YES);
	newAlert = [[MKAlert allocFromZone:zone] init];
	NXMergeZone(zone);
	if (!newAlert) return NX_ALERTERROR;
    }
    panel = buildAlert(newAlert, title , s, first, second, third);
    NXPing();
    NX_DURING {
	handler.code = 0;
	exitValue = [NXApp runModalFor:panel];
    } NX_HANDLER {
	handler = NXLocalHandler;
	if (handler.code == dps_err_ps) NXReportError((NXHandler *)(&handler));
    } NX_ENDHANDLER
    [panel orderOut:panel];
    cachedAlert = [panel delegate];
    if (handler.code && handler.code != dps_err_ps) {
	NX_RAISE(handler.code, handler.data1, handler.data2);
    }
    return exitValue;
}

@end

