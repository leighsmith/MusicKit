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
  return  [[SndStreamRecorder new] autorelease]; 
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

- (BOOL) prepareToRecordForDuration: (double) time
{
  BOOL r = FALSE;
  
  if (isRecording) 
    fprintf(stderr,"SndStreamRecorder::prepareToRecordForDuration - Error: already recording!\n");
  
  else {
    [self lockOutputBuffer];
    {
      SndAudioBuffer *outB = [self outputBuffer]; 
      
      // This ain't an optimal situation - recorder shouldn't even HAVE an output buffer.
      // However, it is the only way at present to get format info from manager 
      // Ideally, we would like the recorder to connect to the stream manager itself
      if (outB == nil)
        fprintf(stderr,"SndStreamRecorder::prepareToRecordForDuration - Error: outBuffer is nil.\n");
        
      else {  
        if (recordBuffer != nil) 
          [recordBuffer release];
      
        recordBuffer = [SndAudioBuffer audioBufferWithFormat: [outB format] 
                                                    duration: time]; 
        if (recordBuffer == nil)
          fprintf(stderr,"SndStreamRecorder::prepareToRecordForDuration - Error: record buffer is nil.\n");
        else {
          [recordBuffer retain];
          r = TRUE;
        }
      }
    }
    [self unlockOutputBuffer];
  }
    
  return r;
}

////////////////////////////////////////////////////////////////////////////////
// startRecording
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startRecording
{
  BOOL r = FALSE;
  
  if (recordBuffer == nil)
    fprintf(stderr,"SndStreamRecorder::startRecording - Error: recordBuffer is nil.\n");

  else if (isRecording) 
    fprintf(stderr,"SndStreamRecorder::startRecording - Error: already recording!\n");
  
  else {
    position    = 0;
    isRecording = TRUE;	
    r           = TRUE;
  }
  return r;
}

////////////////////////////////////////////////////////////////////////////////
// setUpRecordFile:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) setUpRecordFile: (NSString*) filename
{
  if ((recordFile = fopen([filename cString],"wb")) == NULL) 
    fprintf(stderr,"SndStreamRecorder::setupRecordFile - Error opening file '%s' for recording.\n",[filename cString]);

  else if ([self synthBuffer] == nil)
    fprintf(stderr,"SndStreamRecorder::setupRecordFile - Error: synthBuffer is nil.\n");

  else
  {
    SndSoundStruct *format = [[self synthBuffer] format];
    if (format == nil) 
      fprintf(stderr,"SndStreamRecorder::setupRecordFile - Error: synthBuffer format is NULL.\n");
    
    else {
      fwrite(format, sizeof(SndSoundStruct), 1, recordFile);
      if (recordFileName != nil)
        [recordFileName release];
        
      recordFileName = [[filename copy] retain];
      return TRUE;
    }
  }
  
  return FALSE;
}

////////////////////////////////////////////////////////////////////////////////
// closeRecordFile:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) closeRecordFile
{
  // We have to seek back to the beginning of the recorded file to rewrite the
  // file header so that it contains the size of the recorded data, and the
  // file-stream format  
  SndSoundStruct format;
  fseek(recordFile, 0, SEEK_SET);
  memcpy (&format, [[self synthBuffer] format], sizeof(SndSoundStruct));
  format.magic = SND_MAGIC;
  format.dataLocation = sizeof(SndSoundStruct);
  format.dataSize     = bytesRecorded;
  format.dataFormat   = SND_FORMAT_LINEAR_16;
  fwrite (&format, sizeof(SndSoundStruct), 1, recordFile);
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
  
  if (isRecording) 
    fprintf(stderr,"SndStreamRecorder::startRecordingToFile - Error: already recording!\n");

  else if (![self prepareToRecordForDuration: 1.0]) 
    fprintf(stderr,"SndStreamRecorder::startRecordingToFile - Error in prepareTorecordForDuration.\n");

  else  if (![self setUpRecordFile: filename]) 
    fprintf(stderr,"SndStreamRecorder::startRecordingToFile - Error in setUpRecordFile\n");

  else if (recordBuffer == nil) 
    fprintf(stderr,"SndStreamRecorder::startRecordingToFile - Error: recordBuffer is nil.\n");
      
  else if ((conversionBuffer = (short*) malloc(sizeof(short) * [recordBuffer lengthInSamples] * [recordBuffer channelCount])) == NULL)
    fprintf(stderr,"SndStreamRecorder::startRecordingToFile - Error: bad malloc for conversionBuffer\n");
  
  else
  {
    position      = 0;
    bytesRecorded = 0;
    isRecording   = TRUE;
    b             = TRUE;	
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

//static long buffCount = 0; 

- (void) processBuffers
{  
  if (!isRecording && recordFile == NULL) {
//    fprintf(stderr,"Processing... (skip) buff: %li\n",buffCount++);
    return;
  }
  else {
    SndAudioBuffer *inB       = [self inputBuffer];
    void *recData             = [recordBuffer data];
    void *inputData           = [inB data]; 
    long inBuffLengthInBytes  = [inB lengthInBytes];
    long recBuffLengthInBytes = [recordBuffer lengthInBytes];
    long remainder            = 0;
    long length               = 0;

    if (bytesRecorded == 0) {
      if (delegate != nil && [delegate respondsToSelector: @selector(didStartRecording)]) 
        [delegate didStartRecording: self];
    }
    
    // work out how much of the incoming buffer we can dump in the
    // record buffer...
    if (inBuffLengthInBytes + position > recBuffLengthInBytes) {
      remainder = (inBuffLengthInBytes + position) - recBuffLengthInBytes;
      length    = recBuffLengthInBytes - position;
    }
    else {
      length = inBuffLengthInBytes;
    }
    // transfer the incoming data...
    memcpy(recData + position, inputData, length);

    position += length;
    
    
//    fprintf(stderr,"Processing... (pos: %li / %li  length: %li)\n",position,recBuffLengthInBytes,length);
    
    // have we filled a record buffer?
    if (position == recBuffLengthInBytes) {      
    
      if (recordFile != NULL) { // we are streaming to a file, and need to write to disk!
        float *f = (float*) recData; 
        int    i, samsToConvert = recBuffLengthInBytes / sizeof(float);
        float  highest = 0;

        for (i = 0; i < samsToConvert; i++) {
          conversionBuffer[i] = (short)(f[i] * 32767.0f);            
          if (highest  < f[i])
            highest = f[i];
        }
              
        fwrite(conversionBuffer, samsToConvert * sizeof(short), 1, recordFile);
//        fprintf(stderr,"Writing to disk (sams: %i highest: %f)\n",samsToConvert, highest);
      }
      else
       isRecording = FALSE;

      position = 0;
      bytesRecorded += remainder * sizeof(short);
    }        
    if (remainder) {
      memcpy(recData, inputData + length, remainder);
      position += remainder;
    }    
  } // end of isRecording
  
  if (!isRecording) { // has record state changed? If so, shut down stuff.
    if (recordFile != NULL)
      [self closeRecordFile];      
    if (delegate != nil && [delegate respondsToSelector: @selector(didFinishRecording)]) 
      [delegate didFinishRecording: self];
  }
}

////////////////////////////////////////////////////////////////////////////////

@end
