////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    See Class headerdoc description below.
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#if HAVE_CONFIG_H
# import "SndKitConfig.h"
#endif

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "SndStreamArchitectureView.h"
#import "SndStreamClient.h"
#import "SndStreamMixer.h"
#import "SndAudioProcessorInspector.h"
#import "SndAudioProcessorDelay.h"
#import "SndAudioProcessorDistortion.h"
#import "SndAudioProcessorFlanger.h"
#import "SndAudioProcessorNoiseGate.h"
#import "SndAudioProcessorMP3Encoder.h"
#import "SndAudioProcessorRecorder.h"
#import "SndAudioProcessorReverb.h"
#import "SndAudioProcessorToneGenerator.h"

static SndAudioProcessorInspector* defaultInspector = nil;

@implementation SndAudioProcessorInspector

////////////////////////////////////////////////////////////////////////////////
// defaultAudioProcessorInspector
////////////////////////////////////////////////////////////////////////////////

+ defaultAudioProcessorInspector
{
    if (defaultInspector == nil) {
	// Force registration of all known SndAudioProcessor classes
	[SndAudioProcessor registerAudioProcessorClass: [SndAudioProcessorDelay class]];
	[SndAudioProcessor registerAudioProcessorClass: [SndAudioProcessorDistortion class]];
	[SndAudioProcessor registerAudioProcessorClass: [SndAudioProcessorFlanger class]];
	[SndAudioProcessor registerAudioProcessorClass: [SndAudioProcessorNoiseGate class]];
	[SndAudioProcessor registerAudioProcessorClass: [SndAudioProcessorReverb class]];
#if HAVE_LIBMP3LAME && HAVE_LIBSHOUT
	[SndAudioProcessor registerAudioProcessorClass: [SndAudioProcessorMP3Encoder class]];
#endif
#if HAVE_LIBSNDFILE
	[SndAudioProcessor registerAudioProcessorClass: [SndAudioProcessorRecorder class]];
#endif
	[SndAudioProcessor registerAudioProcessorClass: [SndAudioProcessorToneGenerator class]];
	defaultInspector = [[SndAudioProcessorInspector alloc] init];
    }
    return defaultInspector;
}

////////////////////////////////////////////////////////////////////////////////
// initWithAudioProcessor:
////////////////////////////////////////////////////////////////////////////////

- initWithAudioProcessor: (SndAudioProcessor *) anAudProc
{
    if (defaultInspector != nil)
	self = defaultInspector;
    else {
	self = [super init];
	
	if([NSBundle loadNibNamed: @"SndAudioProcessorInspector" owner: self]) {
	    [window makeKeyAndOrderFront: self];
	    {
		NSArray *tableColumns = [parameterTableView tableColumns];
		id tcN = [tableColumns objectAtIndex: 0];
		id tcV = [tableColumns objectAtIndex: 1];
		
		[tcN setIdentifier: @"Name"];
		[tcN setEditable: NO];
		[tcV setIdentifier: @"Value"];
		[tcV setEditable: NO];
	    }
	    [sndArchView setDelegate: self];
	    
	    {
		NSArray *fxClassesArray = [SndAudioProcessor fxClasses];
		int i, c = [fxClassesArray count];
		
		[fxChooser removeAllItems];
		for (i = 0; i < c; i++) {
		    NSString *className = NSStringFromClass([[fxClassesArray objectAtIndex: i] class]);
		    [fxChooser addItemWithObjectValue: className];
		}
		[fxChooser selectItemAtIndex: 0];
	    }	    
	}
    }
    [self setAudioProcessor: anAudProc];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    return [self initWithAudioProcessor: nil];
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  if (theAudProc != nil)
    [theAudProc release];
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// setAudioProcessor:
////////////////////////////////////////////////////////////////////////////////

- setAudioProcessor: (SndAudioProcessor *) anAudProc
{
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndex: 0];
    
    if (theAudProc != nil)
	[theAudProc release];
    theAudProc = [anAudProc retain];
    [processorName setStringValue: [theAudProc name]];
    
    [parameterTableView selectRowIndexes: indexes byExtendingSelection: NO];
    [parameterValueSilder setFloatValue: [theAudProc paramValue: 0]];
    [parameterTableView setDataSource: self];
    
    [parameterTableView reloadData];
    [processorActive setIntValue: [theAudProc isActive]];
    return self;
}

////////////////////////////////////////////////////////////////////////////////
// onProcessorActive:
////////////////////////////////////////////////////////////////////////////////

- onProcessorActive: (id) sender
{
  [theAudProc setActive: [sender intValue]];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// onParameterValueSlider:
////////////////////////////////////////////////////////////////////////////////

- onParameterValueSlider: (id) sender
{
  int r = [parameterTableView selectedRow];
  [theAudProc setParam: r toValue: [sender doubleValue]];
  [parameterValueSilder setDoubleValue: [theAudProc paramValue: r]];

  [parameterTableView reloadData];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// tableView:didClickTableColumn:
////////////////////////////////////////////////////////////////////////////////

- (void)tableView:(NSTableView*)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
  if (theAudProc != nil) {
    int row = [tableView selectedRow];
    [parameterValueSilder setFloatValue: [theAudProc paramValue: row]];
    [parameterValueSilder setNeedsDisplay: YES];
  }
}

////////////////////////////////////////////////////////////////////////////////
// parameterTableAction:
////////////////////////////////////////////////////////////////////////////////

- parameterTableAction: (id) sender
{
  int r = [parameterTableView clickedRow];
//  printf("row: %i\n",r);
  if (theAudProc != nil) {
    [parameterValueSilder setFloatValue:  [theAudProc paramValue: r]];
    [parameterValueSilder setNeedsDisplay: YES];
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// numberOfRowsInTableView:
////////////////////////////////////////////////////////////////////////////////

- (NSInteger) numberOfRowsInTableView: (NSTableView *) aTableView
{
  if (theAudProc != nil)
    return [theAudProc paramCount];
  else
    return 0;
}

////////////////////////////////////////////////////////////////////////////////
// tableView:objectValueForTableColumn:row:
////////////////////////////////////////////////////////////////////////////////

- (id) tableView: (NSTableView*) aTableView objectValueForTableColumn: (NSTableColumn*) aTableColumn
             row: (NSInteger) rowIndex
{
  if ([[aTableColumn identifier] isEqualToString: @"Name"]) {
    
      return [theAudProc paramName: rowIndex];
  }
  else {
    id obj = [theAudProc paramObjectForIndex: rowIndex];

    if ([obj isKindOfClass: [NSString class]]) {
      return obj;
    }
    else if ([obj isKindOfClass: [NSValue class]]){
      NSValue *v = obj;
      const char* type = [v objCType];

      if (strcmp(type,@encode(float)) == 0) {
        float f;
        [v getValue: &f];
        return [NSString stringWithFormat: @"%.3f", f];
      }
      else if (strcmp(type,@encode(int)) == 0) {
        int i;
        [v getValue: &i];
        return [NSString stringWithFormat: @"%i", i];
      }
    }
  }
  NSLog(@"SndAudioProcessor param type not supported yet - code it!\n");
  return nil;
}

////////////////////////////////////////////////////////////////////////////////
// didSelectObject:
////////////////////////////////////////////////////////////////////////////////

- didSelectObject: (id) sndAudioArchObject
{
  if ([sndAudioArchObject isKindOfClass: [SndAudioProcessor class]])
    [self setAudioProcessor: sndAudioArchObject];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// onAddFxButton:
////////////////////////////////////////////////////////////////////////////////

- onAddFxButton: (id) sender
{
  id currentObj = [sndArchView currentlySelectedAudioArchObject];
  
  if ([currentObj isKindOfClass: [SndStreamClient class]] ||
      [currentObj isKindOfClass: [SndStreamMixer class]]) {
    id fxClass = [[SndAudioProcessor fxClasses] objectAtIndex: [fxChooser indexOfSelectedItem]];
    SndAudioProcessor *newFX = [[fxClass alloc] init];
    [[currentObj audioProcessorChain] addAudioProcessor: newFX];
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// onDelFxButton:
////////////////////////////////////////////////////////////////////////////////

- onDelFxButton: (id) sender
{
  id currentObj = [sndArchView currentlySelectedAudioArchObject];
  if ([currentObj isKindOfClass: [SndAudioProcessor class]]) {
    SndAudioProcessorChain* apc = [currentObj audioProcessorChain];
    [sndArchView clearCurrentlySelectedAudioArchObject];
    [apc removeAudioProcessor: currentObj];
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////

@end // Of SndAudioProcessorInspector implementation
