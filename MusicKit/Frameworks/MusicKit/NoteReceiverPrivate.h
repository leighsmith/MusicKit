#ifndef __MK__NoteReceiver_H___
#define __MK__NoteReceiver_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#import "MKNoteReceiver.h"

@interface MKNoteReceiver(Private)

-_setOwner:obj;
-(void)_setData:(void *)anObj ;
-(void *)_getData;

@end



#endif
