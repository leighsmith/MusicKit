/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:54  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__NoteReceiver_H___
#define __MK__NoteReceiver_H___

#import "MKNoteReceiver.h"

@interface MKNoteReceiver(Private)

-_setOwner:obj;
-(void)_setData:(void *)anObj ;
-(void *)_getData;

@end



#endif
