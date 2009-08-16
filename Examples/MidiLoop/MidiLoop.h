/*
 $Id$
 
 Portions Copyright (c) 1999-2005, The MusicKit Project.  All rights reserved.
 
 Permission is granted to use and modify this code for commercial and 
 non-commercial purposes so long as the author attribution and copyright 
 messages remain intact and accompany all relevant code.
 
 */

#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>

@interface MidiLoop : NSObject
{
    MKMidi *midiObj;
    IBOutlet NSPanel *infoPanel;
}

- (void) applicationWillTerminate: (NSNotification *) aNotification;
- (IBAction) go: (id) sender;
- (IBAction) showInfoPanel: (id) sender;

@end
