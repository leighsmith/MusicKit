/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.4  2005/05/09 15:52:55  leighsmith
  Converted headerdoc comments to doxygen comments

  Revision 1.3  2002/05/01 14:27:54  sbrandon
  Defines the (private) PluginSupport category that contains addPlugin:

  Revision 1.2  1999/07/29 01:25:57  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__Score_H___
#define __MK__Score_H___

#import "MKScore.h"

@interface MKScore (Private)

+(BOOL)_isUnarchiving;
-_newFilePartWithName:(NSString *)name;

@end

@interface MKScore (PluginSupport)
/*!
 @param  a plugin object that has been loaded into the MusicKit
 @return void.
*/
+ (void) addPlugin: (id) plugin;
@end


#endif
