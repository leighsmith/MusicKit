/*
  $Id$
  Defined In: The MusicKit

  Description:
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:26:18  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_timeunits_H___
#define __MK_timeunits_H___

/* Time units used for writing files */
typedef enum _MKTimeUnit {
    MK_beat,
    MK_second,
    MK_timeTag
} MKTimeUnit;

#endif
