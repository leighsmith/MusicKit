#ifndef __MK_ReadsoundUG_H___
#define __MK_ReadsoundUG_H___
/* Copyright CCRMA, 1992.  All rights reserved. */

#import <musickit/UnitGenerator.h>
#import <musickit/Conductor.h>
@interface ReadsoundUG : UnitGenerator
{ 
    id aSound;
    int currentSample;  
    int sampleCount;
    MKMsgStruct *_msgPtr;    
    double _bufferDuration;  
    id _synthData;           
    short *_data;            
}

-init;
  /* Sent by the superclass when the UnitGenerator is created. */

-setSound:sound;
  /* Sets sound, which is NOT copied. Returns nil if sound is nil or if there's
     a problem, else self. Note that you must send -run after -setSound: to 
     begin reading the new sound. You can abort a sound by sending 
     setSound:nil */

-setSoundfile:(char *)file;
  /* Same as setSound: but uses a Soundfile. */

-setSamples:aSamples;
  /* Same as setSound: but uses a Samples object. */

-setOutput:aPatchPoint;
  /* Set output to the specified patch point. */

-runSelf;
  /* Invoked by -run. Starts the sound on its way. If you send run 
     twice, the sound is retriggered. Note that the message idle
     causes the sound to be 'forgotten'. */

-idleSelf;
  /* Idling a ReadSound patches its output to Sink (nowhere) and resets
     its sound to nil. */

@end
#endif
