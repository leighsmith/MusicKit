// $Id$
#import <MusicKit/MusicKit.h>
#import "EchoFilter.h"
  
@implementation EchoFilter

/* We generate echoes for each note that comes in.  We give
   the echoes a new noteTag. To keep track of which noteTag to give
   noteOffs and polyphonic key pressure, we keep a mapping from the 
   original noteTag to the list (array) of echo noteTags.
   We use the 0'th location in the list to be the original noteTag.

   We use a standard hash utility that comes with objective-C.  It requires
   us to provide a few helper functions.
   */

#define HASHSIZE 16

static void noFree(const void *info, void *data) {} 

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

- init
  /* Called automatically when an instance is created. */
{    
     [super init]; 
     delay = .1;
     [self addNoteSender: [[MKNoteSender alloc] init]];
     [self addNoteReceiver: [[MKNoteReceiver alloc] init]];
     echoingNotes = [[NSMutableDictionary dictionaryWithCapacity: HASHSIZE] retain];
     return self;
 }

- (void) setDelay: (double) delayArg
  /* change the amount of delay (in seconds) between echoes */
{
    delay = delayArg;
}

/* Forward declarations */
static int *addMapping(id self, int noteTag);
static int getMapping(id self, int noteTag, int echoNumber);
static void removeMapping(id self, int noteTag);

#define BOGUS_TAG MAXINT
#define ECHOS 8

- realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver
  /* Here's where the work is done. */
{
    int i;
    int *noteTagMap;
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
      noteTagMap = addMapping(self, noteTag);
    for (i = 1; i < ECHOS; i++) {                  
	curDly += delay;                         
	newNote = [aNote copy];                  
	switch (noteType) {
	  case MK_noteOn:
	    [newNote setNoteTag: newNoteTag = MKNoteTag()];
	    [newNote setPar: MK_velocity toInt: velocity -= 15];
	    noteTagMap[i] = newNoteTag;
	    break;
	  case MK_noteOff:
	    newNoteTag = getMapping(self, noteTag, i);
	    if (newNoteTag == BOGUS_TAG) /* Bogus noteOff */
	      continue;
	    if (i == ECHOS) /* It's the last one */
	      removeMapping(self, noteTag);
	    [newNote setNoteTag: newNoteTag];
	    break;
	  case MK_noteUpdate:
	    newNoteTag = getMapping(self, noteTag, i);
	    if (newNoteTag == BOGUS_TAG) /* Bogus noteOff */
	      continue;
	    [newNote setNoteTag: newNoteTag];
	    break;
	  }
	[[self noteSender] sendAndFreeNote: newNote withDelay: curDly];
    }
    return self;
}

static int *addMapping(EchoFilter *self, int noteTag)
{
    NSNumber *noteTagNumber = [NSNumber numberWithInt: noteTag];
    NSArray *array = [NSArray arrayWithObject: noteTagNumber];
    [self->echoingNotes setObject: array forKey: noteTagNumber];
    return array;
}

static int getMapping(EchoFilter *self,int noteTag,int echoNumber)
{
  int *array = [self->echoingNotes objectForKey: (const void *)&noteTag];
  if (!array) 
    return BOGUS_TAG;
  else return array[echoNumber];
}

static void removeMapping(EchoFilter *self,int noteTag)
{
  int *array = [self->echoingNotes objectForKey: (const void *)&noteTag];
  [self->echoingNotes removeObjectForKey: noteTag];
  if (array)
    free((void *)array);
}


@end

