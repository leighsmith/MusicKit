/*
  $Id$
  Defined In: The MusicKit

  Description:
    This file describes an abstract interface for supplying your own Objects
    to be read/written from/to MKScorefiles.

    The object may be of any class, but must be able to write itself
    out in ASCII when sent the message -writeASCIIStream:.
    It may write itself any way it wants, as long as it can also read
    itself when sent the message -readASCIIStream:.
    The only restriction on these methods is that the ASCII representation
    should not contain the character ']'.

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.1  2000/04/16 04:07:57  leigh
  Renamed scorefileObject to MKScorefileObject headers

  Revision 1.2  1999/07/29 01:26:16  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_scorefileObject_H___
#define __MK_scorefileObject_H___

#import <Foundation/NSObject.h>
@interface MKScorefileObject: NSObject
-readASCIIStream: (NSMutableData *) aStream;
-writeASCIIStream: (NSMutableData *) aStream;
@end



#endif
