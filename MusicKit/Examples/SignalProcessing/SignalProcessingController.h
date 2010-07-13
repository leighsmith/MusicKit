/*
  $Id: SoundPlayerController.h 3633 2009-10-01 21:55:52Z leighsmith $
 
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

    SndStreamInput *streamInput;
    /*! A reverb audio processor we can selectively enable and disable */
    SndAudioProcessorReverb *reverb;
    /*! A distortion audio processor  we can selectively enable and disable */
    SndAudioProcessorDistortion *distortion;
}

- (IBAction) startProcessing: (id) sender;

- (IBAction) inputSourceSelected: (id) sender;

- (IBAction) outputSourceSelected: (id) sender;

- (IBAction) setVolume: (id) sender;

- (IBAction) enableReverb: (id) sender;

- (IBAction) enableDistortion: (id) sender;

- (void) applicationDidFinishLaunching: (id) sender;


@end
