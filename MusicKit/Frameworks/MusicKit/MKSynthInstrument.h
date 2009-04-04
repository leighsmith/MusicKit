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
/*!
  @class MKSynthInstrument
  @brief An MKSynthInstrument realizes MKNotes by synthesizing them on the DSP.
 
It does this by forwarding each MKNote it receives to a MKSynthPatch object, which
translates the parameter information in the MKNote into DSP instructions.
A MKSynthInstrument can manage any number of MKSynthPatch objects (limited by the
speed and size of the DSP).  However, all of its MKSynthPatches are instances of the
same MKSynthPatch subclass.  You assign a particular MKSynthPatch subclass to a
MKSynthInstrument through the latter's <b>setSynthPatchClass:</b> method.
A MKSynthInstrument can change its MKSynthPatch at any time, even during a performance.

Each MKSynthPatch managed by the MKSynthInstrument corresponds to a particular
noteTag.  As the MKSynthInstrument receives MKNotes, it compares the MKNote's noteTag
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
the MKSynthInstrument has received from noteUpdates without noteTags.  This
information cannot be stored in the noteUpdate state because the noteUpdate
state has room for only one controller/value pair.

By default, the update state is cleared after each performance.  However, you
can request that it be retained with the <b>setRetainUpdates:</b> method.  
You can examine the updates and controllerTable with the method
<b>getUpdates:controllerValues:</b>. 
*/
#ifndef __MK_SynthInstrument_H___
#define __MK_SynthInstrument_H___

/*!
  @defgroup SynthInstrumentAllocConsts MKSynthInstrument Allocation Constants
  @brief MKSynthInstrument Allocation Constants.

  The steps performed by MKSynthInstrument for each of the allocation
  modes are given below:
 
 MANUAL:
 <ul>
 <li>1m. Look for idle patch of correct template.</li>
 <li>2m. Else try and preempt patch of correct template.</li>
 <li>3m. Else look for idle patch of incorrect template.</li>
 <li>4m. Else try and preempt patch of incorrect template.</li>
 <li>5m. Else give up.</li>
 </ul>
 
 AUTO:
 <ul>
 <li>1a. Try to alloc a new patch of correct template.</li>
 <li>2a. Else try and preempt patch of correct template.</li>
 <li>3a. Else try and preempt patch of incorrect template.</li>
 <li>4a. Else give up.</li>
 </ul>
 
 MIXED
 Same as MANUAL, except for the insertion of step 1m+ after 1m:
 <ul>
 <li>1m+. Try to alloc a new patch of correct template.</li>
 </ul>
 */

/*@{*/

/*! Automatic allocation from a global pool. */
#define MK_AUTOALLOC 0
/*! Allocation from a local, manually-allocated, pool. */
#define MK_MANUALALLOC 1
/*! Hybrid between AUTO and MANUAL. First tries local pool, then tries global pool. */
#define MK_MIXEDALLOC 2

/*@}*/

#import "MKInstrument.h"
#import "MKNote.h"
#import "MKSynthPatch.h"

@interface MKSynthInstrument : MKInstrument
{
    id synthPatchClass;                   /*!< class used to create patches. */
    unsigned short allocMode;             /*!< One of MK_MANUALALLOC, MK_AUTOALLOC, or MK_MIXEDALLOC. */
    NSMutableDictionary *taggedPatches;   /*!< Dictionary mapping noteTags to MKSynthPatches */
    NSMutableDictionary *controllerTable; /*!< Dictionary mapping MIDI controllers to values */
    MKNote *updates;                      /*!< MKNote for storing common (no noteTag) updates. */
    BOOL retainUpdates;                   /*!< NO if updates and controllerTable are cleared after each performance. */
    Class orchestra;               	  /*!< MKOrchestra class to allocate MKSynthPatches from */

@private
    NSMutableArray *_patchLists;
}

/*!
  @brief Initializes the receiver.

  You invoke this method when you create a new instance of MKSynthInstrument.
  An overriding subclass method should send <b>[super init]</b> before setting its own defaults.
  @return Returns an id.
*/
- init;

/*!
  @brief Immediately allocates <i>voices</i> MKSynthPatch objects using the
  patch template <i>aTemplate</i> (the MKOrchestra must be open) and
  puts the receiver in manual mode.

  If <i>aTemplate</i> is <b>nil</b>, the value returned by the message:
  
  <tt>[synthPatchClass defaultPatchTemplate]</tt>
  
  is used.  Returns the number of objects that were allocated (it may be less than the number requested).  
  If you decrease the number of manually allocated MKSynthPatches during a performance, 
  the extra MKSynthPatches aren't deallocated until they become inactive.  In other words,
  reallocating downward won't interrupt notes that are already sounding.
  @param  voices is an int.
  @param  aTemplate is an id.
  @return Returns an int.
 */
- (int) setSynthPatchCount: (int) voices patchTemplate: (id) aTemplate;

/*!
  @brief Immediately allocates <i>voices</i> MKSynthPatch objects.

  Implemented as:
  
  <tt>[self setSynthPatchCount: voices template: nil];</tt>
  
  Returns the number of objects that were allocated.
  @param  voices is an int.
  @return Returns an int.
*/
- (int) setSynthPatchCount: (int) voices;

/*!
  @brief Returns the number of allocated MKSynthPatch objects created with the MKPatchTemplate <i>aTemplate</i>.
  @param  aTemplate is an id.
  @return Returns an int.
*/
- (int) synthPatchCountForPatchTemplate: (id) aTemplate;

/*!
  @brief Returns the number of allocated MKSynthPatch objects created with the
  default MKPatchTemplate.
  @return Returns an int.
*/
- (int) synthPatchCount;

/*!
  @brief Synthesizes <i>aNote</i>.
  @param  aNote is an MKNote instance.
  @param  aNoteReceiver is an MKNoteReceiver instance.
  @return Returns an id.
 */
- realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver;   

/*!
  @brief Returns the receiver's MKSynthPatch class.
  @return Returns an id.
*/
- synthPatchClass;

/*!
  @brief Sets the receiver's MKSynthPatch class to <i>aSynthPatchClass</i>.

  Returns <b>nil</b> if the argument isn't a subclass of MKSynthPatch or 
  the receiver is in a performance (the class isn't set in this case).
  Otherwise returns the receiver.
  @param  aSynthPatchClass is an id.
  @return Returns an id.
*/
- setSynthPatchClass: (Class) aSynthPatchClass; 
   
/*!
  @brief Like <i>setSynthPatchClass:</i> but also specifies that 
  MKSynthPatch instances are to be allocated using the object anOrch.

  This is only used when you want a particular orchestra instance to be used rather
  than allocating from the MKOrchestra class. If anOrch is nil, the orchestra 
  used is the value returned by [aSynthPatchClass orchestraClass].
  @param  aSynthPatchClass is an id.
  @param  anOrch is an MKOrchestra.
  @return Returns an id.
 */
- setSynthPatchClass: (Class) aSynthPatchClass orchestra: (Class) anOrch; 

/*!
  @brief Returns the value set with <i>setSynthPatchClass:orchestra:</i>, if any.

  Otherwise returns [MKOrchestra class].
  @return Returns a Class.
*/
- (Class) orchestra;

/*!
  @brief You never invoke this method.

  It's invoked automatically when the
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
 @param  aNote is an MKNote instance.
 @param  firstPatch is an id.
 @return Returns an id.
 */
- preemptSynthPatchFor: (MKNote *) aNote patches: (MKSynthPatch *) firstPatch;

/*!
  @brief Returns the first in the sequence of MKSynthPatches with MKPatchTemplate
  <i>aTemplate</i> that are currently sounding.

  The sequence is
  ordered by the begin times of the MKSynthPatches' current phrases,
  from the earliest to the latest. In addition, all finishing
  MKSynthPatches are returned before all running MKSynthPatches.
  You step down the sequence by sending <b>next</b> to the objects
  returned by this method.  If <i>aTemplate</i> is <b>nil</b>, the
  default MKPatchTemplate is used. 
  If there aren't any active MKSynthPatches with the specified template,
  <b>nil</b> is returned.
 @param  aTemplate is an id.
 @return Returns an id.
*/
- activeSynthPatches: (id) aTemplate;
 
/*!
  @brief You never invoke this method; it's invoked automatically when the
  receiver receives a mute MKNote.

  Mutes aren't normally forwarded to
  MKSynthPatches since they usually don't produce sound.  The default
  implementation does nothing.  A subclass can implement this method
  to examine <i>aMute</i> and act accordingly.
 @param  aMute is an id.
 @return Returns an id.
*/
- mute: (id) aMute;

/*!
  @brief Sets the receiver's allocation mode to MK_AUTOALLOC and releases any
  manually allocated MKSynthPatch objects.

  If the receiver is in
  performance and isn't already in MK_AUTOALLOC mode, this does
  nothing and returns nil. Otherwise returns the receiver.
 @return Returns an id.
*/
- autoAlloc;

/*!
  @brief Returns the receiver's allocation mode, one of MK_AUTOALLOC or
  MK_MANUALALLOC.
 @return Returns an unsigned short.
*/
- (unsigned short) allocMode;

/*!
  @return Returns an id.
  @brief Sends the <b>noteEnd</b> message to all running (or finishing)
  MKSynthPatches managed by the receivers MKSynthInstrument.

  You should only invoke this method when all other attempts to halt synthesis
  fails.
*/
- abort;

/*!
  @brief Creates and returns a new MKSynthInstrument as a copy of the receiver.
  
  The copy has the same (MKNoteReceiver) connections but has no
  MKSynthPatches allocated.
 @param  zone is a NSZone.
 @return Returns an id.
*/
- copyWithZone: (NSZone *) zone;

/*!
  @brief Causes the MKSynthInstrument to clear any noteUpdate state it has
  accumulated as a result of receiving noteUpdates without noteTags.

  The effect is not felt by the MKSynthPatches until the next phrase.
  Also clears controller info.
 @return Returns an id.
*/
- clearUpdates;

/*!
  @brief Controls whether the noteUpdate and controller state is retained
  from performance to performance.

  Default is NO.
 @param  yesOrNo is a BOOL.
 @return Returns an id.
*/
- setRetainUpdates: (BOOL) yesOrNo;

/*!
  @brief Returns whether the noteUpdate and controller state is retained from
  performance to performance.
 @return Returns a BOOL.
*/
- (BOOL) doesRetainUpdates;

/*!
  @param  aNoteUpdate is a MKNote **.
  @param  controllers is a NSMutableDictionary **.
  @return Returns an id.
  @brief Returns by reference the MKNote used to store the accumulated
  noteUpdate state.

  Also returns by reference the NSMutableDictionary used to
  store the state of the controllers. Any alterations to the returned
  objects will effect future phrases.  The returned objects should be
  used only immediately after they are returned, as they may later be
  freed by the MKSynthInstrument. If clearUpdates is sent or the
  performance ends, the objects may be emptied or freed by the MKSynthInstrument.
*/
- getUpdates: (MKNote **) aNoteUpdate controllerValues: (NSMutableDictionary **) controllers;

/* 
     You never send this message directly.  
     Invokes superclass write: method. Also archives allocMode, retainUpdates 
     and, if retainUpdates is YES, the controllerTable and updates.
*/
- (void) encodeWithCoder: (NSCoder *) aCoder;

/* 
     You never send this message directly.  
     Note that -init is not sent to newly unarchived objects.
     See write:. 
*/
- (id) initWithCoder: (NSCoder *) aDecoder;

/*!
  @brief Sends a<b> noteOff:</b> message to all running MKSynthPatches managed
  by this MKSynthInstrument.
 @return Returns an id.
*/
- allNotesOff;

@end

#endif
