/*
  $Id$

  Description:
    Very simple sound player application, demonstrating playing multiple sounds,
    and the use of Snd delegates.
    
  Original Author: Leigh Smith, <leigh@tomandandy.com>, tomandandy music inc.

  2-Mar-2001, Copyright (c) 2001 tomandandy music inc. All rights reserved.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/

#import "SoundPlayerController.h"

@implementation SoundPlayerController

- (void) chooseSoundFile: (id) sender
{
    int result;
    NSArray *fileTypes = [Snd soundFileExtensions];
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

- (void) playSound: (id) sender
{
    Snd *sound;
    int i, count = [filesToPlay count];

    NSLog(@"reading %@\n", filesToPlay);
    for (i=0; i<count; i++) {
        NSString *soundFileName = [filesToPlay objectAtIndex:i];
        sound = [[Snd alloc] initFromSoundfile: soundFileName];
        if(sound != nil) {
            NSLog(@"playing %@\n", soundFileName);
            [sound setDelegate: self];
            [sound setName: soundFileName];
            [sound play];
        }
    }
}

- (void) willPlay: (Snd *) sound duringPerformance: (SndPerformance *) performance
{
    NSLog(@"will begin playing sound named %@\n", [sound name]);
}

- (void) didPlay: (Snd *) sound duringPerformance: (SndPerformance *) performance
{
    NSLog(@"did finish playing sound named %@\n", [sound name]);
}

- (void) hadError: (Snd *) sound
{
    NSLog(@"had error playing sound named %@\n", [sound name]);
}

@end
