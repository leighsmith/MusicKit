/******************************************************************************
$Id$

Description: Main class defining a sound object.

Original Author: Stephen Brandon

LEGAL:
This framework and all source code supplied with it, except where specified, are Copyright Stephen Brandon and the University of Glasgow, 1999. You are free to use the source code for any purpose, including commercial applications, as long as you reproduce this notice on all such software.

Software production is complex and we cannot warrant that the Software will be error free.  Further, we will not be liable to you if the Software is not fit for the purpose for which you acquired it, or of satisfactory quality. 

WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD PARTIES RIGHTS.

If a court finds that we are liable for death or personal injury caused by our negligence our liability shall be unlimited.  

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS OF THIS AGREEMENT.

******************************************************************************/
/* HISTORY
 * $Log$
 * Revision 1.10.2.1  2001/02/11 06:18:07  leigh
 * Handled playing mono files
 *
 * Revision 1.10  2001/02/08 00:17:56  leigh
 * Added Christopher Penroses additions for MacOS X Public Beta CoreAudio
 *
 * Revision 1.9  2000/08/11 01:18:06  leigh
 * Commented out debugging info
 *
 * Revision 1.8  2000/06/29 18:03:37  leigh
 * Merged the NSDictionary use with MacOsX support branches
 *
 * 20/6/99 sb: added check to -compactSamples to ensure sound needs it
 */

#ifdef WIN32
#include <Winsock.h>
#else
#include <libc.h>
#endif
#if defined(__ppc__) || defined(WIN32)
# import <Foundation/NSPathUtilities.h>
# import <AppKit/NSSound.h>
#endif

#include <stdlib.h>
#include <stdio.h>
#include <string.h> /* for memmove() */
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSApplication.h>

#import "Snd.h"

#ifndef USE_NEXTSTEP_SOUND_IO
NSString *NXSoundPboardType = @"NXSoundPboardType";
#endif



@implementation Snd

static NSAutoreleasePool *pool;
static NSMutableDictionary* nameTable = nil;
static NSMutableDictionary* playRecTable = nil;
static int ioTags = 1000;

void merror(int er)
{
    NSLog(@"mem error %i\n",er);
    return;
}

#ifdef macosx

static id	clientDataHack;
static BOOL	isPlaying = NO;

OSStatus SndKitSndIOProc(AudioDeviceID inDevice,
                         const AudioTimeStamp *inNow,
                         const void *inInputData,
			 const AudioTimeStamp *inInputTime,
                         void  *outOutputData,
                         const AudioTimeStamp *inOutputTime,
			 void *inClientData)
{
    
    register int  i;
    
    float         *inputBuffer,
                    *outputBuffer = outOutputData;
    
    id            me = (id) *( (id *) inClientData);
    
    /* select input buffer */
    
    if ([me bufferCount] % 2)
        inputBuffer = (float *) [me bufferOdd];
    
    else
        inputBuffer = (float *) [me bufferEven];
    
    /* fill outputBuffer with floating-point data */
    
    for ( i=0; i < [me bufferFrameSize]; i++ )
        *(outputBuffer+i) = *(inputBuffer+i);
    
    /* unblock main thread waiting on this condition variable */
    
    pthread_cond_signal( [me soundCondition] );
    
    return 0;
}

static void *playSoundFunc(void *obj)
{
  [((id)obj) playSoundThread];
  return 0;
}

#endif


+ (void)initialize
{
#if defined(WIN32) && defined(USE_PERFORM_SOUND_IO)
    char **driverNames;
#endif
//	printf("Snd class initialize\n");
//	malloc_error(&merror);
    pool = [[NSAutoreleasePool alloc] init];
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
    Snd *newSound;
    NSBundle *soundLocation;
    NSString *path;
    NSArray *libraryDirs;
    int i;
    id retSnd = [nameTable objectForKey:aName];
    if (retSnd) return retSnd;

    path = [[NSBundle mainBundle] pathForResource:aName ofType:@"snd"];
    found = (path != nil);
    if (found) {
        newSound = [[Snd alloc] initFromSoundfile:path];
        if (newSound) {
            return [newSound autorelease];
        }
    }

    libraryDirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
    for(i = 0; i < [libraryDirs count]; i++) {
        path = [[[libraryDirs objectAtIndex: i] stringByAppendingPathComponent: @"Sounds"] stringByAppendingPathComponent:path];
        soundLocation = [[NSBundle alloc] initWithPath:path];
        if (soundLocation) {
            found = ((path = [soundLocation pathForResource:aName ofType:@"snd"]) != nil);
            [soundLocation release];
            if (found) {
                newSound = [[Snd alloc] initFromSoundfile:path];
                if (newSound) {
                    return [newSound autorelease];
                }
            }
        }
    }
    return nil;
}

+ findSoundFor:(NSString *)aName
{
    return [self soundNamed: aName];
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
    return [newSnd autorelease];
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
                    return [newSound autorelease];
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
    name = nil;
    conversionQuality = SND_CONVERT_LOWQ;
    delegate = nil;
    status = NX_SoundInitialized;

    currentError = 0;
    _scratchSnd = NULL;
    _scratchSize = 0;
#if defined(__ppc__) || defined(WIN32)
    plSound = nil;
#endif
    tag = 0;

    /*
    soundStruct = (SndSoundStruct *) calloc( 1, sizeof(SndSoundStruct) );

    soundStruct->magic = SND_MAGIC;
    soundStruct->dataLocation = sizeof(SndSoundStruct);
    soundStruct->dataSize = 0;
    soundStruct->dataFormat = SND_FORMAT_UNSPECIFIED;
    */

#ifdef macosx

    soundPlaying = NO;
    stopRequest = NO;

#endif

    return [super init];
}

- initFromSoundfile:(NSString *)filename
{
    [self init];
    if ([self readSoundfile: filename]) {
        [self release];
        return nil;
    }
    return self;
}

- initFromSection:(NSString *)sectionName
{
    printf("Snd: -initFromSection:(NSString *)sectionName  obsolete\n");
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
#if defined(__ppc__) || defined(WIN32)
    [plSound release];
#endif
    [super dealloc];
}

// Debugging function
void soundStructDescription(SndSoundStruct *s)
{
    NSLog(@"read sound Location:%d size:%d format:%d sr:%d cc:%d info:%s\n",
		s->dataLocation, s->dataSize, s->dataFormat,
		s->samplingRate, s->channelCount, s->info);
}

- readSoundFromStream:(NSData *)stream
{
    SndSoundStruct *s;
    int finalSize;

    [name release];
    priority = 0;
//  name = calloc(256,1);
//  NXScanf(stream,"%s",name);
//  NXGetc(stream); /* read off the \n character */
//  name = realloc(name,strlen(name) + 1);
//  NXRead(stream,&priority,sizeof(int));
//  priority = (int)ntohl(priority);

    if (soundStruct) SndFree(soundStruct);
    if (!(s = malloc(sizeof(SndSoundStruct))))
        [[NSException exceptionWithName:@"Sound Error"
                                 reason:@"Can't allocate memory for Snd class"
                               userInfo:nil] raise];
//  NXRead(stream,s,sizeof(SndSoundStruct)); /* gets 1st 4 bytes info string */
    [stream getBytes:s length:sizeof(SndSoundStruct)];/* only gets 1st 4 bytes of info string */
#ifdef __LITTLE_ENDIAN__
    s->magic = ntohl(s->magic);
    s->dataLocation = ntohl(s->dataLocation);
    s->dataSize = ntohl(s->dataSize);
    s->dataFormat = ntohl(s->dataFormat);
    s->samplingRate = ntohl(s->samplingRate);
    s->channelCount = ntohl(s->channelCount);
#endif

//  dumpSoundStruct(s);
    finalSize = s->dataSize + s->dataLocation;

    s = realloc((char *)s,finalSize);
    [stream getBytes:(char *)s + sizeof(SndSoundStruct)
               range:NSMakeRange(sizeof(SndSoundStruct),finalSize - sizeof(SndSoundStruct))];
//  if (s->dataLocation > sizeof(SndSoundStruct)) {
//		/* read off the rest of the info string */
//		NXRead(stream,(char *)s + sizeof(SndSoundStruct),
//			s->dataLocation - sizeof(SndSoundStruct));
//  }
//  NXRead(stream, (char *)s + s->dataLocation, s->dataSize);

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
//  int newPriority = (int)htonl(priority);

//  NXPrintf(stream, "%s\n",name);
//  NXWrite(stream,&newPriority,sizeof(int));

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

//  NXWrite(stream, s, headerSize);
    [stream appendBytes:s length:headerSize];
    if (df != SND_FORMAT_INDIRECT) { /* simple read/write of block of data */
//  NXWrite(stream, (char *)soundStruct + soundStruct->dataLocation,
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
    [aCoder encodeObject:name];

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

- (id)initWithCoder:(NSCoder *)aDecoder
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

//	soundStructDescription(s);

    finalSize = s->dataSize + s->dataLocation;

    s = realloc((char *)s,finalSize);
    if (s->dataLocation > sizeof(SndSoundStruct)) {
            /* read off the rest of the info string */
        [aDecoder decodeArrayOfObjCType:"c"
                                  count:s->dataLocation - sizeof(SndSoundStruct)
                                     at:(char *)s + sizeof(SndSoundStruct)];
    }
    [aDecoder decodeArrayOfObjCType:"c" count:s->dataSize at:(char *)s + s->dataLocation];

    soundStruct = s;
    return SND_ERR_NONE;
}

- awakeAfterUsingCoder:(NSCoder *)aDecoder
{
    status = NX_SoundInitialized;
    conversionQuality = SND_CONVERT_LOWQ;
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
    theSnd = [playRecTable objectForKey: [NSNumber numberWithInt: tag]];
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
    NSNumber *tagNumber = [NSNumber numberWithInt: tag];

    theSnd = [playRecTable objectForKey: tagNumber];
    // NSLog(@"endFun theSnd = %x, err = %d tag = %d\n", theSnd, err, tag);
    [theSnd _setStatus:NX_SoundStopped];
    if (err == SND_ERR_ABORTED) err = SND_ERR_NONE;
    if (err) [theSnd tellDelegate:@selector(hadError:)];
    else [theSnd tellDelegate:@selector(didPlay:)];
    [playRecTable removeObjectForKey: tagNumber];
    /* bug fix for SoundKit: if DSP was used, its access is not
     * released as it should be. So I just automatically release it
     * here, whether or not it was used. Generally it's used for real-time
     * rate conversion for playback. (maybe recording etc too???)
     */
    err = SNDUnreserve(3);
    if(err) {
        NSLog(@"Unreserving error %d\n", err);
    }
    // NSLog(@"theSnd = %x, err = %d\n", theSnd, err);
    ((Snd *)theSnd)->tag = 0;
    return 0;
}

int beginRecFun(SNDSoundStruct *sound, int tag, int err)
{
    Snd *theSnd;
    theSnd = [playRecTable objectForKey: [NSNumber numberWithInt: tag]];
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
    NSNumber *tagNumber = [NSNumber numberWithInt: tag];

    theSnd = [playRecTable objectForKey: tagNumber];
    [theSnd _setStatus:NX_SoundStopped];
    printf("End recording error: %d\n",err);
    if (err == SND_ERR_ABORTED) err = SND_ERR_NONE;
    if (err) [theSnd tellDelegate:@selector(hadError:)];
    else [(Snd *)theSnd tellDelegate:@selector(didRecord:)];
    [playRecTable removeObjectForKey: tagNumber];
    ((Snd *)theSnd)->tag = 0;
    return 0;
}

#endif

#ifdef macosx
- play:(id) sender beginSample:(int) begin sampleCount: (int) count 
{
    playSender = sender;
    
    playBegin = begin;
    playEnd = begin + count;
    
    if (playBegin > [self sampleCount] || playBegin < 0)
        playBegin = 0;
    
    if (playEnd > [self sampleCount] || playEnd < playBegin)
        playEnd = [self sampleCount];
    
    /* tell our self that we are playing */
    
    soundPlaying = YES;
    
    /* detach thread */
    
    pthread_create( &soundThread, NULL, playSoundFunc, (void *) self );
    
    return self;
}

#endif

- play:sender
{
#if macosx
    playSender = sender;
    
    playBegin = 0;
    playEnd = [self sampleCount];
    
    /* tell our self that we are playing */
    
    soundPlaying = YES;
    
    /* detach thread */
    
    pthread_create( &soundThread, NULL, playSoundFunc, (void *) self );
    
    return self;
#else
#ifdef USE_PERFORM_SOUND_IO
	int err;
	if (!soundStruct) return self;
	if (!playRecTable) {
		playRecTable = [NSMutableDictionary dictionaryWithCapacity: 20];
		[playRecTable retain];
	}
	
	tag = ioTags;
        // the same soundStruct is used every time the sound is played, so we use the tag to differentiate.
        // We use an NSDictionary rather than a HashTable for strict OpenStep support.
        [playRecTable setObject: self forKey: [NSNumber numberWithInt: tag]];
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
#if defined(__ppc__) || defined(WIN32)
    NSString *tempfile = [NSTemporaryDirectory() stringByAppendingPathExtension:
        [NSString stringWithFormat:@"SK%s.snd",tmpfile()]];
    if (!soundStruct) return self;
    [self writeSoundfile:tempfile];
    [plSound release]; /* get rid of old one */
    plSound = [[NSSound alloc] initWithContentsOfFile:tempfile byReference:NO];
    [[NSFileManager defaultManager] removeFileAtPath:tempfile handler:nil];
    [self tellDelegate:@selector(willPlay:)];
    [(NSSound *)plSound setDelegate:self];
    [(NSSound *)plSound play];
    return self;
# endif
    return self;
#endif
#endif  // macosx
}

#ifdef macosx

- (void) playSoundThread
{

  int			bufferByteSize,
			currentSample = playBegin * [self channelCount];

  UInt32                intFetch,
			propertySize;

  float			*soundBuffer;

  double		deviceSampleRate;

  BOOL			first = YES,
			finished = NO;

  OSStatus              CAstatus;
  
  int			deviceChannels;
  int duplicateAcrossChannels;


  /* our playback buffer size in bytes */

  bufferByteSize = 32768;
  bufferFrameSize = bufferByteSize / sizeof(float);

  bufferCount = 0;

  /* allocate our buffers */

  bufferEven = (float *)
	NSZoneCalloc(NSDefaultMallocZone(),
		     bufferFrameSize, sizeof(float));

  bufferOdd = (float *)
	NSZoneCalloc(NSDefaultMallocZone(),
		     bufferFrameSize, sizeof(float));

  soundBuffer = bufferEven;

  /* initialize CoreAudio device */

  /* Get the default sound output device */

  propertySize = sizeof(outputDeviceID);
  CAstatus = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
		&propertySize, &outputDeviceID);

  //  fprintf(stderr, "%p\n", (void *) &outputDeviceID);
  //  fprintf(stderr, "output device CAstatus:%s\n", (char *) &CAstatus);

  if (CAstatus) {
    fprintf(stderr, "300AudioHardwareGetProperty returned %d\n", (int) CAstatus);
    exit(1);
  }

  /* check the returned device */

  if (outputDeviceID == kAudioDeviceUnknown) {
    fprintf(stderr, "outputDeviceID is kAudioDeviceUnknown\n");
    exit(1);
  }


  /* get name of device */

  {

    char        deviceName[256];

    propertySize = 256;
    CAstatus = AudioDeviceGetProperty(outputDeviceID, 0, false,
				    kAudioDevicePropertyDeviceName,
				    &propertySize, deviceName);

       // NSLog(@"%s\n", deviceName);

    //    NSLog(@"get device name CAstatus:%s\n", (char *) &CAstatus);

    if (CAstatus) {
      fprintf(stderr, "AudioDeviceGetProperty returned %s\n", (char *) &CAstatus);
      exit(1);
    }
  }


  /* check device CAstatus */

  {

    UInt32      running;

    propertySize = sizeof(UInt32);
    CAstatus = AudioDeviceGetProperty(outputDeviceID, 0, false,
				    kAudioDevicePropertyDeviceIsRunning,
				    &propertySize, &running);

    //    fprintf(stderr,"%d\n", (int) running);

    //    fprintf(stderr, "get isrunning CAstatus:%s\n", (char *) &CAstatus);


    if (CAstatus) {
      fprintf(stderr, "///AudioDeviceGetProperty returned %d\n", (int) CAstatus);
      exit(1);
    }

  }



  /* set the sampleRate of the device */

  propertySize = sizeof(double);
  deviceSampleRate = [self samplingRate];
  CAstatus = AudioDeviceSetProperty(outputDeviceID, NULL, 0, false,
                                  kAudioDevicePropertyRateScalar,
				  propertySize, &deviceSampleRate);

 // NSLog(@"set sampling rate CAstatus:%s deviceSampleRate = %lf\n", (char *) &CAstatus, deviceSampleRate);

  /*
  if (CAstatus) {
    fprintf(stderr, "320AudioDeviceSetProperty returned %d\n", (int) CAstatus);
    exit(1);
  }
  */
  
  /* get the sampleRate of the device */

  propertySize = sizeof(double);
  CAstatus = AudioDeviceGetProperty(outputDeviceID, 0, false,
                                  kAudioDevicePropertyRateScalar,
                                  &propertySize, &deviceSampleRate);

  //  fprintf(stderr, "get sampling rate CAstatus:%s\n", (char *) &CAstatus);

  /*
  if (CAstatus) {
    fprintf(stderr, "332AudioDeviceGetProperty returned %d\n", (int) CAstatus);
    exit(1);
  }
  */

  /* compare the sample rate of our input sound with that of the device */

  if ((double) [self samplingRate] != deviceSampleRate) {
    NSLog(@"input sound sample rate doesn't match device sample rate\n");
    exit(1);
  }


  /* set the buffer size of the device */

  propertySize = sizeof(bufferByteSize);

  CAstatus = AudioDeviceSetProperty(outputDeviceID, NULL, 0, false,
                                  kAudioDevicePropertyBufferSize,
                                  propertySize, &bufferByteSize);

  //  fprintf(stderr, "set buffer size CAstatus:%s\n", (char *) &CAstatus);

  /*
  if (CAstatus) {
    fprintf(stderr, "354AudioDeviceSetProperty returned %d\n", (int) CAstatus);
    exit(1);
  }
  */

  /* fetch the buffer size to checking */

  propertySize = sizeof(intFetch);
  CAstatus = AudioDeviceGetProperty(outputDeviceID, 0, false,
                                  kAudioDevicePropertyBufferSize,
                                  &propertySize, &intFetch);

  //  fprintf(stderr, "get buffer size CAstatus:%s\n", (char *) &CAstatus);

  /*
  if (CAstatus) {
    fprintf(stderr, "365AudioDeviceGetProperty returned %d\n", (int) CAstatus);
    exit(1);
  }
  */

  if (bufferByteSize != intFetch ) {
    fprintf(stderr, "device did not set desired buffer size\n");
    fprintf(stderr, "desired: %d\nactual: %d\n", (int) bufferByteSize,
	    (int) intFetch);
    exit(1);
  }


  /* Get the basic device description */

  propertySize = sizeof(outputStreamBasicDescription);
  CAstatus = AudioDeviceGetProperty(outputDeviceID, 0, false,
                                  kAudioDevicePropertyStreamFormat,
                                  &propertySize,&outputStreamBasicDescription);

  //  fprintf(stderr, "get stream format CAstatus:%s\n", (char *) &CAstatus);

  /*
  if (CAstatus) {
    fprintf(stderr, "384AudioDeviceGetProperty returned %d\n", (int) CAstatus);
    exit(1);
  }
  */

  /* channel management */
  deviceChannels = outputStreamBasicDescription.mChannelsPerFrame;
  // NSLog(@"device channels:      %d\n", deviceChannels);


  outputStreamBasicDescription.mChannelsPerFrame = 1;
  propertySize = sizeof(outputStreamBasicDescription);
  CAstatus = AudioDeviceSetProperty(outputDeviceID, NULL, 0, false,
                                  kAudioDevicePropertyStreamFormat,
                                  propertySize, &outputStreamBasicDescription);

    // fprintf(stderr, "get stream format CAstatus:%s\n", (char *) &CAstatus);

  if (CAstatus) {
    fprintf(stderr, "384AudioDeviceGetProperty returned %d\n", (int) CAstatus);
    exit(1);
  }

  /* put our sound data into successive overlapped buffers and play them */

  while (!finished) {

    int		index,
		dataFormat = [self dataFormat];

    void	*data = [self data];

    /* send zeros for the first buffer */

    if (!first) {

      if ( dataFormat == SND_FORMAT_INDIRECT ) {

	int			fragmentSamples = 0,
				sizeAdj,
				sampleLocation = currentSample;

	SndSoundStruct		**sound_structs = (SndSoundStruct **)
							[self data];

	void   *sampleLand = (short *) ( (char *) (*sound_structs) +
					    (*sound_structs)->dataLocation);

	/* add format switch here */

	switch ( (*sound_structs)->dataFormat ) {

	  case SND_FORMAT_FLOAT:
	    sizeAdj = (sizeof(float)>>1);
	    break;

	  case SND_FORMAT_LINEAR_16:
	    sizeAdj = (sizeof(short)>>1);
	    break;

	  case SND_FORMAT_DOUBLE:
	    sizeAdj = (sizeof(double)>>1);
	    break;

	  case SND_FORMAT_MULAW_8:
	    sizeAdj = (sizeof(char)>>1);
	    break;
	    
	  default:
	    sizeAdj = (sizeof(short)>>1);
	    break;
	}

	/* find the first sound_struct that contains the first sample
	   of our output data */

	while ( sampleLocation >= fragmentSamples ) {

	  if ( *sound_structs == NULL )
	    fprintf(stderr,"Uh oh! Grievous inconsistency!\n");

	  sampleLocation -= fragmentSamples;
	  fragmentSamples = ((*sound_structs)->dataSize) >> sizeAdj;
	  
	  sampleLand = (void *) ((char *) (*sound_structs) +
				  (*sound_structs)->dataLocation);
	  ++sound_structs;
	}

	/* construct out output buffer given the current format */

	for ( index=0; index < bufferFrameSize; index++ ) {

	  if ( currentSample >= playEnd * [self channelCount] ) {
	      
	    finished = YES;
	    break;
	  }

	  switch ( (*sound_structs)->dataFormat ) {

	    case SND_FORMAT_FLOAT:
	      *(soundBuffer+index) = *((float *) sampleLand + sampleLocation);
	      break;

	    case SND_FORMAT_LINEAR_16:
	      *(soundBuffer+index) = *((short *) sampleLand + sampleLocation) /
				32767.;
	      break;
	      
	    case SND_FORMAT_DOUBLE:
	      *(soundBuffer+index) = *((double *) sampleLand + sampleLocation);
	      break;

	    case SND_FORMAT_MULAW_8:
	      *(soundBuffer+index) = SndiMulaw( *((char *) sampleLand +
						  sampleLocation) ) / 32767.;
	      break;
	      
	    default:
	      *(soundBuffer+index) = 0.;
	      break;
	  }

	  currentSample++;
	  sampleLocation++;
	}
      }

      else {

        duplicateAcrossChannels = deviceChannels - [self channelCount];
	for ( index=0; index < bufferFrameSize; index++ ) {

            if ( currentSample >= playEnd * [self channelCount] ) {
                
                finished = YES;
                break;
            }
    
            switch ([self dataFormat]) {
    
            case SND_FORMAT_FLOAT:
    
                *(soundBuffer+index) = *((float *) data+currentSample);
                break;
                
            case SND_FORMAT_LINEAR_16:
    
                *(soundBuffer+index) = *((short *) data + currentSample) /
                                                                    32767.;
                break;
                
            case SND_FORMAT_DOUBLE:
                
                *(soundBuffer+index) = *((double *) data+currentSample);
                break;
    
            case SND_FORMAT_MULAW_8:
    
                *(soundBuffer+index) = 
                        SndiMulaw( *((char *) data + currentSample) ) / 32767.;
                break;
            
            default:
                break;
            }
            // when playing more device channels than the sound channels 
            // i.e playing a mono file on stereo, since this loop iterates across the bufferFrameSize,
            // we delay the advance of the currentSampleIndex until all device Channels have received
            // a copy of the sample.
            if (duplicateAcrossChannels-- == 0) {
                currentSample++;
                duplicateAcrossChannels = deviceChannels - [self channelCount];
            }
        }
      }
    }

    /*
      fwrite( soundBuffer, bufferFrameSize, sizeof(float), stdout);
    */

    if (first) {

      /* start playback */

      clientDataHack = self;

      CAstatus = AudioDeviceAddIOProc(outputDeviceID, SndKitSndIOProc,
				    (void *) &clientDataHack);
      if (CAstatus) {
	fprintf(stderr, "AudioDeviceAddIOProc returned %d\n", (int) CAstatus);
	exit(1);
      }

      CAstatus = AudioDeviceStart(outputDeviceID, SndKitSndIOProc);

      if (CAstatus) {
	fprintf(stderr, "AudioDeviceStart returned %d\n", (int) CAstatus);
	exit(1);
      }

      /* we won't need to return here */

      first = NO;
    }

    /* otherwise we sleep until resumed by the callback function */

    else {

      /* have thread wait for sound driver  to send data before filling up
	 the next buffer */

      [self wait];
    }

    /* we might have the chance to use the most beautiful function in
       computer science */

    if (stopRequest) {

      stopRequest = NO;
      goto CLEANUP;
    }

    bufferCount++;

    if (bufferCount % 2)
      soundBuffer = bufferOdd;

    else
      soundBuffer = bufferEven;

    bzero(soundBuffer, bufferByteSize);
  }

  [self wait];

 CLEANUP:

  /* stop audio playback */

  CAstatus = AudioDeviceStop(outputDeviceID, SndKitSndIOProc);

  if (CAstatus) {
    fprintf(stderr, "AudioDeviceStop returned %d\n", (int) CAstatus);
    exit(1);
  }

  soundPlaying = NO;

  /* free our audio buffers */

  NSZoneFree( NSDefaultMallocZone(), bufferEven );
  NSZoneFree( NSDefaultMallocZone(), bufferOdd );

/* disable the objective-c runtime thread protection, assuming that
   only one MixDocument is playing at a time, submix concerns abound! */

//  objc_setMultithreaded(NO);

  if (playSender && [playSender respondsToSelector:@selector(didPlay:)])
    [playSender didPlay:self];

  /* end our thread */

  pthread_join(soundThread, NULL);

  return;
}

#endif

//#if defined(__ppc__) || defined(WIN32)
- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool;
{
    [self tellDelegate:@selector(didPlay:)];
}
//#endif

- (int)play
{
	[self play:self];
	return SND_ERR_NONE;
}

- record:sender
{
#ifdef USE_NEXTSTEP_SOUND_IO
    int err;
    if (!playRecTable) {
        playRecTable = [NSMutableDictionary dictionaryWithCapacity: 20];
        [playRecTable retain];
    }

    if (soundStruct) {
        err = SndAlloc(&soundStruct,
                (int)((float)SND_RATE_CODEC*600.0 + 1),
                SND_FORMAT_MULAW_8,
                SND_RATE_CODEC,1,4);
        if (err) return nil;
    }
    tag = ioTags;
    [playRecTable setObject: self forKey: [NSNumber numberWithInt: tag]];
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

#ifdef macosx
- (void) wait {

  /* ask current thread to wait on condition */

  /* initialize mutex lock */
  pthread_mutex_init( &soundMutex, NULL );

  /* initialize condition for waiting */
  pthread_cond_init ( &soundCondition, NULL );

  /* acquire the lock */
  pthread_mutex_lock( &soundMutex );

  /* wait */
  pthread_cond_wait( &soundCondition, &soundMutex );

  /* relinguish the lock */
  pthread_mutex_unlock( &soundMutex );

  return;
}
#endif

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
#if defined(macosx)

  if (soundPlaying)
    stopRequest = YES;

  return;

#elif defined(USE_PERFORM_SOUND_IO)
    NSNumber *tagNumber = [NSNumber numberWithInt: tag];

    if (tag) {
        SNDStop(tag);
    }
    if (status == NX_SoundRecording || status == NX_SoundRecordingPaused) {
        [playRecTable removeObjectForKey: tagNumber];
        status = NX_SoundStopped;
        [self tellDelegate:@selector(didRecord:)];	
    }
    if (status == NX_SoundPlaying || status == NX_SoundPlayingPaused) {
        [playRecTable removeObjectForKey: tagNumber];
        status = NX_SoundStopped;
        [self tellDelegate:@selector(didPlay:)];	
    }
    if(tag) {
        tag = 0;
    }
#endif // macosx
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

    if (soundStruct)
        SndFree(soundStruct);

    if (name) {
        free(name);
        name = NULL;
    }

    // check its seekable, by checking its POSIX regular.
    fileAttributeDictionary = [fileManager fileAttributesAtPath: filename
					   traverseLink: YES];

    if([fileAttributeDictionary objectForKey: NSFileType] != NSFileTypeRegular)
        return SND_ERR_CANNOT_OPEN;

    err = SndReadSoundfile([filename cString], &soundStruct);

    // soundStructDescription(soundStruct);
    if (!err)
        soundStructSize = soundStruct->dataLocation + soundStruct->dataSize;

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
    switch (conversionQuality) {
        case SND_CONVERT_LOWQ:
        default:
            err = SndConvertSound(soundStruct, &toSound);
            break;
        case SND_CONVERT_MEDQ:
            err = SndConvertSoundGoodQuality(soundStruct, &toSound);
            break;
        case SND_CONVERT_HIQ:
            err = SndConvertSoundHighQuality(soundStruct, &toSound);
    }
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
    if ((err = SndCompactSamples(&newStruct, soundStruct))) return err;
    if ((err = SndFree(soundStruct))) return err;
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
{   return soundStruct; }

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

- (void)tellDelegate:(SEL)theMessage
{
    if (delegate)
        if ([delegate respondsToSelector:theMessage])
            [delegate performSelector:theMessage withObject:self];
}
- (void)setConversionQuality:(int)quality /* default is SND_CONVERT_LOWQ */
{
    conversionQuality = quality;
}
- (int)conversionQuality
{
    return conversionQuality;
}

#ifdef macosx

- (int) bufferCount {

  return bufferCount;
}

- (int) bufferFrameSize {

  return bufferFrameSize;
}


- (float *) bufferEven {

  return bufferEven;
}

- (float *) bufferOdd {

  return bufferOdd;
}

- (pthread_t *) soundThread {

  return &soundThread;
}

- (pthread_cond_t *) soundCondition {

  return &soundCondition;
}

- (pthread_mutex_t *) soundMutex {

  return &soundMutex;
}

#endif

@end
