////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Original Author: Leigh Smith, <leigh@leighsmith.com>
//
//  Copyright (c) 2004, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import "SndAudioUnitProcessor.h"

/*!
  @class SndAudioUnitController
  @description Responsible for receiving user interface messages from the Cocoa or Carbon Audio Unit views
    and passing them down to the Audio Unit (which is wrapped within the SndAudioUnitProcessor).
    Receives buttons for bypassing an effect.

  @discussion Does this model one connection of a AudioUnitCarbonView instance to a SndAudioUnitProcessor instance? Several?
// Controls the display of an Audio Unit view.
// If it's a Cocoa view, load it from it's bundle and return it. If it's a Carbon View,  start it up in a separate window.
// Probably rename SndAudioUnitController, and normally create or be assigned a Cocoa window or a Carbon window.
*/
@interface SndAudioUnitController : NSObject
{
    /*! @var carbonView The handle onto the AudioUnitCarbonView */
    AudioUnitCarbonView carbonView;
    /*! @var auWindow The handle onto the Carbon window loaded from the Carbon nib file. */
    WindowRef auWindow;
    /*! @var cocoaAUWindow The NSWindow instance that will wrap a Carbon window if the nib file is Carbon or will
	be a Cocoa window that contains the Cocoa Audio Unit user interface instance.
     */
    NSWindow  *cocoaAUWindow;
    /*! @var audioUnitProcessor The AudioUnit SndAudioProcessor instance this instance controls. */
    SndAudioUnitProcessor *audioUnitProcessor;
}

/*!
  @method initWithProcessor:
  @abstract Initialises a view instance with a given AudioUnit Processor. 
  @discussion Responsible for loading the user interface and displaying it either in a separate window (Carbon)
              or initialising it ready for incorporation within another view (Cocoa).
 */
- initWithProcessor: (SndAudioUnitProcessor *) processor;

/*!
  @method window
  @abstract Returns the window displaying and managing the window.
 */
 - (NSWindow *) window;

@end
