/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:43  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__Instrument_H___
#define __MK__Instrument_H___

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
