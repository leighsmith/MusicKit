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
  Revision 1.4  2001/09/10 17:38:28  leighsmith
  Added abstracts from IntroSynthPatches.rtf

  Revision 1.3  2001/09/08 21:22:05  leighsmith
  Added doco that mysteriously was removed

  Revision 1.2  2001/09/08 20:22:09  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

*/
/*!
  @class ArielQPMix
  @abstract Multiple DSP operation with the Ariel QuintProcessor board.
  @discussion

<b>ArielQPMix</b> is a simple MKSynthPatch designed to be used with the Ariel
QuintProcessor.  Instantiating an instance of <b>ArielQPMix</b> causes the sound
output from the four satellite DSPs to be summed into the output of the hub DSP.
<b>ArielQPMix</b> has no parameters, no methods and no instance variables.

Keep in mind that <b>ArielQPMix</b> need not be
used.  Instead, you may handle the sound streams from the four satellites in
some other way.   For example, see the programming example
<b>QP/QuintClusters</b>, which processes the satellites' output in a different
way.
*/
#ifndef __MK_ArielQPMix_H___
#define __MK_ArielQPMix_H___
#import <MusicKit/MKSynthPatch.h>

@interface ArielQPMix: MKSynthPatch
{
}

@end
#endif