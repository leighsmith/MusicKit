/*
  $Id$
  Defined In: The MusicKit

  Description:
    An MKSynthInstrument realizes MKNotes by synthesizing them on the DSP.  It
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
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
 Modification history:

  $Log$
  Revision 1.10  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.9  2001/05/14 17:26:51  leighsmith
  Correctly typed orchestra to respond to _MKClassOrchestra()

  Revision 1.8  2000/11/25 23:05:09  leigh
  Enforced ivar privacy

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
/*!
  @class MKSynthInstrument
  @discussion

A MKSynthInstrument realizes MKNotes by synthesizing them on the DSP.  It does this
by forwarding each MKNote it receives to a MKSynthPatch object, which translates the
parameter information in the MKNote into DSP instructions.  A MKSynthInstrument can
manage any number of MKSynthPatch objects (limited by the speed and size of the
DSP).  However, all of its MKSynthPatches are instances of the same MKSynthPatch
subclass.  You assign a particular MKSynthPatch subclass to a MKSynthInstrument
through the latter's <b>setSynthPatchClass:</b> method.  A MKSynthInstrument can
change its MKSynthPatch at any time, even during a performance.

Each MKSynthPatch managed by the MKSynthInstrument corresponds to a particular
noteTag.  As the MKSynthInstrument receives MKNotes, it compares the Note's noteTag
to the noteTags of the MKSynthPatches that it's managing.  If a MKSynthPatch already
exists for the noteTag, the MKNote is forwarded to that object; otherwise, the
MKSynthInstrument either asks the MKOrchestra to allocate another MKSynthPatch, or it
preempts an allocated MKSynthPatch to accommodate the MKNote.  Which action it takes
depends on the SynthInstrument's allocation mode and the available DSP
resources.

A MKSynthInstrument can either be in automatic allocation mode (MK_AUTOALLOC) or
manual mode (MK_MANUALALLOC).  In automatic mode, MKSynthPatches are allocated
directly from the MKOrchestra as MKNotes are received by the MKSynthInstrument and
released when it's no longer needed.  Automatic allocation is the
default.

In manual mode, the MKSynthInstrument pre-allocates a fixed number of MKSynthPatch
objects through the <b>setSynthPatchCount:</b> method.  If it receives more
simultaneously sounding MKNotes than it has MKSynthPatches, the MKSynthInstrument
preempt its oldest running MKSynthPatch (by sending it the <b>preemptFor:</b>
message).

The MKSynthInstrument has a "noteUpdate state", a MKNote object containing the most
recent parameter values that the MKSynthInstrument has received from  noteUpdates
without noteTags.  For example, the current value of MIDI pitch bend would be
stored there.  Additionally, the MKSynthInstrument has a "controllerTable."   This
is used to map MIDI controller numbers to the most recent controller values that
the MKSynthInstrument has received from noteUpdates without noteTags.   This
information cannot be stored in the noteUpdate state because the noteUpdate
state has room for only one controller/value pair.

By default, the update state is cleared after each performance.  However, you
can request that it be retained with the <b>setRetainUpdates:</b> method.    
You can examine the updates and controllerTable with the method
<b>getUpdates:controllerValues:</b>. 
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
    Class orchestra;               	  /* MKOrchestra class to allocate MKSynthPatches from */

@private
    NSMutableArray *_patchLists;
}
 

/*!
  @method init
  @result Returns an id.
  @discussion Initializes the receiver.  You invoke this method when you careate a
              new instance MKSynthInstrument  An overriding subclass method should
              send <b>[super init]</b> before setting its own defaults.
*/
- init;

/*!
  @method setSynthPatchCount:patchTemplate:
  @param  voices is an int.
  @param  aTemplate is an id.
  @result Returns an int.
  @discussion Immediately allocates <i>voices</i> MKSynthPatch objects using the
              patch template <i>aTemplate</i> (the MKOrchestra must be open) and
              puts the receiver in manual mode.  If <i>aTemplate</i> is
              <b>nil</b>, the value returned by the message
              
              <tt>[synthPatchClass defaultPatchTemplate]</tt>
              
              is used.  Returns the number of objects that were allocated (it may be less than the number requested).  
              If you decrease the number of manually allocated MKSynthPatches during a performance, 
              the extra MKSynthPatches aren't deallocated until they become inactive.  In other words,
              reallocating downward won't interrupt notes that are already sounding.
*/
-(int)setSynthPatchCount:(int)voices patchTemplate:aTemplate;

/*!
  @method setSynthPatchCount:
  @param  voices is an int.
  @result Returns an int.
  @discussion Immediately allocates <i>voices</i> MKSynthPatch objects.  Implemented
              as:
              
              <tt>[self setSynthPatchCount:voices template:nil];</tt>
              
              Returns the number of objects that were allocated.
*/
-(int)setSynthPatchCount:(int)voices;

/*!
  @method synthPatchCountForPatchTemplate:
  @param  aTemplate is an id.
  @result Returns an int.
  @discussion Returns the number of allocated MKSynthPatch objects created with the
              MKPatchTemplate <i>aTemplate</i>.
*/
-(int)synthPatchCountForPatchTemplate:aTemplate;

/*!
  @method synthPatchCount
  @result Returns an int.
  @discussion Returns the number of allocated MKSynthPatch objects created with the
              default MKPatchTemplate.
*/
-(int)synthPatchCount;

/*!
  @method realizeNote:fromNoteReceiver:
  @param  aNote is an id.
  @param  aNoteReceiver is an id.
  @result Returns an id.
  @discussion Synthesizes <i>aNote</i>.
*/
- realizeNote:aNote fromNoteReceiver:aNoteReceiver;   

/*!
  @method synthPatchClass
  @result Returns an id.
  @discussion Returns the receiver's MKSynthPatch class.
*/
- synthPatchClass;

/*!
  @method setSynthPatchClass:
  @param  aSynthPatchClass is an id.
  @result Returns an id.
  @discussion Sets the receiver's MKSynthPatch class to <i>aSynthPatchClass</i>. 
              Returns <b>nil</b> if the argument isn't a subclass of MKSynthPatch or 
              the receiver is in a performance (the class isn't set in this case).
              Otherwise returns the receiver.
*/
- setSynthPatchClass:aSynthPatchClass; 
   
/*!
  @method setSynthPatchClass:orchestra:
  @param  aSynthPatchClass is an id.
  @param  anOrch is an MKOrchestra.
  @result Returns an id.
  @discussion Like <i>setSynthPatchClass:</i> but also specifies that 
              MKSynthPatch instances are to be allocated using the object anOrch. This is 
              only used when you want a particular orchestra instance to be used rather
              than allocating from the MKOrchestra class. If anOrch is nil, the orchestra 
              used is the value returned by [aSynthPatchClass orchestraClass].
*/
- setSynthPatchClass:aSynthPatchClass orchestra:anOrch; 

/*!
  @method orchestra
  @result Returns a Class.
  @discussion Returns the value set with <i>setSynthPatchClass:orchestra:</i>, if any.
              Otherwise returns [MKOrchestra class].
*/
- (Class) orchestra;

/*!
  @method preemptSynthPatchFor:patches:
  @param  aNote is an id.
  @param  firstPatch is an id.
  @result Returns an id.
  @discussion You never invoke this method.  It's invoked automatically when the
              receiver is in manual mode and all MKSynthPatches are in use, or when
              it's in auto mode and the DSP resources needed to build another
              MKSynthPatch aren't available.  The return value is taken as the
              MKSynthPatch to preempt in order to accommodate the latest request. 
              <i>firstPatch</i> is the first in a sequence of ordered active
              MKSynthPatches, as returned by the <b>activeSynthPatches:</b> method. 
              The default implementation simply returns <i>firstPatch</i>, the
              MKSynthPatch with the oldest phrase.  A subclass can reimplement this
              method to provide a different scheme for determining which
              MKSynthPatch to preempt.
*/
-preemptSynthPatchFor:aNote patches:firstPatch;

/*!
  @method activeSynthPatches:
  @param  aTemplate is an id.
  @result Returns an id.
  @discussion Returns the first in the sequence of MKSynthPatches with MKPatchTemplate
              <i>aTemplate</i> that are currently sounding. The sequence is
              ordered by the begin times of the MKSynthPatches' current phrases,
              from the earliest to the latest. In addition, all finishing
              MKSynthPatches are returned before all running MKSynthPatches.
              You step down the sequence by sending <b>next</b> to the objects
              returned by this method.  If <i>aTemplate</i> is <b>nil</b>, the
              default MKPatchTemplate is used. 
              If there aren't any active MKSynthPatches with the specified template,
              <b>nil</b> is returned.
*/
-activeSynthPatches:aTemplate;
 
/*!
  @method mute:
  @param  aMute is an id.
  @result Returns an id.
  @discussion You never invoke this method; it's invoked automatically when the
              receiver receives a mute MKNote.  Mutes aren't normally forwarded to
              MKSynthPatches since they usually don't produce sound.  The default
              implementation does nothing.  A subclass can implement this method
              to examine <i>aMute</i> and act accordingly.
*/
-mute:aMute;

/*!
  @method autoAlloc
  @result Returns an id.
  @discussion Sets the receiver's allocation mode to MK_AUTOALLOC and releases any
              manually allocated MKSynthPatch objects.  If the receiver is in
              performance and isn't already in MK_AUTOALLOC mode, this does
              nothing and returns nil. Otherwise returns the receiver.
*/
-autoAlloc;

/*!
  @method allocMode
  @result Returns an unsigned short.
  @discussion Returns the receiver's allocation mode, one of MK_AUTOALLOC or
              MK_MANUALALLOC.
*/
-(unsigned short)allocMode;

/*!
  @method abort
  @result Returns an id.
  @discussion Sends the <b>noteEnd</b> message to all running (or finishing)
              MKSynthPatches managed by the receivers MKSynthInstrument.
              You should only invoke this method when all other attempts to halt synthesis
              fails.
*/
-abort;

/*!
  @method copyWithZone:
  @param  zone is a NSZone.
  @result Returns an id.
  @discussion Creates and returns a new MKSynthInstrument as a copy of the receiver.
              The copy has the same (MKNoteReceiver) connections but has no
              MKSynthPatches allocated.
*/
- copyWithZone:(NSZone *)zone;

/*!
  @method clearUpdates
  @result Returns an id.
  @discussion Causes the MKSynthInstrument to clear any noteUpdate state it has
              accumulated as a result of receiving noteUpdates without noteTags. 
              The effect is not felt by the MKSynthPatches until the next phrase.
              Also clears controller info.
*/
-clearUpdates;

/*!
  @method setRetainUpdates:
  @param  yesOrNo is a BOOL.
  @result Returns an id.
  @discussion Controls whether the noteUpdate and controller state is retained
              from performance to performance. Default is NO.
*/
-setRetainUpdates:(BOOL)yesOrNo;

/*!
  @method doesRetainUpdates
  @result Returns a BOOL.
  @discussion Returns whether the noteUpdate and controller state is retained from
              performance to performance. 
*/
-(BOOL)doesRetainUpdates;

/*!
  @method getUpdates:controllerValues:
  @param  aNoteUpdate is a MKNote **.
  @param  controllers is a NSMutableDictionary **.
  @result Returns an id.
  @discussion Returns by reference the MKNote used to store the accumulated
              noteUpdate state.  Also returns by reference the NSMutableDictionary used to
              store the state of the controllers. Any alterations to the returned
              objects will effect future phrases.  The returned objects should be
              used only immediately after they are returned, as they may later be
              freed by the MKSynthInstrument. If clearUpdates is sent or the
              performance ends, the objects may be emptied or freed by the MKSynthInstrument.
*/
-getUpdates:(MKNote **)aNoteUpdate controllerValues:(NSMutableDictionary **) controllers;

  /* 
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Invokes superclass write: method. Also archives allocMode, retainUpdates 
     and, if retainUpdates is YES, the controllerTable and updates.
*/
- (void)encodeWithCoder:(NSCoder *)aCoder;
  /* 
     You never send this message directly.  
     Should be invoked via NXReadObject(). 
     Note that -init is not sent to newly unarchived objects.
     See write:. 
*/
- (id)initWithCoder:(NSCoder *)aDecoder;

/*!
  @method allNotesOff
  @result Returns an id.
  @discussion Sends a<b> noteOff:</b> message to all running MKSynthPatches managed
              by this MKSynthInstrument.
*/
-allNotesOff;

@end

#endif
