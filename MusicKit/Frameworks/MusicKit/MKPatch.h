/*
  $Id$
  Defined In: The MusicKit

  Description:
    Each MKPatch is an abstracted superclass of synthesis patch descriptions independent
    of the mechanism used to synthesize. Therefore, it holds synthesis independent patch
    methods, such as patch loading from bundles.
    
  Original Author: Leigh M. Smith <leigh@tomandandy.com>

  Copyright (c) 2001 tomandandy, Inc.
  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and this copyright message remains intact
  and accompanies all derived code.
*/
/*
  $Log$
  Revision 1.1  2001/03/06 21:47:32  leigh
  Abstracted patch loading from SynthPatches into MKPatch

*/
#import <Foundation/Foundation.h>

#define MK_SYNTHPATCH_DIR @"MusicKit/SynthPatches/"
#define MK_PATCH_EXTENSION @"bundle"

@interface MKPatch : NSObject
{
}

@end

@interface MKPatch(PatchLoad)

+ findPatchClass: (NSString *) className;
 /* This method looks for a class with the specified name.  
    If found, it is returned.
    If not found, this method tries to dynamically load the class. 
    The standard library directories are searched for a file named <name>.bundle.
    On MacOS X these would be:

    1. ./
    2. ~/Library/MusicKit/SynthPatches/
    3. /Library/MusicKit/SynthPatches/
    4. /Network/Library/MusicKit/SynthPatches/
    5. /System/Library/MusicKit/SynthPatches/

    If a file is found, it is dynamically loaded.  If the whole process
    is successful, the newly loaded class is returned.  Otherwise, nil
    is returned.  If the file is found but the link fails, an error is printed
    to the stream returned by MKErrorStream() (this defaults to stderr). You
    can change it to another stream with MKSetErrorStream().
    */

@end