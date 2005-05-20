/*
  $Id$
  Defined In: The MusicKit

  Portions Copyright (c) 1999-2005 The MusicKit Project.
*/
#ifndef __MK_classFuncs_H___
#define __MK_classFuncs_H___
#ifndef CLASSFUNCS_H
#define CLASSFUNCS_H

 /* Control of Music Kit-created objects. */
/*!
  @brief Set and retrieve scorefile creation classes

  When you read a scorefile into your application, some number of objects
  are automatically created.  Specifically, these objects are instances of
  MKNote, Part, MKEnvelope, Partials, and Samples.  You can supply your
  own classes from which these instances are created through these
  functions.  The one restriction is that the class that you set must be a
  subclass of the original class; for example, the class that you pass the
  argument to <b>MKSetNoteClass()</b> must be a subclass of MKNote.
     
  The <b>MKGet<i>Class</i>Class()</b> functions return the requested
  classes as set through the  functions above.
  @param  noteSubclass is a MKNote.
  @param   is a *.
  @return <b>MKSet<i>Class</i>Class()</b> returns NO if the argument isn't a
   subclass of <b><i>Class</i></b>; otherwise it returns YES.
   
*/
extern BOOL MKSetNoteClass(id aNoteSubclass);
 /* When reading a scorefile, processing MIDI, etc., the Music Kit creates
  * MKNote objects. Use MKSetNoteClass() to substitute your own MKNote subclass.
  * Returns YES if aNoteSubclass is a subclass of MKNote. Otherwise returns
  * NO and does nothing. This function does not effect objects returned
  * by [MKNote new]; these are instances of the MKNote class, as usual. 
  */

extern id MKGetNoteClass(void);
 /* Returns class set with MKSetNoteClass() or [MKNote class] if none. */

 /* The following are similar to MKSetNoteClass() and MKGetNoteClass() for
  * other Music Kit classes. */
/*!
  @brief Set and retrieve scorefile creation classes

  When you read a scorefile into your application, some number of objects
  are automatically created.  Specifically, these objects are instances of
  MKNote, Part, MKEnvelope, Partials, and Samples.  You can supply your
  own classes from which these instances are created through these
  functions.  The one restriction is that the class that you set must be a
  subclass of the original class; for example, the class that you pass the
  argument to <b>MKSetNoteClass()</b> must be a subclass of MKNote.
     
   The <b>MKGet<i>Class</i>Class() </b>functions return the requested
  classes as set through the  functions above.
  @param  partSubclass is a Part.
  @param   is a *.
*/
extern BOOL MKSetPartClass(id aPartSubclass);

/*!
  @brief Set and retrieve scorefile creation classes

  When you read a scorefile into your application, some number of objects
  are automatically created.  Specifically, these objects are instances of
  MKNote, Part, MKEnvelope, Partials, and Samples.  You can supply your
  own classes from which these instances are created through these
  functions.  The one restriction is that the class that you set must be a
  subclass of the original class; for example, the class that you pass the
  argument to <b>MKSetNoteClass()</b> must be a subclass of MKNote.
     
   The <b>MKGet<i>Class</i>Class() </b>functions return the requested
  classes as set through the  functions above.
  @param  envelopeSubclass is a Envelope.
  @param   is a *.
*/
extern BOOL MKSetEnvelopeClass(id anEnvelopeSubclass);

/*!
  @brief Set and retrieve scorefile creation classes

  When you read a scorefile into your application, some number of objects
  are automatically created.  Specifically, these objects are instances of
  MKNote, Part, MKEnvelope, Partials, and Samples.  You can supply your
  own classes from which these instances are created through these
  functions.  The one restriction is that the class that you set must be a
  subclass of the original class; for example, the class that you pass the
  argument to <b>MKSetNoteClass()</b> must be a subclass of MKNote.
     
   The <b>MKGet<i>Class</i>Class() </b>functions return the requested
  classes as set through the  functions above.
  @param  partialsSubclass is a Partials.
  @param   is a *.
*/
extern BOOL MKSetPartialsClass(id aPartialsSubclass);

/*!
  @brief Set and retrieve scorefile creation classes

  When you read a scorefile into your application, some number of objects
  are automatically created.  Specifically, these objects are instances of
  MKNote, Part, MKEnvelope, Partials, and Samples.  You can supply your
  own classes from which these instances are created through these
  functions.  The one restriction is that the class that you set must be a
  subclass of the original class; for example, the class that you pass the
  argument to <b>MKSetNoteClass()</b> must be a subclass of MKNote.
     
   The <b>MKGet<i>Class</i>Class() </b>functions return the requested
  classes as set through the  functions above.
  @param  samplesSubclass is a Samples.
  @param   is a *.
*/
extern BOOL MKSetSamplesClass(id aSamplesSubclass);

extern id MKGetPartClass(void);
extern id MKGetEnvelopeClass(void);
extern id MKGetPartialsClass(void);
extern id MKGetSamplesClass(void);


#endif /* CLASSFUNCS_H */
#endif
