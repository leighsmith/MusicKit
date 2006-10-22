#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>

@interface SoundInfo: NSObject
{
    id	siSize;
    id	siFrames;
    id	siFormat;
    id	siTime;
    id	siRate;
    id	siPanel;
    id	siChannels;
    int ssize;
    Snd *sndhdr;
}

- init;
- displaySound: (Snd *) sound title: (NSString *) title;
- setSoundHeader: (Snd *) sound;
- (void) display: (NSString *) title;
- (BOOL) windowShouldClose: (id) sender;

- setSiPanel: anObject;
- setSiSize: anObject;
- setSiFrames: anObject;
- setSiFormat: anObject;
- setSiTime: anObject;
- setSiRate: anObject;
- setSiChannels: anObject;

@end
