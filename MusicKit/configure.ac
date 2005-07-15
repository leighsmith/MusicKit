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
# TODO
# For now we require a working MKPerformSndMIDI library, but we
# could default to using MKPerformSndMIDI_silent for users who just want
# to crunch notes and not play anything. Likewise, we currently
# require libsndfile installed but eventually we should work out a
# way of compiling Snd.m when an entire category is missing. This
# could be really tough to do, however, since so many other SndKit
# classes depend on Snd.m.

AC_INIT(MusicKit, 5.5.0, leigh@leighsmith.com)
AC_REVISION($Id$)

AC_CONFIG_SRCDIR([Frameworks/SndKit/Snd.h])
AC_LANG(C)

# AC_ARGV_VAR(XCODEBUILD, [[Defines if xcodebuild exists (set to no
# to compile with GNUstep on MacOS X)]])

# Check if xcodebuild exists, if so we need to use Makefile.in.
# If xcodebuild does not exist, we need to use GNUmakefile.in.
AC_CHECK_PROG(XCODEBUILD, xcodebuild, yes, no)

# TODO The other alternative is to use AC_SUBST_FILE to construct
# Makefile appropriate to MacOS X or GNUstep, rather than selecting
# between two types of configuration file, which is fraught with danger. 
if test $XCODEBUILD == yes; then
   AC_SUBST(TOPLEVELBUILD, Makefile)
else
   AC_SUBST(TOPLEVELBUILD, GNUmakefile)
fi

# Check for an SGML translator for generating documentation.
# Currently openjade is our only option.
AC_CHECK_PROGS(SGMLTRANS, openjade)

AC_HEADER_STDC

# Check for pthreads (needed for portaudio)
AC_CHECK_LIB(pthread, pthread_create)

# Check if we have portaudio installed, if so, use MKPerformSndMIDI_portaudio
AC_CHECK_LIB(portaudio, Pa_Initialize)

# separately check the portaudio header was installed.
AC_CHECK_HEADERS(portaudio.h)

# These are used by lame and libshout but we check for them ourselves
# since we will want them for Ogg I/O ourselves soon.
AC_CHECK_LIB(ogg, ogg_stream_init)
AC_CHECK_LIB(vorbis, vorbis_info_init)

# Ensure that libsndfile must be installed.
AC_CHECK_LIB(sndfile, sf_open)
# if test $ac_cv_lib_sndfile_sf_open != yes; then
#   AC_MSG_ERROR([[libsndfile must be installed and is not.]])
# fi

# Will #if define out SndAudioProcessorMP3Encoder.m if LAME or
# shoutcast libraries aren't available.
AC_MSG_NOTICE([checking for MP3 encoding libraries])
AC_CHECK_LIB(shout, shout_open)
AC_CHECK_LIB(mp3lame, lame_init)

# Will #if define out SndMP3.m if HIP isn't available
AC_MSG_NOTICE([checking for MP3 decoding libraries])
AC_CHECK_LIB(mp3hip, hip_decode_init)

# Create configure headers to control which library headers are included.
AC_CONFIG_HEADERS(Frameworks/PlatformDependent/MKPerformSndMIDI_portaudio/MKPerformSndMIDIConfig.h \
                  Frameworks/SndKit/SndKitConfig.h \
                  Frameworks/MusicKit/MusicKitConfig.h)

# Configures a top-level GNUmakefile for GNUstep systems or a
# Makefile for MacOS X which then runs xcodebuild.
# Since only one top-level make file will be created, the appropriate
# file is selected when make is run.
AC_CONFIG_FILES($TOPLEVELBUILD \
		Frameworks/GNUmakefile
                Frameworks/PlatformDependent/MKPerformSndMIDI_portaudio/GNUmakefile.preamble \
                Frameworks/SndKit/GNUmakefile.preamble \
		Frameworks/MKDSP_Native/GNUmakefile.preamble \
		Frameworks/MusicKit/GNUmakefile.preamble \
		Documentation/Makefile)

AC_OUTPUT
