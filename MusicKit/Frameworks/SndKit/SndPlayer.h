/* SoundPlayer.h created by skot on Sat 10-Feb-2001 */

#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>
#import <SndKit/SndStreamClient.h>

@interface SndPlayerData : NSObject
{
    Snd* snd;
    double playTime;
    long playIndex;
}

+ soundPlayerDataWithSnd: (Snd*) s playTime: (double) y;
- snd;
- (double) playTime;

- (void) dealloc;
- (long) playIndex;
- (void) setPlayIndex: (long) li;

@end

@interface SndPlayer : SndStreamClient
{
    NSMutableArray *toBePlayed;
    NSMutableArray *playing;
}

+ player;

- playSnd: (Snd*) s;
- playSnd: (Snd*) s withTimeOffset: (double) inSeconds;
- stopSnd: (Snd*) s withTimeOffset: (double) inSeconds;
- (void) processBuffers;

- init;
- (void) dealloc;
- (NSString*) description;

@end
