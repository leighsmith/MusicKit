/*
  $Id$
  Defined In: The MusicKit

  Description:
    This is the main public include file that will include all other class header files.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
  $Log$
  Revision 1.10  2001/05/12 09:28:36  sbrandon
  - GNUSTEP: don't import ArielQP.h or DSPSerialPortDevice.h

  Revision 1.9  2000/10/05 08:05:47  skot
  Added fastFFt.h

  Revision 1.8  2000/06/13 17:46:24  leigh
  Added SMF magic number definition

  Revision 1.7  2000/06/09 03:18:06  leigh
  Replaced objc.h with Foundation.h

  Revision 1.6  2000/04/16 04:26:34  leigh
  Renamed scorefileObject.h to MKScorefileObject.h

  Revision 1.5  2000/02/03 19:13:48  leigh
  objective-C declaration added if compiling with ObjC++ to ensure correct name-mangling

  Revision 1.4  1999/10/08 19:53:43  leigh
  MAXSHORT defined irrespective of WIN32, MKSamplerInstrument.h included

  Revision 1.3  1999/09/20 17:30:01  leigh
  Added midi_spec.h, cleaned up documentation.

  Revision 1.2  1999/07/29 01:25:54  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_musickit_H___
#define __MK_musickit_H___

#ifdef __cplusplus
extern "Objective-C" {
#endif

#ifndef MUSICKIT_H
#define MUSICKIT_H

/* Include files outside of the Music Kit. */
#import <Foundation/Foundation.h>           /* Contains nil, etc. */

// These used to be in NS3.3 ansi/math.h but are no longer
// However they are in System.framework on Win32 which is typically #imported afterwards...sigh
#if !defined(MAXSHORT) // && !defined(WIN32)
#define MAXSHORT ((short)0x7fff)
#endif
#if !defined(MAXINT)
#define MAXINT  ((int)0x7fffffff)       /* max pos 32-bit int */
#endif

 /* Music Kit include files */
#import "noDVal.h"              /* Type double utilities */
#import "errors.h"              /* Error codes, debug flags and functions. */
#import "names.h"               /* Various name tables */
#import "midiTranslation.h"     /* Note<->MIDI translation */
#import "classFuncs.h"          /* Stand-in classes */
#import "midi_spec.h"		/* standard MIDI definitions */ 

 /*
  * The following magic number appears as the first 4 bytes of the optimized 
  * scorefile (".playscore" file extension). It is used for type checking and 
  * byte ordering information.
  */
#define MK_SCOREMAGIC ((int)0x2e706c61)  // ".pla"
#define MK_MIDIMAGIC  ((int)1297377380)  // "MThd"

/* Music Kit classes. */
#ifndef GNUSTEP
# import "ArielQP.h"
# import "DSPSerialPortDevice.h"
#endif
#import "MKConductor.h"
#import "MKEnvelope.h"
#import "MKFilePerformer.h"
#import "MKFileWriter.h"
#import "MKInstrument.h"
#import "MKMidi.h"
#import "MKMixerInstrument.h"
#import "MKNote.h"
#import "MKNoteFilter.h"
#import "MKNoteReceiver.h"
#import "MKNoteSender.h"
#import "MKMTCPerformer.h"
#import "MKOrchestra.h"
#import "MKPart.h"
#import "MKPartPerformer.h"
#import "MKPartRecorder.h"
#import "MKPatchTemplate.h"
#import "MKPartials.h"
#import "MKPerformer.h"
#import "MKTimbre.h"
#import "MKSamplerInstrument.h"
#import "MKSamples.h"
#import "MKScore.h"
#import "MKScorePerformer.h"
#import "MKScoreRecorder.h"
#import "MKScorefileObject.h"
#import "MKScorefilePerformer.h"
#import "MKScorefileWriter.h"
#import "MKSynthData.h"
#import "MKSynthInstrument.h"
#import "MKSynthPatch.h"
#import "MKTuningSystem.h"
#import "MKUnitGenerator.h"
#import "MKWaveTable.h"
#import "fastFFT.h"

#endif MUSICKIT_H

#ifdef __cplusplus
}
#endif

#endif __MK_musickit_H___
