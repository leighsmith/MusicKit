/* $Id$
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
    id theButton;
}

- (void) go: sender;
- (void) saveAs: sender;
- (void) save: sender;
- (void) showInfoPanel: sender;

@end
