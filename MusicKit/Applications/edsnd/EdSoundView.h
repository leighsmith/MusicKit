/* EdSoundView.h -- interface for custom SoundView
 *
 * This is a subclass of SoundView with additional editing methods
 *
 * jwp@silvertone.Princeton.edu, 11/89
 *
 * Version 1.2, 1/90
 *	-- Added enveloping
 */

#import <soundkit/soundkit.h>

@interface EdSoundView : SoundView

/* New sound editing methods implemented in EdSoundView:
 *	- erase:	= wipe out the current selection
 *	- addSilence:	= insert silence into the sound
 *	- envelope:Point: = envelope the current selection
 */

- erase:sender;
- addSilence:(float)dur;
- envelope:(NXPoint *)env Points:(int)n;

@end
