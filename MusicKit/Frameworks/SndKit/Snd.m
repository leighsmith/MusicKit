////////////////////////////////////////////////////////////////////////////////
//
// $Id$
// 
// Description: Main class defining a sound object.
// 
// Original Author: Stephen Brandon
// 
// LEGAL:
// This framework and all source code supplied with it, except where specified,
// are Copyright Stephen Brandon and the University of Glasgow, 1999. You are free
// to use the source code for any purpose, including commercial applications, as
// long as you reproduce this notice on all such software.
// 
// Software production is complex and we cannot warrant that the Software will be
// error free.  Further, we will not be liable to you if the Software is not fit
// for the purpose for which you acquired it, or of satisfactory quality. 
// 
// WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL
// WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES
// OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD
// PARTIES RIGHTS.
// 
// If a court finds that we are liable for death or personal injury caused by our
// negligence our liability shall be unlimited.  
// 
// WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS
// OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR
// POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE
// NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED
// DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND
// CONDITIONS OF THIS AGREEMENT.
// 
// Additions Copyright (c) 2001, The MusicKit Project.  All rights reserved.
// 
// Legal Statement Covering Additions by The MusicKit Project:
//
//    Permission is granted to use and modify this code for commercial and
//    non-commercial purposes so long as the author attribution and copyright
//    messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

/* HISTORY
 * ..is now contained in the cvs log.
 * pre cvs:
 * 20/6/99 sb: added check to -compactSamples to ensure sound needs it
 */

#ifdef WIN32
#include <windows.h>
#else
# ifndef GNUSTEP
#  include <libc.h>
# endif
#endif

#include <stdlib.h>
#include <stdio.h>
#include <string.h> /* for memmove() */

#import "Snd.h"
#import "SndError.h"
#import "SndFunctions.h"
#import "SndTable.h"
#import "SndAudioBuffer.h"
#import "SndAudioProcessorChain.h"
#import "SndMuLaw.h"

@implementation Snd

+ soundNamed:(NSString *)aName
{
  return [[SndTable defaultSndTable] soundNamed: aName];
}

+ findSoundFor:(NSString *)aName
{
  return [[SndTable defaultSndTable] findSoundFor: aName];
}

+ addName:(NSString *)aname sound:aSnd
{
  return [[SndTable defaultSndTable] addName: aname sound:aSnd];
}

+ addName:(NSString *)aname fromSoundfile:(NSString *)filename
{
  return [[SndTable defaultSndTable] addName: aname fromSoundfile: filename];
}

+ addName:(NSString *)aname fromSection:(NSString *)sectionName
{
  return [[SndTable defaultSndTable] addName: aname fromSection: sectionName];
}

+ addName:(NSString *)aName fromBundle:(NSBundle *)aBundle
{
  return [[SndTable defaultSndTable] addName: aName fromBundle: aBundle];
}

+ (void) removeSoundForName: (NSString *) aname
{
    [[SndTable defaultSndTable] removeSoundForName: aname];
}

+ (void) removeAllSounds
{
    [[SndTable defaultSndTable] removeAllSounds];
}

- initWithFormat: (SndSampleFormat) format
    channelCount: (int) channels
	  frames: (int) frames
    samplingRate: (float) samplingRate
{
    self = [super init];
    if (self != nil) {
	name = nil;
	conversionQuality = SndConvertLowQuality;
	delegate = nil;
	status = SND_SoundInitialized;
	info = nil;
	currentError = 0;
	tag = 0;
	
	if (performancesArray == nil) {
	    performancesArray     = [[NSMutableArray array] retain];
	    performancesArrayLock = [NSLock new];
	}
	else
	    [performancesArray removeAllObjects];
	
	// initialize loop points to legal values
	loopWhenPlaying = NO;
	loopStartIndex = 0;
	loopEndIndex = frames;
	
	// initialize the priming audio processor chain for playback.
	audioProcessorChain = nil;
	
#if 1 // while we still use soundStruct
	if (soundStruct == NULL) {
	    if (!(soundStruct = malloc(sizeof(SndSoundStruct))))
		[[NSException exceptionWithName: @"Sound Error"
					 reason: @"Can't allocate memory for Snd class"
				       userInfo: nil] raise];
	}
	
	if (soundStruct)
	    SndFree(soundStruct);
	SndAlloc(&soundStruct, SndFramesToBytes(frames, channels, format), format, (int) samplingRate, channels, 0);
#endif
	soundFormat.dataFormat = format;
	soundFormat.sampleRate = samplingRate;
	soundFormat.channelCount = channels;
	soundFormat.frameCount = frames;
	// info = @""; // TODO, should we just leave it nil, rather than empty?
    }
    return self;
}

// The default modern version, generate a zero length floating point, stereo CD quality sound.
- init
{
    return [self initWithFormat: SND_FORMAT_FLOAT channelCount: 2 frames: 0 samplingRate: 44100.0];
}

- initWithAudioBuffer: (SndAudioBuffer *) aBuffer
{
    Snd *newInstance = [self initWithFormat: [aBuffer dataFormat]
			       channelCount: [aBuffer channelCount]
				     frames: [aBuffer lengthInSampleFrames]
			       samplingRate: [aBuffer samplingRate]]; 
  
    memcpy([newInstance data], [aBuffer bytes], [aBuffer lengthInBytes]);  
    return newInstance;
}

- initFromSoundfile: (NSString *) filename
{
  self = [self init];
  if (self != nil) {
    if ([self readSoundfile: filename] != SND_ERR_NONE) {
      [self release];
      return nil;
    }
  }
  return self;
}

- initFromSoundURL: (NSURL *) url
{
  self = [self init];
  if (self != nil) {
      // TODO this should actually read HTTP, FTP URLs also.
    if ([self readSoundfile: [url path]] != SND_ERR_NONE) {
      [self release];
      return nil;
    }
  }
  return self;
}

- initWithData: (NSData *) soundData
{
    if([self init] != nil)
	[self readSoundFromData: soundData];
    
    return self;
}

- (unsigned) hash
{
  unsigned ss = 0;
  if (soundStruct) {
    // take into account all basic metadata, including size, formate, rate, channels
    ss = ((unsigned *)soundStruct)[0] + ((unsigned *)soundStruct)[1] + 
         ((unsigned *)soundStruct)[2] + ((unsigned *)soundStruct)[3] +
	 ((unsigned *)soundStruct)[4] + ((unsigned *)soundStruct)[5] +
         ((unsigned *)soundStruct)[6] + ((unsigned *)soundStruct)[7];
  }
  return [name length] * 256 + 512 * tag + ss + 1023 * soundStructSize;
}

// return the file extensions supported by our sound file reading library, typically sox or sndlibfile.
+ (NSArray *) soundFileExtensions
{
    return SndFileExtensions();
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

- (void) dealloc
{
    if (name) {
        if ([[SndTable defaultSndTable] soundNamed: name] == self)
            [[SndTable defaultSndTable] removeSoundForName: name];
        [name release];
	name = nil;
    }
    if (soundStruct)
	SndFree(soundStruct);
    [performancesArray release];
    performancesArray = nil;
    [performancesArrayLock release];
    performancesArrayLock = nil;
    [info release];
    info = nil;
    [audioProcessorChain release];
    audioProcessorChain = nil;
    //[delegate release]; // We don't retain it so we don't release it.
    //delegate = nil;
    [super dealloc];
}

// for debugging
- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ (%@ %@ %@)", 
	[super description],
	name != nil ? name : @"(unnamed)",
	(soundStruct != NULL) ? SndStructDescription(soundStruct) : @"",
	info];
    // TODO SndFormatDescription(format)
}

// TODO Assumes all data is formatted as .au only.
- (BOOL) readSoundFromData: (NSData *) soundData
{
    SndSoundStruct *s;
    int finalSize;

    priority = 0;

    if (soundStruct)
	SndFree(soundStruct);
    if (!(s = malloc(sizeof(SndSoundStruct))))
        [[NSException exceptionWithName: @"Sound Error"
                                 reason: @"Can't allocate memory for Snd class"
                               userInfo: nil] raise];
    [soundData getBytes: s length: sizeof(SndSoundStruct) - 4]; /* SndSoundStruct includes the first 4 bytes of the info string */

    s->magic = NSSwapBigLongToHost(s->magic);
    s->dataLocation = NSSwapBigLongToHost(s->dataLocation);
    s->dataSize = NSSwapBigLongToHost(s->dataSize);
    s->dataFormat = NSSwapBigLongToHost(s->dataFormat);
    s->samplingRate = NSSwapBigLongToHost(s->samplingRate);
    s->channelCount = NSSwapBigLongToHost(s->channelCount);

    // Verify we do have a .au/.snd file.
    if (s->magic == SND_MAGIC) {
	int infoStringLength = s->dataLocation - sizeof(SndSoundStruct) + 4;
	char *infoCString;
	
	if ((infoCString = malloc(infoStringLength + 1)) == NULL) // + 1 for terminating \0.
	    [[NSException exceptionWithName: @"Sound Error"
				     reason: @"Can't allocate memory for info string"
				   userInfo: nil] raise];
	[soundData getBytes: infoCString range: NSMakeRange(sizeof(SndSoundStruct) - 4, infoStringLength)];
	infoCString[infoStringLength] = '\0'; // terminate the string
	[info release];
	info = [[NSString stringWithCString: infoCString] retain];
	free(infoCString);
	
	finalSize = s->dataSize + sizeof(SndSoundStruct); // Allocate no size for info (deprecated)
	// NSLog(@"%@\n", SndStructDescription(s), finalSize);
	s = realloc((char *) s, finalSize);
	[soundData getBytes: (char *) s + sizeof(SndSoundStruct)
		      range: NSMakeRange(s->dataLocation, s->dataSize)];
	// Reassign dataLocation to be just beyond the SndSoundStruct.
	s->dataLocation = sizeof(SndSoundStruct);
	
	soundStruct = s;
	status = SND_SoundInitialized;
	// Prime format. 
	// TODO these should eventually be read in order direct from the NSData instance once SndSoundStruct is removed.
	soundFormat.dataFormat = s->dataFormat;
	soundFormat.channelCount = s->channelCount;
	soundFormat.frameCount = SndFrameCount(soundStruct);
	soundFormat.sampleRate = s->samplingRate;
	loopEndIndex = [self lengthInSampleFrames] - 1;
	return YES;
    } 
    else
	return NO;
}

// TODO at the moment we ignore the dataFormat, only writing AU format.
// Eventually we need to replace this with file writing routines.
- (NSData *) dataEncodedAsFormat: (NSString *) dataFormat
{
    SndSoundStruct **ssList;
    SndSoundStruct *theStruct;
    NSMutableData *soundData; 
    unsigned int dataOffsetLocation = 6 * sizeof(int);  // offset past the audio header, not including info.
    unsigned int sampleDataSize = [self dataSize];
    SndSampleFormat df = soundStruct->dataFormat;

    if (df == SND_FORMAT_INDIRECT) {
        int newCount = 0;
        int i = 0;
        ssList = (SndSoundStruct **) soundStruct->dataLocation;
        while ((theStruct = ssList[i++]) != NULL)
	    newCount += theStruct->dataSize;
        dataOffsetLocation = soundStruct->dataSize;
        sampleDataSize = newCount;
    }
    // TODO not sure this will work with indirect sounds.
    dataOffsetLocation += [info length];

    soundData = [NSMutableData dataWithCapacity: sampleDataSize]; 

    // Write header. We standardise to a big endian integer representation
    {
	int bigMagic = NSSwapHostIntToBig(SND_MAGIC);
	int bigDataLocation = NSSwapHostIntToBig(dataOffsetLocation);
	int bigDataSize = NSSwapHostIntToBig(sampleDataSize);
	int bigDataFormat = NSSwapHostIntToBig([self dataFormat]);
	int bigSamplingRate = NSSwapHostIntToBig((int) ([self samplingRate] + 0.5));
	int bigChannelCount = NSSwapHostIntToBig([self channelCount]);
	
	[soundData appendBytes: &bigMagic        length: sizeof(bigMagic)];
	[soundData appendBytes: &bigDataLocation length: sizeof(bigDataLocation)];
	[soundData appendBytes: &bigDataSize     length: sizeof(bigDataSize)];
	[soundData appendBytes: &bigDataFormat   length: sizeof(bigDataFormat)];
	[soundData appendBytes: &bigSamplingRate length: sizeof(bigSamplingRate)];
	[soundData appendBytes: &bigChannelCount length: sizeof(bigChannelCount)];
    }

    // append the info string
    // NSLog(@"writing info %@ length %d\n", info, [info length]);
    // TODO we should write unicode data out so foreign language info fields are properly transported. 
    [soundData appendBytes: [info cString] length: [info length]];

    if (df != SND_FORMAT_INDIRECT) { /* simple read/write of block of data */
        [soundData appendBytes: (char *) soundStruct + soundStruct->dataLocation length: soundStruct->dataSize];
	//NSLog(@"writing %u bytes from %u\n", soundStruct->dataSize, soundStruct->dataLocation);
    }
    else {
	int j = 0;

	ssList = (SndSoundStruct **) soundStruct->dataLocation;
	while ((theStruct = ssList[j++]) != NULL) {
	    [soundData appendBytes: (char *) theStruct + theStruct->dataLocation length: theStruct->dataSize];
	}
    }
    return [NSData dataWithData: soundData];
}

- (void) swapHostToBigEndianFormat
{
    void *d = [self data];
    SndSwapHostToBigEndianSound(d, d, [self lengthInSampleFrames], [self channelCount], [self dataFormat]);
}

- (void) swapBigEndianToHostFormat
{
    void *d = [self data];
    SndSwapBigEndianSoundToHost(d, d, [self lengthInSampleFrames], [self channelCount], [self dataFormat]);
}

// TODO Adopt keyed coding. Don't save magic.
- (void) encodeWithCoder: (NSCoder *) aCoder
/* Here I archive data to coder as CHAR rather than exact data
 * type. Why? Well, I don't want it swapping data for me! I always want the
 * internal data representation to be big endian.
 */
{
    SndSoundStruct *s;
    SndSoundStruct **ssList;
    SndSoundStruct *theStruct;
    int headerSize;
    int df;
    int i,j=0;

    [aCoder encodeConditionalObject: delegate];
    [aCoder encodeObject: name];

    df = soundStruct->dataFormat;
    if (df == SND_FORMAT_INDIRECT) headerSize = soundStruct->dataSize;
    else headerSize = soundStruct->dataLocation;
    /* make new header with swapped bytes if nec */
    if (!(s = malloc(headerSize))) [[NSException exceptionWithName: @"Sound Error"
							    reason: @"Can't allocate memory for Snd class"
                                                          userInfo: nil] raise];
    memmove(s, soundStruct, headerSize);
    if (df == SND_FORMAT_INDIRECT) {
        int newCount = 0;
        i = 0;
        s->dataFormat = ((SndSoundStruct *)(*((SndSoundStruct **) (soundStruct->dataLocation))))->dataFormat;
        ssList = (SndSoundStruct **)soundStruct->dataLocation;
        while ((theStruct = ssList[i++]) != NULL)
            newCount += theStruct->dataSize;
        s->dataLocation = s->dataSize;
        s->dataSize = newCount;
    }

    /* no need to swap data in the header, because coders take care
    * of endian issues for us.
    */
    [aCoder encodeValuesOfObjCTypes:"iiiiii", s->magic, s->dataLocation, s->dataSize,
            s->dataFormat, s->samplingRate,s->channelCount];
    [aCoder encodeArrayOfObjCType:"c" count:headerSize - sizeof(SndSoundStruct) + 4 at: [info cString]];

    if (df != SND_FORMAT_INDIRECT) { /* simple read/write of block of data */
        [aCoder encodeArrayOfObjCType:"s"
                                count:soundStruct->dataSize
                                   at:(char *)soundStruct + soundStruct->dataLocation];
        free(s);
    }

    ssList = (SndSoundStruct **)soundStruct->dataLocation;
    free(s);
    while ((theStruct = ssList[j++]) != NULL) {
            [aCoder encodeArrayOfObjCType:"c"
                                    count:theStruct->dataSize
                                       at:(char *)theStruct + theStruct->dataLocation];
    }
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
    SndSoundStruct *s;
    int finalSize;

    delegate = [[aDecoder decodeObject] retain];
    name = [[aDecoder decodeObject] retain];

    if (soundStruct) SndFree(soundStruct);
    if (!(s = malloc(sizeof(SndSoundStruct))))
        [[NSException exceptionWithName:@"Sound Error"
                                 reason:@"Can't allocate memory for Snd class"
                               userInfo:nil] raise];

    [aDecoder decodeValuesOfObjCTypes:"iiiiii", &(s->magic), &(s->dataLocation), &(s->dataSize),
            &(s->dataFormat), &(s->samplingRate), &(s->channelCount)];
    s = realloc((char *)s, s->dataLocation + 1); /* allocate enough room for info string */
    [aDecoder decodeArrayOfObjCType:"c" count:s->dataLocation - sizeof(SndSoundStruct) + 4 at:s->info];

    // NSLog(@"%@\n", SndStructDescription(s));

    finalSize = s->dataSize + s->dataLocation;

    s = realloc((char *)s,finalSize);
    if ((unsigned) s->dataLocation > sizeof(SndSoundStruct)) {
            /* read off the rest of the info string */
        [aDecoder decodeArrayOfObjCType: "c"
                                  count: s->dataLocation - sizeof(SndSoundStruct)
                                     at: (char *)s + sizeof(SndSoundStruct)];
    }
    [aDecoder decodeArrayOfObjCType: "c" count: s->dataSize at: (char *)s + s->dataLocation];

    soundStruct = s;
    return SND_ERR_NONE;
}

- awakeAfterUsingCoder: (NSCoder *) aDecoder
{
    status = SND_SoundInitialized;
    conversionQuality = SndConvertLowQuality;
    return self; /* what to do here??? Doesn't seem to be anything pressing... */
}

- (NSString *) name
{
    return name;
}

- setName: (NSString *) theName
/* this needs to interface with an object-wide name table
 * to identify sounds by name. At the moment multiple sound
 * objects may share the same name, which is not right.
 * Second Thoughts: many sounds MAY share the same name, as
 * they do not have to register with the central name table.
 * The central name table though can only register one sound
 * with any unique name.
 */
{
    if (name) {
        [name release];
        name = nil;
    }
    if (!theName) return self;
    if (![theName length]) return self;
    name = [theName copy];
    return self;
}

- delegate
{
    return delegate;
}

- (void) setDelegate: (id) anObject
{
    delegate = anObject;
}

- (double) samplingRate
{
    if (!soundStruct) return 0;
    return (double)(soundStruct->samplingRate);
    // TODO return soundFormat.samplingRate
}

- (unsigned long) lengthInSampleFrames
{
    if (!soundStruct) return 0;
    return SndFrameCount(soundStruct);
    // TODO return soundFormat.frameCount
}

- (double) duration
{
    double sampleRate = (double) [self samplingRate];
    return (sampleRate == 0) ? 0.0 : (double) [self lengthInSampleFrames] / sampleRate;
}

- (int) channelCount
{
    if (!soundStruct) return 0;
    return soundStruct->channelCount;
    // TODO return soundFormat.channelCount
}

- (NSString *) info
{
    return [[info retain] autorelease];
}

- (void) setInfo: (NSString *) newInfoString
{
    [info release];
    info = [newInfoString copy];
}

- (int) status
{
    // TODO We should compute the status by interogating any performances the
    // Snd instance currently has, rather than storing in a variable.
    return status;
}

- (void) _setStatus: (int) newStatus
    /* for use in the beginFunc and endFunc routines and the SndPlayer */
{
    status = newStatus;
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

    // check its seekable, by checking its POSIX regular.
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

- (int) writeSoundfile: (NSString *) filename
{
    // compaction ideally should not be necessary, but SoX saving requires it for now
    [self compactSamples]; 
    return SndWriteSoundfile(filename, soundStruct);
    //return SndWriteSoundfile([filename fileSystemRepresentation], soundStruct);
}

- (BOOL) isEmpty
{
    if (![self isEditable]) return NO;
    if (!soundStruct) return YES;
    if (![self dataSize]) return YES;
    return NO;
}

- (BOOL) isEditable
{
    int df;
    if (!soundStruct) return YES; /* empty sound can be played! */
    if ((df = soundStruct->dataFormat) == SND_FORMAT_INDIRECT)
        df =  ((SndSoundStruct *)(*((SndSoundStruct **)
                (soundStruct->dataLocation))))->dataFormat;
    switch (df) {
        case SND_FORMAT_MULAW_8:
        case SND_FORMAT_LINEAR_8:
        case SND_FORMAT_LINEAR_16:
        case SND_FORMAT_LINEAR_24:
        case SND_FORMAT_LINEAR_32:
        case SND_FORMAT_FLOAT:
        case SND_FORMAT_DOUBLE:
                return YES;
        default:
                break;
    }
    return NO;
}

- (BOOL) compatibleWithSound: (Snd *) aSound
{
    BOOL formatsOk;
    SndSampleFormat df1 = [self dataFormat];
    SndSampleFormat df2 = [aSound dataFormat];
    
    /* No longer needed since -dataFormat now checks indirect formats.
	if (df1 == SND_FORMAT_INDIRECT)
        df1 = ((SndSoundStruct *) (*((SndSoundStruct **) (soundStruct->dataLocation))))->dataFormat;
    if (df2 == SND_FORMAT_INDIRECT)
        df2 = ((SndSoundStruct *) (*((SndSoundStruct **) ([aSound soundStruct]->dataLocation))))->dataFormat;
    */
    formatsOk = ((df1 == df2) && df1 != SND_FORMAT_INDIRECT);
    
    if (!soundStruct) return YES;
    if (!aSound) return YES;
    if ([self samplingRate] == [aSound samplingRate] &&
	[self channelCount] == [aSound channelCount] &&
	formatsOk)
	return YES;
    return NO;
}

- (int) convertToFormat: (SndSampleFormat) toFormat
	   samplingRate: (double) toRate
	   channelCount: (int) toChannelCount
{
    NSRange wholeSound = { 0, [self lengthInSampleFrames] };
    SndAudioBuffer *bufferToConvert;
    SndAudioBuffer *error;

    if([self dataFormat] == toFormat && [self samplingRate] == toRate && [self channelCount] == toChannelCount)
	return SND_ERR_NONE;

    bufferToConvert = [SndAudioBuffer audioBufferWithSnd: self inRange: wholeSound];

    /* SndConvertLowQuality: fastest conversion, non-interpolated */
    /* SndConvertMediumQuality: medium conversion, small filter, uses interpolation */
    /* SndConvertHighQuality: slow, accurate conversion, large filter, uses interpolation */
    error = [bufferToConvert convertToFormat: toFormat
				channelCount: toChannelCount
                                samplingRate: toRate
                              useLargeFilter: conversionQuality == SndConvertHighQuality
                           interpolateFilter: conversionQuality != SndConvertLowQuality
                      useLinearInterpolation: conversionQuality == SndConvertLowQuality];

    if (error != nil) {
	double stretchFactor = toRate / [self samplingRate];
	SndSoundStruct *toSound;
	int err = SndAlloc(&toSound, [bufferToConvert lengthInBytes], toFormat, toRate, toChannelCount, 4);

	if (err != SND_ERR_NONE)
	    return err;
	
        SndFree(soundStruct);
	// We need to copy the buffer sample data back into the soundStruct. In the future, post-soundStruct,
	// we should just be able to use the buffer directly.
	memcpy((void *) toSound + toSound->dataLocation, [bufferToConvert bytes], [bufferToConvert lengthInBytes]);
	soundStruct = toSound;
        soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
	
	soundFormat.dataFormat = toFormat;
	soundFormat.frameCount = [bufferToConvert lengthInSampleFrames];
	soundFormat.sampleRate = toRate;
	soundFormat.channelCount = toChannelCount;
	loopStartIndex *= stretchFactor;  // adjust the loop pointers if the sound was resampled.
	loopEndIndex *= stretchFactor;
	return SND_ERR_NONE;
    }
    return SND_ERR_UNKNOWN;
}

- (int) convertToFormat: (SndSampleFormat) aFormat
{
    return [self convertToFormat: aFormat
                    samplingRate: soundStruct->samplingRate
                    channelCount: soundStruct->channelCount];
}

+ (SndFormat) nativeFormat
{
    SNDStreamBuffer nativeStreamBufferFormat;

    SNDStreamNativeFormat(&nativeStreamBufferFormat);
    return SndFormatOfSNDStreamBuffer(&nativeStreamBufferFormat);
}

- (int) convertToNativeFormat
{
    SndFormat nativeFormat = [Snd nativeFormat];

    return [self convertToFormat: nativeFormat.dataFormat
                    samplingRate: nativeFormat.sampleRate
                    channelCount: nativeFormat.channelCount];
}

static int SndCopySound(SndSoundStruct **toSound, const SndSoundStruct *fromSound)
{
    SndSoundStruct **ssList=NULL,**newssList=NULL;
    SndSoundStruct *theStruct;
    int i = 0,ssPointer = 0;
    int cc;
    SndSampleFormat df;
    int ds;
    int sr;
    
    if (!fromSound) return SND_ERR_NOT_SOUND;
    if (fromSound->magic != SND_MAGIC) return SND_ERR_NOT_SOUND;
    cc = fromSound->channelCount;
    df = fromSound->dataFormat;
    ds = fromSound->dataSize; /*ie size of header including info string*/
    sr = fromSound->samplingRate;
    
    if (df == SND_FORMAT_INDIRECT) {
	df = ((SndSoundStruct *)(*((SndSoundStruct **)
				   (fromSound->dataLocation))))->dataFormat;
	
	/*Copying fragged sound: */
	/* initial struct -- info and all */
	if (SndAlloc(toSound, 0, df, sr, cc,
		     ds - sizeof(SndSoundStruct) + 4) != SND_ERR_NONE)
	    return SND_ERR_CANNOT_ALLOC;
	
	memmove(&((*toSound)->info),&(fromSound->info),
		ds - sizeof(SndSoundStruct) + 4);
	
	ssList = (SndSoundStruct **)fromSound->dataLocation;
	while ((theStruct = ssList[i++]) != NULL);
	i--;
	/* i is the number of frags */
	newssList = malloc((i+1) * sizeof(SndSoundStruct *));
	if (!newssList) {
	    free (*toSound);
	    return SND_ERR_CANNOT_ALLOC;
	}
	newssList[i] = NULL; /* do the last one now... */
	
	for (ssPointer = 0; ssPointer < i; ssPointer++) {
	    if (!(newssList[ssPointer] = _SndCopyFrag(ssList[ssPointer]))) {
		free (*toSound);
		for (i = 0; i < ssPointer; i++) {
		    free (newssList[i]);
		}
		return SND_ERR_CANNOT_ALLOC;
	    }
	}
	(SndSoundStruct **)((*toSound)->dataLocation) = newssList;
	(*toSound)->dataSize = fromSound->dataSize;
	(*toSound)->dataFormat = SND_FORMAT_INDIRECT;
	return SND_ERR_NONE;
    }
    else {
	/* copy unfragged sound */
	if (SndAlloc(toSound, ds, df, sr, cc, fromSound->dataLocation -
		     sizeof(SndSoundStruct) + 4) != SND_ERR_NONE)
	    return SND_ERR_CANNOT_ALLOC;
	memmove(&((*toSound)->info),&(fromSound->info),
		fromSound->dataLocation - sizeof(SndSoundStruct) + 4);
	memmove((char *)(*toSound)   + (*toSound)->dataLocation,
		(char *)fromSound + fromSound->dataLocation, ds);
    }
    return SND_ERR_NONE;
}

// TODO Perhaps just use soundFromSampleInRange: specifying entire range and passing a NSZone parameter.
- (id) copyWithZone: (NSZone *) zone
{
    int err;
    Snd *newSound = [[[self class] allocWithZone: zone] initWithFormat: [self dataFormat]
							  channelCount: [self channelCount]
								frames: [self lengthInSampleFrames]
							  samplingRate: [self samplingRate]];
    
    
    if (newSound->soundStruct) {
        err = SndFree(newSound->soundStruct);
        newSound->soundStruct = NULL;
        newSound->soundStructSize = 0;
        if (err)
	    return nil;
    }

    err = SndCopySound(&(newSound->soundStruct), soundStruct);
    if (err) {
	return nil;
    }
    if (newSound->soundStruct->dataFormat != SND_FORMAT_INDIRECT)
	newSound->soundStructSize = newSound->soundStruct->dataLocation + newSound->soundStruct->dataSize;
    else
	newSound->soundStructSize = newSound->soundStruct->dataSize;		
    
    // Duplicate all other ivars
    newSound->soundFormat = soundFormat;
    [newSound setInfo: [self info]];
    
    newSound->priority = priority;		 
    [newSound setDelegate: [self delegate]];		 
    [newSound setName: [self name]];
    newSound->conversionQuality = conversionQuality;
        
    newSound->loopWhenPlaying = loopWhenPlaying;
    newSound->loopStartIndex = loopStartIndex;
    newSound->loopEndIndex = loopEndIndex;

    [newSound setAudioProcessorChain: [self audioProcessorChain]];
    
    return newSound; // TODO [newSound autorelease]; ?
}

- (void *) data
{
    if (!soundStruct)
	return NULL;
    if (soundStruct->dataFormat == SND_FORMAT_INDIRECT)
	return (void *) soundStruct->dataLocation;
    return (void *)((char *) soundStruct + soundStruct->dataLocation);
}

- (int) dataSize
/* This looks after fragged sounds ok, as the docs say that for a
 * fragged sound, this should return the length of the main SndSoundStruct
 * (not including data); otherwise, should return num of bytes of data,
 * not including the structure.
 */
{
    // TODO once soundStruct purged.
    //  return soundFormat.frameCount * SndFrameSize(soundFormat);

    if (!soundStruct) return 0;
    return soundStruct->dataSize; 
}

- (SndSampleFormat) dataFormat
{
    int df;
    
    if (!soundStruct)
        return 0;
    if ((df = soundStruct->dataFormat) == SND_FORMAT_INDIRECT)
        return ((SndSoundStruct *)(*((SndSoundStruct **)
                    (soundStruct->dataLocation))))->dataFormat;
    return df;
}

- (BOOL) hasSameFormatAsBuffer: (SndAudioBuffer *) buff
{
    if (buff == nil)
	return FALSE;
    else
	return ([self dataFormat]   == [buff dataFormat]  ) &&
	       ([self channelCount] == [buff channelCount]) &&
	       ([self samplingRate] == [buff samplingRate]);
}

- (SndSoundStruct *) soundStruct
{
#if 0
    // TODO Prepare the soundStruct from the soundFormat once soundFormat is the authorative source.
    soundStruct->dataFormat = soundFormat.dataFormat;
    soundStruct->channelCount = soundFormat.channelCount;
    soundStruct->samplingRate = soundFormat.samplingRate;
    etc
#endif
    
    return soundStruct;
}

/* returns the base address of the block the sample resides in,
 * with appropriate indices for the last sample the block holds.
 * Indices count from 0 so they can be utilised directly.
 */
- (void *) fragmentOfFrame: (int) frame 
	   indexInFragment: (unsigned int *) currentFrame 
	    fragmentLength: (unsigned int *) fragmentLength
		dataFormat: (SndSampleFormat *) dataFormat
{            
    *dataFormat = [self dataFormat];
    if (soundStruct->dataFormat != SND_FORMAT_INDIRECT) {
	*fragmentLength = [self lengthInSampleFrames];
	*currentFrame = frame < *fragmentLength ? frame : *fragmentLength - 1;
	return [self data];
    }
    else {
	int frameSize = SndFrameSize(soundFormat);
	SndSoundStruct **ssList;
	SndSoundStruct *theStruct;
	int i = 0, count = 0, oldCount = 0;

	ssList = (SndSoundStruct **)([self soundStruct]->dataLocation);
	while ((theStruct = ssList[i++]) != NULL) {
	    int numberOfFramesInFragment = (theStruct->dataSize) / frameSize;
	    
	    count += numberOfFramesInFragment;
	    if (count > frame) {
		*fragmentLength = numberOfFramesInFragment;
		*currentFrame = frame - oldCount;
		return (char *) theStruct + theStruct->dataLocation;
	    }
	    oldCount = count;
	}
	*currentFrame = 0;
	*fragmentLength = 0;
	return NULL;	
    }
}

// retrieve a sound value at the given frame, for a specified channel, or average over all channels.
// channelNumber is 0 - channelCount to retrieve a single channel, channelCount to average all channels
- (float) sampleAtFrameIndex: (unsigned long) frameIndex channel: (int) channelNumber
{
#if 0
    SndAudioBuffer *singleFrameBuffer = [self audioBuffer frameRange: NSMakeRange(frameIndex, 1) ];
    return [singleFrameBuffer sampleAtFrameIndex: frameIndex channel: channelNumber];
#else
    float theValue = 0.0;
    int channelCount = [self channelCount]; // TODO can eventually replace channelCount with soundFormat.channelCount
    int averageOverChannels;
    int startingChannel;
    unsigned long sampleIndex;
    unsigned long sampleNumber;
    void *pcmData;
    int fragmentIndex;
    int fragmentLength;
    SndSampleFormat dataFormat;
    
    if (channelNumber == channelCount) {
	averageOverChannels = channelCount;
	startingChannel = 0;
    }
    else {
	averageOverChannels = 1;
	startingChannel = channelNumber;
    }
    // 
    pcmData = [self fragmentOfFrame: frameIndex 
		    indexInFragment: &fragmentIndex 
		     fragmentLength: &fragmentLength
			 dataFormat: &dataFormat];
    sampleNumber = fragmentIndex * channelCount + startingChannel;
    
    for(sampleIndex = sampleNumber; sampleIndex < sampleNumber + averageOverChannels; sampleIndex++) {
	// TODO move this into a SndAudioBuffer method.
	switch (dataFormat) {
	    case SND_FORMAT_LINEAR_8:
		theValue += ((char *) pcmData)[sampleIndex];
		break;
	    case SND_FORMAT_MULAW_8:
		theValue += SndMuLawToLinear(((char *) pcmData)[sampleIndex]);
		break;
	    case SND_FORMAT_EMPHASIZED:
	    case SND_FORMAT_COMPRESSED:
	    case SND_FORMAT_COMPRESSED_EMPHASIZED:
	    case SND_FORMAT_DSP_DATA_16:
	    case SND_FORMAT_LINEAR_16:
		theValue += ((short *) pcmData)[sampleIndex];
		break;
	    case SND_FORMAT_LINEAR_24:
	    case SND_FORMAT_DSP_DATA_24:
		// theValue = ((short *) pcmData)[frameIndex];
		theValue += *((int *) ((char *) pcmData + sampleIndex * 3)) >> 8;
		break;
	    case SND_FORMAT_LINEAR_32:
	    case SND_FORMAT_DSP_DATA_32:
		theValue += ((int *) pcmData)[sampleIndex];
		break;
	    case SND_FORMAT_FLOAT:
		theValue += ((float *) pcmData)[sampleIndex];
		break;
	    case SND_FORMAT_DOUBLE:
		theValue += ((double *) pcmData)[sampleIndex];
		break;
	    default: /* just in case */
		theValue += ((short *) pcmData)[sampleIndex];
		NSLog(@"SndView sampleAtFrameIndex: unhandled format %d\n", dataFormat);
		break;
	}	
    }
    return (averageOverChannels > 1) ? theValue / averageOverChannels : theValue;
#endif
}

- (int) processingError
{
    return currentError;
}

/* default implementation. Provided for subclassing */
- soundBeingProcessed
{
    return self;
}

// delegations which are not nominated per performance.
- (void) tellDelegate: (SEL) theMessage
{
    if (delegate) {
        if ([delegate respondsToSelector:theMessage]) {
            [delegate performSelector:theMessage withObject:self];
        }
    }
}

// delegations which are nominated per performance.
- (void) tellDelegate: (SEL) theMessage duringPerformance: (SndPerformance *) performance
{
    if (delegate) {
        if ([delegate respondsToSelector:theMessage]) {
            [delegate performSelector:theMessage withObject: self withObject: performance];
        }
    }
}

// Convenience function for when using NSInvocations to send messages. NSInvocations don't like
// dealing with SEL types, so we use a NSString on the other end, and convert to SEL here.
- (void) tellDelegateString: (NSString *) theMessage duringPerformance: (SndPerformance *) performance
{
    [self tellDelegate: NSSelectorFromString(theMessage) duringPerformance: performance];
}

- (void) setConversionQuality: (SndConversionQuality) quality
{
    conversionQuality = quality;
}

- (SndConversionQuality) conversionQuality
{
    return conversionQuality;
}

- (void) normalise
{
    // Retrieve the Snd as an SndAudioBuffer (TODO eventually this will be redundant once a SndAudioBuffer is an ivar).
    NSRange wholeSound = { 0, [self lengthInSampleFrames] };
    SndAudioBuffer *audioBufferOfEntireSound = [SndAudioBuffer audioBufferWithSnd: self inRange: wholeSound];
    
    [audioBufferOfEntireSound normalise];

    // We need to copy the buffer sample data back into the soundStruct. In the future, post-soundStruct,
    // we should just be able to use the buffer directly.
    {
	SndSoundStruct *toSound;
	int err = SndAlloc(&toSound, [audioBufferOfEntireSound lengthInBytes], [self dataFormat], [self samplingRate], [self channelCount], 4);
	
	if (err != SND_ERR_NONE)
	    return;
	
	SndFree(soundStruct);
	memcpy((void *) toSound + toSound->dataLocation, [audioBufferOfEntireSound bytes], [audioBufferOfEntireSound lengthInBytes]);
	soundStruct = toSound;
	soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;	
    }
}

- (double) maximumAmplitude
{
    return SndMaximumAmplitude([self dataFormat]);
}

@end
