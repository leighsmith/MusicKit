/* Based on Ensemble MidiFilter */

/* Important note:

     This module assumes that a noteupdate has one and only one controller, 
     aftertouch, or pitchbend parameter set and never a combination.  
     This is the case for input direct from MIDI, but not necessarily the case 
     for arbitrary Notes from an application or scorefile.
*/


#import <mididriver/midi_spec.h>
#import <musickit/Note.h>
#import <musickit/NoteSender.h>
#import <musickit/params.h>
#import <libc.h>
#import "MidiFilter.h"

extern double MKGetTime(void);

@implementation MidiFilter
  /* A simple note filter that thins or blocks pitchbend, aftertouch,
     controller, and program change updates. */
    
    -reset
{
    register int i;
    /* Thin continuous controllers by default */
    for (i=0; i<67; i++) {
	lastVals[i] = 0;
	minVals[i] = 2;    /* Controls how severe is the thining by value */
	lastTimes[i] = -1000.0;
	minTimes[i] = .03; /* Controls how severe is the thining by time */
	action[i] = THIN;
    }
    /* Pass discrete controllers by default */
    for (i=68; i<131; i++) {
	lastVals[i] = 0;
	minVals[i] = 0;
	lastTimes[i] = -1000.0;
	minTimes[i] = 0.0;
	action[i] = PASS;
    }
    minVals[MIDI_BALANCE] = 3;
    minVals[128] = 2048; /* pitch bend */
    minTimes[128] = .3;
    action[128] = THIN;  /* Set to STOP to block all pitch bend. */
    minVals[129] = 2;    /* aftertouch */
    minTimes[129] = .03;
    action[129] = THIN;
    return self;
}

-init
    /* Sent when an instance is created. */
{    
    [super init];
    noteReceiver = [self addNoteReceiver:[[NoteReceiver alloc] init]];
    noteSender = [self addNoteSender:[[NoteSender alloc] init]];
    [self reset];
    return self;
}

-realizeNote:aNote fromNoteReceiver:aNoteReceiver
    /* Here's where the work is done.
     */
{
    if (MKIsNoteParPresent(aNote,MK_sysRealTime)) {
	switch (MKGetNoteParAsInt(aNote,MK_sysRealTime)) {
	  case MK_sysReset: [self reset]; break;
	}
    }
    if ([aNote noteType] != MK_noteUpdate)
	[noteSender sendNote:aNote];
    else {
	static actionType act;
	static int control, value;
	if (MKIsNoteParPresent(aNote,MK_pitchBend)) {
	    act = action[control=128];
	    if (act==STOP) return self;
	    else if (act==THIN) {
		value = MKGetNoteParAsInt(aNote,MK_pitchBend);
		if ((value==0) || (value==8192) || (value==16383)) act = PASS;
	    }
	}
	else if (MKIsNoteParPresent(aNote,MK_afterTouch)) {
	    act = action[control=129];
	    if (act==STOP) return self;
	    else if (act==THIN) {
		value = MKGetNoteParAsInt(aNote,MK_afterTouch);
		if ((value==0) || (value==127)) act = PASS;
	    }
	}
	else if (MKIsNoteParPresent(aNote,MK_programChange)) {
	    act = action[control=130];
	    if (act==STOP) return self;
	    else if (act==THIN)
		value = MKGetNoteParAsInt(aNote,MK_programChange);
	}
	else if (MKIsNoteParPresent(aNote,MK_controlChange)) {
	    act = action[control=MKGetNoteParAsInt(aNote,MK_controlChange)];
	    if (act==STOP) return self;
	    else if (act==THIN) {
		value = MKGetNoteParAsInt(aNote,MK_controlVal);
		if ((value==0) || (value==127)) act = PASS;
	    }
	}
	if (act==THIN) {
	    double time = MKGetTime();
	    if ((abs(value-lastVals[control])<minVals[control]) &&
		((time-lastTimes[control])<minTimes[control]))
		return self;
	    lastVals[control] = value;
	    lastTimes[control] = time;
	}
	[noteSender sendNote:aNote];
    }
    return self;
}

@end
    
