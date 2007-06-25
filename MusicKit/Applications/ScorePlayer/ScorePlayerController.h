#ifndef __MK_ScorePlayerController_H___
#define __MK_ScorePlayerController_H___

#import <AppKit/AppKit.h>
#define TEXT 0

@interface ScorePlayerController: NSObject
{
    IBOutlet NSButton *playButton;
    IBOutlet NSPanel *soundSavePanel;
    IBOutlet NSTextField *soundWriteMsg;
    IBOutlet NSSlider *tempoSlider;
    IBOutlet NSTextField *tempoTitle;
    IBOutlet NSTextField *tempoTextField;
    IBOutlet NSWindow *theMainWindow;
    IBOutlet NSTextField *tooFastErrorMsg;
    IBOutlet NSButton *timeCodeButton;
    IBOutlet NSMatrix *timeCodePortMatrix;
    IBOutlet NSTextField *timeCodeTextField;
    IBOutlet NSPopUpButton *defaultMidiPopUp; // The popup that lists available MIDI drivers for the default "midi" device.
    IBOutlet NSPopUpButton *soundOutputDevicePopUp;  // The popup that lists available sound output devices.
    IBOutlet NSTextField *serialPortDeviceNameField;
    
    // Redundant NeXT specific hardware, needs to be removed.
    id NeXTDacMuteSwitch;
    id NeXTDacVolumeSlider;
    id SSAD64xPanel;
    id StealthDAI2400Panel;
    id NeXTDACPanel;
}

- (void) help: (id) sender;
- (void) openEditFile: (id) sender;
- (void) deviceSpecificSettings: (id) sender;
// Sets the audio output from the selected list.
- (IBAction) setSoundOutFrom: (id) sender;
// Sets the default MIDI driver name from the selected list.
- (IBAction) setMidiDriverName: (id) sender;
- (IBAction) setTempoFrom: (id) sender;
- (IBAction) setTimeCodeSynch: (id) sender;
- (IBAction) setTimeCodeSerialPort: (id) sender;
// Enables or disables tempo adjustment
- (IBAction) setTempoAdjustment: (id) sender;
- (void) saveAsDefaultDevice: (id) sender;
- (void) applicationWillFinishLaunching: (NSNotification *) notification;
- (void) playStop: (id) sender;
- (void) selectFile: (id) sender;
- (void) showErrorLog: (id) sender;
- (void) saveScoreAs: (id) sender;
- (void) setNeXTDACVolume: (id) sender;
- (void) setNeXTDACMute: (id) sender;
- (void) getNeXTDACCurrentValues: (id) sender;
- (BOOL) validateMenuItem: (NSMenuItem *) menuItem;

@end

#endif
