////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorInspector.m
//  SndKit
//
//  Created by SKoT McDonald on Fri Dec 21 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndAudioProcessorInspector.h"

@implementation SndAudioProcessorInspector
 
////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- init
{
  id w;
  self = [super init];

//  if ( !heapSizeField ) {
    [NSBundle loadNibNamed:@"SndAudioProcessorInspector" owner:self];
    w = [processorName window];
    [w makeKeyAndOrderFront:self];
//    [parameterBrowser setDelegate: self];
    
//  }
//  [self setHeapSize:[[NSUserDefaults standardUserDefaults] integerForKey:@"HeapSize"]];
//  [objcFlag setIntValue:[[NSUserDefaults standardUserDefaults] boolForKey:@"UseObjcInterpreter"]];

//  [[heapSizeField window] makeKeyAndOrderFront:self];

    {
      NSArray *tableColumns = [parameterTableView tableColumns];
      id tcN = [tableColumns objectAtIndex: 0];
      id tcV = [tableColumns objectAtIndex: 1];
      [tcN setIdentifier: @"Name"];
      [tcN setEditable: FALSE];
      [tcV setIdentifier: @"Value"];
      [tcV setEditable: FALSE];
    }
    [sndArchView setDelegate: self];
    return self;
}

- initWithAudioProcessor: (SndAudioProcessor*) anAudProc
{
  self = [self init];
  [self setAudioProcessor: anAudProc];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  if (theAudProc != nil)
    [theAudProc release];
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- setAudioProcessor: (SndAudioProcessor*) anAudProc
{
  if (theAudProc != nil)
    [theAudProc release];
  theAudProc = [anAudProc retain];
  [processorName setStringValue: [theAudProc name]];

  [parameterTableView selectRow: 0 byExtendingSelection: FALSE];
  [parameterValueSilder setFloatValue: [theAudProc paramValue: 0]];
  [parameterTableView setDataSource: self];
  [parameterTableView reloadData];
  [processorActive setIntValue: [theAudProc isActive]];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- onProcessorActive: (id) sender
{
  [theAudProc setActive: [sender intValue]];
  return self;
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- onParameterValueSlider: (id) sender
{
  int r = [parameterTableView selectedRow];
  [theAudProc setParam: r toValue: [sender doubleValue]];
  [parameterValueSilder setDoubleValue: [theAudProc paramValue: r]];

  [parameterTableView reloadData];
  return self;
}

- (void)tableView:(NSTableView*)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
  if (theAudProc != nil) {
    int row = [tableView selectedRow];
    [parameterValueSilder setFloatValue: [theAudProc paramValue: row]];
    [parameterValueSilder setNeedsDisplay: TRUE];
  }
}

- parameterTableAction: (id) sender
{
  int r = [parameterTableView clickedRow];
  if (theAudProc != nil) {
    [parameterValueSilder setFloatValue:  [theAudProc paramValue: r]];
    [parameterValueSilder setNeedsDisplay: TRUE];
  }
  return self;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
  if (theAudProc != nil)
    return [theAudProc paramCount];
  else
    return 0;
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn: (NSTableColumn *)aTableColumn row:(int)rowIndex
{
  if ([[aTableColumn identifier] isEqualToString: @"Name"])
    return [theAudProc paramName: rowIndex];
  else
    return [NSString stringWithFormat: @"%.3f", [theAudProc paramValue: rowIndex]];
}

- didSelectObject: (id) sndAudioArchObject
{
  if ([sndAudioArchObject isKindOfClass: [SndAudioProcessor class]])
    [self setAudioProcessor: sndAudioArchObject];
  return self;
}

////////////////////////////////////////////////////////////////////////////////

@end
