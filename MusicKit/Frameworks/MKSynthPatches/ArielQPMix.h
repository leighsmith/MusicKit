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
  @class ArielQPMix
  @discussion

<b>ArielQPMix</b> is a simple SynthPatch designed to be used with the Ariel
QuintProcessor.  Instantiating an instance of <b>ArielQPMix</b> causes the sound
output from the four satellite DSPs to be summed into the output of the hub DSP.
<b>ArielQPMix</b> has no parameters, no methods and no 
*/
#ifndef __MK_ArielQPMix_H___
#define __MK_ArielQPMix_H___
#import <MusicKit/MKSynthPatch.h>

@interface ArielQPMix:MKSynthPatch
{
}

@end
#endif
