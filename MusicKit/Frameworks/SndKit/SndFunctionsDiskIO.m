/*
 *  SndFunctionsDiskIO.m
 *  SndKit
 *
 *  Created by SKoT McDonald on Thu Jan 10 2002.
 *  Copyright (c) 2002 tomandandy Inc. All rights reserved.
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

/* up to 12.17.2, libst.a used LONG. Then it uses st_sample_t */
#if (ST_LIB_VERSION_CODE <= 0x0c1102)
# define st_sample_t LONG
#endif

#define SUN_ULAW        1                       /* u-law encoding */
#define SUN_LIN_8       2                       /* Linear 8 bits */
#define SUN_LIN_16      3                       /* Linear 16 bits */
#define SUN_LIN_24      4                       /* Linear 24 bits */
#define SUN_LIN_32      5                       /* Linear 32 bits */
#define SUN_FLOAT	6			/* IEEE FP 32 bits */
#define SUN_ALAW        27                      /* a-law encoding */

#define SNDREADCHUNKSIZE 256*1024   // Number of st_sample_t samples to read into a buffer.
#ifdef WIN32
#define LASTCHAR        '\\'
#else
#define LASTCHAR        '/'
#endif

#define DEBUG_MESSAGES 0

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
  else if (encoding == ST_ENCODING_SIGN2 && size == ST_SIZE_DWORD)
    sun_encoding = SUN_LIN_32;
  else
    sun_encoding = -1;
  return sun_encoding;
}

int SndFormatToSoxFormat(int sndFormatCode, int *size)
{
  int r = ST_ENCODING_SIGN2;
  switch (sndFormatCode) {
    case SND_FORMAT_LINEAR_8:  *size = 1; break;
    case SND_FORMAT_LINEAR_16: *size = 2; break;
    case SND_FORMAT_LINEAR_32: *size = 4; break;
    case SND_FORMAT_FLOAT:     *size = 4; r = ST_ENCODING_FLOAT; break;
    default:
      NSLog(@"Argh, this sndtosox format conversion not written yet...");
  }
  return r;
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

  
  st_initformat(&informat);
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
  bUnsigned       = informat.info.encoding == ST_ENCODING_UNSIGNED;
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

  // SKoT: slight update here - let's use the informat.length estimate as the canonical length of the sound!
  //       saves much reallocing.

  if (bReadData) {
    long readChunkSize = SNDREADCHUNKSIZE * sizeof(st_sample_t);
    s->dataLocation = headerLen;
    if ((readBuffer = (st_sample_t *) malloc(readChunkSize)) == NULL)
      return SND_ERR_CANNOT_ALLOC;
//    memset(readBuffer, 0, readChunkSize);
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
#if DEBUG_MESSAGES      
      printf("SndRead: startFrame + frameCount > length (%i + %i vs %i) - truncating\n",
             startFrame, frameCount, informat.length);
#endif      
      frameCount = informat.length - startFrame;
    }

    samplesToReadCount = frameCount * informat.info.channels; 
    s = realloc((char *)s, headerLen + samplesToReadCount * informat.info.size);
//    memset(((char*)s) + headerLen, 0, samplesToReadCount * informat.info.size);
//    printf("Allocating: %li\n", samplesToReadCount * informat.info.size);
    (*informat.h->seek)(&informat, startFrame * informat.info.channels);
    do {
      int c, samsToRead = SNDREADCHUNKSIZE;
      storePtr = (char *)s + headerLen + samplesRead * informat.info.channels;
      /* Read chunk of input data. */
      if (samsToRead > frameCount * informat.info.channels)
        samsToRead = frameCount * informat.info.channels;
      lenRead = (*informat.h->read)(&informat, readBuffer, (st_sample_t) samsToRead);
      if (lenRead <= 0)
        return SND_ERR_CANNOT_READ;
      c = lenRead;
      if (samplesRead + lenRead > samplesToReadCount)
        c = samplesToReadCount - samplesRead;

      switch (s->dataFormat) {
        case SUN_LIN_8:
          for(i = 0; i < c; i++) {
            int sample = ST_SAMPLE_TO_SIGNED_BYTE(readBuffer[i]);
            *((char *) storePtr) =  sample; // kludged assuming 16 bits.
            storePtr += informat.info.size;
          }
          break;
        case SUN_LIN_16:
          for(i = 0; i < c; i++) {
            int sample = ST_SAMPLE_TO_SIGNED_WORD(readBuffer[i]);
            *((short *) storePtr) =  sample; // kludged assuming 16 bits.
            storePtr += informat.info.size;
          }
          break;
        case SUN_LIN_32:
          for(i = 0; i < c; i++) {
            long int sample = ST_SAMPLE_TO_SIGNED_DWORD(readBuffer[i]);
            *((long *) storePtr) =  sample; // kludged assuming 16 bits.
            storePtr += informat.info.size;
          }
          break;
        case SUN_FLOAT:
          for(i = 0; i < c; i++) {
            float sample = ST_SAMPLE_TO_FLOAT_DWORD(readBuffer[i]);
            *((float *) storePtr) =  sample; // kludged assuming 16 bits.
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

    s->dataSize = samplesRead * informat.info.size;
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

//
// Expects the sound to not be fragmented, and to be in host order.
// SOX will look after endian issues.
//
// used to be named SndWriteWithSOX

int SndWriteSoundfile(NSString* filename, SndSoundStruct *sound)
{
  int sz;
  struct st_soundstream ft;
  int i;
    
  st_initformat(&ft);
  ft.info.rate     = sound->samplingRate;
  ft.info.encoding = SndFormatToSoxFormat(sound->dataFormat, &sz);
  ft.info.size     = sz;
  ft.info.channels = sound->channelCount;
  ft.filename      = (char *)[filename fileSystemRepresentation];
  ft.filetype      = (char *)[[filename pathExtension] cString] ;
  ft.comment       = sound->info;
  ft.swap          = 0;
  ft.instr.MIDInote= 0;
  ft.instr.MIDIlow = 0;
  ft.instr.MIDIhi  = 0;
  ft.instr.loopmode= 0;
  ft.instr.nloops  = 0;
  for (i = 0 ; i < ST_MAX_NLOOPS ; i++) {
    ft.loops[i].start = ft.loops[i].length = 0;
    ft.loops[i].count = ft.loops[i].type = 0;
  }
  ft.seekable = 1; // so the original header length can be rewritten in aiff etc.
  // don't need ft.length
  // don't need ft.st_errno or st_errstr
  
  if (st_gettype(&ft)) {
    NSLog(@"SOX reports save format error: %s\n",ft.st_errstr);
    return SND_ERR_UNKNOWN;
  }

  if (st_checkformat(&ft)) {
    NSLog(@"SOX reports bad output format: %s\n",ft.st_errstr);
    return SND_ERR_UNKNOWN;
  }

  ft.fp            = fopen(ft.filename,"wb");
  if ((*ft.h->startwrite)(&ft) == ST_EOF)
  {
    NSLog(@"SOX reports header write error: %s\n",ft.st_errstr);
    return SND_ERR_UNKNOWN;
  }

  if([[NSUserDefaults standardUserDefaults] boolForKey: @"SndShowOutputFileFormat"]) {
    fprintf(stderr,"Output file %s: using sample rate %lu\n\tsize %s, encoding %s, %d %s",
             ft.filename, (long unsigned int)ft.info.rate,
             st_sizes_str[(unsigned char)ft.info.size],
             st_encodings_str[(unsigned char)ft.info.encoding],
             ft.info.channels,
             (ft.info.channels > 1) ? "channels" : "channel");

    if (ft.comment) {
      fprintf(stderr,"Output file: comment \"%s\"\n", ft.comment);
    }
  }
  
  {
  int i;
  long readChunkSize = SNDREADCHUNKSIZE * sizeof(st_sample_t);
  long sampleCount = SndSampleCount(sound) * sound->channelCount;
  void *data = (char *)sound + sound->dataLocation;
  st_sample_t *writeBuffer = malloc(readChunkSize);
  
  if (!writeBuffer) {
    fprintf(stderr,"Malloc failed in writeSOXsound\n");
    return SND_ERR_UNKNOWN;
  }
  while (sampleCount > 0) {
    int c = MIN(sampleCount, SNDREADCHUNKSIZE);
    sampleCount -= c;
    
    switch (sound->dataFormat) {
      case SUN_LIN_8:
        for(i = 0; i < c; i++) {
          char sample = ((char *)data)[i];
          writeBuffer[i] = ST_SIGNED_BYTE_TO_SAMPLE(sample) ; // no swap
        }
        (char *)data += c;
        break;
      case SUN_LIN_16:
        for(i = 0; i < c; i++) {
          short sample = ((short *)data)[i];
          writeBuffer[i] = ST_SIGNED_WORD_TO_SAMPLE(sample) ; // no swap
        }
        (short *)data += c;
        break;
      case SUN_LIN_32:
        for(i = 0; i < c; i++) {
          long int sample = ((long int *)data)[i];
          writeBuffer[i] = ST_SIGNED_DWORD_TO_SAMPLE(sample) ; // no swap
        }
        (long int *)data += c;
        break;
      case SUN_FLOAT:
        for(i = 0; i < c; i++) {
          float sample = ((float *)data)[i];
          writeBuffer[i] = ST_FLOAT_DWORD_TO_SAMPLE(sample) ; // no swap
        }
        (float *)data += c;
        break;
      default:
        NSLog(@"SndFunctionsDiskIO: Argh! Can't convert this stuff I'm writing!");
    }
    (* ft.h->write)(&ft, writeBuffer, (st_ssize_t) c);
  }
  free(writeBuffer);
  if ((* ft.h->stopwrite)(&ft) != ST_SUCCESS) {
    NSLog(@"writing error:%s\n",ft.st_errstr);
    return SND_ERR_UNKNOWN;
  }
  fclose(ft.fp);

  }

  return SND_ERR_NONE;
}

// This is the original Sun/NeXT sound savig routine.
int SndWriteSoundfileClassic(const char *path, SndSoundStruct *sound)
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
  SndSoundStruct **ssList;
  SndSoundStruct *theStruct;
  int error;
  int j=0;

  error = SndWriteHeader(fd, sound);
  if (error) {
    return error;
  }
  if (sound->dataFormat != SND_FORMAT_INDIRECT) { /* simple read/write of block of data */
    error = write(fd, (char *)sound + sound->dataLocation, sound->dataSize);
    if (error <= 0) {
      return SND_ERR_CANNOT_WRITE;
    }
    if (error != sound->dataSize) {
      fprintf(stderr, "File write seems to have been truncated! Wrote %d data bytes, tried %d\n",
               error, sound->dataSize);
    }
    return SND_ERR_NONE;
  }
/* more difficult -- fragged data */

  ssList = (SndSoundStruct **)sound->dataLocation;
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

