/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description: 
    This program must run as root. This means it must be owned by root and
    have the u+s (setuid) bit set in its permission.

    It needs to be run only once after each reboot (assuming no program 
    DISables the fixed policy.  No NeXT programs do this). 

    I suggest you invoke this program from yours using system().

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT.
  Portions Copyright (c) 1994 Stanford University  
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.2  2002/09/24 16:57:02  leighsmith
  Cleaned up source, moved comments

*/
#import <mach/mach.h>
#import <mach/mach_init.h>
#import <mach/mach_error.h>
#import	<mach/message.h>
/* #import <mach/cthreads.h> */
#include <sys/types.h> /* for geteuid */
#include <unistd.h>    /* for geteuid */
#import <stdio.h>

int main(int ac,char *av[])
{
    kern_return_t ec;
    int disable = 0;
    int enable = 0;
    int quiet = 0;
    processor_set_t	dpset, dpset_priv;
    int i;
    /* Fix default processor set to take a fixed priority thread. */
    for (i=1; i<=(ac-1); i++) {
	if ((strcmp(av[i], "-q") == 0)) 
	    quiet = 1;
	else if ((strcmp(av[i], "-d") == 0)) {
	    disable = 1;
	    enable = 0;
	}
	else if ((strcmp(av[i], "-e") == 0)) {
	    disable = 0;
	    enable = 1;
	}
    }
    if (ac == 1 || (!disable && !enable)) {
	fprintf(stderr,"Usage: fixedpolicy -{e|d} [-q]\n");
	exit(1);
    }
    if (geteuid() != 0) {   /* See if we're set-uid-ed to root. */
	if (!quiet)
	    fprintf(stderr,
		    "fixedpolicy: Must run as root to change fixedpolicy.\n");
	exit(1);
    }
    ec = processor_set_default(host_self(), &dpset);
    if (ec != KERN_SUCCESS && !quiet) {
	fprintf(stderr,"fixedpolicy: can't get processor set.\n");
	exit(1);
    }
    ec = host_processor_set_priv(host_priv_self(), dpset, &dpset_priv);
    if (ec != KERN_SUCCESS && !quiet) {
	fprintf(stderr,"fixedpolicy: can't get private processor set port.\n");
	exit(1);
    }
    if (disable)
	ec = processor_set_policy_disable(dpset_priv, POLICY_FIXEDPRI, 0);
    else
        ec = processor_set_policy_enable(dpset_priv, POLICY_FIXEDPRI);
    if (ec != KERN_SUCCESS && !quiet) {
	fprintf(stderr,"fixedpolicy: can't %s fixed policy.\n",
		disable ? "disable" : "enable");
	exit(1);
    }
    if (!quiet)
	fprintf(stderr, "fixedpolicy: %s fixed scheduling policy.\n",
		disable ? "disabling" : "enabling");
    exit(0);
}


