#ifndef __MK__OrchloopbeginUG_H___
#define __MK__OrchloopbeginUG_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* Modification history:

   4/23/90/daj - Flushed instance var and added arg to _pause: 

*/
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
