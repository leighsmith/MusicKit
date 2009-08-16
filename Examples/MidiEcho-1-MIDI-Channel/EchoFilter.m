/* 
 $Id$
 Example Application within the MusicKit

 Description:
   We generate echoes for each note that comes in.  We give
   the echoes a new noteTag. To keep track of which noteTag to give
   noteOffs and polyphonic key pressure, we keep a mapping from the 
   original noteTag to the NSArray of echo noteTags.
   We use the 0'th location in the list to be the original noteTag.
 
   We use a standard hash utility that comes with Objective-C.  It requires
   us to provide a few helper functions.
 */
#import <MusicKit/MusicKit.h>
#import "EchoFilter.h"

@implementation EchoFilter

#define HASHSIZE 16

#if 0
static unsigned myHash(const void *info, const void *data) 
{   
    unsigned *arr = (unsigned *)data;
    return arr[0] % HASHSIZE;
}

static int myIsEqual(const void *info, const void *data1, const void *data2)
{
    int *arr1 = (int *)data1, *arr2 = (int *)data2;            
    return (arr1[0] == arr2[0]);
}
#endif

/* Called automatically when an instance is created. */
- init
{    
    self = [super init];
    if(self != nil) {
	delay = .1;
	[self addNoteSender: [[MKNoteSender alloc] init]];
	[self addNoteReceiver: [[MKNoteReceiver alloc] init]];
	echoingNotes = [[NSMutableDictionary dictionaryWithCapacity: HASHSIZE] retain];	
    }
    return self;
}

/* change the amount of delay (in seconds) between echoes */
- (void) setDelay: (double) delayArg
{
    delay = delayArg;
}

#define BOGUS_TAG MAXINT
#define ECHOS 8

- (NSMutableArray *) addMapping: (int) noteTag
{
    NSNumber *noteTagNumber = [NSNumber numberWithInt: noteTag];
    NSMutableArray *array = [NSMutableArray arrayWithObject: noteTagNumber];
    
    [echoingNotes setObject: array forKey: noteTagNumber];
    return array;
}

- (int) getMapping: (int) noteTag
	      echo: (int) echoNumber
{
    NSArray *array = [echoingNotes objectForKey: [NSNumber numberWithInt: noteTag]];
    if (!array) 
	return BOGUS_TAG;
    else
	return [[array objectAtIndex: echoNumber] intValue];
}

- (void) removeMapping: (int) noteTag
{
    NSNumber *noteTagNumber = [NSNumber numberWithInt: noteTag];
    [echoingNotes removeObjectForKey: noteTagNumber];
}

/* Here's where the work is done. */
- realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver
{
    int echoIndex;
    NSMutableArray *noteTagMap = nil;
    double curDly;
    int velocity, newNoteTag;
    id newNote;
    int noteType = [aNote noteType];
    int noteTag = [aNote noteTag];
    
    if (noteType == MK_mute || noteTag == BOGUS_TAG) { /* Don't echo these */
	[[self noteSender] sendNote: aNote];         			
	return self;
    }
    curDly = 0;
    [[self noteSender] sendNote: aNote];          /* Send the original */     
    if (delay == 0)
	return self;
    velocity = [aNote parAsInt: MK_velocity];     
    if (noteType == MK_noteOn)
	noteTagMap = [self addMapping: noteTag];
    for (echoIndex = 1; echoIndex < ECHOS; echoIndex++) {                  
	curDly += delay;                         
	newNote = [aNote copy];                  
	switch (noteType) {
	    case MK_noteOn:
		newNoteTag = MKNoteTag();
		[newNote setNoteTag: newNoteTag];
		[newNote setPar: MK_velocity toInt: velocity -= 15]; // reduce volume for echoes.
		[noteTagMap insertObject: [NSNumber numberWithInt: newNoteTag] atIndex: echoIndex];
		break;
	    case MK_noteOff:
		newNoteTag = [self getMapping: noteTag echo: echoIndex];
		if (newNoteTag == BOGUS_TAG) /* Bogus noteOff */
		    continue;
		if (echoIndex == ECHOS) /* It's the last one */
		    [self removeMapping: noteTag];
		[newNote setNoteTag: newNoteTag];
		break;
	    case MK_noteUpdate:
		newNoteTag = [self getMapping: noteTag echo: echoIndex];
		if (newNoteTag == BOGUS_TAG) /* Bogus noteOff */
		    continue;
		[newNote setNoteTag: newNoteTag];
		break;
	}
	[[self noteSender] sendAndFreeNote: newNote withDelay: curDly];
    }
    return self;
}


@end

