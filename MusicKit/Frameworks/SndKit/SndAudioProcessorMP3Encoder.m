////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    Requires the libshout library produced by the Icecast
//    mp3 shoutcasting library (see http://www.icecast.org),
//    and the LAME MP3 encoder / decoder (http://www.lame.org)
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

#import "SndAudioProcessorMP3Encoder.h"

#define DEFAULT_MP3SERVER_PASSWORD     "letmein"
#define DEFAULT_MP3SERVER_PORT         8000
#define DEFAULT_MP3SERVER_ADDRESS      "127.0.0.1"      
// could also be "localhost" - icecast accepts both.

@implementation SndAudioProcessorMP3Encoder

////////////////////////////////////////////////////////////////////////////////
// initialize shoutcast library
////////////////////////////////////////////////////////////////////////////////

+ (void) initialize
{
  shout_init();
}

////////////////////////////////////////////////////////////////////////////////
// defaults accessors
////////////////////////////////////////////////////////////////////////////////

+ (int) defaultSourcePort
{
  return DEFAULT_MP3SERVER_PORT; 
}

+ (NSString*) defaultSourcePassword
{
  return [NSString stringWithCString: DEFAULT_MP3SERVER_PASSWORD];
}

+ (NSString*) defaultServerAddress
{
  return [NSString stringWithCString: DEFAULT_MP3SERVER_ADDRESS];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  [super initWithParamCount: mp3enc_kNumParams name: @"MP3Encoder"];
  
  buffer_l             = NULL;
  buffer_r             = NULL;
  bufferSizeInSamples  = 0;  
  mp3buff              = NULL;
  encodeNShoutcastLock = [[NSLock alloc] init];

  lameGlobalFlags = lame_init();
  if ((conn = shout_new()) == NULL) {
    NSLog(@"SndAudioProcessorMP3Encoder::init	- Arrrrrgh - error allocating shout data structure!\n");
  }
  lame_set_scale(lameGlobalFlags, 32767.0f);

  if (lame_init_params(lameGlobalFlags) == -1) {
    NSLog(@"SndAudioProcessorMP3Encoder::init	- Arrrrrgh - error initing LAME params!\n");
  }

  shout_set_host(conn, DEFAULT_MP3SERVER_ADDRESS);
  shout_set_port(conn, DEFAULT_MP3SERVER_PORT);
  shout_set_password(conn, DEFAULT_MP3SERVER_PASSWORD);
  shout_set_protocol(conn, SHOUT_PROTOCOL_ICY);
  shout_set_format(conn, SHOUT_FORMAT_MP3);

  return self;
}

////////////////////////////////////////////////////////////////////////////////
// setShoutcastServerAddress:port:password:
////////////////////////////////////////////////////////////////////////////////

- setShoutcastServerAddress: (NSString*) address
                       port: (int) port
                   password: (NSString*) password
{
  [encodeNShoutcastLock lock];
    
  if (shout_get_connected(conn) != SHOUTERR_CONNECTED) {
    shout_set_host(conn, [address cString]);
    shout_set_port(conn, port);
    shout_set_password(conn, [password cString]);
    shout_set_protocol(conn, SHOUT_PROTOCOL_ICY);
    shout_set_format(conn, SHOUT_FORMAT_MP3);
  }
  else {
    NSLog(@"SndAudioProcessorMP3Encoder: Error - can't change shoutcast server details whilst shoutcast is active!");
  }
  [encodeNShoutcastLock unlock];

  return self;
}                   

////////////////////////////////////////////////////////////////////////////////
// connectToShoutcastServer
////////////////////////////////////////////////////////////////////////////////

- (BOOL) connectToShoutcastServer
{
  BOOL r = FALSE;
  
  [encodeNShoutcastLock lock];
  
  if (shout_get_connected(conn) != SHOUTERR_CONNECTED) {
    if (shout_open(conn) == SHOUTERR_SUCCESS) {
      NSLog(@"SndAudioProcessorMP3Encoder::connectToShoutcastServer - Connected to server!\n");
      r = TRUE;
    }
    else { 
      NSLog(@"SndAudioProcessorMP3Encoder::connectToShoutcastServer - Error: Couldn't connect to server %s:%i with password [%s]...%i\n", 
            shout_get_host(conn), shout_get_port(conn), shout_get_password(conn),
            shout_get_error(conn));
    }
  }
  else {
    NSLog(@"SndAudioProcessorMP3Encoder::connectToShoutcastServer - Error: Already connected");
  }
  [encodeNShoutcastLock unlock];
  
  return r;
}

////////////////////////////////////////////////////////////////////////////////
// disconnectFromShoutcastServer
////////////////////////////////////////////////////////////////////////////////

- disconnectFromShoutcastServer
{
  [encodeNShoutcastLock lock];
  shout_close(conn);  
  [encodeNShoutcastLock unlock];
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// basic accessors
////////////////////////////////////////////////////////////////////////////////

- (NSString*) serverAddress
{
  return [NSString stringWithCString: shout_get_host(conn)];
}
 
- (NSString*) serverPassword
{
  return [NSString stringWithCString: shout_get_password(conn)];
}

- (int) serverPort
{
  return shout_get_port(conn);    
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  if (shout_get_connected(conn) == SHOUTERR_CONNECTED){
    [self disconnectFromShoutcastServer];  
    shout_free(conn);
  }

  if (buffer_l != NULL)
    free(buffer_l);
  if (buffer_r != NULL)
    free(buffer_r);
  if (mp3buff !=  NULL)
    free(mp3buff);
  
  if (encodeNShoutcastLock)
    [encodeNShoutcastLock release];
      
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// processReplacingInputBuffer:outputBuffer:
////////////////////////////////////////////////////////////////////////////////

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB 
                        outputBuffer: (SndAudioBuffer*) outB
{

  if (shout_get_connected(conn) == SHOUTERR_CONNECTED) {
    float *buff = (float*) [inB bytes];
    int retval, i, l = [inB lengthInSampleFrames], c = [inB channelCount];
    shout_sync(conn);
    [encodeNShoutcastLock lock];
    if (l != bufferSizeInSamples) {
      if (buffer_l != NULL)
        free(buffer_l);
      if (buffer_r != NULL)
        free(buffer_r);
      if (mp3buff != NULL)
        free(mp3buff);
      
      bufferSizeInSamples = l;
      buffer_l = (float*) malloc(sizeof(float) * bufferSizeInSamples);
      buffer_r = (float*) malloc(sizeof(float) * bufferSizeInSamples);
    
      mp3BufferSizeInBytes = 1.25 * bufferSizeInSamples + 7200;
      mp3buff  = (unsigned char*)  malloc(sizeof(unsigned char) * mp3BufferSizeInBytes);
    }
  
    switch (c) {
    case 2:
      for (i = 0; i < l; i++) {
        buffer_l[i] = buff[i*c];
        buffer_r[i] = buff[i*c+1];
      }
      break;
    default:
      NSLog(@"SndAudioProcessorMP3Encoder::processReplacing... - mono not coded yet");
    }
    retval = lame_encode_buffer_float(
                lameGlobalFlags,
                buffer_l,
                buffer_r,
                bufferSizeInSamples,      // number of samples per channel  
                mp3buff,                  // pointer to encoded MP3 stream  
                mp3BufferSizeInBytes);    // number of valid octets in this stream
                                       
    if (retval >= 0) {
//    fwrite(mp3buff,1,retval,stdout);
      retval = shout_send(conn, mp3buff, retval);
      if (!retval) {
        NSLog(@"SndAudioProcessorMP3Encoder::processReplacing... Send error: %i\n", shout_get_errno(conn));
      }
    }

    [encodeNShoutcastLock unlock];
  }
  return FALSE; // False because we haven't touched inB - signal that it is still 
                // valid for next processor.
}

////////////////////////////////////////////////////////////////////////////////
// paramObjectForIndex:
////////////////////////////////////////////////////////////////////////////////

- (id) paramObjectForIndex: (const int) i
{
  id obj;
  int conn_port;
  switch (i) {
    case mp3enc_kServerAddress:  obj = [NSString stringWithCString: shout_get_host(conn)];                  break;
    case mp3enc_kServerPort:     conn_port = shout_get_port(conn); obj = [NSValue value: &conn_port withObjCType: @encode(int)]; break;
    case mp3enc_kServerPassword: obj = [NSString stringWithCString: shout_get_password(conn)];            break;
    default:
      obj = [super paramObjectForIndex: i];
  }
  return obj;
}

////////////////////////////////////////////////////////////////////////////////
// paramName:
////////////////////////////////////////////////////////////////////////////////

- (NSString*) paramName: (const int) i
{
  NSString *s = nil;
  switch (i) {
    case mp3enc_kServerAddress:  s = @"ServerAddress";  break;
    case mp3enc_kServerPort:     s = @"ServerPort";     break;
    case mp3enc_kServerPassword: s = @"ServerPassword"; break;
  }
  return s;
}

////////////////////////////////////////////////////////////////////////////////

@end
