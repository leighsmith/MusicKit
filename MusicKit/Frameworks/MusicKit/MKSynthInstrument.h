/*
  $Id$
  Defined In: The MusicKit

  Description:
    A MKSynthInstrument realizes MKNotes by synthesizing them on the DSP.  It
    does this by forwarding each MKNote it receives to a MKSynthPatch object,
    which translates the parameter information in the MKNote into DSP
    instructions.  A MKSynthInstrument can manage any number of MKSynthPatch
    objects (limited by the speed and size of the DSP).  However, all of
    its MKSynthPatches are instances of the same MKSynthPatch subclass.  You
    assign a particular MKSynthPatch subclass to a MKSynthInstrument through
    the latter's setSynthPatchClass: method.  A MKSynthInstrument can't
    change its MKSynthPatch class during a performance.

    Each MKSynthPatch managed by the MKSynthInstrument corresponds to a
    particular noteTag.  As the MKSynthInstrument receives MKNotes, it
    compares the MKNote's noteTag to the noteTags of the MKSynthPatches that
    it's managing.  If a MKSynthPatch already exists for the noteTag, the
    MKNote is forwarded to that object; otherwise, the MKSynthInstrument
    either asks the MKOrchestra to allocate another MKSynthPatch, or it
    preempts an allocated MKSynthPatch to accommodate the MKNote.  Which
    action it takes depends on the MKSynthInstrument's allocation mode and
    the available DSP resources.

    A MKSynthInstrument can either be in automatic allocation mode
    (MK_AUTOALLOC) or manual mode (MK_MANUALALLOC).  In automatic mode,
    MKSynthPatches are allocated directly from the MKOrchestra as MKNotes are
    received by the MKSynthInstrument and released when it's no longer
    needed.  Automatic allocation is the default.

    In manual mode, the MKSynthInstrument pre-allocates a fixed number of
    MKSynthPatch objects through the setSynthPatchCount: method.  If it
    receives more simultaneously sounding MKNotes than it has MKSynthPatches,
    the MKSynthInstrument preempt its oldest running MKSynthPatch (by sending
    it the preemptFor: message).

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University  
*/
/*
 Modification history:

  $Log$
  Revision 1.7  2000/07/22 00:33:37  leigh
  Minor doco and typing cleanups.

  Revision 1.6  2000/05/27 19:12:56  leigh
  Converted taggedPatches and controllerTable to NSMutableDictionary from HashTable

  Revision 1.5  2000/05/24 03:46:23  leigh
  Removed use of Storage, replacing with SynthPatchList object

  Revision 1.4  1999/09/10 02:47:03  leigh
  Comments update

  Revision 1.3  1999/07/29 01:43:30  leigh
  Added CVS logs

*/
#ifndef __MK_SynthInstrument_H___
#define __MK_SynthInstrument_H___

#define MK_AUTOALLOC 0
#define MK_MANUALALLOC 1
#define MK_MIXEDALLOC 2

#import "MKInstrument.h"
#import "MKNote.h"

@interface MKSynthInstrument : MKInstrument
{
    id synthPatchClass;                   /* class used to create patches. */
    unsigned short allocMode;             /* One of MK_MANUALALLOC, MK_AUTOALLOC, or MK_MIXEDALLOC. */
    NSMutableDictionary *taggedPatches;   /* Dictionary mapping noteTags to MKSynthPatches */
    NSMutableDictionary *controllerTable; /* Dictionary mapping MIDI controllers to values */
    MKNote *updates;                      /* MKNote for storing common (no noteTag) updates. */
    BOOL retainUpdates;                   /* NO if updates and controllerTable are cleared after each performance. */
    MKOrchestra *orchestra;               /* MKOrchestra to allocate MKSynthPatches from */

    /* The following for internal use only */
    NSMutableArray *_patchLists;
}
 
- init;
 /* 
 * Initializes the receiver.  You never invoke this method directly.
 * An overriding subclass method 
 * should send [super init] before setting its own defaults. 
 */

-(int)setSynthPatchCount:(int)voices patchTemplate:aTemplate;
 /* 
 * Immediately allocates voices SynthPatch objects using the 
 * patch template aTemplate (the
 * Orchestra must be open) and puts the receiver in manual mode.  
 * If aTemplate is nil, the value returned by the message
 * 
 * [synthPatchClass defaultPatchTemplate] 
 *
 * is used.  Returns the number of objects that were allocated (it may be less
 * than the number requested).
 * If the receiver is in performance and it isn't already in manual
 * mode, this message is ignored and 0 is returned.
 *
 * If you decrease the number of manually allocated
 * SynthPatches during a performance, the extra SynthPatches aren't 
 * deallocated until they become inactive.  In other words, reallocating
 * downward won't interrupt notes that are already sounding.
 */

-(int)setSynthPatchCount:(int)voices;
 /* 
 * Immediately allocates voices SynthPatch objects.
 * Implemented as
 *
 * [self setSynthPatchCount:voices template:nil];
 *
 * Returns the number of objects that were allocated.
 */
-(int)synthPatchCountForPatchTemplate:aTemplate;
-(int)synthPatchCount;

- realizeNote:aNote fromNoteReceiver:aNoteReceiver;
 /* 
 * Synthesizes aNote.
 */
   
- synthPatchClass;
 /* 
 * Returns the receiver's SynthPatch class.
 */

- setSynthPatchClass:aSynthPatchClass; 
 /* 
 * Sets the receiver's SynthPatch class to aSynthPatchClass.
 * Returns nil if the argument isn't a subclass of SynthPatch or 
 * the receiver is in a performance (the class isn't set in this case).  
 * Otherwise returns the receiver.
 */ 
   
- setSynthPatchClass:aSynthPatchClass orchestra:anOrch; 
 /* 
   It is like setSynthPatchClass: but also specifies that 
   SynthPatch instances are to be allocated using the object anOrch. This is 
   only used when you want a particular orchestra instance to be used rather
   than allocating from the Orchestra class. If anOrch is nil, the orchestra 
   used is the value returned by [aSynthPatchClass orchestraClass]. */

- orchestra;
/* Returns the value set with setSynthPatchClass:orchestra:, if any.
   Otherwise returns [Orchestra class].
  */

//- (void)dealloc; // LMS redundant after SB's changes
 /* 
 * If the receiver isn't in performance, this frees the receiver 
 * (returns nil).  Otherwise does nothing and returns
 * the receiver.
 */

-preemptSynthPatchFor:aNote patches:firstPatch;
/* 
You never invoke this method.  It's invoked automatically when the receiver is
in manual mode and all SynthPatches are in use, or when it's in auto mode and
the DSP resources to build another SynthPatch aren't available.  The return
value is taken as the SynthPatch to preempt in order to accommodate the latest
request.  firstPatch is the first in a sequence of ordered
active SynthPatches, as returned by the activeSynthPatches: method.  The
default implementation simply returns firstPatch, the SynthPatch with the
oldest phrase.  A subclass can reimplement this method to provide a different
scheme for determining which SynthPatch to preempt.  
*/

-activeSynthPatches:aTemplate;
 /* 
Returns the first in the sequence of aTemplate SynthPatches that are
currently sounding.  The sequence is ordered by the begin times of the
SynthPatches' current phrases, from the earliest to the latest. In addition,
all finishing SynthPatches are before all running SynthPatches. You step down
the sequence by sending next to the objects returned by this method.  If
aTemplate is nil, returns the default PatchTemplate.  If there
aren't any active SynthPatches with the specified template, returns nil.
  */

-mute:aMute;
 /* 
You never invoke this method; it's invoked automatically when the receiver
receives a mute Note.  Mutes aren't normally forwarded to SynthPatches since
they usually don't produce sound.  The default implementation does nothing.
A subclass can implement this method to examine aMute and act
accordingly.

  */

-autoAlloc;
 /* 
Sets the receiver's allocation mode to MK_AUTOALLOC and releases any manually
allocated SynthPatch objects.  If the receiver is in performance and isn't
already in MK_AUTOALLOC mode, this does nothing and returns nil.
Otherwise returns the receiver.  
  */

-(unsigned short)allocMode;
 /* 
Returns the recevier's allocation mode, one of MK_AUTOALLOC or MK_MANUALALLOC.
  */

-abort;
  /* Sends the noteEnd message to all running (or finishing) synthPatches 
     managed by this SynthInstrument. This is used only for aborting in 
     emergencies. */

- copyWithZone:(NSZone *)zone;
  /* Returns a copy of the receiver. The copy has the same connections but
     has no synth patches allocated. */

-clearUpdates;
/* Causes the SynthInstrument to clear any noteUpdate state it has accumulated
   as a result of receiving noteUpdates without noteTags.
   The effect is not felt by the SynthPatches until the next phrase. Also
   clears controller info.
 */

-setRetainUpdates:(BOOL)yesOrNo;
/* Controls whether the noteUpdate and controller state is retained from
   performance to performance. Default is NO.
  */
-(BOOL)doesRetainUpdates;
/* Returns whether the noteUpdate and controller state is retained from
   performance to performance. */

-getUpdates:(MKNote **)aNoteUpdate controllerValues:(NSMutableDictionary **) controllers;
/* Returns by reference the MKNote used to store the accumulated 
   noteUpdate state. Also returns by reference the NSDictionary used to 
   store the state of the controllers. Any alterations to the returned
   objects will effect future phrases. The returned objects should be 
   used only immediately after they are returned. If clearUpdates is
   sent or the performance ends, the objects may be emptied or freed by the 
   MKSynthInstrument.  */

- (void)encodeWithCoder:(NSCoder *)aCoder;
  /* 
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Invokes superclass write: method. Also archives allocMode, retainUpdates 
     and, if retainUpdates is YES, the controllerTable and updates. */
- (id)initWithCoder:(NSCoder *)aDecoder;
  /* 
     You never send this message directly.  
     Should be invoked via NXReadObject(). 
     Note that -init is not sent to newly unarchived objects.
     See write:. */
//- awake;
  /* Makes unarchived object ready for use. 
   */

-allNotesOff;

@end



#endif
