/*
  $Id$
  Defined In: The MusicKit

  Description:
    Each MKPatch 
    
  Original Author: Leigh M. Smith <leigh@tomandandy.com>

  Copyright (c) 2001 tomandandy, Inc.
  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and this copyright message remains intact
  and accompanies all derived code.
*/
#import "MKPatch.h"

#define MK_SYNTHPATCH_DIR @"MusicKit/SynthPatches/"
#define MK_PATCH_EXTENSION @"bundle"

@implementation MKPatch

// TODO Nothing for now, eventually we could incorporate nib loading and display for each MKPatch.

@end

@implementation MKPatch(PatchLoad)

static NSString *findFilenameForClassname(NSString *className)
    /* Returns filename or nil if failure. Assumes name is non-NULL. */
{
    NSString *filename;
    NSString *ext = [className pathExtension];

    if ([ext length])  {
        if (![ext isEqualToString: MK_PATCH_EXTENSION])
            filename = [className stringByAppendingPathExtension: MK_PATCH_EXTENSION];
        else
            filename = [NSString stringWithString: className];
    }
    else 
	filename = [NSString stringWithString: className];

    if (![filename isAbsolutePath]) {
        NSArray *libraryDirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
        unsigned int i;
        
        for(i = 0; i < [libraryDirs count]; i++) {
            NSString *absolutePath = [[[libraryDirs objectAtIndex: i] 
                                        stringByAppendingPathComponent: MK_SYNTHPATCH_DIR]
                                        stringByAppendingPathComponent: filename];
            if ([[NSFileManager defaultManager] isReadableFileAtPath: absolutePath]) 
                return absolutePath;
        }
        return nil;
    }
    return [[NSFileManager defaultManager] isReadableFileAtPath: filename] ? filename : nil;
}

static Class getClassWithoutWarning(NSString *clname)
/* sb: checks all loaded classes to see if we have the named class. Surely NSClassFromString()
 * would do exactly the same thing? (I've tried it for a couple of examples in gdb, and appears
 * to have the desired behaviour)
 */
{
    return NSClassFromString(clname);
}

+ (Class) findPatchClass: (NSString *) className
    /* The user can load in arbitrary bundles. */
{
    NSString *filename;
    NSBundle *bundleToLoad;
    Class loadedClass;
    
    loadedClass = getClassWithoutWarning(className);
    if (loadedClass != nil)
	return loadedClass;
    filename = findFilenameForClassname(className);
    if (filename == nil) 
	return nil;
    bundleToLoad = [NSBundle bundleWithPath: filename];
    if ((loadedClass = [bundleToLoad classNamed: className]) != nil)
        return loadedClass;
    else
        return nil;
}

@end
