/*
 * FILE: resamplesubs.c
 * Sampling Rate Conversion Subroutines
 *   BY: Julius Smith (at CCRMA, Stanford U)
 * C BY: translated from SAIL to C by Christopher Lee Fraley
 *          (cf0v@spice.cs.cmu.edu or @andrew.cmu.edu)
 *     : maintained by Julius Smith (jos) and Mike Minnick (mminnick) at NeXT
 *
 * Modification History:
 *      06/07/88/clf    Version received from Chris Fraley
 *	04/23/90/mtm	Made function prototypes.
 *			Made local functions static.
 *			Use #import.
 *      03/06/91 mcnabb Modified to read & write NeXT mono & stereo 
 *                      sound files
 *      06/06/91 jos	Modification to contain default filter file.
 *			Switched from prompts to command-line options.
 *			Modified filter file format to include Nmult.
 *			Added choice between "small" and "large" filters.
 *      06/18/91 jos	Split resample.c into itself plus resamplesubs.c
 *      11/21/92 jos	Added linear interpolation and saturating overflow.
 */

    /*
     *      Implements sampling rate conversions by (almost) arbitrary factors.
     *      The program internally uses 16-bit data and 16-bit filter
     *      coefficients.
     *
     *      Reference: "A Flexible Sampling-Rate Conversion Method,"
     *      J. O. Smith and P. Gossett, ICASSP, San Diego, 1984, Pgs 19.4.
     */
    
    /* CHANGES from original SAIL program:
     *
     * 1. LpScl is scaled by factor (when factor<1) in resample() so this is
     *       done whether the filter was loaded or created.
     * 2. makeFilter() - ImpD[] is created from Imp[] instead of ImpR[], to 
     *       avoid problems with round-off errors.
     * 3. makeFilter() - ImpD[Nwing-1] gets NEGATIVE Imp[Nwing-1].
     * 4. SrcU/D() - Switched order of making guard bits (v>>Nhg) and
     *       normalizing.  This was done to prevent overflow.
     */
    
    /* LIBRARIES needed:
     *
     * 1. filterkit
     *       readFilter() - reads standard filter file
     *       FilterUp()   - applies filter to sample when factor >= 1
     *       FilterUD()   - applies filter to sample for any factor
     *
     * 2. math
     */
    
#import <stdio.h>
#import <math.h>
#import <stdlib.h>

#import "stdefs.h"
#import "resample.h"

#define IBUFFSIZE 4096                         /* Input buffer size */

#include "small.filter"
#include "large.filter"
    
#import "filterkit.h"
#import <sound/sound.h>
#import <string.h>

static int readData(HWORD *inArray,
		    HWORD **inPtr,
		    int inCount,
		    HWORD *outPtr1, 
		    HWORD *outPtr2, 
		    int dataArraySize, 
		    int nChans, int Xoff)
    /* return: 0 - notDone */
    /*        >0 - index of last sample */
{
    int Nsamps, val=0;
    HWORD *dataStart;
    HWORD *inend = inArray + inCount*nChans;

    dataStart = outPtr1;
    Nsamps = dataArraySize - Xoff; /* Calculate number of samples to get */
    outPtr1 += Xoff;		/* Start at designated sample number */
    if (nChans==1) {
	for (; Nsamps>0; Nsamps--) {
	    if (*inPtr==inend) break;
	    *outPtr1++ = *(*inPtr)++;
	}
    } else {
	outPtr2 += Xoff;		/* Start at designated sample number */
	for (; Nsamps>0; Nsamps--) {
	    if (*inPtr==inend) break;
	    *outPtr1++ = *(*inPtr)++;
	    *outPtr2++ = *(*inPtr)++;
	}
    }
    if (Nsamps > 0) {
	val = outPtr1 - dataStart; /* (Calc return value) */
	while (--Nsamps >= 0) {	/*   fill unread spaces with 0's */
	    *outPtr1++ = 0;	/*   and return FALSE */
	    if (nChans==2)
	      *outPtr2++ = 0;
	}
    }
    return(val);
}



#ifdef DEBUG
static int pof = 0;		/* positive overflow count */
static int nof = 0;		/* negative overflow count */
#endif

static INLINE HWORD WordToHword(WORD v, int scl)
{
    HWORD out;
    WORD llsb = (1<(scl-1));
    if (v & llsb)
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
    out = (HWORD) v;
    return out;
}

/* Sampling rate conversion using linear interpolation for maximum speed.
 */
static int 
  SrcLinear(HWORD X[], HWORD Y[], double factor, UWORD *Time, UHWORD Nx)
{
    HWORD iconst;
    HWORD *Xp, *Ystart;
    WORD v,x1,x2;
    
    double dt;                  /* Step through input signal */ 
    UWORD dtb;                  /* Fixed-point version of Dt */
    UWORD endTime;              /* When Time reaches EndTime, return to user */
    
    dt = 1.0/factor;            /* Output sampling period */
    dtb = dt*(1<<Np) + 0.5;     /* Fixed-point representation */
    
    Ystart = Y;
    endTime = *Time + (1<<Np)*(WORD)Nx;
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
static int SrcUp(HWORD X[], HWORD Y[], double factor, UWORD *Time,
		 UHWORD Nx, UHWORD Nwing, UHWORD LpScl,
		 HWORD Imp[], HWORD ImpD[], BOOL Interp)
{
    HWORD *Xp, *Ystart;
    WORD v;
    
    double dt;                  /* Step through input signal */ 
    UWORD dtb;                  /* Fixed-point version of Dt */
    UWORD endTime;              /* When Time reaches EndTime, return to user */
    
    dt = 1.0/factor;            /* Output sampling period */
    dtb = dt*(1<<Np) + 0.5;     /* Fixed-point representation */
    
    Ystart = Y;
    endTime = *Time + (1<<Np)*(WORD)Nx;
    while (*Time < endTime)
    {
	Xp = &X[*Time>>Np];      /* Ptr to current input sample */
	/* Perform left-wing inner product */
	v = FilterUp(Imp, ImpD, Nwing, Interp, Xp, (HWORD)(*Time&Pmask),-1);
	/* Perform right-wing inner product */
	v += FilterUp(Imp, ImpD, Nwing, Interp, Xp+1, 
		      (HWORD)((-*Time)&Pmask),1);
	v >>= Nhg;		/* Make guard bits */
	v *= LpScl;		/* Normalize for unity filter gain */
	*Y++ = WordToHword(v,NLpScl);   /* strip guard bits, deposit output */
	*Time += dtb;		/* Move to next sample by time increment */
    }
    return (Y - Ystart);        /* Return the number of output samples */
}



/* Sampling rate conversion subroutine */

static int SrcUD(HWORD X[], HWORD Y[], double factor, UWORD *Time,
		 UHWORD Nx, UHWORD Nwing, UHWORD LpScl,
		 HWORD Imp[], HWORD ImpD[], BOOL Interp)
{
    HWORD *Xp, *Ystart;
    WORD v;
    
    double dh;                  /* Step through filter impulse response */
    double dt;                  /* Step through input signal */
    UWORD endTime;              /* When Time reaches EndTime, return to user */
    UWORD dhb, dtb;             /* Fixed-point versions of Dh,Dt */
    
    dt = 1.0/factor;            /* Output sampling period */
    dtb = dt*(1<<Np) + 0.5;     /* Fixed-point representation */
    
    dh = MIN(Npc, factor*Npc);  /* Filter sampling period */
    dhb = dh*(1<<Na) + 0.5;     /* Fixed-point representation */
    
    Ystart = Y;
    endTime = *Time + (1<<Np)*(WORD)Nx;
    while (*Time < endTime)
    {
	Xp = &X[*Time>>Np];	/* Ptr to current input sample */
	v = FilterUD(Imp, ImpD, Nwing, Interp, Xp, (HWORD)(*Time&Pmask),
		     -1, dhb);	/* Perform left-wing inner product */
	v += FilterUD(Imp, ImpD, Nwing, Interp, Xp+1, (HWORD)((-*Time)&Pmask),
		      1, dhb);	/* Perform right-wing inner product */
	v >>= Nhg;		/* Make guard bits */
	v *= LpScl;		/* Normalize for unity filter gain */
	*Y++ = WordToHword(v,NLpScl);   /* strip guard bits, deposit output */
	*Time += dtb;		/* Move to next sample by time increment */
    }
    return (Y - Ystart);        /* Return the number of output samples */
}



static int err_ret(char *s)
{
    fprintf(stderr,"resample: %s \n\n",s); /* Display error message  */
    return -1;
}

static int resampleFast(  /* number of output samples returned */
    double factor,		/* factor = Sndout/Sndin */
    HWORD *inPtr,		/* input data pointer */
    HWORD *outPtr,		/* output data pointer */
    int inCount,		/* number of input samples to convert */
    int outCount,		/* number of output samples to compute */
    int nChans)			/* number of sound channels (1 or 2) */
{
    UWORD Time, Time2;		/* Current time/pos in input sample */
    UHWORD Xp, Ncreep, Xoff, Xread;
    int OBUFFSIZE = (int)(((double)IBUFFSIZE)*factor+2.0);
    HWORD X1[IBUFFSIZE], Y1[OBUFFSIZE]; /* I/O buffers */
    HWORD X2[IBUFFSIZE], Y2[OBUFFSIZE]; /* I/O buffers */
    UHWORD Nout, Nx;
    HWORD *inPtrRun = inPtr;	/* Running pointer thru input */
    int i, Ycount, last;
    
    Xoff = 10;

    Nx = IBUFFSIZE - 2*Xoff;     /* # of samples to process each iteration */
    last = 0;			/* Have not read last input sample yet */
    Ycount = 0;			/* Current sample and length of output file */

    Xp = Xoff;			/* Current "now"-sample pointer for input */
    Xread = Xoff;		/* Position in input array to read into */
    Time = (Xoff<<Np);		/* Current-time pointer for converter */
    
    for (i=0; i<Xoff; X1[i++]=0); /* Need Xoff zeros at begining of sample */
    for (i=0; i<Xoff; X2[i++]=0); /* Need Xoff zeros at begining of sample */

    do {
	if (!last)		/* If haven't read last sample yet */
	{
	    last = readData(inPtr, &inPtrRun, inCount, X1, X2, IBUFFSIZE, 
			    nChans, (int)Xread);
	    if (last && (last-Xoff<Nx)) { /* If last sample has been read... */
		Nx = last-Xoff;	/* ...calc last sample affected by filter */
		if (Nx <= 0)
		  break;
	    }
	}

	/* Resample stuff in input buffer */
	Time2 = Time;
	Nout=SrcLinear(X1,Y1,factor,&Time,Nx);
	if (nChans==2)
	  Nout=SrcLinear(X2,Y2,factor,&Time2,Nx);

	Time -= (Nx<<Np);	/* Move converter Nx samples back in time */
	Xp += Nx;		/* Advance by number of samples processed */
	Ncreep = (Time>>Np) - Xoff; /* Calc time accumulation in Time */
	if (Ncreep) {
	    Time -= (Ncreep<<Np);    /* Remove time accumulation */
	    Xp += Ncreep;            /* and add it to read pointer */
	}
	for (i=0; i<IBUFFSIZE-Xp+Xoff; i++) { /* Copy part of input signal */
	    X1[i] = X1[i+Xp-Xoff]; /* that must be re-used */
	    if (nChans==2)
	      X2[i] = X2[i+Xp-Xoff]; /* that must be re-used */
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

	if (Nout > OBUFFSIZE) /* Check to see if output buff overflowed */
	  return err_ret("Output array overflow");
	
	if (nChans==1) {
	    register HWORD *y1p = &(Y1[0]);
	    register HWORD *op = outPtr;
	    while (Nout--)	/* Nout is UNSIGNED */
	      *op++ = *y1p++;
	    outPtr = op;
	} else {
	    register HWORD *y1p = &(Y1[0]);
	    register HWORD *y2p = &(Y2[0]);
	    register HWORD *op = outPtr;
	    while (Nout--) {
		*op++ = *y1p++;
		*op++ = *y2p++;
	    }
	    outPtr = op;
	}
    } while (Ycount<outCount); /* Continue until done */
    return(Ycount);		/* Return # of samples in output file */
}


static int resampleWithFilter(  /* number of output samples returned */
    double factor,		/* factor = Sndout/Sndin */
    HWORD *inPtr,		/* input data pointer */
    HWORD *outPtr,		/* output data pointer */
    int inCount,		/* number of input samples to convert */
    int outCount,		/* number of output samples to compute */
    int nChans,			/* number of sound channels (1 or 2) */
    BOOL interpFilt,		/* TRUE means interpolate filter coeffs */
    HWORD Imp[], HWORD ImpD[],
    UHWORD LpScl, UHWORD Nmult, UHWORD Nwing)
{
    UWORD Time, Time2;		/* Current time/pos in input sample */
    UHWORD Xp, Ncreep, Xoff, Xread;
    int OBUFFSIZE = (int)(((double)IBUFFSIZE)*factor+2.0);
    HWORD X1[IBUFFSIZE], Y1[OBUFFSIZE]; /* I/O buffers */
    HWORD X2[IBUFFSIZE], Y2[OBUFFSIZE]; /* I/O buffers */
    UHWORD Nout, Nx;
    HWORD *inPtrRun = inPtr;	/* Running pointer thru input */
    int i, Ycount, last;
    
    /* Account for increased filter gain when using factors less than 1 */
    if (factor < 1)
      LpScl = LpScl*factor + 0.5;
    /* Calc reach of LP filter wing & give some creeping room */
    Xoff = ((Nmult+1)/2.0) * MAX(1.0,1.0/factor) + 10;
    if (IBUFFSIZE < 2*Xoff)      /* Check input buffer size */
      return err_ret("IBUFFSIZE (or factor) is too small");
    Nx = IBUFFSIZE - 2*Xoff;     /* # of samples to process each iteration */
    
    last = 0;			/* Have not read last input sample yet */
    Ycount = 0;			/* Current sample and length of output file */
    Xp = Xoff;			/* Current "now"-sample pointer for input */
    Xread = Xoff;		/* Position in input array to read into */
    Time = (Xoff<<Np);		/* Current-time pointer for converter */
    
    for (i=0; i<Xoff; X1[i++]=0); /* Need Xoff zeros at begining of sample */
    for (i=0; i<Xoff; X2[i++]=0); /* Need Xoff zeros at begining of sample */
        
    do {
	if (!last)		/* If haven't read last sample yet */
	{
	    last = readData(inPtr, &inPtrRun, inCount, X1, X2, IBUFFSIZE, 
			    nChans, (int)Xread);
	    if (last && (last-Xoff<Nx)) { /* If last sample has been read... */
		Nx = last-Xoff;	/* ...calc last sample affected by filter */
		if (Nx <= 0)
		  break;
	    }
	}
	/* Resample stuff in input buffer */
	Time2 = Time;
	if (factor >= 1) {	/* SrcUp() is faster if we can use it */
	    Nout=SrcUp(X1,Y1,factor,&Time,Nx,Nwing,LpScl,Imp,ImpD,interpFilt);
	    if (nChans==2)
	      Nout=SrcUp(X2,Y2,factor,&Time2,Nx,Nwing,LpScl,Imp,ImpD,
			 interpFilt);
	}
	else {
	    Nout=SrcUD(X1,Y1,factor,&Time,Nx,Nwing,LpScl,Imp,ImpD,interpFilt);
	    if (nChans==2)
	      Nout=SrcUD(X2,Y2,factor,&Time2,Nx,Nwing,LpScl,Imp,ImpD,
			 interpFilt);
	}

	Time -= (Nx<<Np);	/* Move converter Nx samples back in time */
	Xp += Nx;		/* Advance by number of samples processed */
	Ncreep = (Time>>Np) - Xoff; /* Calc time accumulation in Time */
	if (Ncreep) {
	    Time -= (Ncreep<<Np);    /* Remove time accumulation */
	    Xp += Ncreep;            /* and add it to read pointer */
	}
	for (i=0; i<IBUFFSIZE-Xp+Xoff; i++) { /* Copy part of input signal */
	    X1[i] = X1[i+Xp-Xoff]; /* that must be re-used */
	    if (nChans==2)
	      X2[i] = X2[i+Xp-Xoff]; /* that must be re-used */
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

	if (Nout > OBUFFSIZE) /* Check to see if output buff overflowed */
	  return err_ret("Output array overflow");
	
	if (nChans==1) {
	    register HWORD *y1p = &(Y1[0]);
	    register HWORD *op = outPtr;
	    while (Nout--)	/* Nout is UNSIGNED */
	      *op++ = *y1p++;
	    outPtr = op;
	} else {
	    register HWORD *y1p = &(Y1[0]);
	    register HWORD *y2p = &(Y2[0]);
	    register HWORD *op = outPtr;
	    while (Nout--) {
		*op++ = *y1p++;
		*op++ = *y2p++;
	    }
	    outPtr = op;
	}
    } while (Ycount<outCount); /* Continue until done */
    return(Ycount);		/* Return # of samples in output file */
}



int resample(			/* number of output samples returned */
    double factor,		/* factor = Sndout/Sndin */
    HWORD *inPtr,		/* input data pointer */
    HWORD *outPtr,		/* output data pointer */
    int inCount,		/* number of input samples to convert */
    int outCount,		/* number of output samples to compute */
    int nChans,			/* number of sound channels (1 or 2) */
    BOOL interpFilt,		/* TRUE means interpolate filter coeffs */
    int fastMode,		/* 0 = highest quality, slowest speed */
    BOOL largeFilter,		/* TRUE means use 65-tap FIR filter */
    char *filterFile)		/* NULL for internal filter, else filename */
{
    UHWORD LpScl;		/* Unity-gain scale factor */
    UHWORD Nwing;		/* Filter table size */
    UHWORD Nmult;		/* Filter length for up-conversions */
    HWORD *Imp=0;		/* Filter coefficients */
    HWORD *ImpD=0;		/* ImpD[n] = Imp[n+1]-Imp[n] */
    
    if (fastMode)
      return resampleFast(factor,inPtr,outPtr,inCount,outCount,nChans);

#ifdef DEBUG
    /* Check for illegal constants */
    if (Np >= 16)
      return err_ret("Error: Np>=16");
    if (Nb+Nhg+NLpScl >= 32)
      return err_ret("Error: Nb+Nhg+NLpScl>=32");
    if (Nh+Nb > 32)
      return err_ret("Error: Nh+Nb>32");
#endif
    
    /* Set defaults */

    if (filterFile != NULL && *filterFile != '\0') {
	if (readFilter(filterFile, &Imp, &ImpD, &LpScl, &Nmult, &Nwing))
	  return err_ret("could not find filter file, "
	       "or syntax error in contents of filter file");
    } else if (largeFilter) {
	Nmult = LARGE_FILTER_NMULT;
	Imp = LARGE_FILTER_IMP;	/* Impulse response */
	ImpD = LARGE_FILTER_IMPD;	/* Impulse response deltas */
	LpScl = LARGE_FILTER_SCALE;	/* Unity-gain scale factor */
	Nwing = LARGE_FILTER_NWING;	/* Filter table length */
    } else {
	Nmult = SMALL_FILTER_NMULT;
	Imp = SMALL_FILTER_IMP;	/* Impulse response */
	ImpD = SMALL_FILTER_IMPD;	/* Impulse response deltas */
	LpScl = SMALL_FILTER_SCALE;	/* Unity-gain scale factor */
	Nwing = SMALL_FILTER_NWING;	/* Filter table length */
    }
#if DEBUG
    fprintf(stderr,"Attenuating resampler scale factor by 0.95 "
	    "to reduce probability of clipping\n");
#endif
    LpScl *= 0.95;
    return resampleWithFilter(factor,inPtr,outPtr,inCount,outCount,nChans, 
			      interpFilt, Imp, ImpD, LpScl, Nmult, Nwing);
}
