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

#import "SignalProcessingController.h"

@implementation SignalProcessingController

- (IBAction) startProcessing: (id) sender
{
    // TODO do we need setOutputStream: to allow input to be directed to a different output stream?    
    if(![streamInput isReceivingInput]) {
	[streamInput startReceivingInput];
    }
    else {
	[streamInput stopReceivingInput];
	NSLog(@"Average input latency: %f samples, output latency: %f samples\n",
	      [streamInput averageLatencyForOutput: NO], [streamInput averageLatencyForOutput: YES]);
    }
}

- (IBAction) inputSourceSelected: (id) sender
{
    // TODO Must Restart sound to use the new driver.
    NSLog(@"Selected for input %@", [soundInputDriverPopup titleOfSelectedItem]);
}

- (IBAction) outputSourceSelected: (id) sender
{
    // TODO Must Restart sound to use the new driver.
    NSLog(@"Selected for input %@", [soundInputDriverPopup titleOfSelectedItem]);
}

- (IBAction) setVolume: (id) sender
{
    NSLog(@"volume change");
}

- (void) displaySoundPreferences
{
    [soundInputDriverPopup removeAllItems]; // remove placeholder, in a blitzkrieg kind of way...
    [soundInputDriverPopup addItemsWithTitles: [SndStreamManager getDriverNamesForOutput: NO]];
    // [soundInputDriverPopup selectItemWithTitle: [SndStreamManager ];
    [soundOutputDriverPopup removeAllItems]; // remove placeholder, in a blitzkrieg kind of way...
    [soundOutputDriverPopup addItemsWithTitles: [SndStreamManager getDriverNamesForOutput: YES]];
    // [soundOutputDriverPopup selectItemWithTitle: [[NSUserDefaults standardUserDefaults] objectForKey: SoundDriverName]];    
}

- (IBAction) enableReverb: (id) sender
{
    [reverb setActive: [sender intValue]];
}

- (IBAction) enableDistortion: (id) sender
{
    [distortion setActive: [sender intValue]];
}

- init
{
    self = [super init];
    if (self != nil) {
	SndAudioFader *postFader = [[SndAudioFader alloc] init]; // Create the fader.
	SndStreamManager *streamManager;
	
	reverb = [[SndAudioProcessorReverb alloc] init];
	distortion = [[SndAudioProcessorDistortion alloc] init];
	[distortion setBoostAmount: 0.9];
	//[distortion setHardness: 0.6];

	streamInput = [[SndStreamInput alloc] init];
	
	// Initially make inactive.
	[reverb setActive: NO];
	[distortion setActive: NO];
	
	[[streamInput audioProcessorChain] addAudioProcessor: distortion];
	[[streamInput audioProcessorChain] addAudioProcessor: reverb];

	// [postFader setActive: YES];
	
	//[audioProcessorChain setPostFader: postFader];

	streamManager = [SndStreamManager defaultStreamManager];
	// TODO how do we manage different input and output devices?
	// deviceSpecificStreamManager = [[SndStreamManager streamManagerOnDevice: deviceName] retain];

	[streamManager addClient: streamInput];
    }
    return self;
}

- (void) dealloc
{
    [reverb release];
    reverb = nil;
    [distortion release];
    distortion = nil;
    [streamInput release];
    streamInput = nil;
    [super dealloc];
}

- (void) applicationDidFinishLaunching: (id) sender
{
    [self displaySoundPreferences];
}

@end
