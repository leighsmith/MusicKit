/* This class is a NoteFilter that generates echoes and sends them to 
   its successive NoteSenders. In MidiEcho, we connect the NoteSenders to 
   the NoteReceivers of Midi, thus producing MIDI echoes on successive
   MIDI channels. To use this app, you need to have a MIDI synthesizer that
   can receive on multiple channels, such as the Yamaha SY77 or FB01.
 */

#import "EchoFilter.h"

#define NUMCHANS 8  /* My MIDI Synthesizer handles 8 channels. */
  
@implementation EchoFilter : MKNoteFilter
  /* A simple note filter that does MIDI echo */
{
    double delay;		    /* delay between echos, in seconds */
}

-init
  /* Called automatically when an instance is created. */
{    int i;
     
     [super init]; 
     delay = .1;
     for (i=0;i<=NUMCHANS;i++)  /* 1 for each channel plus 'sys' messages */ 
	 [self addNoteSender:[[MKNoteSender alloc] init]];
     [self addNoteReceiver:[[MKNoteReceiver alloc] init]];
     return self;
 }

- (void)setDelay:(double)delayArg
  /* change the amount of delay (in seconds) between echoes */
{
    delay = delayArg; 
}

- (void)connectAcross:anInstOrNoteFilter    
  /* Just connects successive NoteSenders of the receivers to successive
     NoteReceivers of anInstOrNoteFilter. */
{
    NSArray *pList = [self noteSenders];
    NSArray *iList = [anInstOrNoteFilter noteReceivers];
    int i,siz;
    int pSiz = [pList count];
    int iSiz = [iList count];
    siz = (pSiz > iSiz) ? iSiz : pSiz; /* Take min length */
    for (i = 0; i<siz; i++)            /* Connect them up */
      [[pList objectAtIndex:i] connect:[iList objectAtIndex:i]];
}

//#define NOTESENDER(_i) NX_ADDRESS(noteSenders)[_i] /* For quick array access */
#define NOTESENDER(_i) [[self noteSenders] objectAtIndex:_i]  // for usable array access LMS

- (void)realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver
  /* Here's where the work is done. */
{
    /* This relies on the knowledge that the Midi object sorts its incoming 
       notes by channel as well as by noteTag. Thus, duplicating a note with
       a particular noteTag on several channels works ok. In general, this 
       NoteFilter assumes each output (NoteSender) is assigned a unique
       connection (NoteReceiver). */
       
    int i;
    double curDly;
    int velocity,noteType;
    MKNote *newNote;

    noteType = [aNote noteType];
    if (noteType == MK_mute) {
	[NOTESENDER(0) sendNote:aNote];          /* Just forward these */
	return;
    }
    curDly = 0;
    [NOTESENDER(1) sendNote:aNote];              /* Send current note */
    velocity = [aNote parAsInt:MK_velocity];     /* Grab velocity */
    for (i=2;i<=NUMCHANS;i++) {                  /* Make echoes */
	curDly += delay;                         
	newNote = [aNote copy];                  /* Need to copy notes here */
	if (noteType == MK_noteOn)               /* Decrement echo velocity */
	  [newNote setPar:MK_velocity toInt:velocity -= 15];
	                                         /* Schedule it for later */
	[NOTESENDER(i) sendAndFreeNote:newNote withDelay:curDly];
    } 
}

@end

