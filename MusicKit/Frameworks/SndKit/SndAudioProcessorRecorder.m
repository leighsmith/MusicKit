////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorRecorder.m
//  SndKit
//
//  Created by skot on Wed Dec 05 2001.
//  Copyright (c) 2001 tomandandy. All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////

#import <MKPerformSndMIDI/SndStruct.h>
#import "SndAudioBuffer.h"
#import "SndAudioProcessorRecorder.h"


@implementation SndAudioProcessorRecorder

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  bStartTrigger = FALSE;
  fStartTriggerThreshold = 0.002;

  return [super init];
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
//
////////////////////////////////////////////////////////////////////////////////

- (BOOL) isRecording
{
  return isRecording;
}

- setRecordBuffer: (SndAudioBuffer*) buffer
{
  if (recordBuffer != nil)
    [recordBuffer release];
  recordBuffer = [buffer retain];
  return self;
}

- (long) bytesRecorded
{
  return bytesRecorded;
}

////////////////////////////////////////////////////////////////////////////////
// processReplacingInputBuffer:outputBuffer:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB
                        outputBuffer: (SndAudioBuffer*) outB;
{
//  fprintf(stderr,"process\n");        
  if (!isRecording) {
//    fprintf(stderr,"Finished recording BBB\n");        
    if (bytesRecorded == 0 && position == 0)
      return FALSE;
  }
  {
    void *recData             = [recordBuffer data];
    void *inputData           = [inB data]; 
    long inBuffLengthInBytes  = [inB lengthInBytes];
    long recBuffLengthInBytes = [recordBuffer lengthInBytes];
    long remainder            = 0;
    long length               = 0, i;
    
    if (bStartTrigger) { // whoop! haven't started recording - look thru buffer
      long inBuffLengthInSams   = [inB lengthInSamples];
      float *finB = (float*) [inB data];
      long skip = [inB channelCount];
      
      for (i = skip ; i < inBuffLengthInSams; i += skip) {
        if (fabs(finB[i]) > fStartTriggerThreshold) {
          bStartTrigger = FALSE;
          inputData           += (i-skip) * sizeof(float);
          inBuffLengthInBytes -= (i-skip) * sizeof(float);
          break;
        }
      }
    }
    
    if (!bStartTrigger) { // do NOT make this an 'else' with the above 'if'!
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
      
      // have we filled a record buffer?
      if (position == recBuffLengthInBytes) {      
    
        if (recordFile != NULL) { // we are streaming to a file, and need to write to disk!
          [self streamToDiskData: recData length: recBuffLengthInBytes];
//        fprintf(stderr,"Processing... (pos: %li / %li  length: %li)\n",position,recBuffLengthInBytes,bytesRecorded);
        }
        else {
          bytesRecorded += length;
          isRecording = FALSE;
        }
        position = 0;
      }        
      if (remainder) {
        memcpy(recData, inputData + length, remainder);
        position += remainder;
      }    
    
      if (!isRecording) { // has record state changed? If so, shut down stuff.
        if (recordFile != NULL) {
          if (position > 0)  // flush out partial record buffer to disk
            [self streamToDiskData: recData length: position];
        
          [self closeRecordFile];
//        fprintf(stderr,"closed record file\n");
        }      
      }
    }
  } // end of isRecording
  return FALSE;
}

////////////////////////////////////////////////////////////////////////////////
// prepareToRecordForDuration:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) prepareToRecordForDuration: (double) time withFormat: (SndSoundStruct*) format
{
  BOOL r = FALSE;
  
  if (isRecording) 
    fprintf(stderr,"SndAudioProcessorRecorder::prepareToRecordForDuration - Error: already recording!\n");
  
  else {
    // This ain't an optimal situation - recorder shouldn't even HAVE an output buffer.
    // However, it is the only way at present to get format info from manager 
    // Ideally, we would like the recorder to connect to the stream manager itself
    if (format == NULL)
      fprintf(stderr,"SndAudioProcessorRecorder::prepareToRecordForDuration - Error: format is NULL.\n");
        
    else {  
      if (recordBuffer != nil) 
        [recordBuffer release];
      
      recordBuffer = [SndAudioBuffer audioBufferWithFormat: format 
                                                  duration: time]; 
      if (recordBuffer == nil)
        fprintf(stderr,"SndAudioProcessorRecorder::prepareToRecordForDuration - Error: record buffer is nil.\n");
      else {
        [recordBuffer retain];
        r = TRUE;
      }
    }
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
    fprintf(stderr,"SndAudioProcessorRecorder::startRecording - Error: recordBuffer is nil.\n");

  else if (isRecording) 
    fprintf(stderr,"SndAudioProcessorRecorder::startRecording - Error: already recording!\n");
  
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

void writeWavFormatHeader(SndSoundStruct* format, FILE* f, unsigned long dataLengthInBytes)
{
  unsigned long dw;
  unsigned short w;
  
  fwrite("RIFF", 4, 1, f);  
  fwrite(SndSwap_Convert32BitNative2LittleEndian(dataLengthInBytes + 38), 4, 1, f); // file length
  fwrite("WAVE", 4, 1, f);  
  fwrite("fmt ", 4, 1, f);  
  fwrite(SndSwap_Convert32BitNative2LittleEndian(18), 4, 1, f);                    // chunk length
  fwrite(SndSwap_Convert16BitNative2LittleEndian(1),  2, 1, f);                    // file format 1 = linear wav
  fwrite(SndSwap_Convert16BitNative2LittleEndian(format->channelCount),  2, 1, f); // channels
  fwrite(SndSwap_Convert32BitNative2LittleEndian(format->samplingRate), 4, 1, f);  // chunk length
  dw = format->samplingRate * format->channelCount * sizeof(short);
  fwrite(SndSwap_Convert32BitNative2LittleEndian(dw), 4, 1, f);                    // bytes per second
  w = format->channelCount * sizeof(short);
  fwrite(SndSwap_Convert16BitNative2LittleEndian(w),  2, 1, f);                    // frame size
  fwrite(SndSwap_Convert16BitNative2LittleEndian(16),  2, 1, f);                   // bit resolution
  fwrite(SndSwap_Convert16BitNative2LittleEndian(0),  2, 1, f);                    // extra bytes
  fwrite("data", 4, 1, f);  
  fwrite(SndSwap_Convert32BitNative2LittleEndian(dataLengthInBytes), 4, 1, f);     // data chunk length
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- (BOOL) setUpRecordFile: (NSString*) filename withFormat: (SndSoundStruct*) format
{
  if ((recordFile = fopen([filename fileSystemRepresentation],"wb")) == NULL) 
    fprintf(stderr,"SndAudioProcessorRecorder::setupRecordFile - Error opening file '%s' for recording.\n",[filename cString]);

  else  {
    if (format == NULL)
      fprintf(stderr,"SndAudioProcessorRecorder::setupRecordFile - Error: synthBuffer format is NULL.\n");
    else {
      writeWavFormatHeader(format, recordFile, 0);
      if (recordFileName != nil)
        [recordFileName release];
      recordFileName = [filename copy];
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
  fseek(recordFile, 0, SEEK_SET);
  writeWavFormatHeader([recordBuffer format], recordFile, bytesRecorded);
  fclose(recordFile);
  recordFile    = NULL;
  bytesRecorded = 0;
  
  return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// startRecordingToFile:
//
// Set up an snd file for storage.
////////////////////////////////////////////////////////////////////////////////

- (BOOL) startRecordingToFile: (NSString*) filename withFormat: (SndSoundStruct*) format
{
  BOOL b = FALSE;
  
  if (![self prepareToRecordForDuration: 1.0 withFormat: format]) 
    fprintf(stderr,"SndAudioProcessorRecorder::startRecordingToFile - Error in prepareTorecordForDuration.\n");

  else  if (![self setUpRecordFile: filename withFormat: format]) 
    fprintf(stderr,"SndAudioProcessorRecorder::startRecordingToFile - Error in setUpRecordFile\n");

  else if (recordBuffer == nil) 
    fprintf(stderr,"SndAudioProcessorRecorder::startRecordingToFile - Error: recordBuffer is nil.\n");
      
  else if ((conversionBuffer = (short*) malloc(sizeof(short) * [recordBuffer lengthInSamples] * [recordBuffer channelCount])) == NULL)
    fprintf(stderr,"SndAudioProcessorRecorder::startRecordingToFile - Error: bad malloc for conversionBuffer\n");
  
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
//
////////////////////////////////////////////////////////////////////////////////

- stopRecordingWait: (BOOL) bWait disconnectFromStream: (BOOL) bDisconnectFromStream
{
  isRecording = FALSE; // signal to recording thread that we want to stop.
  
  if (bWait) {
//    fprintf(stderr,"Waiting...\n");
    while (recordFile != NULL) {
//      usleep(100000);
      [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
//      fprintf(stderr,"."); fflush(stderr);
    }
//    fprintf(stderr,"Waiting done.\n");
//    active = FALSE;
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// processBuffers
////////////////////////////////////////////////////////////////////////////////

- (void) streamToDiskData: (void*) recData length: (long) bytesToRecord
{
    float *f = (float*) recData; 
    int    i, samsToConvert = bytesToRecord / sizeof(float);

    for (i = 0; i < samsToConvert; i++) {
        char *p = (char*)(conversionBuffer + i); 
        short s = (short)(f[i] * 32767.0f);
        p[0] = (char) (s & 0x00FF);
        p[1] = (char) ((s & 0xFF00) >> 8);
    }              
    fwrite(conversionBuffer, samsToConvert, sizeof(short), recordFile);
    bytesRecorded += samsToConvert * sizeof(short);    
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- primeStartTrigger
{
  bStartTrigger = TRUE;
  return self;
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

- setStartTriggerThreshold: (float) f
{
  fStartTriggerThreshold = f;
  return self;
}

////////////////////////////////////////////////////////////////////////////////

@end
