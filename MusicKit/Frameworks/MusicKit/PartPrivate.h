/*
  $Id$
  Defined In: The MusicKit

  Description:
    Method declarations for private category of MKPart.

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University 
*/
/*
  $Log$
  Revision 1.3  2000/05/06 00:28:27  leigh
  Converted _mapTags to NSMutableDictionary

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
-(void) _mapTags: (NSMutableDictionary *) aHashTable;

@end



#endif
