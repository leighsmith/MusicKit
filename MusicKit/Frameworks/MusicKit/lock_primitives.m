/*
  $Id$
  Defined In: The MusicKit

  Description: Mutex locks which allow recursive locks and unlocks by the same thread.

  Original Author: Michael B. Jones

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:26:05  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  daj/july 25, 1990 - Created file and changed extern to static.
  daj/july 22, 1991 - Added arg to rec_mutex_unlock

 */
/*
 * HISTORY:
 * $Log$
 * Revision 1.2  1999/07/29 01:26:05  leigh
 * Added Win32 compatibility, CVS logs, SBs changes
 *
 * Revision 2.1.1.2  89/07/20  17:20:20  mbj
 * 	13-Dec-88 Mary Thompson (mrt) @ Carnegie Mellon
 * 	Changed string_t to char * as string_t is no
 * 	longer defined in cthreads.h
 * 
 * Revision 2.1.1.1  89/07/20  17:18:06  mbj
 * 	Check parallel libc and file mapping changes into source tree branch.
 * 
 * 24-Jun-87  Michael Jones (mbj) at Carnegie-Mellon University
 *	Started from scratch.
 */

#include "lock_primitives.h"

#ifndef NO_CTHREAD
#define	NO_CTHREAD	((cthread_t) 0)
#endif	NO_CTHREAD

static rec_mutex_t
rec_mutex_alloc(void)
{
    register rec_mutex_t m;

    m = (rec_mutex_t) malloc(sizeof(struct rec_mutex));
    rec_mutex_init(m);
    return m;
}

static void
rec_mutex_init(rec_mutex_t m)
{
    m->thread = NO_CTHREAD;
    m->count = 0;
    mutex_init(& m->cthread_mutex);
}

#if 0
static void
rec_mutex_set_name(rec_mutex_t m, char * name)
{
    mutex_set_name(& m->cthread_mutex, name);
}

static char *
rec_mutex_name(rec_mutex_t m)
{
    return mutex_name(& m->cthread_mutex);
}

static void
rec_mutex_clear(rec_mutex_t m)
{
    m->thread = NO_CTHREAD;
    m->count = 0;
    mutex_clear(& m->cthread_mutex);
}

static void
rec_mutex_free(rec_mutex_t m)
{
    rec_mutex_clear(m);
    free((char *) m);
}
#endif

static int
rec_mutex_try_lock(rec_mutex_t m)
{
#ifndef WIN32
    cthread_t self = cthread_self();

    ASSERT(self != NO_CTHREAD);
    if (m->thread == self) {	/* If already holding lock */
	m->count += 1;
	return TRUE;
    }
    if (mutex_try_lock(& m->cthread_mutex)) {	/* If can acquire lock */
	ASSERT(m->count == 0);
	ASSERT(m->thread == NO_CTHREAD);
	m->count = 1;
	m->thread = self;
	return TRUE;
    }
#endif
    return FALSE;
}

static void
rec_mutex_lock(rec_mutex_t m)
{
#ifndef WIN32
    cthread_t self = cthread_self();

    ASSERT(self != NO_CTHREAD);
    if (m->thread == self) {	/* If already holding lock */
	m->count += 1;
    } else {
	mutex_lock(& m->cthread_mutex);
	ASSERT(m->count == 0);
	ASSERT(m->thread == NO_CTHREAD);
	m->count = 1;
	m->thread = self;
    }
#endif
}

static void
rec_mutex_unlock_no_count(rec_mutex_t m)
{
    if (m->thread == cthread_self()) {
	m->count = 0; /* Slam it. */
	m->thread = NO_CTHREAD;
	mutex_unlock(& m->cthread_mutex);
    }
}

static void
rec_mutex_unlock(rec_mutex_t m)
{
    if (m->thread == cthread_self()) {	/* Must be holding lock to unlock! */
	if (--(m->count) == 0) {
	    m->thread = NO_CTHREAD;
	    mutex_unlock(& m->cthread_mutex);
	}
    }
}

