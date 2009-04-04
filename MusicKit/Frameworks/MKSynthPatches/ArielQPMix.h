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
/*!
  @brief Multiple DSP operation with the Ariel QuintProcessor board.
  
  <b>ArielQPMix</b> is a simple MKSynthPatch designed to be used with the Ariel
  QuintProcessor.  Instantiating an instance of <b>ArielQPMix</b> causes the sound
  output from the four satellite DSPs to be summed into the output of the hub DSP.
  <b>ArielQPMix</b> has no parameters, no methods and no instance variables.

  Keep in mind that <b>ArielQPMix</b> need not be used.  Instead, you may handle the
  sound streams from the four satellites in some other way.  For example, see the programming example
  <b>QP/QuintClusters</b>, which processes the satellites' output in a different way.
*/
#ifndef __MK_ArielQPMix_H___
#define __MK_ArielQPMix_H___
#import <MusicKit/MKSynthPatch.h>

@interface ArielQPMix: MKSynthPatch
{
}

@end
#endif
