/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.3  2005/05/14 03:27:27  leighsmith
  Clean up of parameter names to correct doxygen warnings

  Revision 1.2  1999/07/29 01:25:56  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__ScorePerformer_H___
#define __MK__ScorePerformer_H___

#import "MKScorePerformer.h"

@interface MKScorePerformer(Private)

-_partPerformerDidDeactivate: (id) sender;
-_deactivate;

@end



#endif
