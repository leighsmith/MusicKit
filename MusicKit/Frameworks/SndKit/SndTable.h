//
//  SndTable.h
//  SndKit
//
//  Created by SKoT McDonald on Thu Jan 10 2002.
//  Copyright (c) 2001 tomandandy. All rights reserved.
//

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
