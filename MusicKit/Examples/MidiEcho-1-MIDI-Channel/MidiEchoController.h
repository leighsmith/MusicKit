/*
  $Id$
 */

#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>
#import "EchoFilter.h"

@interface MidiEchoController : NSObject
{
    EchoFilter *myFilter;
    MKMidi *midi;
    id infoPanel;
    id stringTable;
}

- (IBAction) setMidiDev: (id) sender;
- (IBAction) go: (id) sender;
- (IBAction) setDelayFrom: (id) sender;
- (IBAction) showInfoPanel: (id) sender;

@end
