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

#ifndef USE_NEXTSTEP_SOUND_IO
/* Define this for compatibility */
#define NXSoundPboard SndPasteboardType

extern NSString *SndPasteboardType;
#import <AppKit/NSPasteboard.h>
#endif

#import "Snd.h"

@interface Snd(Pasteboard)

/*!
  @method initFromPasteboard:
  @param  thePboard is a NSPasteboard *.
  @result Returns an id.
  @discussion Initializes the Snd instance, which must be newly allocated, by
              copying the sound data from the Pasteboard object <i>thePboard</i>.
              (A Pasteboard can have only one sound entry at a time.) Returns
              <b>self</b> (an unnamed Snd) if <i>thePboard</i> currently
              contains a sound entry; otherwise, frees the newly allocated Snd
              and returns <b>nil</b>.
 
              See also: +<b>alloc</b> (NSObject), +<b>allocWithZone:</b> (NSObject)
 */
- initFromPasteboard: (NSPasteboard *) thePboard;

/*!
  @method writeToPasteboard:
  @param  thePboard is a NSPasteboard *.
  @result Returns an int.
  @discussion Puts a copy of the Snd's contents (its sample format and sound data) on the pasteboard 
              maintained by the NSPasteboard object <i>thePboard</i>. 
              If the Snd is fragmented, it's compacted before the copy is created. An error code is returned.
 */
- (void) writeToPasteboard: (NSPasteboard *) thePboard;

@end
