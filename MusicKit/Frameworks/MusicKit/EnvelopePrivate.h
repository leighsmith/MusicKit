#ifndef __MK__Envelope_H___
#define __MK__Envelope_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*  Modification history:

    daj/04/23/90 - Created from _musickit.h 

*/

#import "MKEnvelope.h"

/* Envelope functions. */
extern MKEnvStatus _MKGetEnvelopeNth(id self,int n,double *xPtr,double *yPtr,
				     double *smoothingPtr);



#endif
