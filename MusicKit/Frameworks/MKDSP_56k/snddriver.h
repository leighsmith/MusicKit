#ifndef __MK_snddriver_H___
#define __MK_snddriver_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#include <SoundKit/sounddriver.h>

#if VERSION_1

/* Needed before 0.97: extern int open(char *path, int flags, int mode); */

kern_return_t snddriver_dsp_reset (
	port_t		cmd_port,		// valid command port
	int		priority)		// priority of this transaction
{
    return KERN_SUCCESS;
}

kern_return_t snddriver_set_dsp_buffers_per_soundout_buffer (
	port_t		dev_port,		// valid device port
	port_t		owner_port,		// valid owner port
	int		dbpsob)			// so buf size / dsp buf size
{
    return KERN_SUCCESS;
}

#endif

#endif
