////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    Routines to read and write sound files.
//    Historically these have been functions rather than methods. Nowdays, we
//    keep them as functions only to isolate our sound file reading library
//    (libsndfile) from the rest of the code base, especially regarding
//    including headers etc.
//
//  Original Author: Leigh M. Smith <leigh@leighsmith.com>
//
//  Copyright (c) 2002, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#define DEBUG_MESSAGES 0

// Selectively compile this class if the libsndfile library has not been installed.
#if HAVE_CONFIG_H
# import "SndKitConfig.h"
#endif

#import "SndFunctions.h"
#import "SndMuLaw.h"
#import "Snd.h"
#import "SndAudioBuffer.h"

@implementation Snd(FileIO)

+ (int) fileFormatForEncoding: (NSString *) extensionString
		   dataFormat: (SndSampleFormat) sndFormatCode
{
#if HAVE_LIBSNDFILE
    int sndfileFormat;
    int formatIndex, formatCount;
    SF_FORMAT_INFO sfFormatInfo;
    const char *extension = [extensionString UTF8String];
    
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
	NSLog(@"Snd +fileFormatForEncoding:dataFormat: unhandled format %d\n", sndFormatCode);
    }
    return sndfileFormat;
#else
#warning Disabled sound file I/O in Snd class since libsndfile library was not installed.
    return 0;
#endif
}

// return the file extensions supported by our sound file reading library, nowdays libsndfile.
+ (NSArray *) soundFileExtensions
{
#if HAVE_LIBSNDFILE
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
	fileExtension = [NSString stringWithUTF8String: sfFormatInfo.extension];
	[fileTypes addObject: fileExtension];
	// Accept upper case equivalent. TODO This should probably be an optional behaviour.
	[fileTypes addObject: [fileExtension uppercaseString]];
    }
    return [NSArray arrayWithArray: fileTypes]; // make it immutable
#else
    return [NSArray array];
#endif
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

- (SndFormat) soundFormatOfFilename: (NSString *) path
{
#if HAVE_LIBSNDFILE
    SndFormat headerFormat = { SND_FORMAT_UNSPECIFIED, 0, 0, 0 };
    SNDFILE *sfp;
    SF_INFO sfinfo;
    NSFileHandle *readingFileHandle = [NSFileHandle fileHandleForReadingAtPath: [path stringByExpandingTildeInPath]]; 

    if ((sfp = sf_open_fd([readingFileHandle fileDescriptor], SFM_READ, &sfinfo, TRUE)) == NULL) {
	if(sf_error(sfp) != SF_ERR_NO_ERROR) {
	    NSLog(@"%s\n", sf_strerror(sfp));
            if([[NSUserDefaults standardUserDefaults] boolForKey: @"SndShowLogOnReadError"]) {
                char readingLogBuffer[2048];  // TODO we could malloc and free this here instead.
		
                sf_command(sfp, SFC_GET_LOG_INFO, readingLogBuffer, sizeof(readingLogBuffer));
                NSLog(@"Error log of file reading: %s\n", readingLogBuffer);
            }
	}	
    }
    else {
	headerFormat.dataFormat   = SND_FORMAT_FLOAT;  // We only retrieve floats, we let libsndfile do the format conversions itself.
	headerFormat.sampleRate   = sfinfo.samplerate;
	headerFormat.channelCount = sfinfo.channels;
	headerFormat.frameCount   = sfinfo.frames; // whole sound for the moment	
    }
    
    sf_close(sfp);
    [readingFileHandle closeFile];
    
    return headerFormat;
#else
    SndFormat headerFormat = { SND_FORMAT_UNSPECIFIED, 0, 0, 0 };

    return headerFormat;
#endif
}


// Retrieve loop points
// The AIFF loop structure is a lot richer than our simplistic single loop structure. So for now
// we just use the first AIFF loop.
// Returns YES if we could find a set of loop points, NO if not.
- (NSRange) loopRange
{
    // TODO loopEndIndex will be loop.location + loop.length - 1;
    NSRange loop = { 0, [self lengthInSampleFrames] };
    
#if HAVE_LIBSNDFILE
    SF_LOOP_INFO loopInfo;
    int result = sf_command(NULL, SFC_GET_LOOP_INFO, &loopInfo, sizeof(loopInfo));

    if(result) {
	switch(loopInfo.loop_mode) {
	case SF_LOOP_NONE:
	    // Loop is off
	    break;
	case SF_LOOP_FORWARD:
	    // Loop forward only.
	    break;
	case SF_LOOP_BACKWARD:
	    // Loop backward (only?)
	    break;
	}
	// loop.location = loopInfo.start;
	// loop.length   = loopInfo.start + loopInfo.length;
    }
#endif
    return loop;
}

// TODO it would be preferable to have readSoundfile: (NSString *) fromRange: (NSRange) 
// However we need a mechanism to indicate infinity for the length in order to signal to read to EOF.
- (int) readSoundfile: (NSString *) path
	   startFrame: (unsigned long) startFrame
	   frameCount: (long) frameCount // must be signed for -1 = read to EOF marker.
{
#if HAVE_LIBSNDFILE
    SNDFILE *sfp;
    SF_INFO sfinfo;
    SF_FORMAT_INFO soundFileFormatInfo;
    long numOfSamplesActuallyRead;
    long totalNumOfSamplesToRead;
    int errorClosing;
    const char *comment;
    NSFileHandle *readingFileHandle;
    NSAutoreleasePool *fileReadingPool = [[NSAutoreleasePool alloc] init];
    SndAudioBuffer *fileContents;
    
    if (path == nil)
	return SND_ERR_BAD_FILENAME;
    if ([path length] == 0)
	return SND_ERR_BAD_FILENAME;
    readingFileHandle = [NSFileHandle fileHandleForReadingAtPath: [path stringByExpandingTildeInPath]]; 
    if ((sfp = sf_open_fd([readingFileHandle fileDescriptor], SFM_READ, &sfinfo, TRUE)) == NULL) {
	if(sf_error(sfp) != SF_ERR_NO_ERROR) {
	    NSLog(@"File reading error: %s\n", sf_strerror(sfp));
            if([[NSUserDefaults standardUserDefaults] boolForKey: @"SndShowLogOnReadError"]) {
                char readingLogBuffer[2048];  // TODO we could malloc and free this here instead.

                sf_command(sfp, SFC_GET_LOG_INFO, readingLogBuffer, sizeof(readingLogBuffer));
                NSLog(@"Error log of file reading: %s\n", readingLogBuffer);
            }
	}	
	return SND_ERR_CANNOT_OPEN;
    }
    
    if(!sfinfo.seekable && startFrame != 0)
	return SND_ERR_CANNOT_OPEN;
    
    soundFileFormatInfo.format = sfinfo.format;
    if(sf_command(sfp, SFC_GET_FORMAT_INFO, &soundFileFormatInfo, sizeof(soundFileFormatInfo)) != 0) {
	if(sf_error(sfp) != SF_ERR_NO_ERROR) {
	    NSLog(@"%s\n", sf_strerror(sfp));
	}
	return SND_ERR_CANNOT_READ;
    }
    
    // Retrieve the sound file comment as the info string.
    if((comment = sf_get_string(sfp, SF_STR_COMMENT)) != NULL) {
	[info release];
	info = [[NSString stringWithUTF8String: comment] retain];
    }
    
#if DEBUG_MESSAGES
    NSLog(@"Samples: %d data format: %x\n", sfinfo.frames, sfinfo.format);
#endif
    if (startFrame > sfinfo.frames) {
	NSLog(@"SndReadRange: startFrame > length (%i vs %i)\n", startFrame, sfinfo.frames);
	return SND_ERR_CANNOT_READ;
    }
    if (frameCount < 0) {
	frameCount = sfinfo.frames - startFrame;
    }
    if (startFrame + frameCount > sfinfo.frames) {
#if DEBUG_MESSAGES
	NSLog(@"SndReadRange: startFrame + frameCount > length (%i + %i vs %i) - truncating\n", startFrame, frameCount, sfinfo.frames);
#endif
	frameCount = sfinfo.frames - startFrame;
    }
    
    // We only retrieve floats, we let libsndfile do the format conversions itself.
    soundFormat.dataFormat = SND_FORMAT_FLOAT;
    soundFormat.sampleRate = sfinfo.samplerate;
    soundFormat.channelCount = sfinfo.channels;

    totalNumOfSamplesToRead = frameCount * sfinfo.channels;
    
    fileContents = [SndAudioBuffer audioBufferWithDataFormat: soundFormat.dataFormat
						channelCount: soundFormat.channelCount
					        samplingRate: soundFormat.sampleRate
						  frameCount: frameCount];
    if(fileContents == nil)
	return SND_ERR_CANNOT_ALLOC;
    
    // NSLog(@"Allocating: %li\n", totalNumOfSamplesToRead * SndSampleWidth(soundFormat.dataFormat));
    if(sf_seek(sfp, startFrame, SEEK_SET) == -1) {
	if(sf_error(sfp) != SF_ERR_NO_ERROR) {
	    NSLog(@"%s\n", sf_strerror(sfp));
	    return SND_ERR_CANNOT_READ;
	}
    }

    // endian order is handled within sf_read_float().
    numOfSamplesActuallyRead = sf_read_float(sfp, (float *) [fileContents bytes], totalNumOfSamplesToRead);
    if (numOfSamplesActuallyRead < 0)
	return SND_ERR_CANNOT_READ;
    
    soundFormat.frameCount = numOfSamplesActuallyRead / sfinfo.channels;

    if([[NSUserDefaults standardUserDefaults] boolForKey: @"SndShowInputFileFormat"]) {
	NSLog(@"Input file %@: style %s %@\n", path, soundFileFormatInfo.name, self);
    }
    
    errorClosing = sf_close(sfp);
    [readingFileHandle closeFile];

    // Replace all audio buffers with the new file contents buffer.
    [soundBuffers removeAllObjects];
    [soundBuffers addObject: fileContents];
    
    if (errorClosing != 0)
	return SND_ERR_UNKNOWN;
        
    // TODO Need to retrieve loop pointers.
    // This is probably a bit kludgy but it will do for now.
    // TODO when we can retrieve the loop indexes from the sound file, this should become the default value.
    loopEndIndex = [self lengthInSampleFrames] - 1;
    
    [fileReadingPool release];
    
    return SND_ERR_NONE;
#else
    NSLog(@"File reading not configured!\n");
    return SND_ERR_NOT_IMPLEMENTED;
#endif
}

- (int) readSoundfile: (NSString *) filename
{
    NSDictionary *fileAttributeDictionary;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *expandedFilename = [filename stringByExpandingTildeInPath];
    
    [name release];
    name = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath: expandedFilename]) {
	NSLog(@"Snd -readSoundfile: sound file %@ doesn't exist", expandedFilename);
	return SND_ERR_CANNOT_OPEN;
    }
    
    // check its seekable, by checking it is POSIX regular.
#if !defined(MAC_OS_X_VERSION_10_5) || (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5)
    fileAttributeDictionary = [fileManager fileAttributesAtPath: expandedFilename traverseLink: YES];
#else
    fileAttributeDictionary = [fileManager attributesOfItemAtPath: expandedFilename error: NULL];
#endif
    
    if([fileAttributeDictionary objectForKey: NSFileType] != NSFileTypeRegular) {
	NSLog(@"Snd -readSoundfile: sound file %@ not a regular file\n", expandedFilename);
        return SND_ERR_CANNOT_OPEN;
    }
        
    return [self readSoundfile: expandedFilename startFrame: 0 frameCount: -1];    
}

// writes the sound data, soundDataFormat describes the format of the data pointed to by soundData.
// TODO The parameters can probably be eventually changed to take an SndAudioBuffer when Snd's hold it's internal
// data as one or more SndAudioBuffers. Alternatively, perhaps this is a candidate to become a SndAudioBuffer method.
int SndWriteSampleData(SNDFILE *sfp, void *soundData, SndFormat soundDataFormat)
{
#if HAVE_LIBSNDFILE
    long sampleCount = soundDataFormat.frameCount * soundDataFormat.channelCount;

    switch(soundDataFormat.dataFormat) {
    case SND_FORMAT_FLOAT:
	if (sf_write_float(sfp, (float *) soundData, sampleCount) != sampleCount) {
	    NSLog(@"SndWriteSampleData() error writing %ld floats: %s\n", sampleCount, sf_strerror(sfp));
	    return SND_ERR_UNKNOWN;
	}
	break;
    case SND_FORMAT_LINEAR_16:
	if (sf_write_short(sfp, (short *) soundData, sampleCount) != sampleCount) {
	    NSLog(@"SndWriteSampleData() error writing %ld shorts: %s\n", sampleCount, sf_strerror(sfp));
	    return SND_ERR_UNKNOWN;
	}
	break;
    case SND_FORMAT_LINEAR_32:
	if (sf_write_int(sfp, (int *) soundData, sampleCount) != sampleCount) {
	    NSLog(@"SndWriteSampleData() error writing %ld ints: %s\n", sampleCount, sf_strerror(sfp));
	    return SND_ERR_UNKNOWN;
	}
	break;
    default:
	NSLog(@"SndWriteSampleData() Unable to write from format %d, not supported\n", soundDataFormat.dataFormat);	    
    }
#endif    
    return SND_ERR_NONE;
}

// The underlying sound file writing library (libsndfile) will look after endian issues.
- (int) writeSoundfile: (NSString *) path
	    fileFormat: (NSString *) fileFormat
	    dataFormat: (SndSampleFormat) fileDataFormat
{
#if HAVE_LIBSNDFILE
    SF_INFO sfinfo;
    SNDFILE *sfp;
    int error;
    NSFileHandle *writingFileHandle;
    
    sfinfo.samplerate = (int) [self samplingRate];
    sfinfo.channels = [self channelCount];
    sfinfo.format = [[self class] fileFormatForEncoding: fileFormat dataFormat: fileDataFormat];

    if (!sf_format_check(&sfinfo)) {
	NSLog(@"Bad output format: 0x%x\n", sfinfo.format);
	return SND_ERR_UNKNOWN;
    }

    if(![[NSFileManager defaultManager] createFileAtPath: path contents: nil attributes: nil]) {
	NSLog(@"SndAudioProcessorRecorder -writeSoundfile:fileFormat:dataFormat: Error creating file '%@' for recording.\n", path);
	return SND_ERR_UNKNOWN;
    }
    writingFileHandle = [NSFileHandle fileHandleForWritingAtPath: path];
    // NSLog(@"fileFormat = %@, writingFileHandle = %@", fileFormat, writingFileHandle);
    if ((sfp = sf_open_fd([writingFileHandle fileDescriptor], SFM_WRITE, &sfinfo, TRUE)) == NULL)
	return SND_ERR_UNKNOWN;
    
    if([[NSUserDefaults standardUserDefaults] boolForKey: @"SndShowOutputFileFormat"]) {
	NSLog(@"Output file %s: using sample rate %d, encoding %x, %d %s",
	      [path fileSystemRepresentation],
	      sfinfo.samplerate,
	      (unsigned char) sfinfo.format,
	      sfinfo.channels,
	      (sfinfo.channels > 1) ? "channels" : "channel");
    }

    if(info != nil) {
#if DEBUG_MESSAGES
	NSLog(@"Output file: writing info comment \"%s\"\n", [info UTF8String]);
#endif	
	error = sf_set_string(sfp, SF_STR_COMMENT, [info UTF8String]);
	// if saving comments are not supported for this file format, just skip it silently
	if(error != 0) {
	    NSLog(@"-writeSoundfile:fileFormat:dataFormat: Error writing info comment \"%s\": %s\n", [info UTF8String], sf_error_number(error));
	    // TODO libsndfile does not allow testing whether strings are supported or not, so we have to skip over a potential hard error.
	    // return SND_ERR_CANNOT_WRITE;	
	}
    }
    
    // Writing the whole thing out assumes the sound is compacted.
    error = SndWriteSampleData(sfp, [self bytes], [self format]);
    if(error != SND_ERR_NONE)
	return error;
    sf_close(sfp);
    [writingFileHandle closeFile];
    
    return SND_ERR_NONE;
#else
    return SND_ERR_NOT_IMPLEMENTED;
#endif
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
