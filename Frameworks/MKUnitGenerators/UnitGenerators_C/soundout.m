/* MACHINE-DEPENDENT utility for writing sound from memory to NeXT sound file */
/* 6/01/95, jos, created */
/* 1/26/96, gps,  added byte swapping for the i386 machines */ 
/* 4/11/96, gps,  made different routines for different architechtures */ 
/* 8/01/96, jos,  fixed bugs in writeSound for channels > 1 case */ 

#include "musickit_c.h"


/* --------------- NeXT i386 soundout routine ------------*/ 
#ifdef i386
#include <SndKit/SndKit.h>

int writeSound(char *name, short *soundData, 
	       int frameCount, int channels, int srate) 
{
    int i, err;
    short *data;
    SndSoundStruct *sound;
    SndAlloc(&sound, frameCount * sizeof(short), SND_FORMAT_LINEAR_16, srate, channels, 4);
    data = (short *) ((char *)sound + sound->dataLocation);
    for (i = 0; i < frameCount; i++) { 
        /* 
          If its an x86 machine, you need to swap (swab) 
          the bytes  -gps 1/26/96
        */ 
        swab(&soundData[i], &data[i], 2); 
    } 
    err = SNDWriteSoundfile(name,sound);
    if(err)
    	fprintf(stderr,"*** Could not write sound file %s\n",name);
    else
    	printf("File %s written.\n",name);
    return err;
}

#endif 

/* --------------- NeXT m68k soundout routine -------------*/ 

#ifdef m68k
#include <sound/sound.h>

int writeSound(char *name, short *soundData, 
	       int frameCount, int channels, int srate) 
{
    int i, err;
    short *data;
    SNDSoundStruct *sound;
    SNDAlloc(&sound, frameCount*sizeof(short)*channels, SND_FORMAT_LINEAR_16, 
	     srate, channels, 4);
    data = (short *) ((char *)sound + sound->dataLocation);
    for (i = 0; i < frameCount*channels; i++) { 
    	data[i] = soundData[i];	
    } 
    err = SNDWriteSoundfile(name,sound);
    if(err)
    	fprintf(stderr,"*** Could not write sound file %s\n",name);
    else
    	printf("File %s written.\n",name);
    return err;
}


#endif

/* ------------------ SGI soundout routine --------------*/ 
#ifdef _SGI_SOURCE
#include <dmedia/audio.h>
#include <dmedia/audiofile.h>

int writeSound(char *name, short *soundData, 
	       int frameCount, int channels, int srate) 
{
    int i, err;
    short *data;

    AFfilesetup   filesetup;                      /* audio file setup                  */
    AFfilehandle  file;                           /* audio file handle                 */
    long          filesampwidth = 16;             /* audio file sample width           */

    filesetup    = AFnewfilesetup();
    AFinitfilefmt(filesetup, AF_FILE_AIFFC);                       /* its an aiff file         */ 

    AFinitchannels(filesetup, AF_DEFAULT_TRACK,  (long) channels); /* it has 2 channels        */ 
    AFinitrate(filesetup, AF_DEFAULT_TRACK, (double) srate);       /* its at 44100 sample rate */  
    AFinitsampfmt(filesetup, AF_DEFAULT_TRACK, 
                      AF_SAMPFMT_TWOSCOMP, filesampwidth);         /* its a 16 bit linear file */

   file = AFopenfile(name, "w", filesetup);

    if ((AFwriteframes(file, AF_DEFAULT_TRACK,  soundData, frameCount)) < frameCount)
        {
    		fprintf(stderr,"*** Could not write sound file %s\n",name);
        	err = 1; 
        }
    else
	{
	    	printf("File %s written.\n",name);
		err = 0; 
	}	

    AFclosefile(file);   /* this is important: it updates the file header */
    return err;
}


#endif







