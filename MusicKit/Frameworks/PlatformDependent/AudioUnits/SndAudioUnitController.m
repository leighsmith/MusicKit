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
    if (carbonView) {
	if(CloseComponent(carbonView) != noErr) {
	    NSLog(@"SndAudioUnitController: Unable to open audio unit carbon view component\n");
	    return NO;
	}
	carbonView = 0;
    }
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

- (BOOL) loadCarbonWindowEntitled: (NSString *) windowTitle inNibNamed: (NSString *) nibName
{
    CFBundleRef bundleRef;
    IBNibRef    nibRef;
    OSStatus    err;
    
    // Calls the Core Foundation Bundle Services function CFBundleGetBundleWithIdentifier to obtain an instance
    // of the framework's bundle (autoreleased).
    bundleRef = CFBundleGetBundleWithIdentifier((CFStringRef) @"org.musickit.SndKit");
    
    // Create a reference to the Carbon window's nib file.
    // The Core Foundation string you provide must be the name of the nib file, without the .nib extension.    
    err = CreateNibReferenceWithCFBundle(bundleRef, (CFStringRef) nibName, &nibRef); 

    if (err != noErr) {
	NSLog(@"failed to create carbon nib reference to %@", nibName);
	return NO;
    }
    
    // Call the IB Services function CreateWindowFromNib to unarchive the named Carbon window from the nib file.
    err = CreateWindowFromNib(nibRef, (CFStringRef) windowTitle, &auWindow); 
    
    if (err != noErr) {
	NSLog(@"failed to create carbon window %@ from nib %@", windowTitle, nibName);
	return NO;
    }
    
    // For historical reasons, contrary to normal memory management policy initWithWindowRef: does not retain windowRef.
    // It is therefore recommended that you make sure you retain windowRef before calling this method. If windowRef is
    // still valid when the Cocoa window is deallocated, the Cocoa window will release it. However, doing so seems to 
    // cause the windows to require two pushes of the close button.

    // Make the unarchived window visible.
    ShowWindow(auWindow);
    
    // Call the IB Services function DisposeNibReference to dispose of the reference to the nib file.
    // We should call this function immediately after finishing unarchiving an object.
    DisposeNibReference(nibRef);

    // wrap the Carbon AU window in a NSWindow instance, since it's easier to manage.
    cocoaAUWindow = [[NSWindow alloc] initWithWindowRef: auWindow];
    
    return YES;
}

- (BOOL) createCarbonWindowFromAudioUnit: (AudioUnit) editUnit displayComponent: (ComponentDescription *) inDesc
{
    NSSize windowSize;    
    ControlRef viewPane;
    Rect viewPaneControlBounds;
    ControlRef rootControl;
    Rect rootControlBounds;
    NSString *windowTitle;
    Component editComp = FindNextComponent(NULL, inDesc);
    
    if(editComp == NULL) {
	NSLog(@"SndAudioUnitController: Couldn't find Audio Unit editor Component: %4.4s %4.4s\n",
	      (char *) &inDesc->componentManufacturer, (char *) &inDesc->componentSubType);
	return NO;
    }

    [self closeView];
    
    if(OpenAComponent(editComp, &carbonView) != noErr) {
	NSLog(@"SndAudioUnitController: Unable to open audio unit carbon view component\n");
	return NO;
    }
    
    if(![self loadCarbonWindowEntitled: @"CarbonWindow" inNibNamed: @"AUCarbonWindow"])
	return NO;

    if(GetRootControl(auWindow, &rootControl) != noErr) {
	NSLog(@"SndAudioUnitController: Unable to GetRootControl\n");
	return NO;
    }
    
    GetControlBounds(rootControl, &rootControlBounds);
    Float32Point location = { kOffsetForAUView_X, kOffsetForAUView_Y };
    Float32Point size = { (Float32) rootControlBounds.right, (Float32) rootControlBounds.bottom };
        
    if(AudioUnitCarbonViewCreate(carbonView, editUnit, auWindow, rootControl, &location, &size, &viewPane) != noErr) {
	NSLog(@"SndAudioUnitController: Unable to AudioUnitCarbonViewCreate\n");
	return NO;
    }    
    
#if EVENT_LISTENING
    AudioUnitCarbonViewSetEventListener(carbonView, eventListener, self);
#endif
    
    GetControlBounds(viewPane, &viewPaneControlBounds);
    // NSLog(@"viewPane %p viewPaneControlBounds.top %d, viewPaneControlBounds.right %d, viewPaneControlBounds.left %d, viewPaneControlBounds.bottom %d\n",
    //	  viewPane, viewPaneControlBounds.top, viewPaneControlBounds.right, viewPaneControlBounds.left, viewPaneControlBounds.bottom);

    windowSize.width = viewPaneControlBounds.right - viewPaneControlBounds.left; 
    windowSize.height = viewPaneControlBounds.bottom - viewPaneControlBounds.top + 20;
        
    // NSLog(@"windowSize size (%f, %f)\n", windowSize.width, windowSize.height);
    
    // We have to do this with Carbon, since resizing using Cocoa methods doesn't seem to update the window in entirety.
    SizeWindow(auWindow, windowSize.width, windowSize.height, YES);    
    
    // NSLog(@"auWindow %p\n", auWindow);
    
    windowTitle = [NSString stringWithFormat: @"%@ inspector", [audioUnitProcessor name]];
    [cocoaAUWindow setTitle: windowTitle];
    [cocoaAUWindow setReleasedWhenClosed: NO];

    // NSLog(@"cocoaAUWindow %@ backingType %d\n", cocoaAUWindow, [cocoaAUWindow backingType]);
    
    return YES;
}

- (BOOL) createCarbonWindowFromAudioUnit: (AudioUnit) editUnit genericDisplayOnly: (BOOL) forceGeneric
{
    OSStatus err;
    ComponentDescription editorComponentDesc;
        
    [self closeView];
    
    // set up to use generic UI component
    editorComponentDesc.componentType = kAudioUnitCarbonViewComponentType;
    editorComponentDesc.componentSubType = 'gnrc';
    editorComponentDesc.componentManufacturer = 'appl';
    editorComponentDesc.componentFlags = 0;
    editorComponentDesc.componentFlagsMask = 0;
    
    if (!forceGeneric) {
	// ask the AU for its first editor component
	UInt32 propertySize;
	err = AudioUnitGetPropertyInfo(editUnit, kAudioUnitProperty_GetUIComponentList,
				       kAudioUnitScope_Global, 0, &propertySize, NULL);
	if (err == noErr) {
	    int nEditors = propertySize / sizeof(ComponentDescription);
	    ComponentDescription *editors = malloc(sizeof(ComponentDescription) * nEditors);
	    
	    err = AudioUnitGetProperty(editUnit, kAudioUnitProperty_GetUIComponentList,
				       kAudioUnitScope_Global, 0, editors, &propertySize);
	    if (!err) {
		// just pick the first one for now
		// TODO we should display all nEditors.
		editorComponentDesc = editors[0];
	    }

	    free(editors);
	}
	else {
	    NSLog(@"Unable to retrieve the UI component list property info err = %d", err); 
	}
    }
    
    return [self createCarbonWindowFromAudioUnit: editUnit displayComponent: &editorComponentDesc];
}

// Returns YES if able to create the carbon window and display it. NO if unable to display it.
- (BOOL) createCarbonWindowFromAudioUnit: (AudioUnit) audioUnit
{
    return [self createCarbonWindowFromAudioUnit: audioUnit genericDisplayOnly: NO];
}

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
    if (carbonView && !IsWindowActive(auWindow)) {	
	[self createCarbonWindowFromAudioUnit: [audioUnitProcessor audioUnit]];
	// NSLog(@"window not active, title %@ windowRef %p\n", [cocoaAUWindow title], auWindow);
    }
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
        // Instead create the Carbon UI in a separate window ready for display.
	return [self createCarbonWindowFromAudioUnit: audioUnit] ? self : nil;
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
	    NSLog(@"AudioUnitGetProperty(kAudioUnitProperty_CocoaUI) error %d cocoaViewInfo %p dataSize %d\n",
		  result, cocoaViewInfo, dataSize);
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
