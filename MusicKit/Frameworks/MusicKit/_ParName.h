/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.4  2002/04/15 14:32:30  sbrandon
  changed type of "s" ivar from char* to NSString and had to change all refs
  to it.

  Revision 1.3  1999/09/26 19:58:42  leigh
  Cleanup of documentation

  Revision 1.2  1999/07/29 01:26:00  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__ParName_H___
#define __MK__ParName_H___

#import <Foundation/NSObject.h>

#import "_MKParameter.h"

@interface _ParName : NSObject
{
    // printfunc is a function for writing the value of the par.
    // See _ParName.m for details.
    BOOL (*printfunc)(_MKParameter *param, NSMutableData *aStream, _MKScoreOutStruct *p);
    int par;    /* What parameter this is. */
    NSString *s;    /* Name of parameter */
}

@end

#endif
