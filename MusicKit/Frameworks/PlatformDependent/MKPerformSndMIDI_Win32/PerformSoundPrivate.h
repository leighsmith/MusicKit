/*
  $Id$

  Description:
    PerformSound.h is a public header used with ObjC,
    so we don't want LPDIRECTSOUND definitions there. 
    This file holds non-public prototypes.

  Original Author: Leigh Smith <leigh@tomandandy.com>

  Copyright (C) 1999 Permission is granted to use this code for commercial and
  non-commercial purposes so long as this copyright statement (noting the author) is
  preserved.
*/
/*
  $Log$
  Revision 1.1  1999/11/17 17:57:14  leigh
  Initial revision

*/

#include "PerformSound.h"

#ifdef __cplusplus
extern "C" {
#endif

// return the DirectSound object (for DirectMusic cooperation), or NULL if not using it.
LPDIRECTSOUND SNDGetDirectSound(void);

#ifdef __cplusplus
}
#endif