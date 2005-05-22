/*
  $Id$
  Defined In: The MusicKit

  Portions Copyright (c) 1999-2005 The MusicKit Project.
*/
#ifndef __MK_classFuncs_H___
#define __MK_classFuncs_H___
#ifndef CLASSFUNCS_H
#define CLASSFUNCS_H

/*!
  @defgroup ScorefileCreationFns Set and retrieve scorefile creation classes. Control of MusicKit-created objects. 
 */

/*@{*/

/*!
  @brief When reading a scorefile, processing MIDI, etc., the MusicKit creates
  MKNote objects. Use MKSetNoteClass() to substitute your own MKNote subclass.

  When you read a scorefile into your application, some number of objects
  are automatically created.  Specifically, these objects are instances of
  MKNote, MKPart, MKEnvelope, MKPartials, and MKSamples.  You can supply your
  own classes from which these instances are created through these
  functions.  The one restriction is that the class that you set must be a
  subclass of the original class; for example, the class that you pass the
  argument to <b>MKSetNoteClass()</b> must be a subclass of MKNote.
  This function does not effect objects returned by [MKNote new]; these are
  instances of the MKNote class, as usual.
     
  The <b>MKGet<i>Class</i>Class()</b> functions return the requested
  classes as set through the  functions above.
  @param  noteSubclass is a MKNote.
  @return <b>MKSet<i>Class</i>Class()</b> returns NO if the argument isn't a
   subclass of <b><i>Class</i></b>; otherwise it returns YES.
*/
extern BOOL MKSetNoteClass(id noteSubclass);

/*@
  @brief Returns class set with MKSetNoteClass() or [MKNote class] if none. 
 */
extern id MKGetNoteClass(void);

/*!
  @brief Similar to MKSetNoteClass() for MKParts.

  When you read a scorefile into your application, some number of objects
  are automatically created.  Specifically, these objects are instances of
  MKNote, MKPart, MKEnvelope, MKPartials, and MKSamples.  You can supply your
  own classes from which these instances are created through these
  functions.  The one restriction is that the class that you set must be a
  subclass of the original class; for example, the class that you pass the
  argument to <b>MKSetNoteClass()</b> must be a subclass of MKNote.
     
  The <b>MKGet<i>Class</i>Class() </b>functions return the requested
  classes as set through the  functions above.
  @param  partSubclass is a MKPart instance.
  @return <b>MKSet<i>Class</i>Class()</b> returns NO if the argument isn't a
   subclass of <b><i>Class</i></b>; otherwise it returns YES.
*/
extern BOOL MKSetPartClass(id partSubclass);

/*!
  @brief Similar to MKSetNoteClass() for MKEnvelopes.

  When you read a scorefile into your application, some number of objects
  are automatically created.  Specifically, these objects are instances of
  MKNote, MKPart, MKEnvelope, MKPartials, and MKSamples.  You can supply your
  own classes from which these instances are created through these
  functions.  The one restriction is that the class that you set must be a
  subclass of the original class; for example, the class that you pass the
  argument to <b>MKSetNoteClass()</b> must be a subclass of MKNote.
     
  @param  envelopeSubclass is a MKEnvelope instance.
  @return <b>MKSet<i>Class</i>Class()</b> returns NO if the argument isn't a
 subclass of <b><i>Class</i></b>; otherwise it returns YES.

*/
extern BOOL MKSetEnvelopeClass(id envelopeSubclass);

/*!
  @brief Similar to MKSetNoteClass() for MKPartials.

  When you read a scorefile into your application, some number of objects
  are automatically created.  Specifically, these objects are instances of
  MKNote, MKPart, MKEnvelope, MKPartials, and MKSamples.  You can supply your
  own classes from which these instances are created through these
  functions.  The one restriction is that the class that you set must be a
  subclass of the original class; for example, the class that you pass the
  argument to <b>MKSetNoteClass()</b> must be a subclass of MKNote.
     
  @param  aPartialsSubclass is a MKPartials instance.
  @return <b>MKSet<i>Class</i>Class()</b> returns NO if the argument isn't a
  subclass of <b><i>Class</i></b>; otherwise it returns YES.
*/
extern BOOL MKSetPartialsClass(id aPartialsSubclass);

/*!
  @brief Set and retrieve scorefile creation classes

  When you read a scorefile into your application, some number of objects
  are automatically created.  Specifically, these objects are instances of
  MKNote, MKPart, MKEnvelope, MKPartials, and MKSamples.  You can supply your
  own classes from which these instances are created through these
  functions.  The one restriction is that the class that you set must be a
  subclass of the original class; for example, the class that you pass the
  argument to <b>MKSetNoteClass()</b> must be a subclass of MKNote.
     
  @param  aSamplesSubclass is a MKSamples.
  @return <b>MKSet<i>Class</i>Class()</b> returns NO if the argument isn't a
  subclass of <b><i>Class</i></b>; otherwise it returns YES.
*/
extern BOOL MKSetSamplesClass(id aSamplesSubclass);

/*!
  @brief Similar to MKGetNoteClass() for MKParts.
 
 When you read a scorefile into your application, some number of objects
 are automatically created.  Specifically, these objects are instances of
 MKNote, MKPart, MKEnvelope, MKPartials, and MKSamples.  You can supply your
 own classes from which these instances are created through these
 functions.  The one restriction is that the class that you set must be a
 subclass of the original class; for example, the class that you pass the
 argument to <b>MKSetNoteClass()</b> must be a subclass of MKNote.
 
 The <b>MKGet<i>Class</i>Class()</b> functions return the requested
  classes as set through the functions above.
 @return Returns an id.
 */
extern id MKGetPartClass(void);

/*!
  @brief Similar to MKGetNoteClass() for MKEnvelopes.
 
 When you read a scorefile into your application, some number of objects
 are automatically created.  Specifically, these objects are instances of
 MKNote, MKPart, MKEnvelope, MKPartials, and MKSamples.  You can supply your
 own classes from which these instances are created through these
 functions.  The one restriction is that the class that you set must be a
 subclass of the original class; for example, the class that you pass the
 argument to <b>MKSetNoteClass()</b> must be a subclass of MKNote.
 
 The <b>MKGet<i>Class</i>Class()</b> functions return the requested
 classes as set through the functions above.
 @return Returns an id.
 */
extern id MKGetEnvelopeClass(void);

/*!
  @brief Similar to MKGetNoteClass() for MKPartials.
 
 When you read a scorefile into your application, some number of objects
 are automatically created.  Specifically, these objects are instances of
 MKNote, MKPart, MKEnvelope, MKPartials, and MKSamples.  You can supply your
 own classes from which these instances are created through these
 functions.  The one restriction is that the class that you set must be a
 subclass of the original class; for example, the class that you pass the
 argument to <b>MKSetNoteClass()</b> must be a subclass of MKNote.
 
 The <b>MKGet<i>Class</i>Class()</b> functions return the requested
 classes as set through the functions above.
 @return Returns an id.
 */
extern id MKGetPartialsClass(void);

/*!
 @brief Similar to MKGetNoteClass() for MKSamples.
 
 When you read a scorefile into your application, some number of objects
 are automatically created.  Specifically, these objects are instances of
 MKNote, MKPart, MKEnvelope, MKPartials, and MKSamples.  You can supply your
 own classes from which these instances are created through these
 functions.  The one restriction is that the class that you set must be a
 subclass of the original class; for example, the class that you pass the
 argument to <b>MKSetNoteClass()</b> must be a subclass of MKNote.
 
 The <b>MKGet<i>Class</i>Class()</b> functions return the requested
 classes as set through the functions above.
 @return Returns an id.
 */
extern id MKGetSamplesClass(void);

/*@}*/

#endif /* CLASSFUNCS_H */
#endif
