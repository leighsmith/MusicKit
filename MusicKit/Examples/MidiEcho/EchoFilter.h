#import <MusicKit/MusicKit.h>

/*!
  @class EchoFilter
  @description A simple note filter that does MIDI echo
 */
@interface EchoFilter : MKNoteFilter
{    
    double delay;		    /* delay between echos, in seconds */
}

- init;
- (void) setDelay: (double) delayArg;
- (void) connectAcross: anInstOrNoteFilter;
- (void) realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver;

@end
