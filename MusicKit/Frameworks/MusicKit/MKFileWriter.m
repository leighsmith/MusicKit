/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

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
  Portions Copyright (c) 1994 Stanford University 
*/
/* 
Modification history:

  $Log$
  Revision 1.8  2004/12/06 18:27:35  leighsmith
  Renamed _MKErrorf() to meaningful MKErrorCode(), now void, rather than returning id

  Revision 1.7  2004/10/25 16:22:50  leighsmith
  Updated for new ivar name

  Revision 1.6  2002/01/29 16:07:54  sbrandon
  simplified retain/autorelease usage (not bugfixes)

  Revision 1.5  2002/01/15 12:17:33  sbrandon
  Fixed up autorelease/release errors with stream and filename. Potential
  crashers.

  Revision 1.4  2001/09/06 21:27:47  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.3  2000/04/16 04:09:32  leigh
  comment cleanup

  Revision 1.2  1999/07/29 01:16:36  leigh
  Added Win32 compatibility, CVS logs, SBs changes

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

@implementation MKFileWriter

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
    version = [aDecoder versionForClassName:@"MKFileWriter"];
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
    filename = nil;
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
     by-instance basis. For example MKScorefileWriter returns a different
     default extension for binary format scorefiles. */
{
    /* no need to retain/autorelease since class method should do this*/
    return [[self class] fileExtension]; 
}

- (void)dealloc
{
    [filename release];
    [super dealloc];
}

- setFile: (NSString *) aName
  /* TYPE: Modifying; Associates the receiver with file aName.
   * Associates the receiver with file aName. The string is copied.
   * The file is opened when the first MKNote is realized
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
    if (noteSeen)
	return nil;
    [filename autorelease];
    filename = [aName retain];
    if (stream) {
        [stream autorelease];
        stream = nil;
    }
    return self;
}


- setStream: (NSMutableData *) aStream
  /* TYPE: Modifying; Associates the receiver with file pointer aStream.
   * Associates the receiver with the file pointer aStream.
   * You must open and close the file yourself.
   * Returns the receiver.
   * It's illegal to invoke this method during a performance. Returns nil
   * in this case. Otherwise, returns the receiver. 
   */
{
    if (noteSeen)
	return nil;
    [self setFile: nil];
    [stream autorelease];
    stream = [aStream retain];
    return self;
}

-(NSMutableData *)stream
  /* TYPE: Querying; Returns the receiver's file pointer.
   * Returns the file pointer associated with the receiver
   * or NULL if it isn't set.
   * Note that the receiver's file pointer is set to NULL 
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
    newObj->filename = [filename retain];
    newObj->stream = nil;
    return newObj;
}

-(NSString *)file
  /* TYPE: Querying; Returns the name set through setFile:.
   * If the file associated with the receiver was set through 
   * setFile:,
   * returns the file name, otherwise returns nil.
   */
{
    return [[filename retain] autorelease];
}



-(double)timeShift 
  /* TYPE: Accessing time; Returns the receiver's performance begin time.
   * Returns the receiver's performance begin time, as set through
   * setTimeShift:.
   */
{
	return timeShift;
}

-setTimeShift:(double)shift
  /* TYPE: Accessing time; Delays performance for shift beats.
   * Sets the begin time of the receiver;
   * the receiver's performance is delayed by shift beats.
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
   * You never send the finishFile message directly to a
   * MKFileWriter; it's invoked automatically after each performance.
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
   * You never send the initializeFile message 
   * directly to a MKFileWriter; it's invoked when the first realizeNote:
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
        stream = [[NSMutableData alloc] initWithCapacity:0];
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
        if (![stream writeToFile:[filename stringByAppendingPathExtension:[self fileExtension]] atomically:YES])
            MKErrorCode(MK_cantCloseFileErr,filename);
/*
	if (close(_fd) == -1)
	  MKErrorCode(MK_cantCloseFileErr,filename);
 */
    }
    [stream release];
    stream = nil;
    return self;
}

@end

