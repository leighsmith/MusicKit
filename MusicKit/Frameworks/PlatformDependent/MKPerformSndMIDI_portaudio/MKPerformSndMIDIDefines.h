#
#   $Id$
#   Defined In: The MusicKit
#
#  Description:
#    Defines for MKPerformSndMIDI to facilitate dll creation on Win32
#
#  Original Author: Stephen Brandon <stephen@brandonitconsulting.co.uk>
#
#  31 Oct 2001, Copyright (c) 2001 Stephen Brandon.
#
#  Permission is granted to use and modify this code for commercial and non-
#  commercial purposes so long as the author attribution and this copyright
#  message remains intact and accompanies all derived code.




#ifndef __MKPerformSndMIDIDefines_INCLUDE
#define __MKPerformSndMIDIDefines_INCLUDE

#if BUILD_libMKPerformSndMIDI_DLL
#  define PERFORM_API  __declspec(dllexport)
#  define PERFORM_DECLARE __declspec(dllexport)
#elif libMKPerformSndMIDI_ISDLL
#  define PERFORM_API  extern __declspec(dllimport)
#  define PERFORM_DECLARE __declspec(dllimport)
#else
#  define PERFORM_API extern
#  define PERFORM_DECLARE
#endif

#endif /* __MKPerformSndMIDIDefines_INCLUDE */
