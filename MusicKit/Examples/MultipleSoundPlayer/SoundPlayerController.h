#import <AppKit/AppKit.h>

@interface SoundPlayerController : NSObject
{
    id soundFileNameTextBox1;
    id soundFileNameTextBox2;
    NSArray *filesToPlay;
}

- init;
- (void)chooseSoundFile1:(id)sender;
- (void)chooseSoundFile2:(id)sender;
- (void)playSound:(id)sender;
@end
