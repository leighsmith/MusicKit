/* MIDIPartController.h created by leigh on Tue 04-May-1999 */

#import <MusicKit/MusicKit.h>

@interface MIDIFileController : NSObject
{
    MKMidi *midiInstrument;
    MKScorePerformer *aScorePerformer;
    MKPartPerformer *samplePartPerformer;
    MKSamplerInstrument *sampleInstrument;
    NSString *midiPathName;	
    NSString *soundPathName;
    NSString *keymapPathName;
    id midiPathNameTextBox;
    id keymapPathNameTextBox;
    id playButton;
    id pauseButton;
    id tempoSlider;
    id driverPopup;
    double currentTempo;
    NSDictionary *keymap;
}

- init;
- (void) transport: (id) sender;
- (void) pause: (id) sender;
- (void) applicationWillTerminate: (NSNotification *) aNotification;
- (void) applicationDidFinishLaunching:(NSNotification *) aNotification; 
- (void) setTempo: (id) sender;
- (void) haveFinishedPlaying;
- (void) setDriverName: (id) sender;
- (void) setMIDIFilename: (id) sender;
- (void) setKeymapFilename: (id) sender;
@end
