/*
  $Id$
  Defined In: The MusicKit

  Description:
    A MKFileWriter is an MKInstrument that realizes MKNotes by writing them to
    a file on the disk. An abstract superclass, MKFileWriter
    provides common functionality and declares subclass responsibilities
    for the subclasses MKMidifileWriter and MKScorefileWriter.
    Note: In this release, MKMidifileWriter is not provided. Use a MKScore object
    to write a Midifile.

    A MKFileWriter is associated with a file, either by the
    file's name or with a file pointer.  If you assoicate
    a MKFileWriter with a file name (through the setFile:
    method) the object will take care of opening and closing
    the file for you:  the file is opened for writing when the
    object first receives the realizeNote: message
    and closed after the performance.  The
    file is overwritten each time it's opened.

    The setStream: method associates a MKFileWriter with a file
    pointer.  In this case, opening and closing the file
    is the responsibility of the application.  The MKFileWriter's
    file pointer is set to NULL after each performance.

    To design a subclass of MKFileWriter you must implement
    the method realizeNote:fromNoteReceiver:.

    Two other methods, initializeFile and finishFile, can
    be redefined in a subclass, although neither
    must be.  initializeFile is invoked
    just before the first MKNote is written to the
    file and should perform any special
    initialization such as writing a file header.

    finishFile is invoked after each performance
    and should perform any post-performance cleanup.
    The values returned by initializeFile and finishFile are ignored.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project. 
*/
/*!
  @class MKFileWriter
  @brief A MKFileWriter is an MKInstrument that realizes MKNotes by writing them to a file on
  the disk.  An abstract class, MKFileWriter provides common functionality for the
  MusicKit subclasses such as MKScorefileWriter (currently the only subclass of
  MKFileWriter).

A MKFileWriter is associated with a file on disk or a data object, either by the file's
name or through an NSMutableData object.  If you associate a MKFileWriter with a file
name (through the <b>setFile:</b> method) the object opens and closes the file for you:
The file is opened for writing when the object first receives the <b>realizeNote:</b>
message and closed after the performance.  A MKFileWriter remembers its file name
between performances, but the file is overwritten each time it's
opened.

The <b>setStream:</b> method sets the FileWriter's <b>stream</b> instance
variable to the given NSMutableData object.  Creating and saving the NSMutableData
object is the responsibility of the application.  After each performance, <b>stream</b>
is set to nil.

The subclass responsibility <b>realizeNote:fromNoteReceiver:</b>, inherited from
MKInstrument, is passed on to the MKFileWriter subclasses.  Two other methods,
<b>initializeFile</b> and <b>finishFile</b>, can be redefined in a subclass,
although neither must be.  <b>initializeFile</b> is invoked just before the
first MKNote is written to the file and should perform any special initialization
such as writing a file header.  <b>finishFile</b> is invoked after each
performance and should perform any post-performance cleanup.  The values
returned by <b>initializeFile</b> and <b>finishFile</b> are ignored.
*/
#ifndef __MK_FileWriter_H___
#define __MK_FileWriter_H___

#import <Foundation/Foundation.h>

#import "MKInstrument.h"
#import "timeunits.h"

@interface MKFileWriter : MKInstrument
{
    MKTimeUnit timeUnit;
    NSMutableString *filename;        /* Or NULL. */
    NSMutableData *stream;            /* Pointer of open file. */
    double timeShift;
    BOOL compensatesDeltaT;
    int _fd;
}

/*!
  @return Returns an id.
  @brief Initializes the object by setting both <b>stream</b> and
  <b>filename</b> to NULL.

  You must invoke this method when creating
  a new instance of MKFileWriter.  A subclass implementation should send
  [<b>super init</b>] before performing its own initialization.  The
  return value is ignored.
*/
- init; 

/*!
  @param  aTimeUnit is a MKTimeUnit.
  @return Returns an id.
  @brief Sets the unit in which the object measures time.

  <i>aTimeUnit</i>
  can be <b>MK_second</b> for measurement in seconds,  <b>MK_beat</b>
  for beats or <b>MK_timeTag</b> for the value in the Note's timeTag
  field.  The default is <b>MK_second</b>.
*/
- setTimeUnit: (MKTimeUnit) aTimeUnit;

/*!
  @return Returns a MKTimeUnit.
  @brief Returns the unit in which the object measures time, either
  <b>MK_second</b>, <b>MK_timeTag</b> or <b>MK_beat</b>.

  The default
  is <b>MK_second</b>.
*/
- (MKTimeUnit) timeUnit;

/*!
  @return Returns a NSString.
  @brief Returns the file extension used by the object.

  The default
  implementation returns the value of the <b>fileExtension</b> class
  method.  A subclass can implement this method to allow different
  default file extensions for different instances.
*/
+ (NSString *) fileExtension;

/*!
  @return Returns a NSString.
  @brief Returns the file extension used by the object.

  The default
  implementation returns the value of the <b>fileExtension</b> class
  method.  A subclass can implement this method to allow different
  default file extensions for different instances.
*/
- (NSString *) fileExtension;

/*!
  @param  aName is a NSString.
  @return Returns an id.
  @brief Associates the object with the file <i>aName</i>.

  The file is
  opened when the first MKNote is realized (written to the file) and
  closed at the end of the performance.  If the object is already in a
  performance, this does nothing and returns <b>nil</b>, otherwise
  returns the object.
*/
- setFile: (NSString *) aName; 

/*!
  @param  aStream is an NSMutableData.
  @return Returns an id.
  @brief Points the object's <b>stream</b> pointer to <i>aStream</i>.

  You
  must open and close the <i>aStream</i> yourself.  If the object is
  already in a performance, this does nothing and returns <b>nil</b>,
  otherwise returns the object.
*/
- setStream: (NSMutableData *) aStream; 

/*!
  @return Returns an NSMutableData.
  @brief Returns the object's <b>stream</b> pointer, or NULL if it isn't set.

  The pointer is set to NULL after each performance.
*/
- (NSMutableData *) stream; 

/*!
  @param  zone is an NSZone.
  @return Returns an id.
  @brief Creates and returns a copy of the object.

  The new object's
  <i>filename</i> and <i>stream</i> instance variables are set to
  NULL.
*/
- copyWithZone: (NSZone *) zone; 

/*!
  @return Returns an NSString.
  @brief Returns the object's file name, if any.
*/
- (NSString *) file; 

/*!
  @return Returns an id.
  @brief This can be overridden by a subclass to perform post-performance
  activities.

  You never send the <b>finishFile</b>
  message directly to a MKFileWriter; it's invoked automatically after
  each performance.  The return value is ignored.
*/
- finishFile; 

/*!
  @return Returns an id.
  @brief This can be overriden by a subclass to perform file initialization,
  such as writing a file header.

  You never send the
  <b>initializeFile</b> message directly to a MKFileWriter; it's invoked
  from the <b>firstNote:</b> method.  The return value is
  ignored.
*/
- initializeFile; 

/*!
  @brief You never invoke this method; it's invoked automatically just before
  the object writes its first MKNote.

  It opens a stream to the object's
  <i>filename</i> (if set) and then sends <b>initializeFile</b> to the
  object.
  @param  aNote is an id.
  @return Returns an id.
*/
- firstNote: (MKNote *) aNote; 

/*!
  @return Returns an id.
  @brief You never invoke this method; it's invoked automatically just after
  a performance.

  It closes the object's <i>stream</i> (if the object
  opened it itself in the <b>firstNote:</b> method) and sets it to
  NULL.
*/
- afterPerformance; 

/*!
  @return Returns a double.
  @brief Returns the object's performance time offset, in seconds.
*/
- (double) timeShift;

/*!
  @brief Sets a constant value to be added to MKNotes' times when they are
  written out to the file.

  It's up to the subclass to use this value.
  @param  timeShift is a double.
  @return Returns an id.
*/
- setTimeShift: (double) timeShift;

- (void) encodeWithCoder: (NSCoder *) aCoder;
- (id) initWithCoder: (NSCoder *) aDecoder;

@end

#endif
