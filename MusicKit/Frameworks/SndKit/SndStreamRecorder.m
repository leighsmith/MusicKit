////////////////////////////////////////////////////////////////////////////////
//
//  SndStreamRecorder.m
//  SndKit
//
//  Created by skot on Thu Apr 05 2001.
//  Copyright (c) 2001 tomandandy. All rights reserved.
//
//  ATTENTION!!!
//  Presumptions made to get this class off the ground quickly: The incoming
//  stream is made of 32-bit floats, and the saved file is made of 16-bit ints!
//
//  BIG TODO: general purposae format stuff 
//
// Using the client currently requires an explicit connect-to-stream manager
// call:
// 
// SndStreamRecorder *rec = [SndStreamrRecorder streamRecorder];
// [[SndStreamManager defaultStreamManager] addClient: rec];
// 
// then either...
// 
// [rec startRecordingToFile: @"/tmp/incomingsound.snd"];
// (time passes)
// [rec stopRecording];
// 
// or:
//
// [rec prepareForRecording: 10.5]; //record for 10.5 seonds
// [rec startrRecording];
//
// TODO:
// - Obviously the big todo here is to get general purpose stream and file
//   orformat conversion happening!
// - Also, output is currently buffered + written (in stream-to-file mode) in
//   44100-frame chunks; this should be more general.
// - delegate call-backs to say recording has started / ended, what incoming
//   levels are like, etc
//
////////////////////////////////////////////////////////////////////////////////

#import <MKPerformSndMIDI/SndStruct.h>
#import "SndAudioBuffer.h"
#import "SndStreamRecorder.h"
#import "SndStreamClient.h"

@implementation SndStreamRecorder

////////////////////////////////////////////////////////////////////////////////
// streamRecorder
////////////////////////////////////////////////////////////////////////////////

+ streamRecorder
{
  return  [[[SndStreamRecorder alloc] init] autorelease]; 
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  [super init];
  [self setNeedsInput: TRUE];
  [self setGeneratesOutput: TRUE];  
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  if (recordBuffer != nil) 
    [recordBuffer release];
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// description
////////////////////////////////////////////////////////////////////////////////

- (NSString*) description
{
  return @"SndStreamRecorder";
}

////////////////////////////////////////////////////////////////////////////////
// prepareToRecordForDuration:
////////////////////////////////////////////////////////////////////////////////

- prepareToRecordForDuration: (double) time
{
  if (!isRecording) {
    [self lockOutputBuffer];
    {
      SndAudioBuffer *outB = [self outputBuffer]; 
      if (recordBuffer != nil) 
        [recordBuffer release];
      
      recordBuffer = [SndAudioBuffer audioBufferWithFormat: [outB format] 
                                                duration: time]; 
      [recordBuffer retain];
    }
    [self unlockOutputBuffer];
  }  
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// startRecording
////////////////////////////////////////////////////////////////////////////////

- startRecording
{
  if (recordBuffer != nil && !isRecording) {
    position = 0;
    isRecording = TRUE;	
  }  
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// setUpRecordFile:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) setUpRecordFile: (NSString*) filename
{
  if ((recordFile = fopen([filename cString],"wb")) == NULL) {
    fprintf(stderr,"Error opening file '%s' for recording.\n",[filename cString]);
    return FALSE;
  }
  {
    SndSoundStruct *format = [[self synthBuffer] format];
    fwrite(format, sizeof(SndSoundStruct), 1, recordFile);
  }
  if (recordFileName != nil)
    [recordFileName release];
  recordFileName = [[filename copy] retain];
  
  return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// closeRecordFile:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) closeRecordFile
{
  // We have to seek back to the beginning of the recorded file to rewrite the
  // file header so that it contains the size of the recorded data, and the
  // file-stream format
  
  fseek(recordFile, 0, SEEK_SET);
  {
    SndSoundStruct format;
    memcpy (&format, [[self synthBuffer] format], sizeof(SndSoundStruct));
    format.dataLocation = sizeof(SndSoundStruct);
    format.dataSize     = bytesRecorded;
    format.dataFormat   = SND_FORMAT_LINEAR_16;
    fwrite (&format, sizeof(SndSoundStruct), 1, recordFile);
  }
  fclose(recordFile);
  recordFile = NULL;
  
  return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// startRecordingToFile:
//
// Set up an snd file for storage.
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startRecordingToFile: (NSString*) filename
{
  BOOL b = FALSE;
  
  if (!isRecording) {
    [self prepareToRecordForDuration: 1.0];
    if ([self setUpRecordFile: filename] && recordBuffer != nil) {
      conversionBuffer = (short*) malloc(sizeof(short) * 44100);
      position = 0;
      isRecording = TRUE;
      bytesRecorded = 0;
      b = TRUE;	
    }  
  }
  return b;
}

////////////////////////////////////////////////////////////////////////////////
// stopRecording
////////////////////////////////////////////////////////////////////////////////

- stopRecording
{
  isRecording = FALSE; // signal to recording thread that we wanna stop.
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// processBuffers
////////////////////////////////////////////////////////////////////////////////

- (void) processBuffers
{
  if (isRecording)
  {
    SndAudioBuffer *inB = [self inputBuffer];
    long length     = [inB lengthInBytes];
    void *recData   = [recordBuffer data];
    void *inputData = [inB data]; 
    long bufferSizeInBytes = [recordBuffer lengthInBytes];
    long remainder  = 0;

    if (position == 0) {
      // TODO: send 'started recording' message to delegate here.
    }
    // work out how much of the incoming buffer we can dump in the
    // record buffer...
    if (length + position > bufferSizeInBytes) {
      remainder = (length + position) - bufferSizeInBytes;
      length    = bufferSizeInBytes - position;
    }
    // transfer the incoming data...
    memcpy(recData + position, inputData, length);

    position += length;
    
    // have we filled a record buffer?
    if (position == [recordBuffer lengthInBytes]) {
      if (recordFile != NULL) { // we are streaming to a file, and need to write to disk!
        {
          int i;
          int c = bufferSizeInBytes / sizeof(float);
          float *f = (float*) recData; 

          for (i = 0; i < c; i++)
            conversionBuffer[i] = (short)(f[i] * 32767.0f);
            
          fwrite(conversionBuffer, c * sizeof(short), 1, recordFile);
          bytesRecorded += c * sizeof(short);
        }
        position = 0; 
        if (remainder) {
          memcpy(recData, inputData + length, remainder);
          position += remainder;
        }
      }
      else { 
        // we are streaming to a memory buffer, and have reached 
        // our buffer's limit - stop recording
        isRecording = FALSE;
        // TODO: send 'finished recording' message to delegate here
      }
    }
  }
  else if (!isRecording && recordFile != NULL)
  {
    [self closeRecordFile];
    // TODO: send 'finished recording' message to delegate here
  }
}

////////////////////////////////////////////////////////////////////////////////

@end
