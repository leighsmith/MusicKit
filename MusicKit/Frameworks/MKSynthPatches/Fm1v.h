#ifndef __MK_Fm1v_H___
#define __MK_Fm1v_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* This class is just like Fm1vi but overrides the interpolating osc
   with a non-interpolating osc. Thus, it is slightly less expensive than
   Fm1vi. */

#import "Fm1vi.h"

@interface Fm1v:Fm1vi
{
}

+patchTemplateFor:aNote;

@end

#endif
