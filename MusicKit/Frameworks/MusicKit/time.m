/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: musickit.h

  Description: 
    This file makes it possible to do a non-conducted performance. It 
    implements a "loose link" to MKConductor and provides defaults when there's
    no MKConducted performance. It also insures that the "after performance
    queues" get implemented in a non-conducted performance.

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/ 
/* 
Modification history:

  $Log$
  Revision 1.6  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.5  2001/08/31 21:01:59  skotmcdonald
  Changed calls to conductor time to appropriate new timeInSeconds, timeInBeats calls

  Revision 1.4  1999/09/04 23:02:34  leigh
  Source cleanup

  Revision 1.3  1999/08/06 17:27:53  leigh
  cleaned copyright and comments

  Revision 1.2  1999/07/29 01:26:17  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  11/22/89/daj - Optimized MKGetDeltaTTime() and MKGetTime().
  01/08/90/daj - Added comments.
  02/01/90/daj - Added comment.
  03/13/90/daj - Changes for categories of private msgs.
  04/27/90/daj - Shlib changes: Made _MKSetConductedPerformance reset myTime
                 to 0. (See corresponding change in Conductor.m)
  09/02/90/daj - Changed MAXDOUBLE references to noDVal.h way of doing things
      
*/

#define MK_INLINE 1
#import "_musickit.h"
#import "ConductorPrivate.h"

static double myTime = 0;
static double deltaT = 0;
static BOOL   conductedPerformance    = NO;
static BOOL   wasConductedPerformance = NO;
static id     cond = nil;
static double (*getTimeImp)() = NULL;

void _MKSetConductedPerformance(BOOL yesOrNo,id conductorClass)
    /* Called by the Conductor to set when there's a conducted performance.
       The passing of the conductorClass is an artifact of when the
       musickit was not a shlib. */
{
    if (!yesOrNo && conductedPerformance) {
        wasConductedPerformance = YES;
        myTime = 0; // Reset in case next performance isn't conducted. 
    }
    conductedPerformance = yesOrNo;
    cond = conductorClass;
    getTimeImp = (double (*)())[conductorClass methodForSelector:@selector(timeInSeconds)];
}

double _MKLastTime()
{
    /* Here we need to be careful because time may already have been
       reset, so we have to use the special method _getLastTime. */

    cond = _MKClassConductor();
    /* Here we don't want to check conductedPerformance 
       because performance is probably over. Also we don't want to 
       use cond as a test, since it's conceivable that the performance
       hasn't started yet. */
    if (conductedPerformance || wasConductedPerformance)
        return [cond _getLastTime] + deltaT;
    else 
        return MKGetDeltaTTime();
}

double MKGetTime(void) 
    /* Returns the time in seconds. */
{
    if (conductedPerformance && cond == nil)
        NSLog(@"MKGetTime: conductedPerformance is true, but cond is nil!");
    return ((conductedPerformance) ? 
        (myTime = (*getTimeImp)(cond, @selector(timeInSeconds))): myTime);
}

double MKSetTime(double newTime)
    /* Sets time as indicated. 
       This has no effect (MK_NODVAL is returned) during a conducted 
       performance. It is provided only for non-conducted performances. 
       Sets time to newTime. Caution must be exercised when using this 
       function. */
{
    if (conductedPerformance)
        return MK_NODVAL;
    wasConductedPerformance = NO; 

    /* The first call to MKSetTime() after a conducted performance is over
       resets this variable. Hence, there is a (safe) assumption that nobody
       will call MKSetTime() between the time the conductor finishes its
       performance and the time that MKOrchestra close is called. (This is the
       only situation where the value of wasConductedPerformance matters). */

    return myTime = newTime;
}

double _MKAdjustTime(double newTime)
    /* Adjusts the time as specified. This is used, e.g. by MKMidi for 
       setting the time as specified in incoming Midi time stamps.
       */
{
    if (conductedPerformance)
      myTime = [cond _adjustTimeNoTE:newTime];
    else myTime = MAX(newTime,myTime);
    return myTime;
}

static int deltaTMode = MK_DELTAT_DEVICE_LAG;

void MKSetDeltaTMode(int newMode)
{
    deltaTMode = newMode;
}

int MKGetDeltaTMode(void)
{
    return deltaTMode;
}

double MKGetDeltaT(void)
    /* Returns deltaT, in seconds. */
{
    return deltaT;
}

double MKGetDeltaTTime(void)
    /* Returns deltaT + time, in seconds. */
{
    if (deltaTMode == MK_DELTAT_DEVICE_LAG)
        return deltaT + MKGetTime();
    else 
        return MKGetTime();
}

void MKSetDeltaT(double val)
    /* Sets deltaT, in seconds. */
{
    if (val >= 0)
      deltaT = val;
}

void MKFinishPerformance(void)
    /* If the performance is conducted, this is the same as 
       [MKConductor finishPerformance]. Otherwise, it tells
       Performers and Instruments the performance is over. (Precisely,
       it evaluates the "after performance" queue.) 
       */
{
    [_MKClassConductor() finishPerformance];
}

