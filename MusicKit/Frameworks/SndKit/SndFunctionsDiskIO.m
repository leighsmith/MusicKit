////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    Routines to read and write sound files.
//    Historically these have been functions rather than methods. Nowdays, we
//    Keep them as functions only to isolate our sound file reading library
//    libsndfile or libst (sox) from the rest of the code base, especially regarding
//    including headers etc.
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2002, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#define DEBUG_MESSAGES 0

#define LIBSNDFILE_AVAILABLE

#import "SndFunctions.h"
#import "SndMuLaw.h"

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

#import <Foundation/Foundation.h>
#import "SndResample.h"

#ifdef LIBSNDFILE_AVAILABLE
#import <stdio.h>
#import <sndfile.h>
#endif

#ifdef USE_MACH_MEMORY_ALLOCATION
#import <mach/mach_interface.h>
#import <mach/mach_init.h>
#endif

#ifndef LIBSNDFILE_AVAILABLE

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

#define SNDREADCHUNKSIZE 256*1024   // Number of st_sample_t samples to read into a buffer.

/* converted from a similar routine in libst.a */
static int soxEncodingToSndDataFormat(int size, int encoding)
{
    int dataFormat;

    if (encoding == ST_ENCODING_UNSIGNED && size == ST_SIZE_BYTE)
	dataFormat = SND_FORMAT_LINEAR_8;
    else if (encoding == ST_ENCODING_ULAW && size == ST_SIZE_BYTE)
	dataFormat = SND_FORMAT_MULAW_8;
    else if (encoding == ST_ENCODING_ALAW && size == ST_SIZE_BYTE)
	dataFormat = SND_FORMAT_ALAW_8;
    else if (encoding == ST_ENCODING_SIGN2 && size == ST_SIZE_BYTE)
	dataFormat = SND_FORMAT_LINEAR_8;
    else if (encoding == ST_ENCODING_SIGN2 && size == ST_SIZE_WORD)
	dataFormat = SND_FORMAT_LINEAR_16;
    else if (encoding == ST_ENCODING_SIGN2 && size == ST_SIZE_24BIT)
	dataFormat = SND_FORMAT_LINEAR_24;
    else if (encoding == ST_ENCODING_SIGN2 && size == ST_SIZE_DWORD)
	dataFormat = SND_FORMAT_LINEAR_32;
    else
	dataFormat = -1;
    return dataFormat;
}

static int SndDataFormatToSoxEncoding(int sndFormatCode, int *size)
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

NSArray *SndFileExtensions(void)
{
    NSMutableArray *fileTypes = [NSMutableArray array];
    int formatIndex, aliasIndex;

    for (formatIndex = 0; st_formats[formatIndex].names != NULL; formatIndex++) {
	// include all the alternative namings.
	for(aliasIndex = 0; st_formats[formatIndex].names[aliasIndex] != NULL; aliasIndex++) {
	    [fileTypes addObject: [NSString stringWithCString: st_formats[formatIndex].names[aliasIndex]]];
	}
    }
    return [NSArray arrayWithArray: fileTypes]; // make it immutable
}

#else

static int SndDataFormatToSndFileEncoding(const char *extension, int sndFormatCode)
{
    int sndfileFormat;
    
    // Determine major format from file extension
    // TODO for now just fix it to AIFF
    sndfileFormat = SF_FORMAT_AIFF;
    switch (sndFormatCode) {
    case SND_FORMAT_MULAW_8:
	sndfileFormat |= SF_FORMAT_ULAW;
	break;
    case SND_FORMAT_LINEAR_8:
	sndfileFormat |= SF_FORMAT_PCM_S8;
	break;
    case SND_FORMAT_LINEAR_16:
	sndfileFormat |= SF_FORMAT_PCM_16;
	break;
    case SND_FORMAT_LINEAR_24:
	sndfileFormat |= SF_FORMAT_PCM_24;
	break;
    case SND_FORMAT_LINEAR_32:
	sndfileFormat |= SF_FORMAT_PCM_32;
	break;
    case SND_FORMAT_FLOAT:
	sndfileFormat |= SF_FORMAT_FLOAT;
	break;
    case SND_FORMAT_DOUBLE:
	sndfileFormat |= SF_FORMAT_DOUBLE;
	break;
    default:
	NSLog(@"SndDataFormatToSndFileEncoding unhandled format %d\n", sndFormatCode);
    }
    return sndfileFormat;
}

NSArray *SndFileExtensions(void)
{
    // libsndfile doesn't have a concept of aliases for common file extensions so
    // we have to add them manually. This is bad. libsndfile should provide an alias list.
    NSMutableArray *fileTypes = [NSMutableArray arrayWithObjects: @"aif", @"nist", @"aifc", nil];
    int formatIndex, formatCount;
    SF_FORMAT_INFO sfFormatInfo;

    // libsndfile's "major" formats are different standard sound file formats, the "subtype" formats are various
    // encodings within each format.
    sf_command (NULL, SFC_GET_FORMAT_MAJOR_COUNT, &formatCount, sizeof(int));

    for (formatIndex = 0; formatIndex < formatCount; formatIndex++) {
	// include all the alternative namings.
	sfFormatInfo.format = formatIndex;
	sf_command(NULL, SFC_GET_FORMAT_MAJOR, &sfFormatInfo, sizeof(sfFormatInfo));
	[fileTypes addObject: [NSString stringWithCString: sfFormatInfo.extension]];
    }
    return [NSArray arrayWithArray: fileTypes]; // make it immutable
}
#endif

////////////////////////////////////////////////////////////////////////////////
// SndReadHeader
////////////////////////////////////////////////////////////////////////////////

int SndReadHeader(NSString *path, SndSoundStruct **sound, const char *fileTypeStr)
{
  return SndReadSoundfileRange(path, sound, 0, 0, FALSE);
}

#ifndef LIBSNDFILE_AVAILABLE

// Retrieve loop points
// The AIFF loop structure is a lot richer than our simplistic single loop structure. So for now
// we just use the first AIFF loop.
// Returns YES if we could find a set of loop points, NO if not.
BOOL SndReadLoopPoints(struct st_soundstream *ft, long *loopStartIndex, long *loopEndIndex)
{
    if(ft->instr.nloops > 0) {
	int loopNum;
	
	for(loopNum = 0; loopNum < ft->instr.nloops; loopNum++) {
	    if (ft->loops[loopNum].count > 0) {
		switch(ft->loops[loopNum].type & ~ST_LOOP_SUSTAIN_DECAY) {
		    case 0:
			// Loop is off
			break;
		    case 1:
			// Loop forward only.
			break;
		    case 2:
			// Loop forward and backward
			break;
		}
	        *loopStartIndex = ft->loops[loopNum].start;
		*loopEndIndex   = ft->loops[loopNum].start + ft->loops[loopNum].length;
		return YES;
	    }
	}
    }
    return NO;
}
#endif

////////////////////////////////////////////////////////////////////////////////
// SndReadRange()
////////////////////////////////////////////////////////////////////////////////

#ifdef LIBSNDFILE_AVAILABLE
int SndReadRange(SNDFILE *sfp, SndSoundStruct **sound, SF_INFO *sfinfo, int startFrame, int frameCount, BOOL bReadData)
{
    SndSoundStruct *s;
    long numOfSamplesActuallyRead, oldFrameCount;
    int headerLen;
    int sampleWidth;
    char *comment = NULL;
    long totalNumOfSamplesToRead;
    SF_FORMAT_INFO soundFileFormatInfo;
    
    *sound = NULL;
    if (sfp == NULL)
	return SND_ERR_CANNOT_OPEN;

    if(!sfinfo->seekable && startFrame != 0)
       return SND_ERR_CANNOT_OPEN;
       
    /* Read text descriptions etc for comment. */
    soundFileFormatInfo.format = sfinfo->format;
    if(sf_command(sfp, SFC_GET_FORMAT_INFO, &soundFileFormatInfo, sizeof(soundFileFormatInfo)) != 0) {
	if(sf_error(sfp) != SF_ERR_NO_ERROR) {
	    NSLog(@"%s\n", sf_strerror(sfp));
	}
	return SND_ERR_CANNOT_READ;
    }

    // TODO Retrieve the sound file description into comment.
       
    headerLen = sizeof(SndSoundStruct);
    if (comment) {
	headerLen += strlen(comment) - 4 + 1; // -4 for the 4 bytes defined with SndSoundStruct, +1 for \0
    }
    if (!(s = malloc(headerLen)))
       return SND_ERR_CANNOT_ALLOC;
    /* endianess is handled within sf_read_float() */
    s->magic        = SND_MAGIC; // could be extended using fileTypeStr but only when we write in all formats.
    s->dataLocation = 0;
    s->dataFormat   = SND_FORMAT_FLOAT;  // We only retrieve floats, we let libsndfile do the format conversions itself.
    s->samplingRate = sfinfo->samplerate;
    s->channelCount = sfinfo->channels;
    sampleWidth     = SndSampleWidth(s->dataFormat);
    s->dataSize     = sampleWidth * sfinfo->frames * sfinfo->channels; // whole sound for the moment
    if (comment) // because SndSoundStruct locates comments at a fixed location, we have to copy them in.
	strcpy(s->info, comment);
    else
	s->info[0] = '\0';
    
    if (bReadData) {
	s->dataLocation = headerLen;
#if DEBUG_MESSAGES
	NSLog(@"Samples: %d data format: %x\n", sfinfo->frames, sfinfo->format);
#endif
	if (startFrame > sfinfo->frames) {
	    NSLog(@"SndReadRange: startFrame > length (%i vs %i)\n", startFrame, sfinfo->frames);
	    return SND_ERR_CANNOT_READ;
	}
	if (frameCount < 0) {
	    frameCount = sfinfo->frames - startFrame;
	}
	oldFrameCount = frameCount;
	if (startFrame + frameCount > sfinfo->frames) {
#if DEBUG_MESSAGES
	    NSLog(@"SndReadRange: startFrame + frameCount > length (%i + %i vs %i) - truncating\n", startFrame, frameCount, sfinfo->frames);
#endif
	    frameCount = sfinfo->frames - startFrame;
	}

	totalNumOfSamplesToRead = frameCount * sfinfo->channels;
	if((s = realloc((char *) s, headerLen + totalNumOfSamplesToRead * sampleWidth)) == NULL)
	    return SND_ERR_CANNOT_ALLOC;
	
        // NSLog(@"Allocating: %li\n", totalNumOfSamplesToRead * sampleWidth);
        if(sf_seek(sfp, startFrame, SEEK_SET) == -1)
	    if(sf_error(sfp) != SF_ERR_NO_ERROR) {
	        NSLog(@"%s\n", sf_strerror(sfp));
	        return SND_ERR_CANNOT_READ;
	     }
		    
	numOfSamplesActuallyRead = sf_read_float(sfp, (float *) ((char *) s + s->dataLocation), totalNumOfSamplesToRead);
	if (numOfSamplesActuallyRead < 0)
	    return SND_ERR_CANNOT_READ;

	s->dataSize = numOfSamplesActuallyRead * sampleWidth;

	if([[NSUserDefaults standardUserDefaults] boolForKey: @"SndShowInputFileFormat"]) {
	    NSLog(@"Input file: using sample rate %lu Hz, style %s, %d %s\n",
		(unsigned long)(sfinfo->samplerate), soundFileFormatInfo.name, sfinfo->channels,
		(sfinfo->channels > 1) ? "channels" : "channel");
	    if (comment)
		NSLog(@"Input file: comment \"%s\"\n", comment);
	    SndPrintStruct(s);
	}
    } // end if bReadData

    *sound = s;
    return SND_ERR_NONE;
}

#else

int SndReadRange(FILE *fp, SndSoundStruct **sound, const char *fileTypeStr, int startFrame, int frameCount, BOOL bReadData)
{
    SndSoundStruct *s;
    long numOfSamplesActuallyRead, oldFrameCount;
    long samplesRead;
    int headerLen;
    struct st_soundstream informat;
    st_sample_t *readBuffer;
    char *storePtr;
    long i, totalNumOfSamplesToRead;
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

    if(st_gettype(&informat) != ST_SUCCESS)
	return SND_ERR_CANNOT_OPEN;

    /* Read and write starters can change their formats. */
    (* informat.h->startread)(&informat);
    st_checkformat(&informat);

    headerLen = sizeof(SndSoundStruct);
    if (informat.comment) {
	headerLen += strlen(informat.comment) - 4 + 1; // -4 for the 4 bytes defined with SndSoundStruct, +1 for \0
    }
    if (!(s = malloc(headerLen))) return SND_ERR_CANNOT_ALLOC;
    /* endianess is handled within startread() */
    s->magic        = SND_MAGIC; // could be extended using fileTypeStr but only when we write in all formats.
    s->dataLocation = 0;
    s->dataFormat   = soxEncodingToSndDataFormat(informat.info.size, informat.info.encoding);
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
	long readChunkSizeInBytes = SNDREADCHUNKSIZE * sizeof(st_sample_t);

	s->dataLocation = headerLen;
	if ((readBuffer = (st_sample_t *) malloc(readChunkSizeInBytes)) == NULL)
	    return SND_ERR_CANNOT_ALLOC;
	// memset(readBuffer, 0, readChunkSizeInBytes);
	// NSLog(@"Samples: %li samplesize:%i\n",informat.length,informat.info.size);

	samplesRead = 0; // represents the number of samples read so far (excluding header size).
	if (startFrame > informat.length) {
	    NSLog(@"SndReadRange: startFrame > length (%i vs %i)\n", startFrame, informat.length);
	    return SND_ERR_CANNOT_READ;
	}
	if (frameCount < 0) {
	    frameCount = informat.length - startFrame;
	}
	oldFrameCount = frameCount;
	if (startFrame + frameCount > informat.length) {
#if DEBUG_MESSAGES
	    NSLog(@"SndReadRange: startFrame + frameCount > length (%i + %i vs %i) - truncating\n",
	    startFrame, frameCount, informat.length);
#endif
	    frameCount = informat.length - startFrame;
	}

	totalNumOfSamplesToRead = frameCount * informat.info.channels;
	if((s = realloc((char *) s, headerLen + totalNumOfSamplesToRead * informat.info.size)) == NULL)
	    return SND_ERR_CANNOT_ALLOC;

        // memset(((char*)s) + headerLen, 0, totalNumOfSamplesToRead * informat.info.size);
        // NSLog(@"Allocating: %li\n", totalNumOfSamplesToRead * informat.info.size);
	(*informat.h->seek)(&informat, startFrame * informat.info.channels);

	// Read a series of buffers, each numOfSamplesToRead long.
	do {
	    int numOfSamplesToConvert, numOfSamplesToRead = SNDREADCHUNKSIZE;

	    // Determine where to save converted data. samplesRead = the number of channels * number of frames read.
	    storePtr = (char *) s + headerLen + samplesRead * informat.info.size;
	    /* Read chunk of input data less than or equal to the size of the buffer. */
	    if (numOfSamplesToRead > frameCount * informat.info.channels)
		numOfSamplesToRead = frameCount * informat.info.channels;
	    numOfSamplesActuallyRead = (*informat.h->read)(&informat, readBuffer, (st_sample_t) numOfSamplesToRead);
	    if (numOfSamplesActuallyRead <= 0)
		return SND_ERR_CANNOT_READ;
	    numOfSamplesToConvert = numOfSamplesActuallyRead;
	    if (samplesRead + numOfSamplesActuallyRead > totalNumOfSamplesToRead)
		numOfSamplesToConvert = totalNumOfSamplesToRead - samplesRead;

	    switch (s->dataFormat) {
	    case SND_FORMAT_LINEAR_8:
		for(i = 0; i < numOfSamplesToConvert; i++) {
		    int sample = ST_SAMPLE_TO_SIGNED_BYTE(readBuffer[i]);
		    *((char *) storePtr) =  sample; // kludged assuming 16 bits.
		    storePtr += informat.info.size;
		}
		break;
	    case SND_FORMAT_LINEAR_16:
		for(i = 0; i < numOfSamplesToConvert; i++) {
		    int sample = ST_SAMPLE_TO_SIGNED_WORD(readBuffer[i]);
		    *((short *) storePtr) = sample;
		    storePtr += informat.info.size;
		}
		break;
	    case SND_FORMAT_LINEAR_24:
		for(i = 0; i < numOfSamplesToConvert; i++) {
		    // long int sample = ST_SAMPLE_TO_SIGNED_24BIT(readBuffer[i]);
		    long int sample = ((int32_t)(readBuffer[i]) << 8); // this assumes big endian
		    *((long *) storePtr) = sample;
		    storePtr += informat.info.size;
		}
		break;
	    case SND_FORMAT_LINEAR_32:
		for(i = 0; i < numOfSamplesToConvert; i++) {
		    long int sample = ST_SAMPLE_TO_SIGNED_DWORD(readBuffer[i]);
		    *((long *) storePtr) = sample;
		    storePtr += informat.info.size;
		}
		break;
	    case SND_FORMAT_FLOAT:
		for(i = 0; i < numOfSamplesToConvert; i++) {
		    float sample = ST_SAMPLE_TO_FLOAT_DWORD(readBuffer[i]);
		    *((float *) storePtr) = sample;
		    storePtr += informat.info.size;
		}
		break;
	    default:
		NSLog(@"SndFunctionsDiskIO: Argh! Can't convert this stuff I'm reading!");
	    }

	    samplesRead += numOfSamplesActuallyRead;
	} while(samplesRead < totalNumOfSamplesToRead && numOfSamplesActuallyRead == SNDREADCHUNKSIZE); 
	// sound files exactly modulo SNDREADCHUNKSIZE will read 0 bytes next time thru.

	s->dataSize = samplesRead * informat.info.size;
	free(readBuffer);

	if([[NSUserDefaults standardUserDefaults] boolForKey: @"SndShowInputFileFormat"]) {
	    NSLog(@"Input file: using sample rate %lu Hz, size %s, style %s, %d %s\n",
	    (unsigned long)(informat.info.rate), st_sizes_str[(int)(informat.info.size)],
	    st_encodings_str[(int)(informat.info.encoding)], informat.info.channels,
	    (informat.info.channels > 1) ? "channels" : "channel");
	    if (informat.comment)
		NSLog(@"Input file: comment \"%s\"\n", informat.comment);
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

#endif

int SndReadSoundfileRange(NSString *path, SndSoundStruct **sound, int startFrame, int frameCount, BOOL bReadData)
{
    int errorReading, errorClosing;
#ifdef LIBSNDFILE_AVAILABLE
    SNDFILE *sfp;
    SF_INFO sfinfo;
#else
    FILE *fp;
    const char *filetype;
#endif
    SndSoundStruct *aSound;

    *sound = NULL;
    if (path == nil)
	return SND_ERR_BAD_FILENAME;
    if ([path length] == 0)
	return SND_ERR_BAD_FILENAME;
#ifdef LIBSNDFILE_AVAILABLE
    if ((sfp = sf_open([path fileSystemRepresentation], SFM_READ, &sfinfo)) == NULL)
	return SND_ERR_CANNOT_OPEN;
    errorReading = SndReadRange(sfp, &aSound, &sfinfo, startFrame, frameCount, bReadData);
    errorClosing = sf_close(sfp);
    if (errorClosing != 0)
	return SND_ERR_UNKNOWN;
#else
    fp = fopen([path fileSystemRepresentation], "rb");
    if (fp == NULL) return SND_ERR_CANNOT_OPEN;

    filetype = [[path pathExtension] cString];
    if(filetype == NULL || !*filetype)  /* Default to "auto" */
	filetype = "auto";

    errorReading = SndReadRange(fp, &aSound, filetype, startFrame, frameCount, bReadData);
    errorClosing = fclose(fp);
    if (errorClosing == EOF)
	return SND_ERR_UNKNOWN;
#endif
    *sound = aSound;
    return errorReading;
}

int SndReadSoundfile(NSString *path, SndSoundStruct **sound)
{
  return SndReadSoundfileRange(path, sound, 0, -1, TRUE);
}

//
// Expects the sound to not be fragmented, and to be in host order.
// The underlying sound file writing library (Sox (libst) or libsndfile)
// will look after endian issues.
//
#ifdef LIBSNDFILE_AVAILABLE

int SndWriteSoundfile(NSString *filename, SndSoundStruct *sound)
{
    SF_INFO sfinfo;
    SNDFILE *sfp;
    char *comment = NULL;
    long sampleCount = SndSampleCount(sound) * sound->channelCount;
    
    sfinfo.samplerate = (int) sound->samplingRate;
    sfinfo.channels = sound->channelCount;
    // TODO, at the moment we only set the output format from the format of the soundStruct itself, which
    // nowdays will typically be float since all buffers will read that way. We need a writing format parameter when calling this function. This should probably happen at the same time we abandon SndSoundStructs.
    sfinfo.format = SndDataFormatToSndFileEncoding([[filename pathExtension] cString], sound->dataFormat);
    // comment       = sound->info;

    if (!sf_format_check(&sfinfo)) {
	NSLog(@"Bad output format: %d\n", sfinfo.format);
	return SND_ERR_UNKNOWN;
    }

    if((sfp = sf_open([filename fileSystemRepresentation], SFM_WRITE, &sfinfo)) == NULL)
	return SND_ERR_UNKNOWN;
    
    if (sf_write_float(sfp, (float *)((char *) sound + sound->dataLocation), sampleCount) != sampleCount) {
	NSLog(@"writing error: %s\n", sf_strerror(sfp));
	return SND_ERR_UNKNOWN;
    }

    if([[NSUserDefaults standardUserDefaults] boolForKey: @"SndShowOutputFileFormat"]) {
	NSLog(@"Output file %@: using sample rate %d\n\tencoding %x, %d %s",
	    filename, sfinfo.samplerate,
	    (unsigned char) sfinfo.format,
	    sfinfo.channels,
	    (sfinfo.channels > 1) ? "channels" : "channel");

	if (comment) {
	    fprintf(stderr,"Output file: comment \"%s\"\n", comment);
	}
    }
    sf_close(sfp);

    return SND_ERR_NONE;
}

#else

int SndWriteSoundfile(NSString *filename, SndSoundStruct *sound)
{
  int sz;
  struct st_soundstream ft;
  int i;
    
  st_initformat(&ft);
  ft.info.rate     = sound->samplingRate;
  ft.info.encoding = SndDataFormatToSoxEncoding(sound->dataFormat, &sz);
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
  long readChunkSizeInBytes = SNDREADCHUNKSIZE * sizeof(st_sample_t);
  long sampleCount = SndSampleCount(sound) * sound->channelCount;
  void *data = (char *)sound + sound->dataLocation;
  st_sample_t *writeBuffer = malloc(readChunkSizeInBytes);
  
  if (!writeBuffer) {
    fprintf(stderr,"Malloc failed in writeSOXsound\n");
    return SND_ERR_UNKNOWN;
  }
  while (sampleCount > 0) {
    int c = MIN(sampleCount, SNDREADCHUNKSIZE);
    sampleCount -= c;
    
    switch (sound->dataFormat) {
      case SND_FORMAT_LINEAR_8:
        for(i = 0; i < c; i++) {
          char sample = ((char *)data)[i];
          writeBuffer[i] = ST_SIGNED_BYTE_TO_SAMPLE(sample) ; // no swap
        }
        (char *)data += c;
        break;
      case SND_FORMAT_LINEAR_16:
        for(i = 0; i < c; i++) {
          short sample = ((short *)data)[i];
          writeBuffer[i] = ST_SIGNED_WORD_TO_SAMPLE(sample) ; // no swap
        }
        (short *)data += c;
        break;
      case SND_FORMAT_LINEAR_32:
        for(i = 0; i < c; i++) {
          long int sample = ((long int *)data)[i];
          writeBuffer[i] = ST_SIGNED_DWORD_TO_SAMPLE(sample) ; // no swap
        }
        (long int *)data += c;
        break;
      case SND_FORMAT_FLOAT:
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

#endif
