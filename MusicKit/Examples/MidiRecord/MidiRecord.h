/* $Id$
  Example Application within the MusicKit

  Description:
    See MidiRecord.m for details.

  Portions Copyright (c) 1999-2004, The MusicKit Project.
*/

#import <AppKit/AppKit.h>
#import <MusicKit/MusicKit.h>

@interface MidiRecord : NSObject
{
    MKMidi *midiIn;
    MKScore *score;
    MKScoreRecorder *scoreRecorder;
    NSString *scoreFilePath;
    NSString *scoreFileDir;
    NSString *scoreFileName;
    NSSavePanel *savePanel;
    BOOL needsUpdate;

    id saveAsMenuItem;
    id saveMenuItem;
    id myWindow;
    id infoPanel;
    IBOutlet NSButton *recordButton;
    IBOutlet NSPopUpButton *driverPopup;
}

- (void) go: sender;
- (void) saveAs: sender;
- (void) save: sender;
- (IBAction) showInfoPanel: sender;
- (void) setDriverName: (id) sender;
- init;
@end
