/*
  $Id$
  Defined In: The MusicKit

  Description:
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2003 The MusicKit Project.
*/
/*
Modification history before CVS repository commital.

  02/25/90/daj - Changed to make instancable. Added sysexcl support.
  11/18/92/daj - Added evaluateTempo arg to beginWriting/reading
  04/02/99/lms - Made public header
*/
#ifndef MK__midifile_H___
#define MK__midifile_H___

#import <Foundation/Foundation.h>

/* The magic number appearing as the first 4 bytes of a MIDI file. */
#define MK_MIDIMAGIC  ((int)1297377380)  // "MThd"

/*
 * Only the two following metaevents are supported; data[0] contains one
 * of the following codes if the metaevent flag is set. The metaevents are
 * provided for reading. Separate functions exist to write metaevents.
 */

#define MKMIDI_DEFAULTQUANTASIZE (1000)

typedef enum MKMIDIMetaEvent {
    /* In all of the metaevents, data[0] is the metaevent itself. */
    MKMIDI_sequenceNumber = 0,
    /*
     * data[1] and data[2] contain high and low order bits of number. 
     */
    MKMIDI_text = 1,
    MKMIDI_copyright = 2,
    MKMIDI_sequenceOrTrackName = 3,
    MKMIDI_instrumentName = 4,
    MKMIDI_lyric = 5,
    MKMIDI_marker = 6,
    MKMIDI_cuePoint = 7,
    /* data[1]* specifies null-terminated text. 
     */
    /*
     * MKMIDI_channelprefix, should be implemented by midifile.m and 
     * should not be passed up to user. 
     */
    MKMIDI_trackChange,
    /*
     * Track change metaevent: data[1] and data[2] contain high/low order bits,
     * respectively, containing the track number. These events can only be 
     * encountered when reading a level-1 file.
     */
    MKMIDI_tempoChange,
    /*
     * Tempo change metaevent: data[1:3] contain 3 bytes of data.
     */
    MKMIDI_smpteOffset,
    /*
      data[1:5] are the 5 numbers hr mn sec fr ff
      */
    MKMIDI_timeSig,
    /* data is a single int, where 1-byte fields are nn dd cc bb */
    MKMIDI_keySig
    /*  data is a single short, where 1-byte fields are sf mi  */
  } MKMIDIMetaevent;

extern void *MKMIDIFileBeginReading(NSMutableData *s,
				     int **quanta,
				     BOOL **metaevent,
				     int **ndata,
				     unsigned char ***data,
				     BOOL evaluateTempo);
/* Ref args are set to pointers to where data is returned */

extern void *MKMIDIFileEndReading(void *p);

extern int MKMIDIFileReadPreamble(void *p,int *level,int *track_count);
/*
 * Read the header of the specified file, and return the midifile level 
 * (format) of the file, and the total number of tracks, in the respective 
 * parameters. The return value will be non-zero if all is well; any error
 * causes zero to be returned.
 */

extern int MKMIDIFileReadEvent(void *p);
/*
 * Read the next event in the current track. Return nonzero if successful;
 * zero if an error or end-of-stream occurred.
 */

void *MKMIDIFileBeginWriting(NSMutableData *s, int level, NSString *sequenceName,
			      BOOL evaluateTempo);

/*
 * Writes the preamble and opens track zero for writing. In level 1 files,
 * track zero is used by convention for timing information (tempo,time
 * signature, click track). To begin the first track in this case, first
 * call MKMIDIFileBeginWritingTrack.
 * MKMIDIFileBeginWriting must be balanced by a call to MKMIDIFileEndWriting.
 */


extern int MKMIDIFileEndWriting(void *p);
/*
 * Terminates writing to the stream. After this call, the stream may
 * be closed.
 */

extern int MKMIDIFileBeginWritingTrack(void *p, NSString *trackName);
extern int MKMIDIFileEndWritingTrack(void *p,int quanta);
/*
 * These two functions must be called in a level 1 file to bracket each
 * chunk of track data (except track 0, which is special).
 */

extern int MKMIDIFileWriteTempo(void *p,int quanta, double beatsPerMinute);

extern int MKMIDIFileWriteEvent(void *p, int quanta, int ndata, unsigned char *bytes);

extern int MKMIDIFileWriteSysExcl(void *p,int quanta, int ndata, unsigned char *bytes);

extern int MKMIDIFileWriteSig(void *p,int quanta,short metaevent, unsigned data);
/* Write time sig or key sig. Specified in midifile format. */

extern int MKMIDIFileWriteText(void *p,int quanta,short metaevent,NSString *data);

extern int MKMIDIFileWriteSMPTEoffset(void *p,unsigned char hr,
				       unsigned char min,
				       unsigned char sec,
				       unsigned char ff,
				       unsigned char  fr);

int MKMIDIFileWriteSequenceNumber(void *p,int data);



#endif
