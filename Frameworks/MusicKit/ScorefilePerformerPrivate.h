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
#ifndef __MK__ScorefilePerformer_H___
#define __MK__ScorefilePerformer_H___

#import "MKScorefilePerformer.h"
@interface MKScorefilePerformer(Private)

-_newFilePartWithName:(NSString *)name;
-_elements;
-_setInfo:aInfo;

@end



#endif
