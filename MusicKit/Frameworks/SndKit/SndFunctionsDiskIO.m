/*
 *  SndFunctionsDiskIO.m
 *  SndKit
 *
 *  Created by SKoT McDonald on Thu Jan 10 2002.
 *  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
 *
 */

#import "_Sndlibst.h"
#import "SndFunctions.h"

#ifndef GNUSTEP
# ifndef WIN32
#  import <libc.h>
# else
#  import <stdio.h>
#  import <fcntl.h>
#  import <Winsock.h>
#  import <malloc.h>
#  import <io.h>
# endif
#else
# import <fcntl.h>
#endif

#import <math.h>
#import <Foundation/Foundation.h>

#import "SndFunctions.h"
#import "_Sndlibst.h"
#import "SndResample.h"

#ifdef USE_MACH_MEMORY_ALLOCATION
#import <mach/mach_interface.h>
#import <mach/mach_init.h>
#endif

/* the following ensures Sox doesn't attempt to define its own
* prototype
*/
#define HAVE_RAND 1
/* the following defines are to fool st.h into importing the right
* headers.
*/
#define HAVE_UNISTD_H 1
#define HAVE_STDINT_H 1
#define HAVE_SYS_TYPES 1
#import <st.h> /* prototypes and structures from the Sox sound tools library */
#ifndef RIGHT  /* used to be in old version of libst.h */
# define RIGHT(datum, bits)      ((datum) >> bits)
#endif

/* up to 12.17.2, libst.a used LONG. Then it uses st_sample_t */
#if (ST_LIB_VERSION_CODE <= 0x0c1102)
# define st_sample_t LONG
#endif

#define SUN_ULAW        1                       /* u-law encoding */
#define SUN_LIN_8       2                       /* Linear 8 bits */
#define SUN_LIN_16      3                       /* Linear 16 bits */
#define SUN_LIN_24      4                       /* Linear 24 bits */
#define SUN_LIN_32      5                       /* Linear 32 bits */
#define SUN_ALAW        27                      /* a-law encoding */

#define SNDREADCHUNKSIZE 256*1024   // Number of st_sample_t samples to read into a buffer.
#ifdef WIN32
#define LASTCHAR        '\\'
#else
#define LASTCHAR        '/'
#endif


int sk_ausunencoding(int size, int encoding) /* used to be in libst.a, but made private */
{
  int sun_encoding;

  if (encoding == ST_ENCODING_UNSIGNED && size == ST_SIZE_BYTE)
    sun_encoding = SUN_LIN_8;
  else if (encoding == ST_ENCODING_ULAW && size == ST_SIZE_BYTE)
    sun_encoding = SUN_ULAW;
  else if (encoding == ST_ENCODING_ALAW && size == ST_SIZE_BYTE)
    sun_encoding = SUN_ALAW;
  else if (encoding == ST_ENCODING_SIGN2 && size == ST_SIZE_BYTE)
    sun_encoding = SUN_LIN_8;
  else if (encoding == ST_ENCODING_SIGN2 && size == ST_SIZE_WORD)
    sun_encoding = SUN_LIN_16;
  else
    sun_encoding = -1;
  return sun_encoding;
}

////////////////////////////////////////////////////////////////////////////////
// SndReadHeader
////////////////////////////////////////////////////////////////////////////////

int SndReadHeader(const char* path, SndSoundStruct **sound, const char *fileTypeStr)
{
  return SndReadSoundfileRange(path, sound, 0, 0, FALSE);
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

int SndReadRange(FILE *fp, SndSoundStruct **sound, const char *fileTypeStr, int startFrame, int frameCount, BOOL bReadData)
{
  SndSoundStruct *s;
  int lenRead, oldFrameCount;
  int samplesRead;
  int headerLen;
  struct st_soundstream informat;
  st_sample_t *readBuffer;
  char *storePtr;
  int i, samplesToReadCount;
  BOOL bUnsigned = FALSE;

  *sound = NULL;
  if (fp == NULL)
    return SND_ERR_CANNOT_OPEN;
  informat.fp = fp;
  informat.seekable = YES;
  /* use a default file type in the absence of an explicit type -- the user shouldn't
    be forced to use file extensions -- snd is native to SndKit */
  informat.filetype = (*fileTypeStr != '\0') ? (char *) fileTypeStr : "snd";
  informat.info.rate = 0;
  informat.info.size = -1;
  informat.info.encoding = -1;
  informat.info.channels = -1;
  informat.comment = NULL;
  informat.swap = 0;
  informat.filename = "input";

  st_gettype(&informat);

  /* Read and write starters can change their formats. */
  (* informat.h->startread)(&informat);
  st_checkformat(&informat);

  headerLen = sizeof(SndSoundStruct);
  if (informat.comment) {
    headerLen += strlen(informat.comment) - 4 + 1; // -4 for the 4 bytes defined with SndSoundStruct, +1 for \0
                                                   // if(headerLen < sizeof(SndSoundStruct))
                                                   // headerLen = sizeof(SndSoundStruct)
  }
  if (!(s = malloc(headerLen))) return SND_ERR_CANNOT_ALLOC;
  /* endianess is handled within startread() */
  s->magic        = SND_MAGIC; // could be extended using fileTypeStr but only when we write in all formats.
  s->dataLocation = 0;
  s->dataFormat   = sk_ausunencoding(informat.info.size, informat.info.encoding);
  bUnsigned = informat.info.encoding == ST_ENCODING_UNSIGNED;
  s->samplingRate = informat.info.rate;
  s->channelCount = informat.info.channels;
  s->dataSize     = informat.info.size * informat.length; // whole sound for the moment
  if (informat.comment) // because SndSoundStruct locates comments at a fixed location, we have to copy them in.
    strcpy(s->info, informat.comment);
  else
    s->info[0] = '\0';

  // Sox read() always returns arrays of st_sample_t integers for each sample which the SndKit should eventually adopt
  // to enable 24 bit operation.
  // For now, we kludge it to 16 bit integers until we have sound drivers that will manage the extra precision.

  // Unfortunately there is the assumption the SndSoundStruct is always big-endian (within the MKPerformSndMIDI
  // framework and any soundStructs returned), which means we need to swap again. The correct solution is to relax
  // the big-endian requirement, introduce another format code allowing for little endian encoding, and revert the
  // MKPerformSndMIDI framework to expect native endian order.

  // SKoT: slight update here - let's use the informat.length estimate as the canonical length of the sound!
  //       saves much reallocing.

  if (bReadData) {
    s->dataLocation = headerLen;
    if((readBuffer = (st_sample_t *) malloc(SNDREADCHUNKSIZE * sizeof(st_sample_t))) == NULL)
      return SND_ERR_CANNOT_ALLOC;

    //        printf("Samples: %li samplesize:%i\n",informat.length,informat.info.size);

    samplesRead = 0; // samplesRead represents ? excluding header.
    if (startFrame > informat.length) {
      printf("SndRead: startFrame > length (%i vs %i)\n", startFrame, informat.length);
      return SND_ERR_CANNOT_READ;
    }
    if (frameCount < 0) {
      frameCount = informat.length - startFrame;
    }
    oldFrameCount = frameCount;
    if (startFrame + frameCount > informat.length) {
//      printf("SndRead: startFrame + frameCount > length (%i + %i vs %i) - truncating\n", startFrame, frameCount, informat.length);
      frameCount = informat.length - startFrame;
    }

    samplesToReadCount = frameCount * informat.info.channels; 
    s = realloc((char *)s, headerLen + samplesToReadCount * informat.info.size);
    memset(((char*)s) + headerLen, 0, samplesToReadCount * informat.info.size);
//    printf("Allocating: %li\n", samplesToReadCount * informat.info.size);
    (*informat.h->seek)(&informat, startFrame * informat.info.size);
    do {
      int c;
      storePtr = (char *)s + headerLen + samplesRead * informat.info.size;
      /* Read chunk of input data. */
      lenRead = (*informat.h->read)(&informat, readBuffer, (st_sample_t) SNDREADCHUNKSIZE);
      if (lenRead <= 0)
        return SND_ERR_CANNOT_READ;
      c = lenRead;
      if (samplesRead + lenRead > samplesToReadCount)
        c = samplesToReadCount - samplesRead;


      switch (s->dataFormat) {
        case SUN_LIN_8:
          for(i = 0; i < c; i++) {
            int sample = RIGHT(readBuffer[i], (sizeof(st_sample_t) - informat.info.size) * 8);
            *((char *) storePtr) =  htons(sample); // kludged assuming 16 bits. We always adopt big-endian format.
            storePtr += informat.info.size;
          }
          break;
        case SUN_LIN_16:
          for(i = 0; i < c; i++) {
            int sample = RIGHT(readBuffer[i], (sizeof(st_sample_t) - informat.info.size) * 8);
            *((short *) storePtr) =  htons(sample); // kludged assuming 16 bits. We always adopt big-endian format.
            storePtr += informat.info.size;
          }
          break;
        default:
          NSLog(@"SndFunctionsDiskIO: Argh! Can't convert this stuff I'm reading!");
      }
      
      samplesRead += lenRead;
      if (samplesRead >= samplesToReadCount)
        break;
    } while(lenRead == SNDREADCHUNKSIZE); // sound files exactly modulo SNDREADCHUNKSIZE will read 0 bytes next time thru.

    // s->dataSize = samplesRead * informat.info.size;
    //        s = realloc((char *)s, headerLen + s->dataSize);
    free(readBuffer);

    if([[NSUserDefaults standardUserDefaults] boolForKey: @"SndShowInputFileFormat"]) {
      printf("Input file: using sample rate %lu Hz, size %s, style %s, %d %s\n",
             (unsigned long)(informat.info.rate), st_sizes_str[(int)(informat.info.size)],
             st_encodings_str[(int)(informat.info.encoding)], informat.info.channels,
             (informat.info.channels > 1) ? "channels" : "channel");
      if (informat.comment)
        printf("Input file: comment \"%s\"\n", informat.comment);
      SndPrintStruct(s);
    }
  } // end if bReadData

  *sound = s;
  (* informat.h->stopread)(&informat);
  return SND_ERR_NONE;
}

/* called from util.c:fail */
void cleanup()
{
  /* Close the input file and outputfile before exiting*/
  //        if (informat.fp)
  //                fclose(informat.fp);
}

int SndReadSoundfileRange(const char *path, SndSoundStruct **sound, int startFrame, int frameCount, BOOL bReadData)
{
  int error,error2;
  FILE *fp;
  SndSoundStruct *aSound;
  const char *filetype;

  *sound = NULL;
  if (!path) return SND_ERR_BAD_FILENAME;
  if (!strlen(path)) return SND_ERR_BAD_FILENAME;
  fp = fopen(path, "rb");
  if (fp == NULL) return SND_ERR_CANNOT_OPEN;

  if ((filetype = strrchr(path, LASTCHAR)) != NULL)
    filetype++;
  else
    filetype = path;
  if ((filetype = strrchr(filetype, '.')) != NULL)
    filetype++;
  else /* Default to "auto" */
    filetype = "auto";

  error = SndReadRange(fp, &aSound, filetype, startFrame, frameCount, bReadData);
  error2 = fclose(fp);
  if (error2 == EOF) return SND_ERR_UNKNOWN;
  *sound = aSound;
  return error;
}

int SndReadSoundfile(const char *path, SndSoundStruct **sound)
{
  return SndReadSoundfileRange(path, sound, 0, -1, TRUE);
}

int SndWriteSoundfile(const char *path, SndSoundStruct *sound)
{
  int error,error2;
  int fd;
  if (!path) return SND_ERR_BAD_FILENAME;
  if (!strlen(path)) return SND_ERR_BAD_FILENAME;
#ifdef WIN32
  fd = open(path, O_BINARY | O_WRONLY | O_CREAT | O_TRUNC, 0644);
#else
  fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
#endif
  if (fd == -1) return SND_ERR_CANNOT_OPEN;
  error = SndWrite(fd, sound);
  error2 = close(fd);
  if (error2 == -1) return SND_ERR_UNKNOWN;
  return error;
}

int SndWriteHeader(int fd, SndSoundStruct *sound)
{
  SndSoundStruct *s;
  SndSoundStruct **ssList;
  SndSoundStruct *theStruct;
  int headerSize;
  int df;
  int i;

  if (fd == 0) return SND_ERR_CANNOT_OPEN;
  df = sound->dataFormat;
  if (df == SND_FORMAT_INDIRECT) headerSize = sound->dataSize;
  else headerSize = sound->dataLocation;
  /* make new header with swapped bytes if nec */
  if (!(s = malloc(headerSize))) return SND_ERR_CANNOT_ALLOC;
  memmove(s,sound,headerSize);
  if (df == SND_FORMAT_INDIRECT) {
    int newCount = 0;
    i = 0;
    s->dataFormat = ((SndSoundStruct *)(*((SndSoundStruct **)
                                          (sound->dataLocation))))->dataFormat;
    ssList = (SndSoundStruct **)sound->dataLocation;
    while ((theStruct = ssList[i++]) != NULL)
      newCount += theStruct->dataSize;
    s->dataLocation = s->dataSize;
    s->dataSize = newCount;
  }

#ifdef __LITTLE_ENDIAN__
  s->magic = NSSwapBigLongToHost(s->magic);
  s->dataLocation = NSSwapBigLongToHost(s->dataLocation);
  s->dataSize = NSSwapBigLongToHost(s->dataSize);
  s->dataFormat = NSSwapBigLongToHost(s->dataFormat);
  s->samplingRate = NSSwapBigLongToHost(s->samplingRate);
  s->channelCount = NSSwapBigLongToHost(s->channelCount);
#endif
  if (write(fd, s, headerSize) != headerSize) { free(s); return SND_ERR_CANNOT_WRITE; }
  free(s);
  return SND_ERR_NONE;
}

int SndWrite(int fd, SndSoundStruct *sound)
{
  SndSoundStruct *s;
  SndSoundStruct **ssList;
  SndSoundStruct *theStruct;
  int error;
  int headerSize;
  int df;
  int i,j=0;

  if (fd == 0) return SND_ERR_CANNOT_OPEN;
  df = sound->dataFormat;
  if (df == SND_FORMAT_INDIRECT) headerSize = sound->dataSize;
  else headerSize = sound->dataLocation;
  /* make new header with swapped bytes if nec */
  if (!(s = malloc(headerSize))) return SND_ERR_CANNOT_ALLOC;
  memmove(s,sound,headerSize);
  if (df == SND_FORMAT_INDIRECT) {
    int newCount = 0;
    i = 0;
    s->dataFormat = ((SndSoundStruct *)(*((SndSoundStruct **)
                                          (sound->dataLocation))))->dataFormat;
    ssList = (SndSoundStruct **)sound->dataLocation;
    while ((theStruct = ssList[i++]) != NULL)
      newCount += theStruct->dataSize;
    s->dataLocation = s->dataSize;
    s->dataSize = newCount;
  }

#ifdef __LITTLE_ENDIAN__
  s->magic        = NSSwapBigLongToHost(s->magic);
  s->dataLocation = NSSwapBigLongToHost(s->dataLocation);
  s->dataSize     = NSSwapBigLongToHost(s->dataSize);
  s->dataFormat   = NSSwapBigLongToHost(s->dataFormat);
  s->samplingRate = NSSwapBigLongToHost(s->samplingRate);
  s->channelCount = NSSwapBigLongToHost(s->channelCount);
#endif
  if (write(fd, s, headerSize) != headerSize) { free(s); return SND_ERR_CANNOT_WRITE;};

  if (df != SND_FORMAT_INDIRECT) { /* simple read/write of block of data */
    error = write(fd,(char *)sound + sound->dataLocation,sound->dataSize);
    if (error <= 0) {
      free(s);
      return SND_ERR_CANNOT_WRITE;
    }
    if (error != sound->dataSize) {
      printf("File write seems to have been truncated!"
             " Wrote %d data bytes, tried %d\n",error, sound->dataSize);
    }
    free(s);
    return SND_ERR_NONE;
  }
/* more difficult -- fragged data */

ssList = (SndSoundStruct **)sound->dataLocation;
free(s);
while ((theStruct = ssList[j++]) != NULL) {
		error = write(fd,(char *)theStruct + theStruct->dataLocation, theStruct->dataSize);
		if (error <= 0) {
      return SND_ERR_CANNOT_WRITE;
    }
    if (error != theStruct->dataSize) {
      printf("File write seems to have been truncated! Wrote %d data bytes, tried %d\n",
             error, theStruct->dataSize);
    }
}
return SND_ERR_NONE;
}

