#ifndef __MK__time_H___
#define __MK__time_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*  Modification history:

    daj/04/23/90 - Created from _musickit.h 

*/
/* Time offsets and conversions */
extern void _MKSetConductedPerformance(BOOL yesOrNo,id conductorClass);
extern double _MKLastTime();
extern double _MKAdjustTime(double newTime);
extern double _MKTime();      /* Gets clock time, before deltaT added. */ 
extern double _MKDeltaTTime();/* Gets clock time, after deltaT is added. */
extern double _MKGetDeltaT(); /* Gets deltaT (Clock time - real time). */
extern void _MKSetDeltaT(double val); /* Sets deltaT (Clock time-real time). */

#endif
