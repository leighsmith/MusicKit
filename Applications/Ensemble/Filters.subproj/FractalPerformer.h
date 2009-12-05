#ifndef __MK_FractalPerformer_H___
#define __MK_FractalPerformer_H___
#import <musickit/Performer.h>
#import "FractalMelody.h"

@interface FractalPerformer : Performer
    /* A performer which generates melodies based on fractal functions */
{
    id keynumFractal;
    id dynamicsFractal;
    id phrasingFractal;
    id controllerFractal;
    int controller;
    double delay;
    
    id noteSender;
    id noteon;
    
    BOOL noteSets[NUMSETS][12];
    float noteGravities[NUMSETS][12];
    double setDurations[NUMSETS];
    int notes[NUMSETS][128];
    float gravities[NUMSETS][128];
    int notesInSet[NUMSETS];
    
    int currentSet;
    int maxSetNum;
    double nextSetTime;
    int restMode;
    BOOL useDurations;
    
    int dynamicSetSize;
    int numDynamicNotes;
    int numDynamicNoteOns;
    int minNoteOns, maxNoteOns;
    int minVelocity, maxVelocity;
    float velocityRange;
    double minDuration, maxDuration;
    double lastNoteOnTime;
    BOOL addOctaves;
    BOOL pitchSorting;
    BOOL uniqueNotes;
    char velocityTracking;
    float velGravityScale;
    float durGravityScale;
    float repGravityScale;
    id dynamicNotes[32];
    int dynamicCounts[128];
    float dynamicGravities[32];
    int noteTags[128];
    double offTimes[128];
    
    int minKey, maxKey;
    int minVel, maxVel;
    int dynamicMinKey, dynamicMaxKey;
    
    BOOL dynamicMode;
    BOOL tieRepeats, noRepeats;
    
    double noteInterval;
    double noteDuration;
    float silence;
    int minVal, maxVal;
    float valDiff;
    int lastKey;
    double startTime;
    BOOL setChange;
	int numTags;
	int tagIndex;
	
	int transposition;
	BOOL intervalChanged;
}

- setDynamicMode:(BOOL)state;
- (BOOL)dynamicMode;
- setDelay:(double)delayTime;
- (double)delay;
- setMinKey:(int)key;
- setMaxKey:(int)key;
- (int)minKey;
- (int)maxKey;
- setMinVelocity:(int)vel;
- setMaxVelocity:(int)vel;
- (int)minVelocity;
- (int)maxVelocity;
- setTieRepeats:(BOOL)state;
- setNoRepeats:(BOOL)state;
- (BOOL)tieRepeats;
- (BOOL)noRepeats;
- setNoteInterval:(double)interval;
- (double)noteInterval;
- setNoteDuration:(double)aDuration;
- (double)noteDuration;
- setRestMode:(int)mode;
- (int)restMode;
- setSilence:(float)val;
- (float)silence;
- setMinControlVal:(int)val;
- setMaxControlVal:(int)val;
- (int)minControlVal;
- (int)maxControlVal;
- setController:(int)controller;
- (int)controller;
- setStaticNote:(int)set key:(int)key enabled:(BOOL)flag;
- setStaticGravity:(int)set key:(int)key gravity:(float)gravity;
- incrementStaticGravity:(int)set key:(int)key increment:(float)inc;
- selectStaticSet:(int)setNumber;
- (int)currentSet;
- (int)maxSetNum;
- (BOOL)noteState:(int)set key:(int)aKey;
- (float)noteGravity:(int)set key:(int)aKey;
- (double)noteSetDuration:(int)set;
- setSetDuration:(int)set :(double)duration;
- setUseDurations:(BOOL)state;
- (BOOL)useDurations;
- setNumTags:(int)num;
- (int)numTags;
- setTransposition:(int)trans;

- setDynamicSetSize:(int)numNotes;
- (int)dynamicSetSize;
- addDynamicNote:aNote;
- setAddOctaves:(BOOL)state;
- setUniqueNotes:(BOOL)state;
- setPitchSorting:(BOOL)state;
- (BOOL)addOctaves;
- (BOOL)uniqueNotes;
- (BOOL)pitchSorting;
- setVelocityTracking:(char)mode;
- (char)velocityTracking;
- setVelGravityScale:(float)inc;
- setDurGravityScale:(float)inc;
- setRepGravityScale:(float)inc;
- (float)velGravityScale;
- (float)durGravityScale;
- (float)repGravityScale;

- inspectFractal:sender;
- keynumFractal;
- dynamicsFractal;
- phrasingFractal;
- controllerFractal;

- reset;
- notesOff;

@end


#endif
