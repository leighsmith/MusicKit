#ifndef __MK__Part_H___
#define __MK__Part_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
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
