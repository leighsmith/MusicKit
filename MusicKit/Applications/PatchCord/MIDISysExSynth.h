/*!
  @class MIDISysExSynth
  @description
     MIDISysExSynth is an abstract synthesiser class, the particular model of synth is a concrete subclass
     (with overloaded methods) and instance is the data, as there can be several patches of a particular
     synth open simultaneously (if we have several physical synths of the same model on
     different channels and we are pulling patches between them, or if we want to compare two patches). 

     The class deals with functions concerning update, display and user
     interaction with the synth.
     Currently this object is both the controller and the model - TODO that must change!
     This is a subclass of NSWindowController so it automatically orders the windows it creates.

     The user has three conceptual fields describing a patch - Synth name (Class
     description), patch description (both displayed in the table view) and the patch
     (displayed via an inspector).

     Therefore think of this class in terms of instance operation:
     [firstJuno106 sendUpdate]
     [myJuno106 acceptNewPatch: msg]
     [secondJuno106 canUploadPatches]
     [synth[i] canUploadPatches]

     Perhaps consider the interface to the synth as of a particular format, i.e only
     communicate to this object with sysEx messages.
 */

#import "SysExMessage.h"
@class Bank;                   // Forward declaration of the Bank class

@interface MIDISysExSynth: NSWindowController <NSCoding>
{
    // These instance vars concern the model
    /*! last sysEx received or sent. The state as a sysEx. */
    SysExMessage *patch;
    /*! name of the patch (from synth and any description). */
    NSString *patchDescription;
    /*! MIDI channel this synth is on (if determinable) 0-15. */
    // TODO check if there is a type for MIDIChannel already
    int MIDIChannel;
    /*! the patchnumber on the channel this patch is associated with. */
    int MIDIpatchNumber;
    /*! the Bank this patch resides in. */
    Bank *bank;
    /*! single icon, perhaps part of nib */
    // icon
}

/*!
  @brief send a dump request message to the synth.
 */
+ (void) requestPatchUpload;

/*!
  @brief initialise and register oneself with the SysExMessage.
 */
- (id) init;

/*!
  @brief initialise with an empty patch ready for editing.
*/
- (id) initWithEmptyPatch;

/*!
  @brief restore a whole patch
 
  We need to initialise to a meaningful empty patch and
  at some point (as soon as it is
  generated?, when commanded to?) download using sendPatch.
  A user will want to audition a patch straight after
  creating a new one and may just start playing on the keyboard. Perhaps that
  should be an instance decision?
*/
- (id) initWithCoder:(NSCoder *) aDecoder;

/*!
  @brief save the patch.
 */
- (void) encodeWithCoder:(NSCoder *) aCoder;

/*!
  @brief Display the patch currently held.
 */
- (void) displayPatch;

/*!
  @brief Download current patch to synth: compile the synth instance data into a sys Ex msg and send it.
 */
- (void) sendPatch;

/*!
  @brief Send an update such as a parameter change.

  The situation is very similar to acceptNewPatch and read (sysEx vs. something more than
  just a sys-ex message to save in a data file).
 */
- (void) sendUpdate;

/*!
  @brief Mix things up a bit (needs a random number seed).
 */
- (void) randomizePatch;

// Methods to parse an incoming sys-ex message for this synth.

/*!
  @brief  The method used to provide new sysEx messages to the synth sub-class.
  The sub-class should check if it is interpretable by this object (ie. the manufacturers ID
  and synth IDs check out. It should perform interpretation of the messages and pass on
  the message to acceptNewPatch, acceptBulkDump, parameterUpdate etc).
 */
- (BOOL) initWithSysEx: (SysExMessage *) msg;

- (SysExMessage *) sysEx;

// The following methods will be called by sysEx:, they should be overloaded in the sub-classes.

/*!
  @brief Check if the sys-ex message is updating a parameter.
 */
- (BOOL) isParameterUpdate: (SysExMessage *) msg;

/*!
  @brief Check if the sys-ex message is a new patch message.
 */
- (BOOL) isNewPatch: (SysExMessage *) msg;

/*!
  @brief Check if the sys-ex message is a bulk patch dump message.
 */
- (BOOL) isBulkDump: (SysExMessage *) msg;

// act upon a parsed sys-ex message

/*!
  @brief set and display a new patch, should load the nib.
*/
- (void) acceptNewPatch: (SysExMessage *) msg;

/*!
  @brief Decompose the message into a set of synth sub-class instances (self) and hand
  each one over to the bank object.
 (which one? and where do we find it?)
 */
- (void) acceptBulkDump: (SysExMessage *) msg;

/*
  From a bank, we could produce a new patch which would be a synth object.
  This may be better performed by read... (have to read on archiving objects), rather than
  calling acceptNewPatch.
*/

/*!
  @brief Change a single parameter in the current patch.
  This will be called when a slider is moved on the synth.
 */
- (void) parameterUpdate: (SysExMessage *) msg;

// Synthesiser capability defining methods.

/*!
 @brief Identifies the synth as responding to note-on/offs.
 */
- (BOOL) canPlayNotes;

/*!
  @brief Returns YES if the receiver can send parameter updates to the synth while it
  sounds and hear the changes without retriggering a note.
 */
- (BOOL) canUpdatePatchWhilePlaying;

/*!
 @brief Returns YES if the receiver is able to retrieve patches from the synth via sysex.
 */
+ (BOOL) canUploadPatches;

/*
  Should the description and the patch name be two different fields, or should the
  patch name be derived from the description (when downloading) & vice-versa when uploading?
*/
/*
  Probably should start thinking about the bank interface in order to fully define the
  synth multiple patch handling methods. Think of it in terms of a general object storage device.
*/

/*!
  The synth can send a whole bunch of patches in a single sysex message.
  Should the synth carve up the patches and hand them back to the controller - hmm.
  However, where should we handle a whole bank of patches being uploaded in a single sys-ex message?
*/
- (BOOL) canSendMultiplePatches;

/*!
  It is feasible to have a synth which only works by downloading an entire bank,
  even though we are working on a single patch. In that case before anything
  can be changed a complete bank has to be assembled.
  Controller may need to inform the user that a complete bank must be downloaded,
  where should the patch be placed.
 */
- (BOOL) mustDownloadBank;

/*!
  @brief will the subclass respond to anything?
 */
- (BOOL) catchesAllMessages;

/*! 
  @brief return the MIDI channel the synth is on.
 */
- (int) midiChannel;

/*!
  @brief assign the MIDI channel
 */
- (void) setMidiChannel:(int) midiChan;

/*!
  @brief returns the text of the patch description.
 */
- (NSString *) patchDescription;

/*!
  @brief assigns the patch description string
 */
- (void) setPatchDescription: (NSString *) newPatch;

/*!
  @brief return the MIDI patch change number the patch is addressed by.
 */
- (int) midiPatchNumber;

/*!
  @brief assign the patch number.
 */
- (void) setMidiPatchNumber: (int) midiPatchNumber;

/*!
  @brief returns the name of the Synthesiser
 */
- (NSString *) synthName;

/*!
  @brief sets and returns the bank this synth patch is part of.
 */
- (void) setBank: (Bank *) b;

/*!
  @brief 
 */
- (Bank *) bank;

@end

@interface MIDISysExSynth(WindowDelegate)

- (BOOL) windowShouldClose: (id) sender;

@end
