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
  @enum       SndConversionQuality
  @brief   Sound conversion quality codes
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


/*!
@class Snd
@brief The Snd object encapsulates a sounds format parameters and it's sample data.
          It supports reading and writing to a soundfile, playback of sound,
          recording of sampled sound, conversion among various sampled formats, 
          basic editing of the sound, and name and storage
          management for sounds.

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
one hardware buffer. A Snd holds parameters that prime it's performance
at the start of play including a SndAudioProcessor for effects processing,
volume and panning.

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

A Snd object contains an NSArray of SndAudioBuffers, the structure that describes
and contains sound data. Most of the methods defined in the Snd class are implemented 
so that you needn't be aware of this structure.

<H3>Sound Conversion Features</H3>

The sample rate conversion routines (in particular) come from Julius Smith
(resample-1.2), but have been modified to not require compacting of fragmented
sound files. Additionally, they will accept 8 bit, float and double input,
although the output is always 16 bit. So although you can convert sampling
rates of float data, it has to go through an intermediate 16 bit
stage for the rate conversion. Sorry.

There are 3 different qualities of sample rate conversion, described by SndConversionQuality.
The fastest conversion is of the lowest quality. The Snd object uses the fastest one by default, but you
can set the quality to be used with the -setConversionQuality: method.

The sound conversion routines (in general) basically convert from any
sampling rate, any number of channels (<= 16), 8, 16 bit, float and double
formats to any other combination of the above, in as
few passes as possible. When changing numbers of channels, you can change
from 1 to many, many to 1, or any power of 2 to any other power of 2
(eg 2 to 8, 4 to 2, 2 to 16 etc).

*/

@interface Snd : NSObject
{
 @protected
    /*! An array of SndAudioBuffers, the number of elements will depend on the fragmentation. */
    NSMutableArray *soundBuffers; 
    /*! The parameters defining the format of the sound. */
    SndFormat soundFormat;
    /*! A descriptive information string read from a sound file. */
    NSString *info;

    /*! The priority of the sound - currently unused. */
    int priority;		 
    /*! The target of notification messages */
    id delegate;		 
    /*! The name of the sound, typically less verbose than the info string which can be descriptive. */
    NSString *name;
    /*! The code of the most recently occurring error. Zero if no error. */
    int currentError;
    /*! Determines quality of sampling rate conversion - see quality defines */
    SndConversionQuality conversionQuality;	 

    /*! An array of all active AND pending performances of this Snd */
    NSMutableArray *performancesArray;
    /*! An NSLock to protect the performancesArray when playing. */
    NSLock *performancesArrayLock;

    /*! An NSRecursiveLock to protect concurrent modifying of a sound. */
    NSRecursiveLock *editingLock;
    
    /*! Indicates whether the default behaviour is to loop when playing. This is set from reading the sound file. */
    BOOL loopWhenPlaying;
    /*! The sample the loop begins at. This is just the priming value for each performance. */
    long loopStartIndex;
    /*! The sample the loop ends at. This is just the priming value for each performance. */
    long loopEndIndex;

    /*! Typically used to prime a performance of this Snd with a chain of audio effects including volume and balance settings (via it's postFader). */
    SndAudioProcessorChain *audioProcessorChain;
        
@public
    /*! A unique identifier tag for the Snd */
    int tag;
}

/*
 * --------------- Factory Methods
 */

+ soundNamed: (NSString *) aName;

/*!
  @param  aName is a NSString instance.
  @return Returns an id.
  @brief Finds and returns the named Snd object.

  First the named Snd
              table is searched; if the sound isn't found, then the method looks
              for <i>&ldquo;aName</i>.snd&rdquo; in the sound segment of the
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
  @brief
  @param  	  name
  @param  	  aSnd
  @return
*/
+ addName: (NSString *) name sound: (Snd *) aSnd;

/*!
  @brief
  @param      name
  @param      filename
  @return
*/
+ addName: (NSString *) name fromSoundfile: (NSString *) filename;

/*!
  @brief
  @param      name
  @param  	  sectionName
  @return
*/
+ addName: (NSString *) name fromSection: (NSString *) sectionName;
/*!
  @brief
  @param      aName
  @param  	  aBundle
  @return
*/
+ addName: (NSString *) aName fromBundle: (NSBundle *) aBundle;

/*!
  @brief
  @param      name
  @return
*/
+ (void) removeSoundForName: (NSString *) name;

/*!
    @brief Remove all named sounds in the name table.
*/
+ (void) removeAllSounds;


- (NSString *) description;

/*!
  @param  filename is a NSString instance.
  @return Returns <b>self</b> (an unnamed Snd) if the file was successfully read;
   otherwise, frees the newly allocated Snd and returns <b>nil</b>.
  @brief Initializes the Snd instance, which must be newly allocated, from
              the sound file <i>filename</i>.
  @see	+<b>alloc</b> (NSObject), +<b>allocWithZone:</b> (NSObject)
*/
- initFromSoundfile: (NSString *) filename;

/*!
  @param  url is a NSURL instance.
  @return Returns an id.
  @brief Initializes the Snd instance, which must be newly allocated, by
              copying the sound data from the possibly remote sound file located using
              <i>url</i>.

  Returns <b>self</b> (an unnamed Snd) if <i>url</i> can retrieve
              a sound file; otherwise, frees the newly allocated Snd and returns <b>nil</b>.

  @see	<b>initFromSoundfile:</b>, +<b>alloc</b> (NSObject), +<b>allocWithZone:</b> (NSObject)
  */
- initFromSoundURL: (NSURL *) url;

/*!
  @brief Initialise a Snd instance with silence of given format and length.
  @param  format is an SndSampleFormat.
  @param  channels specifies the number of channels (i.e 2 for stereo).
  @param  frames specifies the number of frames (multiple channel samples) in the sound.
  @param  samplingRate is a double.
  @return Returns self.
*/
- initWithFormat: (SndSampleFormat) format
    channelCount: (int) channels
          frames: (unsigned long) frames
    samplingRate: (float) samplingRate;

/*!
  @brief Initialise a Snd instance using a NSData instance which holds audio data in Sun/NeXT .au format.
  
  The data is held with format preceding the PCM audio data.
  If the sound in the NSData is named, the Snd gets the new name. 
  <B>Currently only reads Sun/NeXT .au format data</B>.
 
  @param soundData An NSData instance containing preceding sound format data followed by PCM audio data, in Sun/NeXT .au format.
  @return Returns self if the sound was read successfully, nil otherwise.
 */
- initWithData: (NSData *) soundData;

/*!
  @brief  The swapBigEndianToHostFormat method swaps the byte order of the receiver if it
	   is running on a little-endian (e.g Intel) architecture, and has no effect on a big-endian
	   (e.g Motorola 68k, PPC) architecture.
 
   Note that no checks are done as to whether or not the receiver was
   already byte-swapped, so you have to keep track of the state of
   Snd objects yourself.<br>
   Always use the appropriate method to convert your Snd objects; either
   swapBigEndianToHostFormat to convert a Snd from the pasteboard or from a soundfile,
   or swapHostToBigEndianFormat to prepare a Snd which was in host order to be saved
   or put onto the pasteboard.
 */
- (void) swapBigEndianToHostFormat;

/*!
  @brief  The swapHostToBigEndianFormat method swaps the byte order of the receiver if it
               is running on a little-endian (e.g Intel) architecture, and has no effect on a big-endian
               (e.g Motorola 68k, PPC) architecture.
 
   Note that no checks are done as to whether or not the receiver was
   already byte-swapped, so you have to keep track of the state of
   Snd objects yourself.<br>
   Always use the appropriate method to convert your Snd objects; either
   swapBigEndianToHostFormat to convert a Snd from the pasteboard or from a soundfile,
   or swapHostToBigEndianFormat to prepare a Snd which was in host order to be saved
   or put onto the pasteboard.
 */
- (void) swapHostToBigEndianFormat;

- (void) encodeWithCoder: (NSCoder *) aCoder;
- (id) initWithCoder: (NSCoder *) aDecoder;
- awakeAfterUsingCoder: (NSCoder *) aDecoder;

/*!
  @return Returns a NSString instance.
  @brief Returns the Snd's name.
*/
- (NSString *) name;

/*!
  @brief Sets the Snd's name to <i>aName</i>.

  If <i>aName</i> is already being used, then the Snd's name
  isn't set and NO is returned; otherwise returns YES.
  @param  theName is a NSString instance.
  @return Returns a BOOL.
*/
- setName: (NSString *) theName;

/*!
  @return Returns an id.
  @brief Returns the Snd's delegate.
*/
- delegate;

/*!
  @param  anObject is an id.
  @brief Sets the Snd's delegate to <i>anObject</i>.
*/
- (void) setDelegate: (id) anObject;

/*!
  @return Returns a double.
  @brief Returns the Snd's sampling rate.
*/
- (double) samplingRate;

/*!
  @return Returns an int.
  @brief Returns the number of sample frames, or channel count-independent samples, in the Snd.
*/
- (unsigned long) lengthInSampleFrames;

/*!
  @return Returns a double.
  @brief Returns the Snd's length in seconds.
*/
- (double) duration;

/*!
  @return Returns an int.
  @brief Returns the number of channels in the Snd.
*/
- (int) channelCount;

/*!
  @brief Returns the Snd's info string.
 
  The Snd's info string is any text description the user of the object wishes to assign to it.
  It will however, endeavour to be written in an appropriate field to any sound file written from this Snd instance.
  It will be retrieved from an appropriate field when reading a sound file.
  @return Returns an NSString.
*/
- (NSString *) info;

/*!
  @brief Assigns the Snd's info string.

  The Snd's info string is any text description the user of the object wishes to assign to it.
  It will however, endeavour to be written in an appropriate field to any sound file written from this Snd instance.
  @param newInfoString An NSString containing the new text.
 */
- (void) setInfo: (NSString *) newInfoString;

/*!
  @return Returns a BOOL.
  @brief Returns <b>YES</b> if the Snd doesn't contain any sound data,
              otherwise returns <b>NO</b>.

  This always returns <b>NO</b> if the
  Snd isn't editable (as determined by sending it the
  <b>isEditable</b> message).
*/
- (BOOL) isEmpty;

/*!
  @return Returns a BOOL.
  @brief Returns <b>YES</b> if the Snd's format indicates that it can be
              edited, otherwise returns <b>NO</b>.
*/
- (BOOL) isEditable;

/*!
  @param  aSound is an id.
  @return Returns a BOOL.
  @brief Returns <b>YES</b> if the format, sampling rate, and channel count
              of <i>aSound</i>'s sound data is the same as that of the Snd
              receiving this message.

  If one (or both) of the Snds doesn't
  contain a sound (its <b>soundStruct</b> is <b>nil</b>) then the
  objects are declared compatible and <b>YES</b> is returned.              
*/
- (BOOL) compatibleWithSound: (Snd *) aSound;

/*!
  @param  newFormat is an SndSampleFormat.
  @param  newRate is a double.
  @param  newChannelCount is an int.
  @return Returns an error code or SND_ERR_NONE if the conversion was performed correctly.
  @brief Convert the Snd's data to the given format, sampling rate, and number of channels.

  The following conversions are possible:
  <UL>
  <LI>Arbitrary sampling rate conversion.</LI>
  <LI>Compression and decompression.</LI>
  <LI>Floating-point formats (including double-precision) to and from linear formats.</LI>
  <LI>Mono to stereo.</LI>
  <LI>CODEC mu-law to and from linear formats.</LI>
  </UL>
 */
- (int) convertToSampleFormat: (SndSampleFormat) newFormat
	   samplingRate: (double) newRate
	   channelCount: (int) newChannelCount;

/*!
  @param  newFormat is an SndSampleFormat.
  @return Returns an integer indicating any error or SND_ERR_NONE if the conversion worked.
  @brief This is the same as <b>convertToSampleFormat:samplingRate:channelCount:</b>,
              except that only the format is changed.

  An error code is returned.  
*/
- (int) convertToSampleFormat: (SndSampleFormat) newFormat;

/*!
  @brief Returns the native format (sampling rate, resolution and channels) used by the sound
            playback hardware in streaming audio.
 
  The native format is the format sounds loaded and audio buffers created in which will incur
  the least processing overhead in order to play. Recording could be in a different format.
  @return Returns a SndFormat structure.
 */
+ (SndFormat) nativeFormat;

/*!
  @return Returns an error code.
  @brief The Snd is converted to the format (sampling rate, resolution and channels) that
              the hardware natively uses.

  This should result in the fastest playback, avoiding any on the fly conversions. 
 */
- (int) convertToNativeFormat;

/*!
  @param  zone is an NSZone.
  @return Returns a new retained instance with duplicated data, or nil if unable to copy.
*/
- (id) copyWithZone: (NSZone *) zone;

/*!
  @param  dataFormat is an NSString describing the data format.
  @return Returns an autoreleased NSData instance, or nil if unable to encode.
  @brief Creates an NSData instance holding the Snd's name (if any), sample format, and sound data (if any).
 
  The dataFormat parameter matches sound file extensions. Currently however,
  all data is encoded as .au format, dataFormat is ignored.
 */
- (NSData *) dataEncodedAsFormat: (NSString *) dataFormat;

/*!
  @return Returns a void pointer.
  @brief Returns a pointer to the Snd's sampled data.

  You can use the pointer to examine, create, and modify the sound data. 
  To intelligently manipulate the data, you need to be aware of its size,
  format, sampling rate, and the number of channels that it contains
  (a query method for each of these attributes is provided by the
  Snd class). The size of the data, in particular, must be
  respected; it's set when the Snd is created or given a new sound
  (through <b>readSoundfile:</b>, for example) and can't be changed
  directly. To resize the data, you should invoke one of the editing
  methods such as <b>insertSamples:at:</b> or
  <b>deleteSamplesInRange:</b>.

  To start with a new, unfragmented sound with a determinate length, invoke the
  <b>initWithFormat:channelCount:frames:samplingRate:</b> method.
  Keep in mind that the sound data in a fragmented
  sound is an NSArray of SndAudioBuffers, one for each fragment. To
  examine or manipulate the samples in a fragmented sound,
  you should retrieve the audio buffers array using <b>audioBuffers</b>.
*/
- (void *) bytes;

/*!
  @brief Return the size (in bytes) of the Snd's sample data.

  If you modify the data (through the pointer returned by the <b>data</b> method) you
  must be careful not to exceed its length. If the sound is fragmented, 
  the value returned by this method is still the total size of the Snd's data.
  @return Returns a long int.
*/
- (long) dataSize;

/*!
  @return Returns an SndSampleFormat.
  @brief Returns the format of the Snd's data.

  If the data is fragmented,
  the format of the samples is returned (in other words,
  SND_FORMAT_INDIRECT is never returned by this method).
*/
- (SndSampleFormat) dataFormat;

/*!
  @param buff The SndAudioBuffer instance to compare.
  @return Returns a BOOL.
  @brief Returns YES if the Snd's dataFormat, channelCount and sampling rate match the given SndAudioBuffer instance.
 
  The number of frames are <B>not</B> compared.
 */
- (BOOL) hasSameFormatAsBuffer: (SndAudioBuffer *) buff;

/*!
  @brief  Returns the format (number of frames, channels, dataFormat) of the audio buffer as a SndFormat structure.
  @return Returns a SndFormat.
 */
- (SndFormat) format;

/*!
  @brief Returns a string describing the data format in a textual description.
  @brief Returns a NSString instance.
 */
- (NSString *) formatDescription;

/*!
  @return Returns an int.
  @brief Returns a constant that represents the last error that was generated.

  The sound error codes are listed in &ldquo;Types and Constants.&rdquo;
*/
- (int) processingError;

/*!
  @return Returns an id.
  @brief Returns the Snd object that's being performed.

  The default implementation always returns <b>self</b>.
*/
- (Snd *) soundBeingProcessed;

// delegations which are not nominated per performance.

/*!
  @param  theMessage is a SEL.
  @brief Sends <i>theMessage</i> to the Snd's delegate (only sent if the
              delegate implements <i>theMessage</i>).

  You never invoke this method
  directly; it's invoked automatically as the result of activities
  such as recording and playing. However, you can use it in designing
  a subclass of Snd.
*/
- (void) tellDelegate: (SEL) theMessage;

// delegations which are nominated per performance.

/*!
  @brief Sends <i>theMessage</i> to the Snd's delegate (only sent if the
              delegate implements <i>theMessage</i>).

  You never invoke this method directly; it's invoked automatically as the
  result of activities such as recording and playing.
  However, you can use it in designing a subclass of Snd.
  @param  theMessage is a SEL.
  @param  performance The performance playing when the message is sent.
 */
- (void) tellDelegate: (SEL) theMessage duringPerformance: (SndPerformance *) performance;

/*!
  @brief Sends <i>theMessage</i> to the Snd's delegate (only sent if the
              delegate implements <i>theMessage</i>).

  You never invoke this method
  directly; it's invoked automatically as the result of activities
  such as recording and playing. However, you can use it in designing
  a subclass of Snd.
  @param  theMessage is an NSString, which will be converted to a SEL.
  @param  performance The performance playing when the message is sent.
*/
- (void) tellDelegateString: (NSString *) theMessage duringPerformance: (SndPerformance *) performance;

/*!
  @brief Sets the conversion quality performed by convertToSampleFormat:

  Default is SndConvertLowQuality.
  @param quality Sets the conversion quality to a SndConversionQuality enumerated type.
 */
- (void) setConversionQuality: (SndConversionQuality) quality;

/*!
  @brief Returns the current conversion quality performed by convertToSampleFormat:
  @return Returns a SndConversionQuality enumerated type.
*/
- (SndConversionQuality) conversionQuality;

/*!
  @brief Initialises a Snd instance from the provided SndAudioBuffer.
  @param aBuffer the SndAudioBuffer object from which to copy the data
  @return self
 */
- initWithAudioBuffer: (SndAudioBuffer *) aBuffer;

/*!
  @brief Normalises the amplitude of the entire sound.
  @brief The highest amplitude sample in the sound is scaled to be the maximum resolution.
 */
- (void) normalise;

/*!
  @brief Returns the maximum amplitude of the format, that is, the maximum positive value of a sample.
  @return Returns the maximum value of a sample.
 */
- (double) maximumAmplitude;

@end

@interface Snd(FileIO)

+ (int) fileFormatForEncoding: (NSString *) extensionString
		   dataFormat: (SndSampleFormat) sndFormatCode;

/*!
  @brief Returns an array of valid file extensions available for reading and writing.

  Returns an array of file extensions indicating the file format (and file extension)
  that audio files may be read from or written to. This list may be used for limiting NSOpenPanel
  to those formats supported. The list can be expected to vary between platforms, but is ultimately
  derived from those formats supported by the underlying libsndfile library.
 @return Returns an NSArray of NSStrings of file extensions.
 */
+ (NSArray *) soundFileExtensions;

/*!
  @param path A file path
  @return TRUE if the file at path is a sound file.
 */
+ (BOOL) isPathForSoundFile: (NSString*) path;

/*!
  @brief Returns the extension of the standard file format. This may differ between platforms.
 */
+ (NSString *) defaultFileExtension;

/*!
  @param  filename is a NSString instance.
  @return Returns a SndFormat structure.
  @brief Returns the format of the data in the named sound file.

  If the file is unable to be opened a dataFormat of SND_FORMAT_UNSPECIFIED is returned in the SndFormat.
 */
- (SndFormat) soundFormatOfFilename: (NSString *) filename;

/*!
  @param  filename is a NSString instance.
  @param  startFrame The frame in the file to read from.
  @param  frameCount Number of frames to read, -1 = read to EOF marker.
  @return Returns an int.
  @brief Replaces the Snd's contents with a nominated subrange of those of the sound file
              <i>filename</i>.

  The Snd loses its current name, if any. An error code is returned.
  TODO it would be preferable to have readSoundfile: (NSString *) fromRange: (NSRange). 
  However we need a mechanism to indicate infinity for the length in order to signal to read to EOF.
 */
- (int) readSoundfile: (NSString *) filename
	   startFrame: (unsigned long) startFrame
	   frameCount: (long) frameCount;

/*!
  @param  filename is a NSString instance.
  @return Returns an integer error code.
  @brief Replaces the Snd's contents with those of the sound file <i>filename</i>.

  The Snd loses its current name, if any. 
 */
- (int) readSoundfile: (NSString *) filename;

/*!
  @brief Writes the Snd's contents (its sample format and sound data) to the sound file <i>filename</i> in
            the given file format and data encoding.

  Expects the sound to not be fragmented, and to be in host endian order.
  @param filename is a NSString instance.
  @param fileFormat An NSString giving the extension format name (.au, .wav, .aiff etc) to write out the sound
         which matches one of the encodings returned by +soundFileExtensions.
  @param fileDataFormat a SndSampleFormat allowing the sound to be written out in a different format (e.g SND_FORMAT_LINEAR_16)
         than it is held in (e.g SND_FORMAT_FLOAT).
  @return Returns SND_ERR_NONE if the writing went correctly, otherwise an error value.
 */
- (int) writeSoundfile: (NSString *) filename
	    fileFormat: (NSString *) fileFormat
	    dataFormat: (SndSampleFormat) fileDataFormat;

/*!
  @param  filename is a NSString instance.
  @return Returns SND_ERR_NONE if the writing went correctly, otherwise an error value.
  @brief Writes the Snd's contents (its sample format and sound data) to the sound file <i>filename</i>. 

  The filename is expected to have an extension which indicates the format to write and which matches
  one of the encodings returned by +soundFileExtensions. Use writeSoundfile:fileFormat:dataFormat: to
  write a filename without an extension. An error code is returned.
 */
- (int) writeSoundfile: (NSString *) filename;

@end

@interface Snd(Playing)

/*!
  @return Returns a BOOL.
  @brief Returns YES if the sound output of all playing sounds is currently muted.
*/
+ (BOOL) isMuted;

/*!
  @param  aFlag is a BOOL.
  @return If successful, returns <b>self</b>; otherwise returns <b>nil</b>.
  @brief Mutes and unmutes the sound output level of all playing sounds if <i>aFlag</i> is YES or
              NO, respectively.  
 */
+ setMute: (BOOL) aFlag;

/*!
  @return Returns an int.
  @brief If the Snd is currently playing or recording, waits until the
              sound has finished playing or recording, at which time it returns
              the result of the <b>SNDWait() </b>function.

  If the Snd is not
  playing or recording when <b>waitUntilStopped</b> is invoked, it
  returns SND_ERROR_NONE.
 */
- (int) waitUntilStopped;

/*!
  @brief Stop the given playback of the sound at some future time, specified in seconds.
  @param inSeconds The number of seconds beyond the current time point to begin playback.
  @param performance The performance that represents the sound playing. 
 */
+ (void) stopPerformance: (SndPerformance *) performance inFuture: (double) inSeconds;

/*!
  @param  sender is an id.
  @brief Action method that stops the Snd's playback or recording.

  Other than the argument and the return type, this is the same as the <b>stop</b> method.
 */
- (void) stop: (id) sender;

/*!
  @return Returns an int.
  @brief Terminates the Snd's playback or recording.

  If the Snd was recording, the <b>didRecord:</b> message is sent to the delegate; if
  playing, <b>didPlay:duringPerformance:</b> is sent. An error code is returned.
 */
- (int) stop;

/*!
  @param  sender is an id.
  @brief Action method that pauses the Snd.

  Other than the argument and the return type, 
  this is the same as the <b>pause</b> method.
 */
- pause: (id) sender;

/*!
  @return Returns an integer error code.
  @brief Pauses the Snd during recording or playback.
 */
- (int) pause;

/*!
  @param  sender is an id.
  @brief Action method that resumes the paused Snd.
 */
- resume: (id) sender;

/*!
  @return Returns an integer error code.
  @brief Resumes the paused Snd's activity.
 */
- (int) resume;

/*!
  @return Returns a BOOL.
  @brief Returns <b>YES</b> if the Snd can be played, otherwise returns <b>NO</b>.

  Some unplayable Snds just need to be converted to
  another format, sampling rate, or number of channels; others are
  inherently unplayable, such as those whose format is
  SND_FORMAT_DISPLAY. To play a Snd that's just been recorded from
  the DSP, you must change its format from SND_FORMAT_DSP_DATA_16 to
  SND_FORMAT_LINEAR_16. 
*/
- (BOOL) isPlayable;

/*!
  @return Returns a BOOL, YES if a sound has playing performances, NO if not.
  @brief Returns <b>YES</b> if the Snd is currently playing one or more performances,
              otherwise returns <b>NO</b>.
 */
- (BOOL) isPlaying;

/*!
  @brief Play the entire sound now.
  @return Returns the performance that represents the sound playing.
  @brief Initiates playback of the Snd.

  The method returns immediately while the playback continues asynchronously in the background. 
  The playback ends when the Snd receives the <b>stop</b> message, or when its data is exhausted.

  When playback starts, <b>willPlay:</b> is sent to the Snd's delegate; when it stops, <b>didPlay:</b> is sent.

  <b>Warning:</b> For this method to work properly, the main event loop must not be blocked.
*/
- (SndPerformance *) play;

/*!
  @brief Play the entire sound now, for use as an action method.
  @param sender The sending object.
  @return Returns the performance that represents the sound playing.
 */
- (SndPerformance *) play: (id) sender;

/*!
  @brief Begin playback at some time in the future, over a region of the sound.
  @param inSeconds The number of seconds beyond the current time point to begin playback.
  @param begin The sample number to begin playing from. Use 0 to play from the start of the sound.
  @param count The number of samples to play. Use sampleCount to play the entire sound.
  @return Returns the performance that represents the sound playing.
 */
- (SndPerformance *) playInFuture: (double) inSeconds
		      beginSample: (unsigned long) begin
		      sampleCount: (unsigned long) count;

/*!
  @brief Begin playback at some time in the future, over a region of the sound.
  @param inSeconds The number of seconds beyond the current time point to begin playback.
  @param startPosition The time in seconds in the Snd to begin playing from.
    Use 0.0 to play from the start of the sound.
  @param duration The duration of the Snd to play in seconds. Use -[Snd duration] to play the entire sound.
  @return Returns the performance that represents the sound playing.
 */
- (SndPerformance *) playInFuture: (double) inSeconds
           startPositionInSeconds: (double) startPosition
                durationInSeconds: (double) duration;
/*!
  @brief Begin playback at a certain absolute stream time, for a certain duration.
  @param    t Start time in seconds
  @param    d Duration in seconds
  @return   Returns the performance that represents the sound playing.
 */
- (SndPerformance *) playAtTimeInSeconds: (double) t withDurationInSeconds: (double) d;

/*!
  @brief Begin playback now, over a region of the sound.
 
  This is a deprecated method for SoundKit compatability.
  You should use playInFuture:beginSample:sampleCount: instead.
  @param begin The sample number to begin playing from. Use 0 to play from the start of the sound.
  @param count The number of samples to play. Use sampleCount to play the entire sound.
  @return Returns the performance that represents the sound playing.
 */
- (SndPerformance *) play: (id) sender beginSample: (int) begin sampleCount: (int) count;

/*!
  @brief Begin the playback of the sound at some future time, specified in seconds.
  @param inSeconds The number of seconds beyond the current time point to begin playback.
  @return Returns the performance that represents the sound playing.
 */
- (SndPerformance *) playInFuture: (double) inSeconds;

/*!
  @brief Begin the playback of the sound at a specified date.
  @param date The date to begin playback.
  @return Returns the performance that represents the sound playing.
 */
- (SndPerformance *) playAtDate: (NSDate *) date;

/*!
  @param sender
 */
- record: (id) sender;

/*!
  @return An error code is returned.
  @brief Initiate recording into the Snd.

  To record from the CODEC
  microphone, the Snd's format, sampling rate, and channel count
  must be SND_FORMAT_MULAW_8, SND_RATE_CODEC, and 1, respectively. If
  this information isn't set (if the Snd is a newly created object,
  for example), it defaults to accommodate a CODEC recording. If the
  Snd's format is SND_FORMAT_DSP_DATA_16, the recording is from the DSP.

  The method returns immediately while the recording
  continues asynchronously in the background. The recording stops when
  the Snd receives the <b>stop</b> message or when the recording has
  gone on for the duration of the original sound data. The default
  CODEC recording lasts precisely ten minutes if not stopped. To
  record for a longer time, first increase the size of the sound data
  with  <b>initWithFormat:channelCount:frames:samplingRate:</b>.

  When the recording begins, <b>willRecord:</b> is sent to the Snd's delegate; when the recording stops,
  <b>didRecord:</b> is sent.

  <b>Warning:</b> For this method to work properly, the main event loop must not be blocked.
 */
- (int) record;

/*!
  @brief Returns whether the Snd instance is currently recording audio into the sound.
  @return Returns YES if the recording has begun (regardless of whether samples have actually
  been received).
 */
- (BOOL) isRecording;

/*!
  @param performance The SndPerformance of which to enquire.
  @return Returns an int.
  @brief If the Snd is currently playing or recording, this returns the
         number of sample frames that have been played or recorded so far.
 
  If not currently playing or recording, the number of sample frames in the Snd is returned.
  If the sample frame count can't be determined, -1 is returned.
 */
- (int) samplesPerformedOfPerformance: (SndPerformance *) performance;

/*!
  @brief   Performance array accessor.

  Mainly for use by SndPlayer.
  @return     NSArray of performances.
*/
- (NSArray*) performances;

/*!
  @brief   Adds a performance to the performance array.
 
  Mainly for use by SndPlayer.
  @param      p A performance
  @return     self.
*/
- addPerformance: (SndPerformance *) p;

/*!
  @brief   Removes a performance from the performance array.

  Mainly for use by SndPlayer.
  @param      p A performance to be removed.
  @return     self.
*/
- removePerformance: (SndPerformance *) p;

/*!
  @brief Returns the number of active AND pending performances 
 
  Mainly for use by SndPlayer.
  @return     self.
*/
- (int) performanceCount;

/*!
  @brief   Sets the default behaviour whether to loop during play.
  @param      yesOrNo Sets the default behaviour whether to loop during play.
 */
- (void) setLoopWhenPlaying: (BOOL) yesOrNo;

/*!
  @brief   Returns whether the default behaviour is to loop during play.
  @return     Returns whether the default behaviour is to loop during play.
 */
- (BOOL) loopWhenPlaying;

/*!
  @brief   Sets the sample to stop playing at.

  The loop start index may be changed while the sound is being performed and regardless of
  whether the performance is looping.
  @param      newEndAtIndex The sample index that playing should stop after.
 */
- (void) setLoopStartIndex: (long) loopStartIndex;

/*!
  @brief   Returns the sample to start playing at.
  @return     Returns the sample index to start playing at.
 */
- (long) loopStartIndex;

/*!
  @brief   Sets the sample at which the performance loops back to the start index (set using setLoopStartIndex:).

  This sample index is the last sample of the loop, i.e. it is the last sample heard before
  the performance loops, the next sample heard will be that returned by -<B>loopStartIndex</B>.
  The loop end index may be changed while the sound is being performed and regardless of whether
  the performance is looping.
  @param      newLoopEndIndex The sample index at the end of the loop.
 */
- (void) setLoopEndIndex: (long) newLoopEndIndex;

/*!
  @brief   Returns the sample index at the end of the loop.
  @return     Returns the sample index ending the loop.
 */
- (long) loopEndIndex;

// We declare this because it is used by the SndEditing category.
- (void) adjustLoopsAfterAdding: (BOOL) adding 
			 frames: (long) sampleCount
		     startingAt: (long) startSample;

/*!
  @brief   Assigns the audioProcessorChain to this Snd instance.
 
  This is typically used during playback of the Snd, but could be used for any other (i.e offline processing of the Snd).
  @param newAudioProcessorChain A SndAudioProcessorChain instance.
 */
- (void) setAudioProcessorChain: (SndAudioProcessorChain *) newAudioProcessorChain;

/*!
  @brief   Returns the audioProcessorChain associated with this Snd instance.
 
  This is typically used during playback of the Snd, but could be used for any other (i.e offline processing of the Snd).
  @return     Returns a SndAudioProcessorChain instance.
 */
- (SndAudioProcessorChain *) audioProcessorChain;

@end

@interface Snd(Editing)

/*!
  @brief Used to lock Snd instance against editing.
  @brief See also -<i>unlockEditing</i> for the complementary method to match with.
 */
- (void) lockEditing;

/*!
  @brief Used to unlock Snd instance for editing.
  @brief See also -<i>lockEditing</i> for the complementary method to match with.
 */
- (void) unlockEditing;

/*!
  @return Returns an int.
  @brief Deletes all the samples in the Snd's data.

  The Snd must be editable. An error code is returned.
 */
- (int) deleteSamples;

/*!
  @param  frameRange is an NSRange giving the range of frames to delete.
  @return Returns an integer error code.
  @brief Deletes a range of samples from the sound: the length of <i>frameRange</i>
      sample frames are deleted starting with the location of the <i>frameRange</i>
      (zero-based).

  The Snd must be editable and may become fragmented.
 */
- (int) deleteSamplesInRange: (NSRange) frameRange;

/*!
  @param  aSound is an id.
  @param  startSample is an int.
  @return Returns an int.
  @brief Pastes the sound data in <i>aSound</i> into the Snd receiving
	  this message, starting at the receiving Snd's <i>startSample</i>'th sample (zero-based).
 
  The receiving Snd doesn't lose any of its original sound data - the samples greater than
  or equal to <i>startSample</i> are moved to accommodate the inserted sound data. The receiving
  Snd must be editable and the two Snds must be compatible (as determined by <b>isCompatible:</b>).
  If the method is successful, the receiving Snd is fragmented. An error code is returned.
 */
- (int) insertSamples: (Snd *) aSnd at: (int) startSample;

/*!
  @param frameRange is an NSRange of sample frames.
  @return Returns an autoreleased Snd instance.
  @brief Returns a new Snd instance of the same format with a copy of a
              portion of receivers sound data.

  The copied portion is given by 
  <i>frameRange</i> frames (zero-based). If
  the specified portion of the Snd receiving this message is fragmented,
  the Snd returned will also be fragmented.
 */
- (Snd *) soundFromSamplesInRange: (NSRange) frameRange;

/*!
  @return Returns an int.
  @brief The Snd's sampled data is compacted into a contiguous block,
              undoing the fragmentation that can occur during editing.

  If the Snd's data isn't fragmented, then this method does
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
  @return Returns a BOOL.
  @brief Returns <b>YES</b> if the Snd's data is fragmented. Otherwise returns <b>NO</b>.
 */
- (BOOL) needsCompacting;

/*!
  @function fragmentOfFrame:indexInFragment:fragmentLength:dataFormat:
  @brief Get data address and statistics for fragmented or non-fragmented Snds.
 
  For fragmented sounds, you often need to be able to find the
  SndAudioBuffer of data that a certain frame resides in. You then often
  need to know which is the last frame in that fragment (audio buffer),
  indexed from the start of the block.
  @param frame            The index of the sample you wish to find the block for, indexed from the beginning of the sound
  @param currentFrame     Returns by reference the index of the frame supplied, indexed from the start of the block
  @param fragmentLength   Returns by reference the length the block, indexed from the start of the block
  @param dataFormat       Returns by reference the format of the data. This will normally be the same as the Snd's dataFormat,
                          but can differ if the format is encoded with compression.
  @return the memory address of the first sample in the block.
 */
- (void *) fragmentOfFrame: (unsigned long) frame 
	   indexInFragment: (unsigned long *) currentFrame 
	    fragmentLength: (unsigned long *) fragmentLength
		dataFormat: (SndSampleFormat *) dataFormat;

/*!
  @brief Copies samples from self into the provided SndAudioBuffer.
 
  The SndAudioBuffer's data object's size is decreased if less than fillLength number of samples can be read.
  The buffer is not expanded.
  @param buff The SndAudioBuffer object into which to copy the data.
  @param fillLength The number of sample frames in the buffer to copy into.
  @param sndReadingRange The sample frame in the Snd to start reading from and maximum length of samples readable.
  @return Returns the number of sample frames read from the Snd instance in filling the audio buffer.
          This can be more or less than the number requested, if resampling occurs.
 */
- (long) fillAudioBuffer: (SndAudioBuffer *) buff
	        toLength: (long) fillLength
          samplesInRange: (NSRange) sndReadingRange;

/*!
  @brief Copies samples from self into a sub region of the provided SndAudioBuffer.
 
  If the buffer and the Snd instance have different formats, a format
  conversion will be performed to the buffers format, including resampling
  if necessary.

  The Snd audio data will be read enough to fill the range of samples
  specified according to the sample rate of the buffer compared to the sample rate
  of the Snd instance. In the case where there are less than the needed number of
  samples left in the sndFrameRange to completely insert into the specified buffer region, the
  number of samples inserted will be returned less than bufferRange.length.
 @param buff The SndAudioBuffer object into which to copy the data.
 @param bufferRange An NSRange of sample frames (i.e channel independent time position specified in samples)
              in the buffer to copy into.
 @param sndFrameRange An NSRange of sample frames (i.e channel independent time position specified in samples)
              within the Snd to start reading data from and the last permissible index to read from.
 @return Returns the number of samples actually inserted. This may be less than the length specified
              in the bufferRange if sndStartIndex is less than the number samples needed to convert to
              insert in the specified buffer region.
 */
- (long) insertIntoAudioBuffer: (SndAudioBuffer *) buff
		intoFrameRange: (NSRange) bufferFrameRange
		samplesInRange: (NSRange) sndFrameRange;

/*!
 @brief Copies in the given SndAudioBuffer into the Snd instance.
 @param buffer The SndAudioBuffer to copy sound from.
 @param writeIntoSndFrameRange The range of frames to copy. Can not be longer than the buffer.
 @return Returns the new size of the buffer.
 */
- (long) insertAudioBuffer: (SndAudioBuffer *) buffer
	    intoFrameRange: (NSRange) writeIntoSndFrameRange;

/*!
  @brief Appends the given SndAudioBuffer to the end of the Snd instance.
  @param buffer The SndAudioBuffer to copy sound from.
  @return Returns the new size of the Snd.
 */
- (long) appendAudioBuffer: (SndAudioBuffer *) buffer;

/*!
  @brief Returns a SndAudioBuffer containing a range of samples in the Snd.
  @param  sndFrameRange Range of sample <I>frames</I> (as opposed to individual single
		        channel samples) to stick into the audioBuffer.
  @param isLooping Indicates whether to read from the loop start if the length of the sndFrameRange exceeds
                   the length of the Snd instance.
  @return An SndAudioBuffer containing the samples in the range r.
 */
- (SndAudioBuffer *) audioBufferForSamplesInRange: (NSRange) sndFrameRange
					  looping: (BOOL) isLooping;

/*!
  @brief Returns a SndAudioBuffer containing a range of samples in the Snd.
  @param  r Range of sample <I>frames</I> (as opposed to individual single
 	    channel samples) to stick into the audioBuffer
  @return An SndAudioBuffer containing the samples in the range r.
 */
- (SndAudioBuffer *) audioBufferForSamplesInRange: (NSRange) r;

/*!
  @brief Returns an NSArray of SndAudioBuffers comprising the Snd. The array is stored in temporal order.
  @return An autoreleased NSArray of SndAudioBuffers.
 */
- (NSArray *) audioBuffers;

@end

@interface SndDelegate : NSObject

/*!
  @param  sender is an id.
  @brief Sent to the delegate when the Snd begins to record.
*/
- willRecord: sender;

/*!
  @param  sender is an id.
  @brief Sent to the delegate when the Snd stops recording.
*/
- didRecord:  sender;

/*!
  @param  sender is an id.
  @brief Sent to the delegate if an error occurs during recording or
              playback.
*/
- hadError:   sender;

/*!
  @param  sender is an id.
  @param  performance is a SndPerformance instance.
  @brief Sent to the delegate when the Snd begins to play.
*/
- willPlay:   sender duringPerformance: (SndPerformance *) performance;

/*!
  @param  sender is an id.
  @param  performance is a SndPerformance instance.
  @brief Sent to the delegate when the Snd stops playing.
*/
- didPlay:    sender duringPerformance: (SndPerformance *) performance;

@end

#endif
