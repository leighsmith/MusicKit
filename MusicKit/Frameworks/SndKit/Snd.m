#ifdef WIN32
#include <Winsock.h>
#else
#include <libc.h>
#endif

#include <stdlib.h>
#include <stdio.h>
#include <string.h> /* for memmove() */
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSApplication.h>
#import <objc/HashTable.h>

#import "Snd.h"

#ifndef USE_NEXTSTEP_SOUND_IO
NSString *NXSoundPboardType = @"NXSoundPboardType";
#endif

/* HISTORY
 * 20/6/99 sb: added check to -compactSamples to ensure sound needs it
 */

@implementation Snd

static NSMutableDictionary* nameTable = nil;
static HashTable* playRecTable = nil;
static ioTags = 1000;

void merror(int er)
{
	NSLog(@"mem error %i\n",er);
	return;
}

+ (void)initialize
{
#if defined(WIN32) && defined(USE_PERFORM_SOUND_IO)
    char **driverNames;
#endif
//	printf("Snd class initialize\n");
//	malloc_error(&merror);
    if ( self == [Snd class] ) {
        nameTable = [[NSMutableDictionary alloc] initWithCapacity:10];
#if defined(WIN32) && defined(USE_PERFORM_SOUND_IO)
        SNDInit(TRUE);
        driverNames = SNDGetAvailableDriverNames();
        printf("driver selected is %s\n", driverNames[SNDGetAssignedDriverIndex()]);
#endif
    }
    return;
}

+ soundNamed:(NSString *)aName
/* Does not name sound, or add to name table.
 */
{
	BOOL found;
	id newSound;
	NSBundle *soundLocation;
	NSString *path;
        id retSnd = [nameTable objectForKey:aName];
	if (retSnd) return retSnd;

        found = ((path = [[NSBundle mainBundle] pathForResource:aName ofType:@"snd"]) != nil);
	if (found) {
		newSound = [[Snd alloc] initFromSoundfile:path];
		if (newSound) {
			return newSound;
		}
	}
        path = [NSHomeDirectory() stringByAppendingPathComponent:path];
	soundLocation = [[NSBundle alloc] initWithPath:path];
	if (soundLocation) {

            found = ((path = [soundLocation pathForResource:aName ofType:@"snd"]) != nil);
		[soundLocation release];
		if (found) {
			newSound = [[Snd alloc] initFromSoundfile:path];
			if (newSound) {
				return newSound;
			}
		}
	}
	soundLocation = [[NSBundle alloc] initWithPath:@"/LocalLibrary/Sounds"];
	if (soundLocation) {

            found = ((path = [soundLocation pathForResource:aName ofType:@"snd"]) != nil);
		[soundLocation release];
		if (found) {
			newSound = [[Snd alloc] initFromSoundfile:path];
			if (newSound) {
				return newSound;
			}
		}
	}
	soundLocation = [[NSBundle alloc] initWithPath:@"/NextLibrary/Sounds"];
	if (soundLocation) {

            found = ((path = [soundLocation pathForResource:aName ofType:@"snd"]) != nil);
		[soundLocation release];
		if (found) {
                    newSound = [[Snd alloc] initFromSoundfile:path];
			if (newSound) {
				return newSound;
			}
		}
	}
	return nil;
}

+ addName:(NSString *)aname sound:aSnd
{
    if ([nameTable objectForKey:aname]) return nil; /* already exists */
    if (!aSnd) return nil;
    [(Snd *)aSnd setName:aname];
    [nameTable setObject:aSnd forKey:aname];
    return aSnd;
}

+ addName:(NSString *)aname fromSoundfile:(NSString *)filename
{
    Snd *newSnd;
    if ([nameTable objectForKey:aname]) return nil; /* already exists */
    newSnd = [[Snd alloc] initFromSoundfile:filename];
    if (!newSnd) return nil;
    [Snd addName:aname sound:newSnd];
    return newSnd;
}

+ addName:(NSString *)aname fromSection:(NSString *)sectionName
{
    printf("Snd: +addName:fromSection: not implemented\n");
    return self;
}

+ addName:(NSString *)aName fromBundle:(NSBundle *)aBundle
{
	BOOL found;
	Snd *newSound;
	NSString *path;
	if (!aBundle) return nil;
	if (!aName) return nil;
        if (![aName length]) return nil;
        if ([nameTable objectForKey:aName]) return nil; /* already exists */
        found = ((path = [aBundle pathForResource:aName ofType:@"snd"]) != nil);
	if (found) {
		newSound = [[Snd alloc] initFromSoundfile:path];
		if (newSound) {
			[Snd addName:aName sound:newSound];
			return newSound;
		}
	}
	return nil;
}

+ (void)removeSoundForName:(NSString *)aname
{
    [nameTable removeObjectForKey:aname];
}

+ getVolume:(float *)left :(float *)right
{
#ifdef USE_NEXTSTEP_SOUND_IO
	return [Sound getVolume:(float *)left :(float *)right];
#else
	*left = 0.0;
	*right = 0.0;
	return [self class];
#endif
}

+ setVolume:(float)left :(float)right
{
#ifdef USE_NEXTSTEP_SOUND_IO
	return [Sound setVolume:(float)left :(float)right];
#else
	return [self class];
#endif
}

+ (BOOL)isMuted
{
#ifdef USE_NEXTSTEP_SOUND_IO
	return [Sound isMuted];
#elif defined(USE_PERFORM_SOUND_IO) && defined(WIN32)
        return SNDIsMuted();
#else
	return NO;
#endif
}

+ setMute:(BOOL)aFlag
{
#ifdef USE_NEXTSTEP_SOUND_IO
	return [Sound setMute:(BOOL)aFlag];
#elif defined(USE_PERFORM_SOUND_IO) && defined(WIN32)
	SNDSetMute(aFlag);
	return self;
#else
	return self;
#endif
}

- init
{
	name = NULL;
	delegate = nil;
	status = NX_SoundInitialized;
	soundStruct = NULL;
	soundStructSize = 0;
	currentError = 0;
	_scratchSnd = NULL;
	_scratchSize = 0;
	tag = 0;
#if 0 // disabled as this should be done in initialize
	SNDInit(TRUE);
#endif
	return [super init];
}

- initFromSoundfile:(NSString *)filename
{
	[self init];
	if ([self readSoundfile:filename]) {
		[self release];
		return nil;
	}
	return self;
}

- initFromSection:(NSString *)sectionName
{
    printf("Snd: -initFromSection:(NSString *)sectionName  obselete\n");
    return nil;
}

- (void)dealloc
{
	if (name) {
            if ([nameTable objectForKey:name] == self)
			[Snd removeSoundForName:name];
		[name release];
	}
	if (soundStruct) SndFree(soundStruct);
	if (_scratchSnd) SndFree(_scratchSnd);
	[super dealloc];
}

- readSoundFromStream:(NSData *)stream
{
	SndSoundStruct *s;
	int finalSize;

        [name release];
        priority = 0;
//	name = calloc(256,1);
//	NXScanf(stream,"%s",name);
//	NXGetc(stream); /* read off the \n character */
//	name = realloc(name,strlen(name) + 1);
//	NXRead(stream,&priority,sizeof(int));
//	priority = (int)ntohl(priority);
	
	if (soundStruct) SndFree(soundStruct);
        if (!(s = malloc(sizeof(SndSoundStruct)))) [[NSException exceptionWithName:@"Sound Error"
                                                                            reason:@"Can't allocate memory for Snd class"
                                                                          userInfo:nil] raise];
//	NXRead(stream,s,sizeof(SndSoundStruct)); /* gets 1st 4 bytes info string */
        [stream getBytes:s length:sizeof(SndSoundStruct)];/* only gets 1st 4 bytes of info string */
#ifdef __LITTLE_ENDIAN__
	s->magic = ntohl(s->magic);
	s->dataLocation = ntohl(s->dataLocation);
	s->dataSize = ntohl(s->dataSize);
	s->dataFormat = ntohl(s->dataFormat);
	s->samplingRate = ntohl(s->samplingRate);
	s->channelCount = ntohl(s->channelCount);
#endif

	printf("read sound Location:%d size:%d format:%d sr:%d cc:%d info:%s\n",
		s->dataLocation, s->dataSize, s->dataFormat,
		s->samplingRate, s->channelCount, s->info);
	finalSize = s->dataSize + s->dataLocation;
	
	s = realloc((char *)s,finalSize);
        [stream getBytes:(char *)s + sizeof(SndSoundStruct)
                   range:NSMakeRange(sizeof(SndSoundStruct),finalSize - sizeof(SndSoundStruct))];
//	if (s->dataLocation > sizeof(SndSoundStruct)) {
//		/* read off the rest of the info string */
//		NXRead(stream,(char *)s + sizeof(SndSoundStruct),
//			s->dataLocation - sizeof(SndSoundStruct));
//	}
//	NXRead(stream, (char *)s + s->dataLocation, s->dataSize);

	soundStruct = s;
	status = NX_SoundInitialized;
	return SND_ERR_NONE;
}

- writeSoundToStream:(NSMutableData *)stream
{
	SndSoundStruct *s;
	SndSoundStruct **ssList;
	SndSoundStruct *theStruct;
	int headerSize;
	int df;
	int i,j=0;
//	int newPriority = (int)htonl(priority);

//	NXPrintf(stream, "%s\n",name);
//	NXWrite(stream,&newPriority,sizeof(int));

	df = soundStruct->dataFormat;
	if (df == SND_FORMAT_INDIRECT) headerSize = soundStruct->dataSize;
	else headerSize = soundStruct->dataLocation;
	/* make new header with swapped bytes if nec */
	if (!(s = malloc(headerSize))) [[NSException exceptionWithName:@"Sound Error"
                                                         reason:@"Can't allocate memory for Snd class"
                                                       userInfo:nil] raise];
	memmove(s, soundStruct,headerSize);
	if (df == SND_FORMAT_INDIRECT) {
		int newCount = 0;
		i = 0;
		s->dataFormat = ((SndSoundStruct *)(*((SndSoundStruct **)
				(soundStruct->dataLocation))))->dataFormat;
		ssList = (SndSoundStruct **)soundStruct->dataLocation;
		while ((theStruct = ssList[i++]) != NULL)
			newCount += theStruct->dataSize;
		s->dataLocation = s->dataSize;
		s->dataSize = newCount;
	}

#ifdef __LITTLE_ENDIAN__
	s->magic = htonl(s->magic);
	s->dataLocation = htonl(s->dataLocation);
	s->dataSize = htonl(s->dataSize);
	s->dataFormat = htonl(s->dataFormat);
	s->samplingRate = htonl(s->samplingRate);
	s->channelCount = htonl(s->channelCount);
#endif

// 	NXWrite(stream, s, headerSize);
        [stream appendBytes:s length:headerSize];
	if (df != SND_FORMAT_INDIRECT) { /* simple read/write of block of data */
//		NXWrite(stream, (char *)soundStruct + soundStruct->dataLocation,
//			soundStruct->dataSize );
            [stream appendBytes:(char *)soundStruct + soundStruct->dataLocation length:soundStruct->dataSize];
		free(s);
		return SND_ERR_NONE;
	}

	ssList = (SndSoundStruct **)soundStruct->dataLocation;
	free(s);
	while ((theStruct = ssList[j++]) != NULL) {
//		NXWrite(stream, (char *)theStruct + theStruct->dataLocation,
//			theStruct->dataSize);
            [stream appendBytes:(char *)theStruct + theStruct->dataLocation length:theStruct->dataSize];
	}
	return SND_ERR_NONE;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
/* Here I archive data to typed stream as CHAR rather than exact data
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

	[aCoder encodeConditionalObject:delegate];
	[aCoder encodeValueOfObjCType:"*" at:name];

	df = soundStruct->dataFormat;
	if (df == SND_FORMAT_INDIRECT) headerSize = soundStruct->dataSize;
	else headerSize = soundStruct->dataLocation;
	/* make new header with swapped bytes if nec */
	if (!(s = malloc(headerSize))) [[NSException exceptionWithName:@"Sound Error"
                                                         reason:@"Can't allocate memory for Snd class"
                                                       userInfo:nil] raise];
	memmove(s, soundStruct,headerSize);
	if (df == SND_FORMAT_INDIRECT) {
		int newCount = 0;
		i = 0;
		s->dataFormat = ((SndSoundStruct *)(*((SndSoundStruct **)
				(soundStruct->dataLocation))))->dataFormat;
		ssList = (SndSoundStruct **)soundStruct->dataLocation;
		while ((theStruct = ssList[i++]) != NULL)
			newCount += theStruct->dataSize;
		s->dataLocation = s->dataSize;
		s->dataSize = newCount;
	}

/* no need to swap data in the header, because NXTypedStreams take care
 * of endian issues for us.
 */
 	[aCoder encodeValuesOfObjCTypes:"iiiiii", s->magic, s->dataLocation, s->dataSize,
		s->dataFormat, s->samplingRate,s->channelCount];
	[aCoder encodeArrayOfObjCType:"c" count:headerSize - sizeof(SndSoundStruct) + 4 at:s->info];

	if (df != SND_FORMAT_INDIRECT) { /* simple read/write of block of data */
		[aCoder encodeArrayOfObjCType:"s" count:soundStruct->dataSize at:(char *)soundStruct + soundStruct->dataLocation];
		free(s);
	}

	ssList = (SndSoundStruct **)soundStruct->dataLocation;
	free(s);
	while ((theStruct = ssList[j++]) != NULL) {
		[aCoder encodeArrayOfObjCType:"c" count:theStruct->dataSize at:(char *)theStruct + theStruct->dataLocation];
	}
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	SndSoundStruct *s;
	int finalSize;

	delegate = [[aDecoder decodeObject] retain];
	[aDecoder decodeValueOfObjCType:"*" at:&name];
	
	if (soundStruct) SndFree(soundStruct);
	if (!(s = malloc(sizeof(SndSoundStruct)))) [[NSException exceptionWithName:@"Sound Error"
                                                                     reason:@"Can't allocate memory for Snd class"
                                                                   userInfo:nil] raise];

 	[aDecoder decodeValuesOfObjCTypes:"iiiiii", &(s->magic), &(s->dataLocation), &(s->dataSize),
		&(s->dataFormat), &(s->samplingRate), &(s->channelCount)];
	s = realloc((char *)s, s->dataLocation + 1); /* allocate enough room for info string */
	[aDecoder decodeArrayOfObjCType:"c" count:s->dataLocation - sizeof(SndSoundStruct) + 4 at:s->info];

	printf("read sound Location:%d size:%d format:%d sr:%d cc:%d info:%s\n",
		s->dataLocation, s->dataSize, s->dataFormat,
		s->samplingRate, s->channelCount, s->info);
	finalSize = s->dataSize + s->dataLocation;
	
	s = realloc((char *)s,finalSize);
	if (s->dataLocation > sizeof(SndSoundStruct)) {
		/* read off the rest of the info string */
		[aDecoder decodeArrayOfObjCType:"c" count:s->dataLocation - sizeof(SndSoundStruct) at:(char *)s + sizeof(SndSoundStruct)];
	}
	[aDecoder decodeArrayOfObjCType:"c" count:s->dataSize at:(char *)s + s->dataLocation];

	soundStruct = s;
	return SND_ERR_NONE;
}

- awakeAfterUsingCoder:(NSCoder *)aDecoder
{
	status = NX_SoundInitialized;
	return self;/* what to do here??? Doesn't seem to be anything pressing... */
}

- (NSString *)name
{
    return name;
}

- setName:(NSString *)theName
/* this needs to interface with an object-wide name table
 * to identify sounds by name. At the moment multiple sound
 * objects may share the same name, which is not right.
 * Second Thoughts: many sounds MAY share the same name, as
 * they do not have do register with the central name table.
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

- (void)setDelegate:(id)anObject
{
	delegate = anObject;
}

- (double)samplingRate
{
	if (!soundStruct) return 0;
	return (double)(soundStruct->samplingRate);

}

- (int)sampleCount
{
	if (!soundStruct) return 0;
	return SndSampleCount(soundStruct);
}

- (double)duration
{
	if (!soundStruct) return 0.0;
	if ((double)(soundStruct->samplingRate) == 0) return 0.0; /* cop-out */
	return (double)[self sampleCount] / (double)(soundStruct->samplingRate);
}

- (int)channelCount
{
	if (!soundStruct) return 0;
	return soundStruct->channelCount;
}

- (char *)info
{
	if (!soundStruct) return NULL;
	return (char *)(soundStruct->info);
}

- (int)infoSize
{
	if (!soundStruct) return 0;
	return strlen((char *)(soundStruct->info));
}

#ifdef USE_PERFORM_SOUND_IO
int beginFun(SNDSoundStruct *sound, int tag, int err)
{
    Snd *theSnd;
    theSnd = [playRecTable valueForKey: (void *) tag];
    if (err) {
            [theSnd _setStatus:NX_SoundStopped];
            [theSnd tellDelegate:@selector(hadError:)];
    }
    else {
            [theSnd _setStatus:NX_SoundPlaying];
            [theSnd tellDelegate:@selector(willPlay:)];
    }
    return 0;
}

int endFun(SNDSoundStruct *sound, int tag, int err)
{
    Snd *theSnd;

    theSnd = [playRecTable valueForKey: (void *) tag];
    [theSnd _setStatus:NX_SoundStopped];
    if (err == SND_ERR_ABORTED) err = SND_ERR_NONE;
    if (err) [theSnd tellDelegate:@selector(hadError:)];
    else [theSnd tellDelegate:@selector(didPlay:)];
    [playRecTable removeKey: (void *) tag];
    /* bug fix for SoundKit: if DSP was used, its access is not
     * released as it should be. So I just automatically release it
     * here, whether or not it was used. Generally it's used for real-time
     * rate conversion for playback. (maybe recording etc too???)
     */
    err = SNDUnreserve(3);
    if(err) {
        NSLog(@"Unreserving error %d\n", err);
    }
    ((Snd *)theSnd)->tag = 0;
    return 0;
}

int beginRecFun(SNDSoundStruct *sound, int tag, int err)
{
	Snd *theSnd;
	theSnd = [playRecTable valueForKey: (void *) tag];
	if (err) {
		[theSnd _setStatus:NX_SoundStopped];
		[theSnd tellDelegate:@selector(hadError:)];
	}
	else {
		[theSnd _setStatus:NX_SoundRecording];
		[theSnd tellDelegate:@selector(willRecord:)];
	}
	return 0;
}

int endRecFun(SNDSoundStruct *sound, int tag, int err)
{
	Snd *theSnd;
	theSnd = [playRecTable valueForKey: (void *) tag];
	[theSnd _setStatus:NX_SoundStopped];
	printf("End recording error: %d\n",err);
	if (err == SND_ERR_ABORTED) err = SND_ERR_NONE;
	if (err) [theSnd tellDelegate:@selector(hadError:)];
	else [theSnd tellDelegate:@selector(didRecord:)];
	[playRecTable removeKey: (void *) tag];
	((Snd *)theSnd)->tag = 0;
	return 0;
}

#endif

- play:sender
{
#ifdef USE_PERFORM_SOUND_IO
	int err;
	if (!soundStruct) return self;
	if (!playRecTable) playRecTable = [[HashTable alloc] initKeyDesc:"i"];
	
	tag = ioTags;
        [playRecTable insertKey: (void *) tag value:self];
	status = NX_SoundPlayingPending;
        err = SNDUnreserve(3);
        if(err) {
            NSLog(@"Unreserving error %d\n", err);
        }
	err = SNDStartPlaying((SNDSoundStruct *)soundStruct,
		ioTags++ /*	int tag			*/,
		1 /*	int priority	*/,
		0 /*	int preempt		*/, 
		(SNDNotificationFun) beginFun,
		(SNDNotificationFun) endFun);
	if (err) NSLog(@"Playback error %d\n",err);
	return self;
#else
	return self;
#endif
}

- (int)play
{
	[self play:self];
	return SND_ERR_NONE;
}

- record:sender
{
#ifdef USE_NEXTSTEP_SOUND_IO
	int err;
	if (!playRecTable) playRecTable = [[HashTable alloc] initKeyDesc:"i"];

	if (soundStruct) {
		err = SndAlloc(&soundStruct,
			(int)((float)SND_RATE_CODEC*600.0 + 1),
			SND_FORMAT_MULAW_8,
			SND_RATE_CODEC,1,4);
		if (err) return nil;
	}
	tag = ioTags;
        [playRecTable insertKey: (void *) tag value:self];
	status = NX_SoundRecordingPending;
	err = SNDStartRecording((SNDSoundStruct *)soundStruct,
		ioTags++, /*	int tag			*/
		9, /*	int priority	*/
		1, /*	int preempt		*/
		(SNDNotificationFun) beginRecFun,
		(SNDNotificationFun) endRecFun);
	return self;
#else
	return self;
#endif
}

- (int)record
{
	[self record:self];
	return SND_ERR_NONE;
}

- (int)samplesProcessed
{
#ifdef USE_PERFORM_SOUND_IO
	return (tag == 0) ? -1 : SNDSamplesProcessed(tag);
#else
	return -1; /* not yet implemented */
#endif
}

- (int)status
{
	return status;
}

- (void)_setStatus:(int)newStatus
/* for use in the beginFunc and endFunc routines */
{
	status = newStatus;
}

- (int)waitUntilStopped
{
	return SND_ERR_NOT_IMPLEMENTED;
}

- (void)stop:(id)sender
{
#ifdef USE_PERFORM_SOUND_IO
	if (tag) {
		SNDStop(tag);
	}
	if (status == NX_SoundRecording || status == NX_SoundRecordingPaused) {
		if ([playRecTable isKey: (void *) tag])
                	[playRecTable removeKey:(void *) tag];
		status = NX_SoundStopped;
		[self tellDelegate:@selector(didRecord:)];	
	}
	if (status == NX_SoundPlaying || status == NX_SoundPlayingPaused) {
        	if ([playRecTable isKey:(void *) tag])
       			[playRecTable removeKey:(void *) tag];
		status = NX_SoundStopped;
		[self tellDelegate:@selector(didPlay:)];	
	}
	if(tag) {
		tag = 0;
	}
#endif
}

- (int)stop
{
#ifdef USE_PERFORM_SOUND_IO
	[self stop:self];
	return SND_ERR_NONE;
#else
	return SND_ERR_NOT_IMPLEMENTED;
#endif
}

- pause:sender
{
    return self;
}

- (int)pause
{
#ifdef USE_NEXTSTEP_SOUND_IO
	return SND_ERR_NOT_IMPLEMENTED;
#else
	return SND_ERR_NOT_IMPLEMENTED;
#endif
}

- resume:sender
{
    return self;
}

- (int)resume;
{
	return SND_ERR_NOT_IMPLEMENTED;
}

- (int)readSoundfile:(NSString *)filename
{
	int err;
	NSDictionary *fileAttributeDictionary;
        NSFileManager *fileManager = [NSFileManager defaultManager];

	if (soundStruct) SndFree(soundStruct);
	if (name) {
		free(name);
		name = NULL;
		}
        // check its seekable, by checking its POSIX regular.
        fileAttributeDictionary = [fileManager fileAttributesAtPath: filename traverseLink: YES];
        if([fileAttributeDictionary objectForKey: NSFileType] != NSFileTypeRegular)
	     return SND_ERR_CANNOT_OPEN;

	err = SndReadSoundfile([filename cString],&soundStruct);
	if (!err) soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
	return err;
}

- (int)writeSoundfile:(NSString *)filename
{
	return SndWriteSoundfile([filename cString], soundStruct);
}

- (void)writeToPasteboard:(NSPasteboard *)thePboard
{
/* here I provide data straight away. Ideally, a non-freeing object
 * should be given the data to hold, and it should implement the "provideData"
 * method.
 * If I could guarantee that the Snd Class object itself wold not be freed
 * (for instance when the app is terminated) then one could specify the class
 * object. Cunning, eh. Maybe I'll do that anyway, and use a static variable to
 * hold the data...
 */
/* an alternative method of providing the data here is to NOT compact,
 * but to write the data to a stream (  NXStream *ts ) and send the stream to 
 * the pasteboard. I'll leave it like it is for now.
 */
/* here I assume that the header will be in host form, and the sound data
 * will be in "sound" (ie big endian) format. This is ok if we aren't trying
 * to share the pasteboard between dissimilar machines...
 */
    BOOL ret;
    NSMutableData *ts = [NSMutableData dataWithCapacity:soundStructSize];

//	[self compactSamples];
    [self writeSoundToStream:ts];
    [thePboard declareTypes:[NSArray arrayWithObject:NXSoundPboardType] owner:nil];	

    ret = [thePboard setData:ts forType:NXSoundPboardType];
    if (!ret) {
        printf("Sound paste error\n");
        }
}

- initFromPasteboard:(NSPasteboard *)thePboard
{
    NSData *ts;
    ts = [thePboard dataForType:NXSoundPboardType];
    [self init];
    [self readSoundFromStream:ts];

    return self;
}

- (BOOL)isEmpty
{
	if (![self isEditable]) return NO;
	if (!soundStruct) return YES;
	if (![self dataSize]) return YES;
	return NO;
}

- (BOOL)isEditable
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

- (BOOL)compatibleWith:(Snd *)aSound
{
	SndSoundStruct *aStruct;
	if (!soundStruct) return YES;
	if (!aSound) return YES;
	if (!(aStruct = [aSound soundStruct])) return YES;
	if (soundStruct->samplingRate == aStruct->samplingRate
	 && soundStruct->channelCount == aStruct->channelCount
	 && [self dataFormat] == [aSound dataFormat]) return YES;
	return NO;
}

- (BOOL)isPlayable
{
	int df,cc,sr;
	if (!soundStruct) return YES; /* empty sound can be played! */
	if ((df = soundStruct->dataFormat) == SND_FORMAT_INDIRECT)
		df =  ((SndSoundStruct *)(*((SndSoundStruct **)
			(soundStruct->dataLocation))))->dataFormat;
	cc = soundStruct->channelCount;
	if (cc < 1 || cc > 2) return NO;
	sr = soundStruct->samplingRate;
	if (sr < 4000 || sr > 48000) return NO; /* need to check hardware here */
	switch (df) {
		case SND_FORMAT_MULAW_8:
		case SND_FORMAT_LINEAR_8:
		case SND_FORMAT_LINEAR_16:
		case SND_FORMAT_LINEAR_32:
		case SND_FORMAT_FLOAT:
		case SND_FORMAT_DOUBLE:
			return YES;
		default:
			break;
	}
	return NO;
}
	
- (int)convertToFormat:(int)aFormat
	   samplingRate:(double)aRate
	   channelCount:(int)aChannelCount
{
	int err;
	SndSoundStruct *toSound;
	err = SndAlloc(&toSound,0,aFormat,aRate,aChannelCount,4);
	if (err) return err;
	err = SndConvertSound(soundStruct, &toSound);
	if (!err) {
		soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
		SndFree(soundStruct);
		soundStruct = toSound;
	}
	return err;
}

- (int)convertToFormat:(int)aFormat
{
	return [self convertToFormat:aFormat
		samplingRate:soundStruct->samplingRate
		channelCount:soundStruct->channelCount];
}

- (int)deleteSamples
{
	return [self deleteSamplesAt:0 count:[self sampleCount]];
}

- (int)deleteSamplesAt:(int)startSample count:(int)sampleCount
{
	int err;
	err = SndDeleteSamples(soundStruct, startSample, sampleCount);
	if (!err) {
		if (soundStruct->dataFormat != SND_FORMAT_INDIRECT)
			soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
		else soundStructSize = soundStruct->dataSize;		
	}
	return err;
}
- (int)insertSamples:(Snd *)aSnd at:(int)startSample
{
	int err;
	SndSoundStruct *fromSound;
	if (!aSnd) return SND_ERR_NONE;
	if (!(fromSound = [aSnd soundStruct]))
		return SND_ERR_NONE;
	err = SndInsertSamples(soundStruct, fromSound, startSample);
	if (!err) {
		if (soundStruct->dataFormat != SND_FORMAT_INDIRECT)
			soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
		else soundStructSize = soundStruct->dataSize;		
	}
	return err;
}

- (id)copy
{
    id newSound = [[[self class] alloc] init];
    [newSound copySound:self];
    return newSound;
}

- (int)copySound:(Snd *)aSnd
{
	int err;
	SndSoundStruct *fromSound;
	status = NX_SoundInitialized;
	if (aSnd)
		if (soundStruct == [aSnd soundStruct]) return SND_ERR_NONE;
	if (soundStruct) {
		err = SndFree(soundStruct);
		soundStruct = NULL;
		soundStructSize = 0;
		if (err) return err;
	}
	if (!aSnd) {
		return SND_ERR_NONE;
	}

	if (!(fromSound = [aSnd soundStruct])) {
		return SND_ERR_NONE;
	}
	err = SndCopySound(&soundStruct,fromSound);
	if (!err) {
		if (soundStruct->dataFormat != SND_FORMAT_INDIRECT)
			soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
		else soundStructSize = soundStruct->dataSize;		
	}
	return err;
}

- (int)copySamples:(Snd *)aSnd at:(int)startSample count:(int)sampleCount
{
	int err;
	status = NX_SoundInitialized;
	if (!aSnd) {
		if (soundStruct) {
			err = SndFree(soundStruct);
			soundStruct = NULL;
			soundStructSize = 0;
			return err;
		}
		return SND_ERR_NONE;
	}
	if (soundStruct) {
		if (![self isEditable]) return SND_ERR_CANNOT_EDIT;
// following condition not in the original! Therefore removed.
//		if (![aSnd compatibleWith:self]) return SND_ERR_CANNOT_COPY;
		SndFree(soundStruct);
		soundStruct = NULL;
		soundStructSize = 0;
	}
	err = SndCopySamples(&soundStruct, [aSnd soundStruct],
		startSample, sampleCount);
	if (!err) {
		if (soundStruct->dataFormat != SND_FORMAT_INDIRECT)
			soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
		else soundStructSize = soundStruct->dataSize;		
	}
	return err;
}

- (int)compactSamples
{
	SndSoundStruct *newStruct;
	int err;
    if (![self isEditable]) return SND_ERR_CANNOT_EDIT;
	if (!soundStruct) return SND_ERR_NOT_SOUND;
	if (soundStruct->dataFormat != SND_FORMAT_INDIRECT) return SND_ERR_NONE;
	if (err = SndCompactSamples(&newStruct, soundStruct)) return err;
	if (err = SndFree(soundStruct)) return err;
	soundStruct = newStruct;
	soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;
	return SND_ERR_NONE;
}

- (BOOL)needsCompacting
{
	if (!soundStruct) return NO;
	return (soundStruct->dataFormat == SND_FORMAT_INDIRECT);
}

- (unsigned char *)data
{
	if (!soundStruct) return NULL;
	if (soundStruct->dataFormat == SND_FORMAT_INDIRECT)
		return (char *)soundStruct->dataLocation;
	return (char *)soundStruct + soundStruct->dataLocation;
}

- (int)dataSize
/* This looks after fragged sounds ok, as the docs say that for a
 * fragged sound, this should return the length of the main SndSoundStruct
 * (not including data); otherwise, should return num of bytes of data,
 * not including the structure.
 */
{
	if (!soundStruct) return 0;
	return soundStruct->dataSize; 
}

- (int)dataFormat
{
	int df;
	if (!soundStruct) return 0;
	if ((df = soundStruct->dataFormat) == SND_FORMAT_INDIRECT)
		return ((SndSoundStruct *)(*((SndSoundStruct **)
			(soundStruct->dataLocation))))->dataFormat;
	return df;
}

- (int)setDataSize:(int)newDataSize
     dataFormat:(int)newDataFormat
     samplingRate:(double)newSamplingRate
     channelCount:(int)newChannelCount
     infoSize:(int)newInfoSize
{
	if (soundStruct) SndFree(soundStruct);
	return SndAlloc(&soundStruct, newDataSize, newDataFormat,
		newSamplingRate, newChannelCount, newInfoSize);
}

- (SndSoundStruct *)soundStruct
{	return soundStruct; }

- (int)soundStructSize
/* if the sound is fragmented, returns only the size of the FIRST fragment */
{
	if (!soundStruct) return 0;
	if (soundStruct->dataFormat != SND_FORMAT_INDIRECT)
		return soundStruct->dataSize + soundStruct->dataLocation;
	else return soundStruct->dataSize; /* see SndFunctions.h */
}

- setSoundStruct:(SndSoundStruct *)aStruct soundStructSize:(int)aSize
{
	if (status != NX_SoundInitialized && status != NX_SoundStopped)
		return nil;
	if (soundStruct && soundStruct != aStruct) SndFree(soundStruct);
	soundStruct = aStruct;
	soundStructSize = aSize;
	return self;
}

- (SndSoundStruct *)soundStructBeingProcessed
{ return soundStruct; } /* when we implement i/o, need to return different */

- (int)processingError
{
	return currentError;
}

- soundBeingProcessed
{ return self; } /* default implementation. Provided for subclassing */

- tellDelegate:(SEL)theMessage
{
	if (delegate)
		if ([delegate respondsToSelector:theMessage])
                    [delegate performSelector:theMessage withObject:self];
	return self;
}

@end
