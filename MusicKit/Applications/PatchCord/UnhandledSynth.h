/*!
  @class UnhandledSynth
  @author Leigh M. Smith
  @description
     Presents a text user interface for System Exclusive messages which are not 
     supported by more specific MIDISysExSynth subclasses.
 */

#import <AppKit/AppKit.h>
#import "MIDISysExSynth.h"

@interface UnhandledSynth: MIDISysExSynth <NSTextViewDelegate>
{
    IBOutlet id scrollingDisplay;   // Points to our NSText NSScrollView
    NSTextView *sysExText;	    // The NSTextView within the NSScrollView
    SysExMessage *userMessages;	    // the messages typed by the user, the superclass has those received from the synth.
}

- (id) init;
- (id) initWithEmptyPatch;
- (BOOL) initWithSysEx: (SysExMessage *) msg;
- (NSTextView *) text;
- (void) dealloc;
- (void) displayToText: (NSString *) msg;
- (void) setScrollingDisplay: aScroller;
- (BOOL) catchesAllMessages;	// Unhandled will respond to anything
@end
