/* Copyright 1993-1996 by J.O. Smith (jos@ccrma.stanford.edu).  All rights reserved. */


/* 4/6/96  - gps, integrated all include files in musickit_c.h */ 
/* 4/11/96 - gps, added SGI dependencies                       */ 

typedef struct _MKSysVars {
    synthdata dma_wfb;		/* write-fill buffer */
    synthdata dma_wfp;		/* write-buffer fill-pointer */
    synthdata dma_web;		/* write-emptying buffer (sent to DMA out) */
    int sampleTime;		/* current time in samples */
    int tickSize;		/* MK vector size */
} MKSysVars;

void mk_init(MKSysVars *s);
void mk_sys(MKSysVars *s);
void mk_initsoundout(int nframes);
int  mk_writesoundout(char *filename, int srate);

void mk_partials(int partialCount, double *freqRatios, double *ampRatios,
   double *phases, double orDefaultPhase, word *dspData, int dspDataLength);

extern MKWavetable MKSineRom;


