////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description: A category of Snd performing I/O to AppKit pasteboards.
//    We place this in a separate category to isolate AppKit dependence.
//
//  Original Author:  Leigh Smith, <leigh@leighsmith.com>
//
//  Copyright (c) 2004, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "Snd.h"

#ifndef USE_NEXTSTEP_SOUND_IO
/* Define this for compatibility */
#define NXSoundPboard SndPasteboardType

extern NSString *SndPasteboardType;
#import <AppKit/NSPasteboard.h>
#endif

@interface Snd(Pasteboard)

/*!
  @param  thePboard is a NSPasteboard *.
  @return Returns an id.
  @brief Initializes the Snd instance, which must be newly allocated, by
  copying the sound data from the Pasteboard object <i>thePboard</i>.

  
  (A Pasteboard can have only one sound entry at a time.) Returns
  <b>self</b> (an unnamed Snd) if <i>thePboard</i> currently
  contains a sound entry; otherwise, frees the newly allocated Snd
  and returns <b>nil</b>.
 
  @see +<b>alloc</b> (NSObject), +<b>allocWithZone:</b> (NSObject)
 */
- initFromPasteboard: (NSPasteboard *) thePboard;

/*!
  @param  thePboard is a NSPasteboard *.
  @return Returns an int.
  @brief Puts a copy of the Snd's contents (its sample format and sound data) on the pasteboard 
  maintained by the NSPasteboard object <i>thePboard</i>.

  
  If the Snd is fragmented, it's compacted before the copy is created. An error code is returned.
 */
- (void) writeToPasteboard: (NSPasteboard *) thePboard;

@end
