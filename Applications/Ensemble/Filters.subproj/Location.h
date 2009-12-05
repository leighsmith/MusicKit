#ifndef __MK_Location_H___
#define __MK_Location_H___
#import "musickit/musickit.h"
#import "EnsembleNoteFilter.h"

typedef enum _LocateType {
    Spread, Randomize, Key, Sweep} 
LocateType;

@interface Location : EnsembleNoteFilter
    /* a Notefilter that provides various left-right panning effects. */
{    
    double minBearing;
    double maxBearing;
    double minFollowBearing;
    double maxFollowBearing;
    double width;
    double halfWidth;
    double center;
    double bearing;
    double minSweepTime,sweepTimeScl;
    double spreadInc;
    int minKey,maxKey,keyWidth;
    int positions;
    LocateType type;
    BOOL followMidiPan;
    BOOL sendMidiPan;
    BOOL performerStatus;
    Note *note;
    Conductor *conductor;
    id tagTable;

	id paramInterface;
	id typeButtons;
	id trackMidiSwitch;
	id sendMidiSwitch;
}

- takeParamFrom:sender;
- takeTypeFrom:sender;
- toggleFollowing:sender;
- togglePanSending:sender;

@end


#endif
