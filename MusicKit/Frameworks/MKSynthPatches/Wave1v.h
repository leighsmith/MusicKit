#ifndef __MK_Wave1v_H___
#define __MK_Wave1v_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* This class is just like Wave1vi but overrides the interpolating osc
   with a non-interpolating osc. Thus, it is slightly less expensive than
   Wave1vi. */

#import "Wave1vi.h"

@interface Wave1v:Wave1vi
{
}

+patchTemplateFor:aNote;

@end

#endif
