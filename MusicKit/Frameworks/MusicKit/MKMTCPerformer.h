/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:45  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_MTCPerformer_H___
#define __MK_MTCPerformer_H___
#import "MKPerformer.h"

/* The following defines must agree with the MIDI time code spec. */
#define MK_MTC_FORMAT_24      0   
#define MK_MTC_FORMAT_25      1
#define MK_MTC_FORMAT_DROP_30 2
#define MK_MTC_FORMAT_30      3

#define MK_MTC_REVERSE (-1)
#define MK_MTC_FORWARD 1

/* These functions do not compensate for deltaT.  They're just straight
 * translation  
 */
extern double 
  MKConvertMTCToSeconds(short format,short hours,short minutes,short seconds,
			short frames);

extern void 
  MKConvertSecondsToMTC(double seconds,short format,short *hoursPtr,short *minutesPtr,
			short *secondsPtr,short *framesPtr);

@interface MKMTCPerformer:MKPerformer
{
    double firstTimeTag;   /* firstTimeTag, as specified by user. */
    double lastTimeTag;    /* lastTimeTag, as specified by user. */
    int direction;         /* 1 for forward, -1 for reverse */
    short format;          /* MTC format */
    id noteSender;
    id aNote;
    BOOL frozen;

    /* The following are for internal use only.  Do not access them directly */
    int _cmpStat;          
    short _lastHours;
    short _lastMinutes;
    short _lastSeconds;
    short _lastFrames;
    short _frameQuarter;
    short _hours;
    short _minutes;
    short _seconds;
    short _frames;
}

- init;
/* Sent to new objects */

-setFirstTimeTag:(double)f;
/* Sets firstTimetTag that will be output.  Also sets time from activation
 * at which this performer will start sending time code.  You can decouple
 * the time the performer runs from the time code it outputs by using 
 * Performer's setTimeShift:.  For example, to generate time code, beginning
 * with time 2, and to start sending that time code at time 3, you'd send:
 *     [perf setFirstTimeTag:2]; 
 *     [perf setTimeOffset:1];
 */

-setLastTimeTag:(double)l;
/* Sets lastTimetTag that will be output.  The Performer runs until lastTimeTag
 * is output.  If direction is MK_MTC_REVERSE, lastTimeTag should be less than
 * firstTimeTag.  Otherwise, lastTimeTag should be greater than firstTimeTag.
 */

-setFirstTimeTagMTCHours:(short)h minutes:(short)m seconds:(short)s frames:(short)f;
/* Same as setFirstTimeTag:, except that the time is specified in Midi time
 * code units.  Assumes the current format. (See setFormat:)
 */

-setLastTimeTagMTCHours:(short)h minutes:(short)m seconds:(short)s frames:(short)f;
/* Same as setLastTimeTag:, except that the time is specified in Midi time
 * code units.  Assumes the current format. (See setFormat:)
 */

-setTimeShiftMTCHours:(short)h minutes:(short)m seconds:(short)s frames:(short)f;
/* Same as setTimeShift:, except that the time is specified in Midi time
 * code units.  Assumes the current format. (See setFormat:)
 */

-(double)firstTimeTag;
/* Returns firstTimeTag, as previously set with setLastTimeTag: or
 * setFirstTimeTagMTCHours:minutes:seconds:frames: 
 */

-(double)lastTimeTag;
/* Returns lastTimeTag, as previously set with setLastTimeTag: or
 * setLastTimeTagMTCHours:minutes:seconds:frames:
 */

-setFormat:(int)fmt;
/* Sets format of the timecode to one of the following:
   MK_MTC_FORMAT_24
   MK_MTC_FORMAT_25
   MK_MTC_FORMAT_DROP_30
   MK_MTC_FORMAT_30
 */

-(double)timeTag;
/* Returns the current time code value being output. */

-getMTCHours:(short *)h minutes:(short *)m seconds:(short *)s frames:(short *)f;
/* Same as timeTag, except that the time is returned in Midi time code units.
 * Assumes the current format. */

-setDirection:(int)newDirection;
/* Sets direction of time code to be generated. */

-sendUserBits:(unsigned int)userBits groupFlagBits:(unsigned char)groupFlagBits;
/* Sends SMPTE user bits */

-freezeTimeCode;  
/* Stops the advance of time code, but doesn't pause performer.  Time code will
 * continue to be generated, but the same value will be output over and over.
 */

-thawTimeCode;
/* Undoes the effect of freezeTimeCode. */

-sendFullMTCMessage; 
/* Sends the current time as a MIDI full message. */

-activateSelf;    /* Prepares the object for performance */
- (void)deactivate;  /* Sends NAK SYSEX, then deactivates. */
-pause;           /* Sends NAK SYSEX, then pauses.  */
-resume;          /* Resumes time code. Sends a Full message */
-perform;


@end



#endif
