/*
  $Id$
  Defined In: The MusicKit

 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Portions Copyright (c) 1999-2004, The MusicKit Project.
 
 */
#ifndef __MK__NoteReceiver_H___
#define __MK__NoteReceiver_H___

#import "MKNoteReceiver.h"

@interface MKNoteReceiver(Private)

- _setOwner: obj;
- (void) _setData: (void *) anObj;
- (void *) _getData;

- _connect: (MKNoteSender *) aNoteSender;
- _disconnect: (MKNoteSender *) aNoteSender;

@end

#endif
