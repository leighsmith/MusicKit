/*
  $Id$

	Substantially based on Sound Kit, Release 2.0
	Copyright (c) 1988, 1989, 1990, NeXT, Inc.  All rights reserved.
	Additions Copyright (c) 1999 Stephen Brandon and the University of Glasgow 
*/

#import <Foundation/Foundation.h>
//#import <Foundation/NSObject.h>
//#import <Foundation/NSBundle.h>

/* The following define maps most sound I/O functions to the SoundKit counterparts,
 * for OpenStep 4.2 Intel and m68k (black NeXT) machines. You could try it on PPC
 * MacOS-X machines if you wanted to, but this may then conflict with the ppc/YBWin
 * code for using NSSound objects for sound playback.
 */
#if !defined(macosx)
#define macosx (defined(__ppc__) && !defined(ppc))
#define macosx_server (defined(__ppc__) && defined(ppc))
#endif

#import <MKPerformSndMIDI/PerformSound.h>
#import "sounderror.h"
#import "SndFunctions.h"

/* Define this for compatibility */
#define NXSoundPboard NXSoundPboardType

extern NSString *NXSoundPboardType;

@class NSPasteboard;
@class SndPlayer;
@class SndPerformance;

/*
 * This is the sound pasteboard type.
 */
@interface Snd : NSObject
/*
 * The Snd object encapsulates a SndSoundStruct, which represents a sound.
 * It supports reading and writing to a soundfile, playback of sound,
 * recording of sampled sound, conversion among various sampled formats, 
 * basic editing of the sound, and name and storage management for sounds.
 */
 {
 @private
    SndSoundStruct *soundStruct; /* the sound data structure */
    int soundStructSize;	 /* the length of the structure in bytes */
    int priority;		 /* the priority of the sound */
    id delegate;		 /* the target of notification messages */
    int status;			 /* what the object is currently doing */
    NSString *name;		 /* The name of the sound */
    SndSoundStruct *_scratchSnd;
    int _scratchSize;
    int currentError;
    int conversionQuality;	 /* see defines below */
    
@public
    int tag;
}
#define SND_CONVERT_LOWQ 0
#define SND_CONVERT_MEDQ 1
#define SND_CONVERT_HIQ  2

/*
 * Status codes
 */
typedef enum {
    SND_SoundStopped = 0,
    SND_SoundRecording,
    SND_SoundPlaying,
    SND_SoundInitialized,
    SND_SoundRecordingPaused,
    SND_SoundPlayingPaused,
    SND_SoundRecordingPending,
    SND_SoundPlayingPending,
    SND_SoundFreed = -1,
} SNDSoundStatus;

// legacy compatible
#if !defined(USE_NEXTSTEP_SOUND_IO) && !defined(USE_PERFORM_SOUND_IO) || defined(WIN32)
typedef enum {
    NX_SoundStopped = SND_SoundStopped,
    NX_SoundRecording = SND_SoundRecording,
    NX_SoundPlaying = SND_SoundPlaying,
    NX_SoundInitialized = SND_SoundInitialized,
    NX_SoundRecordingPaused = SND_SoundRecordingPaused,
    NX_SoundPlayingPaused = SND_SoundPlayingPaused,
    NX_SoundRecordingPending = SND_SoundRecordingPending,
    NX_SoundPlayingPending = SND_SoundPlayingPending,
    NX_SoundFreed = SND_SoundFreed,
} NXSoundStatus;
#endif


/*
 * Macho segment name where sounds may be.
 */
#ifndef NX_SOUND_SEGMENT_NAME
#define NX_SOUND_SEGMENT_NAME "__SND"
#endif

/*
 * --------------- Factory Methods
 */

+ soundNamed:(NSString *)aName;
+ findSoundFor:(NSString *)aName;

+ addName:(NSString *)name sound:aSnd;
+ addName:(NSString *)name fromSoundfile:(NSString *)filename;
+ addName:(NSString *)name fromSection:(NSString *)sectionName;
+ addName:(NSString *)aName fromBundle:(NSBundle *)aBundle;

+ (void) removeSoundForName:(NSString *)name;

/*!
    @method removeAllSounds
    @abstract Remove all named sounds in the name table.
*/
+ (void) removeAllSounds;

+ getVolume:(float *)left :(float *)right;
+ setVolume:(float)left :(float)right;
+ (BOOL)isMuted;
+ setMute:(BOOL)aFlag;
+ (NSArray *) soundFileExtensions;

- (NSString *) description;

- initFromSoundfile:(NSString *)filename;
- initFromSection:(NSString *)sectionName;
- initFromPasteboard:(NSPasteboard *)thePboard;

- (void)dealloc;
- readSoundFromStream:(NSData *)stream;
- writeSoundToStream:(NSMutableData *)stream;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;
- awakeAfterUsingCoder:(NSCoder *)aDecoder;
- (NSString *)name;
- setName:(NSString *)theName;
- delegate;
- (void)setDelegate:(id)anObject;
- (double)samplingRate;
- (int)sampleCount;
- (double)duration;
- (int)channelCount;
- (char *)info;
- (int)infoSize;

/*!
    @method play
    @abstract Play the entire sound now.
    @result Returns SND_ERR_NONE if the sound played correctly.
*/
- (int) play;

/*!
    @method play:
    @abstract Play the entire sound now, for use as an action method.
    @param sender The sending object.
    @result Returns self if play occured correctly, nil if there was an error.
*/
- play:sender;

/*!
    @method playInFuture:beginSample:sampleCount:
    @abstract Begin playback at some time in the future, over a region of the sound.
    @param inSeconds The number of seconds beyond the current time point to begin playback.
    @param begin The sample number to begin playing from. Use 0 to play from the start of the sound.
    @param count The number of samples to play. Use sampleCount to play the entire sound.
    @result Returns the performance that represents the sound playing.
*/
- (SndPerformance *) playInFuture: (double) inSeconds beginSample: (int) begin sampleCount: (int) count;

/*!
    @method play:beginSample:sampleCount:
    @abstract Begin playback now, over a region of the sound.
    @discussion This is a deprecated method for SoundKit compatability. 
                You should use playInFuture:beginSample:sampleCount: instead.
    @param begin The sample number to begin playing from. Use 0 to play from the start of the sound.
    @param count The number of samples to play. Use sampleCount to play the entire sound.
    @result Returns self
*/
- play:(id) sender beginSample:(int) begin sampleCount:(int) count;

/*!
    @method playInFuture:
    @abstract Begin the playback of the sound at some future time, specified in seconds.
    @param inSeconds The number of seconds beyond the current time point to begin playback.
    @result Returns the performance that represents the sound playing.
*/
- (SndPerformance *) playInFuture: (double) inSeconds;

/*!
    @method playAtDate:
    @abstract Begin the playback of the sound at a specified date.
    @param date The date to begin playback.
    @result Returns the performance that represents the sound playing.
*/
- (SndPerformance *) playAtDate: (NSDate *) date;

- record:sender;
- (int)record;
- (int)samplesProcessed;
- (int)status;
- (int)waitUntilStopped;

/*!
    @method stopPerformance:inFuture:
    @abstract Stop the given playback of the sound at some future time, specified in seconds.
    @param inSeconds The number of seconds beyond the current time point to begin playback.
    @param performance The performance that represents the sound playing. 
*/
+ (void) stopPerformance: (SndPerformance *) performance inFuture: (double) inSeconds;
- (void)stop:(id)sender;
- (int)stop;
- pause:sender;
- (int)pause;
- resume:sender;
- (int)resume;
- (int)readSoundfile:(NSString *)filename;
- (int)writeSoundfile:(NSString *)filename;
- (void)writeToPasteboard:(NSPasteboard *)thePboard;
- (BOOL)isEmpty;
- (BOOL)isEditable;
- (BOOL)compatibleWith:(Snd *)aSound;
- (BOOL)isPlayable;
- (int)convertToFormat:(int)aFormat
	   samplingRate:(double)aRate
	   channelCount:(int)aChannelCount;
- (int)convertToFormat:(int)aFormat;
- (int)deleteSamples;
- (int)deleteSamplesAt:(int)startSample count:(int)sampleCount;
- (int)insertSamples:(Snd *)aSnd at:(int)startSample;
- (id) copyWithZone: (NSZone *) zone;
- (int)copySound:(Snd *)aSnd;
- (int)copySamples:(Snd *)aSnd at:(int)startSample count:(int)sampleCount;
- (int)compactSamples;
- (BOOL)needsCompacting;
- (unsigned char *)data;
- (int)dataSize;
- (int)dataFormat;
- (int)setDataSize:(int)newDataSize
     dataFormat:(int)newDataFormat
     samplingRate:(double)newSamplingRate
     channelCount:(int)newChannelCount
     infoSize:(int)newInfoSize;
- (SndSoundStruct *)soundStruct;
- (int)soundStructSize;
- setSoundStruct:(SndSoundStruct *)aStruct soundStructSize:(int)aSize;
- (SndSoundStruct *)soundStructBeingProcessed;
- (int)processingError;
- soundBeingProcessed;
// delegations which are not nominated per performance.
- (void)tellDelegate:(SEL)theMessage;
// delegations which are nominated per performance.
- (void) tellDelegate:(SEL)theMessage duringPerformance: (SndPerformance *) performance;

- (void)_setStatus:(int)newStatus; /* Private! not for general use. */

    /*************************
     * these methods are unique
     * to SndKit.
     *************************/
- (void)setConversionQuality:(int)quality; /* default is SND_CONVERT_LOWQ */
- (int)conversionQuality;

@end

@interface SndDelegate : NSObject
- willRecord: sender;
- didRecord:  sender;
- hadError:   sender;
- willPlay:   sender duringPerformance: (SndPerformance *) performance;
- didPlay:    sender duringPerformance: (SndPerformance *) performance;
@end

