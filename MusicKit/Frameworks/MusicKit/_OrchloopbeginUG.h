/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:26:00  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  4/23/90/daj - Flushed instance var and added arg to _pause: 
*/
#ifndef __MK__OrchloopbeginUG_H___
#define __MK__OrchloopbeginUG_H___

#import "MKUnitGenerator.h"

@interface _OrchloopbeginUG : MKUnitGenerator
{

}
+_setXArgsAddr:(int)xArgsAddr y:(int)yArgsAddr l:(int)lArgsAddr 
 looper:(int)looperWord;
-_unpause;
-_pause:(int)looperWord;
@end



#endif
