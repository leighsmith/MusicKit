/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:26:02  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  daj/04/23/90 - Created from _musickit.h 
*/
#ifndef __MK__error_H___
#define __MK__error_H___

#define _MK_ERRMSG static char * 

#import "errors.h"

extern NSString * _MKGetErrStr(int errCode);
    /* Returns the error string for the given code or "unknown error" if
       the code is not one of the  MKErrno enums. 
       The string is not copied. Note that some of the strings have printf-
       style 'arguments' embeded. Thus care must be taken in writeing them. */
extern char *_MKErrBuf();


#endif
