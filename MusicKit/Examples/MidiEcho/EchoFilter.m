/* This class is a NoteFilter that generates echoes and sends them to 
   its successive NoteSenders. In MidiEcho, we connect the NoteSenders to 
   the NoteReceivers of Midi, thus producing MIDI echoes on successive
   MIDI channels. To use this app, you need to have a MIDI synthesizer that
   can receive on multiple channels, such as the Yamaha SY77 or FB01.
 */

#import "EchoFilter.h"

#define NUMCHANS 8  /* My MIDI Synthesizer handles 8 channels. */
  
@implementation EchoFilter : MKNoteFilter

/* Called automatically when an instance is created. */
- init
{
    self = [super init];
    if(self != nil) {
	int i;

	delay = .1;
	for (i = 0; i <= NUMCHANS; i++)  /* 1 for each channel plus 'sys' messages */ 
	    [self addNoteSender: [[MKNoteSender alloc] init]];
	[self addNoteReceiver: [[MKNoteReceiver alloc] init]];
    }
    return self;	
}

/* change the amount of delay (in seconds) between echoes */
- (void) setDelay: (double) delayArg
{
    delay = delayArg; 
}

/* Just connects successive MKNoteSenders of the receivers to successive MKNoteReceivers of anInstOrNoteFilter. */
- (void) connectAcross: anInstOrNoteFilter    
{
    NSArray *noteSendersList = [self noteSenders];
    NSArray *noteReceiversList = [anInstOrNoteFilter noteReceivers];
    int i, siz;
    int pSiz = [noteSendersList count];
    int iSiz = [noteReceiversList count];
    
    siz = (pSiz > iSiz) ? iSiz : pSiz; /* Take min length */
    for (i = 0; i < siz; i++) {        /* Connect them up */
	MKNoteSender *noteSender = [noteSendersList objectAtIndex: i];
	MKNoteReceiver *noteReceiver = [noteReceiversList objectAtIndex: i];
	[noteSender connect: noteReceiver];
    } 
}

/* Here's where the work is done. */
- (void) realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver
{
    /* This relies on the knowledge that the Midi object sorts its incoming 
    notes by channel as well as by noteTag. Thus, duplicating a note with
    a particular noteTag on several channels works ok. In general, this 
    MKNoteFilter assumes each output (MKNoteSender) is assigned a unique
    connection (MKNoteReceiver). */
    
    int i;
    double curDly;
    int velocity,noteType;
    MKNote *newNote;
    
    noteType = [aNote noteType];
    if (noteType == MK_mute) {
	[[[self noteSenders] objectAtIndex: 0] sendNote: aNote];          /* Just forward these */
	return;
    }
    curDly = 0;
    [[[self noteSenders] objectAtIndex: 1] sendNote: aNote];              /* Send current note */
    velocity = [aNote parAsInt: MK_velocity];     /* Grab velocity */
    for (i = 2; i <= NUMCHANS; i++) {                  /* Make echoes */
	curDly += delay;                         
	newNote = [aNote copy];                  /* Need to copy notes here */
	if (noteType == MK_noteOn)               /* Decrement echo velocity */
	    [newNote setPar: MK_velocity toInt: velocity -= 15];
	/* Schedule it for later */
	[[[self noteSenders] objectAtIndex: i] sendAndFreeNote: newNote withDelay: curDly];
    } 
}

@end

