#ifndef __MK__Performer_H___
#define __MK__Performer_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 
Modification history:

  03/24/90/daj - Added pauseFor: instance variable.
*/

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
