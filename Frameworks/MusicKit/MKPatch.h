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
/*!
  @class MKPatch
  @brief Each MKPatch is an abstracted superclass of synthesis patch descriptions independent
  of the mechanism used to synthesize. Therefore, it holds synthesis independent patch
  methods, such as patch loading from bundles.
*/
#import <Foundation/Foundation.h>

@interface MKPatch : NSObject
{
}

@end

@interface MKPatch(PatchLoad)

/*!
  @brief This method looks for a class with the specified name.

  If found, it is returned.
  If not found, this method tries to dynamically load the class. 
  The standard library directories are searched for a file named <name>.bundle.
  On MacOS X these would be:

  <ol>
  <li>./</li>
  <li>~/Library/MusicKit/SynthPatches/</li>
  <li>/Library/MusicKit/SynthPatches/</li>
  <li>/Network/Library/MusicKit/SynthPatches/</li>
  <li>/System/Library/MusicKit/SynthPatches/</li>
  </ol>

  If the file is found but the link fails, an error is printed
  to the stream returned by MKErrorStream() (this defaults to stderr). You
  can change it to another stream with MKSetErrorStream().
  @param  className is an NSString instance.
  @return Returns the Class of the MKSynthPatch. If a file is found, it is dynamically loaded.
   If the whole process is successful, the newly loaded class is returned.  Otherwise, nil is returned.
*/
+ (Class) findPatchClass: (NSString *) className;

@end
