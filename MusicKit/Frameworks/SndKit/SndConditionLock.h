/*
  $Id$

  Description:

  Original Author: Stephen Brandon, <stephen@brandonitconsulting.co.uk>

  Tue 30-Oct-2001, Copyright (c) 2001 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.

  The Win32 Condition code is substantially taken from
  http://www.cs.wustl.edu/~schmidt/win32-cv-1.html
*/

#ifndef __SNDCONDITIONLOCK_H__
#define __SNDCONDITIONLOCK_H__

#ifdef __MINGW32__

#import <windows.h>
#import <Foundation/Foundation.h>
#import "SndKit.h"


typedef struct
{
  int waiters_count_;
  // Number of waiting threads.

  CRITICAL_SECTION waiters_count_lock_;
  // Serialize access to <waiters_count_>.

  HANDLE sema_;
  // Semaphore used to queue up threads waiting for the condition to
  // become signaled. 

  HANDLE waiters_done_;
  // An auto-reset event used by the broadcast/signal thread to wait
  // for all the waiting thread(s) to wake up and be released from the
  // semaphore. 

  size_t was_broadcast_;
  // Keeps track of whether we were broadcasting or signaling.  This
  // allows us to optimize the code if we're just signaling.
} pthread_cond_t;

typedef HANDLE pthread_mutex_t;



/*!
    @class      SndConditionLock 
    @abstract   Condition Lock implementation for Win32
    @discussion The libobjc implementation of threads for Win32 does not
                implement conditions. The class should replace NSConditionLock
                at runtime via "poseAs" in order for the audio I/O to work.
*/

@interface SndConditionLock : NSObject <NSLocking, GCFinalization>
{
@private
  objc_condition_t      _condition;
  objc_mutex_t          _mutex;
  int                   _condition_value;
}

/*
 * this was originally part of the NSLocking protocol
 */
- (void) lock;
- (void) unlock;

/*
 * Initialize lock with condition
 */
- (id) initWithCondition: (int)value;

/*
 * Return the current condition of the lock
 */
- (int) condition;

/*
 * Acquiring and release the lock
 */
- (void) lockWhenCondition: (int)value;
- (void) unlockWithCondition: (int)value;
- (BOOL) tryLock;
- (BOOL) tryLockWhenCondition: (int)value;

/*
 * Acquiring the lock with a date condition
 */
- (BOOL) lockBeforeDate: (NSDate*)limit;
- (BOOL) lockWhenCondition: (int)condition
                beforeDate: (NSDate*)limit;

- (void) lock;
- (void) unlock;

@end

#endif /* mingw32 */

#endif
