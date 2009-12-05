/*
  $Id$
  Defined In: The MusicKit

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2005 The MusicKit Project.
*/
#ifndef __MK_timeunits_H___
#define __MK_timeunits_H___

/*!
  @file timeunits.h
 */

/*!
  @brief This enumeration specifies the manner in which time is recorded by
  MKScorefileWriter, MKPartWriter and MKScoreWriter classes.  The values are: 
 */
typedef enum _MKTimeUnit {
    /*!  Time is stored in beats. */
    MK_beat,
    /*! Time is stored in seconds.  */
    MK_second,
    /*!  The time is taken from the timeTag in the MKNote itself.
    Care must be taken when using this TimeUnit - otherwise, out-of-order MKNotes may result.
    */
    MK_timeTag
} MKTimeUnit;

#endif
