/*
  $Id$

	Substantially based on Sound Kit, Release 2.0
	Copyright (c) 1988, 1989, 1990, NeXT, Inc.  All rights reserved.
	Additions Copyright (c) 1999 Stephen Brandon and the University of Glasgow 
*/
#ifndef __SND_H__
#define __SND_H__

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

/*!
    @class      Snd 
    @abstract   The Snd object encapsulates a SndSoundStruct, which represents a sound.
                It supports reading and writing to a soundfile, playback of sound,
                recording of sampled sound, conversion among various sampled formats, 
                basic editing of the sound, and name and storage
		management for sounds.

    @discussion 

Snd objects represent and manage sounds. A Snd object's sound can be
recorded from a microphone, read from a sound file or NSBundle
resource, retrieved from the pasteboard or from the sound segment in
the application's executable file, or created algorithmically. The Snd
class also provides an application-wide name table that lets you
identify and locate sounds by name.

Playback and recording are performed by background threads, allowing
your application to proceed in parallel. The latency between sending a
<b>play:</b> or <b>record:</b> message and the start of the playback
or recording, while within the tolerance demanded by most
applications, can be further decreased by first reserving the sound
facilities that you wish to use. This is done by calling the
<b>SNDReserve()</b> C function.

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
*/

@interface Snd : NSObject
{
 @private
/*! @var soundStruct the sound data structure */
    SndSoundStruct *soundStruct;  
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
/*! @var _scratchSnd */
    SndSoundStruct *_scratchSnd;
/*! @var _scratchSize */
    int _scratchSize;
/*! @var currentError */
    int currentError;
/*! @var conversionQuality Determines quality of sampling rate conversion - see quality defines */
    int conversionQuality;	 
    
@public
/*! @var tag A unique identifier tag for the Snd */
    int tag;
}



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

/*!
  @method findSoundFor:
  @param  aName is a NSString *.
  @result Returns an id.
  @discussion Finds and returns the named Snd object. First the named Snd
              table is searched; if the sound isn't found, then the method looks
              for <i>&#ldquo;aName</i>.snd&#rdquo; in the sound segment of the
              application's executable file. Finally, <i>the file</i> is searched
              for in the following directories (in order):
              
              &#183;	~/Library/Sounds
              &#183;	/LocalLibrary/Sounds
              &#183;	/NextLibrary/Sounds
              
              where <b>~</b> represents the user's home directory.
              If the Snd eludes the search, <b>nil</b> is returned.
*/
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


/*!
  @method getVolume::
  @param  left is a float *.
  @param  right is a float *.
  @result Returns an id.
  @discussion  Returns, by reference, the stereo output levels as floating-point
              numbers between 0.0 and 1.0.
*/
+ getVolume:(float *)left :(float *)right;

/*!
  @method setVolume::
  @param  left is a float.
  @param  right is a float.
  @result Returns an id.
  @discussion  Sets the stereo output levels. These affect the volume of the
              stereo signals sent to the built-in speaker and headphone jacks.
              <i>left</i> and <i>right</i> must be floating-point numbers between
              0.0 (minimum) and 1.0 (maximum). If successful, returns<b> self</b>;
              otherwise returns <b>nil</b>.
*/
+ setVolume:(float)left :(float)right;

/*!
  @method isMuted
  @result Returns a BOOL.
  @discussion Returns YES if the sound output level is currently
              muted.
*/
+ (BOOL)isMuted;

/*!
  @method setMute:
  @param  aFlag is a BOOL.
  @result Returns an id.
  @discussion Mutes and unmutes the sound output level as <i>aFlag</i> is YES or
              NO, respectively. If successful, returns<b> self</b>; otherwise
              returns <b>nil</b>.
*/
+ setMute:(BOOL)aFlag;

/*!
  @method soundFileExtensions
  @result Returns an array of file extensions available for reading and writing.
  @discussion Returns an array of file extensions indicating the file format (and file extension)
              that audio files may be read from or written to. This list may be used for limiting NSOpenPanel
              to those formats supported. The list can be expected to vary between platforms, but is ultimately
              derived from those formats supported by the underlying Sox library.
*/
+ (NSArray *) soundFileExtensions;

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
- initFromSoundfile:(NSString *)filename;

/*!
  @method initFromSection:
  @param  sectionName is a NSString *.
  @result Returns an id.
  @discussion Initializes the Snd instance, which must be newly allocated, by
              copying the sound data from section <i>sectionName</i> of the sound
              segment of the application's executable file. If the section isn't
              found, the object looks for a sound file named <i>sectionName</i> in
              the same directory as the application's executable.   Returns
              <b>self</b> (an unnamed Snd) if the sound data was successfully
              copied; otherwise, frees the newly allocated Snd and returns
              <b>nil</b>.
              
              See also:	+<b>alloc</b> (NSObject), +<b>allocWithZone:</b> (NSObject)
*/
- initFromSection:(NSString *)sectionName;

/*!
  @method initFromPasteboard:
  @param  thePboard is a NSPasteboard *.
  @result Returns an id.
  @discussion Initializes the Snd instance, which must be newly allocated, by
              copying the sound data from the Pasteboard object <i>thePboard</i>.
              (A Pasteboard can have only one sound entry at a time.) Returns
              <b>self</b> (an unnamed Snd) if <i>thePboard</i> currently
              contains a sound entry; otherwise, frees the newly allocated Snd
              and returns <b>nil</b>.
              
              See also:	+<b>alloc</b> (NSObject), + <b>allocWithZone:</b> (NSObject)
*/
- initFromPasteboard:(NSPasteboard *)thePboard;

- (void)dealloc;

/*!
  @method readSoundFromStream:
  @param  stream is a NSData *.
  @result Returns a BOOL.
  @discussion Replaces the Snd's contents with those of the sound in the
              NXStream <i>stream</i>. The Snd is given the name of the sound in
              the NXStream. If the sound in the NXStream is named, the Snd gets
              the new name. Returns YES if the sound was read successfully, NO
              otherwise.
*/
- readSoundFromStream:(NSData *)stream;

/*!
  @method writeSoundToStream:
  @param  stream is a NXStream *.
  @discussion Writes the Snd's name (if any), priority, SndSoundStruct, and
              sound data (if any) to the NXStream <i>stream</i>.
*/
- writeSoundToStream:(NSMutableData *)stream;

- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;
- awakeAfterUsingCoder:(NSCoder *)aDecoder;

/*!
  @method name
  @result Returns a NSString *.
  @discussion Returns the Snd's name.
*/
- (NSString *)name;

/*!
  @method setName:
  @param  aName is a NSString *.
  @result Returns a BOOL.
  @discussion Sets the Snd's name to <i>aName</i>. If <i>aName</i> is already
              being used, then the Snd's name isn't set and NO is returned;
              otherwise returns YES.
*/
- setName:(NSString *)theName;

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
- (void)setDelegate:(id)anObject;

/*!
  @method samplingRate
  @result Returns a double.
  @discussion Returns the Snd's sampling rate.
*/
- (double)samplingRate;

/*!
  @method sampleCount
  @result Returns an int.
  @discussion Returns the number of sample frames, or channel count-independent
              samples, in the Snd.
*/
- (int)sampleCount;

/*!
  @method duration
  @result Returns a double.
  @discussion Returns the Snd's length in seconds.
*/
- (double)duration;

/*!
  @method channelCount
  @result Returns an int.
  @discussion Returns the number of channels in the Snd.
*/
- (int)channelCount;

/*!
  @method info
  @result Returns a char *.
  @discussion Returns a pointer to the Snd's info string.
*/
- (char *)info;

/*!
  @method infoSize
  @result Returns an int.
  @discussion Returns the size (in bytes) of the Snd's info string.
*/
- (int)infoSize;

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
- (int)record;

/*!
  @method samplesProcessed
  @result Returns an int.
  @discussion If the Snd is currently playing or recording, this returns the
              number of sample frames that have been played or recorded so far.
              Otherwise, the number of sample frames in the Snd is returned. If
              the sample frame count can't be determined, -1 is
              returned.
*/
- (int)samplesProcessed;

/*!
  @method status
  @result Returns an int.
  @discussion Return the Snd's current status, one of the following integer
              constants:
              
              &#183;	NX_SoundStopped
              &#183;	NX_SoundRecording
              &#183;	NX_SoundPlaying
              &#183;	NX_SoundInitialized
              &#183;	NX_SoundRecordingPaused
              &#183;	NX_SoundPlayingPaused
              &#183;	NX_SoundRecordingPending
              &#183;	NX_SoundPlayingPending
              &#183;	NX_SoundFreed
*/
- (int)status;

/*!
  @method waitUntilStopped
  @result Returns an int.
  @discussion If the Snd is currently playing or recording, waits until the
              sound has finished playing or recording, at which time it returns
              the result of the <b>SNDWait() </b>function. If the Snd is not
              playing or recording when <b>waitUntilStopped</b> is invoked, it
              returns SND_ERROR_NONE.
*/
- (int)waitUntilStopped;

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
- (void)stop:(id)sender;

/*!
  @method stop
  @result Returns an int.
  @discussion Terminates the Snd's playback or recording. If the Snd was
              recording, the <b>didRecord:</b> message is sent to the delegate; if
              playing, <b>didPlay:</b> is sent. An error code is
              returned.
*/
- (int)stop;

/*!
  @method pause:
  @param  sender is an id.
  @discussion Action method that pauses the Snd. Other than the argument and the
              return type, this is the same as the <b>pause</b>
              method.
*/
- pause:sender;

/*!
  @method pause
  @result Returns an int.
  @discussion Pauses the Snd during recording or playback. An error code is
              returned.
*/
- (int)pause;

/*!
  @method resume:
  @param  sender is an id.
  @discussion Action method that resumes the paused Snd.
*/
- resume:sender;

/*!
  @method resume
  @result Returns an int.
  @discussion Resumes the paused Snd's activity. An error code is
              returned.
*/
- (int)resume;

/*!
  @method sndPlayer
  @result Returns the static SndPlayer object used by the Snd class.
  @discussion The Snd class holds a static SndPlayer object to which all
              playing Snds are attached. If you wish to query this object
              or set performance attributes such as <b>setRemainConnectedToManager:</b>
              you can get it using this method.
*/
+ (SndPlayer *)sndPlayer;

/*!
  @method readSoundfile:
  @param  filename is a NSString *.
  @result Returns an int.
  @discussion Replaces the Snd's contents with those of the sound file
              <i>filename</i>. The Snd loses its current name, if any. An error
              code is returned.
*/
- (int)readSoundfile:(NSString *)filename;

/*!
  @method writeSoundfile:
  @param  filename is a NSString *.
  @result Returns an int.
  @discussion Writes the Snd's contents (its SndSoundStruct and sound data) to
              the sound file <i>filename</i>. An error code is
              returned.
*/
- (int)writeSoundfile:(NSString *)filename;

/*!
  @method writeToPasteboard:
  @param  thePboard is a NSPasteboard *.
  @result Returns an int.
  @discussion Puts a copy of the Snd's contents (its SndSoundStruct and sound
              data) on the pasteboard maintained by the NSPasteboard object
              <i>thePboard</i>. If the Snd is fragmented, it's compacted before
              the copy is created. An error code is returned.
*/
- (void)writeToPasteboard:(NSPasteboard *)thePboard;

/*!
  @method isEmpty
  @result Returns a BOOL.
  @discussion Returns <b>YES</b> if the Snd doesn't contain any sound data,
              otherwise returns <b>NO</b>. This always returns <b>NO</b> if the
              Snd isn't editable (as determined by sending it the
              <b>isEditable</b> message).
*/
- (BOOL)isEmpty;

/*!
  @method isEditable
  @result Returns a BOOL.
  @discussion Returns <b>YES</b> if the Snd's format indicates that it can be
              edited, otherwise returns <b>NO</b>.
*/
- (BOOL)isEditable;

/*!
  @method compatibleWith:
  @param  aSound is an id.
  @result Returns a BOOL.
  @discussion Returns <b>YES</b> if the format, sampling rate, and channel count
              of <i>aSound</i>'s sound data is the same as that of the Snd
              receiving this message. If one (or both) of the Snds doesn't
              contain a sound (its <b>soundStruct</b> is <b>nil</b>) then the
              objects are declared compatible and <b>YES</b> is returned.
              
*/
- (BOOL)compatibleWith:(Snd *)aSound;

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
- (BOOL)isPlayable;


/*!
  @method convertToFormat:
  @param  newFormat is an int.
  @param  newRate is a double.
  @param  newChannelCount is an int.
  @result Returns an int.
  @discussion Convert the Snd's data to the given format,
              sampling rate, and number of channels. The following conversions are
              possible:
              
              &#183;	Arbitrary sampling rate conversion.
              &#183;	Compression and decompression.
              &#183;	Floating-point formats (including double-precision) to and from linear formats.
              &#183;	Mono to stereo.
              &#183;	CODEC mu-law to and from linear formats.

              An error code is returned.
*/
- (int)convertToFormat:(int)aFormat
	   samplingRate:(double)aRate
	   channelCount:(int)aChannelCount;

/*!
  @method convertToFormat:
  @param  newFormat is an int.
  @result Returns an int.
  @discussion This is the same as
              <b>convertToFormat:samplingRate:channelCount:</b>,
              except that only the format is changed. An error code is
              returned.  
*/
- (int)convertToFormat:(int)aFormat;

/*!
  @method deleteSamples
  @result Returns an int.
  @discussion Deletes all the samples in the Snd's data. The Snd must be
              editable. An error code is returned.
*/
- (int)deleteSamples;

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
- (int)deleteSamplesAt:(int)startSample count:(int)sampleCount;

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
- (int)insertSamples:(Snd *)aSnd at:(int)startSample;

- (id) copyWithZone: (NSZone *) zone;

/*!
  @method copySound:
  @param  aSound is an id.
  @result Returns an int.
  @discussion Replaces the Snd's data with a copy of <i>aSound</i>'s data. The
              Snd receiving this message needn't be editable, nor must the two
              Snds be compatible. An error code is returned.
*/
- (int)copySound:(Snd *)aSnd;

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
- (int)copySamples:(Snd *)aSnd at:(int)startSample count:(int)sampleCount;

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
- (int)compactSamples;

/*!
  @method needsCompacting
  @result Returns a BOOL.
  @discussion Returns <b>YES</b> if the Snd's data is fragmented. Otherwise
              returns <b>NO</b>.
*/
- (BOOL)needsCompacting;

/*!
  @method data
  @result Returns an unsigned char *.
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
- (unsigned char *)data;

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
- (int)dataSize;

/*!
  @method dataFormat
  @result Returns an int.
  @discussion Returns the format of the Snd's data. If the data is fragmented,
              the format of the samples is returned (in other words,
              SND_FORMAT_INDIRECT is never returned by this method).
*/
- (int)dataFormat;

/*!
  @method setDataSize:dataFormat:samplingRate:channelCount:infoSize:
  @param  newDataSize is an int.
  @param  newDataFormat is an int.
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
- (int)setDataSize:(int)newDataSize
     dataFormat:(int)newDataFormat
     samplingRate:(double)newSamplingRate
     channelCount:(int)newChannelCount
     infoSize:(int)newInfoSize;

/*!
  @method soundStruct
  @result Returns a SndSoundStruct *.
  @discussion Returns a pointer to the Snd's SndSoundStruct structure that holds
              the object's sound data.
*/
- (SndSoundStruct *)soundStruct;

/*!
  @method soundStructSize
  @result Returns an int.
  @discussion Returns the size, in bytes, of the Snd's sound structure (pointed
              to by <b>soundStruct</b>). Use of this value requires a knowledge of
              the SndSoundStruct architecture.
*/
- (int)soundStructSize;

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
              NX_SoundInitialized or NX_SoundStopped for this method to do
              anything.
*/
- setSoundStruct:(SndSoundStruct *)aStruct soundStructSize:(int)aSize;

/*!
  @method soundStructBeingProcessed
  @result Returns a SndSoundStruct *.
  @discussion Returns a pointer to the SndSoundStruct structure that's being
              performed. This may not be the same structure as returned by the
              <b>soundStruct</b> method - Snd object's contain a private sound
              structure that may be used for recording playing. If the Snd isn't
              currently playing or recording, then this will return the public
              structure.
*/
- (SndSoundStruct *)soundStructBeingProcessed;

/*!
  @method processingError
  @result Returns an int.
  @discussion Returns a constant that represents the last error that was
              generated. The sound error codes are listed in &#ldquo;Types and
              Constants.&#rdquo;
*/
- (int)processingError;

/*!
  @method soundBeingProcessed
  @result Returns an id.
  @discussion Returns the Snd object that's being performed. The default
              implementation always returns <b>self</b>.
*/
- soundBeingProcessed;

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
- (void)tellDelegate:(SEL)theMessage;

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
- (void) tellDelegate:(SEL)theMessage duringPerformance: (SndPerformance *) performance;


    /*************************
     * these methods are unique
     * to SndKit.
     *************************/
- (void)setConversionQuality:(int)quality; /* default is SND_CONVERT_LOWQ */

- (int)conversionQuality;


- (void)_setStatus:(int)newStatus; /* Private! not for general use. */

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
  @enum       SNDSoundConversion 
  @abstract   Sound conversion quality codes
  @constant   SND_CONVERT_LOWQ Low quality
  @constant   SND_CONVERT_MEDQ Medium quality
  @constant   SND_CONVERT_HIQ  High quality
*/
typedef enum {
    SND_CONVERT_LOWQ = 0,
    SND_CONVERT_MEDQ = 1,
    SND_CONVERT_HIQ  = 2
} SNDSoundConversionQuality;

/*!
  @enum       SNDSoundStatus
  @abstract   Status Codes
  @discussion Categorizes beverages into groups of similar types.
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


#endif
