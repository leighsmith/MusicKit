/*
  $Id$
  Defined In: The MusicKit

  Description:
    A MKScore is a collection of MKPart objects.  MKScores can be read from and
    written to a scorefile or midifile, performed with a MKScorePerformer,
    and an be used to record MKNotes from a MKScoreRecorder.

    Each MKScore has an info MKNote (a mute) that defines, in its parameters,
    information that can be useful in performing or otherwise interpreting
    the MKScore.  Typical information includes tempo, DSP headroom (see the
    MKOrchestra class), and sampling rate (the parameters MK_tempo,
    MK_headroom, and MK_samplingRate are provided to accommodate this
    utility).

    When you read a scorefile into a MKScore, a MKPart object is created and
    added to the MKScore for each MKPart name in the file's part statement.
    If the MKScore already contains a MKPart with the same name as a MKPart in
    the file, the MKNotes from the two sources are merged together in the
    existing MKPart in the MKScore.

    MKScoreFile print statements are printed as the scorefile is read into a
    MKScore. You can set the stream on which the messages are printed by
    invoking setScorefilePrintStream:.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University  
  Portions Copyright (c) 1999-2000, The MusicKit Project.
*/
/*!
@class MKScore

@abstract A MKScore is a collection of MKPart objects.  MKScores can be read from and
          written to a scorefile or midifile, performed with a MKScorePerformer,
	  and can be used to record MKNotes from a MKScoreRecorder.

@discussion

A MKScore is a collection of MKPart objects.  MKScores can be read from
and written to a <b>.score</b> or <b>.playscore </b> scorefile or a
Standard MIDI file, performed with a MKScorePerformer, and can be used
to record MKNotes from a MKScoreRecorder.

Each MKScore has an info MKNote (a mute) that defines, in its
parameters, information that can be useful in performing or otherwise
interpreting the MKScore.  Typical information includes tempo, DSP
headroom (see the MKOrchestra Class), and sampling rate (the
parameters MK_tempo, MK_headroom, and MK_samplingRate are provided to
accommodate this utility).

When you read a scorefile into a MKScore, a MKPart object is created
and added to the MKScore for each MKPart name in the file's <b>part</b>
statement.  If the MKScore already contains a MKPart with the same
name as a MKPart in the file, the MKNotes from the two sources are
merged together in the existing MKPart in the MKScore.

MKScoreFile <b>print</b> statements are printed as the scorefile is
read into a MKScore.  You can set the stream on which the messages are
printed by invoking <b>setScorefilePrintStream:</b>.

*/
#ifndef __MK_Score_H___
#define __MK_Score_H___

#import <Foundation/NSObject.h>

@class MKNote;

/*!
  @enum       MKScoreFormat
  @abstract   Formats that MKScore can read or write.
  @constant   MK_UNRECOGNIZEDFORMAT
  @constant   MK_MIDIFILE  MIDI Manufacturers Association Standard MIDI File V1.0.
  @constant   MK_SCOREFILE Text format version of Scorefile format, described in
              <A href=http://www.musickit.org/MusicKitConcepts/scorefilesummary.html>this syntax description</A>.
  @constant   MK_PLAYSCORE Binary format version of Scorefile format.
  @constant   MK_MUSICXML  XML based MusicXML format.
 */
 typedef enum {
    MK_UNRECOGNIZEDFORMAT,
    MK_MIDIFILE,
    MK_SCOREFILE,
    MK_PLAYSCORE,
    MK_MUSICXML
} MKScoreFormat;

@interface MKScore : NSObject
{
/*! @var parts The object's collection of MKParts. */
    NSMutableArray *parts;
/*! @var scorefilePrintStream The stream used by scorefile <b>print</b> statements. */
    NSMutableData *scorefilePrintStream;    
/*! @var info The object's info MKNote. */
    MKNote *info;
}
 
/*!
  @method init
  @result Returns an id.
  @discussion Initializes the receiver. You invoke this method when creating a new
              instance.  A subclass implementation should send <b>[super init]</b>
              before performing its own initialization. 
*/
- init;

/*! 
   @method dealloc
   @abstract Releases the receiver and its contents.
 */
- (void) dealloc;

 /* 
 Removes and releases the MKNotes contained in the receiver's MKParts.
 Also releases the receiver's info MKNote.  Returns the receiver.
 */
- releaseNotes; 

/*! 
  @method removeAllParts
  @abstract Removes the receiver's MKParts.
 */
- (void) removeAllParts; 

/*!
  @method readScorefile:
  @param  fileName is a NSString *.
  @result Returns an id.
  @discussion Opens the scorefile named <i>fileName</i> and merges its contents
              with the receiver.  The file is automatically closed.  Returns the
              receiver or <b>nil</b> if the file couldn't be read.
*/
- readScorefile: (NSString *) fileName; 


/*!
  @method readScorefileStream:
  @param  stream is a NSData *.
  @result Returns an id.
  @discussion Reads the scorefile pointed to by <i>stream</i> into the receiver. 
              The file must be open for reading; the sender is responsible for
              closing the file.  Returns the receiver or <b>nil</b> if the file
              couldn't be read.
*/
- readScorefileStream: (NSData *) stream; 

/*!
  @method readScorefile:firstTimeTag:lastTimeTag:timeShift:
  @param  fileName is a NSString *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @result Returns an id.
  @discussion The same as <b>readScorefile:</b>, but only those
              MKNotes with timeTags in the specified range are added
              to the receiver.  The added MKNotes' timeTags are
              shifted by <i>timeShift</i> beats.  Returns the receiver
              or <b>nil</b> if the file couldn't be read.  
*/
- readScorefile: (NSString *) fileName 
   firstTimeTag: (double) firstTimeTag
    lastTimeTag: (double) lastTimeTag
      timeShift: (double) timeShift; 

/*!
  @method readScorefileStream:firstTimeTag:lastTimeTag:timeShift:
  @param  stream is a NSMutableData *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @result Returns an id.
  @discussion The same as <b>readScorefileStream:</b>, but only those
              MKNotes with timeTags in the specified range are added
	      to the receiver. The added MKNotes' timeTags are shifted
	      by <i>timeShift</i> beats.  Returns the receiver or
	      <b>nil</b> if the file couldn't be read.
*/
- readScorefileStream: (NSData *) stream
         firstTimeTag: (double) firstTimeTag
          lastTimeTag: (double) lastTimeTag
            timeShift: (double) timeShift; 

/*!
  @method writeScorefile:
  @param  aFileName is a NSString *.
  @result Returns an id.
  @discussion Opens the scorefile named <b>aFileName</b> and writes the receiver to
              it (the file is overwritten).  The file is automatically closed. 
              Returns the receiver or <b>nil</b> if the file couldn't be
              written.
*/
- writeScorefile: (NSString *) aFileName; 

/*!
  @method writeScorefileStream:
  @param  aStream is a NSMutableData *.
  @result Returns an id.
  @discussion Writes the receiver into the scorefile pointed to by <i>aStream</i>.
              The file must be open for reading; the sender is responsible for
              closing the file.  Returns the receiver or <b>nil</b> if the file
              couldn't be written.
*/
- writeScorefileStream: (NSMutableData *) aStream; 

/*!
  @method writeScorefile:firstTimeTag:lastTimeTag:timeShift:
  @param  aFileName is a NSString *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @result Returns an id.
  @discussion The same as <b>writeScorefile:</b>, but only those
              MKNotes with timeTags in the specified range are written
              to the file.  The written MKNotes' timeTags are shifted
              by <i>timeShift</i> beats.  Returns the receiver or
              <b>nil</b> if the file couldn't be written.
*/
- writeScorefile: (NSString *) aFileName
    firstTimeTag: (double) firstTimeTag
     lastTimeTag: (double) lastTimeTag
       timeShift: (double) timeShift; 

/*!
  @method writeScorefileStream:firstTimeTag:lastTimeTag:timeShift:
  @param  aStream is a NSMutableData *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @result Returns an id.
  @discussion The same as <b>writeScorefileStream:</b>, but only those
	      MKNotes with timeTags in the specified range are written
	      to the file.  The written MKNotes' timeTags are shifted
	      by <i>timeShift</i> beats.  Returns the receiver or
	      <b>nil</b> if the file couldn't be written.
*/
- writeScorefileStream: (NSMutableData *) aStream
          firstTimeTag: (double) firstTimeTag
           lastTimeTag: (double) lastTimeTag
             timeShift: (double) timeShift; 

/*!
  @method writeOptimizedScorefile:
  @param  aFileName is a NSString *.
  @result Returns an id.
  @discussion Opens the OptimizedScorefile named <b>fileName</b> and writes the
              receiver to it (the file is overwritten).  The file is automatically
              closed.  Returns the receiver or <b>nil</b> if the file couldn't be
              written.
*/
- writeOptimizedScorefile: (NSString *) aFileName;

/*!
  @method writeOptimizedScorefileStream:
  @param  aStream is a NSMutableData *.
  @result Returns an id.
  @discussion Writes the receiver into the OptimizedScorefile pointed to by
              <i>aStream</i>.  The file must be open for reading; the sender is
              responsible for closing the file.  Returns the receiver or
              <b>nil</b> if the file couldn't be written.
*/
- writeOptimizedScorefileStream: (NSMutableData *) aStream;

/*!
  @method writeOptimizedScorefile:firstTimeTag:lastTimeTag:timeShift:
  @param  aFileName is a NSString *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @result Returns an id.
  @discussion The same as <b>writeOptimizedScorefile:</b>, but only
              those MKNotes with timeTags in the specified range are
	      written to the file.  The written MKNotes' timeTags are
              shifted by <i>timeShift</i> beats.  Returns the receiver
	      or <b>nil</b> if the file couldn't be written.
*/
- writeOptimizedScorefile: (NSString *)aFileName
             firstTimeTag: (double)firstTimeTag 
              lastTimeTag: (double)lastTimeTag
                timeShift: (double)timeShift;

/*!
  @method writeOptimizedScorefileStream:firstTimeTag:lastTimeTag:
  @param  aStream is a NSMutableData *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @result Returns an id.
  @discussion The same as <b>writeOptimizedScorefileStream:</b>, but
              only those MKNotes with timeTags in the specified range are written
              to the file. Returns the receiver or <b>nil</b> if the
              file couldn't be written.
*/
- writeOptimizedScorefileStream: (NSMutableData *) aStream 
                   firstTimeTag: (double) firstTimeTag 
                    lastTimeTag: (double) lastTimeTag ;

/*!
  @method writeOptimizedScorefileStream:firstTimeTag:lastTimeTag:timeShift:
  @param  aStream is a NSMutableData *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @result Returns an id.
  @discussion The same as <b>writeOptimizedScorefileStream:</b>, but
              only those MKNotes with timeTags in the specified range
	      are written to the file. The written MKNotes' timeTags
	      are shifted by <i>timeShift</i> beats.  Returns the
	      receiver or <b>nil</b> if the file couldn't be written.
*/
- writeOptimizedScorefileStream: (NSMutableData *) aStream 
                   firstTimeTag: (double) firstTimeTag 
                    lastTimeTag: (double) lastTimeTag 
                      timeShift: (double) timeShift; 
 
/*!
  @method readMidifile:firstTimeTag:lastTimeTag:timeShift:
  @param  aFileName is a NSString *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @result Returns an id.
  @discussion Reads the midifile <i>aFileName</i>  into the
              receiver.  The MKNotes that are created are retained in the receiver
              only if their timeTags are within the given boundaries. 
              <i>TimeShift</i> is added to each timeTag.
              
              See the <b>readMidiFileStream</b>: method for a
              discussion of MIDI to MKNote conversion.
*/
- readMidifile: (NSString *) aFileName
  firstTimeTag: (double) firstTimeTag
   lastTimeTag: (double) lastTimeTag
     timeShift: (double) timeShift;

/*!
  @method readMidifileStream:firstTimeTag:lastTimeTag:timeShift:
  @param  aStream is a NSMutableData *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @result Returns an id.
  @discussion Reads the midifile from <i>aStream</i> into the
              receiver.  Only the MKNote objects that have timeTags within the
              given boundaries are retained in the receiver.
	      <i>timeShift<b></b></i> is added to each MKNote's
	      timeTag.
*/
- readMidifileStream: (NSMutableData *) aStream
        firstTimeTag: (double) firstTimeTag
         lastTimeTag: (double) lastTimeTag
           timeShift: (double) timeShift;

/*!
  @method readMidifile:
  @param  fileName is a NSString *.
  @result Returns an id.
  @discussion Reads the midifile <i>fileName</i> into the receiver, creating
              MKParts for each MIDI Channel represented in the file and MKNotes
              for each MIDI message.  See the <b>readMidifileStream</b>: method
              for a discussion of MIDI to MKNote conversion.
*/
- readMidifile: (NSString *) fileName;

/*!
  @method readMidifileStream:
  @param  aStream is a NSMutableData *.
  @result Returns an id.
  @discussion Reads the midifile from aStream, converting the messages therein
              into MKNote objects.  A midifile is converted into MKNotes as
              follows:
              
              If the file is format 0, the Channel Voice messages are
              written into 16 MKParts, one for each channel.  Channel
              Mode and System messages are combined in an additional
              MKPart.  The midi channel of a particular MKPart can be
              determined by examining the MK_midiChan parameter of the
              MKPart info MKNote.  The special MKPart has no
              MK_midiChan parameter.
              
              If the file is format 1, each track is written to a
              separate MKPart.  The track number is set in the MKPart
              info's MK_track parameter.
              
              If the file is format 2, each track is written to a
              separate MKPart.  The track number is set in the MKPart
              info's MK_sequence parameter.
              
              Tempo is encoded in the MK_tempo parameter of the
              MKScore's info.  Similarly, copyright shows up in the
              MKScore's info as an MK_copyright parameter.
              
              The info of each MKPart that corresponds to a track is
              given an MK_instrumentName parameter if a corresponding
              meta-event appears in the file.
              
              Other MIDI file meta-events such as time signature,
              lyric, etc. appear as corresponding MKNote parameters in
              mute MKNotes in the appropriate MKPart.
              
              The current contents of the MKScore are not affected.
              The new MKParts are never merged with the current
              contents.  Instead, new MKParts are added to the
              MKScore.  
*/
- readMidifileStream: (NSMutableData *) aStream;

/*!
  @method writeMidifile:firstTimeTag:lastTimeTag:timeShift:
  @param  aFileName is a NSString *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @result Returns an id.
  @discussion Writes the receiver's MKNotes, within the given
              timeTag range,  as a midifile named <i>aFileName</i>.  See
              <b>writeMidifile</b>: for conversion details.  <i>timeShift</i> is
              added to each MKNote's timeTag.
*/
- writeMidifile: (NSString *) aFileName
   firstTimeTag: (double) firstTimeTag
    lastTimeTag: (double) lastTimeTag
      timeShift: (double) timeShift;

/*!
  @method writeMidifileStream:firstTimeTag:lastTimeTag:timeShift:
  @param  aStream is a NSMutableData *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @param  timeShift is a double.
  @result Returns an id.
  @discussion Write the receiver, as a midifile, to <i>aStream</i>. 
              Only the MKNotes within the given timeTag boundaries are written. 
              <i>timeShift</i> is added to each MKNote's timeTag.
*/
- writeMidifileStream: (NSMutableData *) aStream
         firstTimeTag: (double) firstTimeTag
          lastTimeTag: (double) lastTimeTag
            timeShift: (double) timeShift;

/*!
  @method writeMidifileStream:
  @param  aStream is a NSMutableData *.
  @result Returns an id.
  @discussion Write the receiver, as a midifile, to <i>aStream</i>.
*/
- writeMidifileStream: (NSMutableData *) aStream;

/*!
  @method writeMidifile:
  @param  aFileName is a NSString *.
  @result Returns an id.
  @discussion The receiver is written as a format 1 midifile as
              follows:
              
              The MKParts are written in the order they appear in the
              MKScore as separate tracks.  The track number encoded in
              the MKPart's info MKNote is ignored.  MKNoteDurs are
              split into noteOns and noteOffs as defined by MKPart's
              <b>splitNotes</b> method.  The original MKPart isn't
              altered.
              
              If the receiver's info has a title or tempo parameter,
	      these are written to the midifile.  
*/
- writeMidifile: (NSString *) aFileName;

/*!
  @method noteCount
  @result Returns an unsigned.
  @discussion Returns the number of MKNotes in all the receiver's
              MKParts.
*/
- (unsigned) noteCount; 

/*!
  @method replacePart:with:
  @param  oldPart is an id.
  @param  newPart is an id.
  @result Returns an id.
  @discussion Removes <i>oldPart</i> from the receiver and replaces it with
              <i>newPart</i>.   Returns <i>newPart</i>.  If <i>oldPart</i> is not a
              member of this score, returns <b>nil</b>and doesn't add <i>newPart</i>.
              If <i>oldPart</i> is <b>nil</b>, or if <i>newPart</i> is already a
              member of this score, or if <i>oldPart</i> is not a kind of MKPart,
              returns <b>nil</b>.
*/
- (MKPart *) replacePart: (MKPart *) oldPart with: (MKPart *) newPart;

/*!
  @method addPart:
  @param  aPart is an MKPart instance.
  @result Returns an id.
  @discussion Adds <i>aPart</i> to the receiver.  The MKPart is first removed from
              the MKScore that it's presently a member of, if any.  Returns
              <i>aPart</i>, or <b>nil</b> if it's already a member of the
              receiver.
*/
- (MKPart *) addPart: (MKPart *) aPart; 

/*!
  @method removePart:
  @param  aPart is an MKPart instance.
  @result Returns an id.
  @discussion Removes <i>aPart</i> from the receiver.  Returns <i>aPart</i> or
              <b>nil</b> if it wasn't a member of the receiver.
*/
- (MKPart *) removePart: (MKPart *) aPart;

/*!
  @method shiftTime:
  @param  shift is a double.
  @result Returns an id.
  @discussion Shifts the timeTags of all receiver's MKNotes by <i>shift</i> beats.
              Returns the receiver.
*/
- shiftTime: (double) shift; 

/*!
  @method scaleTime:
  @param  scale is a double.
  @result Returns an id.
  @discussion Scales the timeTags and durations of all receiver's MKNotes by 
              <i>scale</i> beats. Returns the receiver.
*/
- scaleTime: (double) scale;

/*!
  @method earliestNoteTime
  @abstract Returns the time tag of the earliest note in the score.
  @result Returns an double of time in seconds.
  @discussion This can be useful to determine how much silence precedes the first note.
 */
- (double) earliestNoteTime;

/*!
  @method isPartPresent:
  @param  aPart is an MKPart instance.
  @result Returns a BOOL.
  @discussion Returns <b>YES</b> if <i>aPart</i> has been added to the receiver,
              otherwise returns <b>NO</b>.
*/
- (BOOL) isPartPresent: (MKPart *) aPart; 

/*!
  @method midiPart:
  @param  aChan is an int.
  @result Returns an MKPart instance.
  @discussion Returns the MKPart object that represents MIDI Channel <i>aChan.</i>
              There are 17 MIDI Channels:  0 represents the channel for MIDI
              System and Channel Mode messages and 1 through 16 represent the
              Voice Channels.
*/
- (MKPart *) midiPart: (int) aChan; 
  /* 
     Returns the first MKPart with a MK_midiChan info parameter equal to
     aChan, if any. aChan equal to 0 corresponds to the MKPart representing
     MIDI system and channel mode messages. */


/*!
  @method partCount
  @result Returns an unsigned.
  @discussion Returns the number of MKPart contained in the receiver.
*/
- (unsigned) partCount;

/*!
  @method parts
  @result Returns an id.
  @discussion Creates and returns a NSMutableArray containing the receiver's
              MKParts.  The MKParts themselves aren't copied.
*/
- (NSMutableArray *) parts;

/*
 combine notes into noteDurs for all MKParts 
*/
- combineNotes;

 /* 
   Creates and returns a new MKScore as a copy of the receiver in the
   nominated NSZone..
   The receiver's MKPart, MKNotes, and info MKNote are all copied.
   */
- copyWithZone: (NSZone *) zone;

/*!
  @method copy
  @result Returns an id.
  @discussion Creates and returns a new MKScore as a copy of the receiver.  The
              receiver's MKPart, MKNotes, and info MKNote are all
              copied.
*/
- copy;

/*!
  @method setInfoNote:
  @param  aNote is an MKNote.
  @result Returns an id.
  @discussion Sets the receiver's info MKNote to a copy of <i>aNote</i>.  The
              receiver's previous info MKNote is removed and freed.
*/
- setInfoNote: (MKNote *) aNote;

/*!
  @method infoNote
  @result Returns an MKNote.
  @discussion Returns the receiver's info MKNote.
*/
- (MKNote *) infoNote;

/*!
  @method setScorefilePrintStream:
  @param  aStream is a NSMutableData *.
  @result Returns an id.
  @discussion Sets the stream used by ScoreFile <b>print</b> statements to
              <b>aStream</b>.  Returns the receiver.
*/
- setScorefilePrintStream: (NSMutableData *) aStream;

/*!
  @method scorefilePrintStream
  @result Returns a NSMutableData *.
  @discussion Returns the receiver's ScoreFile <b>print</b> statement
              stream.
*/
- (NSMutableData *) scorefilePrintStream;

 /* 
   You never send this message directly.  
   Should be invoked with NXWriteRootObject(). 
   Archives MKNotes and info. Also archives MKScore using 
   NXWriteObjectReference(). */
- (void) encodeWithCoder: (NSCoder *) aCoder;

 /* 
   You never send this message directly.  
   Should be invoked via NXReadObject(). 
   Note that -init is not sent to newly unarchived objects.
   See write:.

   Maps noteTags as represented in the archive file onto a set that is
   unused in the current application. This insures that the integrity
   of the noteTag is maintained. The noteTags of all MKParts in the MKScore are 
   considered part of a single noteTag space. 
*/ 
- (id) initWithCoder: (NSCoder *) aDecoder;

/*!
  @method setMidifilesEvaluateTempo:
  @param  yesOrNo is a BOOL.
  @result Returns an id.
  @discussion Sets the class variable <i>midifilesEvaluateTempo</i>, which
              specifies how tempo is interpreted when reading or writing MIDI
              files as follows:
              
              If <i>midifilesEvaluateTempo</i> is YES, the MKNotes'
              timeTags and durations are modified according to the tempo.  For
              example, if the tempo is 120 and a MIDI note begins at time 1.0 in
              the file and lasts for a half of a beat, the corresponding Music Kit
              MKNote will have a timeTag of 0.5 and a duration of 0.25.  
              Similarly, when writing files, the tempo is taken into account.  For
              example, if the tempo is 120 and a Music Kit MKNote has a timeTag of
              0.5 and a duration of 0.25, it is converted back to a MIDI note that
              begins at time 1.0 and lasts for a half of a beat.
                            
              If <i>midifilesEvaluateTempo</i> is NO, the
              modification of timeTags and durations is not performed.   NO is an
              appropriate value when you are doing real-time tempo modification
              with a slider or other control.
              
              Whatever the value of <i>midifilesEvaluateTempo</i>,
              the first tempo event found in the file is supplied as the MKScore
              info's MK_tempo parameter.   Note that the Music Kit does not
              currently support evaluating time-varying tempos found in Standard
              MIDI Files.
              
              The default value of <i>midifilesEvaluateTempo</i> is
              YES. When so, when writing to a MIDIfile, tempo is factored into the timestamps. 
*/
+ setMidifilesEvaluateTempo: (BOOL) yesOrNo;

/*!
  @method midifilesEvaluateTempo
  @result Returns a BOOL.
  @discussion Returns the value of the class variable <i>midifilesEvaluateTempo.</i> 

              See <b>setMidifilesEvaluateTempo:</b>.
*/
+ (BOOL) midifilesEvaluateTempo;

/*!
  @method midifileExtensions
  @result Returns an NSArray of NSStrings.
  @discussion Returns the possible file extensions used in writing and
              reading MIDI files appropriate for the native operating system.
*/
+ (NSArray *) midifileExtensions;

/*!
  @method scorefileExtensions
  @result Returns an NSArray of NSStrings.
  @discussion Returns the possible file extensions used in writing and
              reading scorefiles files appropriate for the native operating system.
*/
+ (NSArray *) scorefileExtensions;

/*!
  @method setAlternativeScorefileExtensions:
  @result Returns an NSArray of NSStrings.
  @discussion This method allows overriding the file extensions used in writing and
     reading scorefiles files returned by <i>scorefileExtensions</i>.
 */
+ (void) setAlternativeScorefileExtensions: (NSArray *) otherScoreFileExtensions;

/*!
  @method fileExtensions
  @result Returns an NSArray of NSStrings.
  @discussion Returns the possible file extensions used in writing and
              reading scorefiles and MIDI files appropriate for the
              native operating system.
*/
+ (NSArray *) fileExtensions;

/*!
  @method bundleExtensions
  @result Returns an NSArray of NSStrings.
  @discussion Returns the possible file extensions supported by any available
              plugins. It does not make a distinction between extensions supported
              for reading and those for writing, so query each plugin in turn to see
              what it supports.
 */
+ (NSArray *) bundleExtensions;

/*!
  @method score
  @result Returns a newly allocated MKScore instance.
  @discussion Creates and returns an allocated, initialised and autoreleased MKScore instance.
*/
+ (MKScore *) score;

/*!
  @method scoreFormatOfData:
  @abstract Determines the format of the scorefile data.
  @param data An NSData object containing score data, it should be a MIDI file, Scorefile or playscore format.
  @result Returns whether the data is a MIDI file (MK_MIDIFILE), Scorefile (MK_SCOREFILE), playscore (MK_PLAYSCORE).
 */
+ (MKScoreFormat) scoreFormatOfData: (NSData *) fileData;

/*!
  @method scoreFormatOfFile:
  @abstract Determines the format of the named scorefile.
  @param filename The name of the file to be inspected.
  @result Returns the format of the files data.
 */
+ (MKScoreFormat) scoreFormatOfFile: (NSString *) filename;

/*!
  @method writeScorefile:firstTimeTag:lastTimeTag:
  @param  aFileName is a NSString *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @result Returns an id.
  @discussion The same as <b>writeScorefile:</b>, but only those
              MKNotes with timeTags in the specified range are written
              to the file.  Returns the receiver or <b>nil</b> if the
              file couldn't be written.
*/
- writeScorefile: (NSString *) aFileName 
    firstTimeTag: (double) firstTimeTag 
     lastTimeTag: (double) lastTimeTag;

/*!
  @method writeScorefileStream:firstTimeTag:lastTimeTag:
  @param  aStream is a NSMutableData *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @result Returns an id.
  @discussion The same as <b>writeScorefileStream:</b>, but only those
	      MKNotes with timeTags in the specified range are written
	      to the file. Returns the receiver or <b>nil</b> if the
	      file couldn't be written.
*/
- writeScorefileStream: (NSMutableData *) aStream 
          firstTimeTag: (double) firstTimeTag 
           lastTimeTag: (double) lastTimeTag;

/*!
  @method readScorefile:firstTimeTag:lastTimeTag:
  @param  fileName is a NSString *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @result Returns an id.
  @discussion The same as <b>readScorefile:</b>, but only those
	      MKNotes with timeTags in the specified range are added
	      to the receiver.  Returns the receiver or <b>nil</b> if
	      the file couldn't be read.
*/
- readScorefile: (NSString *) fileName 
   firstTimeTag: (double) firstTimeTag 
    lastTimeTag: (double) lastTimeTag;

/*!
  @method readScorefileStream:firstTimeTag:lastTimeTag:
  @param  stream is a NSMutableData *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @result Returns an id.
  @discussion The same as <b>readScorefileStream:</b>, but only those
	      MKNotes with timeTags in the specified range are added
	      to the receiver.   Returns the receiver or <b>nil</b> if
	      the file couldn't be read.
*/
- readScorefileStream: (NSMutableData *) stream 
         firstTimeTag: (double) firstTimeTag 
          lastTimeTag: (double) lastTimeTag;

/*!
  @method writeOptimizedScorefile:firstTimeTag:lastTimeTag:
  @param  aFileName is a NSString *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @result Returns an id.
  @discussion The same as <b>writeOptimizedScorefile:</b>, but only
	      those MKNotes with timeTags in the specified range are
	      written to the file. Returns the receiver or <b>nil</b>
	      if the file couldn't be written.
*/
- writeOptimizedScorefile: (NSString *) aFileName 
             firstTimeTag: (double) firstTimeTag 
              lastTimeTag: (double) lastTimeTag;

/*!
  @method readMidifile:firstTimeTag:lastTimeTag:
  @param  aFileName is a NSString *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @result Returns an id.
  @discussion Reads the midifile <i>aFileName</i> into the receiver.
              The MKNotes that are created are retained in the
              receiver only if their timeTags are within the given
              boundaries.
              
              See the <b>readMidiFileStream</b>: method for a
	      discussion of MIDI to MKNote conversion.  
*/
- readMidifile: (NSString *) aFileName 
  firstTimeTag: (double) firstTimeTag
   lastTimeTag: (double) lastTimeTag;

/*!
  @method readMidifileStream:firstTimeTag:lastTimeTag:
  @param  aStream is a NSMutableData *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @result Returns an id.
  @discussion Reads the midifile from <i>aStream</i> into the
              receiver.  Only the MKNote objects that have timeTags within the
              given boundaries are retained in the receiver.
*/
- readMidifileStream: (NSMutableData *) aStream 
        firstTimeTag: (double) firstTimeTag
         lastTimeTag: (double) lastTimeTag;

/*!
  @method writeMidifile:firstTimeTag:lastTimeTag:
  @param  aFileName is a NSString *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @result Returns an id.
  @discussion Writes the receiver's MKNotes, within the given
              timeTag range,  as a midifile named <i>aFileName</i>.  See
              <b>writeMidifile</b>: for conversion details.
*/
- writeMidifile: (NSString *) aFileName
   firstTimeTag: (double) firstTimeTag
    lastTimeTag: (double) lastTimeTag;

/*!
  @method writeMidifileStream:firstTimeTag:lastTimeTag:
  @param  aStream is a NSMutableData *.
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @result Returns an id.
  @discussion Write the receiver, as a midifile, to <i>aStream</i>. 
              Only the MKNotes within the given timeTag boundaries are written. 
*/
- writeMidifileStream: (NSMutableData *) aStream 
         firstTimeTag: (double) firstTimeTag
          lastTimeTag: (double) lastTimeTag;

/*!
  @method partTitled:
  @param  partTitleToFind
  @discussion Returns the MKPart whose info note has an MK_title parameter
              equal to partTitleToFind, nil if it couldn't be found.
  @result Returns the MKPart, nil if it couldn't be found.
*/
- (MKPart *) partTitled: (NSString *) partTitleToFind;

/*!
  @method partNamed:
  @param  partNameToFind
  @result Returns the MKPart named partNameToFind, nil if it couldn't be found.
 */
- (MKPart *) partNamed: (NSString *) partNameToFind;

@end

#endif
