/* resamplesubs.c - sampling rate conversion subroutines */
// Altered version
#import "_Sndresample.h"

#ifndef WIN32
#import <libc.h>
#else
#import <stdio.h>
#import <malloc.h>
#endif

#define IBUFFSIZE 4096                         /* Input buffer size */

#include "_Sndsmallfilter.h"
#include "_Sndlargefilter.h"

#import "_Sndfilterkit.h"
//#import <sound/sound.h>
#import "SndFunctions.h"

static int readData(
                    int *inPtr,
                    int inCount,
                    SND_HWORD **outPtrs,
                    int dataArraySize,
                    int nChansOut, int Xoff,
                    const SndSoundStruct *inSnd)  /*sb: take account of data format */
    /* return: 0 - notDone */
    /*        >0 - index of last sample */
{
    int Nsamps, val=0;
    SND_HWORD *dataStart;
    void *newDataStarts[16];/* max 16 channel */
    int channels;
    int nChansIn = inSnd->channelCount;
    int inend = inCount * nChansIn;
    SND_HWORD *myOutPtrs[16];

        int lastSampleInBlock, currentSample;
        int origNsamps;
        int df;

        void *mainIndex = SndGetDataAddresses(*inPtr/nChansIn,
                inSnd,
                (int *)&lastSampleInBlock, /* channel independent */
                (int *)&currentSample);     /* channel independent */
        df = inSnd->dataFormat;
    if (df == SND_FORMAT_INDIRECT)
                df = ((SndSoundStruct *)(*((SndSoundStruct **)
                        (inSnd->dataLocation))))->dataFormat;
    dataStart = outPtrs[0];
    origNsamps = Nsamps = dataArraySize - Xoff; /* Calculate number of samples to get */
        for (channels = 0; channels < nChansOut; channels++) {
                myOutPtrs[channels] = outPtrs[channels] + Xoff;		/* Start at designated sample number */
                newDataStarts[channels] = myOutPtrs[channels];
        }

        if (lastSampleInBlock != -1) {
                for (; Nsamps>0; Nsamps--) {
                        if (*inPtr==inend) break;
                        if (nChansIn == nChansOut) {
                                for (channels = 0; channels < nChansOut; channels++) {
                                        switch(df) {
                                                case SND_FORMAT_LINEAR_8:
                                                        *(myOutPtrs[channels]++) =
                                                                ((signed char *)mainIndex)[currentSample * nChansIn + channels] << 8;
                                                        break;
                                                case SND_FORMAT_MULAW_8:
                                                        *(myOutPtrs[channels]++) =
                                                                SndiMulaw(((unsigned char *)mainIndex)[currentSample * nChansIn + channels]);
                                                        break;
                                                case SND_FORMAT_LINEAR_32:
                                                        *(myOutPtrs[channels]++) =
                                                (SND_HWORD)(((signed int *)mainIndex)[currentSample * nChansIn + channels] >> 16);
                                                        break;
                                                case SND_FORMAT_FLOAT:
                                                        *(myOutPtrs[channels]++) =
                                                (SND_HWORD)(((float *)mainIndex)[currentSample * nChansIn + channels]);
                                                        break;
                                                case SND_FORMAT_DOUBLE:
                                                        *(myOutPtrs[channels]++) =
                                                (SND_HWORD)(((double *)mainIndex)[currentSample * nChansIn + channels]);
                                                        break;
                                                default:
                                                case SND_FORMAT_LINEAR_16:
                                                        *(myOutPtrs[channels]++) =
                                                ((SND_HWORD *)mainIndex)[currentSample * nChansIn + channels];
                                                        break;
                                        }
                                }
                        }
                        else { /* reduce num of channels by averaging alternate pairs/quads of channels */
                                int chansToSum = nChansIn / nChansOut;
                                int passes = nChansOut;/*convenience name*/
                                int m,n;

                                for (m = 0;m < passes; m++) { /*m and n take us through 1 chnl indep sample*/
                                        long sum = 0;
                                        float sumFloat = 0.0;
                                        double sumDouble = 0.0;
                                        for (n = 0; n < chansToSum; n++) {
                                                switch(df) {
                                                        case SND_FORMAT_LINEAR_8:
                                                                sum += ((signed char *)mainIndex)[currentSample * nChansIn + n] << 8;
                                                                break;
                                                        case SND_FORMAT_MULAW_8:
                                                                sum += SndiMulaw(((unsigned char *)mainIndex)[currentSample * nChansIn + n]);
                                                                break;
                                                        case SND_FORMAT_LINEAR_32:
                                                        sum += (SND_HWORD)(((signed int *)mainIndex)[currentSample * nChansIn + n] >> 16);
                                                                break;
                                                        case SND_FORMAT_FLOAT:
                                                        sumFloat += (SND_HWORD)(((float *)mainIndex)[currentSample * nChansIn + n]);
                                                                break;
                                                        case SND_FORMAT_DOUBLE:
                                                        sumDouble += (SND_HWORD)(((double *)mainIndex)[currentSample * nChansIn + n]);
                                                                break;
                                                        default:
                                                        case SND_FORMAT_LINEAR_16:
                                                        sum += ((SND_HWORD *)mainIndex)[currentSample * nChansIn + n];
                                                                break;
                                                }
                                        } /* summing several channels into 1 channel */
                                        switch(df) {
                                                case SND_FORMAT_FLOAT:
                                                *(myOutPtrs[m]++) = (SND_HWORD)(sumFloat / chansToSum);
                                                        break;
                                                case SND_FORMAT_DOUBLE:
                                                *(myOutPtrs[m]++) = (SND_HWORD)(sumDouble / chansToSum);
                                                        break;
                                                default:
                                                case SND_FORMAT_LINEAR_16:
                                                case SND_FORMAT_LINEAR_8:
                                                case SND_FORMAT_MULAW_8:
                                                case SND_FORMAT_LINEAR_32:
                                                *(myOutPtrs[m]++) = (SND_HWORD)(sum / chansToSum);
                                        }
                                } /* passes through chnl indep sample */

                        } /*averaging of channels */
                        currentSample++;
                        (*inPtr) += nChansIn;
                        if (currentSample >= lastSampleInBlock) {
                                mainIndex = SndGetDataAddresses(*inPtr/nChansIn,
                                        inSnd,
                                        (int *)&lastSampleInBlock, /* channel independent */
                                        (int *)&currentSample);
                                if (currentSample == -1 || lastSampleInBlock == -1) {
//					printf("met boundary: %d\n",*inPtr);
                                        break;
                                }
                        }
                }
        }
    if (Nsamps > 0) {
                val = myOutPtrs[0] - dataStart; /* (Calc return value) */
                while (--Nsamps > 0) {	/*   fill unread spaces with 0's */
                        for (channels = 0; channels < nChansOut; channels++) {
                                *(myOutPtrs[channels]++) = 0;
                        }
                }
    }

        for (channels = 0; channels < nChansOut; channels++) {
                SndSwapSoundToHost(newDataStarts[channels], newDataStarts[channels], origNsamps, 1, SND_FORMAT_LINEAR_16);
        }
    return(val);
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

    double dh;                  /* Step through filter impulse response */
    double dt;                  /* Step through input signal */
    SND_UWORD endTime;              /* When Time reaches EndTime, return to user */
    SND_UWORD dhb, dtb;             /* Fixed-point versions of Dh,Dt */

    dt = 1.0/factor;            /* Output sampling period */
    dtb = dt*(1<<Np) + 0.5;     /* Fixed-point representation */

    dh = MIN(Npc, factor*Npc);  /* Filter sampling period */
    dhb = dh*(1<<Na) + 0.5;     /* Fixed-point representation */

    Ystart = Y;
    endTime = *Time + (1<<Np)*(SND_WORD)Nx;
    while (*Time < endTime)
    {
        Xp = &X[*Time>>Np];	/* Ptr to current input sample */
    v = FilterUD(Imp, ImpD, Nwing, Interp, Xp, (SND_HWORD)(*Time&Pmask),
                     -1, dhb);	/* Perform left-wing inner product */
                 v += FilterUD(Imp, ImpD, Nwing, Interp, Xp+1, (SND_HWORD)((-*Time)&Pmask),
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
SND_HWORD *outPtr,		/* output data pointer */
    int inCount,		/* number of input samples to convert */
    int outCount,		/* number of output samples to compute */
    int nChans,			/* number of sound channels (1 or 2) */
    const SndSoundStruct *inSnd) /* to pick up formats and frags*/
{
    SND_UWORD Time, Times[16];		/* Current time/pos in input sample */
    SND_UHWORD Xp, Ncreep, Xoff, Xread;
    int OBUFFSIZE = (int)(((double)IBUFFSIZE)*factor+2.0);
    SND_HWORD *X1S[16],*Y1S[16];

    SND_UHWORD Nout=0, Nx;

        int inPtrRun = 0;//sb   /* Running pointer thru input */
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
                if (!last)		/* If haven't read last sample yet */
                {
                        last = readData(&inPtrRun, inCount, X1S, IBUFFSIZE,
                                        nChans, (int)Xread, inSnd);
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
    int nChans,			/* number of sound channels (1 or 2) */
    BOOL interpFilt,		/* TRUE means interpolate filter coeffs */
    SND_HWORD Imp[], SND_HWORD ImpD[],
    SND_UHWORD LpScl, SND_UHWORD Nmult, SND_UHWORD Nwing,
    const SndSoundStruct *inSnd)		/* to pick up formats and frags*/
{
    SND_UWORD Time, Times[16];		/* Current time/pos in input sample */
    SND_UHWORD Xp, Ncreep, Xoff, Xread;
    int OBUFFSIZE = (int)(((double)IBUFFSIZE)*factor+2.0);
    SND_HWORD *X1S[16],*Y1S[16];

    SND_UHWORD Nout=0, Nx;

        int inPtrRun = 0;//sb

    int i=0, Ycount, last;
        int channels;


    /* Account for increased filter gain when using factors less than 1 */
    if (factor < 1)
      LpScl = LpScl*factor + 0.5;
    /* Calc reach of LP filter wing & give some creeping room */
    Xoff = ((Nmult+1)/2.0) * MAX(1.0,1.0/factor) + 10;
    if (IBUFFSIZE < 2*Xoff)      /* Check input buffer size */
      return err_ret("IBUFFSIZE (or factor) is too small");
    Nx = IBUFFSIZE - 2*Xoff;     /* # of samples to process each iteration */

        for (channels = 0; channels < nChans; channels++){
        X1S[channels] = malloc(IBUFFSIZE * sizeof(SND_HWORD));
        Y1S[channels] = malloc(OBUFFSIZE * sizeof(SND_HWORD));
// printf("Channel %d array: X1S = %p, Y1S = %p\n",channels, X1S[channels], Y1S[channels]);
        }

    last = 0;			/* Have not read last input sample yet */
    Ycount = 0;			/* Current sample and length of output file */
    Xp = Xoff;			/* Current "now"-sample pointer for input */
    Xread = Xoff;		/* Position in input array to read into */
    Time = (Xoff<<Np);		/* Current-time pointer for converter */

        for (channels = 0; channels < nChans; channels++){
        for (i=0; i<Xoff; X1S[channels][i++]=0); /* Need Xoff zeros at begining of sample */
        }
    
    do {
                if (!last)		/* If haven't read last sample yet */
                {
                        last = readData(&inPtrRun, inCount, X1S, IBUFFSIZE,
                                        nChans, (int)Xread, inSnd);
                        if (last && (last-Xoff<Nx)) { /* If last sample has been read... */
                        Nx = last-Xoff;	/* ...calc last sample affected by filter */
                        if (Nx <= 0)
                                break;
                        }
                }
                /* Resample stuff in input buffer */
                if (factor >= 1) {	/* SrcUp() is faster if we can use it */
                        for (channels = 0; channels < nChans; channels++){
                                Times[channels] = Time;
                                Nout=SrcUp(X1S[channels],Y1S[channels],factor,
                                        &Times[channels],Nx,Nwing,LpScl,Imp,ImpD,interpFilt);
                        }
                }
                else {
                        for (channels = 0; channels < nChans; channels++) {
                                Times[channels] = Time;
                                Nout=SrcUD(X1S[channels],Y1S[channels],factor,
                                        &Times[channels],Nx,Nwing,LpScl,Imp,ImpD,interpFilt);
                        }
                }
                Time = Times[0];
                Time -= (Nx<<Np);	/* Move converter Nx samples back in time */
                Xp += Nx;		/* Advance by number of samples processed */
                Ncreep = (Time>>Np) - Xoff; /* Calc time accumulation in Time */
                if (Ncreep) {
                        Time -= (Ncreep<<Np);    /* Remove time accumulation */
                        Xp += Ncreep;            /* and add it to read pointer */
                }
                for (i=0; i<IBUFFSIZE-Xp+Xoff; i++) { /* Copy part of input signal */
                        for (channels = 0; channels < nChans; channels++) {
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

                if (Nout > OBUFFSIZE) {/* Check to see if output buff overflowed */
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
    for (channels = 0; channels < nChans; channels++) {
        free(X1S[channels]);
        free(Y1S[channels]);
        }
    return(Ycount);		/* Return # of samples in output file */
}


int resample(			/* number of output samples returned */
    double factor,		/* factor = Sndout/Sndin */
    SND_HWORD *outPtr,		/* output data pointer */
    int inCount,		/* number of input samples to convert */
    int outCount,		/* number of output samples to compute */
    int nChans,			/* number of sound channels (1 or 2) */
    BOOL interpFilt,		/* TRUE means interpolate filter coeffs */
    int fastMode,		/* 0 = highest quality, slowest speed */
    BOOL largeFilter,		/* TRUE means use 65-tap FIR filter */
    char *filterFile,		/* NULL for internal filter, else filename */
    const SndSoundStruct *inSnd)		/* for data format etc */
{
    SND_UHWORD LpScl;		/* Unity-gain scale factor */
    SND_UHWORD Nwing;		/* Filter table size */
    SND_UHWORD Nmult;		/* Filter length for up-conversions */
    SND_HWORD *Imp=0;		/* Filter coefficients */
    SND_HWORD *ImpD=0;		/* ImpD[n] = Imp[n+1]-Imp[n] */

    if (fastMode)
      return resampleFast(factor,outPtr,inCount,outCount,nChans, inSnd);

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
    return resampleWithFilter(factor,outPtr,inCount,outCount,nChans,
                              interpFilt, Imp, ImpD, LpScl, Nmult, Nwing, inSnd);
}
