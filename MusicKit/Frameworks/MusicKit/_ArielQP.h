/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:58  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__ArielQP_H___
#define __MK__ArielQP_H___

#import "ArielQP.h"

@interface ArielQP(Private)
-_setSatSoundIn:(BOOL)yesOrNo;
@end

@interface ArielQPSat(Private)
-_setHubSoundOut:(BOOL)yesOrNo;
@end



#endif
