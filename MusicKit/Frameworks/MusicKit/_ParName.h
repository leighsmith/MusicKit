/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:26:00  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__ParName_H___
#define __MK__ParName_H___

#import <Foundation/NSObject.h>

#import "_MKParameter.h"

@interface _ParName : NSObject
{
    BOOL (*printfunc)(_MKParameter *param,NSMutableData *aStream,
		      _MKScoreOutStruct *p);
    int par;
    char *s;
}

@end



#endif
