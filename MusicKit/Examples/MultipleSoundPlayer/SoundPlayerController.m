#import "SoundPlayerController.h"

@implementation SoundPlayerController

- init
{
    return self;
}

- (void)chooseSoundFile:(id)sender
{
    int result;
    NSArray *fileTypes = [NSSound soundUnfilteredFileTypes];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];

    NSLog(@"Accepting %@\n", fileTypes);
    [oPanel setAllowsMultipleSelection:YES];
    result = [oPanel runModalForDirectory: NSHomeDirectory() file:nil types:fileTypes];
    if (result == NSOKButton) {
        int i, count;
        filesToPlay = [oPanel filenames];
        [filesToPlay retain];
        count = [filesToPlay count];
        for (i=0; i<count; i++) {
            [soundFileNameTextBox setStringValue: [filesToPlay objectAtIndex:i]];
            [playButton setEnabled: YES];
        }
    }   

}

- (void)playSoundOld:(id)sender
{
    NSSound *sound;
    int i, count = [filesToPlay count];

    NSLog(@"reading %@\n", filesToPlay);
    for (i=0; i<count; i++) {
        NSString *soundFileName = [filesToPlay objectAtIndex:i];
        sound = [[NSSound alloc] initWithContentsOfFile: soundFileName byReference:NO];
        if(sound != nil) {
            NSLog(@"playing %@\n", soundFileName);
            [sound setDelegate: self];
            [sound play];
        }
    }
}


- (void)playSound:(id)sender
{
    NSSound *sound1;
    NSSound *sound2;
    NSString *soundFileName = [filesToPlay objectAtIndex:0];

    NSLog(@"reading %d file %@\n", [filesToPlay count], filesToPlay);
    sound1 = [[NSSound alloc] initWithContentsOfFile: soundFileName byReference:NO];
    if(sound1 != nil) {
        NSLog(@"playing %@\n", soundFileName);
        [sound1 setDelegate: self];
        [sound1 play];
    }
    if([filesToPlay count] > 1) {
        NSString *soundFileName2 = [filesToPlay objectAtIndex:1];

        sound2 = [[NSSound alloc] initWithContentsOfFile: soundFileName2 byReference:NO];
        if(sound2 != nil) {
            NSLog(@"playing %@\n", soundFileName2);
            [sound2 setDelegate: self];
            [sound2 play];
        }
    }
}

- (void) sound:(NSSound *) sound didFinishPlaying:(BOOL)aBool
{
    NSLog(@"did finish playing %d sound named %@\n", aBool, [sound name]);
}


@end
