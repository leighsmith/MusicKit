/*
  $Id$
  Defined In: The MusicKit
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:26:06  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_midiTranslation_H___
#define __MK_midiTranslation_H___
#ifndef MIDITRANS_H
#define MIDITRANS_H

 /* Music Kit-to-MIDI translation */
extern void MKSetInclusiveMidiTranslation(BOOL yesOrNo);
  /* Sets whether strict MIDI semantics are assumed for incoming
   * MIDI or Standard MIDI files (the default).  For example,
   * key pressure and noteOffs for keys that are not on are filtered out.
   * Calling MKSetInclusiveMidiTranslation(YES) relaxes these
   * retrictions.  
   */
extern BOOL MKGetInclusiveMidiTranslation(void);
  /* Returns value set with the above function. */

#endif MIDITRANS_H
#endif
