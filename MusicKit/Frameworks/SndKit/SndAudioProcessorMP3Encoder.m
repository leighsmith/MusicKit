////////////////////////////////////////////////////////////////////////////////
//
// SndAudioProcessorMP3Encoder.m
// SndKit
//
//  Created by SKoT McDonald <skot@tomandandy.com> on Mon Oct 01 2001.
//
// Requires the libshout library produced by the Icecast 
// mp3 shoutcasting library (see http://www.icecast.org), 
// and the LAME MP3 encoder / decoder (http://www.lame.org)
//
////////////////////////////////////////////////////////////////////////////////

#import "SndAudioProcessorMP3Encoder.h"

#define DEFAULT_MP3SERVER_PASSWORD     "letmein"
#define DEFAULT_MP3SERVER_PORT         8000
#define DEFAULT_MP3SERVER_ADDRESS      "127.0.0.1"      
// could also be "localhost" - icecast accepts both.

@implementation SndAudioProcessorMP3Encoder

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
  [super init];
  
  buffer_l             = NULL;
  buffer_r             = NULL;
  bufferSizeInSamples  = 0;  
  mp3buff              = NULL;
  bShoutcastActive     = FALSE;
  encodeNShoutcastLock = [[NSLock alloc] init];

  lameGlobalFlags = lame_init();
  shout_init_connection(&conn);
  lame_set_scale(lameGlobalFlags, 32767.0f);

  if (lame_init_params(lameGlobalFlags) == -1) {
    NSLog(@"SndAudioProcessorMP3Encoder::init	- Arrrrrgh - error initing LAME params!\n");
  }

  conn.ip         = strdup(DEFAULT_MP3SERVER_ADDRESS);
  conn.port       = DEFAULT_MP3SERVER_PORT;
  conn.password   = strdup(DEFAULT_MP3SERVER_PASSWORD);
  conn.icy_compat = 1;
    
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
    
  if (!bShoutcastActive) {

    if (conn.ip != NULL && address != nil)
      free(conn.ip);
    conn.ip   = strdup([address cString]);
    
    if (conn.password != NULL && password != nil)
      free(conn.password);
    conn.password   = strdup([password cString]);

    conn.port       = port;    
    conn.icy_compat = 1;
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
  
  if (!bShoutcastActive) {
    if (shout_connect(&conn)) {
      NSLog(@"SndAudioProcessorMP3Encoder::connectToShoutcastServer - Connected to server!\n");
      bShoutcastActive = TRUE;
      r = TRUE;
    }
    else { 
      NSLog(@"SndAudioProcessorMP3Encoder::connectToShoutcastServer - Error: Couldn't connect to server %s:%i with password [%s]...%i\n", 
            conn.ip, conn.port, conn.password, conn.error);
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
  shout_disconnect(&conn);  
  bShoutcastActive = FALSE;  
  [encodeNShoutcastLock unlock];
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// basic accessors
////////////////////////////////////////////////////////////////////////////////

- (NSString*) serverAddress
{
  return [NSString stringWithCString: conn.ip];
}
 
- (NSString*) serverPassword
{
  return [NSString stringWithCString: conn.password];
}

- (int) serverPort
{
  return conn.port;    
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  if (bShoutcastActive)
    [self disconnectFromShoutcastServer];  

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

- processReplacingInputBuffer: (SndAudioBuffer*) inB 
                 outputBuffer: (SndAudioBuffer*) outB
{

  if (bShoutcastActive) {
    float *buff = (float*) [inB data];
    int retval, i, l = [inB lengthInSamples], c = [inB channelCount];
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
      retval = shout_send_data(&conn, mp3buff, retval);
      if (!retval) {
        NSLog(@"SndAudioProcessorMP3Encoder::processReplacing... Send error: %i\n", conn.error);
      }
    }

    [encodeNShoutcastLock unlock];
  // shout_sleep(&conn);
  }
  [outB copyData: inB];
  return self;
}

////////////////////////////////////////////////////////////////////////////////

@end
