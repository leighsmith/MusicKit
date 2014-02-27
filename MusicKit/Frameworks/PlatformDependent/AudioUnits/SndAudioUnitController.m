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

#import <AudioUnit/AudioUnit.h>
#import <AudioUnit/AUCocoaUIView.h>
#import <AudioUnit/AudioUnitCarbonView.h>
#import "SndAudioUnitController.h"

// TODO there currently isn't much point trapping modification of parameters since no mouse drag events are messaged.
#define EVENT_LISTENING 0
#define DEBUG_COCOA_VIEW 0

@implementation SndAudioUnitController

/*
 The host is responsible for releasing the fields in the  AudioUnitCocoaViewInfostruct before getting the Cocoa UI
 info from the audio unit. It is also responsiblefor cleaning up any additional bundles, views, and classes
 associated with the cocoa UI once it no longer needs them.
 
 We recommend that a host application look first for UI components applicable for the native framework of the
 application. IE, cocoa hosts should give a priority to cocoa UI components and carbon hosts should give priority
 to carbon-based userinterfaces. If a native UI component is not found, the host should load a nonnative user
 interface component in a separate window.
*/ 

// TODO perhaps these should be promoted to ivars?
static const float kOffsetForAUView_X = 0;
static const float kOffsetForAUView_Y = 0;

// verification method that returns true if the plugin class conforms to the protocol
// and responds to all of its methods
+ (BOOL) plugInClassIsValid: (Class) pluginClass
{
    if ([pluginClass conformsToProtocol: @protocol(AUCocoaUIBase)]) {
	if ([pluginClass instancesRespondToSelector: @selector(interfaceVersion)] &&
	    [pluginClass instancesRespondToSelector: @selector(uiViewForAudioUnit:withSize:)]) {
	    return YES;
	}
    }    
    return NO;
}

- (BOOL) closeView
{
    return YES;
}

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ of Audio Unit %@ and window %@", 
	[super description], audioUnitProcessor, cocoaAUWindow];
}

#if EVENT_LISTENING
static void eventListener(void *controller, AudioUnitCarbonView inView, 
			  const AudioUnitParameter *inParameter, AudioUnitCarbonViewEventID inEvent, 
			  const void *inEventParam)
{
    SndAudioUnitController *audioUnitController = (SndAudioUnitController *) controller;
    ComponentResult error;
    Float32 outValue;
    
    if(inEvent == kAudioUnitCarbonViewEvent_MouseDownInControl) {
	NSLog(@"eventListener message mouse down\n");
    }
    else if(inEvent == kAudioUnitCarbonViewEvent_MouseUpInControl) {
	NSLog(@"eventListener message mouse up\n");
    }
    NSLog(@"audioUnitProcessor %@ parameterID %d\n", [audioUnitController audioUnitProcessor], inParameter->mParameterID);
    // [[audioUnitController audioUnitProcessor] describeParameters];
    
    error = AudioUnitGetParameter(inParameter->mAudioUnit, inParameter->mParameterID, inParameter->mScope, inParameter->mElement, &outValue);
    if(error != noErr) {
	NSLog(@"Unable to get parameter %d\n", inParameter->mParameterID);
    }
    NSLog(@"parameter value %f\n", outValue); 	
}
#endif

// Creates the Cocoa View and assigns it into the Cocoa Window.
- (BOOL) createCocoaWindowFromAudioUnit: (AudioUnit) audioUnit 
		       andCocoaViewInfo: (AudioUnitCocoaViewInfo *) cocoaViewInfo
{
    NSURL    *viewBundleURL	= (NSURL *) cocoaViewInfo->mCocoaAUViewBundleLocation;
    NSBundle *viewBundle  	= [NSBundle bundleWithPath: [viewBundleURL path]];
    // Main Cocoa UI class name
    NSString *viewClassName	= (NSString *) cocoaViewInfo->mCocoaAUViewClass[0];		
    Class classOfViewFactory;
    id cocoaAUViewFactory;
    NSString *windowTitle;
    NSSize viewSize = {	640,480 }; // Punt the required size.
    
    if(viewBundle == nil) {
	NSLog(@"Error loading AU view's bundle %@", viewBundleURL);
	return NO;
    }
    
#if DEBUG_COCOA_VIEW
    NSLog(@"viewClassName %@\n", viewClassName);
    NSLog(@"URL %@\n", viewBundleURL);
    NSLog(@"mainBundle %@\n", [NSBundle mainBundle]);
    NSLog(@"before load ViewBundle %@\n", viewBundle);
    NSLog(@"executablePath %@\n", [viewBundle executablePath]);
#endif
    
    classOfViewFactory = [viewBundle classNamed: viewClassName];
    // make sure 'classOfViewFactory' implements the AUCocoaUIBase protocol
    if(![SndAudioUnitController plugInClassIsValid: classOfViewFactory]) {
	NSLog(@"SndAudioUnitController's main class %@ does not properly implement the AUCocoaUIBase protocol", classOfViewFactory);
	return NO;
    }
    
    if(![viewBundle load]) {
	NSLog(@"Unable to load bundle %@", viewBundle);
	return NO;
    }
    cocoaAUViewFactory = [[classOfViewFactory alloc] init];	// instantiate principal class

#if DEBUG_COCOA_VIEW
    NSLog(@"classOfViewFactory %@\n", classOfViewFactory);
    NSLog(@"cocoaAUViewFactory is %@", cocoaAUViewFactory);
    NSLog(@"superclassed from %@", [cocoaAUViewFactory superclass]);
    NSLog(@"viewBundle principleClass %@", [viewBundle principalClass]);
#endif
    
    // Now that the plugin is valid, we can get the UI view.
    audioUnitUIView = [cocoaAUViewFactory uiViewForAudioUnit: audioUnit
						    withSize: viewSize];
    
    // Create a Cocoa NSWindow instance to hold the AudioUnit view.
    // Nowdays returning the audioUnitUIView alone and not really dealing with the window would be better,
    // but at least we create a default window.
    cocoaAUWindow = [[NSWindow alloc] initWithContentRect: [audioUnitUIView bounds]
						styleMask: NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
						  backing: NSBackingStoreBuffered
						    defer: YES];
    
    windowTitle = [NSString stringWithFormat: @"%@ inspector", [audioUnitProcessor name]];
    [cocoaAUWindow setTitle: windowTitle];
    [cocoaAUWindow setReleasedWhenClosed: NO];
    [cocoaAUWindow setContentView: audioUnitUIView];	// replace the current view with the newly created AU view
    // NSLog(@"cocoaAUWindow %@ backingType %d\n", cocoaAUWindow, [cocoaAUWindow backingType]);

    // release cocoaViewInfo's objects
    [viewBundleURL release];
    return YES;
}

// This is totally bogus. We need to fix the cause of the problem which is Carbon windows 
// always releasing whenever closed, effectively ignoring the setReleaseWhenClosed: method
- (void) reinitializeController
{
    // Basically clicking on the close button of a SndAudioUnitController window, being a Carbon window, seems to release
    // the window, not hide it. Therefore we need to check if the window is inactive (closed) or not. If inactive,
    // We need to recreate the object.
}

- initWithAudioProcessor: (SndAudioUnitProcessor *) processor;
{
    UInt32 dataSize;
    Boolean isWritable;
    UInt32 numberOfClasses;
    AudioUnit audioUnit = [processor audioUnit];
    
    self = [self init];
    if(!self)
	return nil;
    
    [audioUnitProcessor release];
    audioUnitProcessor = [processor retain];
    
    // get AU's Cocoa view property if it exists.
    OSStatus result = AudioUnitGetPropertyInfo(audioUnit, kAudioUnitProperty_CocoaUI, kAudioUnitScope_Global, 0, &dataSize, &isWritable);
    numberOfClasses = (dataSize - sizeof(CFURLRef)) / sizeof(CFStringRef);
    // NSLog(@"numberOfClasses %d dataSize %d, isWritable %d\n", numberOfClasses, dataSize, isWritable);
    
    carbonView = 0; // default.
    if ((result != noErr) || (numberOfClasses == 0)) {
        // If we get here, the audio unit does not have a Cocoa UI.
        // Now that Carbon UI's are deprecated, we just return nil.
	return nil;
    } 
    else {
	AudioUnitCocoaViewInfo *cocoaViewInfo = (AudioUnitCocoaViewInfo *) malloc(dataSize);
	BOOL createdCocoaWindow;
	result = AudioUnitGetProperty(audioUnit,
				      kAudioUnitProperty_CocoaUI,
				      kAudioUnitScope_Global,
				      0,
				      cocoaViewInfo,
				      &dataSize);
	if(result != noErr) {
	    NSLog(@"AudioUnitGetProperty(kAudioUnitProperty_CocoaUI) error %ld cocoaViewInfo %p dataSize %u\n",
		  (long) result, cocoaViewInfo, (UInt32) dataSize);
	    return nil;
	}
	createdCocoaWindow = [self createCocoaWindowFromAudioUnit: audioUnit andCocoaViewInfo: cocoaViewInfo];

	UInt32 classIndex;
	for (classIndex = 0; classIndex < numberOfClasses; classIndex++)
	    CFRelease(cocoaViewInfo->mCocoaAUViewClass[classIndex]);
	free (cocoaViewInfo);    

	return createdCocoaWindow ? self : nil;
    }
    return self;
}

- (SndAudioUnitProcessor *) audioUnitProcessor
{
    return [[audioUnitProcessor retain] autorelease];
}

- (void) dealloc
{
    [audioUnitProcessor release];
    audioUnitProcessor = nil;
    [cocoaAUWindow release];
    cocoaAUWindow = nil;
    [super dealloc];
}

- (NSWindow *) window
{
    return [[cocoaAUWindow retain] autorelease];
}

- (NSView *) contentView
{
    return [[audioUnitUIView retain] autorelease];
}

@end
