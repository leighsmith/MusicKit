#import <libc.h>
#import <musickit/musickit.h>
#import "RandomPerformer.h"

@implementation RandomPerformer

static transposition = 0; /* To keep it from getting TOO boring, we slowly
			     change the scale from which notes are chosen */

static double ranNum(RandomPerformer *self)
    /* Returns a random number between 0 and 1. */
{
    double newVal;
#   define   RANDOMMAX (double)((long)MAXINT)
    newVal =  ((double)random()) / RANDOMMAX;
    newVal = (newVal * .75 + self->oldRanValue * .25);  
                   /* Low pass filter the noise for more coherency */
    self->oldRanValue = newVal;
    return newVal;
}

static int
  ranInt(id self,int lowBound,int highBound)
/* Returns a random int between the specified bounds (inclusive) */
{
    return ( ranNum(self) * (highBound - lowBound) + lowBound + .5);
}

static id ampEnvelope, freqEnvelope;

+initialize 
{
    /* arrays are copied below so auto vars are ok*/
    double xAmpArray[] = {0,1.0,2.0,2.5}; 
    double yAmpArray[] = {0,1.0,.015,0};
    double xFreqArray[] = {0,.05,.1,.2};
    double yFreqArray[] = {.99,1.1,1.0,.99};
    ampEnvelope = [[Envelope alloc] init];
    [ampEnvelope setPointCount:4 xArray:xAmpArray yArray:yAmpArray];
    [ampEnvelope setStickPoint:2];
    freqEnvelope = [[Envelope alloc] init];
    [freqEnvelope setPointCount:4 xArray:xFreqArray yArray:yFreqArray];
    [freqEnvelope setStickPoint:1];
    return self;
}

-init
  /* This method is invoked when a new instance is created. */
{
    int aTag;
      /* You must send [super init] in your subclass' implementation. */
    [super init];
    octaveOffset = 60;             /* Start each in the middle of its range */
    rhythmicValue = 1;             /* Start each with rhythmic val of 1 beat */
    noteOn = [[Note alloc] init];  /* We'll reuse the same Notes here */
    [noteOn setNoteType:MK_noteOn];
    [noteOn setNoteTag:aTag = MKNoteTag()];
    noteOff = [[Note alloc] init];
    [noteOff setNoteType:MK_noteOff];
    [noteOff setNoteTag:aTag];
       /* We give ourselves one NoteSender. */  
    [self addNoteSender:[[NoteSender alloc] init]];
    return self;
}

-setRhythmicValueTo:(double)r
  /* Sets the rhythmic value (duration of Notes and rests between Notes) */
{
    rhythmicValue = r;
    return self;
}

-setOctaveTo:(int)octaveNumber
  /* Sets the Octave number as specified */
{
    octaveOffset = octaveNumber * 12;
    return self;
}

static int pentatonicMode[5] = {0,2,4,7,9};  /* e.g. C-D-E-G-A */

static id getDefaults(id self)
{
    id noteUpdate = [[Note alloc] init];
    static char *timbres[] = 
	{"SA","SE","SI","SO","SU","TR","SS","CL","OB","TR","CL","OB","TA",
	     "TE","TI","TO","TU","BN","AS","BC","EH","BA","BE","BO","BU"};
    
    [noteUpdate setNoteType:MK_noteUpdate];
    [noteUpdate setPar:MK_ampEnv toEnvelope:ampEnvelope];
    [noteUpdate setPar:MK_ampAtt toDouble:ranNum(self) * 2.0 + .01];
    [noteUpdate setPar:MK_ampRel toDouble:ranNum(self) * 1.0 + .01];
    [noteUpdate setPar:MK_freqEnv toEnvelope:freqEnvelope]; 
    [noteUpdate setPar:MK_freqAtt toDouble:ranNum(self) * .1 + .05];
    [noteUpdate setPar:MK_freqRel toDouble:ranNum(self) * .2 + .1];
    [noteUpdate setPar:MK_waveform toString:timbres[ranInt(self,0,24)]];
    [noteUpdate setPar:MK_svibAmp toDouble:ranNum(self) * .015];
    [noteUpdate setPar:MK_svibFreq toDouble:ranNum(self) + 4.5];
    [noteUpdate setPar:MK_rvibAmp toDouble:ranNum(self) * .01];
    return noteUpdate;
}

-perform
  /* This is invoked by the Conductor (via the Performer class) each time
     a Note is to be sent. */
{
    if (performCount == 1 || (!on && ranNum(self) < .1)) {
	/* First note or change-of-pace needed?  */
	id aNoteUpdate = getDefaults(self);     /* Send a no-tag noteUpdate */
	[[self noteSender] sendNote:aNoteUpdate];
	[aNoteUpdate free];
    }
    if (on && ranNum(self) < .2) {              /* 20% chance of noteOff */
	[[self noteSender] sendNote:noteOff];
	on = NO;
    }
    else if (ranNum(self) > .2) {               /* else 80% chance of noteOn */
	[noteOn setPar:MK_keyNum toInt:octaveOffset + 
	 pentatonicMode[ranInt(self,0,4)] + transposition];
	[[self noteSender] sendNote:noteOn];
	on = YES;
    }
    if (ranNum(self) < .05)          /* Occassionally change scale. */
	transposition = (transposition + 2) % 12;
    nextPerform = rhythmicValue;      /* Time to next invocation of -perform */
    return self;
}

-pause {
    /* We override superclass pause method to turn off any sounding Note. */
    if (on) {
	[[self noteSender] sendNote:noteOff];
	on = NO;
    }
    /* We forward to the superclass to handle the timing details */
    [super pause];
    return self;
}

@end
