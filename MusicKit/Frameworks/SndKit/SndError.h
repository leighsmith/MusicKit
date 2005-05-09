/*
  $Id$

  Description:
    Error codes.

  Substantially based on Sound Kit, Release 2.0, Copyright (c) 1988, 1989, 1990, NeXT, Inc.  All rights reserved.
  Copyright (c) 1999 Apple Computer, Inc. All rights reserved.
  Additions Copyright (c) 2001, The MusicKit Project.  All rights reserved.

 Legal Statement Covering Additions by The MusicKit Project:
 
     Permission is granted to use and modify this code for commercial and
     non-commercial purposes so long as the author attribution and copyright
     messages remain intact and accompany all relevant code.
 
*/
/*
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

#ifndef __SNDKIT_SNDERROR_H__
#define __SNDKIT_SNDERROR_H__

#if !defined(SND_ERR_NOT_SOUND)
/*!
 @enum SndError
  @constant SND_ERR_NONE              No error - all is well		          
  @constant SND_ERR_NOT_SOUND		      Not a sound
  @constant SND_ERR_BAD_FORMAT		    Bad format
  @constant SND_ERR_BAD_RATE		      Bad sample rate
  @constant SND_ERR_BAD_CHANNEL		    Bad channel count
  @constant SND_ERR_BAD_SIZE		      Bad data size
  @constant SND_ERR_BAD_FILENAME	    Bad filename
  @constant SND_ERR_CANNOT_OPEN		    Error opening the file
  @constant SND_ERR_CANNOT_WRITE	    Error writing to the file
  @constant SND_ERR_CANNOT_READ		    Error reading from the file
  @constant SND_ERR_CANNOT_ALLOC	    Error allocating the required memory
  @constant SND_ERR_CANNOT_FREE		    Error freeing the memory
  @constant SND_ERR_CANNOT_COPY		    Description forthcoming
  @constant SND_ERR_CANNOT_RESERVE    Description forthcoming
  @constant SND_ERR_NOT_RESERVED	    Description forthcoming
  @constant SND_ERR_CANNOT_RECORD	    Description forthcoming
  @constant SND_ERR_ALREADY_RECORDING	Description forthcoming
  @constant SND_ERR_NOT_RECORDING	    Description forthcoming
  @constant SND_ERR_CANNOT_PLAY		    Description forthcoming
  @constant SND_ERR_ALREADY_PLAYING	  Description forthcoming
  @constant SND_ERR_NOT_PLAYING		    Description forthcoming
  @constant SND_ERR_NOT_IMPLEMENTED	  Description forthcoming
  @constant SND_ERR_CANNOT_FIND		    Description forthcoming
  @constant SND_ERR_CANNOT_EDIT		    Description forthcoming
  @constant SND_ERR_BAD_SPACE		      Description forthcoming
  @constant SND_ERR_KERNEL		        Description forthcoming
  @constant SND_ERR_BAD_CONFIGURATION	Description forthcoming
  @constant SND_ERR_CANNOT_CONFIGURE	Description forthcoming
  @constant SND_ERR_UNDERRUN		      Description forthcoming
  @constant SND_ERR_ABORTED		        Description forthcoming
  @constant SND_ERR_BAD_TAG		        Description forthcoming
  @constant SND_ERR_CANNOT_ACCESS	    Description forthcoming
  @constant SND_ERR_TIMEOUT		        Description forthcoming
  @constant SND_ERR_BUSY		          Description forthcoming
  @constant SND_ERR_CANNOT_ABORT	    Description forthcoming
  @constant SND_ERR_INFO_TOO_BIG	    Description forthcoming
  @constant SND_ERR_BAD_STARTTIME     Description forthcoming
  @constant SND_ERR_BAD_DURATION      Description forthcoming
  @constant SND_ERR_UNKNOWN           Unknown error.
*/
typedef enum {
    SND_ERR_NONE		          = 0,
    SND_ERR_NOT_SOUND		      = 1,
    SND_ERR_BAD_FORMAT		    = 2,
    SND_ERR_BAD_RATE		      = 3,
    SND_ERR_BAD_CHANNEL		    = 4,
    SND_ERR_BAD_SIZE		      = 5,
    SND_ERR_BAD_FILENAME	    = 6,
    SND_ERR_CANNOT_OPEN		    = 7,
    SND_ERR_CANNOT_WRITE	    = 8,
    SND_ERR_CANNOT_READ		    = 9,
    SND_ERR_CANNOT_ALLOC	    = 10,
    SND_ERR_CANNOT_FREE		    = 11,
    SND_ERR_CANNOT_COPY		    = 12,
    SND_ERR_CANNOT_RESERVE    = 13,
    SND_ERR_NOT_RESERVED	    = 14,
    SND_ERR_CANNOT_RECORD	    = 15,
    SND_ERR_ALREADY_RECORDING	= 16,
    SND_ERR_NOT_RECORDING	    = 17,
    SND_ERR_CANNOT_PLAY		    = 18,
    SND_ERR_ALREADY_PLAYING	  = 19,
    SND_ERR_NOT_PLAYING		    = 20,
    SND_ERR_NOT_IMPLEMENTED	  = 21,
    SND_ERR_CANNOT_FIND		    = 22,
    SND_ERR_CANNOT_EDIT		    = 23,
    SND_ERR_BAD_SPACE		      = 24,
    SND_ERR_KERNEL		        = 25,
    SND_ERR_BAD_CONFIGURATION	= 26,
    SND_ERR_CANNOT_CONFIGURE	= 27,
    SND_ERR_UNDERRUN		      = 28,
    SND_ERR_ABORTED		        = 29,
    SND_ERR_BAD_TAG		        = 30,
    SND_ERR_CANNOT_ACCESS	    = 31,
    SND_ERR_TIMEOUT		        = 32,
    SND_ERR_BUSY		          = 33,
    SND_ERR_CANNOT_ABORT	    = 34,
    SND_ERR_INFO_TOO_BIG	    = 35,
    SND_ERR_BAD_STARTTIME     = 36,
    SND_ERR_BAD_DURATION      = 37,
    SND_ERR_UNKNOWN           = 32767
} SndError;
#endif

/*!
  @function SndSoundError
  @brief This routine returns a NSString that describes the given error code.
  @param err The reported error number
  @return An NSString that describes the given error code.
 */
NSString *SndSoundError(int err);

#endif
