#ifndef __MK_Fm1_H___
#define __MK_Fm1_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* This class is just like Fm1i but overrides the interpolating osc
   with a non-interpolating osc. Thus, it is slightly less expensive than
   Fm1i. */

#import "Fm1i.h"

@interface Fm1:Fm1i
{
}

+patchTemplateFor:aNote;
/* Returns a template using the non-interpolating osc. */

@end

#endif
