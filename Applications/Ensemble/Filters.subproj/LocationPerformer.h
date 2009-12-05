#ifndef __MK_LocationPerformer_H___
#define __MK_LocationPerformer_H___
#import <musickit/Performer.h>

@interface LocationPerformer : Performer
    /* A performer which implements dynamic panning back and forth */  
{
    double minBearing;
    double maxBearing;
    double bearing;
    double width;
    double sweepTime;
    double direction;
    BOOL sendMidiPan;
    id note;
    id noteSender;
}

- setMinBearing:(double)bearing;
- setMaxBearing:(double)bearing;
- setSweepTime:(double)time;
- setSendMidiPan:(BOOL)sendPan;
- (double)bearing;

@end



#endif
