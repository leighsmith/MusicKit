/*
 $Id$
 Defined In: The MusicKit
 HEADER FILES: MusicKit.h

 Description:
 A MKScore contains a collection of MKParts and has methods for manipulating
 those MKParts. MKScores and MKParts work closely together.
 MKScores can be performed.
 The MKScore can read or write itself from a scorefile or midifile.

 Original Author: David A. Jaffe

 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
 Portions Copyright (c) 1994 Stanford University
 Portions Copyright (c) 1999-2000, The MusicKit Project.
 */
/*
 Modification history:

 $Log$
 Revision 1.36  2003/12/31 00:32:53  leighsmith
 Cleaned up naming of methods, removing underscores

 Revision 1.35  2003/08/04 21:14:33  leighsmith
 Changed typing of several variables and parameters to avoid warnings of mixing comparisons between signed and unsigned values.

 Revision 1.34  2002/08/20 23:26:02  leighsmith
 Removed warning of undeclared method class in bundleExtensions, added setAlternativeScorefileExtensions: to allow alternative names for scorefiles

 Revision 1.33  2002/05/01 14:33:35  sbrandon
 Added static array to hold plugins, added +bundleExtensions to return info collected from plugins, added documentation from the Standard MIDI File Spec defining how time signatures are stored, added the implementation of +addPlugin:, fixed a problem in score merging that caused an endless loop under certain situations, altered readScoreFile to try to open files with plugins if extension is appropriate.
 Note that the plugin implementation is under review.

 Revision 1.32  2002/04/03 03:59:41  skotmcdonald
 Bulk = NULL after free type paranoia, lots of ensuring pointers are not nil before freeing, lots of self = [super init] style init action

 Revision 1.31  2002/03/12 22:52:56  sbrandon
 Changed some of the ways that the list of parts is dealt with. Specifically,
 changed to indexOfObjectIdenticalTo: from indexOfObject, since the isEqual:
 method on MKPart now does a deep compare.

 Revision 1.30  2002/03/06 07:54:34  skotmcdonald
 Added method partNamed which returns the MKPart with a given info-note title

 Revision 1.29  2002/01/23 15:33:02  sbrandon
 The start of a major cleanup of memory management within the MK. This set of
 changes revolves around MKNote allocation/retain/release/autorelease.

 Revision 1.28  2002/01/15 12:14:35  sbrandon
 replaced [NSMutableData data] with alloc:initWithCapacity: so as to prevent
 auto-released data - we release it manually when finished with it.

 Revision 1.27  2001/11/16 19:56:45  skotmcdonald
 Added scaleTime method to MKPart and MKScore, which adjusts the timeTags and durations of notes by a scaling factor (useful for compensating for changes in score tempo). Note: parameters inside individual MKNotes (apart from MK_dur) will need to receive scaling msgs, eg envelopes that match physical sample or synthesis parameters that should(n't) be scaled... a conundrum for discussion at present.

 Revision 1.26  2001/09/06 21:27:48  leighsmith
 Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

 Revision 1.25  2001/08/07 16:17:06  leighsmith
 Cleaned up encoding and decoding

 Revision 1.24  2001/02/23 03:29:44  leigh
 Removed redundant and dangerous releasePartsOnly method

 Revision 1.23  2000/11/28 19:02:50  leigh
 replaced malloc with _MKMalloc (which does error checking), added -fileExtensions, -scorefileExtensions, changed -midiExtensions to produce a list of possible midifile extensions

 Revision 1.22  2000/11/25 22:27:55  leigh
 Removed redundant and potentially bug inducing releaseParts

 Revision 1.21  2000/11/21 19:34:27  leigh
 *** empty log message ***

 Revision 1.20  2000/06/09 18:05:59  leigh
 Added braces to reduce finicky compiler warnings

 Revision 1.19  2000/06/09 15:01:03  leigh
 typed the parameter returned by -parts

 Revision 1.18  2000/05/26 21:03:19  leigh
 Added combineNotes to do the combination over all MKParts

 Revision 1.17  2000/05/06 02:41:32  leigh
 putSysExcl allocates a mutable char array to operate on, since _MKGetSysExByte writes to the string pointer

 Revision 1.16  2000/05/06 00:29:36  leigh
 Converted tagTable to NSMutableDictionary

 Revision 1.15  2000/04/26 01:20:27  leigh
 Corrected readScorefileStream to take a NSData instead of NSMutableData instance

 Revision 1.14  2000/04/25 02:08:40  leigh
 Renamed free methods to release methods to reflect OpenStep behaviour

 Revision 1.13  2000/04/16 04:22:44  leigh
 Comment cleanup and removed assignment in condition warning

 Revision 1.12  2000/04/03 23:45:42  leigh
 Added description method

 Revision 1.11  2000/03/31 00:09:31  leigh
 Adopted OpenStep naming of factory methods

 Revision 1.10  2000/03/29 03:17:47  leigh
 Cleaned up doco and ivar declarations

 Revision 1.9  2000/03/11 01:11:24  leigh
 Reading instrument and track names in level 1 MIDI files now are stored in the MKPart infoNote

 Revision 1.8  2000/02/11 22:52:39  leigh
 Fixed memory leak reading scorefiles

 Revision 1.7  2000/02/08 04:15:18  leigh
 Added +midifileExtension

 Revision 1.6  2000/02/08 03:16:05  leigh
 Improved MIDI file writing, generating separate tempo track with MKPart info entries

 Revision 1.5  1999/10/10 01:10:22  leigh
 MIDI mode messages read from SMF0 files now receive MK_midiChan parameters so MKScores read from SMF1 or SMF0 behave the same.

 Revision 1.4  1999/09/04 22:02:18  leigh
 Removed mididriver source and header files as they now reside in the MKPerformMIDI framework

 Revision 1.3  1999/08/06 00:38:10  leigh
 converted strtols to NSScanners

 Revision 1.2  1999/07/29 01:16:42  leigh
 Added Win32 compatibility, CVS logs, SBs changes

 12/8/89/daj  - Fixed bug in midi-file reading -- first part was being
 initialized to a bogus info object.
 12/15/89/daj - Changed how Midi channel is encoded and written so that the
 information is not lost when reading/writing a format 1
 file.
 12/20/89/daj - Added writeOptimizedScorefile: and
 writeOptimizedScorefileStream:
 01/08/90/daj - Added clipping of firstTimeTag in readScorefile().
 02/26-28/90/daj - Changes to accomodate new way of doing midiFiles.
 Added midifile sys excl and meta-event support.
 03/13/90/daj - Changes for new categories for private methods.
 03/19/90/daj - Changed to use MKGetNoteClass(), MKGetPartClass().
 03/21/90/daj - Added archiving.
 03/27/90/daj - Added 10 new scorefile methods to make the scorefile and
 midifile cases look the same. *SIGH*
 04/21/90/daj - Small mods to get rid of -W compiler warnings.
 04/23/90/daj - Changes to make it a shlib and to make header files more
 modular.
 05/16/90/daj - Got rid of the "fudgeTime" kludge in the MIDI file reader,
 now that the MKPart object's been fixed to insure correct
 ordering. Added check for clas of MKPart class in setPart:.
 06/10/90/daj - Fixed bug in writing of scorefiles.
 07/24/90/daj - Removed unneeded copy of Note from readScorefile. Then
 added it back because it actually sped things up.
 08/31/90/daj - Added import of stdlib.h and define of NOT_YET
 09/26/90/daj - Fixed minor bug in freeNotes.
 12/18/90/daj - Added [parts free] to -free to fix memory leak.
 Added MKMIDIFileEndReading() calls to fix memory leak.
 07/08/91/daj - Was off by one in putSysExcl.
 17/01/92/daj - Fixed midifile tempo bug.
 9/03/92/daj - Fixed writing of scorefiles to preserve Part Note List
 ordering.
 17/06/92/daj - When writing midifile, changed it so that if there is no
 title: parameter, the part name of the first part is used.
 19/10/92/daj - Fixed a bug in scorefile merge function.
 11/17/92/daj - Minor change to shut up compiler warnings.
 11/18/92/daj - Removed bogus comment.
 6/26/93/daj - Added replacePart:with: method.
 */

#import <stdlib.h>
#import "_musickit.h"
#import "PartPrivate.h"
#import "NotePrivate.h"
#import "MKPlugin.h"
#import "_midi.h"
#import "midifile.h"
#import "tokens.h"
#import "_error.h"

#import "ScorePrivate.h"

static NSMutableArray *plugins = nil;
static NSArray *scoreFileExtensions = nil;

@implementation MKScore

#define READIT 0
#define WRITEIT 1

/* Creation and freeing ------------------------------------------------ */

#define VERSION2 2

+ (void)initialize
{
    if (self != [MKScore class])
        return;
    [MKScore setVersion: VERSION2]; //sb: suggested by Stone conversion guide (replaced self)
    _MKCheckInit();
    scoreFileExtensions = [[NSArray arrayWithObjects: _MK_SCOREFILEEXT, _MK_BINARYSCOREFILEEXT, nil] retain];
}

+ score
  /* Create a new instance and sends [self init]. */
{
  self = [self allocWithZone:NSDefaultMallocZone()];
  [self init];
  return [self autorelease];
}

-init
  /* TYPE: Creating and freeing a MKPart
* Initializes the receiver:
  *
  *  * Creates a new notes collection.
  *
  * Sent by the superclass upon creation;
  * you never invoke this method directly.
  * An overriding subclass method should send [super initialize]
  * before setting its own defaults.
  */
{
  self = [super init];
  if (self != nil) {
    parts = [NSMutableArray new];
  }
  return self;
}

-releaseNotes
  /* Releases the notes contained in the parts. Does not releaseParts
  nor does it release the receiver. Implemented as
  [parts makeObjectsPerformSelector:@selector(releaseNotes)];
  Also releases the receivers info note.
  */
{
  [parts makeObjectsPerformSelector:@selector(releaseNotes)];
  [info release];
  info = nil;
  return self;
}

- (void)dealloc
  /* Frees receiver, parts and MKNotes, including info note. */
{
  if (parts != nil) {
    [parts makeObjectsPerformSelector:@selector(_unsetScore)];
  //    [parts removeAllObjects];          // LMS redundant
    [parts release];
    parts = nil;
  }
  if (info != nil) {
    [info release];
    info = nil;
  }
  [super dealloc];
}

- (void)removeAllParts
  /* TYPE: Modifying; Removes the receiver's MKParts.
  * Removes the receiver's MKParts.
  * Returns the receiver.
  */
{
  [parts makeObjectsPerformSelector:@selector(_unsetScore)];
  [parts removeAllObjects];
  return;
}

/* Reading Scorefiles ------------------------------------------------ */

/* forward ref */
static id readScorefile(MKScore *self, NSData *stream,
                        double firstTimeTag, double lastTimeTag, double timeShift, NSString *fileName);

-readScorefile:(NSString *)fileName
  firstTimeTag:(double)firstTimeTag
   lastTimeTag:(double)lastTimeTag
     timeShift:(double)timeShift
  /* Read from scoreFile to receiver, creating new MKParts as needed
  and including only those notes between times firstTimeTag to
  time lastTimeTag, inclusive. Note that the TimeTags of the
  notes are not altered from those in the file. I.e.
  the first note's TimeTag will be greater than or equal to
  firstTimeTag.
  Merges contents of file with current MKParts when the MKPart
  name found in the file is the same as one of those in the
  receiver.
  Returns self or nil if file not found or the parse was aborted
  due to errors. */
{
  NSData *stream;
  id rtnVal;
  int i,count;
  id e = [fileName pathExtension];
  MKLoadAllBundlesOneOff();
  count=[plugins count];
  if ([[MKScore bundleExtensions] containsObject:e]) {
      for (i = 0 ; i < count ; i++) {
          id<MusicKitPlugin> p = [plugins objectAtIndex:i];
          if ([[p fileOpeningSuffixes] containsObject:e]) {
              id s = [p openFileName:fileName forScore:self];
              if (s) return s;
              else NSLog(@"Plugin failed to read file, though it should have managed");
          }
      }
  }
  
  stream = _MKOpenFileStreamForReading(fileName,
                                       _MK_BINARYSCOREFILEEXT,NO);
  if (!stream)
    stream = _MKOpenFileStreamForReading(fileName,_MK_SCOREFILEEXT, YES);
  if (!stream)
    return nil;
  rtnVal = readScorefile(self, stream, firstTimeTag, lastTimeTag, timeShift, fileName);
  //    [stream release]; //sb: no. The above functions are autoreleased.
  return rtnVal;
}

-readScorefileStream:(NSData *)stream
        firstTimeTag:(double)firstTimeTag
         lastTimeTag:(double)lastTimeTag
           timeShift:(double)timeShift
  /* Read from scoreFile to receiver, creating new MKParts as needed
  and including only those notes between times firstTimeTag to
  time lastTimeTag, inclusive. Note that the TimeTags of the
  notes are not altered from those in the file. I.e.
  the first note's TimeTag will be greater than or equal to
  firstTimeTag.
  Merges contents of file with current MKParts when the MKPart
  name found in the file is the same as one of those in the
  receiver.
  Returns self or nil if the parse was aborted due to errors.
  It is the application's responsibility to close the stream after calling
  this method.
  */
{
  return readScorefile(self, stream, firstTimeTag, lastTimeTag, timeShift, NULL);
}

/* Scorefile reading "convenience" methods  --------------------------- */

-readScorefile:(NSString *)fileName
  firstTimeTag:(double)firstTimeTag
   lastTimeTag:(double)lastTimeTag
{
  return [self readScorefile:fileName firstTimeTag:firstTimeTag
                 lastTimeTag:lastTimeTag timeShift:0.0];
}

-readScorefileStream:(NSData *)stream
        firstTimeTag:(double)firstTimeTag
         lastTimeTag:(double)lastTimeTag
{
  return [self readScorefileStream:stream firstTimeTag:firstTimeTag
                       lastTimeTag:lastTimeTag timeShift:0.0];
}

-readScorefile:(NSString *)fileName
{
  return [self readScorefile:fileName firstTimeTag:0.0
                 lastTimeTag:MK_ENDOFTIME timeShift:0.0];
}

-readScorefileStream:(NSData *)stream
{
  return [self readScorefileStream:stream firstTimeTag:0.0
                       lastTimeTag:MK_ENDOFTIME timeShift:0.0];
}

/* Writing Scorefiles --------------------------------------------------- */

-_noteTagRangeLowP:(int *)lowTag highP:(int *)highTag
  /* Returns by reference the lowest and highest noteTags in receiver. */
{
  int noteTag,ht,lt;
  id notes;
  unsigned n = [parts count],m,i,j;
  ht = 0;
  lt = MAXINT;
  for (i = 0; i < n; i++) {
    notes = [[parts objectAtIndex:i] notesNoCopy];
    m = [notes count];
    for (j = 0; j < m; j++) {
      noteTag = [[notes objectAtIndex:j] noteTag];
      if (noteTag != MAXINT) {
        ht = MAX(ht,noteTag);
        lt = MIN(lt,noteTag);
      }
    }
  }
  *highTag = ht;
  *lowTag = lt;
  return self;
}

static void writeNotes();

- writeScorefileStream: (NSMutableData *) aStream
          firstTimeTag: (double) firstTimeTag
           lastTimeTag: (double) lastTimeTag
             timeShift: (double) timeShift
                binary: (BOOL) isBinary
/* Same as writeScorefileStream: but only writes notes within specified
  time bounds. */
{
  _MKScoreOutStruct * p;
  int lowTag, highTag;
  if (!aStream)
    return nil;
  p = _MKInitScoreOut(aStream,self,info,timeShift,NO,isBinary);
  [self _noteTagRangeLowP:&lowTag highP:&highTag];
  if (lowTag <= highTag) {
    if (isBinary) {
      _MKWriteShort(aStream,_MK_noteTagRange);
      _MKWriteInt(aStream,lowTag);
      _MKWriteInt(aStream,highTag);
    }
    else
      [aStream appendData:[[NSString stringWithFormat:@"%s = %d %s %d;\n",
        _MKTokNameNoCheck(_MK_noteTagRange), lowTag,
		      _MKTokNameNoCheck(_MK_to), highTag] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
  }
  writeNotes(aStream, self, p, firstTimeTag, lastTimeTag, timeShift);
  _MKFinishScoreOut(p,YES);            /* Doesn't close aStream. */
  return self;
}

- writeScorefile: (NSString *) aFileName
    firstTimeTag: (double) firstTimeTag
     lastTimeTag: (double) lastTimeTag
       timeShift: (double) timeShift
          binary: (BOOL) isBinary
{
  NSMutableData *stream = [[NSMutableData alloc] initWithCapacity:0];
  BOOL success;

    [self writeScorefileStream: stream
                  firstTimeTag: firstTimeTag
                   lastTimeTag: lastTimeTag
                     timeShift: timeShift
                        binary: isBinary];

  success = _MKOpenFileStreamForWriting(aFileName,
                                        (isBinary) ? _MK_BINARYSCOREFILEEXT : _MK_SCOREFILEEXT,
                                        stream, YES);
  [stream release];
  if (!success) {
    _MKErrorf(MK_cantCloseFileErr, aFileName);
    return nil;
  }
  else
    return self;
}

- writeScorefile: (NSString *) aFileName
    firstTimeTag: (double) firstTimeTag
     lastTimeTag: (double) lastTimeTag
       timeShift: (double) timeShift
  /* Write scorefile to file with specified name within specified
  bounds. */
{
  return [self writeScorefile: aFileName
                 firstTimeTag: firstTimeTag
                  lastTimeTag: lastTimeTag
                    timeShift: timeShift
                       binary: NO];
}

- writeScorefileStream: (NSMutableData *) aStream
          firstTimeTag: (double) firstTimeTag
           lastTimeTag: (double) lastTimeTag
             timeShift: (double) timeShift
/* Same as writeScorefileStream: but only writes notes within specified
  time bounds. */
{
  return [self writeScorefileStream: aStream
                       firstTimeTag: firstTimeTag
                        lastTimeTag: lastTimeTag
                          timeShift: timeShift
                             binary: NO];
}

- writeOptimizedScorefile: (NSString *) aFileName
             firstTimeTag: (double) firstTimeTag
              lastTimeTag: (double) lastTimeTag
                timeShift: (double) timeShift
  /* Write scorefile to file with specified name within specified
  bounds. */
{
    return [self writeScorefile: aFileName
                   firstTimeTag: firstTimeTag
                    lastTimeTag: lastTimeTag
                      timeShift: timeShift
                         binary: YES];
}

- writeOptimizedScorefileStream: (NSMutableData *) aStream
                   firstTimeTag: (double) firstTimeTag
                    lastTimeTag: (double) lastTimeTag
                      timeShift: (double) timeShift
  /* Same as writeScorefileStream: but only writes notes within specified
  time bounds. */
{
    return [self writeScorefileStream: aStream
                        firstTimeTag: firstTimeTag
                        lastTimeTag: lastTimeTag
                          timeShift: timeShift
                           binary: YES];
}

/* Scorefile writing "convenience methods" ------------------------ */

- writeScorefile: (NSString *) aFileName
    firstTimeTag: (double) firstTimeTag
     lastTimeTag: (double) lastTimeTag
{
  return [self writeScorefile: aFileName
                  firstTimeTag: firstTimeTag
                   lastTimeTag: lastTimeTag
                     timeShift: 0.0
                        binary: NO];
}

- writeScorefileStream: (NSMutableData *) aStream
          firstTimeTag: (double) firstTimeTag
           lastTimeTag: (double) lastTimeTag
{
    return [self writeScorefileStream: aStream
                         firstTimeTag: firstTimeTag
                          lastTimeTag: lastTimeTag
                            timeShift: 0.0
                               binary: NO];
}

- writeScorefile: (NSString *) aFileName
{
    return [self writeScorefile: aFileName
                   firstTimeTag: 0.0
                    lastTimeTag: MK_ENDOFTIME
                      timeShift: 0.0];
}

- writeScorefileStream: (NSMutableData *) aStream
{
    return [self writeScorefileStream: aStream
                         firstTimeTag: 0.0
                          lastTimeTag: MK_ENDOFTIME
                            timeShift: 0.0];
}

- writeOptimizedScorefile: (NSString *) aFileName
            firstTimeTag: (double) firstTimeTag
             lastTimeTag: (double) lastTimeTag
{
  return [self writeScorefile: aFileName
                  firstTimeTag: firstTimeTag
                   lastTimeTag: lastTimeTag
                     timeShift: 0.0
                        binary: YES];
}

- writeOptimizedScorefileStream: (NSMutableData *) aStream
                  firstTimeTag: (double) firstTimeTag
                   lastTimeTag: (double) lastTimeTag
{
  return [self writeScorefileStream: aStream
                        firstTimeTag: firstTimeTag
                         lastTimeTag: lastTimeTag
                           timeShift: 0.0
                            binary: YES];
}

- writeOptimizedScorefile: (NSString *) aFileName
{
    return [self writeOptimizedScorefile: aFileName
                            firstTimeTag: 0.0
                             lastTimeTag: MK_ENDOFTIME
                               timeShift: 0.0];
}

- writeOptimizedScorefileStream: (NSMutableData *) aStream
{
    return [self writeOptimizedScorefileStream: aStream
                                  firstTimeTag: 0.0
                                   lastTimeTag: MK_ENDOFTIME
                                     timeShift: 0.0];
}


/* Writing MIDI files ------------------------------------------------ */

static BOOL midifilesEvaluateTempo = YES;

+setMidifilesEvaluateTempo:(BOOL)yesOrNo
{
  midifilesEvaluateTempo = yesOrNo;
  return self;
}

+(BOOL)midifilesEvaluateTempo
{
  return midifilesEvaluateTempo;
}

static int timeInQuanta(void *p,double timeTag)
{
  return MKMIDI_DEFAULTQUANTASIZE * timeTag + .5; /* .5 for rounding */
}

static void putMidi(struct __MKMidiOutStruct *ptr)
{
  MKMIDIFileWriteEvent(ptr->_midiFileStruct,
                       timeInQuanta(ptr->_midiFileStruct,ptr->_timeTag),
                       ptr->_outBytes,
                       &(ptr->_bytes[0]));
}

static void putSysExcl(struct __MKMidiOutStruct *ptr,NSString *sysExclString)
{
  int sysExStrLen = [sysExclString cStringLength];
  char *sysExclStr = alloca(sysExStrLen);
  unsigned char *buffer = alloca(sysExStrLen); /* More than enough */
  unsigned char *bufptr = buffer;
  int bufferLen;
  unsigned char c;

  [sysExclString getCString: sysExclStr];
  c = _MKGetSysExByte(&sysExclStr);
  if (c == MIDI_SYSEXCL)
    c = _MKGetSysExByte(&sysExclStr);
  *bufptr++ = c;
  while (*sysExclStr && c != MIDI_EOX)
    *bufptr++ = c = _MKGetSysExByte(&sysExclStr);
  if (c != MIDI_EOX)
    *bufptr++ = MIDI_EOX;
  bufferLen = bufptr - buffer;
  MKMIDIFileWriteSysExcl(ptr->_midiFileStruct, timeInQuanta(ptr->_midiFileStruct,ptr->_timeTag), bufferLen, buffer);
}

static void sendBufferedData(struct __MKMidiOutStruct *ptr)
/* Dummy function. (Since we don't need an extra level of buffering here) */
{
  // intentionally left blank
}

// return the possible extensions of MIDI files for pathnames
+ (NSArray *) midifileExtensions
{
  return [NSArray arrayWithObjects: _MK_MIDIFILEEXT, nil];
}

// return the extension of scorefiles allowed
+ (NSArray *) scorefileExtensions
{
    return [NSArray arrayWithArray: scoreFileExtensions];
}

+ (void) setAlternativeScorefileExtensions: (NSArray *) otherScoreFileExtensions
{
    [scoreFileExtensions release];
    scoreFileExtensions = [otherScoreFileExtensions retain];
}

+ (NSArray *) bundleExtensions
{
    int i,count;
    NSMutableArray *a = [NSMutableArray new];
    NSObject <MusicKitPlugin> *p;
    count = [plugins count];
    for (i = 0 ; i < count ; i++) {
        p = [plugins objectAtIndex:i];
        if ([[[p class] protocolVersion] isEqualToString:@"1"]) {
            [a addObjectsFromArray:[p fileOpeningSuffixes]];
            [a addObjectsFromArray:[p fileSavingSuffixes]];
        }
    }
    return [a autorelease];
}

// return all fileExtensions readable/writable by this class.
+ (NSArray *) fileExtensions
{
    NSArray *basic = [[MKScore scorefileExtensions] arrayByAddingObjectsFromArray: [MKScore midifileExtensions]];
    MKLoadAllBundlesOneOff();
    return [basic arrayByAddingObjectsFromArray:[MKScore bundleExtensions]];
}

#define T timeInQuanta(fileStructP,(t+timeShift))
#define STRPAR MKGetNoteParAsStringNoCopy
#define INTPAR MKGetNoteParAsInt
#define DOUBLEPAR MKGetNoteParAsDouble
#define INRANGE(_par) (_par >= 128 && _par <= 159)
#define PRESENT(_par) (parBits & (1<<(_par - 128)))
#define WRITETEXT(_meta,_par) MKMIDIFileWriteText(fileStructP,T,(_meta),STRPAR(curNote,(_par)))

/* Write a single MKNote to the MIDI file, tagged appropriately */
static void writeNoteToMidifile(_MKMidiOutStruct *p, void *fileStructP, MKNote *curNote, double timeShift,
                                int defaultChan)
{
  int chan;
  unsigned parBits;
  double t;

  /* First handle normal midi */
  chan = INTPAR(curNote,MK_midiChan);
  t = [curNote timeTag];
  _MKWriteMidiOut(curNote, t+timeShift, ((chan == MAXINT) ? defaultChan : chan), p, nil);
  /* Now check for meta-events. */
  parBits= [curNote parVector:4];
  if (parBits) {
    if (PRESENT(MK_text))
      WRITETEXT(MKMIDI_text,MK_text);
    if (PRESENT(MK_title))
      WRITETEXT(MKMIDI_sequenceOrTrackName,MK_title);
    if (PRESENT(MK_instrumentName))
      WRITETEXT(MKMIDI_instrumentName,MK_instrumentName);
    if (PRESENT(MK_lyric))
      WRITETEXT(MKMIDI_lyric,MK_lyric);
    if (PRESENT(MK_cuePoint))
      WRITETEXT(MKMIDI_cuePoint,MK_cuePoint);
    if (PRESENT(MK_marker))
      WRITETEXT(MKMIDI_marker,MK_marker);
    if (PRESENT(MK_timeSignature)) {
      unsigned int nn, dd, cc, bb, allData;
      NSString *timeSigString = STRPAR(curNote, MK_timeSignature);
      NSScanner *timeSigScan;
      if(timeSigString == nil) {
        allData = 0;
      }
      else {

/*  From the Standard MIDI File Spec:
 The time signature defined with 4 bytes, a numerator, a denominator, a
 metronome pulse and number of 32nd notes per MIDI quarter-note. The
 numerator is specified as a literal value, but the denominator is
 specified as (get ready) the value to which the power of 2 must be
 raised to equal the number of subdivisions per whole note. For example,
 a value of 0 means a whole note because 2 to the power of 0 is 1 (whole
 note), a value of 1 means a half-note because 2 to the power of 1 is 2
 (half-note), and so on. The metronome pulse specifies how often the
 metronome should click in terms of the number of clock signals per click,
 which come at a rate of 24 per quarter-note. For example, a value of 24
 would mean to click once every quarter-note (beat) and a value of 48
 would mean to click once every half-note (2 beats). And finally, the
 fourth byte specifies the number of 32nd notes per 24 MIDI clock signals.
 This value is usually 8 because there are usually 8 32nd notes in a
 quarter-note. At least one Time Signature Event should appear in the
 first track chunk (or all track chunks in a Type 2 file) before any
 non-zero delta time events. If one is not specified 4/4, 24, 8 should
 be assumed.
 */
        timeSigScan = [NSScanner scannerWithString: timeSigString];
        [timeSigScan scanInt: &nn];  // numerator
        [timeSigScan scanInt: &dd];  // denominator
                                     // 0 is whole note, 1 is 1/2, 2 is 1/4,
                                     // 3 is 1/8, 4 is 1/16 (semiquaver)
        [timeSigScan scanInt: &cc];  // clock sigs per metronome click
                                     // 24 = quarter note, 48 = half note etc
        [timeSigScan scanInt: &bb];  // 
        allData = (nn << 24) | (dd << 16) | (cc << 8) | bb;
      }
      MKMIDIFileWriteSig(fileStructP,T,MKMIDI_timeSig, allData);
    }
    if (PRESENT(MK_keySignature)) {
      NSString *keySigString = STRPAR(curNote,MK_keySignature);
      NSScanner *keySigScan;
      unsigned int sf, mi, allData;
      if(keySigString == nil) {
        allData = 0;
      }
      else {
        keySigScan = [NSScanner scannerWithString: keySigString];
        [keySigScan scanInt: &sf];  // ??
        [keySigScan scanInt: &mi];  // ??
        allData = (sf << 8) | mi;
      }
      MKMIDIFileWriteSig(fileStructP, T, MKMIDI_keySig, allData);
    }
    if (PRESENT(MK_tempo))
      MKMIDIFileWriteTempo(fileStructP,T, DOUBLEPAR(curNote,MK_tempo));
  }
}


-writeMidifileStream:(NSMutableData *)aStream firstTimeTag:(double)firstTimeTag
         lastTimeTag:(double)lastTimeTag timeShift:(double)timeShift
  /* Write midi on aStream. */
{
  _MKMidiOutStruct *p;
  void *fileStructP;
  double t = 0;
  MKNote *anInfo = nil;
  NSString *title = nil;
  int defaultChan;
  double tempo;
  MKPart *aPart, *curPart;
  NSArray *notes;
  MKNote *curNote;
  unsigned i,j, numOfParts, numOfNotes;

  NSAssert((INRANGE(MK_tempo) && INRANGE(MK_lyric) &&
            INRANGE(MK_cuePoint) && INRANGE(MK_marker) &&
            INRANGE(MK_timeSignature) &&
            INRANGE(MK_keySignature)), @"Illegal use of parVector.");

  if (!aStream)
    return nil;
  tempo = 60;
  if (info) {
    if ([info isParPresent:MK_title])
      title = [info parAsStringNoCopy:MK_title];
    if (title == nil) { /* Try using tempo track part name */
      id aPart = [parts objectAtIndex:0];
      if (aPart)
        title = (NSString *) MKGetObjectName(aPart);
    }
    if ([info isParPresent: MK_tempo])
      tempo = [info parAsDouble: MK_tempo];
  }
  p = _MKInitMidiOut();
  if (!(fileStructP = MKMIDIFileBeginWriting(aStream, 1, title, [MKScore midifilesEvaluateTempo]))) {
    _MKFinishMidiOut(p);
    return nil;
  }
  else p->_midiFileStruct = fileStructP; /* Needed so functions called from
  _MKWriteMidiOut can find
  struct */
  numOfParts = [parts count];
  if (numOfParts == 0) {
    MKMIDIFileEndWriting(fileStructP);
    _MKFinishMidiOut(p);
    return self;
  }
  p->_owner = self;
  p->_putSysMidi = putMidi;
  p->_putChanMidi = putMidi;
  p->_putSysExcl = putSysExcl;
  p->_sendBufferedData = sendBufferedData;
  MKMIDIFileWriteTempo(fileStructP,0,tempo);
  if (info) {
    if ([info isParPresent:MK_copyright])
      MKMIDIFileWriteText(fileStructP, 0, MKMIDI_copyright, STRPAR(info,MK_copyright));
    if ([info isParPresent:MK_text])
      MKMIDIFileWriteText(fileStructP, 0, MKMIDI_text, STRPAR(info,MK_text));
    if ([info isParPresent:MK_sequence])
      MKMIDIFileWriteSequenceNumber(fileStructP, INTPAR(info,MK_sequence));
    if ([info isParPresent:MK_smpteOffset]) {
      unsigned int hr, mn, sec, fr, ff;
      NSString *smpteString = STRPAR(info, MK_smpteOffset);
      NSScanner *smpteScan;
      if(smpteString == nil) {
        hr = mn = sec = fr = ff = 0;
      }
      else {
        smpteScan = [NSScanner scannerWithString: smpteString];
        [smpteScan scanInt: &hr];
        [smpteScan scanInt: &mn];
        [smpteScan scanInt: &sec];
        [smpteScan scanInt: &fr];
        [smpteScan scanInt: &ff];
      }
      MKMIDIFileWriteSMPTEoffset(fileStructP,hr,mn,sec,fr,ff);
    }
  }
  MKMIDIFileEndWritingTrack(fileStructP, lastTimeTag < MK_ENDOFTIME ? lastTimeTag : 0); // 0 end time is a little kludgy

  for (i = 0; i < numOfParts; i++) {
    curPart = [parts objectAtIndex:i];
    if ([curPart noteCount] == 0)
      continue;
    MKMIDIFileBeginWritingTrack(fileStructP, (NSString *) MKGetObjectName(curPart));
    aPart = [curPart copy]; /* Need to copy to split notes. */
    [aPart splitNotes];
    [aPart sort];
    notes = [aPart notesNoCopy];
    anInfo = [aPart infoNote];
    defaultChan = 1;
    if (anInfo) {
      if ([anInfo isParPresent: MK_midiChan]) {
        defaultChan = [anInfo parAsInt: MK_midiChan];
      }
      // If the time of the part info note has not been set, it becomes 0,
      // otherwise use whatever is there, hopefully user knows best.
      if([anInfo timeTag] >= MK_ENDOFTIME) {
        [anInfo setTimeTag: 0];
      }
      writeNoteToMidifile(p, fileStructP, anInfo, timeShift, defaultChan);
    }
    numOfNotes = [notes count];
    for (j = 0; j < numOfNotes; j++) {
      curNote = [notes objectAtIndex:j];
      if ((t = [curNote timeTag]) >= firstTimeTag) {
        if (t > lastTimeTag)
          break;
        else {
          writeNoteToMidifile(p, fileStructP, curNote, timeShift, defaultChan);
        }
      }
    }
    MKMIDIFileEndWritingTrack(fileStructP,T);
    [aPart release];
  }
  MKMIDIFileEndWriting(fileStructP);
  _MKFinishMidiOut(p);
  return self;
}

-writeMidifile:(NSString *)aFileName firstTimeTag:(double)firstTimeTag
   lastTimeTag:(double)lastTimeTag timeShift:(double)timeShift
  /* Write midi to file with specified name. */
{
  NSMutableData *stream = [[NSMutableData alloc] initWithCapacity:0];
  BOOL success;

  [self writeMidifileStream: stream
               firstTimeTag: firstTimeTag
                lastTimeTag: lastTimeTag
                  timeShift: timeShift];
  success = _MKOpenFileStreamForWriting(aFileName, [[MKScore midifileExtensions] objectAtIndex: 0], stream, YES);
  [stream release];

  if (!success) {
    _MKErrorf(MK_cantCloseFileErr, aFileName);
    return nil;
  }
  else {
    return self;
  }
}

/* Midi file writing "convenience methods" --------------------------- */

-writeMidifileStream:(NSMutableData *)aStream
        firstTimeTag:(double)firstTimeTag
         lastTimeTag:(double)lastTimeTag
{
  return [self writeMidifileStream:aStream firstTimeTag:firstTimeTag
                       lastTimeTag:lastTimeTag timeShift:0.0];
}

-writeMidifile:(NSString *)aFileName
  firstTimeTag:(double)firstTimeTag
   lastTimeTag:(double)lastTimeTag
{
  return [self writeMidifile:aFileName firstTimeTag:firstTimeTag
                 lastTimeTag:lastTimeTag timeShift:0.0];
}

-writeMidifileStream:(NSMutableData *)aStream
{
  return [self writeMidifileStream:aStream firstTimeTag:0.0
                       lastTimeTag:MK_ENDOFTIME];
}

-writeMidifile:(NSString *)aFileName
{
  return [self writeMidifile:aFileName firstTimeTag:0.0
                 lastTimeTag:MK_ENDOFTIME];
}


/* Reading MIDI files ---------------------------------------------- */

- readMidifile: (NSString *) aFileName
  firstTimeTag: (double) firstTimeTag
   lastTimeTag: (double) lastTimeTag
     timeShift: (double) timeShift
{
    id rtnVal;
    id stream;/*sb: could be NSMutableData or NSData */

    stream = _MKOpenFileStreamForReading(aFileName, [[MKScore midifileExtensions] objectAtIndex: 0], YES);
    if (stream == nil)
        return nil;
    rtnVal = [self readMidifileStream: stream
                         firstTimeTag: firstTimeTag
                          lastTimeTag: lastTimeTag
                            timeShift: timeShift];
    return rtnVal;
}

static void writeDataAsNumString(id aNote,int par,unsigned char *data,
                                 int nBytes)
{
#   define ROOM 4 /* Up to 3 digits per number followed by space */
  int size = nBytes * ROOM;
  char *str = _MKMalloc(size); // was alloca
  NSString * retStr;
  int i,j;
  for (i=0; i<nBytes; i++)
    sprintf(&(str[i * ROOM]),"%-3d ",j = data[i+1]);
  str[size - 1] = '\0'; /* Write over last space. */
  retStr = [NSString stringWithCString:str];
  MKSetNoteParToString(aNote,par,retStr);
  free(str);
}

- readMidifileStream:(NSMutableData *) aStream firstTimeTag:(double) firstTimeTag
         lastTimeTag:(double) lastTimeTag timeShift:(double)timeShift
{
  int fileFormatLevel;
  int trackCount;
  double timeFactor,t,prevT,lastTempoTime = -1;
  id              aPart;
  int             i;
  register id     aNote;
#   define MIDIPARTS (16 + 1)
  _MKMidiInStruct *midiInPtr;
  id *midiParts,*curPart;
  BOOL trackInfoMidiChanWritten = NO;
  void *fileStructP;
  int *quanta;
  BOOL *metaevent;
  int *nData;
  unsigned char **data;
  if (!(fileStructP = MKMIDIFileBeginReading(aStream,&quanta,&metaevent,&nData,&data,[MKScore midifilesEvaluateTempo])))
    return nil;
#   define DATA (*data)
  if (!MKMIDIFileReadPreamble(fileStructP,&fileFormatLevel,&trackCount))
    return nil;
  if (fileFormatLevel == 0)
    trackCount = MIDIPARTS;
  else trackCount++; 	/* trackCount doesn't include the 'tempo' track so
    we increment here */
  if (!(midiInPtr = _MKInitMidiIn())) {
    MKMIDIFileEndReading(fileStructP);
    return nil;
  }
  _MK_MALLOC(midiParts,id,trackCount);
  curPart = midiParts;
  for (i=0; i<trackCount; i++) {
    aPart = [MKGetPartClass() new];
    aNote = [MKGetNoteClass() new];
    if ((fileFormatLevel == 0) && (i != 0))
      [aNote setPar:MK_midiChan toInt:i];
    [aPart setInfoNote:aNote];
    [aNote release];
    [self addPart:aPart];
    *curPart++ = aPart;
  }
  lastTimeTag = MIN(lastTimeTag, MK_ENDOFTIME);
  timeFactor = 1.0/(double)MKMIDI_DEFAULTQUANTASIZE;
  /* In format 0 files, *curPart will be the _MK_MIDISYS part. */
  curPart = midiParts;
#   define FIRSTTRACK (MKPart *)*midiParts
#   define CURPART (MKPart *)*curPart
  prevT = -1;
  if (!info)
    info = [MKGetNoteClass() new];
#   define SHORTDATA ((int)(*((short *)&(DATA[1]))))
#   define LONGDATA ((int)(*((int *)&(DATA[1]))))
#   define STRINGDATA ((char *)&(DATA[1]))
#   define LEVEL0 (fileFormatLevel == 0)
#   define LEVEL1 (fileFormatLevel == 1)
#   define LEVEL2 (fileFormatLevel == 2)
  if (LEVEL2) /* Sequences numbered consecutively from 0 by default. */
    MKSetNoteParToInt([FIRSTTRACK infoNote],MK_sequence,0);
  while (MKMIDIFileReadEvent(fileStructP)) {
    if (*metaevent) {
      /* First handle meta-events that are MKPart or MKScore info
      parameters. We never want to skip these. */
      switch (DATA[0]) {
        case MKMIDI_sequenceNumber:
          MKSetNoteParToInt(LEVEL2 ? [CURPART infoNote] : info,
                            MK_sequence,SHORTDATA);
          break;
        case MKMIDI_smpteOffset:
          writeDataAsNumString(LEVEL2 ? [CURPART infoNote] : info,
                               MK_smpteOffset,DATA,5);
          break;
        case MKMIDI_sequenceOrTrackName:
          /* Check if it is the first part. There is no MK_title in level 2 files, since
          the title is merely the name of the first sequence. */
          if ((curPart == midiParts) && !LEVEL2)
            MKSetNoteParToString(info, MK_title, [NSString stringWithCString:STRINGDATA]);
          /* In level 1 files, we name the current part with the
          title. Note that we do this even if the name is a
          sequence name rather than a track name. In level 0
          files, we do not name the part. */
          if(LEVEL1)
            MKSetNoteParToString([CURPART infoNote], MK_title, [NSString stringWithCString:STRINGDATA]);
            if (fileFormatLevel != 0)
              MKNameObject([NSString stringWithCString:STRINGDATA], *curPart);
              break;
        case MKMIDI_copyright:
          MKSetNoteParToString(info,MK_copyright,[NSString stringWithCString:STRINGDATA]);
          break;
        case MKMIDI_instrumentName:
          /* An instrument name is the sort of thing you need in a part info note, but the strict definition of
          the SMF spec allows you to rename the track at different time points, why? It would have been better
        to define more tracks, each with a separate instrument. In that rather wierd case,
          this code is wrong as it will take the last instrument name used as the info note. */
          MKSetNoteParToString(LEVEL1 ? [CURPART infoNote] : info,
                               MK_instrumentName, [NSString stringWithCString:STRINGDATA]);
        default:
          break;
      }
    }
    t = *quanta * timeFactor;
    /* FIXME Should do something better here. (need to change
	   MKPart to allow ordering spec for simultaneous notes.) */
    if (t < firstTimeTag)
      continue;
    if (t > lastTimeTag) {
      if (LEVEL0)
        break; /* We know we're done */
      else
        continue;
    }
    if (*metaevent) {
      /* Now handle meta-events that can be in regular notes. These
      are skipped when out of the time window, as are regular
      MIDI messages. */
      aNote = [[MKGetNoteClass() alloc] initWithTimeTag:t+timeShift]; /* retained */
      switch (DATA[0]) {
        case MKMIDI_trackChange:
          /* Sent at the end of every track. May be missing from the
          end of the file. */
          if (t > (prevT + _MK_TINYTIME)) {
            /* We've got a significant trackChange time. */
            MKSetNoteParToString(aNote,LEVEL1 ? MK_track : MK_sequence,
                                 @"end");
            [CURPART addNote:aNote];    /* Put an end-of-track mark */
          }
          curPart++;
          if (curPart >= midiParts + trackCount)
            goto outOfLoop;
            trackInfoMidiChanWritten = NO;
          if (LEVEL1) /* Other files have no "tracks" */
            MKSetNoteParToInt([CURPART infoNote],MK_track,SHORTDATA);
          else if (LEVEL2) {
            /* Assign ascending sequence number parameters */
#		    define OLDNUM \
            MKGetNoteParAsInt([(*(curPart-1)) infoNote],MK_sequence)
            MKSetNoteParToInt([CURPART infoNote],MK_sequence,OLDNUM + 1);
          }
            lastTempoTime = -1;
          prevT = -1;
          [aNote release];
          continue; /* Don't clobber prevT below */
        case MKMIDI_tempoChange:
          /* For MK-compatibility, tempo is duplicated in info
          MKNotes, but only if it's at time 0 in file.    */
          if (t == 0) {
            if (lastTempoTime == 0) {
              /* Supress duplicate tempi, which can arise because of
                 the way we duplicate tempo in info (do it by bypassing
                 the addNote, below) */
              break;
            }
            else { /* First setting of tempo for current track. */
              id theInfo = LEVEL2 ? [CURPART infoNote] : info;
              if (!MKIsNoteParPresent(theInfo,MK_tempo))
                MKSetNoteParToDouble(theInfo,MK_tempo,
                                     [MKScore midifilesEvaluateTempo] ? 60 : 60000000.0/LONGDATA);
            }
          }
          lastTempoTime = t;
          if(![MKScore midifilesEvaluateTempo]) {
            MKSetNoteParToDouble(aNote,MK_tempo,60000000.0/LONGDATA);
            [(LEVEL2 ? FIRSTTRACK : CURPART) addNote:aNote];
          }
            break;
        case MKMIDI_text:
        case MKMIDI_cuePoint:
        case MKMIDI_lyric:
          MKSetNoteParToString(aNote,
                               ((DATA[0] == MKMIDI_text) ? MK_text :
                                (DATA[0] == MKMIDI_lyric) ? MK_lyric : MK_cuePoint),
                               [NSString stringWithCString:STRINGDATA]);
          [CURPART addNote:aNote];
          break;
        case MKMIDI_marker:
          MKSetNoteParToString(aNote,MK_marker,[NSString stringWithCString:STRINGDATA]);
          [(LEVEL2 ? FIRSTTRACK : CURPART) addNote:aNote];
          break;
        case MKMIDI_timeSig:
          writeDataAsNumString(aNote,MK_timeSignature,DATA,4);
          [(LEVEL2 ? FIRSTTRACK : CURPART) addNote:aNote];
          break;
        case MKMIDI_keySig: {
          char str[5];
          /* Want sf signed, hence (char) cast  */
          int x = (int)((char)DATA[2]); /* sf */
          sprintf(&(str[0]),"%-2d ",x);
          x = (int)DATA[3]; /* mi */
          sprintf(&(str[3]),"%d",x);
          str[4] = '\0';
          MKSetNoteParToString(aNote,MK_keySignature,[NSString stringWithCString:str]);
          [(LEVEL2 ? FIRSTTRACK : CURPART) addNote:aNote];
          break;
        }
        default:
          break;
      }
      [aNote release];
    }
    else { /* Standard MIDI, not sys excl */
      id arp;
      switch (*nData) {
        case 3:
          midiInPtr->_dataByte2 = DATA[2];
          /* No break */
        case 2:
          midiInPtr->_dataByte1 = DATA[1];
          /* No break */
        case 1:
          /* Status passed directly below. */
          break;
        default: { /* Sys exclusive */
          unsigned j;
          char *str = alloca(*nData * 3); /* 3 chars per byte */
          char *ptr = str;
          unsigned char *p = *data;
          unsigned char *endP = p + *nData;
          sprintf(ptr,"%-2x",j = *p++);
          ptr += 2;
          while (p < endP) {
            sprintf(ptr,",%-2x",j = *p++);
            ptr += 3;
          }
          *ptr = '\0';
          aNote = [[MKGetNoteClass() alloc] initWithTimeTag:t+timeShift];
          MKSetNoteParToString(aNote,MK_sysExclusive,[NSString stringWithCString:str]); /* copy */
          [CURPART addNote:aNote];
          [aNote release];
          continue;
        }
      }
  arp = [NSAutoreleasePool new];
  aNote = _MKMidiToMusicKit(midiInPtr,DATA[0]); /* autoreleased */
  if (aNote) { /* _MKMidiToMusicKit can omit MKNotes sometimes. */
		[aNote setTimeTag:t+timeShift];
		/* Need to copy MKNote because it's "owned" by midiInPtr (pre-
  * OpenStep).
  * Now we just add to the part as-is, and it will retain or copy
  * it as necessary. */
		if (LEVEL0) {
      // LMS even if aNote has come from a Level0 file it should retain midiChannels from mode messages.
      if (midiInPtr->chan != _MK_MIDISYS) {
        MKSetNoteParToInt(aNote, MK_midiChan, midiInPtr->chan);
      }
      [midiParts[midiInPtr->chan] addNote:aNote];
    }
		else {
		    if (!trackInfoMidiChanWritten && midiInPtr->chan != _MK_MIDISYS) {
          trackInfoMidiChanWritten = YES;
          MKSetNoteParToInt([CURPART infoNote], MK_midiChan, midiInPtr->chan);
          /* Set Part's chan to chan of first note in track. */
        }
		    if (midiInPtr->chan != _MK_MIDISYS) {
          MKSetNoteParToInt(aNote,MK_midiChan,midiInPtr->chan);
        }
		    [CURPART addNote:aNote];
}
  }
[arp release]; /* take care of autoreleased notes one at a time */
    } /* End of standard MIDI block */
prevT = t;
  } /* End of while loop */
outOfLoop:
free(midiParts);
_MKFinishMidiIn(midiInPtr);
MKMIDIFileEndReading(fileStructP);
return self;
}

/* Midifile reading "convenience methods"------------------------ */

-readMidifile:(NSString *)fileName
 firstTimeTag:(double)firstTimeTag
  lastTimeTag:(double)lastTimeTag
{
  return [self readMidifile:fileName firstTimeTag:firstTimeTag
                lastTimeTag:lastTimeTag timeShift:0.0];
}

-readMidifileStream:(NSMutableData *)aStream
       firstTimeTag:(double)firstTimeTag
        lastTimeTag:(double)lastTimeTag
{
  return [self readMidifileStream:aStream firstTimeTag:firstTimeTag
                      lastTimeTag:lastTimeTag timeShift:0.0];
}

-readMidifile:(NSString *)fileName
/* Like readMidifile:firstTimeTag:lastTimeTag:,
  but always reads the whole file. */
{
  return [self readMidifile:fileName firstTimeTag:0.0
                lastTimeTag:MK_ENDOFTIME timeShift:0.0];
}

-readMidifileStream:(NSMutableData *)aStream
/* Like readMidifileStream:firstTimeTag:lastTimeTag:,
  but always reads the whole file. */
{
  return [self readMidifileStream:aStream firstTimeTag:0.0
                      lastTimeTag:MK_ENDOFTIME timeShift:0.0];
}

/* Number of notes and parts ------------------------------------------ */

-(unsigned)partCount
{
  return [parts count];
}

-(unsigned)noteCount
  /* Returns the total number of notes in all the contained MKParts. */
{
  unsigned n = [parts count], i;
  unsigned numNotes = 0;
  for (i = 0; i < n; i++)
    numNotes += [[parts objectAtIndex:i] noteCount];

  return numNotes;
}

/* Modifying the set of MKParts. ------------------------------- */

-replacePart:(id)oldPart with:(id)newPart
  /* Removes oldPart from self and replaces it with newPart.
  * Returns newPart.
  * If oldPart is not a member of this score, returns nil
  * and doesn't add newPart.  If newPart is nil, or if
  * newPart is already a member of this score, or
  * if newPart is not a kind of MKPart, returns nil.
  */
{
  int i = [parts indexOfObjectIdenticalTo:oldPart];
  if (i == NSNotFound)
    return nil;
  [self removePart:oldPart];
  if ((!newPart) || ([newPart score] == self) || ![newPart isKindOfClass:[MKPart class]])
    return nil;
  [newPart _setScore:self];
  [parts insertObject:newPart atIndex:i];
  return newPart;
}

-addPart:(id)aPart
  /* If aPart is already a member of the MKScore, returns nil. Otherwise,
  adds aPart to the receiver and returns aPart,
  first removing aPart from any other score of which it is a member. */
{
  if ((!aPart) || ([aPart score] == self) || ![aPart isKindOfClass:[MKPart class]])
    return nil;
  [aPart _setScore:self];
  if ([parts indexOfObjectIdenticalTo:aPart] == NSNotFound)
    [parts addObject:aPart];
  return self;
}

-removePart:(id)aPart
  /* Removes aPart from self and returns aPart.
  If aPart is not a member of this score, returns nil. */
{
  [aPart _unsetScore];
  [parts removeObjectIdenticalTo:aPart];
  return self; //sb: assume self is correct. Arrays return void...
}

-shiftTime:(double)shift
   /* TYPE: Editing
  * Shift is added to the timeTags of all notes in the MKPart.
  */
{
  unsigned n = [parts count], i;
  for (i = 0; i < n; i++)
    [[parts objectAtIndex:i] shiftTime:shift];
  return self;
}

-scaleTime:(double)scale
   /* TYPE: Editing
  * Scale factor is applied to the timeTags and durations of all notes in the MKPart.
  */
{
  unsigned n = [parts count], i;
  for (i = 0; i < n; i++)
    [[parts objectAtIndex:i] scaleTime: scale];
  return self;
}

/* Finding a Part ----------------------------------------------- */

-(BOOL)isPartPresent:aPart
  /* Returns whether MKPart is a member of the receiver. */
{
  return ([parts indexOfObjectIdenticalTo:aPart] == NSNotFound) ? NO : YES;
}

-midiPart:(int)aChan
  /* Returns the first MKPart with a MK_midiChan info parameter equal to
  aChan, if any. aChan equal to 0 corresponds to the MKPart representing
  MIDI system and channel mode messages. */
{
  id el, aInfo;
  unsigned n, i;
  if (aChan == MAXINT)
    return nil;
  n = [parts count];
  for (i = 0; i < n; i++) {
    el = [parts objectAtIndex:i];
    if ((aInfo = [el infoNote]))
      if ([aInfo parAsInt:MK_midiChan] == aChan)
        return [[el retain] autorelease];
  }
  return nil;
}


/* Manipulating notes. ------------------------------- */


static void merge(NSMutableArray *listOfLists,NSMutableArray *allNotes)
/* ListOfLists is an Array containing List objects, one per MKPart.
AllNotes is an empty List big enough to hold all the MKNotes of all the
MKParts.
*/
{
  int *counts,*maxcounts;
  int listCount;
  int i,j,k;
  double t;
  MKNote *aNote,*theNote;
  id aList;
  int theList = 0; /* Give it a value to shut up compiler warnings */
  int max=0;
  IMP addMethod;
  listCount = [listOfLists count];
  _MK_CALLOC(counts,int,listCount);
  _MK_CALLOC(maxcounts,int,listCount);
  addMethod = [allNotes methodForSelector:@selector(addObject:)];

  for (k = 0; k < listCount; k++)
    maxcounts[max++] = [[listOfLists objectAtIndex:k] count];

  while (listCount > 0) {
    t = MK_ENDOFTIME + 1;
    theNote = nil;
    i = 0;
    while (i < listCount) {
      aList = [listOfLists objectAtIndex:i]; //sb: was NX_ADDRESS(listOfLists)[i];
      if (counts[i] < maxcounts[i])  // LMS changed from <= on Hamels recommendation & I agree.
        aNote = [aList objectAtIndex:counts[i]];
      else aNote = nil;
      if (!aNote) {  /* No more notes. */
        [listOfLists removeObjectAtIndex:i]; /* Pushes others down.       */
        for (j = i+1; j<listCount; j++) { /* Push counts down          */
          counts[j-1] = counts[j];
          maxcounts[j-1] = maxcounts[j];
        }
        listCount--;                    /* One less list             */
      }
      else if ([aNote timeTag] < t) {   /* Candidate                 */
        t = [aNote timeTag];
        theNote = aNote;
        theList = i;
        i++;
      }
      else
        i++;
    }
    if (theNote) {
      (*addMethod)(allNotes,@selector(addObject:),theNote);
      counts[theList]++;
    }
  }
  if (counts)
    free(counts);
  if (maxcounts)
    free(maxcounts);
}

static void writeNotes(NSMutableData *aStream, MKScore *aScore, _MKScoreOutStruct *p,
                       double firstTimeTag, double lastTimeTag, double timeShift)
{
  /* Write score body on aStream. Assumes p is a valid _MKScoreOutStruct. */
  MKPart *currentPart;
  unsigned n = [aScore->parts count], i;
  BOOL timeBounds = ((firstTimeTag != 0) || (lastTimeTag != MK_ENDOFTIME));
  NSMutableArray *allNotes = [NSMutableArray arrayWithCapacity: [aScore noteCount]];
  NSMutableArray *listOfLists = [NSMutableArray arrayWithCapacity: [aScore->parts count]];
  id aPart,aList;
  MKNote *currentNote;
  for (i = 0; i < n; i++) {
    currentPart = [aScore->parts objectAtIndex:i];
    if (timeBounds)
      aList = [currentPart firstTimeTag:firstTimeTag lastTimeTag:lastTimeTag];
    else {
      [currentPart sort];
      aList = [currentPart notesNoCopy];
    }
    if (aList)
      [listOfLists addObject:aList];
    _MKWritePartDecl(currentPart,p,[currentPart infoNote]);
  }
  merge(listOfLists,allNotes);

  n = [allNotes count];
  p->_timeShift = timeShift;

  for (i = 0; i < n; i++) {
    currentNote = [allNotes objectAtIndex:i];
    _MKWriteNote(currentNote,aPart = [currentNote part],p);
  }
}

static id
readScorefile(MKScore *self,
              NSData *stream,
              double firstTimeTag, double lastTimeTag, double timeShift,
              NSString *fileName)
{
  /* Read from scoreFile to receiver, creating new MKParts as needed
  and including only those notes between times firstTimeTag to
  time lastTimeTag, inclusive. Note that the TimeTags of the
  notes are not altered from those in the file. I.e.
  the first note's TimeTag will be greater than or equal to
  firstTimeTag.
  Merges contents of file with current MKParts when the MKPart
  name found in the file is the same as one of those in the
  receiver.
  Returns self or nil if error abort.  */
  register _MKScoreInStruct *p;
  register id aNote;
  IMP noteCopy, partAddNote;
  id rtnVal;
  unsigned int readPosition = 0;   // this is the top level.

  partAddNote = [MKGetPartClass() instanceMethodForSelector:@selector(addNote:)];
  noteCopy = [MKGetNoteClass() instanceMethodForSelector:@selector(copy)];
  p = _MKNewScoreInStruct(stream, self, self->scorefilePrintStream, NO, fileName, &readPosition);
  if (!p)
    return nil;
  _MKParseScoreHeader(p);
  lastTimeTag = MIN(lastTimeTag, MK_ENDOFTIME);
  firstTimeTag = MIN(firstTimeTag, MK_ENDOFTIME);
  do {
    aNote = _MKParseScoreNote(p); /* not retained or autoreleased - so go careful */
  } while (p->timeTag < firstTimeTag);

#if 0
  /* sbrandon, 22/01/2002
    * this warning is ancient - I'm going to risk adding the MKNotes as they are.
    */
  /* Believe it or not, is actually better to copy the note here!
    I'm not sure why.  Maybe the hashtable has some hysteresis and
    it gets reallocated each time. */
  while (p->timeTag <= lastTimeTag) {
    if (aNote) {
      aNote = (id)(*noteCopy)(aNote, @selector(copy));
      _MKNoteShiftTimeTag(aNote, timeShift);
      (*partAddNote)(p->part, @selector(addNote:), aNote);
    }
    aNote = _MKParseScoreNote(p);
    if ((!aNote) && (p->timeTag > (MK_ENDOFTIME-1)))
      break;
  }
#endif
  while (p->timeTag <= lastTimeTag) {
    if (aNote) {
      _MKNoteShiftTimeTag(aNote, timeShift);
      (*partAddNote)(p->part, @selector(addNote:), aNote);
    }
    aNote = _MKParseScoreNote(p);/* not retained or autoreleased - so go careful */
    if ((!aNote) && (p->timeTag > (MK_ENDOFTIME-1)))
      break;
  }


  rtnVal = (p->_errCount == MAXINT) ? nil : self;
  _MKFinishScoreIn(p);
  return rtnVal;
}

-setScorefilePrintStream:(NSMutableData *)aStream
  /* Sets the stream to be used for Scorefile 'print' statement output. */
{
  scorefilePrintStream = aStream;
  return self;
}

-(NSMutableData *)scorefilePrintStream
  /* Returns the stream used for Scorefile 'print' statement output. */
{
  return scorefilePrintStream;
}

-_setInfo:aInfo
  /* Needed by scorefile parser  */
{
  if (!info)
    info = [aInfo copy];
  else
    [info copyParsFrom: aInfo];
  return self;
}

-setInfoNote:(MKNote *) aNote
  /* Sets info, overwriting any previous info. aNote is copied. The old info,
  if any, is freed. */
{
  [info release];
  info = [aNote copy];
  return self;
}

- (MKNote *) infoNote
{
  return info;
}

- combineNotes
  /* combine notes into noteDurs for all MKParts */
{
  unsigned n = [parts count], i;
  for (i = 0; i < n; i++)
    [(MKPart *) [parts objectAtIndex:i] combineNotes];

  return self;
}

- (NSMutableArray *) parts;
  /* Returns a copy of the List of MKParts in the receiver. The MKParts themselves are not copied.
  Now that we use NSArrays, a [List copyWithZone] did a shallow copy, whereas
  [NSMutableArray copyWithZone] does a deep copy, so we emulate the List operation.  */
{
  return _MKLightweightArrayCopy(parts);
}

- copyWithZone:(NSZone *)zone
  /* Copies receiver, including its MKParts, MKNotes and info. */
{
  unsigned n = [parts count], i;
  MKScore *newScore = [MKScore allocWithZone:zone];
  [newScore init];
  for (i = 0; i < n; i++)
    [newScore addPart:[[parts objectAtIndex:i] copyWithZone:zone]];

  newScore->info = [info copyWithZone:zone];
  return newScore;
}

-copy
{
  return [self copyWithZone:[self zone]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
  /* You never send this message directly.
  Should be invoked with NXWriteRootObject().
  Archives MKParts, MKNotes and info. */
{
  [aCoder encodeValuesOfObjCTypes: "@@", &parts, &info];
}

static BOOL isUnarchiving = NO;

- (id)initWithCoder:(NSCoder *)aDecoder
  /* You never send this message directly.
  Should be invoked via NXReadObject().
          See write:. */
{
  NSMutableDictionary *tagTable = [NSMutableDictionary dictionary];
  isUnarchiving = YES; /* Inhibit MKParts' mapping of noteTags. */

  
  if ([aDecoder versionForClassName: @"MKScore"] == VERSION2)
    [aDecoder decodeValuesOfObjCTypes: "@@", &parts, &info];
  /* Maps noteTags as represented in the archive file onto a set that is
    unused in the current application. This insures that the integrity
    of the noteTag is maintained. */
  [parts makeObjectsPerformSelector:@selector(_mapTags:) withObject:tagTable];
  isUnarchiving = NO;
  return self;
}

- (NSString *) description
{
  unsigned int i;
  NSMutableString *scoreDescription = [[NSMutableString alloc] initWithString: @"MKScore containing MKParts:\n"];
  NSMutableArray *partList = [self parts];
  MKPart *aPart;

  for(i = 0; i < [partList count]; i++) {
    aPart = [partList objectAtIndex: i];
    [scoreDescription appendString: [aPart description]];
  }
  [scoreDescription appendFormat: @"With MKScore info note:\n%@", [[self infoNote] description]];

  return scoreDescription;
}

- (MKPart*) partNamed: (NSString*) partName
{
  int i, c = [parts count];
  for (i = 0; i < c; i++) {
    MKPart *mkp = [parts objectAtIndex: i];
    MKNote *infoNote = [mkp infoNote];
    if ([infoNote isParPresent: MK_title]) {
      NSString *s = [infoNote parAsString: MK_title];
      if ([s isEqualToString: partName])
        return mkp;
    }
  }
  return nil;
}

@end

@implementation MKScore(Private)

+(BOOL)_isUnarchiving
{
  return isUnarchiving;
}

-_newFilePartWithName:(NSString *)name
  /* You never send this message. It is used only by the Scorefile parser
  to add a MKPart to the receiver when a part is declared in the
  scorefile.
  It is a method rather than a C function to hide from the parser
  the differences between MKScore and MKScorefilePerformer.
  */
{
  id aPart = [MKGetPartClass() new];
  MKNameObject(name,aPart);
  [self addPart:aPart];
  [aPart autorelease];
  return aPart; /* sb: I have checked, and it's ok to return "reference" here rather than retained object */
}

@end

@implementation MKScore (PluginSupport)

+ (void) addPlugin: (id) plugin
{
    if (!plugins) {
        plugins = [[NSMutableArray alloc] init];
    }
    [plugins addObject:plugin];
}

@end

