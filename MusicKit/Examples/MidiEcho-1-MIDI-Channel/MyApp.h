/*
  $Id$
 */

#import <AppKit/AppKit.h>

@interface MyApp : NSObject
{
    MKNoteFilter *myFilter;
    MKMidi *midi;
    id infoPanel;
    id stringTable;
}

- setMidiDev: sender;
- go: sender;
- setDelayFrom: sender;
- showInfoPanel: sender;

@end
