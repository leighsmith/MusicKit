////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description: Main class defining a sound object.
//    Designed to emulate some Sound Kit behaviour.
//
//  Original Author: Stephen Brandon
//
//  Copyright (c) 1999 Stephen Brandon and the University of Glasgow
//  Additions Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Legal Statement Covering Work by Stephen Brandon and the University of Glasgow:
//
//    This framework and all source code supplied with it, except where specified,
//    are Copyright Stephen Brandon and the University of Glasgow, 1999. You are free
//    to use the source code for any purpose, including commercial applications, as
//    long as you reproduce this notice on all such software.
//
//    Software production is complex and we cannot warrant that the Software will be
//    error free.  Further, we will not be liable to you if the Software is not fit
//    for the purpose for which you acquired it, or of satisfactory quality.
//
//    WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL
//    WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES
//    OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD
//    PARTIES RIGHTS.
//
//    If a court finds that we are liable for death or personal injury caused by our
//    negligence our liability shall be unlimited.
//
//    WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS
//    OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR
//    POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE
//    NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED
//    DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND
//    CONDITIONS OF THIS AGREEMENT.
//
// Legal Statement Covering Additions by The MusicKit Project:
//
//    Permission is granted to use and modify this code for commercial and
//    non-commercial purposes so long as the author attribution and copyright
//    messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SND_H__
#define __SND_H__

#import <Foundation/Foundation.h>
#import "SndFormat.h"

@class SndPlayer;
@class SndPerformance;
@class SndAudioBuffer;
@class SndAudioProcessorChain;

/*!
@class Snd
@abstract The Snd object encapsulates a sounds format parameters and it's sample data.
          It supports reading and writing to a soundfile, playback of sound,
          recording of sampled sound, conversion among various sampled formats, 
          basic editing of the sound, and name and storage
          management for sounds. It holds parameters that prime it's performance at the start of play.

@discussion 

Snd objects represent and manage sounds. A Snd object's sound can be
recorded from a microphone, read from a sound file or NSBundle
resource, retrieved from the pasteboard or from the sound segment in
the application's executable file, or created algorithmically. The Snd
class also provides an application-wide name table that lets you
identify and locate sounds by name.

Playback and recording are performed by background threads, allowing
your application to proceed in parallel. By using preemption of queueing,
the latency between sending a <b>play:</b> or <b>record:</b> message and
the start of the playback or recording, is no more than the duration of
one hardware buffer.

You can also edit a Snd object by adding and removing samples. To
minimize data movement (and thus save time), an edited Snd may become
fragmented; in other words, its sound data might become discontiguous
in memory. While playback of a fragmented Snd object is transparent,
it does incur some overhead. If you perform a number of edits you may
want to return the Snd to a contiguous state by sending it a
<b>compactSamples</b> message before you play it. However, a large Snd
may take a long time to compact, so a judicious and well-timed use of
<b>compactSamples</b> is advised. Fragmented Snds are automatically
compacted before they're copied to a pasteboard (through the
<b>writeToPasteboard:</b> method). Also, when you write a Snd to a
sound file, the data in the file will be compact regardless of the
state of the object.

A Snd object contains a SndSoundStruct, the structure that describes
and contains sound data and that's used as the sound file format and
the pasteboard sound type. Most of the methods defined in the Snd
class are implemented so that you needn't be aware of this
structure. However, if you wish to directly manipulate the sound data
in a Snd object, you need to be familiar with the SndSoundStruct
architecture, as described in the <b>SndStruct</b> header.

<H3>Sound Conversion Features</H3>

The sample rate conversion routines (in particular) come from Julius Smith
(resample-1.2), but have been modified to not require compacting of fragmented
sound files. Additionally, they will accept 8 bit, float and double input,
although the output is always 16 bit. So although you can convert sampling
rates of float data, it has to go through an intermediate 16 bit
stage for the rate conversion. Sorry.

There are 3 different qualities of sample rate conversion, described by SndConversionQuality.
The fastest conversion is of the lowest quality. The Snd object uses the fastest one by default, but you
can set the quality to be used with the -setConversionQuality method.

The sound conversion routines (in general) basically convert from any
sampling rate, any number of channels (<= 16), 8, 16 bit, float and double
formats to any other combination of the above, in as
few passes as possible. When changing numbers of channels, you can change
from 1 to many, many to 1, or any power of 2 to any other power of 2
(eg 2 to 8, 4 to 2, 2 to 16 etc).

*/

/*!
  @enum       SndConversionQuality
  @abstract   Sound conversion quality codes
  @constant   SndConvertLowQuality Low quality conversion, using linear interpolation.
  @constant   SndConvertMediumQuality Medium quality conversion. Uses bandlimited interpolation,
              using a small filter. Relatively fast.
  @constant   SndConvertHighQuality High quality conversion. Uses bandlimited interpolation, using a
  	      large filter. Relatively slow.
 */
typedef enum {
    SndConvertLowQuality = 0,
    SndConvertMediumQuality = 1,
    SndConvertHighQuality  = 2
} SndConversionQuality;

@interface Snd : NSObject
{
 @protected
/*! @var soundStruct <p>The sound data structure.</p>
  <p>This is defined in the MKPerformSndMIDI framework as follows:</p>
  <pre>
  <b>typedef struct</b> {
    int magic;
    int dataLocation;
    int dataSize;
    int dataFormat;
    int samplingRate;
    int channelCount;
    char info[4];
  } SndSoundStruct;
  </pre>
  */
    SndSoundStruct *soundStruct; // TODO this is deprecated in favour of soundFormat.
    /*! @var soundFormat The parameters defining the format of the sound. */
    SndFormat soundFormat;
    /*! @var info A descriptive information string read from a sound file. */
    NSString *info;
    /*! @var soundStructSize the length of the structure in bytes */
    int soundStructSize;

    /*! @var priority the priority of the sound */
    int priority;		 
    /*! @var delegate the target of notification messages */
    id delegate;		 
    /*! @var status what the object is currently doing */
    int status;			 
    /*! @var name The name of the sound */
    NSString *name;
    /*! @var currentError */
    int currentError;
    /*! @var conversionQuality Determines quality of sampling rate conversion - see quality defines */
    SndConversionQuality conversionQuality;	 

    /*! @var performancesArray An array of all active AND pending performances of this Snd */
    NSMutableArray *performancesArray;
    /*! @var performancesArrayLock An NSLock to protect the performancesArray */
    NSLock *performancesArrayLock;

    /*! @var loopWhenPlaying Indicates whether the default behaviour is to loop when playing.
	This is set from reading the sound file.
     */
    BOOL loopWhenPlaying;
    /*! @var loopStartIndex The sample the loop begins at. This is just the priming value for each performance. */
    long loopStartIndex;
    /*! @var loopEndIndex The sample the loop ends at. This is just the priming value for each performance. */
    long loopEndIndex;

    /*! @var audioProcessorChain Typically used to prime a performance of this Snd with a chain of audio effects
	including volume and balance settings (via it's postFader). 
     */
    SndAudioProcessorChain *audioProcessorChain;
        
@public
/*! @var tag A unique identifier tag for the Snd */
    int tag;
}

/*
 * --------------- Factory Methods
 */

+ soundNamed: (NSString *) aName;

/*!
  @method findSoundFor:
  @param  aName is a NSString *.
  @result Returns an id.
  @discussion Finds and returns the named Snd object. First the named Snd
              table is searched; if the sound isn't found, then the method looks
              for <i>&#ldquo;aName</i>.snd&#rdquo; in the sound segment of the
              application's executable file. Finally, <i>the file</i> is searched
              for in the following directories (in order):

	      <UL>
              <LI>~/Library/Sounds</LI>
              <LI>/LocalLibrary/Sounds</LI>
              <LI>/NextLibrary/Sounds</LI>
	      </UL>
              
              where <b>~</b> represents the user's home directory.
              If the Snd eludes the search, <b>nil</b> is returned.
*/
+ findSoundFor: (NSString *) aName;

/*!
  @method     addName:sound:
  @abstract
  @param  	  name
  @param  	  aSnd
  @result
  @discussion
*/
+ addName: (NSString *) name sound: (Snd *) aSnd;
/*!
  @method     addName:fromSoundfile:
  @abstract
  @param      name
  @param      filename
  @result
  @discussion
*/
+ addName: (NSString *) name fromSoundfile: (NSString *) filename;
/*!
  @method     addName:fromSection:
  @abstract
  @param      name
  @param  	  sectionName
  @result
  @discussion
*/
+ addName: (NSString *) name fromSection: (NSString *) sectionName;
/*!
  @method     addName:fromBundle:
  @abstract
  @param      aName
  @param  	  aBundle
  @result
  @discussion
*/
+ addName: (NSString *) aName fromBundle: (NSBundle *) aBundle;

/*!
  @method     removeSoundForName: 
  @abstract
  @param      name
  @result
  @discussion
*/
+ (void) removeSoundForName: (NSString *) name;

/*!
    @method removeAllSounds
    @abstract Remove all named sounds in the name table.
*/
+ (void) removeAllSounds;

/*!
  @method isMuted
  @result Returns a BOOL.
  @discussion Returns YES if the sound output of all playing sounds is currently
              muted.
*/
+ (BOOL) isMuted;

/*!
  @method setMute:
  @param  aFlag is a BOOL.
  @result Returns an id.
  @discussion Mutes and unmutes the sound output level of all playing sounds if <i>aFlag</i> is YES or
              NO, respectively. If successful, returns <b>self</b>; otherwise
              returns <b>nil</b>.
*/
+ setMute: (BOOL) aFlag;

/*!
  @method soundFileExtensions
  @result Returns an array of file extensions available for reading and writing.
  @discussion Returns an array of file extensions indicating the file format (and file extension)
              that audio files may be read from or written to. This list may be used for limiting NSOpenPanel
              to those formats supported. The list can be expected to vary between platforms, but is ultimately
              derived from those formats supported by the underlying Sox library.
*/
+ (NSArray *) soundFileExtensions;

/*!
 @method isPathForSoundFile:
 @param path A file path
 @result TRUE if the file at path is a sound file.
 */
+ (BOOL) isPathForSoundFile: (NSString*) path;

/*!
  @method defaultFileExtension
*/
+ (NSString *) defaultFileExtension;

- (NSString *) description;

/*!
  @method initFromSoundfile:
  @param  filename is a NSString *.
  @result Returns an id.
  @discussion Initializes the Snd instance, which must be newly allocated, from
              the sound file <i>filename</i>.   Returns <b>self</b> (an unnamed
              Snd) if the file was successfully read; otherwise, frees the newly
              allocated Snd and returns <b>nil</b>.
              
              See also:	+<b>alloc</b> (NSObject), +<b>allocWithZone:</b> (NSObject)
*/
- initFromSoundfile: (NSString *) filename;

/*!
  @method initFromSoundURL:
  @param  url is a NSURL *.
  @result Returns an id.
  @discussion Initializes the Snd instance, which must be newly allocated, by
              copying the sound data from the possibly remote sound file located using
              <i>url</i>. Returns <b>self</b> (an unnamed Snd) if <i>url</i> can retrieve
              a sound file; otherwise, frees the newly allocated Snd and returns <b>nil</b>.

     See also:	<b>initFromSoundfile:</b>, +<b>alloc</b> (NSObject), +<b>allocWithZone:</b> (NSObject)
  */
- initFromSoundURL: (NSURL *) url;

/*!
  @method initWithFormat:channelCount:frames:samplingRate:
  @param  format
  @param  channels
  @param  frames
  @param  samplingRate
  @result Returns self
*/
- initWithFormat: (SndSampleFormat) format
    channelCount: (int) channels
          frames: (int) frames
    samplingRate: (float) samplingRate;

/*!
  @method initWithData:
  @abstract Initialise a Snd instance using a NSData instance which holds audio data in Sun/NeXT .au format.
  @discussion The data is held with format preceding the PCM audio data.
  @param soundData An NSData instance containing preceding sound format data followed by PCM audio data, in Sun/NeXT .au format.
  @result Returns self
 */
- initWithData: (NSData *) soundData;

- (void) dealloc;

/*!
  @method readSoundFromData:
  @param  stream is a NSData instance.
  @result Returns a BOOL.  Returns YES if the sound was read successfully, NO otherwise.
  @discussion Replaces the Snd's contents with those of the sound in the
              NSData instance <i>stream</i>. If the sound in the NSData is named,
              the Snd gets the new name.
			  <B>Currently only reads Sun/NeXT .au format files</B>.
*/
- readSoundFromData: (NSData *) stream;

/*!
  @method writeSoundToData:
  @param  stream is an NSMutableData instance.
  @discussion Writes the Snd's name (if any), priority, sample format, and
              sound data (if any) to the NSMutableData <i>stream</i>.
*/
- writeSoundToData: (NSMutableData *) stream;

/*!
  @method      swapBigEndianToHostFormat
  @discussion  The swapBigEndianToHostFormat method swaps the byte order of the receiver if it
               is running on a little-endian (e.g Intel) architecture, and has no effect on a big-endian
               (e.g Motorola 68k, PPC) architecture.
               Note that no checks are done as to whether or not the receiver was
               already byte-swapped, so you have to keep track of the status of
               Snd objects yourself.<br>
               Always use the appropriate method to convert your Snd objects; either
               swapBigEndianToHostFormat to convert a Snd from the pasteboard or from a soundfile,
               or swapHostToBigEndianFormat to prepare a Snd which was in host order to be saved
               or put onto the pasteboard.
  @result      void
 */
- (void) swapBigEndianToHostFormat;

/*!
  @method      swapHostToBigEndianFormat
  @discussion  The swapHostToBigEndianFormat method swaps the byte order of the receiver if it
               is running on a little-endian (e.g Intel) architecture, and has no effect on a big-endian
               (e.g Motorola 68k, PPC) architecture.
               Note that no checks are done as to whether or not the receiver was
               already byte-swapped, so you have to keep track of the status of
               Snd objects yourself.<br>
               Always use the appropriate method to convert your Snd objects; either
               swapBigEndianToHostFormat to convert a Snd from the pasteboard or from a soundfile,
               or swapHostToBigEndianFormat to prepare a Snd which was in host order to be saved
               or put onto the pasteboard.
  @result      void
 */
- (void) swapHostToBigEndianFormat;

- (void) encodeWithCoder: (NSCoder *) aCoder;
- (id) initWithCoder: (NSCoder *) aDecoder;
- awakeAfterUsingCoder: (NSCoder *) aDecoder;

/*!
  @method name
  @result Returns a NSString *.
  @discussion Returns the Snd's name.
*/
- (NSString *) name;

/*!
  @method setName:
  @param  aName is a NSString *.
  @result Returns a BOOL.
  @discussion Sets the Snd's name to <i>aName</i>. If <i>aName</i> is already
              being used, then the Snd's name isn't set and NO is returned;
              otherwise returns YES.
*/
- setName: (NSString *) theName;

/*!
  @method delegate
  @result Returns an id.
  @discussion Returns the Snd's delegate.
*/
- delegate;

/*!
  @method setDelegate:
  @param  anObject is an id.
  @discussion Sets the Snd's delegate to <i>anObject</i>.
*/
- (void) setDelegate: (id) anObject;

/*!
  @method samplingRate
  @result Returns a double.
  @discussion Returns the Snd's sampling rate.
*/
- (double) samplingRate;

/*!
  @method lengthInSampleFrames
  @result Returns an int.
  @discussion Returns the number of sample frames, or channel count-independent
              samples, in the Snd.
*/
- (unsigned long) lengthInSampleFrames;

/*!
  @method duration
  @result Returns a double.
  @discussion Returns the Snd's length in seconds.
*/
- (double) duration;

/*!
  @method channelCount
  @result Returns an int.
  @discussion Returns the number of channels in the Snd.
*/
- (int) channelCount;

/*!
  @method info
  @abstract Returns the Snd's info string.
  @discussion The Snd's info string is any text description the user of the object wishes to assign to it.
              It will however, endeavour to be written in an appropriate field to any sound file written from this Snd instance.
			  It will be retrieved from an appropriate field when reading a sound file.
  @result Returns an NSString.
*/
- (NSString *) info;

/*!
  @method setInfo:
  @abstract Assigns the Snd's info string.
  @discussion The Snd's info string is any text description the user of the object wishes to assign to it.
              It will however, endeavour to be written in an appropriate field to any sound file written from this Snd instance.
  @param newInfoString An NSString containing the new text.
 */
- (void) setInfo: (NSString *) newInfoString;

/*!
    @method play
    @abstract Play the entire sound now.
    @result Returns SND_ERR_NONE if the sound played correctly.
    @discussion Initiates playback of the Snd. The method returns immediately
              while the playback continues asynchronously in the background. The
              playback ends when the Snd receives the <b>stop</b> message, or
              when its data is exhausted.

              When playback starts, <b>willPlay:</b> is sent to
              the Snd's delegate; when it stops, <b>didPlay:</b> is sent. An
              error code is returned.
              
              <b>Warning:</b> For this method to work properly, the main event loop must not be blocked.
*/
- (int) play;

/*!
    @method play:
    @abstract Play the entire sound now, for use as an action method.
    @param sender The sending object.
    @result Returns self if play occured correctly, nil if there was an error.
*/
- play: (id) sender;

/*!
    @method playInFuture:beginSample:sampleCount:
    @abstract Begin playback at some time in the future, over a region of the sound.
    @param inSeconds The number of seconds beyond the current time point to begin playback.
    @param begin The sample number to begin playing from. Use 0 to play from the start of the sound.
    @param count The number of samples to play. Use sampleCount to play the entire sound.
    @result Returns the performance that represents the sound playing.
*/
- (SndPerformance *) playInFuture: (double) inSeconds
		      beginSample: (unsigned long) begin
		      sampleCount: (unsigned long) count;

/*!
  @method playInFuture:startPositionInSeconds:durationInSeconds:
  @abstract Begin playback at some time in the future, over a region of the sound.
  @param inSeconds The number of seconds beyond the current time point to begin playback.
  @param startPosition The time in seconds in the Snd to begin playing from.
                       Use 0.0 to play from the start of the sound.
  @param duration The duration of the Snd to play in seconds. Use -[Snd duration] to play the entire sound.
  @result Returns the performance that represents the sound playing.
 */
- (SndPerformance *) playInFuture: (double) inSeconds
           startPositionInSeconds: (double) startPosition
                durationInSeconds: (double) duration; 
/*!
    @method   playAtTimeInSeconds:withDurationInSeconds:
    @abstract Begin playback at a certain absolute stream time, for a certain duration.
    @param    t Start time in seconds
    @param    d Duration in seconds
    @result   Returns the performance that represents the sound playing.
*/
- (SndPerformance *) playAtTimeInSeconds: (double) t withDurationInSeconds: (double) d;

/*!
   @method play:beginSample:sampleCount:
   @abstract Begin playback now, over a region of the sound.
   @discussion This is a deprecated method for SoundKit compatability.
   You should use playInFuture:beginSample:sampleCount: instead.
   @param begin The sample number to begin playing from. Use 0 to play from the start of the sound.
   @param count The number of samples to play. Use sampleCount to play the entire sound.
   @result Returns self
*/
- play: (id) sender beginSample: (int) begin sampleCount: (int) count;

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

- record: (id) sender;

/*!
  @method record
  @result Returns an int.
  @discussion Initiate recording into the Snd. To record from the CODEC
              microphone, the Snd's format, sampling rate, and channel count
              must be SND_FORMAT_MULAW_8, SND_RATE_CODEC, and 1, respectively. If
              this information isn't set (if the Snd is a newly created object,
              for example), it defaults to accommodate a CODEC recording. If the
              Snd's format is SND_FORMAT_DSP_DATA_16, the recording is from the
              DSP.
              
              The method returns immediately while the recording
              continues asynchronously in the background. The recording stops when
              the Snd receives the <b>stop</b> message or when the recording has
              gone on for the duration of the original sound data. The default
              CODEC recording lasts precisely ten minutes if not stopped. To
              record for a longer time, first increase the size of the sound data
              with <b>setSoundStruct:soundStructSize:</b> or 
              <b>setDataSize:dataFormat:samplingRate:channelCount:infoSize:</b>.
              
              When the recording begins, <b>willRecord:</b> is
              sent to the Snd's delegate; when the recording stops,
              <b>didRecord:</b> is sent.
              
              An error code is returned.
              
              <b>Warning:</b> For this method to work properly, the main event loop must not be blocked.
*/
- (int) record;

/*!
  @method samplesPerformedOfPerformance:
  @param performance The SndPerformance of which to enquire.
  @result Returns an int.
  @discussion If the Snd is currently playing or recording, this returns the
              number of sample frames that have been played or recorded so far.
              Otherwise, the number of sample frames in the Snd is returned. If
              the sample frame count can't be determined, -1 is
              returned.
*/
- (int) samplesPerformedOfPerformance: (SndPerformance *) performance;

/*!
  @method status
  @result Returns an int.
  @discussion Return the Snd's current status, one of the following integer
              constants:
              <UL>
              <LI>	SND_SoundStopped</LI>
              <LI>	SND_SoundRecording</LI>
              <LI>	SND_SoundPlaying</LI>
              <LI>	SND_SoundInitialized</LI>
              <LI>	SND_SoundRecordingPaused</LI>
              <LI>	SND_SoundPlayingPaused</LI>
              <LI>	SND_SoundRecordingPending</LI>
              <LI>	SND_SoundPlayingPending</LI>
              <LI>	SND_SoundFreed</LI>
              </UL>
*/
- (int) status;

/*!
  @method waitUntilStopped
  @result Returns an int.
  @discussion If the Snd is currently playing or recording, waits until the
              sound has finished playing or recording, at which time it returns
              the result of the <b>SNDWait() </b>function. If the Snd is not
              playing or recording when <b>waitUntilStopped</b> is invoked, it
              returns SND_ERROR_NONE.
*/
- (int) waitUntilStopped;

/*!
    @method stopPerformance:inFuture:
    @abstract Stop the given playback of the sound at some future time, specified in seconds.
    @param inSeconds The number of seconds beyond the current time point to begin playback.
    @param performance The performance that represents the sound playing. 
*/
+ (void) stopPerformance: (SndPerformance *) performance inFuture: (double) inSeconds;

/*!
  @method stop:
  @param  sender is an id.
  @discussion Action method that stops the Snd's playback or recording. Other
              than the argument and the return type, this is the same as the
              <b>stop</b> method.
*/
- (void) stop: (id) sender;

/*!
  @method stop
  @result Returns an int.
  @discussion Terminates the Snd's playback or recording. If the Snd was
              recording, the <b>didRecord:</b> message is sent to the delegate; if
              playing, <b>didPlay:duringPerformance:</b> is sent. An error code is
              returned.
*/
- (int) stop;

/*!
  @method pause:
  @param  sender is an id.
  @discussion Action method that pauses the Snd. Other than the argument and the
              return type, this is the same as the <b>pause</b>
              method.
*/
- pause: (id) sender;

/*!
  @method pause
  @result Returns an int.
  @discussion Pauses the Snd during recording or playback. An error code is
              returned.
*/
- (int) pause;

/*!
  @method resume:
  @param  sender is an id.
  @discussion Action method that resumes the paused Snd.
*/
- resume: (id) sender;

/*!
  @method resume
  @result Returns an int.
  @discussion Resumes the paused Snd's activity. An error code is
              returned.
*/
- (int) resume;

/*!
  @method readSoundfile:
  @param  filename is a NSString *.
  @result Returns an int.
  @discussion Replaces the Snd's contents with those of the sound file
              <i>filename</i>. The Snd loses its current name, if any. An error
              code is returned.
*/
- (int) readSoundfile: (NSString *) filename;

/*!
  @method writeSoundfile:
  @param  filename is a NSString *.
  @result Returns an int.
  @discussion Writes the Snd's contents (its sample format and sound data) to
              the sound file <i>filename</i>. An error code is
              returned.
*/
- (int) writeSoundfile: (NSString *) filename;

/*!
  @method isEmpty
  @result Returns a BOOL.
  @discussion Returns <b>YES</b> if the Snd doesn't contain any sound data,
              otherwise returns <b>NO</b>. This always returns <b>NO</b> if the
              Snd isn't editable (as determined by sending it the
              <b>isEditable</b> message).
*/
- (BOOL) isEmpty;

/*!
  @method isEditable
  @result Returns a BOOL.
  @discussion Returns <b>YES</b> if the Snd's format indicates that it can be
              edited, otherwise returns <b>NO</b>.
*/
- (BOOL) isEditable;

/*!
  @method compatibleWithSound:
  @param  aSound is an id.
  @result Returns a BOOL.
  @discussion Returns <b>YES</b> if the format, sampling rate, and channel count
              of <i>aSound</i>'s sound data is the same as that of the Snd
              receiving this message. If one (or both) of the Snds doesn't
              contain a sound (its <b>soundStruct</b> is <b>nil</b>) then the
              objects are declared compatible and <b>YES</b> is returned.
              
*/
- (BOOL) compatibleWithSound: (Snd *) aSound;

/*!
  @method isPlayable
  @result Returns a BOOL.
  @discussion Returns <b>YES</b> if the Snd can be played, otherwise returns
              <b>NO</b>. Some unplayable Snds just need to be converted to
              another format, sampling rate, or number of channels; others are
              inherently unplayable, such as those whose format is
              SND_FORMAT_DISPLAY. To play a Snd that's just been recorded from
              the DSP, you must change its format from SND_FORMAT_DSP_DATA_16 to
              SND_FORMAT_LINEAR_16. 
*/
- (BOOL) isPlayable;

/*!
  @method isPlaying
  @result Returns a BOOL, YES if a sound has playing performances, NO if not.
  @discussion Returns <b>YES</b> if the Snd is currently playing one or more performances,
              otherwise returns <b>NO</b>.
 */
- (BOOL) isPlaying;

/*!
  @method convertToFormat:samplingRate:channelCount:
  @param  newFormat is an SndSampleFormat.
  @param  newRate is a double.
  @param  newChannelCount is an int.
  @result Returns an error code or SND_ERR_NONE if the conversion was performed correctly.
  @discussion Convert the Snd's data to the given format,
              sampling rate, and number of channels. The following conversions are
              possible:
	      <UL>
              <LI>Arbitrary sampling rate conversion.</LI>
              <LI>Compression and decompression.</LI>
              <LI>Floating-point formats (including double-precision) to and from linear formats.</LI>
              <LI>Mono to stereo.</LI>
              <LI>CODEC mu-law to and from linear formats.</LI>
	      </UL>
 */
- (int) convertToFormat: (SndSampleFormat) newFormat
	   samplingRate: (double) newRate
	   channelCount: (int) newChannelCount;

/*!
  @method convertToFormat:
  @param  newFormat is an SndSampleFormat.
  @result Returns an integer indicating any error or SND_ERR_NONE if the conversion worked.
  @discussion This is the same as
              <b>convertToFormat:samplingRate:channelCount:</b>,
              except that only the format is changed. An error code is
              returned.  
*/
- (int) convertToFormat: (SndSampleFormat) newFormat;

/*!
  @method nativeFormat
  @abstract Returns the native format (sampling rate, resolution and channels) used by the sound
            playback hardware in streaming audio.
  @discussion The native format is the format sounds loaded and audio buffers created in which
              will incur the least processing overhead in order to play. Recording could be in a different format.
  @result Returns a SndFormat structure.
 */
+ (SndFormat) nativeFormat;

/*!
  @method convertToNativeFormat:
  @result Returns an int.
  @discussion The Snd is converted to the format (sampling rate, resolution and channels) that
              the hardware natively uses. This should result in the fastest playback, avoiding any
	      on the fly conversions. An error code is returned.
 */
- (int) convertToNativeFormat;

/*!
  @method deleteSamples
  @result Returns an int.
  @discussion Deletes all the samples in the Snd's data. The Snd must be
              editable. An error code is returned.
*/
- (int) deleteSamples;

/*!
  @method deleteSamplesAt:count:
  @param  startSample is an int.
  @param  sampleCount is an int.
  @result Returns an int.
  @discussion Deletes a range of samples from the Snd: <i>sampleCount</i>
              samples are deleted starting with the <i>startSample</i>'th sample
              (zero-based). The Snd must be editable and may become fragmented.
              An error code is returned.
*/
- (int) deleteSamplesAt: (int) startSample count: (int) sampleCount;

/*!
  @method insertSamples:at:
  @param  aSound is an id.
  @param  startSample is an int.
  @result Returns an int.
  @discussion Pastes the sound data in <i>aSound</i> into the Snd receiving
              this message, starting at the receiving Snd's <i>startSample</i>'th sample (zero-based).
              The receiving Snd doesn't lose any of its original sound data - the samples greater than
              or equal to <i>startSample</i> are moved to accommodate the inserted sound data. The receiving
              Snd must be editable and the two Snds must be compatible (as determined by <b>isCompatible:</b>). If the method is successful, the receiving Snd is fragmented. An error code is returned.
*/
- (int) insertSamples: (Snd *) aSnd at: (int) startSample;


/*!
  @method copyWithZone:
  @param  zone is an NSZone.
  @result Returns a new retained instance with duplicated data, or nil if unable to copy.
*/
- (id) copyWithZone: (NSZone *) zone;

/*!
  @method copySamples:
  @param  aSound is an id.
  @param startSamplein an int.
  @param sampleCount is an int.
  @result Returns an int.
  @discussion             
              Replaces the Snd's sampled data with a copy of a
              portion of <i>aSound</i>'s data. The copied portion starts at
              <i>aSound</i>'s <i>startSample</i>'th sample (zero-based) and
              extends over <i>sampleCount</i> samples. The Snd receiving this
              message must be editable and the two Snds must be compatible. If
              the specified portion of <i>aSound</i> is fragmented, the Snd
              receiving this message will also be fragmented. An error code is
              returned.
*/
- (int) copySamples: (Snd *) aSnd at: (int) startSample count: (int) sampleCount;

/*!
  @method compactSamples
  @result Returns an int.
  @discussion The Snd's sampled data is compacted into a contiguous block,
              undoing the fragmentation that can occur during editing. If the

              Snd's data isn't fragmented (its format isn't
              SND_FORMAT_INDIRECT), then this method does
              nothing. Compacting a large sound can take a long time;
              keep in mind that when you copy a Snd to a pasteboard,
              the object is automatically compacted before it's
              copied. Also, the sound file representation of a Snd
              contains contiguous data so there's no need to compact a
              Snd before writing it to a sound file simply to ensure
              that the file representation will be compact. An error
              code is returned.  
*/
- (int) compactSamples;

/*!
  @method needsCompacting
  @result Returns a BOOL.
  @discussion Returns <b>YES</b> if the Snd's data is fragmented. Otherwise
              returns <b>NO</b>.
*/
- (BOOL) needsCompacting;

/*!
  @method data
  @result Returns a void *.
  @discussion Returns a pointer to the Snd's sampled data. You can use the
              pointer to examine, create, and modify the sound data. To
              intelligently manipulate the data, you need to be aware of its size,
              format, sampling rate, and the number of channels that it contains
              (a query method for each of these attributes is provided by the
              Snd class). The size of the data, in particular, must be
              respected; it's set when the Snd is created or given a new sound
              (through <b>readSoundfile:</b>, for example) and can't be changed
              directly. To resize the data, you should invoke one of the editing
              methods such as <b>insertSamples:at:</b> or
	      <b>deleteSamplesAt:count:</b>.

              To start with a new, unfragmented sound with a
              determinate length, invoke the
              <b>setDataSize:dataFormat:samplingRate:channelCount:infoSize:</b>
              method. Keep in mind that the sound data in a fragmented
              sound is a pointer to a <b>NULL</b>-terminated list of
              pointers to SndSoundStructs, one for each fragment. To
              examine or manipulate the samples in a fragmented sound,
              you must understand the SndSoundStruct structure.  
*/
- (void *) data;

/*!
  @method dataSize
  @result Returns an int.
  @discussion Return the size (in bytes) of the Snd's data. If you modify the
              data (through the pointer returned by the <b>data</b> method) you
              must be careful not to exceed its length. If the sound is
              fragmented, the value returned by this method is the size of the
              Snd's <b>soundStruct</b> and doesn't include the actual data
              itself.
*/
- (int) dataSize;

/*!
  @method dataFormat
  @result Returns an SndSampleFormat.
  @discussion Returns the format of the Snd's data. If the data is fragmented,
              the format of the samples is returned (in other words,
              SND_FORMAT_INDIRECT is never returned by this method).
*/
- (SndSampleFormat) dataFormat;

/*!
  @method hasSameFormatAsBuffer:
  @param buff The SndAudioBuffer instance to compare.
  @result Returns a BOOL.
  @discussion Returns YES if the Snd's dataFormat, channelCount and sampling rate match the given SndAudioBuffer instance.
              The number of samples are not compared.
 */
- (BOOL) hasSameFormatAsBuffer: (SndAudioBuffer *) buff;

/*!
  @method setDataSize:dataFormat:samplingRate:channelCount:infoSize:
  @param  newDataSize is an int.
  @param  newDataFormat is an SndSampleFormat.
  @param  newSamplingRate is a double.
  @param  newChannelCount is an int.
  @param  newInfoSize is an int.
  @result Returns an int.
  @discussion Allocates new, unfragmented sound data for the Snd, as described
              by the arguments. The Snd's previous data is freed. This method is
              useful for setting a determinate data length prior to a recording or
              for creating a scratch pad for algorithmic sound creation. An error
              code is returned.
*/
- (int) setDataSize: (int) newDataSize
         dataFormat: (SndSampleFormat) newDataFormat
       samplingRate: (double) newSamplingRate
       channelCount: (int) newChannelCount
           infoSize: (int) newInfoSize;

/*!
  @method soundStruct
  @result Returns a SndSoundStruct *.
  @discussion Returns a pointer to the Snd's SndSoundStruct structure that holds
              the object's sound data.
              TODO This will be changed to soundData and return an NSData instance.
*/
- (SndSoundStruct *) soundStruct;

/*!
  @method soundStructSize
  @result Returns an int.
  @discussion Returns the size, in bytes, of the Snd's sound structure (pointed
              to by <b>soundStruct</b>). Use of this value requires a knowledge of
              the SndSoundStruct architecture.
*/
- (int) soundStructSize;

/*!
  @method setSoundStruct:soundStructSize:
  @param  aStruct is a SndSoundStruct *.
  @param  size is an int.
  @discussion Sets the Snd's sound structure to <i>aStruct</i>. The size in
              bytes of the new structure, including its sound data storage, must
              be specified by <i>size</i>. This method can be used to set up a
              large buffer before recording into an existing Snd, by passing the
              existing <b>soundStruct</b> in the first argument while making
              <i>size</i> larger than the current size. (The default buffer holds
              ten minutes of CODEC sound.) The method is also useful in cases
              where <i>aStruct</i> already has sound data but isn't encapsulated
              in a Snd object yet. The Snd's status must be
              SND_SoundInitialized or SND_SoundStopped for this method to do
              anything.
              TODO This will be changed to setSoundData: (NSData *).
*/
- setSoundStruct: (SndSoundStruct *) aStruct soundStructSize: (int) aSize;

/*!
  @method processingError
  @result Returns an int.
  @discussion Returns a constant that represents the last error that was
              generated. The sound error codes are listed in &#ldquo;Types and
              Constants.&#rdquo;
*/
- (int) processingError;

/*!
  @method soundBeingProcessed
  @result Returns an id.
  @discussion Returns the Snd object that's being performed. The default
              implementation always returns <b>self</b>.
*/
- (Snd *) soundBeingProcessed;

// delegations which are not nominated per performance.

/*!
  @method tellDelegate:
  @param  theMessage is a SEL.
  @discussion Sends <i>theMessage</i> to the Snd's delegate (only sent if the
              delegate implements <i>theMessage</i>). You never invoke this method
              directly; it's invoked automatically as the result of activities
              such as recording and playing. However, you can use it in designing
              a subclass of Snd.
*/
- (void) tellDelegate: (SEL) theMessage;

// delegations which are nominated per performance.

/*!
  @method tellDelegate:
  @param  theMessage is a SEL.
  @discussion Sends <i>theMessage</i> to the Snd's delegate (only sent if the
              delegate implements <i>theMessage</i>). You never invoke this method
              directly; it's invoked automatically as the result of activities
              such as recording and playing. However, you can use it in designing
              a subclass of Snd.
*/
- (void) tellDelegate: (SEL) theMessage duringPerformance: (SndPerformance *) performance;

/*!
  @method tellDelegateString:
  @param  theMessage is an NSString, which will be converted to a SEL.
  @discussion Sends <i>theMessage</i> to the Snd's delegate (only sent if the
              delegate implements <i>theMessage</i>). You never invoke this method
              directly; it's invoked automatically as the result of activities
              such as recording and playing. However, you can use it in designing
              a subclass of Snd.
*/
- (void) tellDelegateString: (NSString *) theMessage duringPerformance: (SndPerformance *) performance;


/*!
  @method setConversionQuality:
  @abstract Sets the conversion quality performed by convertToFormat:
  @param quality Sets the conversion quality to a SndConversionQuality enumerated type.
  @discussion Default is SndConvertLowQuality.
 */
- (void) setConversionQuality: (SndConversionQuality) quality;

/*!
  @method conversionQuality
  @abstract Returns the current conversion quality performed by convertToFormat:
  @result Returns a SndConversionQuality enumerated type.
*/
- (SndConversionQuality) conversionQuality;

- (void) _setStatus: (int) newStatus; /* Private! not for general use. */

/*!
  @method     performances
  @abstract   Performance array accessor.
  @result     NSArray of performances.
  @discussion Mainly for use by SndPlayer
*/
- (NSArray*) performances;
/*!
  @method     addPerformance:
  @abstract   Adds a performance to the pwerformance array.
  @param      p A performance
  @result     self
  @discussion Mainly for use by SndPlayer
*/
- addPerformance: (SndPerformance *) p;
/*!
  @method     removePerformance:
  @abstract   Removes a performance from the performance array.
  @param      p A performance to be removed.
  @result     self
  @discussion Mainly for use by SndPlayer
*/
- removePerformance: (SndPerformance *) p;
/*!
  @method     performanceCount
  @abstract   returns the number of active AND pending performances 
  @result     self
  @discussion Mainly for use by SndPlayer
*/
- (int) performanceCount;

/*!
  @method audioBufferForSamplesInRange:looping:
  @abstract Returns a SndAudioBuffer containing a range of samples in the Snd.
  @param  sndFrameRange Range of sample <I>frames</I> (as opposed to individual single
 	    channel samples) to stick into the audioBuffer.
  @param isLooping Indicates whether to read from the loop start if the length of the sndFrameRange exceeds
          the length of the Snd instance.
  @result An SndAudioBuffer containing the samples in the range r.
 */
- (SndAudioBuffer *) audioBufferForSamplesInRange: (NSRange) sndFrameRange
					  looping: (BOOL) isLooping;

/*!
  @method audioBufferForSamplesInRange:
  @abstract Returns a SndAudioBuffer containing a range of samples in the Snd.
  @param  r Range of sample <I>frames</I> (as opposed to individual single
          channel samples) to stick into the audioBuffer
  @result An SndAudioBuffer containing the samples in the range r.
*/
- (SndAudioBuffer *) audioBufferForSamplesInRange: (NSRange) r;

/*!
  @method fillAudioBuffer:toLength:samplesStartingFrom:
  @abstract Copies samples from self into the provided SndAudioBuffer
  @discussion The SndAudioBuffer's data object's size is decreased if less than fillLength number
              of samples can be read. The buffer is not expanded.
  @param buff The SndAudioBuffer object into which to copy the data.
  @param fillLength The number of sample frames in the buffer to copy into.
  @param sndReadingRange The sample frame in the Snd to start reading from and maximum length of samples readable.
  @result Returns the number of sample frames read from the Snd instance in filling the audio buffer.
          This can be more or less than the number requested, if resampling occurs.
*/
- (long) fillAudioBuffer: (SndAudioBuffer *) buff
	        toLength: (long) fillLength
          samplesInRange: (NSRange) sndReadingRange;

/*!
  @method insertIntoAudioBuffer:intoFrameRange:samplesInRange:
  @abstract Copies samples from self into a sub region of the provided SndAudioBuffer.
  @discussion If the buffer and the Snd instance have different formats, a format
              conversion will be performed to the buffers format, including resampling
              if necessary. The Snd audio data will be read enough to fill the range of samples
              specified according to the sample rate of the buffer compared to the sample rate
              of the Snd instance. In the case where there are less than the needed number of
              samples left in the sndFrameRange to completely insert into the specified buffer region, the
              number of samples inserted will be returned less than bufferRange.length.
  @param buff The SndAudioBuffer object into which to copy the data.
  @param bufferRange An NSRange of sample frames (i.e channel independent time position specified in samples)
		     in the buffer to copy into.
  @param sndFrameRange An NSRange of sample frames (i.e channel independent time position specified in samples)
                       within the Snd to start reading data from and the last permissible index to read from.
  @result Returns the number of samples actually inserted. This may be less than the length specified
          in the bufferRange if sndStartIndex is less than the number samples needed to convert to
          insert in the specified buffer region.
 */
- (long) insertIntoAudioBuffer: (SndAudioBuffer *) buff
		intoFrameRange: (NSRange) bufferFrameRange
		samplesInRange: (NSRange) sndFrameRange;

/*!
  @method insertAudioBuffer:intoFrameRange:
  @abstract Copies in the given SndAudioBuffer into the Snd instance.
  @param buffer The SndAudioBuffer to copy sound from.
  @param writeIntoSndFrameRange The range of frames to copy. Can not be longer than the buffer.
  @result Returns the new size of the buffer.
 */
- (long) insertAudioBuffer: (SndAudioBuffer *) buffer
	    intoFrameRange: (NSRange) writeIntoSndFrameRange;

/*!
  @method appendAudioBuffer:
  @abstract Appends the given SndAudioBuffer to the end of the Snd instance.
  @param buffer The SndAudioBuffer to copy sound from.
  @result Returns the new size of the buffer.
 */
- (long) appendAudioBuffer: (SndAudioBuffer *) buffer;

/*!
  @method initWithAudioBuffer:
  @abstract Initialises a Snd instance from the provided SndAudioBuffer.
  @param aBuffer the SndAudioBuffer object from which to copy the data
  @result self
 */
- initWithAudioBuffer: (SndAudioBuffer *) aBuffer;

/*!
  @method normalise
  @abstract Normalises the amplitude of the entire sound.
  @discussion The highest amplitude sample in the sound is scaled to be the maximum resolution.
 */
- (void) normalise;

/*!
  @method     setLoopWhenPlaying:
  @abstract   Sets the default behaviour whether to loop during play.
  @param      yesOrNo Sets the default behaviour whether to loop during play.
 */
- (void) setLoopWhenPlaying: (BOOL) yesOrNo;

/*!
  @method     loopWhenPlaying
  @abstract   Returns whether the default behaviour is to loop during play.
  @result     Returns whether the default behaviour is to loop during play.
 */
- (BOOL) loopWhenPlaying;

/*!
  @method     setLoopStartIndex:
  @abstract   Sets the sample to stop playing at.
  @param      newEndAtIndex The sample index that playing should stop after.
  @discussion The loop start index may be changed while the sound is being performed and regardless of
              whether the performance is looping.
 */
- (void) setLoopStartIndex: (long) loopStartIndex;

/*!
  @method     loopStartIndex
  @abstract   Returns the sample to start playing at.
  @result     Returns the sample index to start playing at.
 */
- (long) loopStartIndex;

/*!
  @method     setLoopEndIndex:
  @abstract   Sets the sample at which the performance loops back to the start index (set using setLoopStartIndex:).
  @param      newLoopEndIndex The sample index at the end of the loop.
  @discussion This sample index is the last sample of the loop, i.e. it is the last sample heard before
              the performance loops, the next sample heard will be that returned by -<B>loopStartIndex</B>.
              The loop end index may be changed while the sound is being performed and regardless of whether
              the performance is looping.
 */
- (void) setLoopEndIndex: (long) newLoopEndIndex;

/*!
  @method     loopEndIndex
  @abstract   Returns the sample index at the end of the loop.
  @result     Returns the sample index ending the loop.
 */
- (long) loopEndIndex;

/*!
  @method     setAudioProcessorChain:
  @abstract   Assigns the audioProcessorChain to this Snd instance. 
  @discussion This is typically used during playback of the Snd, but could be used for any other (i.e offline processing of the Snd).
  @param newAudioProcessorChain A SndAudioProcessorChain instance.
 */
- (void) setAudioProcessorChain: (SndAudioProcessorChain *) newAudioProcessorChain;

/*!
  @method     audioProcessorChain
  @abstract   Returns the audioProcessorChain associated with this Snd instance. 
  @discussion This is typically used during playback of the Snd, but could be used for any other (i.e offline processing of the Snd).
  @result     Returns a SndAudioProcessorChain instance.
 */
- (SndAudioProcessorChain *) audioProcessorChain;

@end

@interface SndDelegate : NSObject

/*!
  @method willRecord:
  @param  sender is an id.
  @discussion Sent to the delegate when the Snd begins to record.
*/
- willRecord: sender;

/*!
  @method didRecord:
  @param  sender is an id.
  @discussion Sent to the delegate when the Snd stops recording.
*/
- didRecord:  sender;

/*!
  @method hadError:
  @param  sender is an id.
  @discussion Sent to the delegate if an error occurs during recording or
              playback.
*/
- hadError:   sender;

/*!
  @method willPlay:duringPerformance:
  @param  sender is an id.
  @param  performance is a SndPerformance *.
  @discussion Sent to the delegate when the Snd begins to play.
*/
- willPlay:   sender duringPerformance: (SndPerformance *) performance;

/*!
  @method didPlay:duringPerformance:
  @param  sender is an id.
  @param  performance is a SndPerformance *.
  @discussion Sent to the delegate when the Snd stops playing.
*/
- didPlay:    sender duringPerformance: (SndPerformance *) performance;

@end

/*!
  @enum       SNDSoundStatus
  @abstract   Status Codes
  @discussion Categorizes beverages, err sounds into groups of similar types.
  @constant   SND_SoundStopped
  @constant   SND_SoundRecording
  @constant   SND_SoundPlaying
  @constant   SND_SoundInitialized
  @constant   SND_SoundRecordingPaused
  @constant   SND_SoundRecordingPending
  @constant   SND_SoundPlayingPending
  @constant   SND_SoundFreed
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

#endif
