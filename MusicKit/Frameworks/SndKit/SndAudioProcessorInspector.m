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
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  id w;
  self = [super init];

  [NSBundle loadNibNamed:@"SndAudioProcessorInspector" owner:self];
  w = [processorName window];
  [w makeKeyAndOrderFront:self];
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

  [parameterTableView selectRow: 0 byExtendingSelection: FALSE];
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
    [parameterValueSilder setNeedsDisplay: TRUE];
  }
}

////////////////////////////////////////////////////////////////////////////////
// parameterTableAction:
////////////////////////////////////////////////////////////////////////////////

- parameterTableAction: (id) sender
{
  int r = [parameterTableView clickedRow];
  printf("row: %i\n",r);
  if (theAudProc != nil) {
    [parameterValueSilder setFloatValue:  [theAudProc paramValue: r]];
    [parameterValueSilder setNeedsDisplay: TRUE];
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
//
////////////////////////////////////////////////////////////////////////////////

- didSelectObject: (id) sndAudioArchObject
{
  if ([sndAudioArchObject isKindOfClass: [SndAudioProcessor class]])
    [self setAudioProcessor: sndAudioArchObject];
  return self;
}

////////////////////////////////////////////////////////////////////////////////

@end
