/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
*/
/*
Modification history:

  $Log$
  Revision 1.3  2001/09/06 21:27:47  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.2  1999/07/29 01:25:43  leigh
  Added Win32 compatibility, CVS logs, SBs changes


  daj/04/23/90 - Created from _musickit.h 
*/
#ifndef __MK__Envelope_H___
#define __MK__Envelope_H___

#import "MKEnvelope.h"

/* MKEnvelope functions. */
extern MKEnvStatus _MKGetEnvelopeNth(id self,int n,double *xPtr,double *yPtr, double *smoothingPtr);

#endif
