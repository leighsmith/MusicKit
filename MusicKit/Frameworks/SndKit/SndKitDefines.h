/*
 *   $Id$
 *   Defined In: The MusicKit
 *
 *  Description:
 *    Defines for SndKit to facilitate dll creation on Win32
 *
 *  Original Author: Stephen Brandon <stephen@brandonitconsulting.co.uk>
 *
 *  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
 *
 *  Permission is granted to use and modify this code for commercial and non-
 *  commercial purposes so long as the author attribution and this copyright
 *  message remains intact and accompanies all derived code.
 *
 */

#ifndef __SndKitDefines_INCLUDE
#define __SndKitDefines_INCLUDE

#if BUILD_libSndKit_DLL
#  define SNDKIT_API  __declspec(dllexport)
#  define SNDKIT_DECLARE __declspec(dllexport)
#elif libSndKit_ISDLL
#  define SNDKIT_API  extern __declspec(dllimport)
#  define SNDKIT_DECLARE __declspec(dllimport)
#else
#  define SNDKIT_API extern
#  define SNDKIT_DECLARE
#endif

#endif /* __SndKitDefines_INCLUDE */
