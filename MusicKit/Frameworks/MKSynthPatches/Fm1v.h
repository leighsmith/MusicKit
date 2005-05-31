/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    (See discussion below)

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2005, The MusicKit Project.
*/
/*!
  @class Fm1v
  @ingroup FrequencyModulationSynthesis
  @brief Like <b>Fm1vi</b> but with a non-interpolating osc
  
  This class is just like Fm1vi but overrides the interpolating osc
  with a non-interpolating osc. Thus, it is slightly less expensive than
  Fm1vi. 
*/
#ifndef __MK_Fm1v_H___
#define __MK_Fm1v_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */

#import "Fm1vi.h"

@interface Fm1v:Fm1vi
{
}

/*!
  @param  aNote is an id.
  @return Returns an id.
  @brief  Returns a template using the non-interpolating osc.

  
*/
+patchTemplateFor: (MKNote *) aNote;

@end

#endif
