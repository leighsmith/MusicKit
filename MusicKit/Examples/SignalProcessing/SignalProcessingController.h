/*
  $Id$
 
  Description:
    Simple sound signal processing application, demonstrating applying effects to a input stream and playing the result 
    using SndStreamClients.
 
  Original Author: Leigh Smith, <leigh@leighsmith.com>.
 
  7 July 2010, Copyright (c) 2010 MusicKit Project. All rights reserved.
 
  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
 */
#import <AppKit/AppKit.h>
#import <SndKit/SndKit.h>
#import "SndStreamInput.h"

@interface SignalProcessingController : NSObject 
{
    IBOutlet NSPopUpButton *soundInputDriverPopup;
    IBOutlet NSPopUpButton *soundOutputDriverPopup;
    IBOutlet NSButton *playButton;

    /*! The stream manager, managing clients on the sound hardware */
    SndStreamManager *streamManager;
    /*! An subclass of SndStreamClient that reflects it's input to output, possibly processed by it's SndAudioProcessorChain */
    SndStreamInput *streamInput;
    /*! A reverb audio processor we can selectively enable and disable. */
    SndAudioProcessorReverb *reverb;
    /*! A distortion audio processor  we can selectively enable and disable. */
    SndAudioProcessorDistortion *distortion;
    /*! A sound file that can be played asynchronously. */
    SndMP3 *soundToPlay;
    /*! A fader that can be used to fade out the input. */
    SndAudioFader *liveFader;
    /*! A fader that can be used to fade out the playing sound. */
    SndAudioFader *sndFader;
}

- (IBAction) startProcessing: (id) sender;

- (IBAction) inputSourceSelected: (id) sender;

- (IBAction) outputSourceSelected: (id) sender;

- (IBAction) setVolume: (id) sender;

- (IBAction) setSndVolume: (id) sender;

- (IBAction) enableReverb: (id) sender;

- (IBAction) enableDistortion: (id) sender;

- (IBAction) playSound: (id) sender;

- (IBAction) openFile: (id) sender;

- (void) applicationDidFinishLaunching: (id) sender;


@end
