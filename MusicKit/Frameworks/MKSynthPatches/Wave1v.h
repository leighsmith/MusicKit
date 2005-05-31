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
  @class Wave1v
  @ingroup WaveTableSynthesis
  @brief Wavetable synthesis with 1 non-interpolating (drop-sample) oscillator and
  random and periodic vibrato.
  
  This class is just like Wave1vi but overrides the interpolating osc
  with a non-interpolating osc. Thus, it is slightly less expensive than
  Wave1vi. 
*/

#ifndef __MK_Wave1v_H___
#define __MK_Wave1v_H___

#import "Wave1vi.h"

@interface Wave1v:Wave1vi
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
