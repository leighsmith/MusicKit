/*
  $Id$

  Defined In: The MusicKit
  Description:
    MKPerformer delegate description.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.5  2005/05/14 03:27:26  leighsmith
  Clean up of parameter names to correct doxygen warnings

  Revision 1.4  2005/05/09 15:52:52  leighsmith
  Converted headerdoc comments to doxygen comments

  Revision 1.3  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.2  1999/07/29 01:25:49  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
/*!
  @class MKPerformerDelegate
  @brief The following methods may be implemented by the delegate. The
  messages get sent, if the delegate responds to them, after the
  MKPerformer's status has changed.
*/

#ifndef __MK_PerformerDelegate_H___
#define __MK_PerformerDelegate_H___

#import <Foundation/NSObject.h>
@interface MKPerformerDelegate : NSObject

/*!
  @param  sender is an id.
  @return Returns an id.
  @brief Delegate receives this message, if it responds to it, after the
  performer is activated.

  
*/
- performerDidActivate: (id) sender;

/*!
  @param  sender is an id.
  @return Returns an id.
  @brief Delegate receives this message, if it responds to it,  after the
  performer is paused.

  
*/
- performerDidPause: (id) sender;

/*!
  @param  sender is an id.
  @return Returns an id.
  @brief Delegate receives this message, if it responds to it,  after the
  performer is resumed.

  
*/
- performerDidResume: (id) sender;

/*!
  @param  sender is an id.
  @return Returns an id.
  @brief Delegate receives this message, if it responds to it,  after the
  performer is deactivated.

  
*/
- performerDidDeactivate: (id) sender;

@end



#endif
