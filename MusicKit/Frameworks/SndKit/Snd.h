/*
	Snd.h
	Substantially based on Sound Kit, Release 2.0
	Copyright (c) 1988, 1989, 1990, NeXT, Inc.  All rights reserved.
	Additions Copyright (c) 1999 Stephen Brandon and the University of Glasgow 
*/

#import <Foundation/NSObject.h>
#import <Foundation/Foundation.h>
#import <objc/hashtable.h>
#import <Foundation/NSBundle.h>

/* The following define maps most sound I/O functions to the SoundKit counterparts,
 * for OpenStep 4.2 Intel and m68k (black NeXT) machines. You could try it on PPC
 * MacOS-X machines if you wanted to, but this may then conflict with the ppc/YBWin
 * code for using NSSound objects for sound playback.
 */
#if !defined(macosx)
#define macosx (defined(__ppc__) && !defined(ppc))
#define macosx_server (defined(__ppc__) && defined(ppc))
#endif

#if defined(NeXT) 
  #define USE_NEXTSTEP_SOUND_IO
  #define USE_PERFORM_SOUND_IO
#elif macosx_server
  #define USE_PERFORM_SOUND_IO
  #import "Sound.h"
#elif defined(WIN32)
  #define USE_PERFORM_SOUND_IO
  #import <MKPerformSndMIDI/PerformSound.h>
  #import "sounderror.h"
#endif

#ifdef USE_PERFORM_SOUND_IO
#import "SndFormats.h"
#endif

#import "SndFunctions.h"

@class NSPasteboard;

/* Define this for compatibility */
#define NXSoundPboard NXSoundPboardType

extern NSString *NXSoundPboardType;
;
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
#if defined(__ppc__) || defined(WIN32)
    id plSound;			 /* NSSound object for playback */
#endif
@public
    int tag;
}
#define SND_CONVERT_LOWQ 0
#define SND_CONVERT_MEDQ 1
#define SND_CONVERT_HIQ  2

#if !defined(USE_NEXTSTEP_SOUND_IO) && !defined(USE_PERFORM_SOUND_IO) || defined(WIN32)
/*
 * Status codes
 */
typedef enum {
    NX_SoundStopped = 0,
    NX_SoundRecording,
    NX_SoundPlaying,
    NX_SoundInitialized,
    NX_SoundRecordingPaused,
    NX_SoundPlayingPaused,
    NX_SoundRecordingPending,
    NX_SoundPlayingPending,
    NX_SoundFreed = -1,
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

+ (void)removeSoundForName:(NSString *)name;

+ getVolume:(float *)left :(float *)right;
+ setVolume:(float)left :(float)right;
+ (BOOL)isMuted;
+ setMute:(BOOL)aFlag;

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
- play:sender;
- (int)play;
- record:sender;
- (int)record;
- (int)samplesProcessed;
- (int)status;
- (int)waitUntilStopped;
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
- (void)tellDelegate:(SEL)theMessage;
- (void)_setStatus:(int)newStatus; /* Private! not for general use. */

    /*************************
     * these methods are unique
     * to SndKit.
     *************************/
- (void)setConversionQuality:(int)quality; /* default is SND_CONVERT_LOWQ */
- (int)conversionQuality;

@end

@interface SndDelegate : NSObject
- willRecord:sender;
- didRecord:sender;
- willPlay:sender;
- didPlay:sender;
- hadError:sender;
@end

