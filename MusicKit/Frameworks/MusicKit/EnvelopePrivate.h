/*
 $Id$
 Defined In: The MusicKit
 
 Description:
 This is the private header for the MusicKit Envelope functions which are not exported as part of the library.
 
 Original Author: David Jaffe
 
 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Portions Copyright (c) 1999-2006 The MusicKit Project.
 */
/*
  Modification history prior to CVS import:
 
  daj/04/23/90 - Created from _musickit.h 
 */
#ifndef __MK__Envelope_H___
#define __MK__Envelope_H___

#import "MKEnvelope.h"

/* MKEnvelope functions. */
extern MKEnvStatus _MKGetEnvelopeNth(MKEnvelope *self, int n, double *xPtr, double *yPtr, double *smoothingPtr);

#endif
