#import <MusicKit/MusicKit.h>

@interface EchoFilter : MKNoteFilter
  /* A simple note filter that does MIDI echo */
{    
    double delay;		    /* delay between echos, in seconds */
}
-init;
- (void)setDelay:(double)delayArg;
- (void)connectAcross:anInstOrNoteFilter;
- (void)realizeNote:aNote fromNoteReceiver:aNoteReceiver;
@end
