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
   @defgroup FrequencyModulationSynthesis Frequency Modulation Synthesis
*/
/*!
  @class Fm1
  @ingroup FrequencyModulationSynthesis
  @brief Like <b>Fm1i</b> but with a non-interpolating (drop-sample) oscillator.
  
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
  @param  aNote is an id.
  @return Returns an id.
  @brief  Returns a template using the non-interpolating osc.

  
*/
+patchTemplateFor: (MKNote *) aNote;

@end

#endif
