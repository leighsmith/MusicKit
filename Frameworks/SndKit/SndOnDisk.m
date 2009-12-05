////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    This class is to be regarded as HIGHLY EXPERIMENTAL.
//    Don't use it for general Snd use!!!
//
//    Current experimental activity - stream from disk behaviour.
//    Should be safe to use for playback ONLY!!
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

#import "SndOnDisk.h"
#import "SndAudioBuffer.h"
#import "SndError.h"
#import "SndFunctions.h"

#define SERVER_DEBUG 0

#define HAS_DATA 1
#define HAS_NO_DATA  2

@implementation SndOnDisk

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    self = [super init];
    if (self) {
	bImageInMemory  = FALSE;
	cachedBuffer    = [SndAudioBuffer new];
	cacheLock       = [NSLock new];
	readAheadLock   = [[NSConditionLock alloc] initWithCondition: HAS_NO_DATA];
	readAheadBuffer = nil;
    }
    return self;
}

- (void) dealloc
{
    [cachedBuffer release];
    cachedBuffer = nil;
    [cacheLock release];
    cacheLock = nil;
    [readAheadBuffer release];
    readAheadBuffer = nil;
    [readAheadLock release];
    readAheadLock = nil;
    [super dealloc];
}

- (unsigned char*) data
{
    NSLog(@"SndOnDisk:Don't even *think* of using the data method in experimental Snd objects!");
    return NULL;
}

- (int) dataSize
{
    return 0;
}

////////////////////////////////////////////////////////////////////////////////
// readSoundfile:startFrame:frameCount:
////////////////////////////////////////////////////////////////////////////////

- (int) readSoundfile: (NSString *) filename startFrame: (int) startFrame frameCount: (int) frameCount
{
    int err = SND_ERR_NONE;
    NSDictionary *fileAttributeDictionary;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (name) {
	[name release];
	name = nil;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath: filename]) {
    //      NSLog(@"Snd -readSoundfile:startFrame:frameCount: sound file %@ doesn't exist",filename);
	return SND_ERR_CANNOT_OPEN;
    }
    
    // check its seekable, by checking it is a POSIX regular file.
#if !defined(MAC_OS_X_VERSION_10_5) || (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5)
    fileAttributeDictionary = [fileManager fileAttributesAtPath: filename traverseLink: YES];
#else
    fileAttributeDictionary = [fileManager attributesOfItemAtPath: filename error: NULL];
#endif
    if([fileAttributeDictionary objectForKey: NSFileType] != NSFileTypeRegular)
	return SND_ERR_CANNOT_OPEN;
    
    if (bImageInMemory) {
	err = [super readSoundfile: filename startFrame: startFrame frameCount: frameCount];
    }
    else {
	if (theFileName)
	    [theFileName release];
	theFileName = [filename copy];
	soundFormat = [self soundFormatOfFilename: filename];	
	//    NSLog([self description]);
    }
    return err;
}

////////////////////////////////////////////////////////////////////////////////
// readSoundfile:
////////////////////////////////////////////////////////////////////////////////

- (int) readSoundfile: (NSString*) filename
{
    if (theFileName)
	[theFileName release];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath: filename]) {
	// NSLog(@"Snd::readSoundfile: sound file %@ doesn't exist",filename);
	return SND_ERR_CANNOT_OPEN;
    }
    theFileName = [filename copy];
    bImageInMemory = FALSE;
    soundFormat = [self soundFormatOfFilename: theFileName];
        
    // NSLog([self description]);
    return SND_ERR_NONE;
}

BOOL subRangeIsInsideSuperRange(NSRange subR, NSRange superR)
{
    return (subR.location >= superR.location &&
	    subR.location + subR.length <= superR.location + superR.length);
}

////////////////////////////////////////////////////////////////////////////////
// fillAudioBuffer:toLength:samplesInRange:
////////////////////////////////////////////////////////////////////////////////

- (long) fillAudioBuffer: (SndAudioBuffer *) anAudioBuffer
		toLength: (long) fillLength
          samplesInRange: (NSRange) sndReadingRange;
{
    // TODO this is a kludge which assumes the region read from and copied to is the same number
    // of samples which isn't strictly true if there is resampling occuring.
    // Anyway, this all should be replaced with insertIntoAudioBuffer:inFrameRange:samplesStartingFrom:
    NSRange playRegion = { sndReadingRange.location, fillLength };
    
    [cacheLock lock];
    
    if (bImageInMemory) {
	[super fillAudioBuffer: anAudioBuffer
		      toLength: fillLength
	        samplesInRange: sndReadingRange];
    }
    else {
	unsigned long lengthInSampleFrames = [self lengthInSampleFrames];
	int readLength = (4096*16);
	int bufferMultiplier = ((playRegion.length + 4095)/4096);
	int bufferSize;
	bufferMultiplier = bufferMultiplier == 0 ? 1 : bufferMultiplier;
	bufferSize = readLength * bufferMultiplier;
	
	if (cachedBufferRange.location >= playRegion.location ||
	    readAheadRange.location + readAheadRange.length <= playRegion.location + playRegion.length) {
	    [readAheadLock lock];
      // damn, our play region is outside our cache zone. Throw ze buffers away!
#if SERVER_DEBUG
	    NSLog(@"Jettisoning Buffer with location: %i play region %i", cachedBufferRange.location, playRegion.location);
#endif
	    if (cachedBuffer != nil)
		[cachedBuffer release];
	    cachedBuffer = nil;
	    if (readAheadBuffer != nil)
		[readAheadBuffer release];
	    readAheadBuffer = nil;
	    readAheadRange.location = 0;
	    cachedBufferRange.location = 0;
	    [readAheadLock unlock];
	}
	
	if (cachedBuffer == nil) {
	    unsigned long newLocation = 0;
	    [readAheadLock lock];
	    cachedBufferRange.location = (playRegion.location / 4096) * 4096;
	    cachedBufferRange.length   = bufferSize;
	    
	    cachedBuffer = [[SndOnDiskAudioBufferServer readRange: cachedBufferRange
						    ofSoundFile: theFileName] retain];
	    if (readAheadBuffer != nil)
		[readAheadBuffer release];
	    readAheadBuffer = nil;
	    
	    newLocation = cachedBufferRange.location + bufferSize - playRegion.length * 4;
	    
	    if (newLocation < lengthInSampleFrames) {
		readAheadRange.location = newLocation;
		readAheadRange.length   = bufferSize;
		if (readAheadRange.location + readAheadRange.length > lengthInSampleFrames)
		    readAheadRange.length = lengthInSampleFrames - readAheadRange.location;
		[self requestNextBufferWithRange: readAheadRange];
#if SERVER_DEBUG
		NSLog(@"Requesting (1) Buffer with range: [%i, %i] sndlength: %i",readAheadRange.location, readAheadRange.length,lengthInSampleFrames);
#endif
	    }
	    [readAheadLock unlock];
	}
	
	if (readAheadBuffer != nil &&
	    subRangeIsInsideSuperRange (playRegion, readAheadRange) &&
	    playRegion.location + playRegion.length < lengthInSampleFrames) {
	    // we have moved into the readAheadCache - swap the buffers and request the next...
	    unsigned long newLocation = 0;
	    
	    [readAheadLock lock];
	    if (cachedBuffer != nil)
		[cachedBuffer release];
	    cachedBuffer = readAheadBuffer;
	    cachedBufferRange = readAheadRange;
	    readAheadBuffer = nil;
	    
	    newLocation = cachedBufferRange.location + bufferSize - playRegion.length * 4;
	    if (newLocation < lengthInSampleFrames) {
		readAheadRange.location = newLocation;
		readAheadRange.length   = bufferSize;
		if (readAheadRange.location + readAheadRange.length > lengthInSampleFrames)
		    readAheadRange.length = lengthInSampleFrames - readAheadRange.location;
		
		[self requestNextBufferWithRange: readAheadRange];
#if SERVER_DEBUG
		NSLog(@"Requesting (2) Buffer with range: [%i, %i] sndLength: %i",readAheadRange.location, readAheadRange.length,lengthInSampleFrames);
		NSLog(@"Swapped in Buffer with range: [%i, %i]",cachedBufferRange.location, cachedBufferRange.length);
#endif
	    }
	    [readAheadLock unlockWithCondition: HAS_NO_DATA];
	}
	
	if (cachedBuffer != nil) {
	    if (subRangeIsInsideSuperRange (playRegion, cachedBufferRange)) {
        // woohoo! we are inside the cache...
		NSRange relativeRange = playRegion;
#if SERVER_DEBUG
		NSLog(@"Processing %@", [self filename]);
		NSLog(@"Inside the cache (3) relativeRange: [%i, %i] playRegion: [%i, %i]", relativeRange.location, relativeRange.length,
		      playRegion.location, playRegion.length);
		NSLog(@"cachedBufferRange: [%i, %i]",cachedBufferRange.location, cachedBufferRange.length);
#endif
		relativeRange.location = playRegion.location - cachedBufferRange.location;
		if (relativeRange.location + relativeRange.length > cachedBufferRange.length )
		    relativeRange.length = cachedBufferRange.length - relativeRange.location;
		[anAudioBuffer initWithBuffer: cachedBuffer range: relativeRange];
		if ([anAudioBuffer lengthInSampleFrames] < playRegion.length)
		    [anAudioBuffer setLengthInSampleFrames: playRegion.length];
	    }
	    else {
#if SERVER_DEBUG
		NSLog(@"SndOnDisk::fillAudioBuffer - weird case - doing direct read");
#endif
		[anAudioBuffer initWithBuffer: [SndOnDiskAudioBufferServer readRange: playRegion
								       ofSoundFile: theFileName]];
	    }
	}
    }
    [cacheLock unlock];
    return playRegion.length;
}

////////////////////////////////////////////////////////////////////////////////
// audioBufferForSamplesInRange:
////////////////////////////////////////////////////////////////////////////////

- (SndAudioBuffer*) audioBufferForSamplesInRange: (NSRange) playRegion
{
    SndAudioBuffer *ab = [SndAudioBuffer new];
    [self fillAudioBuffer: ab toLength: playRegion.length samplesInRange: playRegion];
    return [ab autorelease];
}

- (NSString*) filename
{
    return [[theFileName retain] autorelease];
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- requestNextBufferWithRange: (NSRange) range
{
    SndOnDiskAudioBufferServerJob *aJob;
    aJob = [SndOnDiskAudioBufferServerJob alloc];
    [aJob initWithSndOnDisk: self bufferRange: range];
    [[SndOnDiskAudioBufferServer defaultServer] addJob: aJob];
    return self;
}

- receiveRequestedBuffer: (SndAudioBuffer*) aBuffer
{
    [readAheadLock lock];
    if (readAheadBuffer != nil)
	[readAheadBuffer release];
    readAheadBuffer = [aBuffer retain];
    [readAheadLock unlockWithCondition: HAS_DATA];
#if SERVER_DEBUG              
    NSLog(@"Received Buffer with range: [%i, %i]",readAheadRange.location, readAheadRange.length);
#endif      
    return self;
}

@end

////////////////////////////////////////////////////////////////////////////////
// SndOnDiskAudioBufferServer
////////////////////////////////////////////////////////////////////////////////

#define SERVER_NO_JOBS  0
#define SERVER_HAS_JOBS 1

static SndOnDiskAudioBufferServer *defaultServer = nil;

@implementation SndOnDiskAudioBufferServer

+ (void) initialize
{
    defaultServer = [SndOnDiskAudioBufferServer new];
}

+ defaultServer
{
    return defaultServer;
}

+ (SndAudioBuffer *) readRange: (NSRange) range ofSoundFile: (NSString*) theFileName
{
    Snd *soundChunk = [[Snd alloc] init];
    int err = [soundChunk readSoundfile: theFileName 
							 startFrame: range.location
			                 frameCount: range.length];
    
    if (err == SND_ERR_NONE) {
		NSRange wholeSound = { 0, range.length };
		SndAudioBuffer *aBuffer = [SndAudioBuffer audioBufferWithSnd: soundChunk inRange: wholeSound];

		[aBuffer convertToSampleFormat: SND_FORMAT_FLOAT];
		return aBuffer;
    }
    else
		return nil;
}

- init
{
    self = [super init];
    if (self) {
		bGo = TRUE;
		pendingJobsArrayLock = [NSConditionLock new];
		pendingJobsArray     = [NSMutableArray  new];
		[NSThread detachNewThreadSelector: @selector(serverThread)
					             toTarget: self
					           withObject: nil];
    }
    return self;
}

- (void) dealloc
{
	[pendingJobsArrayLock release];
	pendingJobsArrayLock = nil;
	[pendingJobsArray release];
	pendingJobsArray = nil;
	[super dealloc];
}

- addJob: (SndOnDiskAudioBufferServerJob *) aJob
{
    [pendingJobsArrayLock lock];
    [pendingJobsArray addObject: aJob];
    [pendingJobsArrayLock unlockWithCondition: SERVER_HAS_JOBS];
#if SERVER_DEBUG              
    NSLog(@"Added job for %@", [[aJob snd] filename]);
#endif  
    return self;
}

- (void) doJob: (SndOnDiskAudioBufferServerJob *) aJob
{
    SndOnDisk *snd = [aJob snd];
    NSRange r = [aJob range];
    unsigned long requestedLength = r.length;
    unsigned long lengthInSampleFrames = [snd lengthInSampleFrames];
    SndAudioBuffer *aBuffer = nil;
    
    if (r.location + r.length > [snd lengthInSampleFrames])
		r.length = lengthInSampleFrames - r.location;
    
    aBuffer = [SndOnDiskAudioBufferServer readRange: [aJob range]
									  ofSoundFile: [snd filename]];
    
    if ([aBuffer lengthInSampleFrames] < requestedLength)
		[aBuffer setLengthInSampleFrames: requestedLength];
    
    [snd receiveRequestedBuffer: aBuffer];
    [aJob release];
#if SERVER_DEBUG              
    NSLog(@"Completed job for %@", [[aJob snd] filename]);
#endif  
}

- (void) serverThread
{
    while (bGo) {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSDate *date = [NSDate dateWithTimeIntervalSinceNow: 1.0];
	
	if (![pendingJobsArrayLock lockWhenCondition: SERVER_HAS_JOBS beforeDate: date])
	    continue;
	
	if ([pendingJobsArray count] == 0)
	    continue;
	
	activeJob = [[pendingJobsArray objectAtIndex: 0] retain];
	[pendingJobsArray removeObject: activeJob];
	
	if ([pendingJobsArray count] > 0)
	    [pendingJobsArrayLock unlockWithCondition: SERVER_HAS_JOBS];
	else
	    [pendingJobsArrayLock unlockWithCondition: SERVER_NO_JOBS];
	
	if (activeJob != nil)
	    [self doJob: activeJob];
	[pool release];
    }
    [NSThread exit];
}

@end

////////////////////////////////////////////////////////////////////////////////
// SndOnDiskAudioBufferServerJob
////////////////////////////////////////////////////////////////////////////////

@implementation SndOnDiskAudioBufferServerJob 

- initWithSndOnDisk: (SndOnDisk*) sndExpt bufferRange: (NSRange) range
{
    self = [super init];
    if (self) {
	clientSndOnDisk    = [sndExpt retain];
	audioBufferRange = range;
	audioBuffer      = nil;
    }
    return self;
}

- (void) dealloc
{
    if (clientSndOnDisk)
	[clientSndOnDisk release];
    if (audioBuffer)
	[audioBuffer release];
    [super dealloc];
}

- (SndOnDisk *) snd            { return [[clientSndOnDisk retain] autorelease]; }
- (NSRange) range           { return audioBufferRange; }
- (SndAudioBuffer *) buffer  { return [[audioBuffer retain] autorelease]; }

@end

////////////////////////////////////////////////////////////////////////////////
