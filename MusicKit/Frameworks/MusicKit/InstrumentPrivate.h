/*
  $Id$
  Defined In: The MusicKit

  Original Author: David Jaffe
 
  Copyright (c) 1988-1992, NeXT Computer, Inc. All rights reserved.
  Portions Copyright (c) 1999, The MusicKit Project.
*/
#ifndef __MK__Instrument_H___
#define __MK__Instrument_H___

#import "NoteReceiverPrivate.h"
#import "MKInstrument.h"

@interface MKInstrument(Private)

- _realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver;
- _afterPerformance;

@end

#endif
