/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    A MKFilePerformer reads data from a file on the disk,
    fashions a MKNote object from the data, and then performs
    the MKNote.  An abstract superclass, MKFilePerformer
    provides common functionality and declares subclass responsibilities
    for the subclasses
    MKMidifilePerformer and MKScorefilePerformer.
   
    Note: In release 1.0, MKMidifilePerformer is not provided. Use a MKScore object
    to read a Midifile.
   
    A MKFilePerformer is associated with a file, either by the
    file's name or with a file pointer.  If you assoicate
    a MKFilePerformer with a file name (through the setFile:
    method) the object will take care of opening and closing
    the file for you:  the file is opened for reading when the
    MKFilePerformer receives the activate message and closed when
    it receives deactivate.
   
    The setStream: method associates a MKFilePerformer with a file
    pointer.  In this case, opening and closing the file
    is the responsibility of the application.  The MKFilePerformer's
    file pointer is set to NULL after each performance
    so you must send another
    setStream: message in order to replay the file.
   
    Note:  The argument to -setStream: is a NSData or NSMutableData.
   
    The MKFilePerformer class declares two methods as subclass responsibilities:
    nextNote and performNote:.
    nextNote must be subclassed to access the next line of information
    from the file and from it create either a MKNote object or a
    time value.  It
    returns the MKNote that it creates, or, in the case of a time value,
    it sets the instance variable fileTime to represent
    the current time in the file
    and returns nil.
   
    The MKNote created by nextNote is passed as the argument
    to performNote: which
    is responsible
    for performing any manipulations on the
    MKNote and then sending it
    by invoking sendNote:.  The return value of performNote:
    is disregarded.
   
    Both nextNote and performNote: are invoked
    by the perform method, which, recall from the MKPerformer
    class, is itself never called directly but is sent by a Conductor.
    perform also checks and incorporates the time limit
    and performance offset established by the timing window
    variables inherited from MKPerformer; nextNote and
    performNote: needn't access nor otherwise be concerned
    about these variables.
   
    Two other methods, initFile and finishFile, can
    be redefined by a MKFilePerformer subclass, although neither
    must be.  initializeFile is invoked
    when the object is activated and should perform any special
    initialization such as reading the file's header or magic number.
    If initializeFile returns nil, the MKFilePerformer is deactivated.
    The default returns the receiver.
   
    finishFile is invoked when the MKFilePerformer is deactivated
    and should perform any post-performance cleanup.  Its return
    value is disregarded.
   
    A MKFilePerformer reads and performs one MKNote at a time.  This
    allows efficient performance of arbitrarily large files.
    Compare this to the MKScore object which reads and processes the entire file
    before performing the first note.  However, unlike the MKScore object,
    the MKFilePerformer doesn't allow individual timing control over the
    different MKNote streams in the file; the timing window
    specifications inherited from MKPerformer are applied to the entire
    file.
   
    Any number of MKFilePerformers can perform the
    same file concurrently.
 
  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/* 
Modification history:

  $Log$
  Revision 1.11  2002/01/29 16:07:54  sbrandon
  simplified retain/autorelease usage (not bugfixes)

  Revision 1.10  2002/01/23 15:33:02  sbrandon
  The start of a major cleanup of memory management within the MK. This set of
  changes revolves around MKNote allocation/retain/release/autorelease.

  Revision 1.9  2001/09/06 21:27:47  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.8  2001/07/02 16:32:46  sbrandon
  - replaced sel_getName with NSStringFromSelector (hopefully more OpenStep
    compliant)

  Revision 1.7  2000/11/29 00:39:52  leigh
  Corrected comment

  Revision 1.6  2000/04/22 20:16:05  leigh
  Changed fileExtensions to less error-prone NSArray of NSStrings

  Revision 1.5  2000/04/16 04:12:58  leigh
  removed assignment in condition warning

  Revision 1.4  2000/04/02 17:05:06  leigh
  Cleaned up doco

  Revision 1.3  1999/07/29 01:11:58  leigh
  removed last _extraVars fluff, added CVS log

  10/26/89/daj - Added class method fileExtensions for binary scorefile
                 support.
  01/08/90/daj - Flushed _str method. 
  03/21/90/daj - Added archiving. Changed to use _extraVars struct.
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  08/23/90/daj - Changed to zone API.
  03/04/91/daj - Fixed bug in copy and free of _extraVars.
  11/17/92/daj - Flushed _extraPerformerVars to go along with MKPerformer change.
*/

#import "_musickit.h"
#import "_error.h"
#import "PerformerPrivate.h"
#import "MKFilePerformer.h"

@implementation MKFilePerformer

/* METHOD TYPES
 * Initializing a MKFilePerformer
 * Accessing files
 * Accessing MKNotes
 * Performing
 */

#import "timetagInclude.m"

/* Special factory methods. ---------------------------------------- */

#define VERSION2 2

+ (void)initialize
{
    if (self != [MKFilePerformer class])
        return;
    [MKFilePerformer setVersion: VERSION2]; //sb: suggested by Stone conversion guide (replaced self)
    return;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
  /* You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Invokes superclass write: method. Then archives filename, 
     firstTimeTag, and lastTimeTag. 
     */
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeValuesOfObjCTypes:"*ddd",&filename,&firstTimeTag,&lastTimeTag];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* You never send this message directly.  
     Should be invoked via NXReadObject(). 
     See write:. */
{
    [super initWithCoder:aDecoder];
    if ([aDecoder versionForClassName:@"MKFilePerformer"] == VERSION2) {
	[aDecoder decodeValuesOfObjCTypes:"*ddd",&filename,&firstTimeTag,&lastTimeTag];
    }
    return self;
}

-init
  /* TYPE: Initializing; Sent automatically on instance creation.
   * Initializes the receiver by setting stream and filename
   * to NULL.
   * Sent by the superclass upoon creation.
   * You never invoke this method directly.
   * An overriding subclass method should send [super initDefaults]
   * before setting its own defaults. 
   */
{
    [super init];
    lastTimeTag = MK_ENDOFTIME;
    return self;
}

- (void)dealloc
{
    if (filename)
      [filename release];
    [super dealloc];
}

-setFile:(NSString *)aName
  /* TYPE: Modifying; Associates the receiver with file aName.
   * Associates the receiver with file aName. The string is copied.
   * The file is opened when the first MKNote is realized
   * (written to the file) and closed at the end of the
   * performance.
   * It's illegal to invoke this method during a performance. Returns nil
   * in this case. Otherwise, returns the receiver.
   */
{
    if (status != MK_inactive) 
      return nil;
/*
    if (filename) {
	free(filename);
	filename = NULL;
    }
 */
    [filename autorelease];
    filename = [aName copy];
//    filename = _MKMakeStr(aName);
    stream = nil;
    return self;
}

- setStream:(id) aStream
/* * Either NSMutableData, or NSData
   * Sets stream to aStream and sets filename to NULL.
   * aStream must be open for
   * reading.  Returns the receiver.
   * Illegal while the receiver is active. Returns nil in this case, otherwise
   * self.
   */
{
    if (status != MK_inactive) 
        return nil;
    [self setFile:nil];
    [stream autorelease];
    stream = [aStream retain];
    return self;
}

-(id) stream
  /* Either NSMutableData, or NSData
   * Returns the file pointer associated with the receiver
   * or nil if it isn't set.
   * Note that if the file was specified with file: and
   * the performer is inactive (i.e. the file isn't open), this will return
   * nil.
   */
{
    return stream;
}



-(NSString *)file
  /* TYPE: Querying; Returns the name set through setFile:.
   * If the file associated with the receiver was set through 
   * setFile:,
   * returns the file name, otherwise returns NULL.
   */
{
    return filename;
}

+(NSString *)fileExtension
  /* Returns default file extension for files managed by the subclass. The
     default implementation returns NULL. Subclass may override this to
     specify a default file extension. */
{
    return NULL;
}

+(NSArray *)fileExtensions
  /* This method is used when several file extensions must be handled. 
     The value returned by this method is a pointer to a null-terminated
     array of strings, each of which is a valid file extension for files
     handled by the subclass.  Subclass may override this to specify a default 
     file extension.  The default implementation returns 
     an array with one element equal to [self fileExtension]. */
{
    return [NSArray arrayWithObject: [self fileExtension]];
}

/* Methods required by superclasses. ------------------------------- */

-activateSelf
  /* TYPE: Performing; Prepares the receiver for a performance.
   * Invoked by the activate method, this prepares the receiver 
   * for a performance by opening the associated file (if necessary)
   * and invoking nextNote until it returns 
   * an appropriate MKNote -- one with 
   * a timeTag between firstTimeTag
   * and lastTimeTag, inclusive.
   * If an appropriate MKNote isn't found 
   * [self\ deactivate] is sent. 
   *
   * You never send the activateSelf message directly to 
   * a MKFilePerformer.  
   */
{
    if (filename) {
	NSArray *fileExt = [[self class] fileExtensions];
        int fileExtensionsIndex;

        for (fileExtensionsIndex = 0; fileExtensionsIndex < [fileExt count];fileExtensionsIndex++) {
/*	    stream = _MKOpenFileStream(filename,&(_fd(self)),NX_READONLY,
				       *fileExt,NO);
 */
            stream = _MKOpenFileStreamForReading(filename, [fileExt objectAtIndex: fileExtensionsIndex], NO);//sb
            if (stream) {
                [stream retain];
                break;
            }
	} 
	if (!stream)
	  _MKErrorf(MK_cantOpenFileErr,filename);
    }
    fileTime = 0;
    if ((!stream) || (![self initializeFile])) 
      return nil;
    [noteSenders makeObjectsPerformSelector:@selector(_setPerformer:) withObject:self];
    /* The first element in the file may be a time or a note. If it's a note,
       than its time is implicitly 0. Since we don't lookahead unless 
       firstTimeTag > 0, it is guaranteed that this note will not be overlooked.
       */
    if (firstTimeTag > 0) {
        for (; ;) {
            [self nextNote];
            if (fileTime > (MK_ENDOFTIME-1))  {
                [self deactivate];
                return nil;
            }
            if (fileTime >= firstTimeTag)
                break;
        }
    }
    /* Insure we run for the first time on our first note. */
//  nextPerform = fileTime - firstTimeTag;
    nextPerform = fileTime;
    return self;
}

-perform 
  /* TYPE: Performing
   * Grabs the next MKNote out of the file through nextNote,
   * processes it through 
   * performNote: (the method that sends the MKNote), and
   * sets the value of nextPerform. 
   * You may override this method to modify nextPerform, but you must
   * send [super perform].
   * You never send perform directly to an object.
   * Returns the receiver.
   */
{
    id aNote;
    double t = fileTime;
    while ((aNote = [self nextNote])) {
      [aNote retain]; /* to be on the safe side */
      [self performNote:aNote];
      [aNote release];
    }
    if (fileTime > (MK_ENDOFTIME-1) || fileTime >= lastTimeTag) 
      [self deactivate];
    else 
      nextPerform = fileTime - t;
    return self;
}

/* Methods which must be supplied by subclass. ---------------- */

-performNote:(id)aNote
  /* TYPE: Accessing MKNotes
   * This is a subclass responsibility expected to manipulate
   * and send aNote which was presumably just read from a file.
   * It's up to the subclass to free aNote. 
   *
   * You never send the performNote: message 
   * directly to a MKFilePerformer; it's invoked by the perform
   * method.
   */
{
    [NSException raise:NSInvalidArgumentException format:@"*** Subclass responsibility: %s", NSStringFromSelector(_cmd)]; return nil;
}

-(id)nextNote     
  /* TYPE: Accessing MKNotes
   * This is a subclass responsibility expected to get the next MKNote
   * from the file.  Should return the MKNote or nil if the
   * next file entry is a performance time.  In the latter case,
   * this should update fileTime.
   *
   * You never send the nextNote message 
   * directly to a MKFilePerformer; it's invoked by the perform
   * method.
   */
{
    [NSException raise:NSInvalidArgumentException format:@"*** Subclass responsibility: %s", NSStringFromSelector(_cmd)]; return nil;
}

-initializeFile
  /* TYPE: Performing; Preparing the file for a performance.
   * This is a subclass responsibility expected to perform 
   * any special file initialization and return the receiver.
   * If nil is returned, the receiver is deactivated.
   *
   * You never send the initializeFile message 
   * directly to a MKFilePerformer; it's invoked by the activateSelf
   * method.
   *
   */
{
    return self;
}

- (void)deactivate 
  /* TYPE: Performing; Cleans up after a performance.
   * Invokes finishFile, closes the file (if it was 
   * set through setFile:), and sets the file pointer
   * to NULL.
   */
{
   [super deactivate];  // added by LMS - never stopped the performance.
   if (stream)
     [self finishFile];
   if (filename) {
       [stream release];
   }
   stream = nil;
}

-finishFile
  /* TYPE: Performing; Cleans up after a performance.
   * Subclass should override this to do any cleanup
   * needed after a performance -- however, you shouldn't 
   * close the file pointer as part of this method.
   *
   * You never send the finishFile message directly to a
   * MKFilePerformer; it's invoked by the deactivate method.
   */
{
    return self;
} 

- copyWithZone:(NSZone *)zone
  /* The returned value is a copy of the receiver, with a copy of the filename
     and stream set to NULL. The MKNoteSenders are not copied (the superclass
     copy method is overridden); instead, an empty list is given.  */
{
    MKFilePerformer *newObj = [super _copyFromZone:zone];
    newObj->filename = [filename copy];//_MKMakeStr(filename);
    newObj->stream = nil;
    return newObj;
}

@end

