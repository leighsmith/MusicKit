/*
  $Id$

  Description:

  Original Author: Stephen Brandon, <stephen@brandonitconsulting.co.uk>

  31 Oct 2001, Copyright (c) 2001 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-
  commercial purposes so long as the author attribution and copyright messages
  remain intact and accompany all relevant code.


  Substantial part of this code are taken and modified from GCC's libobjc, and
  from the GNUstep project (NSLock.m).

Copyright on libobjc:
=====================

GNU CC is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version.

GNU CC is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
GNU CC; see the file COPYING.  If not, write to the Free Software
Foundation, 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.

   As a special exception, if you link this library with files compiled with
   GCC to produce an executable, this does not cause the resulting executable
   to be covered by the GNU General Public License. This exception does not
   however invalidate any other reasons why the executable file might be
   covered by the GNU General Public License.


Copyright on GNUstep NSLock.m code:
===================================
   Mutual exclusion locking classes
   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Created: 1996
   
   This file is part of the GNUstep Objective-C Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful, 
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "SndConditionLock.h"

// Exceptions

NSString *NSConditionLockException = @"NSConditionLockException";

// Macros

#define CHECK_RECURSIVE_CONDITION_LOCK(mutex)                   \
{                                                               \
  if ((mutex)->owner == objc_thread_id())                       \
    {                                                           \
      [NSException                                              \
        raise: NSConditionLockException                         \
        format: @"Thread attempted to recursively lock"];       \
      /* NOT REACHED */                                         \
    }                                                           \
}

@implementation SndConditionLock

/********************************************************/
/* Backend Win32 functions */

int 
sk_win32_pthread_cond_init (pthread_cond_t *cv)
{
  cv->waiters_count_ = 0;
  cv->was_broadcast_ = 0;
  cv->sema_ = CreateSemaphore (NULL,       // no security
                               0,          // initially 0
                               0x7fffffff, // max count
                               NULL);      // unnamed 
  InitializeCriticalSection (&cv->waiters_count_lock_);
  cv->waiters_done_ = CreateEvent (NULL,  // no security
                                   FALSE, // auto-reset
                                   FALSE, // non-signaled initially
                                   NULL); // unnamed
  if (!(cv->sema_) || !(cv->waiters_done_)) {
    return -1;
  }
  return 0;
}

int 
sk_win32_pthread_cond_destroy (pthread_cond_t *cv)
/* This was written by Stephen Brandon: might need checking */
{
  BOOL failed = FALSE;
  if ( CloseHandle (cv->sema_)) {
    failed = TRUE;
  }
  DeleteCriticalSection (&cv->waiters_count_lock_);
  if ( CloseHandle (cv->waiters_done_)) {
    failed = TRUE;
  }
  return (failed) ? -1 : 0;
}

int
sk_win32_pthread_cond_wait (pthread_cond_t *cv, 
                   pthread_mutex_t *external_mutex)
{
  int last_waiter;
// Avoid race conditions.
  EnterCriticalSection (&cv->waiters_count_lock_);
  cv->waiters_count_++;
  LeaveCriticalSection (&cv->waiters_count_lock_);

  // This call atomically releases the mutex and waits on the
  // semaphore until <pthread_cond_signal> or <pthread_cond_broadcast>
  // are called by another thread.
  SignalObjectAndWait (*external_mutex, cv->sema_, INFINITE, FALSE);

  // Reacquire lock to avoid race conditions.
  EnterCriticalSection (&cv->waiters_count_lock_);

  // We're no longer waiting...
  cv->waiters_count_--;

  // Check to see if we're the last waiter after <pthread_cond_broadcast>.
  last_waiter = cv->was_broadcast_ && cv->waiters_count_ == 0;

  LeaveCriticalSection (&cv->waiters_count_lock_);

  // If we're the last waiter thread during this particular broadcast
  // then let all the other threads proceed.
  if (last_waiter)
    // This call atomically signals the <waiters_done_> event and waits until
    // it can acquire the <external_mutex>.  This is required to ensure fairness. 
    SignalObjectAndWait (cv->waiters_done_, *external_mutex, INFINITE, FALSE);
  else
    // Always regain the external mutex since that's the guarantee we
    // give to our callers. 
    WaitForSingleObject (*external_mutex, INFINITE);
  return 0;
}


int
sk_win32_pthread_cond_signal (pthread_cond_t *cv)
{
  int have_waiters;
  EnterCriticalSection (&cv->waiters_count_lock_);
  have_waiters = cv->waiters_count_ > 0;
  LeaveCriticalSection (&cv->waiters_count_lock_);

  // If there aren't any waiters, then this is a no-op.  
  if (have_waiters)
    ReleaseSemaphore (cv->sema_, 1, 0);
  return 0;
}


int
sk_win32_pthread_cond_broadcast (pthread_cond_t *cv)
{
  // This is needed to ensure that <waiters_count_> and <was_broadcast_> are
  // consistent relative to each other.
  int have_waiters;
  EnterCriticalSection (&cv->waiters_count_lock_);
  have_waiters = 0;

  if (cv->waiters_count_ > 0) {
    // We are broadcasting, even if there is just one waiter...
    // Record that we are broadcasting, which helps optimize
    // <pthread_cond_wait> for the non-broadcast case.
    cv->was_broadcast_ = 1;
    have_waiters = 1;
  }

  if (have_waiters) {
    // Wake up all the waiters atomically.
    ReleaseSemaphore (cv->sema_, cv->waiters_count_, 0);

    LeaveCriticalSection (&cv->waiters_count_lock_);

    // Wait for all the awakened threads to acquire the counting
    // semaphore. 
    WaitForSingleObject (cv->waiters_done_, INFINITE);
    // This assignment is okay, even without the <waiters_count_lock_> held 
    // because no other waiter threads can wake up to access it.
    cv->was_broadcast_ = 0;
  }
  else
    LeaveCriticalSection (&cv->waiters_count_lock_);
  return 0;
}



/********************************************************/
/* Backend condition mutex functions */

/* Allocate a condition. */
int
sk_condition_allocate(objc_condition_t condition)
{
  if (sk_win32_pthread_cond_init((pthread_cond_t *)(&(condition->backend))))
    return -1;
  else
    return 0;
}

/* Deallocate a condition. */
int
sk_condition_deallocate(objc_condition_t condition)
{
  return sk_win32_pthread_cond_destroy((pthread_cond_t *)(&(condition->backend)));
}

/* Wait on the condition */
int
sk_condition_wait(objc_condition_t condition, objc_mutex_t mutex)
{
  return sk_win32_pthread_cond_wait((pthread_cond_t *)(&(condition->backend)),
			   (pthread_mutex_t *)(&(mutex->backend)));
}

/* Wake up all threads waiting on this condition. */
int
sk_condition_broadcast(objc_condition_t condition)
{
  return sk_win32_pthread_cond_broadcast((pthread_cond_t *)(&(condition->backend)));
}

/* Wake up one thread waiting on this condition. */
int
sk_condition_signal(objc_condition_t condition)
{
  return sk_win32_pthread_cond_signal((pthread_cond_t *)(&(condition->backend)));
}


/********************************************************/
/* Frontend condition mutex functions */

/*
  Allocate a condition.  Return the condition pointer if successful or NULL
  if the allocation failed for any reason.
  */
objc_condition_t 
snd_objc_condition_allocate(void)
{
  objc_condition_t condition;
    
  /* Allocate the condition mutex structure */
  if (!(condition = 
	(objc_condition_t)objc_malloc(sizeof(struct objc_condition))))
    return NULL;

  /* Call the backend to create the condition mutex */
  if (sk_condition_allocate(condition))
    {
      /* failed! */
      objc_free(condition);
      return NULL;
    }

  /* Success! */
  return condition;
}

/*
  Deallocate a condition. Note that this includes an implicit 
  condition_broadcast to insure that waiting threads have the opportunity
  to wake.  It is legal to dealloc a condition only if no other
  thread is/will be using it. Here we do NOT check for other threads
  waiting but just wake them up.
  */
int
snd_objc_condition_deallocate(objc_condition_t condition)
{
  /* Broadcast the condition */
  if (snd_objc_condition_broadcast(condition))
    return -1;

  /* Call the backend to destroy */
  if (sk_condition_deallocate(condition))
    return -1;

  /* Free the condition mutex structure */
  objc_free(condition);

  return 0;
}

/*
  Wait on the condition unlocking the mutex until objc_condition_signal()
  or objc_condition_broadcast() are called for the same condition. The
  given mutex *must* have the depth set to 1 so that it can be unlocked
  here, so that someone else can lock it and signal/broadcast the condition.
  The mutex is used to lock access to the shared data that make up the
  "condition" predicate.
  */
int
snd_objc_condition_wait(objc_condition_t condition, objc_mutex_t mutex)
{
  objc_thread_t thread_id;

  /* Valid arguments? */
  if (!mutex || !condition)
    return -1;

  /* Make sure we are owner of mutex */
  thread_id = objc_thread_id();
  if (mutex->owner != thread_id)
    return -1;

  /* Cannot be locked more than once */
  if (mutex->depth > 1)
    return -1;

  /* Virtually unlock the mutex */
  mutex->depth = 0;
  mutex->owner = (objc_thread_t)NULL;

  /* Call the backend to wait */
  sk_condition_wait(condition, mutex);

  /* Make ourselves owner of the mutex */
  mutex->owner = thread_id;
  mutex->depth = 1;

  return 0;
}

/*
  Wake up all threads waiting on this condition. It is recommended that 
  the called would lock the same mutex as the threads in objc_condition_wait
  before changing the "condition predicate" and make this call and unlock it
  right away after this call.
  */
int
snd_objc_condition_broadcast(objc_condition_t condition)
{
  /* Valid condition mutex? */
  if (!condition)
    return -1;

  return sk_condition_broadcast(condition);
}

/*
  Wake up one thread waiting on this condition. It is recommended that 
  the called would lock the same mutex as the threads in objc_condition_wait
  before changing the "condition predicate" and make this call and unlock it
  right away after this call.
  */
int
snd_objc_condition_signal(objc_condition_t condition)
{
  /* Valid condition mutex? */
  if (!condition)
    return -1;

  return sk_condition_signal(condition);
}

/***************************************************/

- (id) init
{
  return [self initWithCondition: 0];
}

// Designated initializer
// Initialize lock with condition
- (id) initWithCondition: (int)value
{
  self = [super init];
  if (self != nil)
    {
      _condition_value = value;

      // Allocate the mutex from the runtime
      _condition = snd_objc_condition_allocate ();
      if (_condition == 0)
        {
          NSLog(@"Failed to allocate a condition with snd_objc_condition_allocate");
          RELEASE(self);
          return nil;
        }
      _mutex = objc_mutex_allocate ();
      if (_mutex == 0)
        {
          NSLog(@"Failed to allocate a mutex");
          RELEASE(self);
          return nil;
        }
    }
  return self;
}

- (void) dealloc
{
  [self gcFinalize];
  [super dealloc];
}

- (void) gcFinalize
{
  if (_condition != 0)
    {
      // Ask the runtime to deallocate the condition
      if (snd_objc_condition_deallocate(_condition) == -1)
        {
          NSWarnMLog(@"snd_objc_condition_deallocate() failed");
        }
    }
  if (_mutex != 0)
    {
      // Ask the runtime to deallocate the mutex
      // If there are outstanding locks then it will block
      if (objc_mutex_deallocate(_mutex) == -1)
        {
          NSWarnMLog(@"objc_mutex_deallocate() failed");
        }
    }
}

// Return the current condition of the lock
- (int) condition
{
  return _condition_value;
}

// Acquiring and release the lock
- (void) lockWhenCondition: (int)value
{
  CHECK_RECURSIVE_CONDITION_LOCK(_mutex);

  if (objc_mutex_lock(_mutex) == -1)
    {
      [NSException raise: NSConditionLockException
        format: @"lockWhenCondition: failed to lock mutex"];
      /* NOT REACHED */
    }

  while (_condition_value != value)
    {
      if (snd_objc_condition_wait(_condition, _mutex) == -1)
        {
          [NSException raise: NSConditionLockException
            format: @"snd_objc_condition_wait failed"];
          /* NOT REACHED */
        }
    }
}

- (void) unlockWithCondition: (int)value
{
  int depth;

  // First check to make sure we have the lock
  depth = objc_mutex_trylock(_mutex);

  // Another thread has the lock so abort
  if (depth == -1)
    {
      [NSException raise: NSConditionLockException
        format: @"unlockWithCondition: Tried to unlock someone else's lock"];
      /* NOT REACHED */
    }

  // If the depth is only 1 then we just acquired
  // the lock above, bogus unlock so abort
  if (depth == 1)
    {
      [NSException raise: NSConditionLockException
        format: @"unlockWithCondition: Unlock attempted without lock"];
      /* NOT REACHED */
    }

  // This is a valid unlock so set the condition
  _condition_value = value;

  // wake up blocked threads
  if (snd_objc_condition_broadcast(_condition) == -1)
    {
      [NSException raise: NSConditionLockException
        format: @"unlockWithCondition: objc_condition_broadcast failed"];
      /* NOT REACHED */
    }

  // and unlock twice
  if ((objc_mutex_unlock(_mutex) == -1)
      || (objc_mutex_unlock(_mutex) == -1))
    {
      [NSException raise: NSConditionLockException
        format: @"unlockWithCondition: failed to unlock mutex"];
      /* NOT REACHED */
    }
}

- (BOOL) tryLock
{
  CHECK_RECURSIVE_CONDITION_LOCK(_mutex);

  // Ask the runtime to acquire a lock on the mutex
  if (objc_mutex_trylock(_mutex) == -1)
    return NO;
  else
    return YES;
}

- (BOOL) tryLockWhenCondition: (int)value
{
  // tryLock message will check for recursive locks

  // First can we even get the lock?
  if (![self tryLock])
    return NO;

  // If we got the lock is it the right condition?
  if (_condition_value == value)
    return YES;
  else
    {
      // Wrong condition so release the lock
      [self unlock];
      return NO;
    }
}

// Acquiring the lock with a date condition
- (BOOL) lockBeforeDate: (NSDate*)limit
{
  CHECK_RECURSIVE_CONDITION_LOCK(_mutex);

  while (objc_mutex_trylock(_mutex) == -1)
    {
      NSDate *current = [NSDate date];
      NSComparisonResult compare;

      compare = [current compare: limit];
      if (compare == NSOrderedSame || compare == NSOrderedDescending)
        {
          return NO;
        }
      /*
       * This should probably be more accurate like usleep(250)
       * but usleep is known to NOT be thread safe under all architectures.
       */
      sleep(1);
    }
  return YES;
}


- (BOOL) lockWhenCondition: (int)condition_to_meet
                beforeDate: (NSDate*)limitDate
{
#ifndef HAVE_OBJC_CONDITION_TIMEDWAIT
  [self notImplemented: _cmd];
  return NO;
#else
  NSTimeInterval atimeinterval;
  struct timespec endtime;

  CHECK_RECURSIVE_CONDITION_LOCK(_mutex);

  if (-1 == objc_mutex_lock(_mutex))
    [NSException raise: NSConditionLockException
                 format: @"lockWhenCondition: failed to lock mutex"];

  if (_condition_value == condition_to_meet)
    return YES;

  atimeinterval = [limitDate timeIntervalSince1970];
  endtime.tv_sec =(unsigned int)atimeinterval; // 941883028;//
  endtime.tv_nsec = (unsigned int)((atimeinterval - (float)endtime.tv_sec)
                                   * 1000000000.0);

  while (_condition_value != condition_to_meet)
    {
      switch (snd_objc_condition_timedwait(_condition, _mutex, &endtime))
        {
          case 0:
            break;
          case EINTR:
            break;
          case ETIMEDOUT :
            [self unlock];
            return NO;
          default:
            [NSException raise: NSConditionLockException
                         format: @"objc_condition_timedwait failed"];
            [self unlock];
            return NO;
        }
    }
  return YES;
#endif /* HAVE__OBJC_CONDITION_TIMEDWAIT */
}

// NSLocking protocol
// These methods ignore the condition
- (void) lock
{
  CHECK_RECURSIVE_CONDITION_LOCK(_mutex);

  // Ask the runtime to acquire a lock on the mutex
  // This will block
  if (objc_mutex_lock(_mutex) == -1)
    {
      [NSException raise: NSConditionLockException
        format: @"lock: failed to lock mutex"];
      /* NOT REACHED */
    }
}

- (void) unlock
{
  // wake up blocked threads
  if (snd_objc_condition_broadcast(_condition) == -1)
    {
      [NSException raise: NSConditionLockException
        format: @"unlockWithCondition: objc_condition_broadcast failed"];
      /* NOT REACHED */
    }

  // Ask the runtime to release a lock on the mutex
  if (objc_mutex_unlock(_mutex) == -1)
    {
      [NSException raise: NSConditionLockException
        format: @"unlock: failed to unlock mutex"];
      /* NOT REACHED */
    }
}

@end
