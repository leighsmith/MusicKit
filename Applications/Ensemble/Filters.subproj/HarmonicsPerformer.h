#ifndef __MK_HarmonicsPerformer_H___
#define __MK_HarmonicsPerformer_H___
#import <musickit/Performer.h>

#define NUMHARMS 32

@interface HarmonicsPerformer : Performer
    /* A performer which generates dynamically-changing harmonics */
{
    double interval;
    float velocityAmp;
    float freq;
    float amp;
    float firstHarm;
    float numHarms;
    float lastHarm;
    float spectralPower;
    double noteDuration;
    float bendSensitivity;
    float intervalScale;
    float durationScale;
    float harmScale;
    float startTime;
    int tags[NUMHARMS];
    id noteOffs[NUMHARMS];
    id fractal;
    BOOL useFractal;
    BOOL noRepeats;
    id noteSender;
	int numTags;
	int tagIndex;
}

- setInterval:(double)anInterval;
- (double)interval;
- setDuration:(double)aDuration;
- (double)noteDuration;
- setFirstHarmonic:(float)firstHarmonic;
- (float)firstHarmonic;
- setNumHarmonics:(int)numHarmonics;
- (int)numHarmonics;
- setSpectralPower:(float)power;
- (float)spectralPower;
- setBendSensitivity:(int)bend;
- (int)bendSensitivity;
- setNoRepeats:(BOOL)state;
- (BOOL)noRepeats;
- setUseFractal:(BOOL)state;
- (BOOL)usingFractal;
- setFreq:(float)aFreq;
- setVelocity:(int)aVelocity;
- setAmp:(float)anAmp;
- setIntervalScale:(float)aScaler;
- setDurationScale:(float)aScaler;
- setHarmonicsScale:(float)aScaler;
- inspectFractal:sender;
- setNumTags:(int)num;
- (int)numTags;

@end


#endif
