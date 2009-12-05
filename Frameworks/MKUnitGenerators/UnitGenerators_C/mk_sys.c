/* 6/1/95  - jos, created */

#include "musickit_c.h"

#define BOOL int
#define CHANS (2)		/* channel count (frame size in samples) */
#define DMA_BUF_SIZE (1024)	/* Must be multiple of NTICK*CHANS */
				/* Buffer size is for two stereo soundout buffers */
				/* Each buffer is DMA_BUF_SIZE/2 "frames" long */
				/* Each buffer is DMA_BUF_SIZE/4 "samples" long */

#ifndef SRATE
#define SRATE (44100)		/* sampling rate in samples per second */
#endif

static int soundoutframes = 0;
static word *soundoutbuf = 0;
static short *shortsbuf = 0;
static word *sobp = 0;

#define SINE_ROM_SIZE (256)	/* in samples */
static word mk_sinerom[SINE_ROM_SIZE];
MKWavetable MKSineRom;

static void s_init_sinerom()
{
    int i;
    for (i=0; i<SINE_ROM_SIZE; i++)
	mk_sinerom[i] = mk_double_to_word(sin(2.0*M_PI*i/((double)SINE_ROM_SIZE)));
    MKSineRom.size = SINE_ROM_SIZE;
    MKSineRom.data = mk_sinerom;
}

int mk_writesoundout(char *filename, int srate)
{
    int err;
    if (sizeof(word) != sizeof(short))
	mk_word_to_short_array(shortsbuf,soundoutbuf, soundoutframes * CHANS);
    err = writeSound(filename, (short *)shortsbuf, soundoutframes, CHANS, srate );
    if (err)
	fprintf(stderr,"*** sys.c:mk_writesoundout: writeSound error %d\n",err);
    return err;
}

void mk_initsoundout(int frames)
{
    soundoutframes = frames;
    soundoutbuf = calloc(frames*CHANS, sizeof(word)); /* written by out2sum */
    sobp = soundoutbuf;  
    if (sizeof(word) != sizeof(short))
	shortsbuf = malloc(frames * sizeof(short) * CHANS); /* raw stereo output */
    else
	shortsbuf = (short *)soundoutbuf;
}

static void sendSoundoutBuffer(MKSysVars *s)
{
    int i;
    if (soundoutbuf == 0)
	mk_initsoundout(SRATE); /* generate one second */
    if (sobp-soundoutbuf + DMA_BUF_SIZE/2 >= soundoutframes*CHANS) {
	fprintf(stderr,"*** sys.c:sendSoundoutBuffer: Buffer dropped\n");
	return;
    }
    for (i=0; i<DMA_BUF_SIZE/2; i++) {
	*sobp++ = s->dma_wfb[i]; /* copy out stereo soundout buffer */
    }

#ifdef PRINT_OUTPUT
    for (i=0; i<DMA_BUF_SIZE/2; i++)
    /* "sound out" as ascii to the terminal */
      printf("%f ",FLOAT(s->dma_wfb[i]));
    printf("\n");
#endif
}

void mk_partials(int partialCount, double *freqRatios, double *ampRatios,
   double *phases, double orDefaultPhase, word *dspData, int dspDataLength)
/* Implements the Music Kit Partial object's method
   "setPartialCount:freqRatios:ampRatios:phases:orDefaultPhase:" */
{
    int n,k;
    int didmalloc = 0;
    double *ddata = malloc(dspDataLength*sizeof(double)); 
    double dmax,dscl;

    if (!phases) {
	phases = (double *)malloc(partialCount * sizeof(double));
	didmalloc = 1;
	for (k=0; k<partialCount; k++)
	    phases[k] = orDefaultPhase;
    }

    for (n=0; n<dspDataLength; n++)
	ddata[n] = 0;
    for (k=0; k<partialCount; k++) {
	double dangk = (2*M_PI) * freqRatios[k] / dspDataLength;
	double phasek = phases[k];
	for (n=0; n<dspDataLength; n++) {
	    double val = ampRatios[k]*sin(phasek + ((double)n)*dangk);
	    ddata[n] += mk_double_to_word(val);
	}
    }

    dmax = 0.0;
    for (n=0; n<dspDataLength; n++) {
	double d = fabs(ddata[n]);
	if (d > dmax) dmax = d;
    }

    dscl = ( (dmax > 0.0) ? 1.0/dmax : 1.0 );

    for (n=0; n<dspDataLength; n++)
	dspData[n] += mk_double_to_word(dscl*ddata[n]);

    if (didmalloc)
       free(phases);
}


/* Note: The following "system" functions are designed to parallel 
   very closely what happens in the DSP monitors used by the Music Kit.
   Even the names used are the same, so it can serve as a guide to
   understanding the monitor code in /usr/local/lib/dsp/smsrc/*.asm .
 */

void mk_init(MKSysVars *s)
{
    s->dma_wfp = s->dma_wfb = (word *)calloc(sizeof(word), DMA_BUF_SIZE);
    s->dma_web = s->dma_wfb + DMA_BUF_SIZE/2;
    s->tickSize = NTICK;
    s->sampleTime = 0;
    s_init_sinerom();
}

static void handleTMQ(MKSysVars *s)
{
    /* Timed-message processing goes here.
     * Execute all messages in the Timed Message Queue having time stamp
     * less than or equal to s->sampleTime.
     */
}

void mk_sys(MKSysVars *s)
{
    BOOL fillingLowerHalf;
    BOOL swap;
    word *dma_wfn;
    int i;
    int frameSamples = s->tickSize * CHANS;
    s->sampleTime += s->tickSize; /* Update current time in samples */
    handleTMQ(s);		/* Process timed message queue */
    s->dma_wfp += frameSamples; /* Advance stereo soundout dma buffer pointer */
    fillingLowerHalf = (s->dma_web > s->dma_wfb);
    swap = ((fillingLowerHalf) ? (s->dma_wfp == s->dma_web) : 
	    (s->dma_wfp == s->dma_wfb + DMA_BUF_SIZE/2));
    if (swap) {
	synthdata tmp; 
	sendSoundoutBuffer(s);	/* Ideally via DMA in separate thread */
	tmp = s->dma_web;
	s->dma_web = s->dma_wfb; /* Swap */
	s->dma_wfb = tmp;
	s->dma_wfp = s->dma_wfb;
    }
    for (dma_wfn = s->dma_wfp, i=0; i<frameSamples; i++)
	*dma_wfn++ = 0;		/* Clear new section of soundout DMA buffer */
}



