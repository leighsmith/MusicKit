#ifndef __MK_SoundRecorder_H___
#define __MK_SoundRecorder_H___
#import <objc/Object.h>
#import <sound/sound.h>

@interface SoundRecorder:Object
{
	id recordStream;
	int squelch;
	int dataSize;
	unsigned char *data, *dataPtr;
}

- startRecording;
- stopRecording;
- setSquelch:(int)dB;
- (BOOL)isActive;
- (SNDSoundStruct *)soundStruct;

@end
#endif
