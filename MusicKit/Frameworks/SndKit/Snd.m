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
 * Revision 1.14  2001/02/16 21:30:03  leigh
 * Added description function and SndPlayer usage, replacing Snd() functions with streams
 *
 * Revision 1.13  2001/02/14 17:54:28  leigh
 * Renamed status messages to SND prefixes
 *
 * Revision 1.12  2001/02/12 18:30:45  leigh
 * Added autorelease pools for begin and end functions for play
 *
 * Revision 1.11  2001/02/11 03:15:22  leigh
 * Factored all platform specific code for playback and recording into MKPerformSndMIDI.framework
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h> /* for memmove() */
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSApplication.h>

#import "Snd.h"
#import "SndPlayer.h"

#ifndef USE_NEXTSTEP_SOUND_IO
NSString *NXSoundPboardType = @"NXSoundPboardType";
#endif

@implementation Snd

static NSAutoreleasePool *pool;
static NSMutableDictionary *nameTable = nil;
static NSMutableDictionary *playRecTable = nil;
static int ioTags = 1000;
static SndPlayer *sndPlayer;

+ (void)initialize
{
    char **driverNames;
    pool = [[NSAutoreleasePool alloc] init];
    if ( self == [Snd class] ) {
        nameTable = [[NSMutableDictionary alloc] initWithCapacity:10];
        SNDInit(TRUE);
        driverNames = SNDGetAvailableDriverNames();
        NSLog(@"driver selected is %s\n", driverNames[SNDGetAssignedDriverIndex()]);
        sndPlayer = [[SndPlayer player] retain];
    }
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
        newSound = [[Snd alloc] initFromSoundfile: path];
        if (newSound) {
            [Snd addName: aName sound: newSound];
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
    SNDGetVolume(left, right);
    return [self class];
}

+ setVolume:(float)left :(float)right
{
    SNDSetVolume(left, right);
    return [self class];
}

+ (BOOL)isMuted
{
    return SNDIsMuted();
}

+ setMute:(BOOL)aFlag
{
    SNDSetMute(aFlag);
    return self;
}

- init
{
    name = nil;
    conversionQuality = SND_CONVERT_LOWQ;
    delegate = nil;
    status = SND_SoundInitialized;

    currentError = 0;
    _scratchSnd = NULL;
    _scratchSize = 0;
    tag = 0;

    /*
    soundStruct = (SndSoundStruct *) calloc( 1, sizeof(SndSoundStruct) );

    soundStruct->magic = SND_MAGIC;
    soundStruct->dataLocation = sizeof(SndSoundStruct);
    soundStruct->dataSize = 0;
    soundStruct->dataFormat = SND_FORMAT_UNSPECIFIED;
    */

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
    [super dealloc];
}

// for debugging
- (NSString *) description
{
    return [NSString stringWithCString: SndStructDescription(soundStruct)];
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

//  SndPrintStruct(s);
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
    status = SND_SoundInitialized;
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

//	SndPrintStruct(s);

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
    status = SND_SoundInitialized;
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

// Since these two functions come in from the cold, they warm and snug autorelease pools...
int beginFun(SndSoundStruct *sound, int tag, int err)
{
    Snd *theSnd;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    theSnd = [playRecTable objectForKey: [NSNumber numberWithInt: tag]];
    // NSLog(@"beginFun theSnd = %x, err = %d tag = %d\n", theSnd, err, tag);
    if (err) {
        [theSnd _setStatus:SND_SoundStopped];
        [theSnd tellDelegate:@selector(hadError:)];
    }
    else {
        [theSnd _setStatus:SND_SoundPlaying];
        [theSnd tellDelegate:@selector(willPlay:)];
    }
    [pool release];
    return 0;
}

int endFun(SndSoundStruct *sound, int tag, int err)
{
    Snd *theSnd;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSNumber *tagNumber = [NSNumber numberWithInt: tag];

    theSnd = [playRecTable objectForKey: tagNumber];
    // NSLog(@"endFun theSnd = %x, err = %d tag = %d\n", theSnd, err, tag);
    [theSnd _setStatus:SND_SoundStopped];
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
    [pool release];
    return 0;
}

int beginRecFun(SndSoundStruct *sound, int tag, int err)
{
    Snd *theSnd;
    theSnd = [playRecTable objectForKey: [NSNumber numberWithInt: tag]];
    if (err) {
        [theSnd _setStatus:SND_SoundStopped];
        [theSnd tellDelegate:@selector(hadError:)];
    }
    else {
        [theSnd _setStatus:SND_SoundRecording];
        [theSnd tellDelegate:@selector(willRecord:)];
    }
    return 0;
}

int endRecFun(SndSoundStruct *sound, int tag, int err)
{
    Snd *theSnd;
    NSNumber *tagNumber = [NSNumber numberWithInt: tag];

    theSnd = [playRecTable objectForKey: tagNumber];
    [theSnd _setStatus:SND_SoundStopped];
    printf("End recording error: %d\n",err);
    if (err == SND_ERR_ABORTED) err = SND_ERR_NONE;
    if (err) [theSnd tellDelegate:@selector(hadError:)];
    else [(Snd *)theSnd tellDelegate:@selector(didRecord:)];
    [playRecTable removeObjectForKey: tagNumber];
    ((Snd *)theSnd)->tag = 0;
    return 0;
}

// [sndPlayer playSnd: self];
// 

// Begin the playback of the sound at some future time, specified in seconds.
- play: (id) sender inFuture: (double) inSeconds 
{
#if 0
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
    status = SND_SoundPlayingPending;
    err = SNDUnreserve(3);
    if(err) {
        NSLog(@"Unreserving error %d\n", err);
    }
    err = SNDStartPlaying((SndSoundStruct *)soundStruct,
            ioTags++ /*	int tag			*/,
            1 /*	int priority	*/,
            0 /*	int preempt		*/, 
            (SNDNotificationFun) beginFun,
            (SNDNotificationFun) endFun);
    if (err) NSLog(@"Playback error %d\n",err);
#else
    [sndPlayer playSnd: self withTimeOffset: inSeconds];
#endif
    return self;
}

- play:sender
{
    return [self play: sender inFuture: 0.0];
}

- (int)play
{
    [self play:self];
    return SND_ERR_NONE;
}

- play:(id) sender beginSample:(int) begin sampleCount: (int) count 
{
    int playBegin = begin;
    int playEnd = begin + count;
    
    if (playBegin > [self sampleCount] || playBegin < 0)
        playBegin = 0;
    
    if (playEnd > [self sampleCount] || playEnd < playBegin)
        playEnd = [self sampleCount];
    
    return [self play: sender];
}

- play: (id) sender atDate: (NSDate *) date
{
//    return [self play: sender inFuture: [date dateInSeconds]];
}

- record:sender
{
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
    status = SND_SoundRecordingPending;
    err = SNDStartRecording((SndSoundStruct *)soundStruct,
            ioTags++, /*	int tag			*/
            9, /*	int priority	*/
            1, /*	int preempt		*/
            (SNDNotificationFun) beginRecFun,
            (SNDNotificationFun) endRecFun);
    return self;
}

- (int)record
{
    [self record:self];
    return SND_ERR_NONE;
}

- (int)samplesProcessed
{
    return (tag == 0) ? -1 : SNDSamplesProcessed(tag);
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
    NSNumber *tagNumber = [NSNumber numberWithInt: tag];

    if (tag) {
        SNDStop(tag);
    }
    if (status == SND_SoundRecording || status == SND_SoundRecordingPaused) {
        [playRecTable removeObjectForKey: tagNumber];
        status = SND_SoundStopped;
        [self tellDelegate:@selector(didRecord:)];	
    }
    if (status == SND_SoundPlaying || status == SND_SoundPlayingPaused) {
        [playRecTable removeObjectForKey: tagNumber];
        status = SND_SoundStopped;
        [self tellDelegate:@selector(didPlay:)];	
    }
    if(tag) {
        tag = 0;
    }
}

- (int)stop
{
    [self stop:self];
    return SND_ERR_NONE;
}

- pause:sender
{
    return self;
}

- (int)pause
{
    return SND_ERR_NOT_IMPLEMENTED;
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

    // SndPrintStruct(soundStruct);
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
    status = SND_SoundInitialized;
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
    status = SND_SoundInitialized;
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

- (SndSoundStruct *) soundStruct
{
    return soundStruct;
}

- (int) soundStructSize
/* if the sound is fragmented, returns only the size of the FIRST fragment */
{
    if (!soundStruct) return 0;
    if (soundStruct->dataFormat != SND_FORMAT_INDIRECT)
        return soundStruct->dataSize + soundStruct->dataLocation;
    else
        return soundStruct->dataSize; /* see SndFunctions.h */
}

- setSoundStruct:(SndSoundStruct *)aStruct soundStructSize:(int)aSize
{
    if (status != SND_SoundInitialized && status != SND_SoundStopped)
            return nil;
    if (soundStruct && soundStruct != aStruct) SndFree(soundStruct);
    soundStruct = aStruct;
    soundStructSize = aSize;
    return self;
}

/* when we implement i/o, need to return different */
- (SndSoundStruct *) soundStructBeingProcessed
{
    return soundStruct;
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

- (void) tellDelegate:(SEL)theMessage
{
    if (delegate) {
        if ([delegate respondsToSelector:theMessage]) {
            [delegate performSelector:theMessage withObject:self];
        }
    }
}

- (void) setConversionQuality:(int)quality /* default is SND_CONVERT_LOWQ */
{
    conversionQuality = quality;
}

- (int) conversionQuality
{
    return conversionQuality;
}

@end
