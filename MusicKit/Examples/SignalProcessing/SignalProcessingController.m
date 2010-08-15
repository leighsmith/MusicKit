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

#define BUFFER_SIZE 256

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
    // [streamManager setAssignedDriverToIndex: [soundInputDriverPopup indexOfSelectedItem] forOutput: NO];

}

- (IBAction) outputSourceSelected: (id) sender
{
    NSString *inputDriverName, *outputDriverName;
    
#if 0 // Windows
    NSArray *driverNames = [SndStreamManager driverNamesForOutput: YES];
    unsigned int newDriverIndex = ([streamManager assignedDriverIndexForOutput: YES] + 1) % [driverNames count];
    
    // On Windows ASIO devices the output must match the input so we enforce the same device for input & output.
    inputDriverName = [driverNames objectAtIndex: newDriverIndex];
    outputDriverName = [driverNames objectAtIndex: newDriverIndex];
#else
    inputDriverName = [soundInputDriverPopup titleOfSelectedItem];
    outputDriverName = [soundOutputDriverPopup titleOfSelectedItem];
#endif
#if 1
    NSLog(@"Selected for input %@ & output %@", inputDriverName, outputDriverName);
    [streamManager stopStreaming]; // shut the streaming down early to release the device.
    NSLog(@"stream manager retain count %d\n", [streamManager retainCount]);
    [streamManager release];
    streamManager = [[SndStreamManager alloc] initOnDeviceForInput: inputDriverName 
						   deviceForOutput: outputDriverName];
    // Must re-add the clients.
    NSLog(@"streamInput = %@\n", streamInput);
    [streamManager addClient: streamInput];
    [streamManager addClient: [SndPlayer defaultSndPlayer]];
    NSLog(@"Assigned input %@ output %@",
	  [streamManager assignedDriverNameForOutput: NO], [streamManager assignedDriverNameForOutput: YES]);
#else
    // TODO Must Restart sound to use the new driver.
    if(![streamManager setAssignedDriverToIndex: [soundOutputDriverPopup indexOfSelectedItem] forOutput: YES])
	NSLog(@"Unable to set output device to %@", [soundOutputDriverPopup titleOfSelectedItem]);
#endif
    NSLog(@"stream manager = %@", streamManager);
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
    [soundInputDriverPopup addItemsWithTitles: [SndStreamManager driverNamesForOutput: NO]];
    [soundInputDriverPopup selectItemAtIndex: [streamManager assignedDriverIndexForOutput: NO]];
    [soundOutputDriverPopup removeAllItems]; // remove placeholder, in a blitzkrieg kind of way...
    [soundOutputDriverPopup addItemsWithTitles: [SndStreamManager driverNamesForOutput: YES]];
    [soundOutputDriverPopup selectItemAtIndex: [streamManager assignedDriverIndexForOutput: YES]];
    NSLog(@"output devices: %@", [SndStreamManager driverNamesForOutput: YES]);
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
	SndPerformance *performance = [soundToPlay play];
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
	SndAudioProcessorChain *audioProcessorChain;
	
	soundToPlay = nil;
	liveFader = [[SndAudioFader alloc] init]; // Create the live fader.
	[liveFader setAmp: 1.0 clearingEnvelope: NO]; // TODO use [liveFaderSlider floatValue]
	sndFader = [[SndAudioFader alloc] init]; // Create the sound playback fader.
	[sndFader setAmp: 1.0 clearingEnvelope: NO];  // TODO use [sndFaderSlider floatValue]
	
	reverb = [[SndAudioProcessorReverb alloc] init];
	distortion = [[SndAudioProcessorDistortion alloc] init];
	[distortion setBoostAmount: 0.6];
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

	streamManager = [[SndStreamManager defaultStreamManager] retain];

	// TODO compute new output buffer size based on original size together with minimum
	// size = 128/44100 seconds.
#if 0
	if(![streamManager setHardwareBufferSize: BUFFER_SIZE])
	    NSLog(@"Unable to set the output buffer size to %d\n", BUFFER_SIZE);
#endif	
	
	[streamManager addClient: streamInput];
	NSLog(@"streamManager is %@", streamManager);
    }
    return self;
}

- (void) dealloc
{
    [streamManager release];
    streamManager = nil;
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
