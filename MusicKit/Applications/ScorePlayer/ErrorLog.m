/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* Created by David Jaffe on Jan. 25, 1991. 

 */

#import "ErrorLog.h"
#import <AppKit/AppKit.h>
#import <stdarg.h>
#import <objc/zone.h>
#import <objc/NXBundle.h>

@implementation ErrorLog

+ new
{
    return [[self allocFromZone:NXDefaultMallocZone()] init];
}

- init
{
    char buf[MAXPATHLEN + 1];
    [super init];
    if (![[NXBundle mainBundle] getPath:buf forResource:"ErrorLog.nib" ofType:"nib"])
      fprintf(stderr,"Nib file missing for ScorePlayer!\n");
    panel = [NXApp loadNibFile:buf owner:self withNames:NO];
    return self;
}

- clear {
    int endPos = [msg byteLength];
    [msg setSel:0 :endPos];
    [msg replaceSel:"\n"];
    return self;
}

- buttonPressed:sender
{
    [self clear];
    return self;
}

- (BOOL)isVisible
{
    return [panel isVisible];
}

- setMsg:anObject
{
    msg = [anObject docView];
    [msg setFont:[Font newFont:"Courier" size:[[msg font] pointSize]]];
    return self;
}

- free
{
    [panel free];
    return [super free];
}

-addText:(char *)theText
{
    int endPos = [msg byteLength];
    [msg setSel:endPos :endPos];
    [msg replaceSel:"\n"];
    endPos++;
    [msg setSel:endPos :endPos];
    [msg scrollSelToVisible];
    [msg replaceSel:theText];
    return self;
}

-show
{
    [panel orderFront:panel];
    return self;
}

@end

