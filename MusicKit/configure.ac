#
# MusicKit Configuration 
#
# Process this file with autoconf to produce a configure script.
#
# Leigh Smith <leigh@leighsmith.com>
# 
# Copyright (c) 2005, The MusicKit Project.  All rights reserved.
#
# Permission is granted to use and modify this code for commercial and 
# non-commercial purposes so long as the author attribution and copyright 
# messages remain intact and accompany all relevant code.
#

AC_INIT(MusicKit,5.5.0,leigh@leighsmith.com)
AC_REVISION($Id$)

AC_CONFIG_SRCDIR([Frameworks/SndKit/Snd.h])
AC_LANG(C)

# Create configure headers to control which library headers are included.
AC_CONFIG_HEADERS(Frameworks/SndKit/SndKitConfig.h \
                  Frameworks/MusicKit/MusicKitConfig.h)

# Needs to create a GNUmakefile for GNUstep, and possibly a makefile which
# then runs xcodebuild on MacOS X.
AC_CONFIG_FILES(Makefile \
                Frameworks/PlatformDependent/MKPerformSndMIDI_portaudio/GNUmakefile.preamble \
                Frameworks/SndKit/GNUmakefile)

AC_HEADER_STDC

# check openjade for generating documentation
AC_CHECK_PROG(OPENJADE, openjade, yes, no)

AC_MSG_NOTICE([checking libraries installed, determining which classes to compile])
AC_CHECK_LIB(portaudio, Pa_Initialize)
# MKPerformSndMIDI_portaudio

# These are used by lame and libshout but we check for them ourselves
# since we will want them for Ogg I/O ourselves soon.
AC_CHECK_LIB(ogg, ogg_stream_init)
AC_CHECK_LIB(vorbis, vorbis_info_init)

# SndAudioProcessorRecorder & SndFileIO.m
AC_CHECK_LIB(sndfile, sf_open)

# Will #if define out SndAudioProcessorMP3Encoder.m if LAME or
# shoutcast libraries aren't available.
AC_MSG_NOTICE([checking for MP3 encoding libraries])
AC_CHECK_LIB(shout, shout_open)
AC_CHECK_LIB(mp3lame, lame_init)

# Will #if define out SndMP3.m if HIP isn't available
AC_MSG_NOTICE([checking for MP3 decoding libraries])
AC_CHECK_LIB(mp3hip, hip_decode_init)


AC_OUTPUT
