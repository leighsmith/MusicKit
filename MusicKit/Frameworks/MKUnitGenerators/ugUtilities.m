/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* CCRMA changes copyright 1993-1996, Stanford University.  
   All rights reserved. */
#ifdef SHLIB
#include "shlib.h"
#endif

#import <MusicKit/MusicKit.h>

#import "AsympUG.h"
#import "AsympUGx.h"
#import "AsympUGy.h"
#import "AsympenvUG.h"
#import "AsympenvUGx.h"
#import "AsympenvUGy.h"

/* Public utilities */

/* A generic function for setting Asymps used as envelope handlers. */
/* Note that MKUpdateAsymp() must not reference any instance variables
 * of Asymp so that it may be used with other function handlers, such
 * as AsympenvUG.
 */

/*!
  TODO this should be in an header file somewhere...
  @brief Apply a DSP-synthesis envelope during a performance.
  @param
 */
 
void MKUpdateAsymp (id asymp, id envelope, double val0, double val1,
		    double attDur, double relDur, double portamentoTime,
		    MKPhraseStatus status)
    /*
     * Warning: This function is special-purpose and can do some strange
     * things.  For example, if you call it with MK_phraseUpdate and pass
     * in val0 and val1 not set to MK_NODVAL, it will reset the current
     * value.  This is almost certainly not what you want!
     *
     * Note also that attDur and relDur are ignored except on phraseOn
     * (and rearticulate and preempt) and phraseOff.
     */
{
    if (status <= MK_phraseRearticulate) {
	if (envelope) {                    /* new note? */
	    double attScl,relScl;
	    if (MKIsNoDVal(attDur))       /* No attDur param? */
	      attScl = 1.0;                /* Identity scaling. */
	    else {   
		double attackDur = [envelope attackDur];
		if (attackDur)             /* Does it have a non-0 attack? */
		  attScl = attDur / attackDur;
		else attScl = 0.0;
	    }
	    if (MKIsNoDVal(relDur))        /* No relDur param? */
	      relScl = 1.0;                /* Identity scaling. */
	    else {
		double releaseDur = [envelope releaseDur];
		if (releaseDur)            /* Does envelope have a decay? */
		  relScl = relDur / releaseDur;
		else relScl = 0.0;        
	    }
	    if (!MKIsNoDVal(val0) && !MKIsNoDVal(val1))
	      val1 -= val0;
	    else {
		if (MKIsNoDVal(val1))
		  val1 = 1.0;
		if (MKIsNoDVal(val0))
		  val0 = 0;
	    }
	    switch (status) {
	      case MK_phraseOnPreempt:
	      case MK_phraseOn:
		[asymp setEnvelope:envelope yScale:val1 yOffset:val0 xScale:
		 attScl releaseXScale:relScl funcPtr:NULL];
		break;
	      case MK_phraseRearticulate:
		[asymp resetEnvelope:envelope yScale:val1 yOffset:val0 xScale:
		 attScl releaseXScale:relScl funcPtr:NULL transitionTime:
		 portamentoTime];
		break;
	    }
	    return;
	}
    }
    else {     /* Status > MK_phraseRearticulate */
	if (envelope = [asymp envelope]) {   /* Don't require env passed here*/
	    if (!MKIsNoDVal(val1) || !MKIsNoDVal(val0)) {
		/* In this case we allow reset of scale and offset */
		if (!MKIsNoDVal(val0) && !MKIsNoDVal(val1))
		  val1 -= val0;
		else { /* The following isn't necessary if you assume params
			  are sticky in the SynthPatch */
		    if (MKIsNoDVal(val1))
		      val1 = 1.0;
		    if (MKIsNoDVal(val0))
		      val0 = 0;
		}
		[asymp setYScale:val1 yOffset:val0];
	    }
	    if ((status == MK_phraseOff) && (!MKIsNoDVal(relDur))) {
		double releaseDur = [envelope releaseDur];
		/* Note that currently this often gets evaluated twice,
		   once on the noteOn and once on the noteOff. Sigh. */
		if (releaseDur)
		  [asymp setReleaseXScale:relDur / releaseDur];
	    }
	    return;
	}
    }
    /* No envelope */
    if (!MKIsNoDVal(val1))
      [asymp setConstant:val1];
    else if (!MKIsNoDVal(val0))
      [asymp setConstant:val0];

}

static BOOL useRealTimeEnvelopes = NO;

id MKAsympUGxClass(void)
{
    return (useRealTimeEnvelopes) ? [AsympenvUGx class] : [AsympUGx class];
}

id MKAsympUGyClass(void)
{
    return (useRealTimeEnvelopes) ? [AsympenvUGy class] : [AsympUGy class];
}

void MKUseRealTimeEnvelopes(BOOL yesOrNo)
{
    useRealTimeEnvelopes = yesOrNo;
}

BOOL MKIsUsingRealTimeEnvelopes(void)
{
    return useRealTimeEnvelopes;
}


/* Private utilities */

static inline double log2(double x)
{
  return log(x)/log(2.0);
}

BOOL _MKUGIsPowerOf2 (int n)
{
  double y;
#if 1 /* modf() buggy on Intel? */
  /* Check common cases */
  int i;
  if (n == 256 || n == 128 || n == 512 || n == 1024 || n == 2048)
    return YES;
  for (i=2; i<8192;) {
      if (i==n)
	return YES;
      i *= 2;
  }
#endif
  return (fabs(modf(log2((double)n)+.0000001,&y)) < .000001);
}

int _MKUGNextPowerOf2(int n)
{
#if 1 /* modf() buggy or maybe not thread-safe on Intel? */
    int i;     /* Check common cases */
    if (n == 256 || n == 128 || n == 512 || n == 1024 || n == 2048)
      return n;
    i=2;
    while (i < n) 
      i *= 2;
    return i;
#else
    double y;
    double logN = log2((double)n)+.0000001; /* +eps necessary ! */
    if (fabs(modf(logN ,&y)) < 0.000001)
      return n;
    return (int)pow(2.0,(double)(((int)logN)+1));
#endif
}




