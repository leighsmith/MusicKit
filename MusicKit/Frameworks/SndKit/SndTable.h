////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2002, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import "Snd.h"

@interface SndTable : NSObject {
  NSMutableDictionary *nameTable;
}

+ defaultSndTable;
- init;
- (void) dealloc;
- soundNamed:(NSString *)aName;
- findSoundFor:(NSString *)aName;
- addName:(NSString *)aname sound:aSnd;
- addName:(NSString *)aname fromSoundfile:(NSString *)filename;
- addName:(NSString *)aname fromSection:(NSString *)sectionName;
- addName:(NSString *)aName fromBundle:(NSBundle *)aBundle;
- (void)removeSoundForName: (NSString *) aname;
- (void) removeAllSounds;

@end
