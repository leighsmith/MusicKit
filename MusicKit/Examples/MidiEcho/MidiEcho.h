/*
 $Id$
 
 Portions Copyright (c) 1999-2005, The MusicKit Project.  All rights reserved.
 
 Permission is granted to use and modify this code for commercial and 
 non-commercial purposes so long as the author attribution and copyright 
 messages remain intact and accompany all relevant code.
 
 */

#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>
#import "EchoFilter.h"

@interface MidiEcho: NSObject
{
    IBOutlet NSPanel *infoPanel;
    EchoFilter *myFilter;
    MKMidi *midi;
}

- (IBAction) setMidiDev: (id) sender;
- (IBAction) go: (id) sender;
- (IBAction) setDelayFrom: (id) sender;
- (IBAction) showInfoPanel: (id) sender;

@end
