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
#import <AppKit/AppKit.h>
#import <SndKit/SndKit.h>

@interface SoundPlayerController : NSObject
{
    IBOutlet NSTableView *soundFileNameTableView;
    IBOutlet NSButton *playButton;
    NSArray *filesToPlay;
    NSMutableDictionary *currentPerformances;
    int soundTag;
}

- init;
- (void) chooseSoundFile: (id) sender;
- (void) playSound: (id) sender;
@end
