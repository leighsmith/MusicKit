/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#ifdef SHLIB
#include "shlib.h"
#endif

/*
  FileWriter.m
  Responsibility: David A. Jaffe
  
  DEFINED IN: The Music Kit
  HEADER FILES: musickit.h
*/
/* 
Modification history:

  10/26/89/daj - Added instance fileExtension method for binary scorefile
                 support.
  03/21/90/daj - Added archiving.
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  08/23/90/daj - Changed to zone API.
  01/02/91/daj - Fixed bug in firstNote: involving file extensions

*/

#import "_musickit.h"
#import "_noteRecorder.h"
#import "_error.h"
#import "MKNote.h"

#import "MKFileWriter.h"
#import "InstrumentPrivate.h" /*sb: moved to here from within implementation...! */

@implementation MKFileWriter:MKInstrument
/* A FileWriter is an Instrument that realizes Notes
 * by writing them to a file on the disk.
 * An abstract superclass, FileWriter
 * provides common functionality and declares subclass responsibilities
 * for the subclasses
 * MidifileWriter and ScorefileWriter.
 * Note: In release 1.0, MidifileWriter is not provided. Use a Score object
 * to write a Midifile.
 * 
 * A FileWriter is associated with a file, either by the
 * file's name or with a file pointer.  If you assoicate
 * a FileWriter with a file name (through the \fBsetFile:\fR
 * method) the object will take care of opening and closing
 * the file for you:  the file is opened for writing when the
 * object first receives the \fBrealizeNote:\fR message
 * and closed after the performance.  The 
 * file is overwritten each time it's opened.
 *
 * The \fBsetStream:\fR method associates a FileWriter with a file
 * pointer.  In this case, opening and closing the file
 * is the responsibility of the application.  The FileWriter's
 * file pointer is set to \fBNULL\fR after each performance.
 *
 * To design a subclass of FileWriter you must implement
 * the method \fBrealizeNote:fromNoteReceiver:\fR.
 *
 * Two other methods, \fBinitializeFile\fR and \fBfinishFile\fR, can
 * be redefined in a subclass, although neither
 * must be.  \fBinitializeFile\fR is invoked 
 * just before the first Note is written to the 
 * file and should perform any special
 * initialization such as writing a file header.
 *
 * \fBfinishFile\fR is invoked after each performance
 * and should perform any post-performance cleanup.  The values returned
 * by \fBinitializeFile\fR and \fBfinishFile\fR are ignored.
 */
{
    MKTimeUnit timeUnit;
    NSMutableString *filename;        /* Or NULL. */
    NSMutableData *stream;            /* Pointer of open file. */
    double timeShift;
    BOOL compensatesDeltaT;
    int _fd;
}

#import "noteRecorderMethods.m"

#define VERSION2 2
#define VERSION3 3 /* Changed Nov 7, 1992 */

+ (void)initialize
{
    if (self != [MKFileWriter class])
      return;
    [MKFileWriter setVersion:VERSION3];//sb: suggested by Stone conversion guide (replaced self)
    return;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
  /* TYPE: Archiving; Writes object to archive file.
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Invokes superclass write: method. Then archives timeUnit, filename, 
     and timeShift. 
     */
{
    [super encodeWithCoder:aCoder];
    NSAssert((sizeof(MKTimeUnit) == sizeof(int)), @"write: method error.");
    [aCoder encodeValuesOfObjCTypes:"i@d",&timeUnit,&filename,&timeShift];//sb: was i*d
    [aCoder encodeValuesOfObjCTypes:"c",&compensatesDeltaT];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* TYPE: Archiving; Reads object from archive file.
     You never send this message directly.  
     Should be invoked via NXReadObject(). 
     See write:. */
{
    int version;
    [super initWithCoder:aDecoder];
    version = [aDecoder versionForClassName:@"FileWriter"];
    if (version >= VERSION2)
        [aDecoder decodeValuesOfObjCTypes:"i@d",&timeUnit,&filename,&timeShift];//sb: was i*d
    if (version >= VERSION3)
      [aDecoder decodeValuesOfObjCTypes:"c",&compensatesDeltaT];
    return self;
}

-init     
  /* Does instance initialization. Sent by superclass on creation. 
     If subclass overrides this method, it must send [super init]
     before setting its own defaults. */
{
    [super init];
    timeUnit = MK_second;
    stream = nil;
    filename = [NSMutableString string];//sb: was NULL;
    return self;
}

+(NSString *)fileExtension
  /* Returns default file extension for files managed by the subclass. The
     default implementation returns NULL. Subclass may override this to
     specify a default file extension. */
{
    return nil;
}

-(NSString *)fileExtension
  /* Returns default file extension for files managed by the subclass. The
     default implementation just invokes the fileExtension method.
     A subclass can override this to provide a fileExtension on an instance-
     by-instance basis. For example ScorefileWriter returns a different
     default extension for binary format scorefiles. */
{
    return [[[[self class] fileExtension] retain] autorelease];
}

- (void)dealloc
{
    if (filename)
      [filename release];
    [super dealloc];
}

-setFile:(NSString *)aName
  /* TYPE: Modifying; Associates the receiver with file \fIaName\fR.
   * Associates the receiver with file \fIaName\fR. The string is copied.
   * The file is opened when the first Note is realized
   * (written to the file) and closed at the end of the
   * performance.
   *
   * sb: NOT TRUE. NSData method of doing things (as opposed to stream)
   * means that file is not written until all finished.
   *
   * It's illegal to invoke this method during a performance. Returns nil
   * in this case. Otherwise, returns the receiver.
   */
{
    if (_noteSeen)
      return nil;
    [filename autorelease];
    filename = [aName copy];
    if (stream) {
        [stream autorelease];
        stream = nil;
        }
    return self;
}


-setStream:(NSMutableData *)aStream
  /* TYPE: Modifying; Associates the receiver with file pointer \fIaStream\fR.
   * Associates the receiver with the file pointer \fIaStream\fR.
   * You must open and close the file yourself.
   * Returns the receiver.
   * It's illegal to invoke this method during a performance. Returns nil
   * in this case. Otherwise, returns the receiver. 
   */
{
    if (_noteSeen)
      return nil;
    [self setFile:nil];
    if (stream)
        [stream autorelease];
    stream = [aStream retain];
    return self;
}

-(NSMutableData *)stream
  /* TYPE: Querying; Returns the receiver's file pointer.
   * Returns the file pointer associated with the receiver
   * or \fBNULL\fR if it isn't set.
   * Note that the receiver's file pointer is set to \fBNULL\fR 
   * after each performance.
   *
   * sb: now returns a NSMutableData object that can be written to.
   */
{
    return [[stream retain] autorelease];
}

- copyWithZone:(NSZone *)zone
  /* The returned value is a copy of the receiver, with a copy of the filename
     and stream set to NULL. */
{
    MKFileWriter *newObj = [super copyWithZone:zone];
    if (filename)
      newObj->filename = [filename copy];
    newObj->stream = nil;
    return newObj;
}

-(NSString *)file
  /* TYPE: Querying; Returns the name set through \fBsetFile:\fR.
   * If the file associated with the receiver was set through 
   * \fBsetFile:\fR,
   * returns the file name, otherwise returns NULL.
   */
{
    return [[filename retain] autorelease];
}



-(double)timeShift 
  /* TYPE: Accessing time; Returns the receiver's performance begin time.
   * Returns the receiver's performance begin time, as set through
   * \fBsetTimeShift:\fR.
   */
{
	return timeShift;
}

-setTimeShift:(double)shift
  /* TYPE: Accessing time; Delays performance for \fIshift\fR beats.
   * Sets the begin time of the receiver;
   * the receiver's performance is delayed by \fIshift\fR beats.
   * Returns the receiver.
   * Illegal while the receiver is active. Returns nil in this case, else self.
   */
{	
    if ([self inPerformance])
      return nil;
    timeShift = shift;
    return self;
}		

-finishFile
  /* TYPE: Accessing; Cleans up after a performance.
   * This can be overridden by a subclass to perform any cleanup
   * needed after a performance.  You shouldn't 
   * close the file pointer as part of this method.
   * The return value is ignored; the default returns the receiver.
   *
   * You never send the \fBfinishFile\fR message directly to a
   * FileWriter; it's invoked automatically after each performance.
   */
{
    return self;
}

-initializeFile
  /* TYPE: Accessing; Prepares the file for writing.
   * This can be overriden by a subclass to perform
   * file initialization, such as writing a file header..
   * The return value is ignored; the default returns the receiver.
   *
   * You never send the \fBinitializeFile\fR message 
   * directly to a FileWriter; it's invoked when the first \fBrealizeNote:\fR
   * message is received.
   */
{
    return self;
}

-firstNote:aNote
  /* You never send this message.  Overrides superclass method to initialize
     file. */
{
    if (filename) {
        [stream autorelease]; /* get rid of old one */
        stream = [NSMutableData data];
        }
/* sb: now defers writing and opening until finished */
/*      _MKOpenFileStream(filename,&_fd,NX_WRITEONLY,
				 [self fileExtension],YES);
 */
//    if (!stream) 
//      return nil;
    [self initializeFile];
    return self;
}

-afterPerformance
    /* You never send this message. Overrides superclass method to finish up */
{
    [self finishFile];
    if (filename) {
//#error StreamConversion: NXFlush should be converted to an NSData method
//	NXFlush(stream);
        if (![stream writeToFile:[filename stringByAppendingPathExtension:[self fileExtension]] atomically:YES])
            _MKErrorf(MK_cantCloseFileErr,filename);
        [stream autorelease];
/*
	if (close(_fd) == -1)
	  _MKErrorf(MK_cantCloseFileErr,filename);
 */
    }
    stream = nil;
    return self;
}

@end

