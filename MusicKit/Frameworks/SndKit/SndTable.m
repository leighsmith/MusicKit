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

#import "Snd.h"
#import "SndTable.h"

static SndTable* defaultSndTable = nil;

@implementation SndTable

////////////////////////////////////////////////////////////////////////////////
// defaultSndTable
////////////////////////////////////////////////////////////////////////////////

+ defaultSndTable
{
  if (defaultSndTable == nil)
    defaultSndTable = [SndTable new];
  return [[defaultSndTable retain] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  self = [super init];
  if (self) {
    if (nameTable != nil)
      nameTable = [[NSMutableDictionary alloc] initWithCapacity:10];
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  if (nameTable)
    [nameTable release];
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// soundNamed:
// Does not name sound, or add to name table.
////////////////////////////////////////////////////////////////////////////////

- soundNamed: (NSString *) aName
{
    NSArray *libraryDirs = [NSArray arrayWithObject: @"."];
    NSArray *sndFileExtensions = [Snd soundFileExtensions];
    int directoryIndex;
    id retSnd = [nameTable objectForKey: aName];
    
    if (retSnd)
	return [[retSnd retain] autorelease];

    [libraryDirs arrayByAddingObjectsFromArray: NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES)];

    for(directoryIndex = 0; directoryIndex < [libraryDirs count]; directoryIndex++) {
	NSString *soundLibraryPath = [[libraryDirs objectAtIndex: directoryIndex] stringByAppendingPathComponent: @"Sounds"];
	NSBundle *soundLibraryBundle = (directoryIndex == 0) ? [NSBundle mainBundle] : [NSBundle bundleWithPath: soundLibraryPath];
	
	if (soundLibraryBundle) {
	    int extensionIndex;

	    for(extensionIndex = 0; extensionIndex < [sndFileExtensions count]; extensionIndex++) {
		NSString *sndFileExtension = [sndFileExtensions objectAtIndex: extensionIndex];
		NSString *path = [soundLibraryBundle pathForResource: aName ofType: sndFileExtension];

		if (path != nil) {
		    Snd *newSound = [[Snd alloc] initFromSoundfile: path];
		    
		    if (newSound) {
			return [newSound autorelease];
		    }
		}
	    }
	}
    }
    return nil;
}

////////////////////////////////////////////////////////////////////////////////
// findSoundFor:
////////////////////////////////////////////////////////////////////////////////

- findSoundFor:(NSString *)aName
{
  return [self soundNamed: aName];
}

////////////////////////////////////////////////////////////////////////////////
// addName:sound:
////////////////////////////////////////////////////////////////////////////////

- addName:(NSString *)aname sound:aSnd
{
  if ([nameTable objectForKey:aname]) return nil; /* already exists */
  if (!aSnd) return nil;
  [(Snd *)aSnd setName:aname];
  [nameTable setObject:aSnd forKey:aname];
  return aSnd;
}

////////////////////////////////////////////////////////////////////////////////
// addName:fromSoundfile:
////////////////////////////////////////////////////////////////////////////////

- addName:(NSString *)aname fromSoundfile:(NSString *)filename
{
  Snd *newSnd;
  if ([nameTable objectForKey:aname]) return nil; /* already exists */
  newSnd = [[Snd alloc] initFromSoundfile:filename];
  if (!newSnd) return nil;
  [Snd addName:aname sound:newSnd];
  return [newSnd autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// addName:fromSection:
////////////////////////////////////////////////////////////////////////////////

- addName:(NSString *)aname fromSection:(NSString *)sectionName
{
  printf("Snd: +addName:fromSection: obsolete, not implemented\n");
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// addName:fromBundle:
////////////////////////////////////////////////////////////////////////////////

- addName:(NSString *)aName fromBundle:(NSBundle *)aBundle
{
  BOOL found;
  Snd *newSound;
  NSString *path;
  if (!aBundle) return nil;
  if (!aName) return nil;
  if (![aName length]) return nil;
  if ([nameTable objectForKey:aName]) return nil; /* already exists */
  found = ((path = [aBundle pathForResource:aName ofType: [Snd defaultFileExtension]]) != nil);
  if (found) {
    newSound = [[Snd alloc] initFromSoundfile: path];
    if (newSound) {
      [Snd addName: aName sound: newSound];
      return [newSound autorelease];
    }
  }
  return nil;
}

////////////////////////////////////////////////////////////////////////////////
// removeSoundForName:
////////////////////////////////////////////////////////////////////////////////

- (void)removeSoundForName: (NSString *) aname
{
  [nameTable removeObjectForKey: aname];
}

////////////////////////////////////////////////////////////////////////////////
// removeAllSounds
////////////////////////////////////////////////////////////////////////////////

- (void) removeAllSounds
{
  [nameTable removeAllObjects];
}

////////////////////////////////////////////////////////////////////////////////

@end
