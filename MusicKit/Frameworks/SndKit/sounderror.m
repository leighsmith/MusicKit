/*
 * Copyright (c) 1999 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * "Portions Copyright (c) 1999 Apple Computer, Inc.  All Rights
 * Reserved.  This file contains Original Code and/or Modifications of
 * Original Code as defined in and that are subject to the Apple Public
 * Source License Version 1.0 (the 'License').  You may not use this file
 * except in compliance with the License.  Please obtain a copy of the
 * License at http://www.apple.com/publicsource and read it before using
 * this file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE OR NON-INFRINGEMENT.  Please see the
 * License for the specific language governing rights and limitations
 * under the License."
 * 
 * @APPLE_LICENSE_HEADER_END@
 */


/*
 *	sounderror.c
 *	Written by Lee Boynton
 *	Copyright 1988 NeXT, Inc.
 *
 *	12/04/91/mtm	Made error strings localizable.
 *
 */

#import <Foundation/Foundation.h>
#ifndef USE_NEXTSTEP_SOUND_IO
#import "sounderror.h"
#endif

static id soundBundle = nil;

/*
 * Localizable strings.
 */
#define LSTRING_NO_ERROR \
NSLocalizedStringFromTableInBundle(@"No error", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_NOT_A_SOUND \
NSLocalizedStringFromTableInBundle(@"Not a sound", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_BAD_DATA_FORMAT \
NSLocalizedStringFromTableInBundle(@"Bad data format", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_BAD_SAMPLING_RATE \
NSLocalizedStringFromTableInBundle(@"Bad sampling rate", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_BAD_CHANNEL_COUNT \
NSLocalizedStringFromTableInBundle(@"Bad channel count", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_BAD_SIZE \
NSLocalizedStringFromTableInBundle(@"Bad size", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_BAD_FILE_NAME \
NSLocalizedStringFromTableInBundle(@"Bad file name", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_CANNOT_OPEN_FILE \
NSLocalizedStringFromTableInBundle(@"Cannot open file", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_CANNOT_WRITE_FILE \
NSLocalizedStringFromTableInBundle(@"Cannot write file", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_CANNOT_READ_FILE \
NSLocalizedStringFromTableInBundle(@"Cannot read file", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_CANNOT_ALLOCATE_MEMORY \
NSLocalizedStringFromTableInBundle(@"Cannot allocate memory", @"SoundLib", soundBundle, \
\
@"SNDSoundError message")

#define LSTRING_CANNOT_FREE_MEMORY \
NSLocalizedStringFromTableInBundle(@"Cannot free memory", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_CANNOT_COPY \
NSLocalizedStringFromTableInBundle(@"Cannot copy", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_CANNOT_RESERVE_ACCESS \
NSLocalizedStringFromTableInBundle(@"Cannot reserve access", @"SoundLib", soundBundle, \
\
@"SNDSoundError message")

#define LSTRING_ACCESS_NOT_RESERVED \
NSLocalizedStringFromTableInBundle(@"Access not reserved", @"SoundLib", soundBundle, \
\
@"SNDSoundError message")

#define LSTRING_CANNOT_RECORD_SOUND \
NSLocalizedStringFromTableInBundle(@"Cannot record sound", @"SoundLib", soundBundle, \
\
@"SNDSoundError message")

#define LSTRING_ALREADY_RECORDING_SOUND \
NSLocalizedStringFromTableInBundle(@"Already recording sound", @"SoundLib", soundBundle, \
\
@"SNDSoundError message")

#define LSTRING_NOT_RECORDING_SOUND \
NSLocalizedStringFromTableInBundle(@"Not recording sound", @"SoundLib", soundBundle, \
\
@"SNDSoundError message")

#define LSTRING_CANNOT_PLAY_SOUND \
NSLocalizedStringFromTableInBundle(@"Cannot play sound", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_ALREADY_PLAYING_SOUND \
NSLocalizedStringFromTableInBundle(@"Already playing sound", @"SoundLib", soundBundle, \
\
@"SNDSoundError message")

#define LSTRING_NOT_IMPLEMENTED \
NSLocalizedStringFromTableInBundle(@"Not implemented", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_NOT_PLAYING_SOUND \
NSLocalizedStringFromTableInBundle(@"Not playing sound", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_CANNOT_FIND_SOUND \
NSLocalizedStringFromTableInBundle(@"Cannot find sound", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_CANNOT_EDIT_SOUND \
NSLocalizedStringFromTableInBundle(@"Cannot edit sound", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_BAD_MEMORY_SPACE_IN_DSP_LOAD_IMAGE \
NSLocalizedStringFromTableInBundle(@"Bad memory space in dsp load image", @"SoundLib", soundBundle, \
\
@"SNDSoundError message")

#define LSTRING_MACH_KERNEL_ERROR \
NSLocalizedStringFromTableInBundle(@"Mach kernel error", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_BAD_CONFIGURATION \
NSLocalizedStringFromTableInBundle(@"Bad configuration", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_CANNOT_CONFIGURE \
NSLocalizedStringFromTableInBundle(@"Cannot configure", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_DATA_UNDERRUN \
NSLocalizedStringFromTableInBundle(@"Data underrun", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_ABORTED \
NSLocalizedStringFromTableInBundle(@"Aborted", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_BAD_TAG \
NSLocalizedStringFromTableInBundle(@"Bad tag", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_CANNOT_ACCESS_HARDWARE_RESOURCES \
NSLocalizedStringFromTableInBundle(@"Cannot access hardware resources", @"SoundLib", soundBundle, \
\
@"SNDSoundError message")

#define LSTRING_TIMEOUT \
NSLocalizedStringFromTableInBundle(@"Timeout", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_HARDWARE_RESOURCES_ALREADY_IN_USE \
NSLocalizedStringFromTableInBundle(@"Hardware resources already in use", @"SoundLib", soundBundle, \
\
@"SNDSoundError message")

#define LSTRING_CANNOT_ABORT_OPERATION \
NSLocalizedStringFromTableInBundle(@"Cannot abort operation", @"SoundLib", soundBundle, \
\
@"SNDSoundError message")

#define LSTRING_INFORMATION_STRING_TOO_LARGE \
NSLocalizedStringFromTableInBundle(@"Information string too large", @"SoundLib", soundBundle, \
\
@"SNDSoundError message")

#define LSTRING_UNKNOWN_ERROR \
NSLocalizedStringFromTableInBundle(@"Unknown error", @"SoundLib", soundBundle, \
@"SNDSoundError message")

#define LSTRING_BAD_STARTTIME \
NSLocalizedStringFromTableInBundle(@"Bad start time error", @"SoundLib", soundBundle, \
                                   @"SNDSoundError message")
#define LSTRING_BAD_DURATION \
NSLocalizedStringFromTableInBundle(@"Bad duration error", @"SoundLib", soundBundle, \
                                   @"SNDSoundError message")


const char *SndSoundError(int err)
{
    /*
     * Tell string localize routines where .strings file is.
     */
    if (!soundBundle)
	soundBundle = [[NSBundle alloc]
	    initWithPath:@"/System/Library/CoreServices/Resources"];

    switch (err) {
	case SND_ERR_NONE:			//	0
	    return (char *)LSTRING_NO_ERROR;
	case SND_ERR_NOT_SOUND:			//	1
	    return (char *)LSTRING_NOT_A_SOUND;
	case SND_ERR_BAD_FORMAT:		//	2
	    return (char *)LSTRING_BAD_DATA_FORMAT;
	case SND_ERR_BAD_RATE:			//	3
	    return (char *)LSTRING_BAD_SAMPLING_RATE;
	case SND_ERR_BAD_CHANNEL:		//	4
	    return (char *)LSTRING_BAD_CHANNEL_COUNT;
	case SND_ERR_BAD_SIZE:			//	5
	    return (char *)LSTRING_BAD_SIZE;
	case SND_ERR_BAD_FILENAME:		//	6
	    return (char *)LSTRING_BAD_FILE_NAME;
	case SND_ERR_CANNOT_OPEN:		//	7
	    return (char *)LSTRING_CANNOT_OPEN_FILE;
	case SND_ERR_CANNOT_WRITE:		//	8
	    return (char *)LSTRING_CANNOT_WRITE_FILE;
	case SND_ERR_CANNOT_READ:		//	9
	    return (char *)LSTRING_CANNOT_READ_FILE;
	case SND_ERR_CANNOT_ALLOC:		//	10
	    return (char *)LSTRING_CANNOT_ALLOCATE_MEMORY;
	case SND_ERR_CANNOT_FREE:		//	11
	    return (char *)LSTRING_CANNOT_FREE_MEMORY;
	case SND_ERR_CANNOT_COPY:		//	12
	    return (char *)LSTRING_CANNOT_COPY;
	case SND_ERR_CANNOT_RESERVE:		//	13
	    return (char *)LSTRING_CANNOT_RESERVE_ACCESS;
	case SND_ERR_NOT_RESERVED:		//	14
	    return (char *)LSTRING_ACCESS_NOT_RESERVED;
	case SND_ERR_CANNOT_RECORD:		//	15
	    return (char *)LSTRING_CANNOT_RECORD_SOUND;
	case SND_ERR_ALREADY_RECORDING:		//	16
	    return (char *)LSTRING_ALREADY_RECORDING_SOUND;
	case SND_ERR_NOT_RECORDING:		//	17
	    return (char *)LSTRING_NOT_RECORDING_SOUND;
	case SND_ERR_CANNOT_PLAY:		//	18
	    return (char *)LSTRING_CANNOT_PLAY_SOUND;
	case SND_ERR_ALREADY_PLAYING:		//	19
	    return (char *)LSTRING_ALREADY_PLAYING_SOUND;
	case SND_ERR_NOT_IMPLEMENTED:		//	20
	    return (char *)LSTRING_NOT_IMPLEMENTED;
	case SND_ERR_NOT_PLAYING:		//	21
	    return (char *)LSTRING_NOT_PLAYING_SOUND;
	case SND_ERR_CANNOT_FIND:		//	22
	    return (char *)LSTRING_CANNOT_FIND_SOUND;
	case SND_ERR_CANNOT_EDIT:		//	23
	    return (char *)LSTRING_CANNOT_EDIT_SOUND;
	case SND_ERR_BAD_SPACE:			//	24
	    return (char *)LSTRING_BAD_MEMORY_SPACE_IN_DSP_LOAD_IMAGE;
	case SND_ERR_KERNEL:			//	25
	    return (char *)LSTRING_MACH_KERNEL_ERROR;
	case SND_ERR_BAD_CONFIGURATION:		//	26
	    return (char *)LSTRING_BAD_CONFIGURATION;
	case SND_ERR_CANNOT_CONFIGURE:		//	27
	    return (char *)LSTRING_CANNOT_CONFIGURE;
	case SND_ERR_UNDERRUN:			//	28
	    return (char *)LSTRING_DATA_UNDERRUN;
	case SND_ERR_ABORTED:			//	29
	    return (char *)LSTRING_ABORTED;
	case SND_ERR_BAD_TAG:			//	30
	    return (char *)LSTRING_BAD_TAG;
	case SND_ERR_CANNOT_ACCESS:		//	31
	    return (char *)LSTRING_CANNOT_ACCESS_HARDWARE_RESOURCES;
	case SND_ERR_TIMEOUT:			//	32
	    return (char *)LSTRING_TIMEOUT;
	case SND_ERR_BUSY:			//	33
	    return (char *)LSTRING_HARDWARE_RESOURCES_ALREADY_IN_USE;
	case SND_ERR_CANNOT_ABORT:		//	34
	    return (char *)LSTRING_CANNOT_ABORT_OPERATION;
	case SND_ERR_INFO_TOO_BIG:		//	35
	    return (char *)LSTRING_INFORMATION_STRING_TOO_LARGE;
  case SND_ERR_BAD_STARTTIME:
    return (char*) LSTRING_BAD_STARTTIME;
  case SND_ERR_BAD_DURATION:
    return (char*) LSTRING_BAD_DURATION; 
	case SND_ERR_UNKNOWN:
	default:
	    return (char *)LSTRING_UNKNOWN_ERROR;
    }
}


