#ifndef __MK__Instrument_H___
#define __MK__Instrument_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#ifndef __INSTRUMENT_H
#define __INSTRUMENT_H

#import "NoteReceiverPrivate.h"
#import "MKInstrument.h"

@interface MKInstrument(Private)

-_realizeNote:aNote fromNoteReceiver:aNoteReceiver;
-_afterPerformance;

@end

#endif __INSTRUMENT_H



#endif
