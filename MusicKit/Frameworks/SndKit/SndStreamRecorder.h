//
//  SndStreamRecorder.h
//  SndKit
//
//  Created by skot on Thu Apr 05 2001.
//  Copyright (c) 2001 __CompanyName__. All rights reserved.
//
#ifndef __SNDSTREAMRECORDER_H__
#define __SNDSTREAMRECORDER_H__

#import <Foundation/Foundation.h>

#import "SndAudioBuffer.h"
#import "SndStreamClient.h"

@interface SndStreamRecorder : SndStreamClient {

  SndAudioBuffer *recordBuffer;
  short          *conversionBuffer;
  long  position;
  BOOL  isRecording; 
  id    delegate;
  long bytesRecorded;
  
  FILE *recordFile;
  NSString *recordFileName;
}

+ streamRecorder;

- init;
- (void) dealloc;
- (NSString*) description;
- prepareToRecordForDuration: (double) time;
- startRecording;
- (BOOL) startRecordingToFile: (NSString*) filename;
- (BOOL) setUpRecordFile: (NSString*) filename;
- (BOOL) closeRecordFile;
- stopRecording;

@end

@interface SndStreamRecorderDelegate : NSObject
- didStartRecording:  sender;
- didFinishRecording: sender;
@end

#endif
