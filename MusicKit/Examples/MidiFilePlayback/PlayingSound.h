#ifndef __MK_PlayingSound_H___
#define __MK_PlayingSound_H___
#import <MusicKit/MusicKit.h>
#import <SoundKit/SoundKit.h>

@interface PlayingSound : NSObject
{
    SndSoundStruct *soundStruct;
    NXPlayStream *soundStream;
    Sound *sound;

    char *data;
    char *endData;
    char *buffer;
// NSMutableData *buffer;
    char *bufptr;
    int  chunk;
    double performDuration;
    int channelCount;
    int samplingRate;
    float rateConvert;
    int noteTag;
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
// NSArray *buffer;
// May need to be a dictionary if the integer noteTag is to be used , when we want to delete something.
	int bufferTag;
	BOOL preloadingEnabled;
    MKConductor *conductor;
    MKPerformerStatus status; // extreme kludge and will be removed when we purge this class of MKperformerisms which it isn't.
}

- (void) dealloc;
- initWithSound:(Snd *) aSound andNote: (MKNote *) note;
- setSound:(Snd *) aSoundObj;
- (SndSoundStruct *)soundStruct;
- (Sound *) sound;
- setPitchBend:(float)aPitchBend;
- setTransposition:(float)aTransposition;
- setAmp:(float)amp;
- setVolume:(float)volume;
- setVelocity:(float)aVelocity;
- setBearing:(float)pan;
- setAmp:(float)anAmp volume:(float)aVolume bearing:(float)aBearing;
- enableResampling:(BOOL)flag;
- (void) enablePreloading:(BOOL)flag;
- setNoteTag:(int)aTag;
- (int)noteTag;
- reset;
- abort;
- (double)activationTime;
- (void) deactivate;
- (NSString *) description;

@end
#endif
