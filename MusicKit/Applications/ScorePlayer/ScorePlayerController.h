#ifndef __MK_MyApp_H___
#define __MK_MyApp_H___

#import <AppKit/AppKit.h>
#define TEXT 0

@interface ScorePlayerController: NSObject
{
    IBOutlet NSButton *playButton;
    id tempoSlider;
    id tempoTitle;
    id tempoTextField;
    id theMainWindow;
    id tooFastErrorMsg;
    IBOutlet NSPanel *soundSavePanel;
    IBOutlet NSTextField *soundWriteMsg;
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


- (void)help:sender;
- (void)openEditFile:sender;
- (void)deviceSpecificSettings:sender;
- (void)setSoundOutFrom:sender;
- (void)saveAsDefaultDevice:sender;
- (void)applicationWillFinishLaunching:(NSNotification *)notification;
- (void)setTempoFrom:sender;
- (void)playStop:sender;
- (void)selectFile:sender;
- (void)showErrorLog:sender;
- (void)saveScoreAs:sender;
- (void)setAD64xConsumer:sender;
- (void)setAD64xProfessional:sender;
- (void)setTimeCodeSynch:sender;
- (void)setTimeCodeSerialPort:sender;
- (void)setDAI2400CopyProhibit:sender;
- (void)setDAI2400Emphasis:sender;
- (void)setNeXTDACVolume:sender;
- (void)setNeXTDACMute:sender;
- (void)getNeXTDACCurrentValues:sender;
- (BOOL) validateMenuItem: (NSMenuItem *) menuItem;

@end

#endif
