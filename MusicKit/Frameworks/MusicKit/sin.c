/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* Simple sine table of size 1024 with linear interpolation.  Note that this
   version differs from the one in fastFft.c in that the latter takes its
   argument in terms of the FFT size.  This one makes no such assumptions. */

#import <math.h>
#define SINTABLEN 1024

// Dear WinNT doesn't know about PI, stolen from MacOSX-Servers math.h definition
#ifndef M_PI
#define M_PI            3.14159265358979323846  /* pi */
#endif
#ifndef M_PI_2
#define M_PI_2          1.57079632679489661923  /* pi/2 */
#endif

static unsigned char sinTabInited = 0;
static double sinTab[SINTABLEN];

static void initSineTab(void)
{
    int i;
    for (i=0; i<SINTABLEN; i++) 
	sinTab[i] = sin(i * (M_PI * 2/SINTABLEN));
}

static double mySin(double x)
{
    int floorVal;
    double diff;
    if (!sinTabInited) {
	initSineTab();
	sinTabInited = 1;
    }
    while (x < 0) 
	x += (M_PI * 2);
    while (x > (M_PI*2))
	x -= (M_PI * 2);
    x *= SINTABLEN/(2 * M_PI);
    floorVal = x; 
    diff = x-floorVal;
    if (floorVal == SINTABLEN-1)
	return sinTab[floorVal] * (1-diff) + sinTab[0] * diff;
    else return sinTab[floorVal] * (1-diff) + sinTab[floorVal+1] * diff;
}

static double myCos(double x)
{
    return mySin(x + M_PI_2);
}

