/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
  This is the main public include file that will include all other class header files.
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:54  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_musickit_H___
#define __MK_musickit_H___

#ifndef MUSICKIT_H
#define MUSICKIT_H

 /* Include files outside of the Music Kit. */
#import <objc/objc.h>           /* Contains nil, etc. */
//#import <streams/streams.h>     /* Contains NXStream, etc. */
//#import <math.h>                /* Contains MAXINT, etc. */
// These used to be in 3.3 ansi/math.h but are no longer
// However they are in System.framework on Win32 which is typically #imported afterwards...sigh
#if !defined(MAXSHORT) && !defined(WIN32)
#define MAXSHORT ((short)0x7fff)
#endif
#if !defined(MAXINT)
#define MAXINT  ((int)0x7fffffff)       /* max pos 32-bit int */
#endif

 /* Music Kit include files */
#import "noDVal.h"              /* Type double utilities */
//#import "NSErrors.h"              /* Error codes, debug flags and functions. */
#import "errors.h"              /* Error codes, debug flags and functions. */
#import "names.h"               /* Various name tables */
#import "midiTranslation.h"     /* Note<->MIDI translation */
#import "classFuncs.h"          /* Stand-in classes */

 /*
  * The following magic number appears as the first 4 bytes of the optimized 
  * scorefile (".playscore" file extension). It is used for type checking and 
  * byte ordering information.
  */
#define MK_SCOREMAGIC ((int)0x2e706c61)

/* Music Kit classes. */
#import "ArielQP.h"
#import "MKConductor.h"
#import "DSPSerialPortDevice.h"
#import "MKEnvelope.h"
#import "MKFilePerformer.h"
#import "MKFileWriter.h"
#import "MKInstrument.h"
#import "MKMidi.h"
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
#import "MKSamples.h"
#import "MKScore.h"
#import "MKScorePerformer.h"
#import "MKScoreRecorder.h"
#import "MKScorefilePerformer.h"
#import "MKScorefileWriter.h"
#import "MKSynthData.h"
#import "MKSynthInstrument.h"
#import "MKSynthPatch.h"
#import "MKTuningSystem.h"
#import "MKUnitGenerator.h"
#import "MKWaveTable.h"
#import "scorefileObject.h"


#endif MUSICKIT_H



#endif
