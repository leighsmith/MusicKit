/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:55  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__Part_H___
#define __MK__Part_H___

#import "MKPart.h"

@interface MKPart(Private)

-(void)_setNoteSender: (MKNoteSender *) aNS;
- (MKNoteSender *) _noteSender;
-(void)_unsetScore;
-_addPerformanceObj:aPerformer;
-_removePerformanceObj:aPerformer;
-_setScore:(id)newScore;
-(void) _mapTags:aHashTable;

@end



#endif
