#import "SoundRecorder.h"
#import <soundkit/soundkit.h>
#import <math.h>
#import <string.h>
#import <sound/mulaw.h>

static id recordDevice = nil;

@implementation SoundRecorder:Object
{}

- init
{
	[super init];
	dataSize = 64 * vm_page_size;
	data = NXZoneMalloc([self zone], dataSize);
	if (!recordDevice)
		recordDevice = [[NXSoundIn allocFromZone:[self zone]] init];
	recordStream = [[NXRecordStream allocFromZone:[self zone]] 
		initOnDevice:recordDevice];
	[recordStream setDelegate:self];
	[self setSquelch:-30.0];
	return self;
}

- setSquelch:(int)dB
{
	squelch = 32767.0 * pow(10.0, dB/20.0);
	return self;
}

- startRecording
{
	dataPtr = data;
	[recordStream activate];
	[recordStream recordSize:1024 tag:0];
	[recordStream recordSize:1024 tag:0];
	[recordStream recordSize:1024 tag:0];
	[recordStream recordSize:1024 tag:0];
	return self;
}

- stopRecording
{
	[recordStream deactivate];
	return self;
}

- (BOOL)isActive
{
	return [recordStream isActive];
}

- (SNDSoundStruct *)soundStruct
{
	SNDSoundStruct *new;
	SNDAlloc(&new, dataPtr-data, SND_FORMAT_MULAW_8, SND_RATE_CODEC, 1, 4);
	bcopy(data, (char *)new+new->dataLocation, dataPtr-data);
	return new;
}
	
extern void _MKLock(void);
extern void _MKUnlock(void);

- soundStream:sender didRecordData:(void *)dataBuf 
	size:(unsigned int)numBytes forBuffer:(int)tag
{
	register unsigned char *dp; 
	register unsigned char *end; 
	_MKLock();
	dp = (unsigned char *)dataBuf;
	end = dp + numBytes;
	while (dp < end)
		if (muLaw[*dp++] > squelch) {
			bcopy(dataBuf, dataPtr, numBytes);
			dataPtr += numBytes;
			break;
		}
	[recordStream recordSize:1024 tag:0];
	_MKUnlock();
	return self;
}

@end
