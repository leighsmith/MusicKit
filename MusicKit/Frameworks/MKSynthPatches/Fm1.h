/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    (See discussion below)

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.2  2001/09/08 20:22:09  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

*/
/*!
  @class Fm1
  @discussion
  
  This class is just like Fm1i but overrides the interpolating osc
  with a non-interpolating osc. Thus, it is slightly less expensive than
  Fm1i.
*/
#ifndef __MK_Fm1_H___
#define __MK_Fm1_H___

#import "Fm1i.h"

@interface Fm1:Fm1i
{
}

/*!
  @method patchTemplateFor:
  @param  aNote is an id.
  @result Returns an id.
  @discussion  Returns a template using the non-interpolating osc.
*/
+patchTemplateFor:aNote;

@end

#endif
