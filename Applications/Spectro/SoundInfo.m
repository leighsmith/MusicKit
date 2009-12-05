/* 
 * $Id$
 *
 * Originally from SoundEditor2.1
 * Modified by Gary Scavone for Spectro3.0
 * Last modified: 2/94
 */

#import <AppKit/AppKit.h>
#import "SoundInfo.h"

@implementation SoundInfo

- init
{
    [super init];
    [NSBundle loadNibNamed:@"soundInfo.nib" owner:self];
    ssize = 0;
    return self;
}

- displaySound: (Snd *) sound title: (NSString *) title
{
    sndhdr = [sound retain];
    [self display:title];
    return self;
}

- setSoundHeader: (Snd *) sound
{
    sndhdr = [sound retain];
    return self;
}

- (void) display: (NSString *) title
{
    int hours, minutes;
    float seconds;
    
    [siPanel setTitle: title];
    [siSize setIntValue: [sndhdr dataSize]];
    [siRate setIntValue: [sndhdr samplingRate]];
    [siChannels setIntValue: [sndhdr channelCount]];
    [siFormat setStringValue: [sndhdr formatDescription]];
    [siFrames setIntValue: [sndhdr lengthInSampleFrames]];
    seconds = [sndhdr duration];
    hours = (int) (seconds / 3600);
    minutes = (int) ((seconds - hours * 3600) / 60);
    seconds = seconds - hours * 3600 - minutes * 60;
    [siTime setStringValue: [NSString stringWithFormat: @"%02d:%02d:%05.2f", hours, minutes, seconds]];
    [siPanel makeKeyAndOrderFront: self];
    [NSApp runModalForWindow: siPanel];
}

- setSiPanel:anObject
{
    siPanel = anObject;
    [siPanel setDelegate:self];
    return self;
}
- setSiSize:anObject
{
    siSize = anObject;
    [siSize setSelectable:NO];
    [siSize setEditable:NO];
    return self;
}

- setSiFrames:anObject
{
    siFrames = anObject;
    [siFrames setSelectable:NO];
    [siFrames setEditable:NO];
    return self;
}

- setSiFormat:anObject
{
    siFormat = anObject;
    [siFormat setSelectable:NO];
    [siFormat setEditable:NO];
    return self;
}

- setSiTime:anObject
{
    siTime = anObject;
    [siTime setSelectable:NO];
    [siTime setEditable:NO];
    return self;
}

- setSiRate:anObject
{
    siRate = anObject;
    [siRate setSelectable:NO];
    [siRate setEditable:NO];
    return self;
}

- setSiChannels:anObject
{
    siChannels = anObject;
    [siChannels setSelectable:NO];
    [siChannels setEditable:NO];
    return self;
}

- (BOOL) windowShouldClose: (id) sender
{
    [NSApp stopModal];
    return YES;
}

@end
