////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorInspector.h
//  SndKit
//
//  Created by SKoT McDonald on Fri Dec 21 2001.
//  Copyright (c) 2001 tomandandy. All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDAUDIOPROCESSORINSPECTOR_H
#define __SNDKIT_SNDAUDIOPROCESSORINSPECTOR_H

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

#import "SndAudioProcessor.h"
#import <AppKit/NSDocumentController.h>

////////////////////////////////////////////////////////////////////////////////

/*!
@class      SndAudioProcessorInspector
@abstract   
@discussion To come
*/
@interface SndAudioProcessorInspector : NSDocumentController {
/*! @var parameterTableView */   
  id parameterTableView;
/*! @var parameterValueSilder */   
  id parameterValueSilder;
/*! @var processorActive */   
  id processorActive;
/*! @var processorName */   
  id processorName;
/*! @var sndArchView */   
  id sndArchView;
/*! @var theAudProc */   
  SndAudioProcessor *theAudProc;

  id addFxButton;
  id delFxButton;
  id fxChooser;
}

/*!
  @method     init
  @abstract
  @discussion
  @result     self
*/
- init;
/*!
  @method     initWithAudioProcessor:
  @abstract
  @discussion
  @param      anAudProc
  @result     self
*/
- initWithAudioProcessor: (SndAudioProcessor*) anAudProc;
/*!
  @method     dealloc
  @abstract   destructor
  @discussion
*/
- (void) dealloc;
/*!
  @method     setAudioProcessor:
  @abstract
  @discussion
  @param      anAudProc
  @result
*/
- setAudioProcessor: (SndAudioProcessor*) anAudProc;
/*!
  @method     onProcessorActive:
  @abstract
  @discussion
  @param      sender
  @result
*/
- onProcessorActive: (id) sender;
/*!
  @method     onParameterValueSlider:
  @abstract
  @discussion
  @param      sender
  @result
*/
- onParameterValueSlider: (id) sender;
/*!
  @method     parameterTableAction:
  @abstract
  @discussion
  @param      sender
  @result
*/
- parameterTableAction: (id) sender;
/*!
  @method     tableView:didClickTableColumn:
  @abstract
  @discussion
  @param      tableView
  @param      tableColumn
  @result
*/
- (void) tableView: (NSTableView*) tableView didClickTableColumn: (NSTableColumn*) tableColumn;
/*!
  @method     tableView:objectValueForTableColumn:row:
  @abstract
  @discussion
  @param      aTableView
  @param      aTableColumn
  @param      rowIndex
  @result
*/
- (id) tableView: (NSTableView*) aTableView objectValueForTableColumn: (NSTableColumn*) aTableColumn row: (int) rowIndex;
/*!
  @method     numberOfRowsInTableView:
  @abstract
  @discussion
  @param      aTableView
  @result     The number of parameters SndAudioProcessor 
*/
- (int) numberOfRowsInTableView: (NSTableView*) aTableView;
/*!
  @method     didSelectObject:
  @abstract
  @discussion
  @param      sndAudioArchObject
  @result     self
*/
- didSelectObject: (id) sndAudioArchObject;

- onAddFxButton: (id) sender;
- onDelFxButton: (id) sender;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
