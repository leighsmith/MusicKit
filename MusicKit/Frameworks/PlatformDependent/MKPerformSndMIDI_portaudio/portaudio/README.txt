README for PortAudio
Implementations for PC DirectSound and Mac SoundManager

/*
 * PortAudio Portable Real-Time Audio Library
 * Latest Version at: http://www.softsynth.com/portaudio/
 * DirectSound Implementation
 * Copyright (c) 1999-2000 Phil Burk and Ross Bencina
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * Any person wishing to distribute modifications to the Software is
 * requested to send the modifications to the original developer so that
 * they can be incorporated into the canonical version.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
 * ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */

PortAudio is a portable audio I/O library designed for cross-platform
support of audio. It uses a callback mechanism to request audio processing.
Audio can be generated in various formats including 32 bit floating point
and will be converted to the native format internally.

Documentation:
	See "pa_common/portaudio.h" for API.
	See docs folder for a tutorial.
	And see "pa_common/patest_sine.c" for an example.

Files:
	pa_common/              = platform independant code
	pa_common/portaudio.h   = header file for PortAudio API. Specifies API.
	pa_common/pa_lib.c      = host independant code for DirectSound and Macintosh.
	pa_common/pa_rbuf.c     = ring Buffer used by blocking read/write.
	pa_common/pa_rw.c       = blocking read/write tool.

DirectSound Files:
	pa_win_ds/pa_dsound.c   = implementation of PA for DirectSound on a PC
	pa_win_ds/dsound_wrapper.cpp = wrapper for DirectSound C++ calls

Macintosh Files:
	pa_mac/pa_mac.c         = implementation for Macintosh Soundmanager

Test Programs
	pa_tests/pa_fuzz.c = guitar fuzz box
	pa_tests/pa_devs.c = print a list of available devices
	pa_tests/pa_minlat.c = determine minimum latency for your machine
	pa_tests/paqa_devs.c = self test that opens all devices
	pa_tests/paqa_errs.c = test error detection and reporting
	pa_tests/patest_clip.c = hear a sine wave clipped and unclipped
	pa_tests/patest_dither.c = hear effects of dithering (unlikely)
	pa_tests/patest_pink.c = fun with pink noise
	pa_tests/patest_record.c = record and playback some audio
	pa_tests/patest_maxsines.c = how many sine waves can we play? Tests Pa_GetCPULoad().
	pa_tests/patest_sine.c = output a sine wave in a simple PA app
	pa_tests/patest_rw.c = blocking read/write
	pa_tests/patest_wire.c = pass input to output, wire simulator

For information on compiling programs with PortAudio, please see the
tutorial at:

  http://www.portaudio.com/docs/pa_tutorial.html

