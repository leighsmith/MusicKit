#ifndef __MK_MyApp_H___
#define __MK_MyApp_H___

#import <AppKit/AppKit.h>
#define TEXT 0

@interface ScorePlayerController: NSObject
{
    IBOutlet NSButton *playButton;
    IBOutlet NSPanel *soundSavePanel;
    IBOutlet NSTextField *soundWriteMsg;
    IBOutlet id tempoSlider;
    id tempoTitle;
    id tempoTextField;
    IBOutlet id theMainWindow;
    id tooFastErrorMsg;
    id NeXTDacMuteSwitch;
    id NeXTDacVolumeSlider;
    id timeCodeButton;
    id timeCodePortMatrix;
    id timeCodeTextField;
    id serialPortDeviceNameField;
    id serialPortDeviceMatrix;
    id SSAD64xPanel;
    id StealthDAI2400Panel;
    id NeXTDACPanel;
}

- (void) help: (id) sender;
- (void) openEditFile: (id) sender;
- (void) deviceSpecificSettings: (id) sender;
- (void) setSoundOutFrom: (id) sender;
- (void) saveAsDefaultDevice: (id) sender;
- (void) applicationWillFinishLaunching: (NSNotification *) notification;
- (void) setTempoFrom: (id) sender;
- (void) playStop: (id) sender;
- (void) selectFile: (id) sender;
- (void) showErrorLog: (id) sender;
- (void) saveScoreAs: (id) sender;
- (void) setTimeCodeSynch: (id) sender;
- (void) setTimeCodeSerialPort: (id) sender;
- (void) setNeXTDACVolume: (id) sender;
- (void) setNeXTDACMute: (id) sender;
- (void) getNeXTDACCurrentValues: (id) sender;
- (BOOL) validateMenuItem: (NSMenuItem *) menuItem;

@end

#endif
