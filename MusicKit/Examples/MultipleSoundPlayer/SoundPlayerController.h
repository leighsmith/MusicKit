#import <AppKit/AppKit.h>

@interface SoundPlayerController : NSObject
{
    IBOutlet id soundFileNameTextBox;
    NSArray *filesToPlay;
    IBOutlet id playButton;
}

- init;
- (void)chooseSoundFile:(id)sender;
- (void)playSound:(id)sender;
@end
