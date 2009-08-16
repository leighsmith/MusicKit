/*
  $Id$

  Description:
    Very simple sound player application, demonstrating playing multiple sounds,
    and the use of Snd delegates. In this case we simply use the SndPerformances
    to enumerate which version of a sound is playing.
    
  Original Author: Leigh Smith, <leigh@tomandandy.com>, tomandandy music inc.

  Copyright (c) 2001 tomandandy music inc. All rights reserved.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/

#import "SoundPlayerController.h"

@implementation SoundPlayerController

- init
{
    [super init];
    currentPerformances = [[NSMutableDictionary dictionaryWithCapacity: 12] retain];
    soundTag = 0;
    return self;
}

- (void) chooseSoundFile: (id) sender
{
    int result;
    NSArray *fileTypes = [Snd soundFileExtensions];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];

    // NSLog(@"Accepting %@\n", fileTypes);
    [oPanel setAllowsMultipleSelection: YES];
    result = [oPanel runModalForDirectory: nil file: nil types: fileTypes];
    if (result == NSOKButton) {
        [filesToPlay release];
        filesToPlay = [[oPanel filenames] retain];
        [playButton setEnabled: YES];
    }
    [soundFileNameTableView setDataSource: self];
    [soundFileNameTableView deselectAll: self];
    [soundFileNameTableView reloadData];
}

- (void) playSound: (id) sender
{
    Snd *sound;
    int i, count = [filesToPlay count];

    for (i=0; i<count; i++) {
        NSString *soundFileName = [filesToPlay objectAtIndex:i];
        sound = [[Snd alloc] initFromSoundfile: soundFileName];
        if(sound != nil) {
            // NSLog(@"starting playing %@\n", soundFileName);
            [sound setDelegate: self];
            [sound setName: soundFileName];
            [sound play];
        }
    }
}

- (void) willPlay: (Snd *) sound duringPerformance: (SndPerformance *) performance
{
    // NSLog(@"will begin playing sound number %d named %@\n", soundTag, [sound name]);
    [currentPerformances setObject: [NSNumber numberWithInt: soundTag++]
                            forKey: performance];
}

- (void) didPlay: (Snd *) sound duringPerformance: (SndPerformance *) performance
{
    NSNumber *soundTagNumber;
    NSEnumerator *performanceEnum;
    id currentPerf;
    performanceEnum = [currentPerformances keyEnumerator];
    while((currentPerf = [performanceEnum nextObject])) {
        if([currentPerf isEqual: performance]) {
            break;
        }
    }
    soundTagNumber = [currentPerformances objectForKey: currentPerf];  // yet works with this?
    // NSLog(@"did finish playing sound number %d named %@\n", [soundTagNumber intValue], [sound name]);
    [currentPerformances removeObjectForKey: performance];
}

- (void) hadError: (Snd *) sound
{
    NSLog(@"had error playing sound named %@\n", [sound name]);
}

/******************** DELEGATE MESSAGES FOR NSTableView ******************/
- (id) tableView: (NSTableView *) aTableView
objectValueForTableColumn: (NSTableColumn *) aTableColumn
	     row: (int) rowIndex
{	
    return [filesToPlay objectAtIndex:rowIndex];
}

- (int) numberOfRowsInTableView: (NSTableView *) aTableView
{
    return [filesToPlay count];
}

@end
