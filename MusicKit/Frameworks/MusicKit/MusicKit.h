#ifndef __MK_musickit_H___
#define __MK_musickit_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 
    musickit.h 
    
    This file is part of the Music Kit.

  */
#ifndef MUSICKIT_H
#define MUSICKIT_H

 /* Include files outside of the Music Kit. */
#import <objc/objc.h>           /* Contains nil, etc. */
//#import <streams/streams.h>     /* Contains NXStream, etc. */
//#import <math.h>                /* Contains MAXINT, etc. */
// These used to be in 3.3 ansi/math.h but are no longer
#define MAXSHORT ((short)0x7fff)
#define MAXINT  ((int)0x7fffffff)       /* max pos 32-bit int */

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
