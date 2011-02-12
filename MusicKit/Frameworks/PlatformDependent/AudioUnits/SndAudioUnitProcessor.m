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

#import "SndAudioUnitProcessor.h"
#import <AudioToolbox/AudioUnitUtilities.h>

@implementation SndAudioUnitProcessor

static NSMutableDictionary *namedComponents = nil;

// General routine to retrieve a device property, performing error checking.
static BOOL getAudioUnitProperty(AudioUnit au, AudioUnitPropertyID propertyType, AudioUnitScope scope, AudioUnitElement element, void *buffer, int maxBufferSize)
{
    ComponentResult AUstatus;
    UInt32 propertySize;
    Boolean propertyWritable;
    
    AUstatus = AudioUnitGetPropertyInfo(au, propertyType, scope, element, &propertySize, &propertyWritable);
    if (AUstatus) {
        NSLog(@"getDeviceProperty AudioDeviceGetPropertyInfo property %4s: %d\n", (char *) propertyType, AUstatus);
        return FALSE;
    }
    
    if(propertySize > maxBufferSize) {
        NSLog(@"getAudioUnitProperty property %4s: size %d larger than available buffer size %d\n",
	      (char *) propertyType, propertySize, maxBufferSize);
        return FALSE;
    }
    
    AUstatus = AudioUnitGetProperty(au, propertyType, scope, element, buffer, &propertySize);
    if (AUstatus) {
        NSLog(@"getAudioUnitProperty AudioUnitGetProperty %4s: %d\n", (char *) propertyType, AUstatus);
        return FALSE;
    }
    
    return TRUE;
}

// Retrieves the text describing the AudioUnit as described by it's component.
// This takes the form of "Manufacturer: Audio Unit Name"
+ (NSString *) getComponentDescription: (Component) theComponent
{
    NSString *componentDescription;
    Handle componentInfoHandle = NewHandle(4);
    ComponentDescription mCompDesc;
    OSStatus err = GetComponentInfo(theComponent, &mCompDesc, componentInfoHandle, 0, 0);
    
    if (err) 
	return nil;
    
    HLock(componentInfoHandle);
    char *componentDescriptionPtr = *componentInfoHandle;
    int len = *componentDescriptionPtr++;
    
    componentDescriptionPtr[len] = 0;
    
    componentDescription = [NSString stringWithUTF8String: componentDescriptionPtr];
    
    DisposeHandle(componentInfoHandle);
    
    return componentDescription;
}

+ (SndAudioProcessor *) audioProcessorNamed: (NSString *) processorName
{
    return [[[SndAudioUnitProcessor alloc] initWithParameterDictionary: nil 
								  name: processorName] autorelease];
}

// Provide a list of the AUs which are available. 
+ (NSArray *) availableAudioProcessors
{
    NSMutableArray *audioUnitNameArray;
    ComponentDescription desc;
    Component theAUComponent;
#if 0
    // Get the superclasses list for merging.
    NSArray *audioProcessorNames = [super availableAudioProcessors];
#endif
    
    desc.componentType = kAudioUnitType_Effect; //'aufx'
    desc.componentSubType = 0;
    desc.componentManufacturer = 0;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;

    // NSLog(@"Found %ld Effect Audio Units\n", CountComponents(&desc));

    theAUComponent = FindNextComponent(NULL, &desc);
    
    if(namedComponents != nil) {
	[namedComponents release];
    }
    namedComponents = [[NSMutableDictionary dictionaryWithCapacity: CountComponents(&desc)] retain];
    audioUnitNameArray = [NSMutableArray arrayWithCapacity: CountComponents(&desc)];
    
    while (theAUComponent != NULL) {
	// now we need to get the information on the found component
        ComponentDescription found;
	NSString *componentDescription;
	NSArray *componentFields;
	
        GetComponentInfo(theAUComponent, &found, 0, 0, 0);

#if 0
        NSLog(@"%4.4s - ", (char *) &(found.componentType));
        NSLog(@"%4.4s - ", (char *) &(found.componentSubType));
        NSLog(@"%4.4s,", (char *) &(found.componentManufacturer));
        NSLog(@"%lx,%lx\n", found.componentFlags, found.componentFlagsMask);
#endif
	componentDescription = [self getComponentDescription: theAUComponent];
	
	[audioUnitNameArray addObject: componentDescription];
	componentFields = [NSArray arrayWithObjects: [NSNumber numberWithUnsignedInt: found.componentManufacturer],
						     [NSNumber numberWithUnsignedInt: found.componentSubType],
					             nil];
	[namedComponents setObject: componentFields forKey: componentDescription];

        theAUComponent = FindNextComponent(theAUComponent, &desc);
    }

#if 0
    return [audioProcessorNames arrayByAddingObjectsFromArray: audioUnitNameArray];
#else
    return [NSArray arrayWithArray: audioUnitNameArray];
#endif
}

- (AudioUnit) audioUnit
{
    return audioUnit;
}

// Provide the audio data into ioData
// get source data for the supplied bus number
// ioData will contain a valid list of AUBuffers
// These AUBuffers will also contain allocated memory in their mData fields
// We must put the audio data into those mData fields.
// If the client has NO Data, then it is responsible for
// setting the data to zero - ie. silence - see memset(...)
static OSStatus auInputCallback(void *inRefCon, 
				AudioUnitRenderActionFlags *inActionFlags,
				const AudioTimeStamp *inTimeStamp, 
				UInt32 inBusNumber,
				UInt32 inNumFrames, 
				AudioBufferList *theAudioData)
{
    SndAudioUnitProcessor *audioUnitProcessor = inRefCon;

    if(audioUnitProcessor->auIsNonInterleaved) {
	// Deinterleave the buffers in order to process them, then reassemble in processReplacingInputBuffer:.
#if ALTIVEC
	// TODO Use Altivec permute instruction to do this.
#else
	unsigned int channelIndex;
	// If there is a mismatch in channels, we take a subset of channels from the interleaved input samples.
	// If there are more channels processed by an AudioUnit than interleaved input samples, we just supply whatever we have,
	// erroneously leaving some channels unfilled.
	// The AudioBufferList has a number of buffers, each to hold one channel, so the number of buffers matches the number of
	// expected AudioUnit channels.
	// TODO we should expand to match the number of AU channels with duplicated data.
	// TODO We really should take the appropriate stereo channels, rather than just the first minimum number,
	// but we probably need a smarter channel remapping algorithm, i.e stereo->5.1, 5.1->stereo etc.
	unsigned int channelCount = MIN(theAudioData->mNumberBuffers, audioUnitProcessor->inputChannelCount);
	
	for (channelIndex = 0; channelIndex < channelCount; channelIndex++) {
	    unsigned int frameIndex;

	    for(frameIndex = 0; frameIndex < inNumFrames; frameIndex++) {
		((float *) theAudioData->mBuffers[channelIndex].mData)[frameIndex] = audioUnitProcessor->interleavedInputSamples[frameIndex * audioUnitProcessor->inputChannelCount + channelIndex];
	    }
	}
#endif
    }
    else {
	NSLog(@"unimplemented non-interleaved audio unit!\n");
    }
    
    return noErr;
}

// We need to retrieve the parameterID list and retain it, for mapping monotonic SndAudioProcessor parameter indexes
// to potentially non-contiguous AudioUnitParameterIDs. We need to check the size of array returned, so we don't use
// getAudioUnitProperty().
- (void) discoverParameters
{
    ComponentResult AUstatus;
    UInt32 propertySize;
    Boolean propertyWritable;
    
    AUstatus = AudioUnitGetPropertyInfo(audioUnit, kAudioUnitProperty_ParameterList, kAudioUnitScope_Global, inputBusNumber, &propertySize, &propertyWritable);
    if (AUstatus) {
        NSLog(@"discoverParameters AudioDeviceGetPropertyInfo property %4s: %d\n", (char *) kAudioUnitProperty_ParameterList, AUstatus);
        return;
    }
    
    parameterListLength = propertySize / sizeof(AudioUnitParameterID);
    if((parameterIDList = malloc(propertySize)) == NULL)
	NSLog(@"unable to allocate memory for %ld parameters\n", parameterListLength);
        
    AUstatus = AudioUnitGetProperty(audioUnit, kAudioUnitProperty_ParameterList, kAudioUnitScope_Global, inputBusNumber, parameterIDList, &propertySize);
    if (AUstatus) {
        NSLog(@"discoverParameters AudioUnitGetProperty %4s: %d\n", (char *) kAudioUnitProperty_ParameterList, AUstatus);
        return;
    }
    
    [self setNumParams: parameterListLength];
}

// TODO Need to create a delegate for notification of parameter changes
// and drive it from the AudioUnit parameter notification call-back

- (float) paramValue: (const int) index
{
    Float32 parameterValue;
    ComponentResult AUstatus;
    
    AUstatus = AudioUnitGetParameter(audioUnit, parameterIDList[index], kAudioUnitScope_Global, inputBusNumber, &parameterValue);
    if (AUstatus) {
        NSLog(@"paramValue: AudioUnitGetParameter %ld: %d\n", parameterIDList[index], AUstatus);
        return 0.0f;
    }
    
    return parameterValue;
}

////////////////////////////////////////////////////////////////////////////////
// paramName:
////////////////////////////////////////////////////////////////////////////////

- (NSString *) paramName: (const int) index
{
    AudioUnitParameterInfo parameterInfo;
        
    if(getAudioUnitProperty(audioUnit, kAudioUnitProperty_ParameterInfo, kAudioUnitScope_Global, parameterIDList[index], &parameterInfo, sizeof(parameterInfo))) {
	if(parameterInfo.flags & kAudioUnitParameterFlag_HasCFNameString)
	    return [NSString stringWithString: (NSString *) parameterInfo.cfNameString];
	else
	    return [NSString stringWithUTF8String: parameterInfo.name];
    }
    else
	return [super paramName: index];
}

////////////////////////////////////////////////////////////////////////////////
// paramLabel:
////////////////////////////////////////////////////////////////////////////////

- (NSString*) paramLabel: (const int) index
{
    AudioUnitParameterInfo parameterInfo;
    
    // use the kAudioUnitProperty_ParameterInfo property to retrieve the unit identifier for the given ParameterID.		
    if(getAudioUnitProperty(audioUnit, kAudioUnitProperty_ParameterInfo, kAudioUnitScope_Global, parameterIDList[index], &parameterInfo, sizeof(parameterInfo))) {
	switch(parameterInfo.unit) {
	case kAudioUnitParameterUnit_Boolean:
	    return @"Yes/No";
	case kAudioUnitParameterUnit_Percent:
	    return @"%";
	case kAudioUnitParameterUnit_Seconds:
	    return @"seconds";
	case kAudioUnitParameterUnit_SampleFrames:
	    return @"samples";
	case kAudioUnitParameterUnit_Phase:
	    return @"radians";
	case kAudioUnitParameterUnit_Rate:
	    return @"seconds";
	case kAudioUnitParameterUnit_Hertz:
	    return @"Hz";
	case kAudioUnitParameterUnit_AbsoluteCents:
	case kAudioUnitParameterUnit_Cents:
	    return @"cents";
	case kAudioUnitParameterUnit_RelativeSemiTones:
	    return @"semitones";
	case kAudioUnitParameterUnit_MIDINoteNumber:
	    return @"MIDI Note number";
	case kAudioUnitParameterUnit_MIDIController:
	    return @"MIDI Controller";
	case kAudioUnitParameterUnit_Decibels:
	    return @"deciBels";
	case kAudioUnitParameterUnit_LinearGain:
	    return @"Linear Gain";
	case kAudioUnitParameterUnit_Degrees:
	    return @"degrees";
	case kAudioUnitParameterUnit_Pan:
	    return @"Left/Right";
	case kAudioUnitParameterUnit_Meters:
	    return @"Meters";
	case kAudioUnitParameterUnit_EqualPowerCrossfade:
	    return @"%";
	case kAudioUnitParameterUnit_MixerFaderCurve1:
	case kAudioUnitParameterUnit_Indexed:
	    // return [NSString stringWithFormat: @"parameter unit %d", parameterInfo.unit];
	case kAudioUnitParameterUnit_Generic:
	default:
	    return @"";
	}
    }
    else
	return [super paramLabel: index];
}

////////////////////////////////////////////////////////////////////////////////
// paramDisplay:
////////////////////////////////////////////////////////////////////////////////

- (NSString *) paramDisplay: (const int) index
{
    // The host can use the kAudioUnitProperty_ParameterInfo property to retrieve specific information about a given ParameterID.		
    return [NSString stringWithFormat: @"%03f", [self paramValue: index]];
}

////////////////////////////////////////////////////////////////////////////////
// setParam:toValue:
////////////////////////////////////////////////////////////////////////////////

- (void) setParam: (const int) index toValue: (const float) parameterValue
{
    ComponentResult AUstatus;
    
    AUstatus = AudioUnitSetParameter(audioUnit, parameterIDList[index], kAudioUnitScope_Global, inputBusNumber, parameterValue, 0);
    if (AUstatus) {
        NSLog(@"setParam:toValue: AudioUnitSetParameter %ld: %d\n", parameterIDList[index], AUstatus);
        return;
    }
}

- (void) messageDelegateOfParameter: (int) parameterID value: (float) inValue
{
    id delegate = [self parameterDelegate];
    
    if(delegate) {
	unsigned int parameterIndex;
	
	for(parameterIndex = 0; parameterIndex < parameterListLength; parameterIndex++) {
	    if(parameterIDList[parameterIndex] == parameterID)
		[delegate parameter: parameterIndex ofAudioProcessor: self didChangeTo: inValue];
	}
    }
}

static void parameterListener(void *audioProcessorInstance, void *inObject, const AudioUnitParameter *inParameter, Float32 inValue)
{
#if 1
    [(SndAudioUnitProcessor *) audioProcessorInstance messageDelegateOfParameter: inParameter->mParameterID value: inValue];
#else
    NSLog(@"parameter %d changed to %f\n", inParameter->mParameterID, inValue);
#endif	
}

// Set up a parameter listener to report any parameter changes. 
// In theory, we could simply listen to controller changes using AudioUnitCarbonViewSetEventListener()
// however these messages are only called when the user clicks or releases the mouse, it doesn't indicate mouse drag parameter changes.
// Note that only parameter changes issued through AUParameterSet will generate notifications to listeners. Luckily this interface
// is used by the AudioUnit controllers. We register to be notified of all parameters changing.
- (void) registerParameterListener
{
    AUParameterListenerRef outListener;
    AudioUnitParameter parameterToMonitor;
    int parameterIndex;
    
    for(parameterIndex = 0; parameterIndex < parameterListLength; parameterIndex++) {
	OSStatus error = AUListenerCreate(parameterListener, self, NULL, NULL, 0.0, &outListener);
	if(error != 0) // TODO need better constant than 0
	    NSLog(@"Unable to AUListenerCreate %d\n", error);
	
	parameterToMonitor.mAudioUnit = audioUnit;
	parameterToMonitor.mParameterID = parameterIDList[parameterIndex];
	parameterToMonitor.mScope = kAudioUnitScope_Global;
	parameterToMonitor.mElement = 0; // TODO this shouldn't be hardwired
	
	error = AUListenerAddParameter(outListener, NULL, &parameterToMonitor);
	if(error != 0) // TODO need better constant than 0
	    NSLog(@"Unable to AUListenerAddParameter %d\n", error);
    }
}

// set stream format property
// TODO this should probably be inside the processReplacingInputBuffer: method.
- (void) setStreamFormat: (SndFormat) streamFormat
{ 
    AudioStreamBasicDescription newStreamFormat;
    ComponentResult result;
    
    newStreamFormat.mSampleRate = streamFormat.sampleRate;
    newStreamFormat.mFormatID = kAudioFormatLinearPCM;
    newStreamFormat.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    newStreamFormat.mBytesPerPacket = 4;        
    newStreamFormat.mFramesPerPacket = 1;       
    newStreamFormat.mBytesPerFrame = 4;         
    newStreamFormat.mChannelsPerFrame = streamFormat.channelCount;      
    newStreamFormat.mBitsPerChannel = sizeof(Float32) * 8;     
    
    result = AudioUnitSetProperty(audioUnit, 
				  kAudioUnitProperty_StreamFormat,
				  kAudioUnitScope_Input,
				  inputBusNumber,
				  &newStreamFormat,
				  sizeof(newStreamFormat));
    if(result != 0)
	NSLog(@"Setting kAudioUnitProperty_StreamFormat result %d\n", result);
}

- initWithParamCount: (const int) count name: (NSString *) audioUnitName
{
    Component auComp;
    OSErr result;
    AURenderCallbackStruct auRenderCallback;
    
    self = [super initWithParamCount: count name: audioUnitName];

    if (self != nil) {
	ComponentDescription desc;
	AudioStreamBasicDescription auFormatDescription;
	// Run through the list of audio units [SndAudioUnitProcessor availableAudioUnits] cached into class ivar.
	NSArray *componentArray = [namedComponents valueForKey: audioUnitName];
	OSType manufacturer = [[componentArray objectAtIndex: 0] unsignedIntValue]; 
	OSType subType = [[componentArray objectAtIndex: 1] unsignedIntValue];

	desc.componentType = kAudioUnitType_Effect; //'aufx'
	desc.componentSubType = subType;
	desc.componentManufacturer = manufacturer; //'appl' etc.
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;

	// Fairly typical input and output bus defaults for the majority of AudioUnits.
	inputBusNumber = 0;
	inputChannelCount = 2;
	outputBusNumber = 0;
	
	//NSLog(@"initialising %4.4s - %4.4s - %4.4s\n", 
	//      (char *) &(desc.componentType), (char *) &(desc.componentSubType), (char *) &(desc.componentManufacturer));

	auComp = FindNextComponent(NULL, &desc);
	if (auComp == NULL) {
	    NSLog(@"didn't find the component\n");
	    return nil;
	}
	
	if ((result = OpenAComponent(auComp, &audioUnit)) != 0) {
	    NSLog(@"Error: %d opening AudioUnit\n", result);
	    return nil;
	}

	// After opening an Audio Unit component, it must be initialized.
	// Initialization of an Audio Unit can be an expensive operation, as it can involve the
	// acquisition of assets (e.g. a sound bank for a MusicDevice),
	// allocation of memory buffers required for the processing involved within
	// the unit, and so forth. Once a unit is initialized it is basically in a
	// state in which it can be largely expected to do work.
	
	if ((result = AudioUnitInitialize(audioUnit)) != 0) {
	    NSLog(@"Error: %d initialising AudioUnit\n", result);
	    return nil;
	}

	// The input and output capability of any audio unit is published through the
	// kAudioUnitProperty_BusCount property.
	// An effect unit will generally have a single bus, represented in the audio unit as a single input element where
	// elementID is equal to zero, and a single output element where elementID is equal to zero.

	// If an effect unit has either a restriction (say it can only process stereo input to stereo output),
	// or has some flexibility then the audio unit must publish this capability through supporting the
	// kAudioUnitProperty_SupportedNumChannels property.
	
	if(!getAudioUnitProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &auFormatDescription, sizeof(auFormatDescription)))
	    return nil;
	
	auIsNonInterleaved = (auFormatDescription.mFormatFlags & kAudioFormatFlagIsNonInterleaved) == kAudioFormatFlagIsNonInterleaved;
#if 0
	NSLog(@"native format number of channels %d\n", ([Snd nativeFormat]).channelCount);
	NSLog(@"Number of channels for Audio Unit %d\n", auFormatDescription.mChannelsPerFrame);
	NSLog(@"non-interleaved %d\n", auIsNonInterleaved);
#endif

	[self setStreamFormat: [Snd nativeFormat]];
	
	// OK, now we have the AudioUnit, set the render callback member function 
	// which will supply the audio data to the Audio Unit in a "pull" operation. 
	// SndAudioProcessors use a "push" operation, so we need to prime the audio 
	// data in processReplacingInputBuffer:outputBuffer: before calling the AudioUnitRender function.
	
	auRenderCallback.inputProc = auInputCallback;
	auRenderCallback.inputProcRefCon = self; // store the instance pointer so we can retrieve ivars in the callback.
	
	// Set up render callback
	result = AudioUnitSetProperty(audioUnit, 
			      kAudioUnitProperty_SetRenderCallback,
			      kAudioUnitScope_Input,
			      inputBusNumber,
			      &auRenderCallback,
			      sizeof(auRenderCallback));
	if(result != 0)
	    NSLog(@"Setting kAudioUnitProperty_SetRenderCallback result %d\n", result);
	
	[self discoverParameters];
	[self registerParameterListener];
    }
    return self;
}

- (void) dealloc
{ 
    // When we're finished with it
    CloseComponent(audioUnit);
    audioUnit = 0;
    if(parameterIDList != NULL)
	free(parameterIDList);
    parameterIDList = NULL;
    [super dealloc];
}    

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ %@ input bus: %d output bus: %d",
	[super description], [self name], inputBusNumber, outputBusNumber];
}

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer *) inputAudioBuffer
                        outputBuffer: (SndAudioBuffer *) outputAudioBuffer
{
    ComponentResult result;
    int channelIndex;
    int channelCount = [outputAudioBuffer channelCount];
    int minimumChannelCount;
    int bufferLengthInFrames = [outputAudioBuffer lengthInSampleFrames];
    float *interleavedOutputSamples = [outputAudioBuffer bytes];
    AudioUnitRenderActionFlags actionFlags = 0;
    AudioTimeStamp auTimeStamp;

    // Save the input data for the render callback.
    interleavedInputSamples = [inputAudioBuffer bytes];
    inputChannelCount = [inputAudioBuffer channelCount];
    
    // update AudioUnit's time against the audioProcessorChain current time (in frames).
    auTimeStamp.mSampleTime = [audioProcessorChain nowTime] * [inputAudioBuffer samplingRate]; 
    auTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    
    // A bus in an audio unit can contain n-channels of audio data, and for a V2 unit, these n-channels are deinterleaved,
    // mono channels. A bus of audio data is represented by the AudioBufferList structure, a structure that contains a
    // collection of AudioBuffers. Thus, each of these buffers will generally contain a single channel of audio data.

    // this allocates enough space for a buffer list with channelCount AudioBuffers in it
    AudioBufferList *theAudioData = 
	(AudioBufferList *) malloc(offsetof(AudioBufferList, mBuffers[channelCount]));
    
    theAudioData->mNumberBuffers = channelCount;
    
    // set up each of the buffers for each of the output channels
    for (channelIndex = 0; channelIndex < channelCount; channelIndex++) {
        theAudioData->mBuffers[channelIndex].mNumberChannels = 1;
        theAudioData->mBuffers[channelIndex].mDataByteSize = bufferLengthInFrames * sizeof(float);
	theAudioData->mBuffers[channelIndex].mData = NULL;
    }
    
    // NSLog(@"rendering %d channels to audioUnit %p of buffer %d frames length\n", channelCount, audioUnit, bufferLengthInFrames);
    result = AudioUnitRender(audioUnit, &actionFlags, &auTimeStamp, outputBusNumber, bufferLengthInFrames, theAudioData); 
    if(result != noErr) {
	NSLog(@"Unable to AudioUnitRender at %f, error %ld see AudioUnit/AUComponent.h\n", auTimeStamp.mSampleTime, result);
	return NO;
    }
    
    // now we have the rendered audio data in theAudioData,
    // interleave the audio unit result into the output buffer.
    if(auIsNonInterleaved) {
#if ALTIVEC
	// TODO
#else
	// Only retrieve the minimum number of channels if the AudioUnit processes a different number than the output audio buffer.
	// TODO We should be using speaker configuration to map channels.
	minimumChannelCount = MIN(theAudioData->mNumberBuffers, channelCount);
	for (channelIndex = 0; channelIndex < minimumChannelCount; channelIndex++) {
	    unsigned int frameIndex;
	    
	    for(frameIndex = 0; frameIndex < bufferLengthInFrames; frameIndex++) {
		interleavedOutputSamples[frameIndex * channelCount + channelIndex] = ((float *) theAudioData->mBuffers[channelIndex].mData)[frameIndex];
	    }
	}
#endif	
    }
    else {
	NSLog(@"unimplemented interleaved audio unit!\n");
	return NO;
    }
    
    // we're done - remember to free!!!
    free(theAudioData);
    
    // TODO this should change depending on whether the audio unit modifies the output. Most audio units produce output in the nominated output buffer.
    return YES;
}

@end
