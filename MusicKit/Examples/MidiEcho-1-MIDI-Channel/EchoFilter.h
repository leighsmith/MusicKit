#import <musickit/musickit.h>
#import <objc/hashtable.h>

@interface EchoFilter : NoteFilter
  /* A simple note filter that does MIDI echo */
{    
    double delay;		    /* delay between echos, in seconds */
    NXHashTable *h;
}
-init;
-setDelay:(double)delayArg;
-realizeNote:aNote fromNoteReceiver:aNoteReceiver;
@end
