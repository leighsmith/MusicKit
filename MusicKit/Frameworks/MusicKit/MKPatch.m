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
/*
  $Log$
  Revision 1.6  2003/08/04 21:14:33  leighsmith
  Changed typing of several variables and parameters to avoid warnings of mixing comparisons between signed and unsigned values.

  Revision 1.5  2002/01/24 16:55:57  sbrandon
  fixed nasty release bug in findFilenameForClassname

  Revision 1.4  2001/09/08 21:53:16  leighsmith
  Prefixed MK for UnitGenerators and SynthPatches

  Revision 1.3  2001/04/20 02:57:11  leighsmith
  Improved variable naming

  Revision 1.2  2001/03/12 01:55:38  leigh
  Moved patch locations inside the class implementation since they shouldn't be accessible to apps at compile time, only at run time

  Revision 1.1  2001/03/06 21:47:32  leigh
  Abstracted patch loading from MKSynthPatches into MKPatch

*/
#import "MKPatch.h"

#define MK_SYNTHPATCH_DIR @"MusicKit/SynthPatches/"
#define MK_PATCH_EXTENSION @"bundle"

@implementation MKPatch

// Nothing for now, eventually we could incorporate nib loading and display for each MKPatch.

@end

@implementation MKPatch(PatchLoad)

static NSString *findFilenameForClassname(NSString *className)
    /* Returns filename or nil if failure. Assumes name is non-NULL. */
{
    NSString *filename;
    NSString *ext;
    ext = [className pathExtension];
    if ([ext length])  {
        if (![ext isEqualToString: MK_PATCH_EXTENSION])
            filename = [className stringByAppendingPathExtension: MK_PATCH_EXTENSION];
        else
            filename = [NSString stringWithString: className];
    }
    else filename = [NSString stringWithString: className];

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

+ findPatchClass: (NSString *) className
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
