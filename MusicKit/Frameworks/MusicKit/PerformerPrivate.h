/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
 Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:25:56  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  03/24/90/daj - Added pauseFor: instance variable.
*/
#ifndef __MK__Performer_H___
#define __MK__Performer_H___

#ifndef __PERFORMER_H
#define __PERFORMER_H

//#import "_NoteSender.h" redundant
#import "MKNoteSender.h"
#import "MKPerformer.h"

@interface MKPerformer(Private)

-_copyFromZone:(NSZone *)zone;

@end

#endif __PERFORMER_H



#endif
