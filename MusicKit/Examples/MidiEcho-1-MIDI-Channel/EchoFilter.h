/*
 $Id$

 Description:
   A simple note filter that does MIDI echo 
 */

#import <MusicKit/MusicKit.h>

@interface EchoFilter : MKNoteFilter
{
    double delay;		  /* delay between echos, in seconds */  
    NSMutableDictionary *echoingNotes;  /* See below */
}

-init;
- (void) setDelay: (double) delayArg;
-realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver;
@end
