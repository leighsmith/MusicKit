#ifndef __MK_PerformerDelegate_H___
#define __MK_PerformerDelegate_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
 * ------------ Performer delegate description
 */
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
