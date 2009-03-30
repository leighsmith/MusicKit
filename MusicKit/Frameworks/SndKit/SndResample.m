/* 
  $Id$

 Description:
   Sampling Rate Conversion Subroutines
   Implements sampling rate conversions by (almost) arbitrary factors.
   The program internally uses 16-bit data and 16-bit filter coefficients.

   Reference: "A Flexible Sampling-Rate Conversion Method,"
     J. O. Smith and P. Gossett, ICASSP, San Diego, 1984, Pgs 19.4.

   CHANGES from original SAIL program:

   1. LpScl is scaled by factor (when factor < 1) in resample() so this is
         done whether the filter was loaded or created.
   2. makeFilter() - ImpD[] is created from Imp[] instead of ImpR[], to
	 avoid problems with round-off errors.
   3. makeFilter() - ImpD[Nwing-1] gets NEGATIVE Imp[Nwing-1].
   4. SrcU/D() - Switched order of making guard bits (v>>Nhg) and
         normalizing.  This was done to prevent overflow.

   LIBRARIES needed:

   1. filterkit
       readFilter() - reads standard filter file
       FilterUp()   - applies filter to sample when factor >= 1
       FilterUD()   - applies filter to sample for any factor
   2. math

 
 Original Author:
   BY: Julius Smith (at CCRMA, Stanford U)
   C BY: translated from SAIL to C by Christopher Lee Fraley
         (cf0v@spice.cs.cmu.edu or @andrew.cmu.edu)
         maintained by Julius Smith (jos) and Mike Minnick (mminnick) at NeXT
   Added to the SndKit handling a variety of sound formats by Stephen Brandon
   Cleaned up by Leigh Smith

 Original License:
   Copyright (c) 1984, Julius Smith
   All rights reserved.
        
   This is free software from the Digital Audio Resampling Home Page:
   http://www-ccrma.stanford.edu/~jos/resample/.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

   Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
   Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
   Neither the name of CCRMA, Stanford University, nor the names of its
   contributors may be used to endorse or promote products derived from this
   software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNERS OR CONTRIBUTORS BE
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
   POSSIBILITY OF SUCH DAMAGE.

 Subsequent changes:
   Copyright (c) 1999, The MusicKit Project.  All rights reserved.

   Permission is granted to use and modify this code for commercial and
   non-commercial purposes so long as the author attribution and copyright
   messages remain intact and accompany all relevant code.
  
 Modification history prior to commital to CVS repository:

      06/07/88/clf    Version received from Chris Fraley
      04/23/90/mtm	Made function prototypes.
			Made local functions static.
			Use #import.
      03/06/91 mcnabb Modified to read & write NeXT mono & stereo sound files
      06/06/91 jos	Modification to contain default filter file.
			Switched from prompts to command-line options.
			Modified filter file format to include Nmult.
			Added choice between "small" and "large" filters.
      06/18/91 jos	Split resample.c into itself plus resamplesubs.c
      11/21/92 jos	Added linear interpolation and saturating overflow.
*/

#define IBUFFSIZE 4096                         /* Input buffer size */

#import <Foundation/Foundation.h>
#include "SndResample.h"
#include "_Sndsmallfilter.h"
#include "_Sndlargefilter.h"
#include "_Sndfilterkit.h"
#include "SndFunctions.h"
#import "SndMuLaw.h"

/* Read sound data inData of format inSndFormat, starting from beginFrom into a resampling buffer outPtrs
 * of nChans channels upto sampleArraySizeInFrames number of frames long, but store data between Xoff and
 * sampleArraySizeInFrames - Xoff with zero'd samples of Xoff length preceding and following the buffer.
 * return: 0 - notDone 
 *        >0 - index of last sample
 */
static int readData(
    int *beginFromFrame,  /* which frame to begin reading from in inData. */
    int inCount,	  /* specifies the total number of frames in the input data wanted retrieved. Could differ from the number of frames specified in inSndFormat. */
    SND_HWORD **outPtrs,  /* array of channels of sound samples, each sampleArraySizeInFrames long. */
    int sampleArraySizeInFrames,  /* specifies the number of frames (SND_HWORDS) to retrieve. */
    int nChans,           /* number of channels for input and output which must match, no averaging occurs */
    int Xoff,		  /* read into input array starting at this index */
    const SndFormat inSndFormat, /* take account of data format */
    void *inData) /* use this address for contiguous sample data to read from */
{
    int origFramesToOutput, framesToOutput;  // The number of frames to read into the output buffer. Two versions for debugging.
    int lastFrameIndex = 0;
    SND_HWORD *dataStart;    // where the first channel starts. Helps calculate the number of samples read.
    int channelIndex;
    SND_HWORD *shiftedOutPtrs[16]; // Maximum of 16 channels (change at will, or make dynamic if need be).
    int numOfFramesInInputBlock, currentFrameInInputBlock;
    int inDataFormat = inSndFormat.dataFormat;
    
    if (!inData) {
	NSLog(@"readData now only works with inData, no more SndSoundStructs.\n");
	return 0;
    }
    numOfFramesInInputBlock = inSndFormat.frameCount;
    currentFrameInInputBlock = 0;
    
    dataStart = outPtrs[0];
    for (channelIndex = 0; channelIndex < nChans; channelIndex++) {
	/* Start at designated sample number */
        shiftedOutPtrs[channelIndex] = outPtrs[channelIndex] + Xoff;
    }

    /* Calculate number of samples to retreive and store into the output buffer. */
    origFramesToOutput = framesToOutput = sampleArraySizeInFrames - Xoff;
    // NSLog(@"framesToOutput = %d\n", framesToOutput);

    if (numOfFramesInInputBlock != -1) {
        for (; framesToOutput > 0 && *beginFromFrame < inCount; framesToOutput--) {
	    for (channelIndex = 0; channelIndex < nChans; channelIndex++) {
		int sampleIndex = *beginFromFrame * nChans + channelIndex;
		
		switch(inDataFormat) {
		case SND_FORMAT_LINEAR_8:
		    *(shiftedOutPtrs[channelIndex]++) = ((signed char *)inData)[sampleIndex] << 8;
		    break;
		case SND_FORMAT_MULAW_8:
		    *(shiftedOutPtrs[channelIndex]++) = SndMuLawToLinear(((unsigned char *)inData)[sampleIndex]);
		    break;
		case SND_FORMAT_LINEAR_32:
		    *(shiftedOutPtrs[channelIndex]++) = (SND_HWORD)(((signed int *)inData)[sampleIndex] >> 16);
		    break;
		case SND_FORMAT_FLOAT:
		    *(shiftedOutPtrs[channelIndex]++) = (SND_HWORD)(((float *)inData)[sampleIndex] * MAX_HWORD);
		    break;
		case SND_FORMAT_DOUBLE:
		    *(shiftedOutPtrs[channelIndex]++) = (SND_HWORD)(((double *)inData)[sampleIndex] * MAX_HWORD);
		    break;
		default:
		case SND_FORMAT_LINEAR_16:
		    *(shiftedOutPtrs[channelIndex]++) = ((SND_HWORD *)inData)[sampleIndex];
		    break;
		}
	    }
            currentFrameInInputBlock++;
            (*beginFromFrame)++;
            if (currentFrameInInputBlock > numOfFramesInInputBlock) {
                NSLog(@"Error in resample - overreading data - should not happen, currentFrameInInputBlock = %d, numOfFramesInInputBlock = %d, origFramesToOutput = %d\n",
			currentFrameInInputBlock, numOfFramesInInputBlock, origFramesToOutput);
                break;
            }
        }
    }
    if (framesToOutput > 0) {
        lastFrameIndex = shiftedOutPtrs[0] - dataStart; /* (Calc return value) */
        while (--framesToOutput > 0) {	/*   fill unread spaces with 0's */
            for (channelIndex = 0; channelIndex < nChans; channelIndex++) {
		*(shiftedOutPtrs[channelIndex]++) = 0;
            }
        }
    }

    return(lastFrameIndex); /* return index of last samp */
}


#ifdef DEBUG
static int pof = 0;		/* positive overflow count */
static int nof = 0;		/* negative overflow count */
#endif

static INLINE SND_HWORD WordToHword(SND_WORD v, int scl)
{
    SND_HWORD out;
    SND_WORD llsb = (1<<(scl-1));
    v += llsb;		/* round */
    v >>= scl;
    if (v>MAX_HWORD) {
#ifdef DEBUG
        if (pof == 0)
          fprintf(stderr, "*** libsound: resample: sound sample overflow\n");
        else if ((pof % 10000) == 0)
          fprintf(stderr, "*** libsound: resample: "
                  "another ten thousand overflows\n");
        pof++;
#endif
        v = MAX_HWORD;
    } else if (v < MIN_HWORD) {
#ifdef DEBUG
        if (nof == 0)
          fprintf(stderr, "*** resample: sound sample (-) overflow ***\n");
        else if ((nof % 1000) == 0)
          fprintf(stderr, "*** resample: another thousand (-) overflows **\n");
        nof++;
#endif
        v = MIN_HWORD;
    }	
    out = (SND_HWORD) v;
    return out;
}

/* Sampling rate conversion using linear interpolation for maximum speed.
 */
static int
SrcLinear(SND_HWORD X[], SND_HWORD Y[], double factor, SND_UWORD *Time, SND_UHWORD Nx)
{
    SND_HWORD iconst;
    SND_HWORD *Xp, *Ystart;
    SND_WORD v,x1,x2;

    double dt;                  /* Step through input signal */
    SND_UWORD dtb;                  /* Fixed-point version of Dt */
    SND_UWORD endTime;              /* When Time reaches EndTime, return to user */

    dt = 1.0/factor;            /* Output sampling period */
    dtb = dt*(1<<Np) + 0.5;     /* Fixed-point representation */

    Ystart = Y;
    endTime = *Time + (1<<Np)*(SND_WORD)Nx;
    while (*Time < endTime)
    {
        iconst = (*Time) & Pmask;
        Xp = &X[(*Time)>>Np];      /* Ptr to current input sample */
        x1 = *Xp++;
        x2 = *Xp;
        x1 *= ((1<<Np)-iconst);
        x2 *= iconst;
        v = x1 + x2;
        *Y++ = WordToHword(v,Np);   /* Deposit output */
        *Time += dtb;		    /* Move to next sample by time increment */
    }
    return (Y - Ystart);            /* Return number of output samples */
}

/* Sampling rate up-conversion only subroutine;
 * Slightly faster than down-conversion;
 */
static int SrcUp(SND_HWORD X[], SND_HWORD Y[], double factor, SND_UWORD *Time,
                 SND_UHWORD Nx, SND_UHWORD Nwing, SND_UHWORD LpScl,
                 SND_HWORD Imp[], SND_HWORD ImpD[], BOOL Interp)
{
    SND_HWORD *Xp, *Ystart;
    SND_WORD v;

    double dt;                  /* Step through input signal */
    SND_UWORD dtb;                  /* Fixed-point version of Dt */
    SND_UWORD endTime;              /* When Time reaches EndTime, return to user */

    dt = 1.0/factor;            /* Output sampling period */
    dtb = dt*(1<<Np) + 0.5;     /* Fixed-point representation */

    Ystart = Y;
    endTime = *Time + (1<<Np)*(SND_WORD)Nx;
    while (*Time < endTime) {
                Xp = &X[*Time>>Np];      /* Ptr to current input sample */
                /* Perform left-wing inner product */
    v = FilterUp(Imp, ImpD, Nwing, Interp, Xp, (SND_HWORD)(*Time&Pmask),-1);
                /* Perform right-wing inner product */
                v += FilterUp(Imp, ImpD, Nwing, Interp, Xp+1,
                (SND_HWORD)((-*Time)&Pmask),1);
                v >>= Nhg;		/* Make guard bits */
                v *= LpScl;		/* Normalize for unity filter gain */
                *Y++ = WordToHword(v,NLpScl);   /* strip guard bits, deposit output */
                *Time += dtb;		/* Move to next sample by time increment */
    }
    return (Y - Ystart);        /* Return the number of output samples */
}


/* Sampling rate conversion subroutine */

static int SrcUD(SND_HWORD X[], SND_HWORD Y[], double factor, SND_UWORD *Time,
                 SND_UHWORD Nx, SND_UHWORD Nwing, SND_UHWORD LpScl,
                 SND_HWORD Imp[], SND_HWORD ImpD[], BOOL Interp)
{
    SND_HWORD *Xp, *Ystart;
    SND_WORD v;

    double dh;                      /* Step through filter impulse response */
    double dt;                      /* Step through input signal */
    SND_UWORD endTime;              /* When Time reaches EndTime, return to user */
    SND_UWORD dhb, dtb;             /* Fixed-point versions of Dh,Dt */

    dt = 1.0/factor;                /* Output sampling period */
    dtb = dt * (1 << Np) + 0.5;     /* Fixed-point representation */

    dh = MIN(Npc, factor * Npc);    /* Filter sampling period */
    dhb = dh * (1 << Na) + 0.5;     /* Fixed-point representation */

    Ystart = Y;
    endTime = *Time + (1 << Np) * (SND_WORD) Nx;
    while (*Time < endTime) {
        Xp = &X[*Time >> Np];	/* Ptr to current input sample */
	v = FilterUD(Imp, ImpD, Nwing, Interp, Xp, (SND_HWORD)(*Time&Pmask), -1, dhb);	/* Perform left-wing inner product */
	v += FilterUD(Imp, ImpD, Nwing, Interp, Xp+1, (SND_HWORD)((-*Time)&Pmask), 1, dhb);	/* Perform right-wing inner product */
        v >>= Nhg;		/* Make guard bits */
        v *= LpScl;		/* Normalize for unity filter gain */
        *Y++ = WordToHword(v, NLpScl);   /* strip guard bits, deposit output */
        *Time += dtb;		/* Move to next sample by time increment */
    }
    return (Y - Ystart);        /* Return the number of output samples */
}


static int err_ret(const char *formatString, ...)
{
    char fullString[120]; // should be long enough...
    va_list ap;

    va_start(ap, formatString);
    sprintf(fullString, "resample: %s \n\n", formatString);
    vfprintf(stderr, fullString, ap); /* Display error message  */
    va_end(ap);

    return -1;
}

static int resampleFast(  /* number of output samples returned */
    double factor,		/* factor = Sndout/Sndin */
    SND_HWORD *outPtr,		/* output data pointer */
    int inCount,		/* number of input samples to convert */
    int outCount,		/* number of output samples to compute */
    int nChans,			/* number of sound channels (1 to n) */
    const SndFormat inSndFormat, /* to pick up formats and frags*/
    int beginFrom,
    void *inData)               /* if non-null, gives an alternative
                                   source of contiguous audio data */
{
    SND_UWORD Time, Times[16];		/* Current time/pos in input sample */
    SND_UHWORD Xp, Ncreep, Xoff, Xread;
    int OBUFFSIZE = (int)(((double)IBUFFSIZE)*factor+2.0);
    SND_HWORD *X1S[16],*Y1S[16];

    SND_UHWORD Nout=0, Nx;

    int inPtrRun = beginFrom;    /* Running pointer thru input */
    int channels;

    int i=0, Ycount, last;

    Xoff = 10;

    for (channels = 0; channels < nChans; channels++){
        X1S[channels] = malloc(IBUFFSIZE * sizeof(SND_HWORD));
        Y1S[channels] = malloc(OBUFFSIZE * sizeof(SND_HWORD));
    }

    Nx = IBUFFSIZE - 2*Xoff;     /* # of samples to process each iteration */
    last = 0;			/* Have not read last input sample yet */
    Ycount = 0;			/* Current sample and length of output file */

    Xp = Xoff;			/* Current "now"-sample pointer for input */
    Xread = Xoff;		/* Position in input array to read into */
    Time = (Xoff<<Np);		/* Current-time pointer for converter */

    for (channels = 0; channels < nChans; channels++){
        for (i=0; i<Xoff; X1S[channels][i++]=0); /* Need Xoff zeros at begining of sample */
    }

    do {
        if (!last) {		/* If haven't read last sample yet */
            last = readData(&inPtrRun, inCount, X1S, IBUFFSIZE,
                            nChans, (int)Xread, inSndFormat, inData);
            if (last && (last-Xoff<Nx)) { /* If last sample has been read... */
            Nx = last-Xoff;	/* ...calc last sample affected by filter */
            if (Nx <= 0)
                break;
            }
        }

        /* Resample stuff in input buffer */
        for (channels = 0; channels < nChans; channels++) {
            Times[channels] = Time;
            Nout=SrcLinear(X1S[channels],Y1S[channels],factor,&Times[channels],Nx);
        }

        Time = Times[0];
        Time -= (Nx<<Np);	/* Move converter Nx samples back in time */
        Xp += Nx;		/* Advance by number of samples processed */
        Ncreep = (Time>>Np) - Xoff; /* Calc time accumulation in Time */
        if (Ncreep) {
            Time -= (Ncreep<<Np);    /* Remove time accumulation */
            Xp += Ncreep;            /* and add it to read pointer */
        }
        for (channels = 0; channels < nChans; channels++){
            for (i=0; i<IBUFFSIZE-Xp+Xoff; i++) { /* Copy part of input signal */
                    X1S[channels][i] = X1S[channels][i+Xp-Xoff]; /* that must be re-used */
            }
        }
        if (last) {		/* If near end of sample... */
            last -= Xp;		/* ...keep track were it ends */
            if (!last)		/* Lengthen input by 1 sample if... */
                    last++;		/* ...needed to keep flag TRUE */
        }
        Xread = i;		/* Pos in input buff to read new data into */
        Xp = Xoff;

        Ycount += Nout;
        if (Ycount>outCount) {
            Nout -= (Ycount-outCount);
            Ycount = outCount;
        }

        if (Nout > OBUFFSIZE) { /* Check to see if output buff overflowed */
            for (channels = 0; channels < nChans; channels++){
                    free(X1S[channels]);
                    free(Y1S[channels]);
            }
            return err_ret("Output array overflow");
        }

        {
            register SND_HWORD *op=outPtr;
            SND_HWORD *Y1P[16];
            for (channels = 0; channels < nChans; channels++) {
                Y1P[channels] = Y1S[channels];
            }
            while (Nout--) {
                for (channels = 0; channels < nChans; channels++) {
                    *op++ = *(Y1P[channels]++);
                }
            }
            outPtr = op;
        }
    } while (Ycount<outCount); /* Continue until done */
    for (channels = 0; channels < nChans; channels++){
            free(X1S[channels]);
            free(Y1S[channels]);
    }
    return(Ycount);		/* Return # of samples in output file */
}


static int resampleWithFilter(  /* number of output samples returned */
    double factor,		/* factor = Sndout/Sndin */
    SND_HWORD *outPtr,		/* output data pointer */
    int inCount,		/* number of input samples to convert */
    int outCount,		/* number of output samples to compute */
    int nChans,			/* number of sound channels (1 to n) */
    BOOL interpFilt,		/* TRUE means interpolate filter coeffs */
    SND_HWORD Imp[], SND_HWORD ImpD[],
    SND_UHWORD LpScl, SND_UHWORD Nmult, SND_UHWORD Nwing,
    const SndFormat inSndFormat, /* to pick up format */
    int beginFrom,
    void *inData)               /* source of contiguous audio data */
{
    SND_UWORD Time, Times[16];		/* Current time/pos in input sample */
    SND_UHWORD Xp, Ncreep, Xoff, Xread;
    int OBUFFSIZE = (int)(((double)IBUFFSIZE) * factor + 2.0);
    SND_HWORD *X1S[16], *Y1S[16];
    SND_UHWORD Nout = 0, Nx;
    int inPtrRun = beginFrom;
    int i = 0, Ycount, last;
    int channelIndex;

    /* Account for increased filter gain when using factors less than 1 */
    if (factor < 1)
        LpScl = LpScl * factor + 0.5;
    /* Calc reach of LP filter wing & give some creeping room */
    Xoff = ((Nmult + 1) / 2.0) * MAX(1.0, 1.0 / factor) + 10;
    if (IBUFFSIZE < 2 * Xoff)      /* Check input buffer size */
	return err_ret("IBUFFSIZE %d (or factor %lf) is too small compared to Xoff %u", IBUFFSIZE, factor, Xoff);
    Nx = IBUFFSIZE - 2 * Xoff;     /* # of samples to process each iteration */

    for (channelIndex = 0; channelIndex < nChans; channelIndex++){
        X1S[channelIndex] = malloc(IBUFFSIZE * sizeof(SND_HWORD));
        Y1S[channelIndex] = malloc(OBUFFSIZE * sizeof(SND_HWORD));
	// NSLog(@"Channel %d array: X1S = %p, Y1S = %p\n", channelIndex, X1S[channelIndex], Y1S[channelIndex]);
    }

    last = 0;			/* Have not read last input sample yet */
    Ycount = 0;			/* Current sample and length of output file */
    Xp = Xoff;			/* Current "now"-sample pointer for input */
    Xread = Xoff;		/* Position in input array to read into */
    Time = (Xoff << Np);	/* Current-time pointer for converter */

    for (channelIndex = 0; channelIndex < nChans; channelIndex++) {
        for (i = 0; i < Xoff; i++)
	    X1S[channelIndex][i] = 0; /* Need Xoff zeros at begining of sample */
    }
    do {
        if (!last) {		/* If haven't read last sample yet */
            last = readData(&inPtrRun, inCount, X1S, IBUFFSIZE, nChans, (int) Xread, inSndFormat, inData);
            if (last && (last - Xoff < Nx)) { /* If last sample has been read... */
                Nx = last - Xoff;	/* ...calc last sample affected by filter */
                if (Nx <= 0)
                    break;
            }
        }
        /* Resample stuff in input buffer */
        if (factor >= 1) {	/* SrcUp() is faster if we can use it */
            for (channelIndex = 0; channelIndex < nChans; channelIndex++){
		Times[channelIndex] = Time;
		Nout = SrcUp(X1S[channelIndex], Y1S[channelIndex], factor,
			&Times[channelIndex], Nx, Nwing, LpScl, Imp, ImpD, interpFilt);
            }
        }
        else {
            for (channelIndex = 0; channelIndex < nChans; channelIndex++) {
		Times[channelIndex] = Time;
		Nout = SrcUD(X1S[channelIndex], Y1S[channelIndex], factor,
			&Times[channelIndex], Nx, Nwing, LpScl, Imp, ImpD, interpFilt);
            }
        }
        Time = Times[0];
        Time -= (Nx << Np);	/* Move converter Nx samples back in time */
        Xp += Nx;		/* Advance by number of samples processed */
        Ncreep = (Time >> Np) - Xoff; /* Calc time accumulation in Time */
        if (Ncreep) {
            Time -= (Ncreep<<Np);    /* Remove time accumulation */
            Xp += Ncreep;            /* and add it to read pointer */
        }
        for (i = 0; i < IBUFFSIZE - Xp + Xoff; i++) { /* Copy part of input signal */
            for (channelIndex = 0; channelIndex < nChans; channelIndex++) {
		X1S[channelIndex][i] = X1S[channelIndex][i + Xp - Xoff]; /* that must be re-used */
            }
        }
        if (last) {		/* If near end of sample... */
            last -= Xp;		/* ...keep track were it ends */
            if (!last)		/* Lengthen input by 1 sample if... */
		last++;		/* ...needed to keep flag TRUE */
        }
        Xread = i;		/* Pos in input buff to read new data into */
        Xp = Xoff;

        Ycount += Nout;
        if (Ycount > outCount) {
            Nout -= (Ycount - outCount);
            Ycount = outCount;
        }

        if (Nout > OBUFFSIZE) { /* Check to see if output buff overflowed */
            for (channelIndex = 0; channelIndex < nChans; channelIndex++){
		free(X1S[channelIndex]);
		free(Y1S[channelIndex]);
            }
            return err_ret("Output array overflow");
        }
        {
            register SND_HWORD *op = outPtr;
            SND_HWORD *Y1P[16];
	    
            for (channelIndex = 0; channelIndex < nChans; channelIndex++) {
                Y1P[channelIndex] = Y1S[channelIndex];
            }
            while (Nout--) {
                for (channelIndex = 0; channelIndex < nChans; channelIndex++) {
                    *op++ = *(Y1P[channelIndex]++);
                }
            }
            outPtr = op;
        }
    } while (Ycount < outCount); /* Continue until done */

    for (channelIndex = 0; channelIndex < nChans; channelIndex++) {
        free(X1S[channelIndex]);
        free(Y1S[channelIndex]);
    }
    return(Ycount);		/* Return # of samples in output file */
}


int resample(			/* number of output samples returned */
    double factor,		/* factor = sample rate of Sndout/Sndin */
    SND_HWORD *outPtr,		/* output data pointer */
    int inCount,		/* number of input samples to convert */
    int outCount,		/* number of output samples to compute */
    int nChans,			/* number of sound channels (1 to n) */
    BOOL interpFilt,		/* TRUE means interpolate filter coeffs */
    int fastMode,		/* 0 = highest quality, slowest speed */
    BOOL largeFilter,		/* TRUE means use 65-tap FIR filter */
    char *filterFile,		/* NULL for internal filter, else filename */
    const SndFormat inSndFormat, /* for data format, channel and frame count, sample rate */
    int beginFrom,		/* The sample number within the sound to begin the resampling from */
    void *inData)               /* if non-null, gives an alternative source of contiguous audio data */
{
    SND_UHWORD LpScl;		/* Unity-gain scale factor */
    SND_UHWORD Nwing;		/* Filter table size */
    SND_UHWORD Nmult;		/* Filter length for up-conversions */
    SND_HWORD *Imp=0;		/* Filter coefficients */
    SND_HWORD *ImpD=0;		/* ImpD[n] = Imp[n+1]-Imp[n] */

    if (fastMode)
        return resampleFast(factor, outPtr, inCount, outCount, nChans, inSndFormat, beginFrom, inData);

#ifdef DEBUG  // turn this on only when SndResample.h is modified.
    /* Check for illegal constants */
    if (Np >= 16)
      return err_ret("Error: Np >= 16");
    if (Nb + Nhg + NLpScl >= 32)
      return err_ret("Error: Nb + Nhg + NLpScl >= 32");
    if (Nh + Nb > 32)
      return err_ret("Error: Nh + Nb > 32");
#endif

    /* Set defaults */
    if (filterFile != NULL && *filterFile != '\0') {
        if (readFilter(filterFile, &Imp, &ImpD, &LpScl, &Nmult, &Nwing))
	    return err_ret("could not find filter file, or syntax error in contents of filter file");
    }
    else if (largeFilter) {
        Nmult = LARGE_FILTER_NMULT;
        Imp = LARGE_FILTER_IMP;	        /* Impulse response */
        ImpD = LARGE_FILTER_IMPD;	/* Impulse response deltas */
        LpScl = LARGE_FILTER_SCALE;	/* Unity-gain scale factor */
        Nwing = LARGE_FILTER_NWING;	/* Filter table length */
    }
    else {
        Nmult = SMALL_FILTER_NMULT;
        Imp = SMALL_FILTER_IMP;	        /* Impulse response */
        ImpD = SMALL_FILTER_IMPD;	/* Impulse response deltas */
        LpScl = SMALL_FILTER_SCALE;	/* Unity-gain scale factor */
        Nwing = SMALL_FILTER_NWING;	/* Filter table length */
    }
#ifdef DEBUG
    NSLog(@"Attenuating resampler scale factor by 0.95 to reduce probability of clipping\n");
#endif
    LpScl *= 0.95;
    return resampleWithFilter(factor, outPtr, inCount, outCount, nChans,
                              interpFilt, Imp, ImpD, LpScl, Nmult, Nwing, inSndFormat, beginFrom, inData);
}
