/* SoundPlayer.h created by skot on Sat 10-Feb-2001 */

#import <Foundation/Foundation.h>
#import "SndKit.h"
#import "SndStreamClient.h"
#import "SndPerformance.h"

@interface SndPlayer : SndStreamClient
{
    NSMutableArray *toBePlayed;
    NSMutableArray *playing;
}

+ player;

- (SndPerformance *) playSnd: (Snd*) s;
- (SndPerformance *) playSnd: (Snd*) s withTimeOffset: (double) inSeconds;
- stopSnd: (Snd*) s withTimeOffset: (double) inSeconds;
- (void) processBuffers;

- init;
- (void) dealloc;
- (NSString*) description;
// Return an array of the performances of a given sound.
- (NSArray *) performancesOfSnd: (Snd *) snd;

@end
