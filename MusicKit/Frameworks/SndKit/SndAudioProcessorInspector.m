////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorInspector.m
//  SndKit
//
//  Created by SKoT McDonald on Fri Dec 21 2001.
//  Copyright (c) 2001 tomandandy. All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////

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

+ defaultAudioProcessorInspector
{
  if (defaultInspector == nil) {
    // Force registration of all known SndAudioProcessor classes
    [SndAudioProcessor registerAudioProcessorClass: [SndAudioProcessorDelay class]];
    [SndAudioProcessor registerAudioProcessorClass: [SndAudioProcessorDistortion class]];
    [SndAudioProcessor registerAudioProcessorClass: [SndAudioProcessorFlanger class]];
    [SndAudioProcessor registerAudioProcessorClass: [SndAudioProcessorNoiseGate class]];
    [SndAudioProcessor registerAudioProcessorClass: [SndAudioProcessorReverb class]];
    [SndAudioProcessor registerAudioProcessorClass: [SndAudioProcessorMP3Encoder class]];
    [SndAudioProcessor registerAudioProcessorClass: [SndAudioProcessorRecorder class]];
    [SndAudioProcessor registerAudioProcessorClass: [SndAudioProcessorToneGenerator class]];
    defaultInspector = [[SndAudioProcessorInspector alloc] init];
  }
  return defaultInspector;
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  if (defaultInspector != nil)
    self = defaultInspector;
  else {
    self = [super init];

    [NSBundle loadNibNamed:@"SndAudioProcessorInspector" owner:self];
    [window makeKeyAndOrderFront:self];
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
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// initWithAudioProcessor:
////////////////////////////////////////////////////////////////////////////////

- initWithAudioProcessor: (SndAudioProcessor*) anAudProc
{
  self = [self init];
  [self setAudioProcessor: anAudProc];
  return self;
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

- setAudioProcessor: (SndAudioProcessor*) anAudProc
{
  if (theAudProc != nil)
    [theAudProc release];
  theAudProc = [anAudProc retain];
  [processorName setStringValue: [theAudProc name]];

  [parameterTableView selectRow: 0 byExtendingSelection: NO];
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

- (int) numberOfRowsInTableView: (NSTableView *) aTableView
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
             row: (int) rowIndex
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

////////////////////////////////////////////////////////////////////////////////
// SndAudioProcessor(Inspection)
////////////////////////////////////////////////////////////////////////////////

@implementation SndAudioProcessor(Inspection)

//////////////////////////////////////////////////////////////////////////////
// inspect
//
// Hmmm, is this worth having?? - SKoT rethinks.
//////////////////////////////////////////////////////////////////////////////

- (SndAudioProcessorInspector*) inspect
{
  return [[SndAudioProcessorInspector alloc] initWithAudioProcessor: self];
}


@end

////////////////////////////////////////////////////////////////////////////////

