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
 *	sounderror.h
 *	Copyright 1988-89 NeXT, Inc.
 *
 */
#if !defined(SND_ERR_NOT_SOUND)
typedef enum {
    SND_ERR_NONE		= 0,
    SND_ERR_NOT_SOUND		= 1,
    SND_ERR_BAD_FORMAT		= 2,
    SND_ERR_BAD_RATE		= 3,
    SND_ERR_BAD_CHANNEL		= 4,
    SND_ERR_BAD_SIZE		= 5,
    SND_ERR_BAD_FILENAME	= 6,
    SND_ERR_CANNOT_OPEN		= 7,
    SND_ERR_CANNOT_WRITE	= 8,
    SND_ERR_CANNOT_READ		= 9,
    SND_ERR_CANNOT_ALLOC	= 10,
    SND_ERR_CANNOT_FREE		= 11,
    SND_ERR_CANNOT_COPY		= 12,
    SND_ERR_CANNOT_RESERVE	= 13,
    SND_ERR_NOT_RESERVED	= 14,
    SND_ERR_CANNOT_RECORD	= 15,
    SND_ERR_ALREADY_RECORDING	= 16,
    SND_ERR_NOT_RECORDING	= 17,
    SND_ERR_CANNOT_PLAY		= 18,
    SND_ERR_ALREADY_PLAYING	= 19,
    SND_ERR_NOT_PLAYING		= 20,
    SND_ERR_NOT_IMPLEMENTED	= 21,
    SND_ERR_CANNOT_FIND		= 22,
    SND_ERR_CANNOT_EDIT		= 23,
    SND_ERR_BAD_SPACE		= 24,
    SND_ERR_KERNEL		= 25,
    SND_ERR_BAD_CONFIGURATION	= 26,
    SND_ERR_CANNOT_CONFIGURE	= 27,
    SND_ERR_UNDERRUN		= 28,
    SND_ERR_ABORTED		= 29,
    SND_ERR_BAD_TAG		= 30,
    SND_ERR_CANNOT_ACCESS	= 31,
    SND_ERR_TIMEOUT		= 32,
    SND_ERR_BUSY		= 33,
    SND_ERR_CANNOT_ABORT	= 34,
    SND_ERR_INFO_TOO_BIG	= 35,
    SND_ERR_UNKNOWN=32767
} SndError;
#endif

char *SndSoundError(int err);
/*
 * This routine returns a pointer to a string that describes the
 * given error code. 
 */

