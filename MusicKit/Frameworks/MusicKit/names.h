/*
  $Id$
  Defined In: The MusicKit

  Description: This file contains various functions having to do with names in the MusicKit 

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2005 The MusicKit Project.
*/
#ifndef __MK_names_H___
#define __MK_names_H___
#ifndef MK_NAMES_H
#define MK_NAMES_H

 /* MusicKit table management.
  *  
  * The MusicKit provides a simple naming mechanism.  There are 5
  * functions provided for manipulating the name of an object. These are
  * declared below.
  * 
  * Names are primarily used when reading and writing scorefiles. For
  * example, when you read a scorefile into a MKScore object, the MKParts that
  * are created are given the names used in the file.  Similarly, when
  * performing a scorefile with a MKScorefilePerformer, the MKNoteSenders are
  * given the part names used in the file.  Envelopes and WaveTables
  * created when reading a scorefile are also given names.
  * 
  * When writing a MKScore which contains MKParts you created in an application,
  * you can explicitly give the MKParts names.  If a name you specify is not
  * unique, or if you don't specify any name, one will be automatically
  * generated (a variant of what you supplied). Similarly, when recording to a 
  * scorefile with a MKScorefileWriter, you can explicitly provide part names by 
  * naming the corresponding MKNoteReceivers.
  * 
  * Note that the naming mechanism allows any object, whether or not it is
  * in the MusicKit, to be named. In general, it is the Application's 
  * responsibility to remove the names before freeing the object. 
  * However, as a convenience, the following classes remove the instance name
  * when freeing the instance. Copying an object does not copy its name.
  * 
  * It's illegal to change the name of an object during a performance
  * involving a MKScorefileWriter. (Because an object'll get written to the
  * file with the wrong name.) 
  */

/*!
  @defgroup ObjNameFns Identify and return objects by name.
 */

/*!
  @brief Adds the object <i>object</i> into the table, with name <i>name</i>.

  The MusicKit provides a global naming mechanism that lets you identify
  and locate objects by name.  While names are primarily used in reading
  and writing scorefiles, any object - even a non-MusicKit object - can
  be named.  Names needn't be unique; more than one object can be given
  the same name.  However, a single object can have but one name at a
  time.  
   
  <b>MKNameObject()</b> sets <i>object</i>'s name to a copy of
  <i>name</i> and returns YES.  If the object already has a name, then
  this function does nothing and returns <b>NO</b>.
   
  @param  name is an NSString instance.
  @param  object is an id.
  @return Returns a BOOL.
  @ingroup ObjNameFns
*/
extern BOOL MKNameObject(NSString * name,id object);

/*!
  @brief Returns object name if any.

  The MusicKit provides a global naming mechanism that lets you identify
  and locate objects by name.  While names are primarily used in reading
  and writing scorefiles, any object - even a non-MusicKit object - can
  be named.  Names needn't be unique; more than one object can be given
  the same name.  However, a single object can have but one name at a
  time.  
   
  <b>MKGetObjectName()</b> returns its argument's name, or NULL if it
  isn't named.  The returned value is read-only and shouldn't be freed by
  the caller.  
   
  @param  object is an id.
  @return Returns an NSString instance. If object is not found, returns NULL.
  @see MKNameObject().
  @ingroup ObjNameFns
*/
extern NSString *MKGetObjectName(id object);

/*!
  @brief Removes its argument's name (if any) and returns <b>nil</b>.  

  The MusicKit provides a global naming mechanism that lets you identify
  and locate objects by name.  While names are primarily used in reading
  and writing scorefiles, any object - even a non-MusicKit object - can
  be named.  Names needn't be unique; more than one object can be given
  the same name.  However, a single object can have but one name at a
  time.  
   
  @param  object is an id.
  @return Returns an id.
  @ingroup ObjNameFns
  @see <b>MKNameObject()</b>.
*/
extern id MKRemoveObjectName(id object);

/*!
  @brief Returns the first object in the name table that has the name <i>name</i>. 

  The MusicKit provides a global naming mechanism that lets you identify
  and locate objects by name.  While names are primarily used in reading
  and writing scorefiles, any object - even a non-MusicKit object - can
  be named.  Names needn't be unique; more than one object can be given
  the same name.  However, a single object can have but one name at a
  time.  
   
  @param  name is an NSString instance.
  @return Returns an id.
  @see MKNameObject().
  @ingroup ObjNameFns
*/
extern id MKGetNamedObject(NSString *name);

/*! 
  @brief Allows giving an object a name that can be seen by a scorefile. 

  Adds the object as a global scorefile object, 
  referenced in the scorefile with the name specified. The name is copied.
  The object does not become visible to a scorefile unless it explicitly
  'imports' it by a getGlobal statement.
  If there is already a global scorefile object with the specified name, 
  does nothing and returns NO. Otherwise returns YES. 
  The type of the object in the scorefile is determined as follows:
  If object -isKindOf:MKWaveTable, then the type is MK_waveTable.
  If object -isKindOf:MKEnvelope, then the type is MK_envelope.
  Otherwise, the type is MK_object.
  Note that the global scorefile table is independent of the MusicKit
  name table. Thus, an object can be named in one and unnamed in the other,
  or it can be named differently in each.
  @param object The object to be named.
  @param name The NSString instance containing the name.
  @ingroup ObjNameFns
*/
extern BOOL MKAddGlobalScorefileObject(id object,NSString *name);

/*!
  @brief Returns the global scorefile object with the given name.
 
  Allows you to give an object a name that can be seen
  by a scorefile. The object may be either one that was added
  with MKAddGlobalScorefileObject or it may be one that was added
  from within a scorefile using "putGlobal".
  Objects accessible to the application are those of type 
  MK_envelope, MK_waveTable and MK_object. 
  @ingroup ObjNameFns
 */
extern id MKGetGlobalScorefileObject(NSString *name);

/*!
  @defgroup ScorefileFns Scorefile reading and writing. 
 */

/*!
  @brief Write pitches to a scorefile

  <b>MKWritePitchNames</b> sets the format by which frequency parameter
  values <b>freq0</b> and <b>freq</b> are written to a scorefile.
  If the argument is YES, the parameter values are written as pitch name
  constants such as &ldquo;a4&rdquo;. If it's NO, frequencies are written as fractional
  numbers in Hz. If you write them as pitch names, they are rounded to the nearest pitch.
  The default is NO.
  @param  usePitchNames is a BOOL.
  @ingroup ScorefileFns
*/
extern void MKWritePitchNames(BOOL usePitchNames);

/*!
  @brief Write pitches to a scorefile

  <b>MKWriteKeyNumNames</b> controls how keyNum
  values are written to a scorefile.  If the argument is YES, the
  parameter values are written as keyNum name constants such as &ldquo;a4k&rdquo;.
  If it's NO,  key numbers are written as integers.
  @param  useKeyNums is a BOOL.
  @see MKWritePitchNames().
  @ingroup ScorefileFns
*/
extern void MKWriteKeyNumNames(BOOL useKeyNums);

#endif /* MK_NAMES_H */
#endif
