#ifndef __MK_names_H___
#define __MK_names_H___
#ifndef MK_NAMES_H
#define MK_NAMES_H

/* This file contains various functions having to do with names in the
 * Music Kit 
 */

 /* Music Kit table management.
  *  
  * The Music Kit provides a simple naming mechanism.  There are 5
  * functions provided for manipulating the name of an object. These are
  * declared below.
  * 
  * Names are primarily used when reading and writing scorefiles. For
  * example, when you read a scorefile into a Score object, the Parts that
  * are created are given the names used in the file.  Similarly, when
  * performing a scorefile with a ScorefilePerformer, the NoteSenders are
  * given the part names used in the file.  Envelopes and WaveTables
  * created when reading a scorefile are also given names.
  * 
  * When writing a Score which contains Parts you created in an application,
  * you can explicitly give the Parts names.  If a name you specify is not
  * unique, or if you don't specify any name, one will be automatically
  * generated (a variant of what you supplied). Similarly, when recording to a 
  * scorefile with a ScorefileWriter, you can explicitly provide part names by 
  * naming the corresponding NoteReceivers.
  * 
  * Note that the naming mechanism allows any object, whether or not it is
  * in the Music Kit, to be named. In general, it is the Application's 
  * responsibility to remove the names before freeing the object. 
  * However, as a convenience, the following classes remove the instance name
  * when freeing the instance. Copying an object does not copy its name.
  * 
  * It's illegal to change the name of an object during a performance
  * involving a ScorefileWriter. (Because an object'll get written to the
  * file with the wrong name.) 
  */

extern BOOL MKNameObject(NSString * name,id object);
 /*
  * Adds the object theObject in the table, with name theName.
  * If the object is already named, does 
  * nothing and returns NO. Otherwise returns YES. Note that the name is copied.
  */

extern NSString * MKGetObjectName(id object);
 /* 
  * Returns object name if any. If object is not found, returns NULL. The name
  * is not copied and should not be freed by caller.
  */

extern id MKRemoveObjectName(id object);
 /* Removes theObject from the table, if present. Returns nil. */

extern id MKGetNamedObject(NSString *name);
 /* Returns the first object found in the name table, with the given name.
    Note that the name is not necessarily unique in the table; there may
    be more than one object with the same name.
   */

 /* These two functions allow you to give an object a name that can be seen
  * by a scorefile. 
  */
extern BOOL MKAddGlobalScorefileObject(id object,NSString *name);
 /*
  * Adds the object as a global scorefile object, 
  * referenced in the scorefile with the name specified. The name is copied.
  * The object does not become visible to a scorefile unless it explicitly
  * 'imports' it by a getGlobal statement.
  * If there is already a global scorefile object with the specified name, 
  * does nothing and returns NO. Otherwise returns YES. 
  * The type of the object in the scorefile is determined as follows:
  * If object -isKindOf:WaveTable, then the type is MK_waveTable.
  * If object -isKindOf:Envelope, then the type is MK_envelope.
  * Otherwise, the type is MK_object.
  * Note that the global scorefile table is independent of the Music Kit
  * name table. Thus, an object can be named in one and unnamed in the other,
  * or it can be named differently in each.
  */


extern id MKGetGlobalScorefileObject(NSString *name);
 /* Returns the global scorefile object with the given name. The object may
  * be either one that was added with MKAddGlobalScorefileObject or it
  * may be one that was added from within a scorefile using "putGlobal".
  * Objects accessable to the application are those of type 
  * MK_envelope, MK_waveTable and MK_object. 
  */


 /* Scorefile reading and writing. */
extern void MKWritePitchNames(BOOL usePitchNames);
 /* Selects whether values of the parameters freq0 and freq are written as 
  * pitch names or as frequencies in Hz. If you write them as pitch names,
  * they are rounded to the nearest pitch. The default is NO. 
  */

extern void MKWriteKeyNumNames(BOOL useKeyNums);
 /* Selects whether values of the parameter keyNum are written as 
  * keyNum names or as integers. The default is YES.
  */

#endif MK_NAMES_H
#endif
