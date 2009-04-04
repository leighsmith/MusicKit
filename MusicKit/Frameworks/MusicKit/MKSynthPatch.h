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
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*!
  @class MKSynthPatch
  @brief A MKSynthPatch contains a configuration of MKUnitGenerators that work as a sound synthesis module.
 
MKSynthPatches are not created by the application; rather, they're created by the
MKOrchestra. The MKOrchestra is also responsible for filling the MKSynthPatch instance with
MKUnitGenerator and MKSynthData instances.  It does this on the basis of a template provided
by the MKSynthPatch class method <b>patchTemplate</b>.  You implement this method in a subclass
of MKSynthPatch to provide a MKPatchTemplate that specifies the mix of MKUnitGenerators 
and MKSynthData objects, in what order they're allocated, and how to connect them.

Typically, a MKSynthPatch is owned and operated by a MKSynthInstrument object.  The
MKSynthInstrument manages the allocation of MKSynthPatches in response to incoming
MKNotes.  Alternatively, MKSynthPatches may be used in a stand-alone fashion.  In
this case, you must allocate the objects by sending the MKOrchestra an
<b>allocSynthPatch:</b> or <b>allocSynthPatch:patchTemplate:</b>
message.

While in performance, a MKSynthPatch is identified by the noteTag of the MKNote
stream that it's synthesizing.
 
*/

#ifndef __MK_SynthPatch_H___
#define __MK_SynthPatch_H___

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import "MKPatch.h"
#import "MKConductor.h"
#import "MKUnitGenerator.h"
#import "orch.h"

/*!
  @file MKSynthPatch.h
 */

/*!
  @brief This enumeration defines the state of a MKSynthPatch and is designed for
  use in a MKSynthPatch subclass implementation.
 
  Each instance of MKSynthPatch performs a single musical voice.  The <b>MKPhraseStatus</b>
  defines where in the phrase that voice is.  The method <b>phraseStatus</b> returns one
  of these values. Note that if a MKSynthPatch is not in one of the subclass methods
  <b>noteOnSelf:</b>, <b>noteOffSelf:</b>, <b>noteUpdateSelf:</b>, or <b>noteEndSelf</b>, the method
  <b>phraseStatus</b> returns <b>MK_noPhraseActivity</b>.
 */
typedef enum _MKPhraseStatus {
    /*! MKSynthPatch is processing a noteOn for a new phrase. */
    MK_phraseOn,
    /*! MKSynthPatch is processing a noteOn for a preempted phrase.  That is, a phrase
    for another noteTag was preempted because there were not enough DSP
    resources available to play the new note. */
    MK_phraseOnPreempt,
    /*! MKSynthPatch is processing a noteOn for a rearticulation of an existing phrase.
    That is, a noteOn has been received for a noteTag that is already in the process
    of playing a phrase. */
    MK_phraseRearticulate,
    /*! MKSynthPatch is processing a noteUpdate for a phrase
    that has received a noteOn but has not yet received a noteOff. */
    MK_phraseUpdate,
    /*! MKSynthPatch is processing a noteOff. */
    MK_phraseOff,
    /*! MKSynthPatch is processing a noteUpdate for a phrase that has received a noteOff. */
    MK_phraseOffUpdate,
    /*! MKSynthPatch is executing the <b>noteEnd</b> method.*/
    MK_phraseEnd,
    /*! MKSynthPatch is not currently executing any of the methods <b>noteOnSelf:</b>,
    <b>noteOffSelf:</b>, <b>noteUpdateSelf</b>, or <b>noteEndSelf</b>. */
    MK_noPhraseActivity
} MKPhraseStatus;

@interface MKSynthPatch : MKPatch
{
    /*! Array of MKUnitGenerator and MKSynthData objects. */
    NSMutableArray *synthElements;
    /*! The MKSynthInstrument object currently in possession of the MKSynthPatch or nil if none. */
    id synthInstrument;
    /*! Tag of notes currently implemented by this MKSynthPatch. */
    int noteTag;
    /*! Status of patch. One of MK_running, MK_finishing or MK_idle. You should never set it explicitly in your subclass. */
    MKSynthStatus status;
    /*! MKPatchTemplate of this patch. */
    id patchTemplate;
    /*! YES if the object is allocated. */
    BOOL isAllocated;
    /*! MKOrchestra instance on which the object is allocated and on which this MKSynthPatch is running. */
    MKOrchestra *orchestra;

@private
    unsigned short _whichList;  // Which list am I on?
    int _orchIndex;             // Which DSP?
    id _next;                   // Used internally for linked list of active MKSynthPatches.

    // Used to unqueue noteEnd request. If non-null, we have seen a noteOff but are not yet noteEnd.
    MKMsgStruct *_noteEndMsgPtr; 

    // Used to unqueue noteOff:aNote request. Non-null if we have seen a noteDur recently.
    // Used to remember tagged NoteOffs auto-generated from NoteDurs.
    MKMsgStruct *_noteDurMsgPtr;  

    id _sharedKey;
    MKMsgStruct *_notePreemptMsgPtr;
    short _phraseStatus;
}

+ new;
+ allocWithZone:(NSZone *)zone;
+ alloc;
- copy;
- copyWithZone:(NSZone *)zone;
 /* These methods are overridden to return [self doesNotRecognize]. 
    You never create, free or copy MKSynthPatches directly. These operations
    are always done via an MKOrchestra object. */


/*!
  @brief Returns an appropriate MKPatchTemplate with which to create an MKSynthPatch instance
  that will adequately synthesize <i>currentNote</i>.
  
  Determines an appropriate patchTemplate and returns it. In some cases, it is necessary to
  look at the current note to determine which patch to use. 
  This method is invoked by MKSynthInstrument whenever it needs to allocate a new MKSynthPatch instance.  It may
  also be sent by an application to obtain the template to be used as
  the second argument to MKSynthInstrument's <b>setSynthPatchCount:patchTemplate:</b> method. 
  Implementation of this method is a subclass responsibility such that when
  currentNote is nil, a default template is returned.
  @param  currentNote is an MKNote instance. If <i>currentNote</i> is <b>nil</b>, the default template 
  should be returned.
  @return Returns an id.
 */
+ patchTemplateFor: (MKNote *) currentNote;

/*!
  @return Returns an id.
  @brief Always returns the MKOrchestra class.

  It's provided for applications
  that extend the Music Kit to use other hardware.  Each MKSynthPatch
  subclass is associated with a particular kind of hardware.  The
  default hardware is that represented by MKOrchestra, the
  DSP56001.
*/
+ orchestraClass;

/*!
  @brief Returns the default MKPatchTemplate for the class. 
  @return Returns an id.
  
  You never implement this method. It is the same as return [self patchTemplateFor: nil].
*/
+ defaultPatchTemplate;

/*!
  @return Returns an id.
  @brief Returns synthInstrument owning the receiver, if any.
*/
- synthInstrument;

/*!
  @return Returns an id.
  @brief Sent by the MKOrchestra only when a new MKSynthPatch has just been
  created and before its MKUnitGenerator connections have been made, as
  defined by the MKPatchTemplate.

  A subclass may override the
  <b>init</b> method to provide additional initialization. A return of
  <b>nil</b> aborts the creation and frees the new MKSynthPatch.  The
  default implementation does nothing and returns the
  receiver.
*/
- init;

/*!
  @brief Returns the MKUnitGenerator or MKSynthData at the specified index or
  <b>nil</b> if <i>anIndex</i> is out of bounds.

 @param  anIndex is an unsigned int and is zero-based.
 @return Returns an id.
*/
- synthElementAt: (unsigned) anIndex;

/*!
  @brief (sb): changed to mkdealloc to prevent conflict with OpenStep deallocation.
 
 This is used to explicitly deallocate a MKSynthPatch you previously
 allocated manually from the MKOrchestra with allocSynthPatch: or 
 allocSynthPatch:patchTemplate:.
 It sends noteEnd to the receiver, then causes the receiver to become 
 deallocated and returns nil. This message is ignored (and self is returned)
 if the receiver is owned by a MKSynthInstrument.
 */
- (void) mkdealloc;

/*!
  @brief Sent when the receiver is running or finishing and is preempted by
  its MKSynthInstrument.

  This happens, for example, when a MKSynthInstrument with 
  3 voices receives a fourth note. It preempts one of the voices by 
  sending it preemptFor:newNote followed by noteOn:newNote. The default implementation does nothing and
  returns self. Normally, a time equal to the value returned by
  <b>MKPreemptDuration()</b> is allowed to elapse before the
  preempting MKNote begins. A subclass can specify that the new MKNote
  happen immediately by returning <b>nil</b>.
  @param  aNote is an MKNote instance.
  @return Returns an id.
*/
- preemptFor: (MKNote *) aNote;

/*!
  @brief You never invoke this method directly.

  The default implementation returns the receiver.
  Subclass may override this method to do any initialization needed
  for each noteOn. <b>noteOnSelf</b>: is sent whenever a new MKNote
  stream commences, even if the MKSynthPatch is already running. 
  The subclass can determine whether or not the MKSynthPatch is already running
  by examing the status instance variable. It should also check for preemption with -phraseStatus.
  
  The message <b>noteEnd</b> is sent to the receiver if this method returns <b>nil</b>.
  @param  aNote is an MKNote instance.
  @return Returns the receiver or <b>nil</b> if the receiver should immediately become idle.
*/
- noteOnSelf: (MKNote *) aNote;

/*!
  @brief You never invoke this method, it's invoked automatically by <b>noteUpdate</b>:.

  A subclass can implement this method to provide
  behavior appropriate to reception of a noteUpdate. noteUpdateSelf: should send
  whatever messages are necessary to update the state of the DSP as reflected by the parameters in 
  aNote. 
 @param  aNote is an MKNote instance.
 @return Returns an id.
*/
- noteUpdateSelf: (MKNote *) aNote; 

/*!
  @brief You never invoke this method; it's invoked automatically by <b>noteOff</b>:.

  It is sent when a noteOff or end-of-noteDur is received. However, a subclass
  may provide an implementation that describes its response to a noteOff, the beginning of the
  final segment of the note or phrase. The return value is the
  amount of time to wait, in seconds, before the MKSynthPatch
  can be released. For example, a MKSynthPatch that has 2 envelope handlers should implement
  this method to send finish to each envelope handler and return
  the maximum of the two. The default implementation returns 0.0.
 @param  aNote is an MKNote instance.
 @return Returns a double.
*/
- (double) noteOffSelf: (MKNote *) aNote; 

/*!
  @return Returns an id.
  @brief This method is invoked automatically when the MKNote stream is
  complete.

  You never invoke this method directly; it's invoked by
  the MKSynthInstrument.  A subclass may override this to do what it
  needs to do to ensure that the MKSynthPatch produces no output.
  Usually, the subclass implementation sends the <b>idle</b> message
  to the Out2sumUGx or Out2sumUGy MKUnitGenerator.  The default
  implementation does nothing and returns the receiver.
*/
- noteEndSelf; 

/*!
  @brief This starts or rearticulates a MKNote stream by sending
  <b>noteOnSelf</b>:<i>aNote</i> to the receiver.

  If
  <b>noteOnSelf:</b> returns <b>self</b>, the receiver's status is set
  to MK_running and the receiver is returned.  If <b>noteOnSelf:</b>
  returns <b>nil</b>, <b>noteEnd</b> is sent to the receiver and
  <b>nil</b> is returned.  Ordinarily sent only by
  MKSynthInstrument.
 @param  aNote is an MKNote instance.
 @return Returns an id.
*/
- noteOn: (MKNote *) aNote; 

/*!
   @brief Sent ordinarily only by the MKSynthInstrument when a noteUpdate is received.

  Implemented as<b> [self noteUpdateSelf:</b><i>aNote</i>].
 @param  aNote is an MKNote instance.
 @return Returns an id.
*/
- noteUpdate: (MKNote *) aNote;

/*!
  @brief Concludes a MKNote stream by sending <b>[self noteOffSelf:</b> <i>aNote</i><b>]</b>.
  
  Sets the receiver's status to MK_finishing. This method is ordinarily invoked only by an MKSynthInstrument.
 @param aNote is an MKNote.
 @return Returns the release duration as returned by <b>noteOffSelf:</b>
*/
- (double) noteOff: (MKNote *) aNote; 

/*!
  @brief Causes the receiver to become idle.
  @return Returns self.
  
  The message <b>noteEndSelf</b> is sent to the receiver and its status is set to MK_idle. 
  Ordinarily this is invoked automatically by the MKSynthInstrument, but may be sent by anyone to
	  immediately stop a patch. 
*/
- noteEnd; 

/*!
  @brief Sent when the MKOrchestra moves a MKSynthPatch's MKUnitGenerator during
  DSP memory compaction.

  <i>aUG</i> is the unit generator that was moved.  A
  subclass can override this method to provide specialized behavior. 
  The default implementation does nothing. 
  @see phraseStatus.
  @param  aUG is an MKUnitGenerator instance.
  @return Returns an id.
*/
- moved: (MKUnitGenerator *) aUG; 

/*!
  @brief Returns the status of the receiver.
  @return Returns an int.
  
  This is not necessarily the status of all contained MKUnitGenerators.  For example, it is not
  unusual for a MKSynthPatch to be idle but most of its MKUnitGenerators,
  with the exception of the Out2sum, to be running.
*/
- (int) status; 

/*!
  @brief Two MKSynthPatches are considered equal if they have the same noteTag.

  This is used by the MKSynthInstrument to search for a MKSynthPatch
  matching a certain noteTag.
 @param  anObject is an MKSynthPatch instance.
 @return Returns a BOOL.
*/
- (BOOL) isEqual: (MKSynthPatch *) anObject; 

/*!
  @brief Uses the noteTag to hash itself.
 @return Returns an unsigned.
*/
- (unsigned) hash;  

/*!
  @return Returns an id.
  @brief Returns the MKPatchTemplate associated with the receiver.
*/
- patchTemplate;

/*!
  @brief Returns the noteTag associated with the MKNote stream the receiver is
  currently playing.
 @return Returns an int.
*/
- (int) noteTag; 

/*!
  @brief Returns the MKOrchestra instance to which the receiver belongs.
  @return Returns an id.
  
  All MKUnitGenerators and MKSynthData in an instance of MKSynthPatch are on the
  same MKOrchestra instance. In the standard NeXT configuration, there
  is one DSP and, thus, one MKOrchestra instance.
*/
- orchestra; 

/*!
  @return Returns a BOOL.
  @brief Returns YES if the receiver may be freed; otherwise returns NO.

  An MKSynthPatch may only be freed if it is idle and not owned by a
  manually allocated MKSynthInstrument.
*/
-(BOOL) isFreeable; 

- (void) dealloc; /*sb: was -free before OS conversion. Maybe I should have left it alone... */
 /* Same as dealloc */


/*!
  @brief Sent by the MKSynthInstrument to a MKSynthPatch when a new tag stream
  begins, before the <b>noteOn:</b> message is sent.

  
  The default implementation  does nothing. You
  may override it in a subclass as desired.
  
  Note that the sustain pedal controller is handled automatically by the MKSynthPatch class.
  Note that pitchbend is not a controller in MIDI. Thus the current
  pitchbend is included in the MKNote passed to noteOn:, not in the
  HashTable. See the HashTable spec sheet for details on how to 
  access the values in controllers. The table should not be altered
  by the receiver. 
 @param  controllers is a HashTable that describes the state of the
 MIDI controllers by mapping integer controller numbers to integer
 controller values.
 @return Returns an id.
 */
- controllerValues: (id) controllers;

/*!
  @return Returns an id.
  @brief This method is used in conjunction with a MKSynthInstrument's
  <b>preemptSynthPatchFor:patches:</b> method.

  It returns the next
  MKSynthPatch in a List of active MKSynthPatches owned by the
  MKSynthInstrument.  The objects in the List are in the order in which
  they began synthesizing their current phrases (oldest first), i.e in the
  order of the onset times of the phrases played by the MKSynthPatches.
*/
- next;

/*!
  @brief Sent just before the receiver is free, a subclass can implement this
  method to provide specialized behavior.
 @return Returns an id.
*/
- freeSelf;

/*!
  @brief This is a convenience method for MKSynthPatch subclass implementors.

  The value returned takes into account whether the phrase is
  preempted, the noteType of the current MKNote and the status of the
  receiver.  If not called by a MKSynthPatch subclass, returns
  MK_noPhraseActivity.
 @return Returns a MKPhraseStatus.
*/
- (MKPhraseStatus) phraseStatus;

 /* -read: and -write: 
  * Note that archiving is not supported in the MKSynthPatch object, since,
  * by definition the MKSynthPatch instance only exists when it is resident on
  * a DSP.
  */

@end

@interface MKSynthPatch(PatchLoad)

/*!
  @brief This method does dynamic loading of Objective-C MKSynthPatch 
  modules.

  It looks for a class with the specified name. It
  first tries to find the specified class in the
  application.   
  If found, it is returned.
  If not found, this method tries to dynamically load the class. 
  The standard library directories are searched for a file named <name>.bundle.
  On MacOS X these would be:

  1. ./
  2. ~/Library/MusicKit/SynthPatches/
  3. /Library/MusicKit/SynthPatches/
  4. /Network/Library/MusicKit/SynthPatches/
  5. /System/Library/MusicKit/SynthPatches/

  On Open/NeXTStep these would be:

  1. ~/Library/Music/SynthPatches
  2. /LocalLibrary/Music/SynthPatches
  3. /NextLibrary/Music/SynthPatches
  
  If a file is found, it is dynamically loaded.  If the
  whole process is successful, the newly loaded class is returned.
  Otherwise, nil is returned.  If the file is found but the link
  fails, an error is printed to the stream returned by
  <b>MKErrorStream()</b>(this defaults to <b>stderr</b> ). You can
  change it to another stream with <b>MKSetErrorStream().</b>
  
  When doing dynamic loading, you have to make sure that
  any symbols referenced by the dynamically loaded code are present in
  the application.  For example, if a MKSynthPatch uses a MKUnitGenerator
  that is not linked to your application, the dynamic load will fail. 
  <b>ProjectBuilder</b> normally supplies the <b>-ObjC</b> flag,
  which has the effect of linking all ObjectiveC classes in all
  libraries against which your application links.  If you do not use
  the<b> -ObjC </b>flag,  you can specify linking of specific
  unreferenced symbols using <b>-u .objc_class_name_MyClass</b>.   If
  you want the dynamically loaded code to be able to access
  non-ObjectiveC symbols in l<b>ibNeXT</b> or <b>libsys</b> that are
  not already used in the application, you must include <b>-u
  libNeXT_s</b> or <b>-u libsys_s</b> on the link line.  
  Alternatively, you can use the <b>-all_load</b> linker option, which
  will pull in everything from all libraries.   
  @param name Class name.
  @return Returns an id.
*/
+ findPatchClass: (NSString *) name;

@end

#endif
