/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$

  Performer delegate description
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:49  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_PerformerDelegate_H___
#define __MK_PerformerDelegate_H___

#import <Foundation/NSObject.h>
@interface MKPerformerDelegate : NSObject
/*
 * The following methods may be implemented by the delegate. The
 * messages get sent, if the delegate responds to them, after the
 * Performer's status has changed.
 */

- performerDidActivate:sender;
- performerDidPause:sender;
- performerDidResume:sender;
- performerDidDeactivate:sender;

@end



#endif
