/*
  $Id$
  Defined In: The MusicKit
*/
/*
Modification history:

  $Log$
  Revision 1.4  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.3  2001/07/02 16:56:01  sbrandon
  - commented out cruft after endif

  Revision 1.2  1999/07/29 01:26:03  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_classFuncs_H___
#define __MK_classFuncs_H___
#ifndef CLASSFUNCS_H
#define CLASSFUNCS_H

 /* Control of Music Kit-created objects. */
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
extern BOOL MKSetPartClass(id aPartSubclass);
extern BOOL MKSetEnvelopeClass(id anEnvelopeSubclass);
extern BOOL MKSetPartialsClass(id aPartialsSubclass);
extern BOOL MKSetSamplesClass(id aSamplesSubclass);
extern id MKGetPartClass(void);
extern id MKGetEnvelopeClass(void);
extern id MKGetPartialsClass(void);
extern id MKGetSamplesClass(void);


#endif /* CLASSFUNCS_H */
#endif
