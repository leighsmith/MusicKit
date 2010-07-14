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
    [liveFader setAmp: [sender floatValue] clearingEnvelope: NO];
}

- (IBAction) setSndVolume: (id) sender
{
    [sndFader setAmp: [sender floatValue] clearingEnvelope: NO];
}

- (void) displaySoundPreferences
{
    [soundInputDriverPopup removeAllItems]; // remove placeholder, in a blitzkrieg kind of way...
    [soundInputDriverPopup addItemsWithTitles: [SndStreamManager getDriverNamesForOutput: NO]];
    [soundInputDriverPopup selectItemAtIndex: [SndStreamManager getAssignedDriverIndexForOutput: NO]];
    [soundOutputDriverPopup removeAllItems]; // remove placeholder, in a blitzkrieg kind of way...
    [soundOutputDriverPopup addItemsWithTitles: [SndStreamManager getDriverNamesForOutput: YES]];
    [soundOutputDriverPopup selectItemAtIndex: [SndStreamManager getAssignedDriverIndexForOutput: YES]];    
}

- (IBAction) enableReverb: (id) sender
{
    [reverb setActive: [sender intValue]];
}

- (IBAction) enableDistortion: (id) sender
{
    [distortion setActive: [sender intValue]];
}

- (IBAction) playSound: (id) sender
{
    if(![soundToPlay isPlaying]) {
	[soundToPlay play];
    }
    else {
	[soundToPlay stop];
    }
}

- (IBAction) openFile: (id) sender
{
    int result;
    NSArray *fileTypes = [SndMP3 soundFileExtensions];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    
    // NSLog(@"Accepting %@\n", fileTypes);
    result = [oPanel runModalForDirectory: nil file: nil types: fileTypes];
    if (result == NSOKButton) {
        NSArray *fileNames = [[oPanel filenames] retain];
	SndAudioProcessorChain *audioProcessorChain = [SndAudioProcessorChain audioProcessorChain];
	
	[soundToPlay release];
	soundToPlay = [[SndMP3 alloc] initFromSoundfile: [fileNames objectAtIndex: 0]];
	[audioProcessorChain setPostFader: sndFader];
	[sndFader setActive: YES];
	[soundToPlay setAudioProcessorChain: audioProcessorChain];
        [playButton setEnabled: YES];
    }
}

- init
{
    self = [super init];
    if (self != nil) {
	SndStreamManager *streamManager;
	SndAudioProcessorChain *audioProcessorChain;
	
	soundToPlay = nil;
	liveFader = [[SndAudioFader alloc] init]; // Create the live fader.
	[liveFader setAmp: 1.0 clearingEnvelope: NO]; // TODO use [liveFaderSlider floatValue]
	sndFader = [[SndAudioFader alloc] init]; // Create the sound playback fader.
	[sndFader setAmp: 1.0 clearingEnvelope: NO];  // TODO use [sndFaderSlider floatValue]
	
	reverb = [[SndAudioProcessorReverb alloc] init];
	distortion = [[SndAudioProcessorDistortion alloc] init];
	[distortion setBoostAmount: 0.8];
	//[distortion setHardness: 0.6];
	
	streamInput = [[SndStreamInput alloc] init];
	audioProcessorChain = [streamInput audioProcessorChain];
	
	// Initially make inactive.
	[reverb setActive: NO];
	[distortion setActive: NO];
	
	[audioProcessorChain addAudioProcessor: distortion];
	[audioProcessorChain addAudioProcessor: reverb];
	[liveFader setActive: YES];
	[audioProcessorChain setPostFader: liveFader];

	streamManager = [SndStreamManager defaultStreamManager];
	// TODO how do we manage different input and output devices?
	// deviceSpecificStreamManager = [[SndStreamManager streamManagerOnDevice: deviceName] retain];

	[streamManager addClient: streamInput];
    }
    return self;
}

- (void) dealloc
{
    if(soundToPlay != nil) {
	[soundToPlay release];
	soundToPlay = nil;
    }
    [liveFader release];
    liveFader = nil;
    [sndFader release];
    sndFader = nil;
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
