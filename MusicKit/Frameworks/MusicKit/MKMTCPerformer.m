/*
  $Id$
  Defined In: The MusicKit

  Description:
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:16:37  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#import "MusicKit.h"
#import "MKMTCPerformer.h"

/* To do:  Add user bits, NAK, full messages */

@implementation MKMTCPerformer:MKPerformer
{
    double firstTimeTag;   /* firstTimeTag, as specified by user. */
    double lastTimeTag;    /* lastTimeTag, as specified by user. */
    int direction;         /* 1 for forward, -1 for reverse */
    short format;          /* MTC format */
    id noteSender;
    id aNote;
    BOOL frozen;

    int _cmpStat;

    /* This is the stopping point, in delta-t-adjusted time */
    short _lastHours;
    short _lastMinutes;
    short _lastSeconds;
    short _lastFrames;
    short _frameQuarter;     /* Which quarter-frame we're on */

    /* These are the time in delta-t adjusted units.  Use
     * the access methods to get their value in Conductor's time
     * base.
     */
    short _hours;
    short _minutes;
    short _seconds;
    short _frames;
}


enum {CMP_NONE,CMP_HOURS,CMP_MINUTES,CMP_SECONDS};

- init
{
    [super init];
    [self addNoteSender:noteSender = [[MKNoteSender alloc] init]];
    aNote = [[MKNote alloc] init];
    format = MK_MTC_FORMAT_24; /* default */
    [self setFirstTimeTag:0];
    [self setLastTimeTagMTCHours:23 minutes:59 seconds:0 frames:0];
    _cmpStat = CMP_NONE;
    direction = MK_MTC_FORWARD;
    return self;
}

-(double)firstTimeTag
{
    return firstTimeTag;
}

-(double)lastTimeTag
{
    return lastTimeTag;
}

/* There are 4 types of time code, 24, 25, 30-drop, and 30-no-drop. Only
   drop-frame is tricky.

   Here's the story about drop-frame:

   Color NTSC is only 29.97 frames per second instead of 30.  
   To compensate for this descrepency, 108 frames are eliminated each hour.
   This is done by omitting the first two frames every minute (see exception
   below).  E.g. after 01:08:59:29 comes 01:09:00:02.  The exception is that
   on every 10th minute, frames are not dropped.  This ensures that 108, rather
   than 120 frames are dropped. 

   This means that time code can be behind clock time by as much as
   2 frames @ 29.97 frames/sec. = 60 ms every minute.  Then the time
   code synchs up to within 6 milliseconds of clock time every minute
   (see below). Finally, every 10 minutes, time code synchs up exactly
   with clock time.

   30 frames/" * 59" + 28 frames = 1798 frames
   1798/29.97 = 59.993", which is 6 ms short. 

   I assume that it is on 10 minute boundaries that frames are not dropped or
   is it every 10 minutes from the start of time code. I'm not sure if that's
   right.
*/   

static const unsigned int mtcFramesPerSec[] = {24,25,30,30};
static const double mtcQuarterFrameInc[] = {.010417,.010000,.008333,.008341};
static const double mtcFrameInc[] = {1/24.0,1/25.0,1/30.0,1/30.0};
// static const double mtcDoubleFrameInc[] = {2/24.0,2/25.0,2/30.0,2/30.0};

double 
  MKConvertMTCToSeconds(short format,short hours,short minutes,short seconds,
			short frames)
/* This function does not compensate for deltaT */
{
    if (format == MK_MTC_FORMAT_DROP_30)
      return (((1/29.97) * frames) + ((30/29.97) * seconds) + 
	      ((1/29.97) * (30 * 59 + 28) * (minutes % 10)) + 
	      ((minutes - (minutes % 10)) * 60) + 
	      hours * 60 * 60);
    return frames * mtcFrameInc[format] + seconds + minutes * 60 + hours * (60 * 60);
}

void 
  MKConvertSecondsToMTC(double seconds,short format,short *hoursPtr,short *minutesPtr,
			short *secondsPtr,short *framesPtr)
/* This function does not compensate for deltaT */
{
    double x;
    *hoursPtr = seconds * (1.0/(60 * 60));
    if (*hoursPtr > 23) {   /* Clip to maximum allowable MTC value */
	seconds -= (*hoursPtr - 23) * 60 * 60;
	*hoursPtr = 23;
    }
    x = *hoursPtr * 60;  /* x is now minutes */
    *minutesPtr = (seconds - x) * (1.0/60);
    x *= 60;             /* x is now seconds */
    x += *minutesPtr * 60;
    *secondsPtr = (seconds - x);
    if (format == MK_MTC_FORMAT_DROP_30) {
	int mins = *minutesPtr % 10;  /* Proportion of minutes mod 10 */
	int secs;
	double y,frames;
	*minutesPtr -= mins;          /* We'll add this back later */
	secs = *secondsPtr + mins * 60;
	y = secs / (60.0 * 10);       /* y is in tens of (minutes % 10) */
	frames = y * (28 * 9 * 60 + 30 * 60); 	 /* frames in (minutes % 10) */
	*minutesPtr += frames / (28 * 60);
	frames -= *minutesPtr * (28 * 60);
	*secondsPtr = frames / 28;
	frames -= *secondsPtr * 28;
	*framesPtr = frames + 2;
    } else {
	x *= mtcFramesPerSec[format];/* x is now frames */
	x += *secondsPtr * mtcFramesPerSec[format];
	*framesPtr = (seconds - x) * mtcFrameInc[format];
    }
}

-setFirstTimeTag:(double)f
{
    if (status != MK_inactive)
      return nil;
    firstTimeTag = f;
    if (MKGetDeltaTMode() == MK_DELTAT_DEVICE_LAG)
      f += MKGetDeltaT();
    MKConvertSecondsToMTC(f,format,&_hours,&_minutes,&_seconds,&_frames);
    return self;
}

-setLastTimeTag:(double)l
{
    if (status != MK_inactive) 
      return nil;
    lastTimeTag = l;
    if (MKGetDeltaTMode() == MK_DELTAT_DEVICE_LAG)
      l += MKGetDeltaT();
    MKConvertSecondsToMTC(l,format,&_lastHours,&_lastMinutes,
			  &_lastSeconds,&_lastFrames);
    return self;
}

-setFormat:(int)fmt
{
    format = fmt;
    return self;
}

-setFirstTimeTagMTCHours:(short)h minutes:(short)m seconds:(short)s frames:(short)f
{
    if (status != MK_inactive)
      return nil;
    firstTimeTag = MKConvertMTCToSeconds(format,h,m,s,f);
    if (MKGetDeltaTMode() == MK_DELTAT_DEVICE_LAG) 
      MKConvertSecondsToMTC(firstTimeTag + MKGetDeltaT(),format,&h,&m,&s,&f);
    _hours = h;
    _minutes = m;
    _seconds = s;
    _frames = f;
    return self;
}

-setLastTimeTagMTCHours:(short)h minutes:(short)m seconds:(short)s frames:(short)f
{
    if (status != MK_inactive) 
      return nil;
    lastTimeTag = MKConvertMTCToSeconds(format,h,m,s,f);
    if (MKGetDeltaTMode() == MK_DELTAT_DEVICE_LAG) 
      MKConvertSecondsToMTC(lastTimeTag + MKGetDeltaT(),format,&h,&m,&s,&f);
    _lastHours = h;
    _lastMinutes = m;
    _lastSeconds = s;
    _lastFrames = f;
    return self;
}

-setTimeShiftMTCHours:(short)h minutes:(short)m seconds:(short)s frames:(short)f
{
    if (status != MK_inactive) 
      return nil;
    return [self setTimeShift:MKConvertMTCToSeconds(format,h,m,s,f)];
}

-getMTCHours:(short *)h minutes:(short *)m seconds:(short *)s frames:(short *)f
  /* Can be called at any time to get current timetag in MTC units */
{
    if (MKGetDeltaTMode() == MK_DELTAT_DEVICE_LAG) {
	double t = MKConvertMTCToSeconds(format,_hours,_minutes,_seconds,_frames);
	MKConvertSecondsToMTC(t - MKGetDeltaT(),format,h,m,s,f);
	return self;
    }
    *h = _hours;
    *m = _minutes;
    *s = _seconds;
    *f = _frames;
    return self;
}

-(double)timeTag
  /* Can be called at any time to get current timetag in seconds */
{
    return (MKConvertMTCToSeconds(format,_hours,_minutes,_seconds,_frames) - 
	    (MKGetDeltaTMode() == MK_DELTAT_DEVICE_LAG) ? MKGetDeltaT() : 0);
}

-activateSelf
{
    nextPerform = firstTimeTag;
    [self setFirstTimeTag:firstTimeTag]; /* Updates MTC variables */
    _cmpStat = CMP_NONE;
    if (_hours == _lastHours) {
	_cmpStat = CMP_HOURS;
	if (_minutes == _lastMinutes) {
	    _cmpStat = CMP_MINUTES;
	    if (_seconds == _lastSeconds) {
		_cmpStat = CMP_SECONDS;
	    }
	}
    }
    return (((firstTimeTag <= lastTimeTag) && (direction > 0)) ||
	    ((firstTimeTag >= lastTimeTag) && (direction < 0))) ? self : nil;
}

-sendFullMTCMessage
  /* Sends a MIDI Full message reporting the current time. */
{
//    char msg[32];
    unsigned int h,m,s,fr;
    h = (format << 5) | ( _hours & 0x1f);
    m = _minutes & 0xff;
    s = _seconds & 0xff;
    fr = _frames & 0xff;
//    sprintf(msg,"f0,7f,7f,01,02,%-2x,%-2x,%-2x,%-2x,f7",h,m,s,fr);
    [aNote setPar:MK_sysExclusive toString:[NSString
         stringWithFormat:@"f0,7f,7f,01,02,%-2x,%-2x,%-2x,%-2x,f7",h,m,s,fr]];
    [noteSender sendNote:aNote];
    [aNote removePar:MK_sysExclusive];
    return self;
}

-sendUserBits:(unsigned int)userBits groupFlagBits:(unsigned char)groupFlagBits
  /* Sends a MIDI SMPTE User Bits message. 
   */
{
//    char msg[64];
    #define BYTENUM(_x) ((userBits << _x) & 0x0f)
/*
    sprintf(msg,"f0,7f,7f,01,02,"
	    "0%-1x,0%-1x,0%-1x,0%-1x,0%-1x,0%-1x,0%-1x,0%-1x,0%-1x,f7",
	    BYTENUM(7),BYTENUM(6),BYTENUM(5),BYTENUM(4),
	    BYTENUM(3),BYTENUM(2),BYTENUM(1),BYTENUM(0),
	    (unsigned int)groupFlagBits);
 */
    [aNote setPar:MK_sysExclusive toString:[NSString
         stringWithFormat:@"f0,7f,7f,01,02,0%-1x,0%-1x,0%-1x,0%-1x,0%-1x,0%-1x,0%-1x,0%-1x,0%-1x,f7",
         BYTENUM(7),BYTENUM(6),BYTENUM(5),BYTENUM(4),
                    BYTENUM(3),BYTENUM(2),BYTENUM(1),BYTENUM(0),
                    (unsigned int)groupFlagBits]];
    [noteSender sendNote:aNote];
    [aNote removePar:MK_sysExclusive];
    return self;
}

-_sendNAK
  /* Sends NAK SYSEX message */
{
    [aNote setPar:MK_sysExclusive toString:@"f0,7e,7f,7e,00,f7"];
    [noteSender sendNote:aNote];
    [aNote removePar:MK_sysExclusive];
    return self;
}

- (void)deactivate
  /* Sends NAK SYSEX */
{
    [self _sendNAK];
}

-pause
  /* Sends NAK SYSEX */
{
    [super pause];
    [self _sendNAK];
    return self;
}

-resume
{
    [super resume];
    [self sendFullMTCMessage];
    return self;
}

-freezeTimeCode
  /* Continues sending time code, but time doesn't advance */
{
    frozen = YES;
    return self;
}

-thawTimeCode
{
    frozen = NO;
    return self;
}

-perform
{
    int data;
    if (performCount == 1)
      [self sendFullMTCMessage];
    if (frozen) {
	if (direction == MK_MTC_FORWARD) {
	    if (++_frameQuarter == 8)
	      _frameQuarter = 0;
	} else if (--_frameQuarter == -1)
	  _frameQuarter = 7;
    }
    else if (direction == MK_MTC_FORWARD) {
	if (++_frameQuarter == 8) {
	    _frameQuarter = 0;
	    if (format == MK_MTC_FORMAT_DROP_30) {
	    
	    } else {  /* All other formats */
		_frames += 2;
		if (_frames >= mtcFramesPerSec[format]) {
		    _frames = 0;
		    if (++_seconds == 60) {
			_seconds = 0;
			if (++_minutes == 60) {
			    _minutes = 0;
			    ++_hours;
			    if (_hours == 24)
			      _hours = 0;
			    if (_hours == _lastHours)
			      _cmpStat = CMP_HOURS;
			}
			if (_cmpStat == CMP_HOURS && _minutes == _lastMinutes)
			  _cmpStat = CMP_MINUTES;
		    }
		    if (_cmpStat == CMP_MINUTES && _seconds == _lastSeconds)
		      _cmpStat = CMP_SECONDS;
		}
		if (_cmpStat == CMP_SECONDS && _frames >= _lastFrames) {[self deactivate]; return self;}
	    }
	}
    } else {
	if (--_frameQuarter == -1) {
	    _frameQuarter = 7;
	    if (format == MK_MTC_FORMAT_DROP_30) {
	    
	    } else {  /* All other formats */
		_frames -= 2;
		if (_frames < 0) {
		    _frames = mtcFramesPerSec[format] - 1;
		    if (--_seconds < 0) {
			_seconds = 59;
			if (--_minutes < 0) {
			    _minutes = 59;
			    --_hours;
			    if (_hours < 0)
			      _hours = 23;
			    if (_hours == _lastHours)
			      _cmpStat = CMP_HOURS;
			}
			if (_cmpStat == CMP_HOURS && _minutes == _lastMinutes)
			  _cmpStat = CMP_MINUTES;
		    }
		    if (_cmpStat == CMP_MINUTES && _seconds == _lastSeconds)
		      _cmpStat = CMP_SECONDS;
		}
		if (_cmpStat == CMP_SECONDS && _frames <= _lastFrames) {[self deactivate]; return self;}
	    }
	}
    }
    switch (_frameQuarter) {
      case 0:
	data = _frames & 0xf;
	break;
      case 1:
	data = (1 << 4) | ((_frames >> 4) & 0xf);
	break;
      case 2:
	data = (2 << 4) | (_seconds & 0xf);
	break;
      case 3:
	data = (3 << 4) | ((_seconds >> 4) & 0xf);
	break;
      case 4:
	data = (4 << 4) | (_minutes & 0xf);
	break;
      case 5:
	data = (5 << 4) | ((_minutes >> 4) & 0xf);
	break;
      case 6:
	data = (6 << 4) | (_hours & 0xf);
	break;
      case 7:
	data = (6 << 4) | ((_hours >> 4) & 0x1) | (format << 1);
	break;
      default:
	data = 0; /* Shut up compiler warning */
	break; 
    }
    [aNote setPar:MK_timeCodeQ toInt:data];
    [noteSender sendNote:aNote];
    nextPerform = mtcQuarterFrameInc[format];
    return self;
}

-setDirection:(int)newDirection
{
    if (direction == newDirection)
      return self;
    direction = newDirection;
    if (newDirection == MK_MTC_FORWARD)
      _frameQuarter = 7;   /* Will wrap and be set to 0 */
    else _frameQuarter = 0;/* Will wrap and be set to 7 */
    return self;
}

@end

