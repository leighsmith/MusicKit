/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:57  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__ScoreRecorder_H___
#define __MK__ScoreRecorder_H___

#import "MKScoreRecorder.h"

@interface MKScoreRecorder(Private)

-(void)_firstNote:aNote;
-_afterPerformance;

@end



#endif
