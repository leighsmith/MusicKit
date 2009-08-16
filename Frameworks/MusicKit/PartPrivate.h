/*
  $Id$
  Defined In: The MusicKit

  Description:
    Method declarations for private category of MKPart.

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2005 The MusicKit Project.
*/
#ifndef __MK__Part_H___
#define __MK__Part_H___

#import "MKPart.h"

@interface MKPart(Private)

- (void) _setNoteSender: (MKNoteSender *) aNS;
- (MKNoteSender *) _noteSender;
- (void) _unsetScore;
- _addPerformanceObj: (MKPerformer *) aPerformer;
- _removePerformanceObj: (MKPerformer *) aPerformer;
- (MKScore *) _setScore: (MKScore *) newScore;
- (void) _mapTags: (NSMutableDictionary *) aHashTable;

@end

#endif
