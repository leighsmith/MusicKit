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

#define LIBSNDFILE_AVAILABLE 1

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

#import "SndFunctions.h"
#import "SndMuLaw.h"
#import <Foundation/Foundation.h>
#import "Snd.h"

#import <stdio.h>
#import <sndfile.h>

@implementation Snd(FileIO)

static int SndDataFormatToSndFileEncoding(const char *extension, int sndFormatCode)
{
    int sndfileFormat;
    int formatIndex, formatCount;
    SF_FORMAT_INFO sfFormatInfo;
    
    // Determine major format from file extension, default to AIFF
    sndfileFormat = SF_FORMAT_AIFF;
    
    // libsndfile's "major" formats are different standard sound file formats, 
    // the "subtype" formats are various encodings within each format.
    sf_command(NULL, SFC_GET_FORMAT_MAJOR_COUNT, &formatCount, sizeof(int));

    for (formatIndex = 0; formatIndex < formatCount; formatIndex++) {	
	sfFormatInfo.format = formatIndex;
        if(sf_command(NULL, SFC_GET_FORMAT_MAJOR, &sfFormatInfo, sizeof(sfFormatInfo)) == 0) {
            if(strcmp(extension, sfFormatInfo.extension) == 0) {
                sndfileFormat = sfFormatInfo.format;
                break;
            }
        }
    }
    
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

// return the file extensions supported by our sound file reading library, typically sox or sndlibfile.
+ (NSArray *) soundFileExtensions
{
    // libsndfile doesn't have a concept of aliases for common file extensions so
    // we have to add them manually. This is bad. libsndfile should provide an alias list.
    NSMutableArray *fileTypes = [NSMutableArray arrayWithObjects: @"aif", @"nist", @"aifc", @"snd", nil];
    int formatIndex, formatCount;
    SF_FORMAT_INFO sfFormatInfo;

    // libsndfile's "major" formats are different standard sound file formats, the "subtype" formats are various
    // encodings within each format.
    sf_command (NULL, SFC_GET_FORMAT_MAJOR_COUNT, &formatCount, sizeof(int));

    for (formatIndex = 0; formatIndex < formatCount; formatIndex++) {
	NSString *fileExtension;
	
	// include all the alternative namings.
	sfFormatInfo.format = formatIndex;
	sf_command(NULL, SFC_GET_FORMAT_MAJOR, &sfFormatInfo, sizeof(sfFormatInfo));
	fileExtension = [NSString stringWithCString: sfFormatInfo.extension];
	[fileTypes addObject: fileExtension];
	// Accept upper case equivalent. TODO This should probably be an optional behaviour.
	[fileTypes addObject: [fileExtension uppercaseString]];
    }
    return [NSArray arrayWithArray: fileTypes]; // make it immutable
}

+ (NSString *) defaultFileExtension
{
    return @"au"; // TODO this should probably be determined at run time based on the operating system
}

+ (BOOL) isPathForSoundFile: (NSString *) path
{
    NSArray *exts = [[self class] soundFileExtensions];
    NSString *ext  = [path pathExtension];
    int extensionIndex, extensionCount = [exts count];
    
    for (extensionIndex = 0; extensionIndex < extensionCount; extensionIndex++) {
	NSString *anExt = [exts objectAtIndex: extensionIndex];
	if ([ext compare: anExt options: NSCaseInsensitiveSearch] == NSOrderedSame)
	    return YES;
    }
    return NO;
}

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

int SndReadSoundfileRange(NSString *path, SndSoundStruct **sound, int startFrame, int frameCount, BOOL bReadData)
{
    int errorReading, errorClosing;
    SNDFILE *sfp;
    SF_INFO sfinfo;
    SndSoundStruct *aSound;

    *sound = NULL;
    if (path == nil)
	return SND_ERR_BAD_FILENAME;
    if ([path length] == 0)
	return SND_ERR_BAD_FILENAME;
    if ((sfp = sf_open([path fileSystemRepresentation], SFM_READ, &sfinfo)) == NULL) {
	if(sf_error(sfp) != SF_ERR_NO_ERROR) {
	    NSLog(@"%s\n", sf_strerror(sfp));
            if([[NSUserDefaults standardUserDefaults] boolForKey: @"SndShowLogOnReadError"]) {
                char readingLogBuffer[2048];  // TODO we could malloc and free this here instead.

                sf_command(sfp, SFC_GET_LOG_INFO, readingLogBuffer, sizeof(readingLogBuffer));
                NSLog(@"Error log of file reading: %s\n", readingLogBuffer);
            }
	}	
	return SND_ERR_CANNOT_OPEN;
    }
    errorReading = SndReadRange(sfp, &aSound, &sfinfo, startFrame, frameCount, bReadData);
    errorClosing = sf_close(sfp);
    if (errorClosing != 0)
	return SND_ERR_UNKNOWN;
    *sound = aSound;
    return errorReading;
}

int SndReadSoundfile(NSString *path, SndSoundStruct **sound)
{
  return SndReadSoundfileRange(path, sound, 0, -1, TRUE);
}

- (int) readSoundfile: (NSString *) filename
{
    int err;
    NSDictionary *fileAttributeDictionary;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (soundStruct)
        SndFree(soundStruct);
    
    [name release];
    name = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath: filename]) {
//      NSLog(@"Snd::readSoundfile: sound file %@ doesn't exist",filename);
	return SND_ERR_CANNOT_OPEN;
    }
    
    // check its seekable, by checking it is POSIX regular.
    fileAttributeDictionary = [fileManager fileAttributesAtPath: filename
					           traverseLink: YES];
    
    if([fileAttributeDictionary objectForKey: NSFileType] != NSFileTypeRegular)
        return SND_ERR_CANNOT_OPEN;
    
    // TODO this needs to retrieve loop pointers and an info NSString.
    err = SndReadSoundfile(filename, &soundStruct);
    
    // NSLog(@"%@\n", SndStructDescription(soundStruct));
    if (!err) {
	// Set ivars after reading the file.
	info = [[NSString stringWithCString: (char *)(soundStruct->info)] retain];
        soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
	// TODO These are only needed until the soundStruct parameter to SndReadSoundfile becomes a SndFormat.
	soundFormat.sampleRate = soundStruct->samplingRate;
	soundFormat.channelCount = soundStruct->channelCount;
	soundFormat.dataFormat = soundStruct->dataFormat;
	soundFormat.frameCount = SndFrameCount(soundStruct);
        // This is probably a bit kludgy but it will do for now.
	// TODO when we can retrieve the loop indexes from the sound file, this should become the default value.
        loopEndIndex = [self lengthInSampleFrames] - 1;
    }
    return err;
}

// writes the sound data, soundDataFormat describes the format of the data pointed to by soundData.
// TODO The parameters can probably be eventually changed to take an SndAudioBuffer when Snd's hold it's internal
// data as one or more SndAudioBuffers.
int SndWriteSampleData(SNDFILE *sfp, void *soundData, SndFormat soundDataFormat)
{
    long sampleCount = soundDataFormat.frameCount * soundDataFormat.channelCount;

    switch(soundDataFormat.dataFormat) {
    case SND_FORMAT_FLOAT:
	if (sf_write_float(sfp, (float *) soundData, sampleCount) != sampleCount) {
	    NSLog(@"writing from floats error: %s\n", sf_strerror(sfp));
	    return SND_ERR_UNKNOWN;
	}
	break;
    case SND_FORMAT_LINEAR_16:
	if (sf_write_short(sfp, (short *) soundData, sampleCount) != sampleCount) {
	    NSLog(@"writing from shorts error: %s\n", sf_strerror(sfp));
	    return SND_ERR_UNKNOWN;
	}
	break;
    case SND_FORMAT_LINEAR_32:
	if (sf_write_int(sfp, (int *) soundData, sampleCount) != sampleCount) {
	    NSLog(@"writing from ints error: %s\n", sf_strerror(sfp));
	    return SND_ERR_UNKNOWN;
	}
	break;
    default:
	NSLog(@"Unable to write from format %d, not supported\n", soundDataFormat.dataFormat);	    
    }
    return SND_ERR_NONE;
}

// The underlying sound file writing library (libsndfile) will look after endian issues.
- (int) writeSoundfile: (NSString *) filename
	    fileFormat: (NSString *) fileFormat
	    dataFormat: (SndSampleFormat) fileDataFormat
{
    SF_INFO sfinfo;
    SNDFILE *sfp;
    char *comment = NULL;
    int error;
    
    sfinfo.samplerate = (int) [self samplingRate];
    sfinfo.channels = [self channelCount];
    sfinfo.format = SndDataFormatToSndFileEncoding([fileFormat cString], fileDataFormat);
    // comment       = sound->info;

    if (!sf_format_check(&sfinfo)) {
	NSLog(@"Bad output format: 0x%x\n", sfinfo.format);
	return SND_ERR_UNKNOWN;
    }

    if((sfp = sf_open([filename fileSystemRepresentation], SFM_WRITE, &sfinfo)) == NULL)
	return SND_ERR_UNKNOWN;
    
    if([[NSUserDefaults standardUserDefaults] boolForKey: @"SndShowOutputFileFormat"]) {
	NSLog(@"Output file %s: using sample rate %d, encoding %x, %d %s",
	      [filename fileSystemRepresentation],
	      sfinfo.samplerate,
	      (unsigned char) sfinfo.format,
	      sfinfo.channels,
	      (sfinfo.channels > 1) ? "channels" : "channel");
	
	if (comment) {
	    NSLog(@"Output file: comment \"%s\"\n", comment);
	}
    }
    // Writing the whole thing out assumes the sound is compacted.
    error = SndWriteSampleData(sfp, [self data], [self format]);
    if(error != SND_ERR_NONE)
	return error;
    sf_close(sfp);

    return SND_ERR_NONE;
}

// Set the output format from the format of the sound itself, which
// nowdays will typically be float since all buffers will read that way. 
// Any other desired format requires converting the Snd.
- (int) writeSoundfile: (NSString *) filename
{
    // compaction ideally should not be necessary, but libsndfile  requires it for now
    [self compactSamples]; 
    return [self writeSoundfile: filename fileFormat: [filename pathExtension] dataFormat: [self dataFormat]];
}

@end
