/*
  $Id$
  Defined In: The MusicKit

  Description:
    This is the main public include file that will include all other class header files.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2003 The MusicKit Project.
*/

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
#import "fastFFT.h"

/* Music Kit classes. */
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
#import "MKPlugin.h"
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

#endif /* MUSICKIT_H */

#ifdef __cplusplus
}
#endif

