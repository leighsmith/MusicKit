/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    A MKSynthPatch contains an NSArray of unit generators which behave as
    a functional unit.
    
    MKSynthPatches are not created by the application. Rather, they
    are created by the MKOrchestra. The MKOrchestra is also
    responsible for filling the MKSynthPatch instance with MKUnitGenerator and
    MKSynthData instances. It does this on the basis of a template provided by the
    MKSynthPatch class method +patchTemplate. The subclass designer implements
    this method to provide a MKPatchTemplate which specifies what the mix of
    MKUnitGenerators and MKSynthData objects should
    be, in what order it should be allocated, and how to connect them up.
    (See MKPatchTemplate.)
    The MKSynthPatch instance, thus, is an NSArray containing the MKUnitGenerators
    and MKSynthData objects in the order they were specified in the template and
    connected as specified in the template.

    MKSynthPatches can be in one of three states:
    MK_running
    MK_finishing
    MK_idle

    The subclass may supply methods to be invoked at the initialiation
    (creation), noteOn, noteOff, noteUpdate and end-of-note (noteEnd) times, as
    described below.

    MKSynthPatches are ordinarily used in conjunction with a Conducted
    performance by using a MKSynthInstrument. The MKSynthInstrument manages the allocation
    of MKSynthPatches in response to incoming MKNotes. Alternatively, MKSynthPatches
    may be used in a stand-alone fashion. In this case, you must allocate the
    MKSynthPatch by sending the MKOrchestra the -allocSynthPatch: or
    allocSynthPatch:patchTemplate: method.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2000, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.5  2001/03/06 21:47:32  leigh
  Abstracted patch loading from SynthPatches into MKPatch

  Revision 1.4  2000/11/25 23:26:10  leigh
  Enforced ivar privacy

  Revision 1.3  2000/03/24 21:11:35  leigh
  Cleanups of doco, removed the objc_loadmodules include causing compilation probs on MOXS 1.2

  Revision 1.2  1999/07/29 01:25:51  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_SynthPatch_H___
#define __MK_SynthPatch_H___

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>    /* Needed, by subclass, to access synth elements. */
#import "MKPatch.h"
#import "MKConductor.h"
#import "orch.h"

typedef enum _MKPhraseStatus {
    MK_phraseOn,
    MK_phraseOnPreempt,
    MK_phraseRearticulate,
    MK_phraseUpdate,
    MK_phraseOff,
    MK_phraseOffUpdate,
    MK_phraseEnd,
        MK_noPhraseActivity}
MKPhraseStatus;

@interface MKSynthPatch : MKPatch
{
    NSMutableArray *synthElements;    // Array of MKUnitGenerator and MKSynthData objects.
    id synthInstrument;    // The MKSynthInstrument object currently in possession of the MKSynthPatch or nil if none.
    int noteTag;           // Tag of notes currently implemented by this MKSynthPatch.
    MKSynthStatus status;  // Status of patch. One of MK_running, MK_finishing or MK_idle.
                           // You should never set it explicitly in your subclass.
    id patchTemplate;      // MKPatchTemplate of this patch.
    BOOL isAllocated;      // YES if the object is allocated.
    MKOrchestra *orchestra; // MKOrchestra instance on which the object is allocated and on which this MKSynthPatch is running.

@private
    unsigned short _whichList;  // Which list am I on?
    int _orchIndex;             // Which DSP?
    id _next;                   // Used internally for linked list of active SynthPatches.

    // Used to unqueue noteEnd request. If non-null, we have seen a noteOff but are not yet noteEnd.
    MKMsgStruct *_noteEndMsgPtr; 

    // Used to unqueue noteOff:aNote request. Non-null if we have seen a noteDur recently.
    // Used to remember tagged NoteOffs auto-generated from NoteDurs.
    MKMsgStruct *_noteDurMsgPtr;  

    id _sharedKey;
    MKMsgStruct *_notePreemptMsgPtr;
    short _phraseStatus;
}

+new;
+ allocWithZone:(NSZone *)zone;
+alloc;
-copy;
- copyWithZone:(NSZone *)zone;
 /* These methods are overridden to return [self doesNotRecognize]. 
    You never create, free or copy SynthPatches directly. These operations
    are always done via an Orchestra object. */

+ patchTemplateFor:currentNote; 
 /* 
   patchTemplateFor: determines
   an appropriate patchTemplate and returns it. 
   In some cases, it is necessary to look at the current note to 
   determine which patch to use. 
   patchTemplateFor: is sent by the SynthInstrument 
   when a new MKSynthPatch is to be created. It may also be sent by
   an application to obtain the template to be used as an argument to 
   SynthInstrument's -setSynthPatchCount:patchTemplate:.
   Implementation of this method is a subclass responsibility. 
   The subclass should implement this method such that when
   currentNote is nil, a default template is returned. */

+ orchestraClass;
 /* 
   This method always returns the Orchestra factory. It is provided for
   applications that extend the Music Kit to use other hardware. Each 
   MKSynthPatch subclass is associated with a particular kind of hardware.
   The default hardware is that represented by Orchestra, the DSP56001.
   */

+ defaultPatchTemplate; 
  /* 
     You never implement this method. It is the same as 
     return [self patchTemplateFor:nil]. */

- synthInstrument;
  /* Returns synthInstrument owning the receiver, if any. */

- init; 
 /* 
   Init is sent by the orchestra 
   only when a new MKSynthPatch has just been created and before its
   connections have been made, as defined by the PatchTemplate.
   Subclass may override the init method to provide additional 
   initialization. The subclass method may return nil to 
   abort the creation. In this case, the new MKSynthPatch is freed.
   The PatchTemplate is available in the instance variable patchTemplate.
   Default implementation just returns self.
   */

//- (void)initialize;
 /* Obsolete */

- (void)mkdealloc; /*sb: changed to mkdealloc to prevent conflict with OpenStep deallocation */
 /* 
   This is used to explicitly deallocate a MKSynthPatch you previously
   allocated manually from the Orchestra with allocSynthPatch: or 
   allocSynthPatch:patchTemplate:.
   It sends noteEnd to the receiver, then causes the receiver to become 
   deallocated and returns nil. This message is ignored (and self is returned)
   if the receiver is owned by a SynthInstrument. 
   */

- synthElementAt:(unsigned)anIndex;
  /* 
     Returns the UnitGenerator or SynthData at the specified index or nil if 
     anIndex is out of bounds. anIndex is zero-based. */

- preemptFor:aNote;
  /* 
     The preemptFor: message is sent when the receiver is running or 
     finishing and it is preempted by its SynthInstrument.
     This happens, for example, when a SynthInstrument with 
     3 voices receives a fourth note. It preempts one of the voices by 
     sending it preemptFor:newNote followed by noteOn:newNote. The default
     implementation does nothing and returns self. Normally, a time equal to
     the value returned by MKGetPreemptDuration() is allowed before the new note
     begins. A MKSynthPatch can specify that the new note happen immediately 
     by returning nil. */

- noteOnSelf:aNote; 
  /* 
     Subclass may override this method to do any initialization needed for 
     each noteOn. noteOnSelf: is sent whenever a new note commences, even if
     the MKSynthPatch is already running. (The subclass can determine whether or not
     the MKSynthPatch is already running by examing the status instance
     variable. It should also check for preemption with -phraseStatus.) 

     Returns self or nil if the MKSynthPatch should immediately
     become idle. The message -noteEnd is sent to the MKSynthPatch
     if noteOnSelf: returns nil.

     You never invoke this method directly. 
     The default implementation just returns self. */

- noteUpdateSelf:aNote; 
  /* 
     You override but never send this message. It is sent by the noteUpdate:
     method. noteUpdateSelf: should send whatever messages are necessary
     to update the state of the DSP as reflected by the parameters in 
     aNote. */

-(double ) noteOffSelf:aNote; 
  /* 
     You may override but never call this method. It is sent when a noteOff
     or end-of-noteDur is received. The subclass may override it to do whatever
     it needs to do to begin the final segment of the note or phrase.
     The return value is a duration to wait before releasing the 
     MKSynthPatch.
     For example, a MKSynthPatch that has 2 envelope handlers should implement
     this method to send finish to each envelope handler and return
     the maximum of the two. The default implementation returns 0. */

- noteEndSelf; 
  /* 
     This method is invoked automatically when
     the note or phrase is completed. You never invoke this method directly.
     Subclass may override this to do what it needs to do to insure that
     the MKSynthPatch produces no output. Usually, the subclass implementation
     sends the -idle message to the Out2sumUGx or Out2sumUGy UnitGenerator. 
     The default implementation just returns self. */

- noteOn:aNote; 
  /* 
     Start or rearticulate a note or phrase by sending 
     [self noteOnSelf:aNote]. If noteOnSelf:aNote returns self, 
     sets status to MK_running, returns self. Otherwise,
     if noteOnSelf returns nil, sends [self noteEnd] and returns nil.
     Ordinarily sent only by SynthInstrument.
     */

- noteUpdate:aNote;
  /* 
     Sent ordinarily only by the SynthInstrument when a noteUpdate is
     received. Implemented simply as [self noteUpdateSelf:aNote]. */

-(double ) noteOff:aNote; 
  /* 
     Conclude a note or phrase by sending
     [self noteOffSelf:aNote]. Sets status to MK_finishing.
     Returns the release duration as returned by noteOffSelf:.
     Ordinarily sent only by SynthInstrument.
     */

- noteEnd; 
    /* 
       Causes the receiver to become idle.
       The message noteEndSelf is sent to self, the status
       is set to MK_idle and returns self.
       Ordinarily sent automatically only, but may be sent by anyone to
       immediately stop a patch. 
       */

- moved:aUG; 
  /* 
     The moved: message is sent when the Orchestra moves a MKSynthPatch's
     UnitGenerator during DSP memory compaction. aUG is the unit generator that
     was moved. Subclass occasionally overrides this method.
     The default method does nothing. See also phraseStatus.
     */

-(int ) status; 
 /* 
   Returns status of the receiver. This is not necessarily the status
   of all contained UnitGenerators. For example, it is not unusual
   for a MKSynthPatch to be idle but most of its UnitGenerators, with the
   exception of the Out2sum, to be running. */

-(BOOL ) isEqual:anObject; 
  /* Obsolete. */

-(unsigned ) hash;  
  /* Obsolete. */

- patchTemplate; 
    /* 
       Returns PatchTemplate associated with the receiver. */

-(int ) noteTag; 
    /* 
       Returns the noteTag associated with the note or phrase the 
       receiver is currently playing. */

- orchestra; 
    /* 
       Returns the Orchestra instance to which the receiver belongs. All
       UnitGenerators and SynthData in an instance of MKSynthPatch are on
       the same Orchestra instance. In the standard NeXT configuration, there
       is one DSP and, thus, one Orchestra instance. */

-(BOOL ) isFreeable; 
  /* 
     Returns whether or not the receiver may be freed. A MKSynthPatch may only
     be freed if it is idle and not owned by any SynthInstrument in 
     MK_MANUALALLOC mode. */

- (void)dealloc; /*sb: was -free before OS conversion. Maybe I should have left it alone... */
 /* Same as dealloc */

-controllerValues:controllers;
  /* This message is sent by the SynthInstrument 
     to a MKSynthPatch when a new tag stream begins, before the noteOn:
     message is sent. The argument, 'controllers' describing the state of
     the MIDI controllers. It is a HashTable object 
     (see <objc/HashTable.h>), mapping integer controller
     number to integer controller value. The default implementation of this 
     method does nothing. You may override it in a subclass as desired.

     Note that pitchbend is not a controller in MIDI. Thus the current
     pitchbend is included in the Note passed to noteOn:, not in the
     HashTable. See the HashTable spec sheet for details on how to 
     access the values in controllers. The table should not be altered
     by the receiver. 

     */

- next;
  /* 
     This method is used in conjunction with a SynthInstrument's
     -preemptSynthPatchFor:patches: method. If you send -next to a MKSynthPatch
     which is active (not idle) and which is managed by a 
     SynthInstrument,
     the value returned is the next in the list of active SynthPatches (for
     a given PatchTemplate) managed 
     by that SynthInstrument. The list is in the order of the onset times
     of the phrases played by the SynthPatches. */

- freeSelf;
  /* You can optionally implement this method. FreeSelf is sent to the object
     before it is freed. */

-(MKPhraseStatus)phraseStatus;
/* This is a convenience method for MKSynthPatch subclass implementors.
   The value returned takes into account whether the phrase is preempted, 
   the type of the current note and the status of the synthPatch. 
   If not called by a MKSynthPatch subclass, returns MK_noPhraseActivity */

 /* -read: and -write: 
  * Note that archiving is not supported in the MKSynthPatch object, since,
  * by definition the MKSynthPatch instance only exists when it is resident on
  * a DSP.
  */

@end

@interface MKSynthPatch(PatchLoad)

+findPatchClass: (NSString *) name;
 /* This method looks for a class with the specified name.  
    If found, it is returned.
    If not found, this method tries to dynamically load the class. 
    The standard library directories are searched for a file named <name>.bundle.
    On MacOS X these would be:

    1. ./
    2. ~/Library/MusicKit/SynthPatches/
    3. /Library/MusicKit/SynthPatches/
    4. /Network/Library/MusicKit/SynthPatches/
    5. /System/Library/MusicKit/SynthPatches/

    If a file is found, it is dynamically loaded.  If the whole process
    is successful, the newly loaded class is returned.  Otherwise, nil
    is returned.  If the file is found but the link fails, an error is printed
    to the stream returned by MKErrorStream() (this defaults to stderr). You
    can change it to another stream with MKSetErrorStream().
    */   

@end

#endif
