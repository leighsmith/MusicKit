#import <Foundation/NSObject.h>

#import <SndKit/Snd.h>

@interface SoundInfo:NSObject
{
    id	siSize;
    id	siFrames;
    id	siFormat;
    id	siTime;
    id	siRate;
    id	siPanel;
    id	siChannels;
	int ssize;
	SndSoundStruct *sndhdr;
}

- init;
- displaySound:sound title:(NSString *)title;
- setSoundHeader:sound;
- (int)getSrate;
- (int)getChannelCount;
- (NSString *)getSoundFormat;
- (void)display:(NSString *)title;
- setSiPanel:anObject;
- setSiSize:anObject;
- setSiFrames:anObject;
- setSiFormat:anObject;
- setSiTime:anObject;
- setSiRate:anObject;
- setSiChannels:anObject;
- (BOOL)windowShouldClose:(id)sender;

@end
