/*
 *  $Id$
 *  Defined In: The MusicKit
 *
 * Description:
 *   Defines for MKDSP to facilitate dll creation on Win32
 *
 * Original Author: Stephen Brandon <stephen@brandonitconsulting.co.uk>
 *
 * 31 Oct 2001, Copyright (c) 2001 Stephen Brandon.
 *
 * Permission is granted to use and modify this code for commercial and non-
 * commercial purposes so long as the author attribution and this copyright
 * message remains intact and accompanies all derived code.
 *
 */

#ifndef __MKDSPDefines_INCLUDE
#define __MKDSPDefines_INCLUDE

#if BUILD_libMKDSP_DLL
#  define MKDSP_API  __declspec(dllexport)
#  define MKDSP_DECLARE __declspec(dllexport)
#elif libMKDSP_ISDLL
#  define MKDSP_API  extern __declspec(dllimport)
#  define MKDSP_DECLARE __declspec(dllimport)
#else
#  define MKDSP_API extern
#  define MKDSP_DECLARE
#endif

#endif /* __MKDSPDefines_INCLUDE */
