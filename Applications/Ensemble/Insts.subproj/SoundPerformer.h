#ifndef __MK_SoundPerformer_H___
#define __MK_SoundPerformer_H___
#import <musickit/Performer.h>
#import <sound/sound.h>
#import <soundkit/soundkit.h>

@interface SoundPerformer : Performer
{
    SNDSoundStruct *sound;
    NXPlayStream *soundStream;
    char *data;
    char *endData;
    char *buffer;
    char *bufptr;
    int  chunk;
    double performDuration;
    int channelCount;
    int samplingRate;
    int tag;
    float pitchBend;
    float transposition;
    float fraction;
    BOOL resamplingEnabled;
    float amp;
	float volume;
	float leftPan, rightPan;
	int bufferSize;
	int nchunks;
	int frameSize;
	float velocity;
	double activationTime;
	char *buffers[16];
	int bufferTag;
	BOOL preloadingEnabled;
	float rateConvert;
}


- initWithSound:(SNDSoundStruct *)aSoundStruct;
- setSoundStruct:(SNDSoundStruct *)aSoundStruct;
- (SNDSoundStruct *)soundStruct;
- setPitchBend:(float)aPitchBend;
- setTransposition:(float)aTransposition;
- setAmp:(float)amp;
- setVolume:(float)volume;
- setVelocity:(float)aVelocity;
- setBearing:(float)pan;
- setAmp:(float)anAmp volume:(float)aVolume bearing:(float)aBearing;
- enableResampling:(BOOL)flag;
- enablePreloading:(BOOL)flag;
- setTag:(int)aTag;
- (int)tag;
- reset;
- abort;
- (double)activationTime;

@end
#endif
