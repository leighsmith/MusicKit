/*
  $Id$
  Defined In: The MusicKit

  Description:
    See the discussion below.
   
  Original Author: David A. Jaffe
  
  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2003, The MusicKit Project.

  Modification history in CVS at musickit.org
 */

@class MKNote;
@class MKScore;
@class MKNoteSender;

/*!
  @class MKPart
  @brief A MKPart is a timeTag-ordered collection of MKNotes that can be edited
  performed, and realized.  MKParts are typically grouped together in an MKScore.

A MKPart is a timeTag-ordered collection of MKNotes that can be edited
performed, and realized.  MKParts are typically grouped together in a MKScore.

A MKNote can belong to only one MKPart at a time, and a MKPart to only
one MKScore.  When you add a MKNote to a MKPart, it's automatically
removed from its old MKPart.  Similarly, adding a MKPart to a MKScore
removes it from its previous MKScore.

You can add MKNotes to a MKPart either by invoking one of MKPart's
<b>addNote:</b> methods, or by &ldquo;recording&rdquo; them with a
MKPartRecorder, a type of MKInstrument that realizes MKNotes by adding
copies of them to a specified MKPart.  Any number of MKPartRecorders
can simultaneously record into the same MKPart.  A MKPart is added to
a MKScore through MKPart's <b>addToScore:</b> method (or the
equivalent MKScore method <b>addPart:</b>).

Within a MKPart, MKNotes are ordered by their time tag values, lowest
to highest.  To move a MKNote within a MKPart, you simply change the
MKNote's time tag (through MKNote's <b>setTimeTag:</b> method).  For
efficiency, a MKPart sorts itself only when its MKNotes are retrieved
or when a MKNote is moved within the MKPart (or removed altogether).
In other words, adding a MKNote to a MKPart won't cause the MKPart to
sort itself; but keep in mind that since adding a MKNote to a MKPart
automatically removes it from its current MKPart, the act will cause
the moved-from MKPart to sort itself.  You can force a MKPart to sort
itself by sending it a <b>sort</b>message.

A MKPart can be a source of MKNotes in a performance through
association with a MKPartPerformer.  During a performance, the
MKPartPerformer reads the MKNotes in the MKPart, performing them in
order.  While you shouldn't free a MKPart or any of its MKNotes while
an associated MKPartPerformer is active, you can add MKNotes to and
remove MKNotes from the MKPart at any time without affecting the
MKPartPerformer's performance.

  A MKPart can be performed using a MKPartPerformer and can 'record' notes
  by using a MKPartRecorder. You must not free a MKPart or any of the MKNotes
  in a MKPart while there are any MKPartPerformers using the MKPart. It is ok
  to record to a part and perform that part at the same time because the
  MKPartPerformer takes a snap-shot of the MKPart when the MKPartPerformer
  is activated.

A MKPartPerformer creates its own NSMutableArray of the MKPart's
MKNotes when it receives the setPart: message (but keep in mind that
it doesn't make copies of the MKNotes themselves); changes to the MKPart
made during a performance won't affect the MKPartPerformer.  This
allows a MKPart to be performed by a MKPartPerformer and used for
recording by a MKPartRecorder at the same time.

To each MKPart you can give an info MKNote, a sort of header for the
MKPart that can contain any amount and type of information.  Info
MKNotes are typically used to describe a performance setup; for
example, an info MKNote might contain, as a parameter, the name of the
MKSynthPatch subclass on which the MKNotes in the MKPart are meant to
be synthesized.  When the MKPart's MKScore is written to a scorefile,
the info MKNote is written in the file's header; this is in
distinction to the MKPart's other MKNotes, which make up the body of
the scorefile.  (To store a MKPart in a scorefile you must first add
it to a MKScore and then write the MKScore.)

Keep in mind that a MKPart's info MKNote must be interpreted by your
application if it is to have any effect.  A few parameters defined by
the MusicKit are designed specifically to be used in a MKPart's info
MKNote.  These are listed in the description of the <b>setInfo:</b>
method, below.  The info MKNote is stored separately from the MKNotes
in the body of the MKPart; most of the MKNote-accessing methods, such
as <b>empty</b>, <b>nth:</b>, and <b>next:</b>, don't apply to the
info MKNote.  The exceptions - the methods that <i>do</i> affect the
info MKNote - are so noted in their descriptions below.

MKParts are commonly given string name identifiers, through the
<b>MKNameObject()</b> C function.  The most important use of a
MKPart's name is to identify the MKPart in a scorefile.

MKParts are automatically created by the MusicKit in a number of
circumstances, such as when reading a MKScorefile.  The function
<b>MKSetPartClass()</b> allows you to specify that your own subclass
of MKPart be used when MKParts are automatically created.  You
retrieve the MKPart class with <b>MKGetPartClass()</b>.

Editing a MKPart refers generally to adding and removing MKNotes,
not to changing the contents of the MKNotes themselves (although
some methods do both; see <b>splitNotes</b> and <b>combineNotes</b>).
MKNotes are ordered within the MKPart by their timeTag values.
To move a MKNote within a MKPart, you simply change its timeTag by
sending it the appropriate message (see the MKNote class).
This effectively removes the MKNote from its MKPart, changes the timeTag,
and then adds it back to its MKPart.

The MKNotes in a MKPart are stored in a NSArray object. The NSArray is only sorted
when necessary. In particular, the NSArray is sorted, if necessary, when an
access method is invoked. The access methods are:
  
<ul>
  <li><tt>firstTimeTag: (double) firstTimeTag lastTimeTag: (double) lastTimeTag;</tt></li>
  <li><tt>atTime: (double) timeTag;</tt></li>
  <li><tt>atOrAfterTime: (double) timeTag;</tt></li>
  <li><tt>nth: (unsigned) n;</tt></li>
  <li><tt>atOrAfterTime: (double) timeTag nth: (unsigned) n;</tt></li>
  <li><tt>atTime: (double) timeTag nth: (unsigned) n;</tt></li>
  <li><tt>next: (MKNote *) aNote;</tt></li>
  <li><tt>notes;</tt></li>
</ul>

  Other methods that cause a sort, if necessary, are:
  
<ul>
  <li><tt>combineNotes;</tt></li>
  <li><tt>removeNotes: (NSArray *) aList;</tt></li>
  <li><tt>removeNote: (MKNote *) aNote;</tt></li>
</ul>

  Methods that may alter the NSArray such that its MKNotes are no longer sorted are
  the following:

<ul>
  <li><tt>addNoteCopies: (NSArray *) aList timeShift: (double) shift;</tt></li>
  <li><tt>addNotes: (NSArray *) aList timeShift: (double) shift;</tt></li>
  <li><tt>addNote: (MKNote *) aNote;</tt></li>
  <li><tt>addNoteCopy: (MKNote *) aNote;</tt></li>
  <li><tt>splitNotes;</tt></li>
</ul>
  
This scheme works well for most cases. However, there are situations where
it can be problematic. For example:
  
<tt>
  for (i = 0; i < 100; i++) {<br>
  &nbsp;&nbsp;[aPart addNote: anArray[i]];<br>
  &nbsp;&nbsp;[aPart removeNote: anotherArray[i]];<br>
  }
</tt>

In this case, the MKPart will be sorted each time removeNote: is called,
causing N-squared behavior. You can get around this by first adding all the
notes using addNotes: and then removing all the notes using removeNotes:.

In some cases, you may find it most convenient to
remove the MKNotes from the MKPart, modify them in your own
data structure, and then reinsert them into the MKPart.

You can explicitly trigger a sort (if needed) by sending the -<b>sort</b> message.
This is useful if you ever subclass MKPart.

To get a sorted copy of the NSArray of notes use the -<b>notes</b> method.
To get the NSArray of notes itself, use the -<b>notesNoCopy</b> method.
  -<b>notesNoCopy</b> does not guarantee the MKNotes are sorted.
If you want to examine the MKNotes in-place sorted, first send -<b>sort</b>, then
  -<b>notesNoCopy</b>.

You can find out if the NSArray is currently sorted by the -<b>isSorted</b> method.
*/

#ifndef __MK_Part_H___
#define __MK_Part_H___

#import <Foundation/NSObject.h>

@interface MKPart : NSObject
{
/*! @var score The score to which this MKPart belongs. */
    MKScore *score;
/*! @var notes NSArray of MKNotes. */
    NSMutableArray *notes;  
 /*! @var info A MKNote used to store an arbitrary collection of info associated with the MKPart. */
    MKNote *info;      
/*! @var noteCount Number of MKNotes in the MKPart. */
    unsigned int noteCount;          
/*! @var isSorted YES if the receiver is sorted. */
    BOOL isSorted;          

@private
    MKNoteSender *_aNoteSender; /* Used only by MKScorefilePerformers. */
    NSMutableArray *_activePerformanceObjs;
    int _highestOrderTag;       /* For disambiguating binary search on identical time tagged MKNotes. */
}

/*!
  @brief Returns a newly allocated, initialized and autoreleased MKPart.
  @return Returns an MKPart instance.
*/
+ (MKPart *) part;

/*!
  @brief Returns a newly allocated, initialized and autoreleased MKPart with the given name.
  @param partName is an NSString instance.
  @return Returns a newly allocated, initialized and autoreleased MKPart.
 */
+ partWithName: (NSString *) partName;

/*!
  @return Returns <b>self</b>.
  @brief Causes the MKPart to sort itself if it's currently unsorted.
 
  Normally, a MKPart sorts itself only when MKNotes are accessed, moved, or removed.
  
  @see -<b>isSorted</b>
*/
- sort;

/*!
  @return Returns a BOOL.
  @brief Returns YES if the MKPart's MKNotes are currently guaranteed to be
  in time tag order, otherwise returns NO.   
  
  @see -<b>sort</b>
*/
- (BOOL) isSorted;

/*!
  @return Returns <b>self</b>.
  @brief Creates and adds a single noteDur for each noteOn/noteOff pair in the MKPart.
 
  A noteOn/noteOff pair is identified by pairing a noteOn
  with the earliest subsequent noteOff that has a matching note tag. 
  The parameters from the two MKNotes are merged in the noteDur.  If
  the noteOn and its noteOff have different values for the same
  parameter, the value from the noteOn takes precedence.  The
  noteDur's duration is the time tag difference between the two
  original MKNotes.  After the noteDur is created and added to the
  MKPart, the noteOn and noteOff are removed and freed.
 
  @see -<b>splitNotes</b>
*/
- combineNotes; 

/*!
  @return Returns an id.
  @brief Splits the MKPart's noteDurs into noteOn/noteOff pairs.
 
  Each noteDur's note type is set to noteOn and a noteOff is created (and
  added) to complement it.  The original parameters and note tag are
  divided between the two MKNotes as described in MKNote's
  <b>split::</b> method.  Returns <b>self</b>.
  
  @see -<b>combineNotes:</b>, -<b>split::</b> (MKNote)
*/
- splitNotes; 

/*!
  @param  newScore is an MKScore instance.
  @return Returns <b>self</b>.
  @brief Moves the MKPart from its present MKScore, if any, to <i>aScore</i>.
 
  Implemented in terms of MKScore's <b>addPart:</b> method.  
  
  @see  -<b>removeFromScore:</b>, -<b>score</b>
*/
- addToScore: (MKScore *) newScore; 

/*!
  @return Returns <b>self</b>, or <b>nil</b> if it isn't part of a MKScore.
  @brief Removes the MKPart from its present MKScore.
 
  This is implemented in terms of MKScore's <b>removePart:</b> method.  
  
  @see -<b>addToScore:</b>, -<b>score</b>
*/
- removeFromScore; 

/*!
  @return Returns an id.
  @brief Initializes the object.  This should be invoked when alloc'ing a new
  MKPart. 
*/
- init;

/*!
  @brief Deallocates ivars.
 */
- (void) dealloc;

/*!
  @return Returns an id.
  @brief Removes and frees the MKPart's MKNotes and its info MKNote.
 
  Removes the receiver's name from the name table.  If the MKPart has an
  active MKPartPerformer associated with it, this does nothing.  
  Returns <b>nil</b>.
  
  @see -<b>empty</b>, -<b>removeNotes:</b>
*/
- releaseNotes;

/*!
  @return Returns an id.
  @brief THIS IS DEPRECATED. DO NOT USE. EXPECT IT TO BE REMOVED SOON.
  
  Frees the MKPart but not its MKNotes.  The MKPart is removed from
  its MKScore, if any.  You <i>can</i> free a MKPart while its being
  performed by a MKPartPerformer - it's the MKPart's MKNotes, not the
  MKPart itself, that's performed.
  
  @see -<b>empty</b>, -<b>removeNotes:</b>
*/
- releaseSelfOnly; 

/*!
  @param  firstTimeTag is a double.
  @param  lastTimeTag is a double.
  @return Returns an id.
  @brief Creates and returns a NSMutableArray of the MKPart's MKNotes that
  have time tag values between <i>firstTimeTag</i> and
  <i>lastTimeTag</i>, inclusive.
 
  The MKNotes themselves are not copied.  The sender is responsible for freeing the NSMutableArray. 
  The object returned by this method is useful as the NSMutableArray
  argument in methods such as <b>addNotes:</b> (sent to another
  MKPart), <b>addNotes:timeShift:</b>, and <b>removeNotes:</b>.
*/
- firstTimeTag: (double) firstTimeTag lastTimeTag: (double) lastTimeTag;

/*!
  @param  aNote is an MKNote.
  @return Returns <i>aNote</i>'s old MKPart, or <b>nil</b> if none.
  @brief Moves <i>aNote</i> from its present MKPart to the receiving MKPart. 
	  
  @see -<b>addNoteCopy:</b>, -<b>addNotes:timeShift:</b>, -<b>removeNote:</b>
*/
- (MKPart *) addNote: (MKNote *) aNote;

/*!
  @param  aNote is an MKNote.
  @return Returns the new MKNote.
  @brief Adds a copy of <i>aNote</i> to the MKPart.
 
  Implemented in terms of <b>addNote:</b>.  
  
  @see -<b>addNote:</b>, -<b>addNoteCopies:timeShift:</b>, -<b>removeNote:</b>
*/
- (MKNote *) addNoteCopy: (MKNote *) aNote;

/*!
  @param  aNote is an MKNote.
  @return Returns the MKNote or <b>nil</b> if it isn't found.
  @brief Removes <i>aNote</i> from the MKPart. 
 
  You shouldn't invoke this method if the MKPart has an active MKPartPerformer associated with it. 
  
  @see -<b>removeNotes:</b>, -<b>empty</b>, -<b>addNote</b>
*/
- (MKNote *) removeNote: (MKNote *) aNote; 

/*!
  @param  aNoteList is an NSArray instance.
  @return Returns <b>self</b>.
  @brief Removes all the MKNotes the MKPart has in common with <i>aNoteList</i>.
  @see -<b>removeNote:</b>, -<b>empty</b>, -<b>addNote:</b>, -<b>firstTimeTag:lastTimeTag:</b>
*/
- removeNotes: (NSArray *) aNoteList;

/*!
  @brief Deletes all MKNotes within this part.
 */
- (void) removeAllNotes; 

/*!
  @param  aNoteList is an NSArray instance.
  @param  shift is a double.
  @return  Returns <b>self</b>, or <b>nil</b> if <i>aNoteList</i> is <b>nil</b>.
  @brief Copies each MKNote in <i>aNoteList</i> (which should be a
  NSMutableArray object) adds <i>shift</i> to each new MKNote's time
  tag, then adds the new MKNotes to the MKPart by repeatedly invoking
  <b>addNote:</b>.
 
  The MKNotes in <i>aNoteList</i>  are unaffected. 
  <i>aNoteList</i> is typically generated through MKPart's
  <b>notes</b> or <b>firstTimeTag:lastTimeTag:</b> method.  In this
  way, all or a portion of one MKPart can be copied into another. 
 
  @see  -<b>addNotes:timeShift:</b>, -<b>shift</b>
*/
- addNoteCopies: (NSArray *) aNoteList timeShift: (double) shift;

/*!
  @param  aNoteList is an NSArray instance.
  @param  shift is a double.
  @return Returns <b>self</b>, or <b>nil</b> if <i>aNoteList</i> is <b>nil</b>.
  @brief Moves each MKNote in <i>aNoteList</i> from its present MKPart to the
	  receiving MKPart, adding <i>shift</i> to each MKNote's time tag in
	  the process.
 
  Implemented in terms of <b>addNote:</b>. The
  NSMutableArray argument is typically generated through MKPart's
  <b>notes</b> or <b>firstTimeTag:lastTimeTag:</b> method.  In this
  way, all or a portion of one MKPart can be merged into another. 

  @see  -<b>addNoteCopies:timeShift:</b>, -<b>shift:</b>
*/
- addNotes: (NSArray *) aNoteList timeShift: (double) shift; 

/*!
  @param  shift is a double.
  @return Returns <b>self</b>.
  @brief Shifts the MKPart's contents by adding <i>shift</i> to each of the
  MKNotes' time tags.
 
  Implemented in terms of <b>addNotes:timeShift:</b>.  Notice that this means the MKNotes are
  removed and then readded to the MKPart.  Returns the
  MKPart.
*/
- shiftTime: (double) shift; 

/*!
  @param  scale is a double.
  @return Returns <b>self</b>.
  @brief Scales the MKPart's contents by multiplying <i>scale</i> to each of the MKNotes' time tags and durations.  
*/
- scaleTime: (double) scale;

/*!
  @brief Returns the number of MKNotes in the MKPart (not counting the info MKNote).
  @return Returns an unsigned.
  
  @see -<b>notes</b>, -<b>isEmpty</b>
*/
- (unsigned) noteCount;

/*!
  @param  aNote is an id.
  @return Returns a BOOL.
  @brief Returns <b>YES</b> if the MKPart contains <i>aNote</i>, otherwise <b>returns </b>NO.
  @see -<b>isEmpty</b>, -<b>noteCount</b>
*/
- (BOOL) containsNote: (MKNote *) aNote; 

/*!
  @return Returns a BOOL.
  @brief Returns <b>YES</b> if the MKPart contains any MK_noteDur or MK_noteOn notes.        
*/
- (BOOL) hasSoundingNotes;

/*!
  @return Returns a BOOL.
  @brief Returns YES if the MKPart contains no MKNotes (not including the info MKNote), otherwise returns NO.
  
  @see -<b>noteCount</b>
*/
- (BOOL) isEmpty; 

/*!
  @param  timeTag is a double.
  @return Returns an MKNote instance.
  @brief Returns the (first) MKNote in the MKPart that has a time tag of
  <i>timeTag</i>, or <b>nil</b> if none.
 
  Invokes MKNote's <b>compareNotes:</b> method if the MKPart contains more than one such MKNote.
  
  @see -<b>atOrAfterTime:</b>, -<b>atTime:nth:</b>, -<b>next</b>
*/
- (MKNote *) atTime: (double) timeTag; 

/*!
  @param  timeTag is a double.
  @return Returns an MKNote instance.
  @brief Returns the first MKNote with a time tag equal to or greater than
  <i>timeTag</i>, or <b>nil</b> if none.
  
  @see -<b>atTime:</b>, -<b>atOrAfterTime:nth:</b>, -<b>next</b>
*/
- (MKNote *) atOrAfterTime: (double) timeTag;

/*!
  @param  timeTag is a double.
  @return Returns an MKNote instance.
  @brief Returns the first MKNote with a time tag equal to or less than <i>timeTag</i>, or <b>nil</b> if none.
*/
- (MKNote *) atOrBeforeTime: (double) timeTag;

/*!
  @param  n is an unsigned.
  @return Returns an MKNote instance.
  @brief Returns the <i>n</i>th MKNote (0-based), or <b>nil</b> if <i>n</i>
  is out of bounds (negative or greater than the MKPart's MKNote
  count).
  
  @see -<b>notes</b>, -<b>noteCount</b>, -<b>atTime:</b>
*/
- (MKNote *) nth: (unsigned) n; 

/*!
  @param  timeTag is a double.
  @param  n is an unsigned.
  @return Returns an MKNote instance.
  @brief Returns the <i>n</i>th MKNote (zero-based) in the MKPart that has a
  time tag equal to or greater than <i>timeTag</i>, or <b>nil</b> if none.
  
  @see  -<b>atTime:</b>, -<b>atOrAfterTime:</b>, -<b>next</b>
*/
- (MKNote *) atOrAfterTime: (double) timeTag nth: (unsigned) n; 

/*!
  @param  timeTag is a double.
  @param  n is an unsigned.
  @return Returns an MKNote instance.
  @brief Returns the <i>n</i>th MKNote (zero-based) in the MKPart that has a
  time tag of <i>timeTag</i>, or <b>nil </b>if none.
  
  @see -<b>atTime:</b>, -<b>atOrAfterTime:</b>, -<b>next</b>
*/
- (MKNote *) atTime: (double) timeTag nth: (unsigned) n;

/*!
  @param  aNote is an MKNote instance.
  @return Returns an MKNote instance.
  @brief Returns the MKNote immediately following <i>aNote</i>, or <b>nil</b>
  if <i>aNote</i> isn't a member of the MKPart, or if it's the last
  MKNote in the MKPart.
 
  For greater efficiency, you should create a NSMutableArray from the <b>notes</b> method
  and then iterate over the array.
  
  @see -<b>nth:</b>, -<b>atTime:</b>, -<b>atOrAfterTime:</b>
*/
- (MKNote *) next: (MKNote *) aNote; 

/*!
  @brief Returns the time of the earliest note in the part.

  Returns 0.0 if there are no notes in the part.
  @return Returns a double being the time tag of the first note.
 */
- (double) earliestNoteTime;

/*!
  @param  zone is a NSZone instance.
  @return Returns an id.
  @brief This is the same as <b>copy</b>, but the new MKNote is allocated in <i>aZone</i>.
  
  @see -<b>copy</b>
*/
- copyWithZone: (NSZone *) zone; 

/*!
  @return Returns an id.
  @brief Creates and returns a new MKPart as a copy of the receiving MKPart.
 
 
  The new MKPart contains copies of receiving MKPart's MKNotes
  (including the info MKNote).   The new MKPart is added to the same
  MKScore as the receiving MKPart, but is left unnamed.
  
  @see -<b>copyFromZone:</b>
*/
- copy;

/*!
  @return Returns an NSArray.
  @brief Creates and returns a NSArray of the MKPart's MKNotes in time order.
  
  The MKPart is sorted before the NSArray is created. The MKNotes
  themselves are copied (for the moment, but ideally not).
  The NSArray is autoreleased and should be retained if required.
  
  @see -<b>notesNoCopy</b>, -<b>noteCount</b>
*/
- (NSArray *) notes;

/*!
  @return Returns an id.
  @brief Returns the NSMutableArray object that contains the MKPart's MKNotes.
 
  The NSMutableArray isn't guaranteed to be sorted. The MKNotes are not copied.

  @see -<b>notes</b>, -<b>noteCount</b>
 */
- (NSMutableArray *) notesNoCopy;

/*!
  @return Returns an MKScore.
  @brief Returns the MKScore the MKPart is a member of, or <b>nil</b> if
  none.
  
  @see -<b>addToScore:</b>, -<b>removeFromScore</b>
*/
- (MKScore *) score; 

/*!
  @return Returns an MKNote.
  @brief Returns the MKPart's info MKNote.
  
  @see -<b>setInfoNote:</b>
*/
- (MKNote *) infoNote; 

/*!
  @param aNote is an MKNote.
  @brief Sets the MKPart's info MKNote to a copy of <i>aNote</i>.
 
  The info MKNote can be given information (as
  parameters) that helps define how the MKPart should be interpreted;
  in particular, special MusicKit parameters (more accurately,
  parameter tags) are by convention used in a MKPart info MKNote. 
  Listed below, these parameters pertain to the manner in which the
  MKNotes in the MKPart are synthesized, although as with any MKNote,
  the info MKNote's parameters must be read and applied by some other
  object (or your application) in order for them to have an effect. 
  Keep in mind that the info MKNote is be no means restricted to
  containing only these parameters:

<table border=1 cellspacing=2 cellpadding=0 align=center>
<thead>
<tr>
<th align=center>Parameter Tag</th>
<th align=center>Expected Value</th>
<th align=left>Typical Use</th>
</tr>
</thead>
<tbody>
<tr>
<td align=center>MK_synthPatch</td>
<td align=center>MKSynthPatch subclass</td>
<td align=left>Argument to MKSynthInstrument's <b>setSynthPatchClass:</b> method.</td>
</tr>
<tr>
<td align=center>MK_synthPatchCount</td>
<td align=center>integer</td>
<td align=left>Argument to MKSynthInstrument's <b>setSynthPatchCount:</b> method.</td>
</tr>
<tr>
<td align=center>MK_midiChan</td>
<td align=center>integer</td>
<td align=left>Argument to MKMidi's <b>channelNoteReceiver:</b> method.</td>
</tr>
<tr>
<td align=center>MK_track</td>
<td align=center>integer</td>
<td align=left>Automatically set when a midifile is read into a MKScore.</td>
</tr>
</tbody>
</table>

  The info MKNote is stored separately from the MKPart's main body of MKNotes; 
  methods such as <b>empty</b> don't affect it.  
  
  @see -<b>infoNote</b>
*/
- (void) setInfoNote: (MKNote *) aNote;

/*!
  @brief Return the name of the receiver.
  @return Returns an NSString instance.
 */
- (NSString *) partName;

/*!
  @brief Assigns the name of the receiver.
  @param newPartName An NSString for the new name of the part.
  @brief The part name is used when reading and writing parts to a Scorefile.
 */
- (void) setPartName: (NSString *) newPartName;

- (void) encodeWithCoder: (NSCoder *) aCoder;
- (id) initWithCoder: (NSCoder *) aDecoder;

- (NSString *) description;

@end

#endif
