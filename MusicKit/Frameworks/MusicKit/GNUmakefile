#
#   $Id$
#   Defined In: The MusicKit
#
#  Description:
#    Makefile for GNUstep
#
#  Original Author: Stephen Brandon <stephen@pyrusmalus.com>
#
#  21 April 2001, Copyright (c) 2001 Stephen Brandon.
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

#Modification history:
# $Log$
# Revision 1.1  2001/05/12 09:07:25  sbrandon
# - first attempt at compilation on GNUSTEP. This makefile needs to be kept
#   in sync as much as possible with file additions/removals done on MacOSX.
#
#

# Install into the local root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_LOCAL_ROOT)

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

srcdir = .

# The framework to be compiled
FRAMEWORK_NAME = MusicKit

# The framework resource files and directories
$(FRAMEWORK_NAME)_RESOURCE_FILES = 

$(FRAMEWORK_NAME)_RESOURCE_DIRS = 

# The framework libraries to link against
#sb: not sure about this...
#$(FRAMEWORK_NAME)BUNDLE_LIBS = 


# The Bundle Objective-C source files to be compiled
$(FRAMEWORK_NAME)_OBJC_FILES = \
          MKConductor.m MKEnvelope.m\
          MKFilePerformer.m MKFileWriter.m MKInstrument.m MKMidi.m\
          MKMixerInstrument.m MKMTCPerformer.m MKNote.m MKNoteFilter.m\
          MKNoteReceiver.m MKNoteSender.m MKOrchestra.m MKPart.m\
          MKPartPerformer.m MKPartRecorder.m MKPartials.m\
          MKPartialsWaveshapingTable.m MKPatchConnection.m\
          MKPatchEntry.m MKPatchTemplate.m MKPerformer.m\
          MKSamplerInstrument.m MKSamples.m MKScore.m\
          MKScorePerformer.m MKScoreRecorder.m MKScorefilePerformer.m\
          MKScorefileWriter.m MKSynthData.m MKSynthInstrument.m\
          MKSynthPatch.m MKTimbre.m MKTuningSystem.m MKUnitGenerator.m\
          MKWaveTable.m OrchloopbeginUG.m _MKAppProxy.m _MKNameTable.m\
          _MTCHelper.m _OrchloopbeginUG.m _ParName.m _ScorefileVar.m\
          _SharedSynthInfo.m SynthPatchList.m conversion.m midifile.m\
          noteRecorderCFuncs.m parseMidi.m parseScore.m time.m\
          tokenNames.m utilities.m writeBinary.m writeMidi.m\
          writeScore.m #ArielQP.m DSPSerialPortDevice.m

$(FRAMEWORK_NAME)_C_FILES = fastFFT.c sin.c

# The framework installed header files
$(FRAMEWORK_NAME)_HEADER_FILES = \
         ConductorPrivate.h \
         EnvelopePrivate.h InstrumentPrivate.h MKConductor.h\
         MKConductorDelegate.h MKDeviceStatus.h MKEnvelope.h\
         MKFilePerformer.h MKFileWriter.h MKInstrument.h\
         MKMTCPerformer.h MKMidi.h MKMixerInstrument.h MKNote.h\
         MKNoteFilter.h MKNoteReceiver.h MKNoteSender.h MKOrchestra.h\
         MKPart.h MKPartPerformer.h MKPartRecorder.h MKPartials.h\
         MKPatchConnection.h MKPatchEntry.h MKPatchTemplate.h\
         MKPerformer.h MKPerformerDelegate.h MKSamplerInstrument.h\
         MKSamples.h MKScore.h MKScorePerformer.h MKScoreRecorder.h\
         MKScorefileObject.h MKScorefilePerformer.h MKScorefileWriter.h\
         MKSynthData.h MKSynthInstrument.h MKSynthPatch.h MKTimbre.h\
         MKTuningSystem.h MKUnitGenerator.h MKWaveTable.h MidiPrivate.h\
         MusicKit.h NotePrivate.h NoteReceiverPrivate.h\
         OrchestraPrivate.h OrchloopbeginUG.h PartPerformerPrivate.h\
         PartPrivate.h PartRecorderPrivate.h PartialsPrivate.h\
         PatchTemplatePrivate.h PerformerPrivate.h\
         ScorePerformerPrivate.h ScorePrivate.h ScoreRecorderPrivate.h\
         ScorefilePerformerPrivate.h SynthDataPrivate.h\
         SynthInstrumentPrivate.h SynthPatchPrivate.h SynthPatchList.h\
         TuningSystemPrivate.h UnitGeneratorPrivate.h _ArielQP.h\
         _DSPMK.h _MKAppProxy.h _MKNameTable.h _MKParameter.h\
         _MTCHelper.h _OrchloopbeginUG.h _ParName.h _ScorefileVar.h\
         _SharedSynthInfo.h _error.h _midi.h _musickit.h\
         _noteRecorder.h _scorefile.h _time.h classFuncs.h dsp_types.h\
         dspwrap.h errors.h keynums.h midiTranslation.h midi_spec.h\
         midifile.h names.h noDVal.h orch.h params.h pitches.h\
         timeunits.h tokens.h fastFFT.h \
		 #ArielQP.h DSPSerialPortDevice.h


SRCS = $(LIBRARY_NAME:=.m)
HDRS = $(LIBRARY_NAME:=.h)


-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/framework.make

-include Makefile.postamble
