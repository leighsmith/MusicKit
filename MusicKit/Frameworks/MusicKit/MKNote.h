/*
  $Id$
  Defined In: The MusicKit

  Description:   
    A MKNote object represents a musical sound or event by describing its
    attributes.  This information falls into three categories:
   
    * parameters
    * timing information
    * type information.
   
    Most of the information in a MKNote is in its parameters; a MKNote can
    have any number of parameters.  A parameter consists of an identifier,
    a string name, and a value.  The identifier is a unique integer used
    to catalog the parameter within the MKNote; the MusicKit defines a
    number of parameter identifiers such as MK_freq (for frequency) and
    MK_amp (for amplitude).  The string name is used to identify the
    parameter in a scorefile.  The string names for the MusicKit
    parameters are the same as the identifier names, but without the "MK_"
    prefix.  You can create your own parameter identifiers by passing a
    name to the parTagForName: class method.  This method returns the identifier
    associated with the parameter name, creating it if it doesn't already
    exit.
   
    A parameter's value can be a double, int, NSString object, an MKEnvelope object,
    MKWaveTable object, or other (non-Music Kit) object.  These six
    parameter value types are represented by the following MKDataType
    constants:
   
    * MK_double
    * MK_int
    * MK_string
    * MK_envelope
    * MK_waveTable
    * MK_object
   
    The method you invoke to set a parameter value depends on the type of
    the value.  To set a double value, for example, you would invoke the
    setPar:toDouble: method.  Analogous methods exist for the other data
    types.
   
    You can retrieve the value of a parameter as any of the parameter data
    types.  For instance, the parAsInt: method returns an integer
    regardless of the parameter value's actual type.  The exceptions are
    in retrieving object information: The parAsEnvelope:, parAsWaveTable:,
    and parAsObject: messages return nil if the parameter value isn't the
    specified type.
   
    A MKNote's parameters are significant only if an object that processes
    the MKNote (such as an instance of a subclass of MKPerformer, MKNoteFilter,
    MKInstrument, or MKSynthPatch) accesses and uses the information.
   
    Timing information is used to perform the MKNote at the proper time and
    for the proper duration.  This information is called the MKNote's
    timeTag and duration, respectively.  A single MKNote can have only one
    timeTag and one duration.  Setting a MKNote's duration automatically
    changes its noteType to MK_noteDur, as described below.  TimeTag and
    duration are measured in beats.
   
    A MKNote has two pieces of type information, a noteType and a noteTag.
    A MKNote's noteType establishes its nature; there are six noteTypes:
   
    * A noteDur represents an entire musical note (a note with a duration).
    * A noteOn establishes the beginning of a note.
    * A noteOff establishes the end of a note.
    * A noteUpdate represents the middle of a note (it updates a sounding note).
    * A mute makes no sound.
   
    These are represented by MKNoteType constants:
   
    * MK_noteDur
    * MK_noteOn
    * MK_noteOff
    * MK_noteUpdate
    * MK_mute
   
    The default is MK_mute.
   
    NoteTags are integers used to identify MKNote objects that are part of
    the same musical sound or event; in particular, matching noteTags are
    used to create noteOn/noteOff pairs and to associate noteUpdates with
    other MKNotes.  (A noteUpdate without a noteTag updates all the MKNotes in
    its MKPart.)
  
    The C function MKNoteTag() is provided to generate noteTag values that
    are guaranteed to be unique across your entire application -- you
    should never create a new noteTag except through this function.  The
    actual integer value of a noteTag has no significance (the range of
    noteTag values extends from 0 to 2^BITS_PER_INT).
   
    Mutes can't have noteTags; if you set the noteTag of such a MKNote, it
    automatically becomes a noteUpdate.
   
    MKNotes are typically added to MKPart objects.  A MKPart is a time-ordered
    collection of MKNotes.
  
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2000 The MusicKit Project.
*/
/*
  $Log$
  Revision 1.18  2002/01/09 19:49:43  leighsmith
  Clean up of doco and typed copyParsFrom: parameter

  Revision 1.17  2001/09/07 18:42:25  leighsmith
  Generates lists and moved @class before headerdoc declaration, formatted table and correctly formatted code example, made Music Tables a URL reference, replaced HTML numeric entity with correct symbolic entity for double quotes

  Revision 1.16  2001/09/07 00:15:36  leighsmith
  Made var headerdoc layout conform to the standard

  Revision 1.15  2001/09/06 21:27:47  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.14  2001/08/30 19:05:20  leighsmith
  Merged RTF Class documentation into headerdoc comments

  Revision 1.13  2001/08/09 15:12:51  skotmcdonald
  Shifted MKNote C function declarations outside MKNote interface namespace - no reason for them to be inside, and they are not selectors. Rah consistency.

  Revision 1.12  2001/01/24 21:58:50  skot
  Added note adjustment methods setEndTime, setTimeTagPreserveEndTime

  Revision 1.11  2000/11/25 22:54:14  leigh
  Enforced ivar privacy

  Revision 1.10  2000/10/11 16:56:50  leigh
  Removed unnecessary _parameters redefinition

  Revision 1.9  2000/10/04 06:30:18  skot
  Added endTime method

  Revision 1.8  2000/10/01 06:52:40  leigh
  Changed NXHashTable to NSHashTable, typing _parameter properly.

  Revision 1.7  2000/06/16 23:25:34  leigh
  MKConductor imported for typing of ivars

  Revision 1.6  2000/05/06 00:32:59  leigh
  Converted _binaryIndecies to NSMutableDictionary

  Revision 1.5  2000/04/16 04:20:36  leigh
  Comment cleanup

  Revision 1.4  2000/03/31 00:06:21  leigh
  Adopted OpenStep naming of factory methods

  Revision 1.3  1999/09/24 05:50:27  leigh
  cleaned up documentation.

  Revision 1.2  1999/07/29 01:25:46  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
@class MKPart;
@class MKPerformer;

/*!
  @class MKNote
  @abstract A MKNote object represents a musical sound or event by describing its attributes. 
  @discussion

MKNote objects are containers of musical information.  The amount and
type of information that a MKNote can hold is practically unlimited;
however, you should keep in mind that MKNotes haven't the ability to
act on this information, but merely store it.  It's left to other
objects to read and process the information in a MKNote.  Most of the
other MusicKit classes are designed around MKNote objects, treating
them as common currency.  For example, MKPart objects store MKNotes,
MKPerformers acquire them and pass them to MKInstruments,
MKInstruments read the contents of MKNotes and apply the information
therein to particular styles of realization, and so on.

The information that comprises a MKNote defines the attributes of a
particular musical event.  Typically, an object that uses MKNotes
plucks from them just those bits of information in which it's
interested.  Thus you can create MKNotes that are meaningful in more
than one application.  For example, a MKNote object that's realized as
synthesis on the DSP would contain many particles of information that
are used to drive the synthesis machinery; however, this doesn't mean
that the MKNote can't also contain graphical information, such as how
the MKNote would be rendered when drawn on the screen.  The objects
that provide the DSP synthesis realization (MKSynthPatch objects, as
defined by the MusicKit) are designed to read just those bits of
information that have to do with synthesis, and ignore anything else
the MKNote contains.  Likewise, a notation application would read the
attributes that tell it how to render the MKNote graphically, and
ignore all else.  Of course, some information, such as the pitch and
duration of the MKNote, would most likely be read and applied in both
applications.

Most of the methods defined by the MKNote class are designed to let
you set and retrieve information in the form of <i>parameters</i>.  A
parameter consists of a tag, a name, a value, and a data type:

<ul>
<li> A parameter tag is a unique integer used to catalog the
parameter within the MKNote; the MusicKit defines a number of
parameter tags such as MK_freq (for frequency) and MK_amp (for
amplitude).

<li> The parameter's name is used primarily to identify the
parameter in a scorefile.  The names of the MusicKit parameters are
the same as the tag constants, but without the "MK_" prefix.
You can also use a parameter's name to retrieve its tag, by passing
the name to MKNote's <b>parTagForName:</b> class method.  (As
explained in its descriptions below, it's through this method that you
create your own parameter tags.)  Similarly, you can get a name from a
tag with MKNote's <b>parNameForTag:</b>class method.

<li> A parameter's value can be a <b>double</b>, <b>int</b>, string
(<b>char *</b>), or an object (<b>id</b>).  The method you invoke to
set a parameter value depends on the type of the value.  To set a
<b>double</b> value, for example, you would invoke the
<b>setPar:toDouble:</b> method.  Analogous methods exist for the other
types.  You can retrieve the value of a <b>double</b>-, <b>int</b>-,
or string-valued parameter as any of these three types, regardless of
the actual type of the value.  For example, you can set the frequency
of a MKNote as a <b>double</b>, thus:
	
	<tt>[aNote setPar:MK_freq toDouble:440.0]</tt>

and then retrieve it as an <b>int</b>:
	
	<tt>int freq = [aNote parAsInt:MK_freq]</tt>

The type conversion is done automatically.  

Object-valued parameters are treated differently from the other value types.
The only MusicKit objects that are designed to be used as parameter values
are MKEnvelopes and MKWaveTables (and the MKWaveTable descendants MKPartials
and MKSamples).  Special methods are provided for setting and retrieving
these objects.  Other objects, most specifically, objects of your own classes,
are set through the <b>setPar:toObject:</b> method.  While an instance of any
class may be set as a parameter's value through this method, you should note
well that only those objects that respond to the <b>writeASCIIStream:</b> and
<b>readASCIIstream:</b> messages can be written to and read from a scorefile. 
None of the MusicKit classes implement these methods and so their instances
can't be written to a scorefile as parameter values (MKEnvelopes and
MKWaveTables are written and read through a different mechanism).

<li> The parameter's data type is set when the parameter's value is
set; thus the data type is either a <b>double</b>, <b>int</b>, string,
MKEnvelope, MKWaveTable, or (other) object.  These are represented by
constants, as given in the description of <b>parType:</b>, the method
that retrieves a parameter's data type.
</ul>

A parameter is said to be present within a MKNote once its value has
been set.  You can determine whether a parameter is present in one of
four ways:

<ul>
<li> The easiest way is to invoke the boolean<b></b>method<b>
isParPresent:</b>, passing the parameter tag as the argument.  An
equivalent C function, <b>MKIsNoteParPresent()</b> is also provided
for greater efficiency.

<li> At a lower lever, you can invoke the <b>parVector:</b> method
to retrieve one of a MKNote's &ldquo;parameter bit vectors,"
integers that the MKNote uses internally to indicate which parameters
are present.  You query a parameter bit vector by masking it with the
parameter's tag:
	
<tt>
// A MKNote may have more then one bit vector to accommodate all<br>
// its parameters.<br>

int parVector = [aNote parVector:(MK_amp/32)];
	
// If MK_amp is present, the predicate will be true.<br>
if (parVector &amp; (1 &lt;&lt; (MK_amp % 32)))
</tt>

<li> If you plan on retrieving the value of the parameter after
you've checked for the parameter's presence, then it's generally more
efficient to go ahead and retrieve the value and <i>then</i> determine
if the parameter is actually set by comparing its value to the
appropriate parameter-not-set value, as given below:
	
<table border=1 cellspacing=2 cellpadding=0 align=center>
<thead>
<tr>
<th align=left>Retrieval type</th>
<th align=left>No-set value</th>
</tr>
</thead>
<tbody>
<tr>
<td align=left>int</td>
<td align=left>MAXINT</td>
</tr>
<tr>
<td align=left>double</td>
<td align=left>MK_NODVAL (but see below)</td>
</tr>
<tr>
<td align=left>NSString</td>
<td align=left>&#64;"" (this needs checking - LMS)</td>
</tr>
<tr>
<td align=left>id</td>
<td align=left><b>nil</b></td>
</tr>
</tbody>
</table>

Unfortunately, you can't use MK_NODVAL in a simple comparison
predicate. To check for this return value, you must call the 
in-line function <b>MKIsNoDVal()</b>; the function returns 0 if
its argument is MK_NODVAL and nonzero if not:
	
<tt>
// Retrieve the value of the amplitude parameter.<br>
double amp = [aNote parAsDouble:MK_amp];<br>
	
// Test for the parameter's existence.<br>
if (!MKIsNoDVal(amp))<br>
   ... // do something with the parameter<br>
</tt>

<li> If you're looking for and processing a large number of
parameters in one block, then you should make calls to the
<b>MKNextParameter()</b> C function, which returns the values of a
MKNote's extant parameters only.  See the function's description in
Chapter 2 for more details.
</ul>

A MKNote has two special timing attributes:  A MKNote's time tag
corresponds, conceptually, to the time during a performance that the
MKNote is performed.   Time tags are set through the
<b>setTimeTag:</b> method.  The other timing attribute is the MKNote's
duration, a value that indicates how long the MKNote will endure once
it has been struck. It's set through <b>setDur:</b>. A single MKNote
can have only one time tag and one duration.  Keep in mind, however,
that not all MKNotes need a time tag and a duration.  For example, if
you realize a MKNote by sending it directly to an MKInstrument, then
the MKNote's time tag - indeed, whether it even has a time tag - is
of no consequence; the MKNote's performance time is determined by
when the MKInstrument receives it (although see the
MKScorefileWriter, MKScoreRecorder, and MKPartRecorder class
descriptions for alternatives to this edict).  Similarly, a MKNote
that merely initiates an event, relying on a subsequent MKNote to
halt the festivities, as described in the discussion of <i>note
types</i>, below, doesn't need and actually mustn't be given a
duration value.

During a performance, time tag and duration values are measured in
time units called <i>beats.</i>The size of a beat<i> </i>  is
determined by the tempo of the MKNote's MKConductor.  You can set the
MKNote's conductor directory with the method <b>setConductor:</b>.
However, if  the MKNote is in the process of being sent by a
MKPerformer (or MKMidi), the MKPerformer's MKConductor is used
instead.   Hence, MKNote's <b>conductor</b> method returns the
MKPerformer's MKConductor if the MKNote is in the process of being
sent by a MKPerformer, or the MKNote's conductor otherwise.  If no
MKConductor is set, then its MKConductor is the
<i>defaultConductor</i>, which has a default (but not immutable)
tempo of 60.0 beats per minute.

Keep in mind that if you send a MKNote directly to an MKInstrument, then
the MKNote's time tag is (usually) ignored, as described above, but
its duration may be considered and employed by the MKInstrument.

A MKNote has a <i>note type</i> that casts it into one of five roles: 

<ul>
<li>	A noteDur represents an entire musical note (a note with a duration).</li>
<li>	A noteOn establishes the beginning of a note.</li>
<li>	A noteOff establishes the end of a note.</li>
<li>	A noteUpdate represents the middle of a note (it updates a sounding note).</li>
<li>	A mute makes no sound.</li>
</ul>

Only noteDurs may have duration values; the very act of setting a
MKNote's duration changes it to a noteDur.

You match the two MKNotes in a noteOn/noteOff pair by giving them the
same <i>note tag</i> value; a note tag is an integer that identifies
two or more MKNotes as part of the same musical event or phrase.  In
addition to coining noteOn/noteOff pairs, note tags are used to
associate a noteUpdate with a noteDur or noteOn that's in the process
of being performed.  The C function <b>MKNoteTag()</b> is provided to
generate note tag values that are guaranteed to be unique across your
entire application - you should never create a new note tag except
through this function. 

Instead of or in addition to being actively realized, a MKNote object
can be stored.  In a running application, MKNotes are stored within
MKPart objects through the <b>addToPart:</b> method.  A MKNote can
only be added to one MKPart at a time; adding it to a MKPart
automatically removes it from its previous MKPart.  Within a MKPart
object, MKNotes are sorted according to their time tag values.

For long-term storage, MKNotes can be written to a scorefile.  There
are two "safe" ways to write a scorefile: You can add a
MKNote-filled MKPart to a MKScore and then write the MKScore to a
scorefile, or you can send MKNotes during a performance to a
MKScorefileWriter MKInstrument.  The former of these two methods is
generally easier and more flexible since it's done statically and
allows random access to the MKNotes within a MKPart.  The latter
allows MKNote objects to be reused since the file is written
dynamically; it also lets you record interactive performances.

You can also write individual MKNotes in scorefile format to an open
stream by sending <b>writeScorefileStream:</b> to the MKNotes.  This
can be convenient while debugging, but keep in mind, however, that the
method is designed primarily for use by MKScore and MKScorefileWriter
objects; if you write MKNotes directly to a stream that's open to a
file, the  file isn't guaranteed to be recognized by methods that
read scorefiles, such as MKScore's <b>readScorefile:</b>.

MKNote are automatically created by the MusicKit in a number of
circumstances, such as when reading a MKScorefile.  The function
<b>MKSetNoteClass()</b> allows you to specify that your own subclass
of MKNote be used when MKNotes are automatically created.  You
retrieve the MKNote class with <b>MKGetNoteClass()</b>.

*/
#ifndef __MK_Note_H___
#define __MK_Note_H___
#import <Foundation/Foundation.h>

#import <Foundation/NSObject.h>

#import "MKConductor.h"

 /* NoteTag allocation. */
extern unsigned MKNoteTag(void);
extern unsigned MKNoteTags(unsigned n);

 /* dB to amp conversion. E.g. MKdB(-60) returns ca. .001 and MKdB(0.0) returns
  * 1.0. */
extern double MKdB(double dB);          

 /* Maps MIDI value (such as velocity) onto an amplitude scaler such that 
    64->1.0, 127->10.0, and 0->0. This is primarily designed for scaling 
    amplitude by a value derived from MIDI velocity. */
extern double MKMidiToAmp(int midiValue);

 /* Same as above, but uses sensitivity to control how much effect 
    midiValue has.  */
extern double MKMidiToAmpWithSensitivity(int midiValue, double sensitivity);

 /* Maps an amplitude scaler onto velocity such that
    MKAmpToMidi(MKMidiToAmp(x)) == x
    */
extern int MKAmpToMidi(double amp);

 /* Maps MIDI controller values (e.g. volume pedal) onto an amplitude scaler 
    such that 64->0.1, 127->1.0, and 0->0. */
extern double MKMidiToAmpAttenuation(int midiValue);

 /* Same as above, but uses sensitivity to control how much effect 
    midiValue has.  */
extern double MKMidiToAmpAttenuationWithSensitivity(int midiValue, 
						    double sensitivity);

 /* Maps an amplitude scaler onto velocity such that
    MKAmpAttenuationToMidi(MKMidiToAmpAttenuation(x)) == x
    */
extern int MKAmpAttenuationToMidi(double amp);

typedef enum _MKNoteType {
    MK_noteDur = 257, MK_noteOn, MK_noteOff, MK_noteUpdate, MK_mute} 
MKNoteType;

extern int MKHighestPar(void);
 /* Returns the parameter tag of the highest numbered parameter.  This 
  * can be used, for example, to print the names of all known parameters
  * as follows:
  *
  * for (i=0; i<=MKHighestPar(); i++) printf([MKNote parNameForTag:i]);
  */

#import "params.h"

#define BITS_PER_INT 32
#define MK_MKPARBITVECTS ((((int)MK_appPars-1)/ BITS_PER_INT)+1)

typedef enum _MKDataType {     /* Data types supported by MKNotes */
    MK_noType = ((int)MK_sysReset + 1),
    MK_double,  
    MK_string,
    MK_int,
    MK_object,
    MK_envelope, 
    MK_waveTable}
MKDataType;

@interface MKNote : NSObject
{
/*! @var noteType The MKNote's noteType. */
    MKNoteType noteType;
/*! @var noteTag The MKNote's noteTag. */
    int noteTag;
/*! @var performer MKPerformer object that's currently sending the MKNote in performance, if any. */
    MKPerformer *performer;   
/*! @var part The MKPart that this MKNote is a member of, if any. */
    MKPart *part;
/*! @var timeTag Time tag, if any, else MK_ENDOFTIME. */
    double timeTag;
/*! @var conductor MKConductor to use if performer is nil. If performer is not nil, uses [performer conductor]. */
    MKConductor *conductor;  

@private
    NSHashTable *_parameters;       /* Set of parameter values. */
    unsigned _mkPars[MK_MKPARBITVECTS]; /* Bit vectors specifying presence of Music Kit parameters. */
    unsigned *_appPars; /* Bit-vector for application-defined parameters. */
    short _highAppPar; /* Highest bit in _appPars (0 if none). */
    /* _orderTag disambiguates simultaneous notes. If it's negative,
       it means that the MKNote is actually slated for deletion. In this case,
       the ordering is the absolute value of _orderTag. */
    int _orderTag;
} 

/*!
  @method initWithTimeTag:
  @param  aTimeTag is a double in seconds.
  @discussion Sets timeTag as specified and sets type to mute.
              If aTimeTag is MK_ENDOFTIME, the timeTag isn't set.
              Subclasses should send [super initWithTimeTag:aTimeTag] if it overrides 
              this method. 
*/ 
- initWithTimeTag:(double) aTimeTag;

/*!
  @method init
  @result Returns an id.
  @discussion Initializes a MKNote that was created through <b>allocFromZone:</b>.
              For example:
              	
              <tt>id aNote = [MKNote allocFromZone:aZone];
              [aNote init];</tt>
              
              A newly initialized MKNote's note type is mute.  Returns <b>self</b>.

              Same as [self initWithTimeTag:MK_ENDOFTIME].
              See also:  -<b>init:</b>
*/
- init;

/*!
  @method dealloc 
  @discussion Removes the receiver from its MKPart, if any, and then frees the
              receiver and its contents.  The contents of object-valued,
              envelope-valued and wavetable-valued parameters aren't
	      freed.  
*/
- (void)dealloc; 

/*! 
  @method copyWithZone:
  @param  zone is an NSZone.
  @discussion Creates and returns a new MKNote object as a copy of the receiver.  The
              receiver's parameters, timing information, noteType, and noteTag are
	      copied into the new MKNote.  Object-valued parameters are shared by the
	      two MKNotes.  The new MKNote's MKPart is set to nil.  
*/
- copyWithZone:(NSZone *)zone; 

/*!
  @method split::
  @param  aNoteOn is an id *.
  @param  aNoteOff is an id *.
  @result Returns an id.
  @discussion This method splits a noteDur into a noteOn/noteOff pair, as
              described below.  The new MKNotes are returned by reference in the
              arguments.  The noteDur itself is left unchanged.  If the receiving
              MKNote isn't a noteDur, this does nothing and returns <b>nil</b>,
              otherwise it returns <b>self</b>. 
              
              The receiving MKNote's MK_relVelocity parameter, if
              present, is copied into the noteOff.  All other
              parameters are copied into (or, in the case of
              object-valued parameters, referenced by) the noteOn.
              The noteOn takes the receiving MKNote's time tag value;
              the noteOff's time tag is that of the MKNote plus its
              duration.  If the receiving MKNote has a note tag, it's
              copied into the noteOn and noteOff; otherwise a new note
              tag is generated for them.  The new MKNotes are added to
              the receiving MKNote's MKPart, if any.
              
              Keep in mind that if while this method replicates the
	      noteDur within the noteOn/noteOff pair, it doesn't
	      replace the former with the latter.  To do this, you
	      must free the noteDur yourself.  
*/
- split:(id *)aNoteOn :(id *)aNoteOff; 
 /* 
  * If receiver isn't a noteDur, returns nil.  Otherwise, creates a noteOn
  * and a noteOff, splits the information in the receiver between the two
  * of them (as explained below), and returns the new MKNotes by reference
  * in the arguments.  The method itself returns the receiver, which is
  * neither freed nor otherwise affected.
  * 
  * All the receiver's parameters are copied into the noteOn except for
  * MK_relVelocity which, if present, is copied into the noteOff.  The
  * noteOn takes the receiver's timeTag while the noteOff's timeTag is
  * that of the receiver plus its duration.  If the receiver has a
  * noteTag, it's copied into both new MKNotes; otherwise a new noteTag is
  * generated for them.  The new MKNotes are added to the receiver's MKPart,
  * if any.
  * 
  * The new noteOn shares the receiver's object-valued parameters.
  */


/*!
  @method performer
  @result Returns an id.
  @discussion Returns the MKPerformer that most recently performed the MKNote. 
              This is provided, primarily, as part of the implementation of the
              <b>conductor</b> method. 
              
              See also:  -<b>conductor</b>
*/
- performer; 

/*!
  @method part
  @result Returns an id.
  @discussion Returns the MKPart that contains the MKNote, or <b>nil</b> if none. 
              By default, a MKNote isn't contained in a MKPart.
              
              
              See also:  -<b>addToPart:</b>, -<b>removeFromPart</b>
*/
- part; 

/*!
  @method conductor
  @result Returns an id.
  @discussion If the MKNote is being sent by a MKPerformer (or MKMidi), returns the
              MKPerformer's MKConductor. Otherwise, if conductor was set with
              <b>setConductor:</b>, returns the <i>conductor</i> instance
              variable.  Otherwise returns the <i>defaultConductor</i>.  A
              MKNote's MKConductor is used, primarily, by MKInstrument objects that
              split noteDurs into noteOn/noteOff pairs; performance of the noteOff
              is scheduled with the MKConductor that's returned by this method.
              
              SEE ALSO: -<b>performer</b>
*/
- conductor; 

/*!
  @method setConductor:
  @param  newConductor is an id.
  @result Returns an id.
  @discussion Sets <i>conductor</i> instance variable.  Note that <i>conductor</i>
              is not archived, nor is it saved when a MKNote is added to a MKPart
              - it is used only in performance.   Note that <b>-setConductor</b>
              is called implicitly when a MKNote is copied with the <b>copy</b>
              method.   Be careful not to free a MKConductor while leaving a
              dangling reference to it in a MKNote!
              
              See also:  -<b>conductor</b>
*/
-setConductor:aConductor; 

/*!
  @method addToPart:
  @param  aPart is an id.
  @result Returns an id.
  @discussion Removes the MKNote from the MKPart that it's currently a member of
              and adds it to <i>aPart</i>.  Returns the MKNote's old MKPart, if
              any. 
              
              This method is equivalent to MKPart's <b>addNote:</b> method.
              
              SEE ALSO: -<b>part</b>, -<b>removeFromPart</b>
*/
- addToPart:aPart; 

/*!
  @method timeTag
  @result Returns a double.
  @discussion Returns the MKNote's time tag.  If the time tag isn't set,
              MK_ENDOFTIME is returned.  Time tag values are used to sort the
              MKNotes within a MKPart.
              
              See also:   -<b>setTimeTag:</b>
*/
-(double)  timeTag; 

/*!
  @method setTimeTag:
  @param  newTimeTag is a double.
  @result Returns a double.
  @discussion Sets the MKNote's time tag to <i>newTimeTag</i> or 0.0, whichever is
              greater (a time tag can't be negative) .  The old time tag value is
              returned; a return value of MK_ENDOFTIME indicates that the time tag
              hadn't been set.  Time tags are used to sort the MKNotes within a
              MKPart; if you change the time tag of a MKNote that's been added to
              a MKPart, the MKNote is automatically resorted.
              
              See also:   -<b>timeTag</b>, -<b>addToPart:</b>, -<b>sort </b>(MKPart)
*/
-(double)  setTimeTag:(double) newTimeTag; 
 /* 
  * Sets the receiver's timeTag to newTimeTag and returns the old timeTag,
  * or MK_ENDOFTIME if none.  If newTimeTag is negative, it is clipped to
  * 0.0.
  * 
  * If the receiver is a member of a MKPart, it's first removed from the
  * MKPart, its timeTag is set, and then it's re-added to the MKPart.  This
  * ensures that the receiver's position within its MKPart is correct.  
  */

-(double)  setTimeTagPreserveEndTime:(double) newTimeTag;
/*
 * Sets the receiver's timeTag to newTimeTag and returns the old timeTag,
 * or MK_ENDOFTIME if none.  If newTimeTag is negative, it's clipped to
 * 0.0. If newTimeTag is greater than the endTime, it is clipped to endTime.
 *
 * If the receiver is a member of a MKPart, it's first removed from the
 * MKPart, its timeTag is set, and then it's re-added to the MKPart.  This
 * ensures that the receiver's position within its MKPart is correct.
 *
 * Duration is changed to preserve the endTime of the note
 *
 * Note: ONLY works for MK_noteDur type notes! MK_NODVAL returned otherwise.
 */


/*!
  @method removeFromPart
  @result Returns an id.
  @discussion Removes the MKNote from its MKPart.  Returns the MKPart, or
              <b>nil</b> if none.
              
              See also:  -<b>addToPart:</b>, -<b>part</b>
*/
- removeFromPart; 

/*!
  @method compare:
  @param  aNote is an id.
  @result Returns an int.
  @discussion Returns a value that indicates which of the receiving MKNote and the
              argument MKNote would appear first if the two MKNotes were sorted
              into the same MKPart:
              
              <ul>
              <li>	-1 indicates that the receiving MKNote is first.
              <li>	1 means that the argument, <i>aNote</i>, is first.
              <li>	0 is returned if the receiving MKNote and <i>aNote</i> are the same object.
              </ul>
              
              Keep in mind that the two MKNotes needn't actually be
              members of the same MKPart, nor must they be members of
              MKParts at all.  Naturally, the comparison is judged
              first on the relative values of the two MKNotes' time
              tags; changing one or both of the MKNotes' time tags
              invalidates the result of a previous invocation of this
              method.
*/
-(int)  compare:aNote; 
 /* 
  * Compares the receiver with aNote and returns a value as follows:
  * 
  * * If the receiver's timeTag < aNote's timeTag, returns -1.
  * * If the receiver's timeTag > aNote's timeTag, returns 1.
  * 
  * If the timeTags are equal, the comparison is by order in the part.
  * 
  * If the MKNotes are both not in parts or are in different parts, the
  * result is indeterminate.
  * 
  */


/*!
  @method noteType
  @result Returns a MKNoteType.
  @discussion Returns the MKNote's note type, one of MK_noteDur, MK_noteOn,
              MK_noteOff, MK_noteUpdate, or MK_mute.  The note type describes the
              character of the MKNote, whether it represents an entire musical
              note (or event), the beginning, middle, or end of a note, or no note
              (no sound). A newly created MKNote is a mute.  A MKNote's note type
              can be set through <b>setNoteType:</b>, although <b>setDur:</b> and
              <b>setNoteTag:</b> may also change it as a side effect.
              
              See also:  -<b>setNoteType:</b>, -<b>setDur:</b>, -<b>setNoteTag:</b>
*/
-(MKNoteType ) noteType; 

/*!
  @method setNoteType:
  @param  newNoteType is a MKNoteType.
  @result Returns <b>self</b>, or <b>nil</b> if <i>newNoteType</i> isn't a valid note type.
  @discussion Sets the MKNote's note type to <i>newNoteType</i>, one
              of:
              
              <ul>
              <li>	MK_noteDur; represents an entire musical note.
              <li>	MK_noteOn; represents the beginning of a note. 
              <li>	MK_noteOff; represents the end of a note. 
              <li>	MK_noteUpdate; represents the middle of a note. 
              <li>	MK_mute; makes no sound.
              </ul>
              
              You should keep in mind that the <b>setDur:</b> method
              automatically sets a MKNote's note type to MK_noteDur;
              <b>setNoteTag:</b> changes mutes into noteUpdates.
              
              See also: -<b>noteType</b>, -<b>setNoteTag:</b>, -<b>setDur:</b> 
*/
- setNoteType:(MKNoteType )newNoteType; 

/*!
  @method setDur:
  @param  value is a double.
  @result Returns a double.
  @discussion Sets the MKNote's duration to <i>value</i> beats and sets its note
              type to MK_noteDur.  If <i>value</i> is negative the duration isn't
              set, the note type isn't changed, and MK_NODVAL is returned (use the
              function <b>MKIsNoDVal()</b> to check for MK_NODVAL); otherwise
              returns <i>value</i>.
              
              See also:  -<b>dur</b>, -<b>conductor</b>
*/
-(double)  setDur:(double) value; 
 /* 
  * Sets the receiver's duration to value beats and sets its noteType to
  * MK_noteDur.  If value is negative the duration isn't set (but the
  * noteType is still set to noteDur).  Always returns value.  */


/*!
  @method dur
  @result Returns a double.
  @discussion If the MKNote has a duration, returns the duration, or MK_NODVAL if
              it isn't set (use the function <b>MKIsNoDVal()</b> to check for
              MK_NODVAL).    This method always returns MK_NODVAL for noteOn,
              noteOff and noteUpdate MKNotes.  It returns a valid dur (if one has
              been set) for noteDur MKNotes.  For mute MKNotes, it returns a valid
              value if the MKNote has an <b>MK_restDur</b> parameter, otherwise it
              returns MK_NODVAL.  This allows you to specify rests with
              durations.
              
              See also:  -<b>setDur:</b>
*/
-(double)  dur; 

- (double) setEndTime: (double) newEndTime;
 /*
  * Returns the receiver's old end time (duration + timeTag) and sets duration 
  * to newEndTime - timeTag, or MK_NODVAL if not a MK_noteDur or MK_mute.
  */

- (double) endTime;
 /* 
  * Returns the receiver's end time (duration + timeTag), or MK_NODVAL if
  * not a MK_noteDur or MK_mute. */


/*!
  @method noteTag
  @result Returns an int.
  @discussion Return the MKNote's note tag, or MAXINT if it isn't
              set.
              
              See also:  -<b>setNoteTag:, MKNoteTag()</b>
*/
-(int)  noteTag; 

/*!
  @method setNoteTag:
  @param  newTag is an int.
  @result Returns an id.
  @discussion Sets the MKNote's note tag to <i>newTag</i>; if the note type is
              <b>MK_mute it's changed to MK_noteUpdate.  Returns
              self</b>.
              
              MKNote tags are used to associate different MKNotes with
              each other, thus creating an identifiable (by the note
              tag value) "Note stream." For example, you
              create a noteOn/noteOff pair by giving the two MKNotes
              identical note tag values.  Also, you can associate any
              number of noteUpdates with a single noteDur, or with a
              noteOn/noteOff pair, through similarly matching note
              tags.  While note tag values are arbitrary, they should
              be unique across an entire application; to ensure this,
              you should never create noteTag values but through the
              <b>MKNoteTag()</b> C function.
              
              See also: -<b>noteTag, MKNoteTag()</b> 
*/
- setNoteTag:(int) newTag; 

/*!
  @method removeNoteTag
  @result Returns an id.
  @discussion Removes the noteTag, if any. Same as [self setNoteTag:MAXINT].
*/
- removeNoteTag;

/*!
  @method parTagForName:
  @param  aName is a NSString.
  @result Returns an int.
  @discussion Returns the integer that identifies the parameter named
              <i>aName</i>.  If the named parameter doesn't have an identifier,
              one is created and thereafter associated with the parameter.            
              
              SEE ALSO: -<b>setPar:toDouble:</b>(etc), -<b>isParPresent:</b>, -<b>parNameForTag:</b>  
*/
+(int)  parTagForName:(NSString *) aName; 

/*!
  @method parNameForTag:
  @param  aTag is an int.
  @result Returns a NSString.
  @discussion Returns the name that identifies the parameter tagged <i>aTag</i>. 
              For example [MKNote parNameForTag:MK_freq] returns
	      "freq". If the parameter number given is not a valid parameter number,
              returns "".  Note that the string is not copied. 
                            
              SEE ALSO: -<b>setPar:toDouble:</b>(etc), -<b>
              isParPresent:</b> , -<b>parNameForTag:</b> 
*/
+(NSString *) parNameForTag:(int)aPar;

/*!
  @method setPar:toDouble:
  @param  parameterTag is an int.
  @param  aDouble is a double.
  @result Returns self.
  @discussion Sets the value of the parameter identified by <i>parameterTag</i> to
              <i>aDouble</i>, and sets its data type to MK_double.   If
              <i>aDouble</i> is the special value MK_NODVAL, this method is the
              same as <b>[self removePar:</b><i>parameterTag</i><b>].</b>  Returns
              <b>self</b>.
              
              See also: +<b>parTagForName:</b>, +<b>
              parNameForTag:</b>, -<b>parType:</b>, -<b>
              isParPresent:</b>, -<b>parAsDouble:</b> 
*/
- setPar:(int) par toDouble:(double) value; 

/*!
  @method setPar:toInt:
  @param  parameterTag is an int.
  @param  anInteger is an int.
  @result Returns an id.
  @discussion Sets the value of the parameter identified by <i>parameterTag</i> to
              <i>anInteger</i>, and sets its data type to MK_int.  If
              <i>anInteger</i>is MAXINT, this method is the same as  <b>[self
              removePar:</b><i>parameterTag</i><b>].</b>  Returns
              <b>self</b>.
              
              See also:   +<b>parTagForName:</b>, +<b>
	      parNameForTag:</b>, -<b>parType:</b>, -<b>
	      isParPresent:</b>, -<b>parAsInteger:</b> 
*/
- setPar:(int) par toInt:(int) value; 

/*!
  @method setPar:toString:
  @param  parameterTag is an int.
  @param  aString is a char *.
  @result Returns <b>self</b>.
  @discussion Sets the value of the parameter identified by <i>parameterTag</i> to
              <i>aString</i>, and sets its data type to MK_string.  If
              <i>aString</i>is NULL or "", this method is the same as 
              <b>[self removePar:</b><i>parameterTag</i><b>].</b>
              
              See also: +<b>parTagForName:</b>, +<b>parNameForTag:</b>, -<b>parType:</b>, -<b>isParPresent:</b>,
                        -<b>parAsString:</b>
*/
- setPar:(int) par toString:(NSString *) value; 

/*!
  @method setPar:toEnvelope:
  @param  parameterTag is an int.
  @param  anEnvelope is an id.
  @result Returns an id.
  @discussion Sets the value of the parameter identified by <i>parameterTag</i> to
              <i>anEnvelope</i>, and sets its data type to MK_envelope.  If
              <i>anEnvelope</i>is <b>nil</b> , this method is the same as <b>[self
              removePar:</b><i>parameterTag</i><b>].</b>  Returns <b>self</b>.
              
              See also: +<b>parTagForName:</b>, +<b>parNameForTag:</b>, -<b>parType:</b>, -<b>isParPresent:</b>,
                        -<b>parAsEnvelope:</b>
*/
- setPar:(int) par toEnvelope:envObj; 

/*!
  @method setPar:toWaveTable:
  @param  parameterTag is an int.
  @param  aWaveTable is an id.
  @result Returns an id.
  @discussion Sets the value of the parameter identified by <i>parameterTag</i> to
              <i>aWaveTable</i>, and sets its data type to MK_waveTable.  If
              <i>aWaveTable</i>is <b>nil</b> , this method is the same as <b>[self
              removePar:</b><i>parameterTag</i><b>].</b> Returns
              <b>self</b>.
              
              See also:   +<b>parTagForName:</b>, +<b>parNameForTag:</b>, -<b>parType:</b>, -<b>isParPresent:</b>, -<b>parAsWaveTable:</b>
*/
- setPar:(int) par toWaveTable:waveObj; 
 /* 
  * Sets the parameter par to waveObj, a MKWaveTable object.
  * Returns the receiver.  
  */

/*!
  @method setPar:toObject:
  @param  parameterTag is an int.
  @param  anObject is an id.
  @result Returns an id.
  @discussion Sets the value of the parameter identified by <i>parameterTag</i> to
              <i>anObject</i>, and sets its data type to MK_object.  If
              <i>anObject</i>is <b>nil</b>,  this method is the same as <b>[self
              removePar:</b><i>parameterTag</i><b>].</b>  Returns
              <b>self</b>.
              
              While you can use this method to set the value of a
              parameter to any object, it's designed, principally, to
              allow you to use an instance of one of your own classes
              as a parameter value.  If you want the object to be
              written to and read from a scorefile, it must respond to
              the messages <b>writeASCIIStream:</b> and
              <b>readASCIIStream:</b>.  While response to these
              messages isn't a prerequisite for an object to be used
              as the argument to this method, if you try to write a
              MKNote that contains a parameter that doesn't respond to
              <b>writeASCIIStream:</b>, an error is generated.
              
              Note that unless you really need to write your object to
              a Scorefile, you are better off saving your object using
              the NXTypedStream archiving mechanism.
              
              If you're setting the value as an MKEnvelope or MKWaveTable
              object, you should use the <b>setPar:toEnvelope:</b> or
              <b>setPar:toWaveTable:</b> method, respectively.
              
              See also: +<b>parTagForName:</b>, +<b>parNameForTag:</b>, -<b>parType:</b>, -<b>isParPresent:</b>, -<b>parAsObject:</b> 
*/
- setPar:(int) par toObject:anObj; 
 /* 
  * Sets the parameter par to the object anObj.  The object's class must
  * implement the methods writeASCIIStream: and readASCIIStream: (in order
  * to be written to a scorefile).  An object's ASCII representation
  * shouldn't contain the character ']'.  Returns the receiver.
  * 
  * None of the Music Kit classes implement readASCIIStream: or
  * writeASCIIStream: so you can't use this method to set a parameter to a
  * Music Kit object (you should invoke the setPar:toEnvelope: or
  * setPar:toWaveTable: to set the value of a parameter to an MKEnvelope or
  * MKWaveTable object).  This method is provided to support extensions to the 
  * MusicKit allowing you to set the value of a parameter to an instance of 
  * your own class.
  */

/*!
  @method parAsDouble:
  @param  parameterTag is an int.
  @result Returns a double.
  @discussion Returns a <b>double</b> value converted from the value of the
              parameter <i>identified by parameterTag</i>.  If the parameter isn't
              present or if its value is an object, returns MK_NODVAL (use the
              function <b>MKIsNoDVal()</b> to check for MK_NODVAL). You should use
              the <b>freq</b> method if you're want to retrieve the frequency of
              the MKNote.
              
              See also: <b>MKGetNoteParAsDouble()</b>, -<b>
              setPar:toDouble:</b> (etc), -<b>parType:</b>, -<b>
              isParPresent:</b> 
*/
-(double)  parAsDouble:(int) par; 
 /* 
  * Returns a double value converted from the value of the parameter par.
  * If the parameter isn't present, returns MK_NODVAL. 
  * (Use MKIsNoDVal() to check for MK_NODVAL.)
  */


/*!
  @method parAsInt:
  @param  parameterTag is an int.
  @result Returns an int.
  @discussion Returns an <b>int</b> value converted from the value of the
              parameter identified by  <i>parameterTag</i>.  If the parameter
              isn't present, or if its value is an object, returns
              MAXINT.
              
              See also:  <b>MKGetNoteParAsInt()</b>, -<b>setPar:toDouble:</b> (etc), -<b>parType:</b>, <b>isParPresent:</b>
*/
-(int)  parAsInt:(int) par; 
 /* 
  * Returns an int value converted from the value of the parameter par.
  * If the parameter isn't present, returns MAXINT.  */

/*!
  @method parAsString:
  @param  parameterTag is an int.
  @result Returns an NSString.
  @discussion Returns a <b>string converted from a copy of the value of the
              parameter identified by </b><i>parameterTag</i>.  If the parameter
              isn't present, or if its value is an object, returns an empty
              string.
              
              See also: <b>MKGetNoteParAsString()</b>, -<b>setPar:toDouble:</b> (etc),
                        -<b>parType:</b>, <b>isParPresent:</b>
*/
-(NSString *)  parAsString:(int) par; 
 /* 
  * Returns a char * converted from a copy of the value of the parameter
  * par.  If the parameter isn't present, returns a copy of "".  */

/*!
  @method parAsStringNoCopy:
  @param  parameterTag is an int.
  @result Returns an NSString.
  @discussion Returns a <b>string converted from a the value of the parameter
              identified by</b><i> parameterTag</i>.  If the parameter was set as
              a string, then this returns a pointer to the actual string itself;
              you should neither delete nor alter the value returned by this
              method.  If the parameter isn't present, or if its value is an
              object, returns an empty string.
              
              See also:  <b>MKGetNoteParAsStringNoCopy()</b>, -<b>
              setPar:toDouble:</b> (etc), -<b>parType:</b>, -<b>
              isParPresent:</b>
*/
-(NSString *)  parAsStringNoCopy:(int) par; 
 /* 
  * Returns a char * to the value of the parameter par.  You shouldn't
  * delete or alter the value returned by this method.  If the parameter
  * isn't present, returns "".  */

/*!
  @method parAsEnvelope:
  @param  parameterTag is an int.
  @result Returns an id.
  @discussion Returns the MKEnvelope value of <i>parameterTag</i>.  If the parameter
              isn't present or if its value isn't an MKEnvelope, returns
              <b>nil</b>.
              
              See also:  <b>MKGetNoteParAsEnvelope()</b>, -<b>setPar:toDouble:</b> (etc), -<b>parType:</b>, -<b>isParPresent:</b>
*/
- parAsEnvelope:(int) par; 
 /* 
  * Returns the MKEnvelope value of par.  If par isn't present or if its
  * value wasn't set as envelope type, returns nil.  */

/*!
  @method parAsWaveTable:
  @param  parameterTag is an int.
  @result Returns an id.
  @discussion Returns the MKWaveTable value of the parameter identified by 
              <i>parameterTag</i>.  If the parameter isn't present, or if it's
              value isn't a MKWaveTable, returns <b>nil</b>.
*/
- parAsWaveTable:(int) par; 
 /* 
  * Returns the MKWaveTable value of par.  If par isn't present or if it's
  * value wasn't set as waveTable type, returns nil.  */


/*!
  @method parAsObject:
  @param  parameterTag is an int.
  @result Returns an id.
  @discussion Returns the object value of <i>the parameter identified by
              parameterTag</i>.  If the parameter isn't present, or if its value
              isn't an object, returns <b>nil</b>.  This method can be used to
              return MKEnvelope and MKWaveTable objects, in addition to non-MusicKit
              objects.
              
              See also:  <b>MKGetNoteParAsObject()</b>, -<b>setPar:toDouble:</b> (etc), -<b>parType:</b>, -<b>isParPresent:</b>
*/
- parAsObject:(int) par; 
 /* 
  * Returns the object value of par.  If par isn't present or if its value
  * isn't an object, returns nil.  (This method will return MKEnvelope and
  * MKWaveTable objects).  */


/*!
  @method isParPresent:
  @param  parameterTag is an int.
  @result Returns a BOOL.
  @discussion Returns <b>YES</b> if the parameter <i>identified by
              parameterTag</i> is present in the MKNote (in other words, if its
              value has been set), <b>and NO</b> if it isn't.
              
              See also: -<b>parVector:</b>, <b>MKIsNoteParPresent()</b>, <b>MKNextParameter()</b>, +<b>parTagForName:</b>, 
              +<b>parNameForTag:</b>, -<b>parType:</b>, -<b>setPar:toDouble:</b> (etc), -<b>parAsDouble:</b> (etc).
*/
- (BOOL) isParPresent:(int) par;

/*!
  @method parType:
  @param  parameterTag is an int.
  @result Returns a MKDataType.
  @discussion Returns the data type of <i>the value of the parameter identified by
              parameterTag</i>.  The data type is set when the parameter's value
              is set; the specific data type of the value, one of the MKDataType
              constants listed below, depends on which method you used to set it:
              
              	
              <b>Method	Data type</b>	
              setPar:toInt:	MK_int	
              setPar:toDouble	MK_double	
              setPar:toString:	MK_string	
              setPar:toWaveTable:	MK_waveTable	
              setPar:toEnvelope:	MK_envelope	
              setPar:toObject:	MK_object
              
              If the parameter's value hasn't been set, MK_noType is returned.
              
              See also:  <b>MKGetNoteParAsWaveTable()</b>, -<b>setPar:toDouble:</b> (etc), -<b>parType:</b>, -<b>isParPresent:</b>
*/
-(MKDataType ) parType:(int) par; 

/*!
  @method removePar:
  @param  parameterTag is an int.
  @result Returns an id.
  @discussion Removes the parameter identified by <i>parameterTag</i> from the
              MKNote; in other words, this sets the parameter's value to indicate
              that the parameter isn't set.  If the parameter was present, then
              the MKNote is returned; if not, <b>nil</b> is returned.
              
              See also:  +<b>parTagForName:</b>, +<b>parNameForTag:</b>, -<b>isParPresent:</b>, -<b>setPar:toDouble:</b> (etc).
*/
- removePar:(int) par; 

/*!
  @method copyParsFrom:
  @param  aNote is an MKNote *.
  @result Returns <b>self</b>.
  @discussion Copies <i>aNote</i>'s parameters into the receiving MKNote. 
              Object-valued parameters are shared by the two MKNotes.  
              
              See also:  -<b>copy</b>, -<b>copyFromZone:</b>, -<b>split::</b>
*/
- copyParsFrom: (MKNote *) aNote; 

/*!
  @method freq
  @result Returns a double.
  @discussion This method returns the MKNote's frequency, measured in Hertz or
              cycles-per-second.  If the frequency parameter MK_freq is present,
              its value is returned; otherwise, the frequency is converted from
              the key number value given by the MK_keyNum parameter.  In the
              absence of both MK_freq and MK_keyNum, MK_NODVAL is returned (use
              the function <b>MKIsNoDVal()</b> to check for MK_NODVAL).  The
              correspondence between key numbers and frequencies is given in
<a href=http://www.musickit.org/MusicKitConcepts/musictables.html>
the section entitled Music Tables
</a>.
              
              Frequency and key number are the only two parameters whose values are retrieved through specialized methods.  All other parameter values should be retrieved through one of the <b>parAs</b><i>Type</i><b>:</b> methods.
              
              See also:  -<b>keyNum</b>, -<b>setPar:toDouble:</b>
*/
-(double)  freq; 
 /* 
  * If MK_freq is present, returns its value.  Otherwise, gets the
  * frequency that correponds to MK_keyNum according to the installed
  * tuning system (see the MKTuningSystem class).  If MK_keyNum isn't
  * present, returns MK_NODVAL. (Use MKIsNoDVal() to check for MK_NODVAL.)
  */


/*!
  @method keyNum
  @result Returns an int.
  @discussion This method returns the key number of the MKNote.  Key numbers are
              integers that enumerate discrete pitches; they're provided primarily
              to accommodate MIDI.  If the MK_keyNum parameter is present, its
              value is returned; otherwise, the key number that corresponds to the
              value of the MK_freq parameter, if present, is returned. In the
              absence of both MK_keyNum and MK_freq, MAXINT is returned.  The
              correspondence between key numbers and frequencies is given in
<a href=http://www.musickit.org/MusicKitConcepts/musictables.html>
the section entitled Music Tables
</a>.
              
              Frequency and key number are the only two parameters whose values are retrieved through specialized methods.  All other parameter values should be retrieved through one of the <b>parAs</b><i>Type</i><b>:</b> methods.
              
              See also:  -<b>freq</b>, -<b>setPar:toInt:</b>
*/
-(int)  keyNum; 
 /* 
  * If MK_keyNum is present, returns its value.  Otherwise, gets the
  * frequency that correponds to MK_freq according to the installed tuning
  * system (see the MKTuningSystem class).  If MK_freq isn't present,
  * returns MAXINT. */


/*!
  @method writeScorefileStream:
  @param  aStream is a NSMutableData *.
  @result Returns self.
  @discussion Writes the MKNote, in scorefile format, to the stream, that is, the data object
              <b><i>aStream</i></b>.  You rarely invoke this method yourself; it's invoked from the
              scorefile-writing methods defined by MKScore and MKScorefileWriter.
*/
- writeScorefileStream:(NSMutableData *)aStream; 

- (void)encodeWithCoder:(NSCoder *)aCoder;
  /* 
     You never send this message directly. Should be invoked via 
     NXWriteRootObject().
     Archives parameters, noteType, noteTag, and timeTag. Also archives
     performer and part using MKWriteObjectReference(). */

- (id)initWithCoder:(NSCoder *)aDecoder;
  /* 
     You never send this message directly.  
     Reads MKNote back from archive file. Note that the noteTag is NOT mapped
     onto a unique note tag. This is left up to the MKPart or MKScore with which
     the Note is unarchived. If the MKNote is unarchived directly with 
     NXReadObject(), then the handling of the noteTag is left to the 
     application.
   */


/*!
  @method parVectorCount
  @result Returns an int.
  @discussion Returns the number of parameter bit vectors that the MKNote is using
              to accommodate all its parameters identifiers.   Normally you only
              need to know this if you're iterating over the parameter
              vectors.
              
              See also:  -<b>parVector</b>
*/
-(int) parVectorCount;

/*!
  @method parVector:
  @param  index is an unsigned.
  @result Returns an unsigned.
  @discussion Returns an integer bit vector that indicates the presence of the
              <i>index</i>'th set of parameters.  Each bit vector represents 32
              parameters.  For example, if <i>index</i> is 1, the bits in the
              returned value indicate the presence of parameters 0 through 31,
              where 1 means the parameter is present and 0 means that it's absent.
               An <i>index</i> of 2 returns a vector that represents parameters 32
              through 63, and so on.  To query for the presence of a particular
              parameter, use the following predicate formula:
              	
              <tt>[aNote parVector:(parameterTag/32)] &amp; (1&lt;&lt;(parameterTag%32))</tt>
              
              In this formula, <i>parameterTag </i>identifies the parameter that you're interested in.<i></i>Keep in mind<i>   </i>that the parameter bit vectors only indicate the presence of a parameter, not its value.
              
              See also:  -<b>parVectorCount</b>, -<b>isParPresent:</b>
*/
-(unsigned)parVector:(unsigned)index;
 /* 
 * Returns a bit vector indicating the presence of parameters 
 * identified by integers (index * BITS_PER_INT) through 
 * ((index + 1) * BITS_PER_INT - 1). For example,
 *
 * .ib
 * unsigned int parVect = [aNote checkParVector:0];
 * .iq
 *
 * returns the vector for parameters 0-31.
 * An argument of 1 returns the vector for parameters 32-63, etc.
 *
 * parVectorCount gives the number of parVectors. For example, if the
 * highest parameter is 65, parVectorCount returns 3.
 */

// for debugging
- (NSString *) description;

/*!
  @method note
  @result Returns a MKNote.
  @discussion Allocates and initializes a new MKNote and returns it autoreleased.
*/
+ note;

/*!
  @method noteWithTimeTag:
  @param  aTimeTag is a double in seconds.
  @result Returns a MKNote.
  @discussion Allocates and initializes a new MKNote and returns it autoreleased. 
              Sets timeTag as specified and sets type to mute.
              If aTimeTag is MK_ENDOFTIME, the timeTag isn't set.
*/
+ noteWithTimeTag:(double) aTimeTag; 

@end

extern NSHashEnumerator *MKInitParameterIteration(id aNote);
extern int MKNextParameter(id aNote, NSHashEnumerator *aState);
 /* These functions provide iteration over the parameters of a Note. 
 * Usage:
 *
 *  void *aState = MKInitParameterIteration(aNote);
 *  int par;
 *  while ((par = MKNextParameter(aNote,aState)) != MK_noPar) {
 *        select (par) {
 *          case freq0: 
 *            something;
 *            break;
 *          case amp0:
 *            somethingElse;
 *            break;
 *          default: // Skip unrecognized parameters
 *            break;
 *        }}
 *
 *  It is illegal to reference aState after MKNextParameter has returned
 *  MK_noPar.
 */

 /* Functions that are equivalent to above methods, for speed. */
extern id MKSetNoteParToDouble(id aNote,int par,double value);
extern id MKSetNoteParToInt(id aNote,int par,int value);
extern id MKSetNoteParToString(id aNote,int par,NSString *value);
extern id MKSetNoteParToEnvelope(id aNote,int par,id envObj);
extern id MKSetNoteParToWaveTable(id aNote,int par,id waveObj);
extern id MKSetNoteParToObject(id aNote,int par,id anObj);
extern double MKGetNoteParAsDouble(id aNote,int par);
extern int MKGetNoteParAsInt(id aNote,int par);
extern NSString *MKGetNoteParAsString(id aNote,int par);
extern NSString *MKGetNoteParAsStringNoCopy(id aNote,int par);
extern id MKGetNoteParAsEnvelope(id aNote,int par);
extern id MKGetNoteParAsWaveTable(id aNote,int par);
extern id MKGetNoteParAsObject(id aNote,int par);
extern BOOL MKIsNoteParPresent(id aNote,int par);


#endif
